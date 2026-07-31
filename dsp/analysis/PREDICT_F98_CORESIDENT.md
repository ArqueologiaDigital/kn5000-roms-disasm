# `PREDICT_F98_CORESIDENT` — the `f98` cross-unit A/B is **NOT VIABLE**, and the review's own premise is superseded by a cheaper fact

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date **2026-07-31**.
**STRICTLY READ-ONLY pass.** No source edited, no build, no MAME run, no commit.
Every number below comes from (a) the committed ROM corpus via `dsp/tools/pat_corpus.py`,
(b) `dsp/disasm/*.dsm`, (c) archived logs in `dsp/analysis/data/*.log.gz` decompressed
to scratch, or (d) `kn7000_mame/src/devices/cpu/upd6383/*` read as source.

⚠ **RULE 19.** This pass makes **no audio claim of any kind**. Nothing here moves any output.

Grades: **MEASURED** / **FORCED** / **INFERRED** / **SPECULATIVE**.

---

## 0. RESULT — five statements, and the verdict

| # | statement | grade |
|---|---|---|
| **A** | ★★★ **The review's pair is REAL, exactly as described.** `012.A.00.1D5` occurs **only** in `a08 GATED REVERB` at `w85`; `212.A.00.1D5` occurs in `a16 ROOM REVERB 1` at `w7` **and** in `a10 MULTI TAP DELAY` at `w7`. `XOR = 0x200000000`, **popcount 1**, bit 33 = `hi12` bit 9 = `f98` msb. Nothing else differs. | **MEASURED** |
| **B** | ★★★★ **BUT THE PROPOSED EXPERIMENT IS DEAD ON ARRIVAL: the `f98 = 2` half sits at `iw207`, inside body 1's third-death region, and it is measured as an EXACT ZERO on every channel in BOTH buckets in NINE archived arms (§220 A/B/C/D, §221 A, §222 A, §223 F, §224 I, §225 K).** `dp = 0xD0`, `acc 0..0 / 0..0`, `mem 0..0 / 0..0`, `L 0..0 / 0..0`. You cannot A/B a live number against a structural zero. | **MEASURED** |
| **C** | ★★★★ **AND THE EXPERIMENT IS UNNECESSARY: an `f98` minimal pair is ALREADY co-resident, ADJACENT, in the ALWAYS-RESIDENT KERNEL.** `KERNEL w16 = 0192A00455` (`f98 = 1`) and `KERNEL w17 = 0292A00455` (`f98 = 2`) differ in **`f98` and nothing else** and run **back-to-back in every frame of every program ever emulated**. Zero effect selections. `§104`, `§S1`, `§S2` and `§175` **already print both**, in every archived log. | **MEASURED** |
| **D** | ★★★ **The brief's premise "`f98` … with no reading at all" is FALSE.** `f98 == 1` **has** a shipped reading: spec-mask **bit 59** (`§148`/`§156`), *`SRC 0x00` = `C-RAM[cursor]` gated on `f98 == 1` **and** `coeff_consumer(word)`*, licensed independently by `§147`. Bit 59 **is set in the shipping default** `m_specmask = 0xb910e446a39b440f` (`upd6383.h:1035`) and `§145` reports it **FIRED 4 705 920 times** in arm K. | **MEASURED** |
| **E** | ★★★★ **EVEN THE PERFECT PAIR IS NOT A CONTROLLED MEASUREMENT.** The kernel pair is a **chain** (`§S2` shows `iw17`'s `carried` term *is* `iw16`'s result, to the digit) and the two words **necessarily read different coefficients** (the cursor advances by construction on every `cur+` word). The model contains **no `f98` term on either word** (`SRC = 0x11 ≠ 0x00`, so bit 59 cannot apply) ⇒ any difference it prints is **100 % attributable to carried-accumulator and coefficient**, and **0 % to `f98`**, *by construction*. | **FORCED** |

> ## ⛔ VERDICT: **NOT VIABLE.**
> The cross-unit A/B must **not** be built. `f98` stays closed, and its closure is
> restated in **§7** — not as *"no co-resident pair"* (which is now falsified four
> ways) but as **"no discriminator: the field has no candidate semantics, and the
> arbiter available to this project cannot adjudicate one."**

---

## 1. VERIFYING THE REVIEW'S CLAIM — and the RULE 20 self-test that licenses the check

### 1.0 ★★★ RULE 20 SELF-TEST — reported BEFORE any result

A census that prints a clean zero is indistinguishable from a correct negative, so the
pair-finder was validated against `CORPUS-PATTERNS-SPECULATIVE.md` §2.3's **published**
table before it was used. **All twelve rows reproduce exactly, blind**, including the
document's own named control (`hi12` bit 7 = **12** pairs, **3** co-resident, **9** images):

```
distinct 36-bit words: 759   (published: 759)  ✓
bit:      0   1   2   3   4   5   6   7   8   9  10  11
pairs:    0   6   6  10  23   2   0  12   1   4   2   0   ✓ all 12 match
co-res:   0   3   1   2   4   1   0   3   0   0   0   0   ✓ all 12 match
images:   0  11   3   4  10   2   0   9   0   0   0   0   ✓ all 12 match
```

⇒ **`CORPUS-PATTERNS-SPECULATIVE.md` §2.3's TABLE IS CORRECT.** Its *conclusion* is not
(§1.2). **MEASURED**, denominator 759 distinct words over the 3057-word corpus, IC310
streams `{79, 88, 89, 90, 91}` excluded via `pat_corpus.MALFORMED`.

### 1.1 The pair itself

Population: **40 images / 3057 words** (`KERNEL` 60, `EPILOGUE` 23, **38 distinct body
images** 2974). `f98` census over all 3057: `0:1777  1:500  2:778  3:2` ⇒ **nonzero =
1280 = 41.87 %**, which reproduces the review's *"41.9 % of the corpus"* to the digit.
**MEASURED.**

| word | `f98` | occurs in | image idx | **I-RAM slot (`iw`)** |
|---|--:|---|--:|--:|
| `012.A.00.1D5` | **0** | `a08 GATED REVERB` (unit 0) — **and nowhere else** | `w85` of 102 | **169** |
| `212.A.00.1D5` | **2** | `a10 MULTI TAP DELAY` (unit **0**) | `w7` of 68 | **91** |
| `212.A.00.1D5` | **2** | `a16 ROOM REVERB 1` (unit **1**, 12 slots, algos 16–27) | `w7` of 133 | **207** |

`XOR = 0x200000000`, popcount **1**, bit 33. Both are `class A`, `addr8 = 0x00`,
`SRC = 0x07`, `ACT = 0x15`, `f31 = 1`, `b4 = 1` (store), `b7 = 0`, no escape, not C-format.
**Both pass `alu_decoded()`** — verified against `upd6383d.h:621` guard by guard (class A
admitted; `lo12 & 0x800` clear; `b4` set with `class4 & 7 == 2` ✓; `ACT ≠ 0x07`; guard 7 not
reached because `b7 = 0`; `f31 = 1 = HI_ACC_LOAD` ⇒ **true**), and confirmed by the
disassembler rendering `w85` as `mac (p),c+,(p)+0` (`prog08_gated_reverb.dsm:125`) rather
than `?word`. **MEASURED.**

⚠ **The review's sentence is incomplete in one respect that matters.** It says
`0212A001D5` *"occurs in `a16 ROOM REVERB 1`"*. It **also occurs in `a10 MULTI TAP DELAY`**,
a **unit-0** image — `CORPUS-PATTERNS-SPECULATIVE.md:629` records `{a10, a16}` correctly.
Consequence: the two halves of this pair can **never** be made co-resident within unit 0
(`a08` and `a10` are both unit-0 images and the machine holds one at a time), so the
cross-unit route is genuinely the only route **for this pair** — the review's conclusion
survives its own omission. **MEASURED / FORCED.**

### 1.2 ★★★★ The closure's *conclusion* is false — and not for the reason the review gives

`CORPUS-PATTERNS-SPECULATIVE.md:619-620` states:

> *"`f98` has 5 minimal pairs and ZERO co-resident ones. **No single loaded program can
> ever exhibit an `f98` difference on otherwise-identical words.**"*

That sentence generalises a **one-bit** census to a **two-bit FIELD**. `f98` has four
states; the transition `1 → 2` flips **both** bits at once and is therefore **invisible** to
a one-bit-pair scan. Re-running the census on the field rather than on single bits:

**17 pairs differing ONLY in `f98`** (vs 5 one-bit pairs), of which **three are
co-resident in a single image** and two more have one half in the always-resident kernel:

| A | B | `f98` | residency verdict |
|---|---|---|---|
| **`192.A.00.455`** | **`292.A.00.455`** | **1/2** | ★★★★ **SAME IMAGE: `KERNEL`** — `w16` and `w17`, **adjacent** |
| `102.2.00.000` | `202.2.00.000` | 1/2 | ★★ **SAME IMAGE**: `a01 CHORUS` (`w38`/`w43` → `iw122`/`iw127`), `a48 AUTO PAN`, `a64 S.DELAY+CHORUS` |
| `104.2.02.1CE` | `204.2.02.1CE` | 1/2 | one half is `KERNEL w4`; other in `a01 CHORUS`, `a05 PHASER` |
| `182.2.00.000` | `282.2.00.000` | 1/2 | one half is `KERNEL w13`; other in `a04`, `a48`, `a50`, `a54`, `a96`, `a98` |
| `012.A.00.1D5` | `212.A.00.1D5` | 0/2 | the review's pair — **cross-unit only** |
| `102.2.4B.1CD` / `104.2.00.000` / `182.A.00.000` | (see script) | 1/2 | cross-unit possible |
| the other 8 | — | — | **BOTH UNIT-0 ONLY ⇒ impossible** (one unit-0 image at a time) |

**And it is stronger than "three pairs":** the `KERNEL` alone carries `f98 ∈ {0 × 49,
1 × 4, 2 × 7}` and the `EPILOGUE` carries `{0 × 15, 1 × 3, 2 × 5}`. Both run **every frame
of every program**. ⇒ **all three attested `f98` values have been co-resident in every
single run this project has ever made.** *"One effect selection away"* is **zero effect
selections away**, and has been since §1. **MEASURED.**

Reproduce (stdlib + `pat_corpus`, ~20 lines — deliberately not shipped as a rival loader):

```python
import sys; sys.path.insert(0, "dsp/tools")
import pat_corpus as P
progs, meta = P.load()
sets = {nm: set(ws) for nm, ws in progs.items()}
distinct = set().union(*(set(ws) for ws in progs.values()))
M = 0x300 << 24                       # the f98 FIELD, not one bit
pairs = [(a, b) for a in distinct for b in distinct
         if a < b and (a ^ b) & ~M == 0]
for a, b in sorted(pairs):
    same = {nm for nm in sets if a in sets[nm] and b in sets[nm]}
    print(P.fmt(a), P.fmt(b), P.F(a).f98, P.F(b).f98, sorted(same) or "-")
```

---

## 2. ★★★★ THE CONFOUND SET — the heart of the task

★ **A minimal pair bounds what a field can ENCODE. It is not a controlled MEASUREMENT.**
Below is what the proposed measurement would actually be confounded by, item by item.

### 2.1 The proposed cross-unit sites are not comparable on ANY axis

| axis | `f98 = 0` site: `a08 w85` | `f98 = 2` site: `a16 w7` | ratio / verdict |
|---|--:|--:|---|
| I-RAM slot | **`iw169`** | **`iw207`** | **38 slots apart** |
| unit | **0** (`m_acc`) | **1** (`m_accb`) | **different accumulator register** |
| position in own ladder | `w85` of 102 = **83.3 %** | `w7` of 133 = **5.3 %** | **×15.7** |
| `cur+` words executed before it (image-relative cursor depth) | **20** | **3** | **×6.7** |
| words executed before it inside its own image | **85** | **7** | **×12.1** |
| coefficient bank in force | unit-0 per-effect bank (`§226` item B: `C-RAM[0x00..0x13]` is **effect-dependent**, `0 of 20` cells invariant) | unit-1 per-algorithm bank (`§227` banner: a preset change rewrites **23 cells of `0x90..0xB4`**) | **two different, both effect-dependent, banks** |
| preceding 6 words | `…018A001D5 104A001D5 C402C0000 182A00000 0002F7447` | `…202AFD1D5 202AF91D5 20224B1CD 00020040E` | **disjoint** |
| delay-descriptor index `m_delay_ix` on arrival | 20+ consumers deep | body-1 entry (`§201` resets at `iw200`) | **different descriptor cell** |
| pointer `m_dp` on arrival | body-0 walk | **`0xD0`** (the dead pointer, §2.2) | **structurally different** |

This is the **exact shape** that killed the `f31` experiment twice — *"the programs diverged
before the bit by a factor of twenty."* Here it is **a factor of 12.1 in executed words and
6.7 in cursor depth, across two different accumulators and two different coefficient banks.**

⇒ **Answering the brief's question plainly: NO. A difference measured at these two sites
could NOT be attributed to `f98` at all.** Not partially, not with a correction term. The
two sites do not share the machine state, the register file, the coefficient bank, the
pointer, the descriptor index, or the ladder position. **FORCED.**

### 2.2 ★★★★ …and one of the two sites is a measured, invariant ZERO

`§104` prints `iw207` in **nine** archived arms spanning §220–§225. It is identical in all
nine (arm K quoted; `A_off_220`, `B_mirror06_220`, `C_noz05_220`, `D_noz05_drpub_220`,
`A_epibus_221`, `A_pickup_222`, `F_satcen_223`, `I_s2_224` are byte-identical on this row):

```
iw  word        dp   nq/nl          acc q/l          mem q/l          L q/l
207 0212A001D5  D0   706040/313960  0..0 / 0..0  =   0..0 / 0..0  =   0..0 / 0..0  =
```

Population: **706 040 quiet + 313 960 loud = 1 020 000 samples**, from a 1 440 001-frame run
with the `§104` arm at frame 420 000.

★ **RULE 21, applied correctly.** The quiet range is degenerate (`min == max == 0`) — which
alone would be consistent with input dependence — **but the LOUD range is degenerate at the
same value.** A slot that does not move when the input latch is loud is neither
input-dependent nor free-running: **it is not carrying anything.** This is the documented
third death (`OUTPUT-STAGE-NULL_findings.md` §1: `iw205` "kills 128 of body 1's 133 slots";
`§104` `iw205` arrives at `dp 0x85` and the pointer is `0xD0` from `iw206` onward). `iw207`
is **three slots** past the death. **MEASURED.**

⇒ The A/B would compare a live `acc/mem/L` at `iw169` against **an unconditional zero**.
There is no contrast to measure and no null that could fail.

### 2.3 The confound does not go away on the BEST pair either

Take the strictly better `KERNEL w16/w17` pair (§1.2) — adjacent slots, one image, same
unit, same bank, same host parameters, 34 of 36 bits identical. `§S2` (§224's accumulator
term census, arm K, quiet bucket, `n = 706 040 / 313 960`) already prints both:

```
iw16  (f98=1)  carried  788981014570 + bus 0 + P  +394721708081 =  1183702722651  (2.153 xFS)
iw17  (f98=2)  carried 1183702722651 + bus 0 + P  -497064679562 =   686638043089  (1.249 xFS)
```

Two confounds survive **even here**, and they are structural:

1. **The pair is a CHAIN, not an A/B.** `iw17`'s `carried` term is *literally* `iw16`'s
   result — `1183702722651` appears in both rows. The second word is **downstream of the
   first**; there is no arm in which they see the same input. **MEASURED / FORCED.**
2. **The two words CANNOT read the same coefficient.** Both carry `cur+`, so the cursor
   advances between them by construction. `§175 PER-SITE` measures exactly this:
   `0192A00455 coef -3792303..3527094` vs `0292A00455 coef -1934277..4194304`. The `P` terms
   differ **because the coefficients differ**, before `f98` is even considered. **MEASURED.**
3. **The model has no `f98` term on these words.** Both have `SRC = 0x11`, so bit 59's
   `SRC 0x00` gate cannot fire; `f98` appears nowhere else in `upd6383.cpp`/`upd6383d.cpp`
   outside `hi_f98()`'s **printing** at `upd6383d.cpp:689`. ⇒ the emulator executes `w16`
   and `w17` **identically**, and every printed difference is `carried` + `coef`.
   **FORCED from source.**

---

## 3. THE DISCRIMINATOR — there isn't one, and naming why is the result

The brief asks: *if viable, name the exact quantity, at what slot, in which existing
instrument.* The honest answer is that **the instrument problem is already solved and the
discriminator problem is untouched**:

* **The instruments already exist and already aim at both halves of the best pair.**
  `§104` rows `iw16`/`iw17`; `§S1` rows `iw16`/`iw17` (clips `706040/313841` and
  `706040/313951`); `§S2` rows `iw16`/`iw17` term by term; `§175 PER-SITE` for the literal
  words `0192A00455` / `0292A00455` (`hits 1212480` each, `nz 1180800` each, `L 0..8388607`
  each, both graded **`live`**). **Nothing needs to be built and nothing needs to be run.**
* **What is missing is a HYPOTHESIS.** A discriminator is a quantity that takes value X if
  `f98` means one thing and value Y if it means another. `f98` has **no candidate
  semantics** — the review proposes none, `instruction-set.md` renders it *"a proven FIELD,
  MEANING UNKNOWN"* (`upd6383d.cpp:45`), and the one reading that exists (bit 59) covers
  only `f98 == 1` on `SRC 0x00` coefficient consumers and was licensed by an
  **independently computed** prediction (`§147`: the twelve `182.A.00.000` words landing on
  the 2/π envelope's one-pole constants, in the ROM's own upload order, matching the UI's
  *ATTACK SENS. / RELEASE SENS.*), **not** by a co-resident pair.
* **A co-resident pair buys convenience, not evidence.** Its only value in this project's
  method is that a **spec-mask A/B** (bit off → bit on) can exercise both branches inside
  one loaded program, so the arms are otherwise identical. But an A/B on a mask bit measures
  *the model you wrote*, and grading it requires a number computed independently of the
  model — `§156`'s `±240`-sample tap sweep is the template. **No such number exists for
  `f98`.** **FORCED by the project's own method.**

⇒ Aiming the existing instrument at the existing pair yields the numbers in §2.3, and those
numbers are the **null**, not a signal.

---

## 4. THE NULL, THE CONTROL, AND THE NAMED WRONG NUMBER — all from logs already on disk

### 4.1 The NULL (what "`f98` does nothing" looks like)

Source: `data/K_lfowrap_default_225.log.gz` (arm K, shipped default), decompressed to
scratch, never in place. Cross-checked identical in shape against `data/A_off_220.log.gz`
and `data/clean_vehicle_default.log.gz`.

**`f98 = 1` at `iw16` vs `f98 = 2` at `iw17`, under a model with no `f98` term:**

| channel | `iw16` (`f98=1`) | `iw17` (`f98=2`) | same? |
|---|---|---|---|
| `§104` `nq/nl` | 706040/313960 | 706040/313960 | **identical** |
| `§104` `dp` | `06` | `06` | **identical** |
| `§104` `mem` q/l | `8388607..8388607 / 1991044..8388607` | `8388607..8388607 / 1991044..8388607` | **identical** |
| `§175` `hits` | 1212480 | 1212480 | **identical** |
| `§175` `nz` | 1180800 | 1180800 | **identical** |
| `§175` `L` | `0..8388607` | `0..8388607` | **identical** |
| `§175` `m_dp` | `0..255`, `live` | `0..255`, `live` | **identical** |
| `§S1` quiet pre-clamp | `12038894..12038894` | `18061870..18061870` | differs |
| `§S2` `P` | **+394 721 708 081** | **−497 064 679 562** | differs |
| `§175` `coef` | `-3792303..3527094` | `-1934277..4194304` | differs |

**The null is: every channel that is not downstream of the coefficient is BIT-IDENTICAL
across the `f98` change.** The three that differ are exactly the three the cursor advance
explains. **MEASURED.**

### 4.2 The CONTROL whose answer is already known

★ **`iw18` and `iw19` are ADJACENT and BOTH `f98 = 1`.** If `f98` were driving the §4.1
differences, holding it constant should suppress them. It does not:

```
iw18 (f98=1)  carried  686638043089 + bus 0 + P  +549755748352 = 1236393791441
iw19 (f98=1)  carried 1236393791441 + bus 0 + P  -197867971549 = 1038525819892
```

**A `P` sign flip of the same magnitude class occurs between two adjacent slots with `f98`
held CONSTANT.** ⇒ "P changes sign across the pair" is a **property of adjacency and the
coefficient**, not of `f98`. **Control PASSES as a null. MEASURED.**

Second control, in the other direction — a quantity that is **insensitive** to `f98` across
the sequence `f98 = 1, 2, 1, 1` at `iw16..19`: the `§S1` quiet-bucket clip count is
`706040/706040`, `706040/706040`, `706040/706040`, `3530200/3530200` — **100 % in every
row regardless of `f98`** (the `iw19` figure is 5× because that slot converts five times per
frame). **MEASURED.**

### 4.3 ★ THE NAMED SPECIFIC WRONG NUMBER — the failure mode to pre-empt

> **If any pass reports that `f98 = 2` inverts the multiply, its evidence will be**
> **`P = −497 064 679 562` at `iw17` against `P = +394 721 708 081` at `iw16`.**
> **That claim is VOID**, because `iw18 → iw19` reproduces the same sign flip with `f98`
> held at 1 (§4.2), and because `§175` measures the two sites' coefficient ranges as
> different (`-3792303..3527094` vs `-1934277..4194304`). **Any `f98` reading built on
> `−497 064 679 562` is a coefficient-sign artefact.**

A second named wrong number, for the cross-unit route specifically: **`0..0`**. `iw207`'s
`acc`, `mem` and `L` are all exactly that, in both buckets, in nine arms. A pass that
reports *"`f98 = 2` zeroes the accumulator"* will be reading the third death, not the field.

---

## 5. THE VEHICLE — constructible, but it is not what kills the experiment

The brief predicted the experiment would die here. **It does not.** Reporting that honestly:

* **Can the machine hold `GATED REVERB` in unit 0 and a reverb in unit 1 simultaneously?**
  **YES — and it always does.** `programs.tsv` gives **exactly one unit-1 image**
  (`a16 ROOM REVERB 1`, 12 slots, algos 16–27); `kernel.dsm`'s banner states the header
  *"CALLs unit-0 body (I-RAM 84) then unit-1 body (I-RAM 200)"* every frame. There is no
  configuration in which unit 1 is empty. ⇒ the "reverb resident in unit 1" half of the
  recipe costs **zero** actions. **MEASURED / FORCED.**
* **How is unit 0 selected?** `data/typewalk/TYPE_MAP.md` gives **TYPE 6 =
  `prog08_gated_reverb`**. ★ **The off-by-one does not apply**: the map's own banner says
  *"TYPE 8 is verified correct, so the duplicate lies above it"*, and 6 < 8. `TYPELAST=36`;
  `type_select.lua` saturates UP then steps DOWN. `peq_select.lua` must **not** be used
  (it drops steps and has already voided an experiment). **MEASURED.**
* ⚠ **The `§193`/`§104` pooling defect is real and would apply.** `§104` arms at
  `m_frames_run > 420000` (`upd6383.cpp:5170`), **never resets**, and
  `m_sp_word[prof_iw] = raw` is last-write-wins (`:5176`). In a type-walk the panel selects
  at ~1.8–2.2 M frames, so the table pools the boot program's numbers with the selected
  program's at the same slot numbers while printing the **selected** program's word.
  ⚠ **Brief correction:** the recorded figures are **~1.4 M boot frames with ~0.4 M
  selected-program frames** (`INSTRUMENT-AUDIT_findings.md:193-198`), not ~1.76 M / ~0.4 M.
  **MEASURED.**
* **How the run would have to be gated, had it been built:** (i) select **before** frame
  420 000 so the `§104` window contains only the selected program, *or* run
  `UPD6383_S104_FRAME`-equivalent gating — which **does not exist**; `§104` never got the
  env knob `§128` has (`INSTRUMENT-AUDIT_findings.md:139`), so in practice (i) is the only
  option; (ii) **fingerprint the loaded program from the upload dump in the same run**
  (`kn5000_dsp1_upload.txt`, 16-word match — a 4-word prefix collides for 8 of 38 programs);
  (iii) grade only on the **frame trace**, which re-zeroes on arming (`:1814`) and is the one
  instrument the pooling defect does not touch. **FORCED from source.**

⇒ **The vehicle is usable. It is items 2 and 3 that kill the experiment, not item 5.**

---

## 6. VERDICT

# **NOT VIABLE**

Three independent sufficient reasons, in decreasing order of finality:

1. **No discriminator (§3).** `f98` has no candidate semantics and no independently
   computable predicted quantity. Co-residency is a convenience; the project's method needs
   a number computed *outside* the model, and none exists. This alone closes it.
2. **The two proposed sites are not comparable (§2.1) and one of them is a measured,
   nine-arm-invariant zero (§2.2).** The kill-condition the review itself wrote — *"the
   corpus pre-computation shows the two images differ in too many other fields to isolate
   the pair ⇒ abort before the build"* — **fires**, and fires harder than anticipated:
   they differ in unit, accumulator register, coefficient bank, ladder depth (×12.1),
   pointer, and descriptor index.
3. **The experiment is superseded (§1.2).** A strictly better pair — adjacent, one image,
   same unit, same bank, `f98` and nothing else — has been co-resident and instrumented in
   **every run this project has ever made**, and its numbers (§4.1) are the null.

---

## 7. ★★★ THE HONEST RESTATEMENT OF `f98`'s CLOSURE

Replacing `CORPUS-PATTERNS-SPECULATIVE.md:619-623`:

> **`f98` — RESTATED CLOSURE, 2026-07-31.**
>
> ⛔ **The old reason is WITHDRAWN.** *"5 minimal pairs and ZERO co-resident ones; no single
> loaded program can ever exhibit an `f98` difference on otherwise-identical words"* is
> **FALSE**. It counted **one-bit** pairs over a **two-bit field**, so the `1 → 2`
> transition — which flips both bits — was invisible to it. The one-bit table itself is
> correct (reproduced 12/12 blind); only the generalisation is wrong.
>
> ★ **`f98` HAS co-resident minimal pairs, and they cost nothing.** On the field rather than
> on single bits there are **17** pairs, of which **three sit inside one image** and two more
> have one half in the always-resident kernel. The cleanest is **`KERNEL w16 = 0192A00455`
> (`f98 = 1`) and `KERNEL w17 = 0292A00455` (`f98 = 2`) — ADJACENT slots in the header that
> runs every frame of every program.** The `KERNEL` carries `f98 ∈ {0 × 49, 1 × 4, 2 × 7}`
> and the `EPILOGUE` `{0 × 15, 1 × 3, 2 × 5}`, so **all three attested values have been
> co-resident in every run ever made.**
>
> ★★ **THE ACTUAL REASON `f98` IS CLOSED: NO DISCRIMINATOR.**
> 1. **No candidate semantics.** Nothing proposes what `f98` selects, so no measurement can
>    have a predicted value, and a test with no predicted value cannot fail (measurement
>    discipline).
> 2. **A co-resident pair is not a controlled measurement.** Even the adjacent kernel pair
>    is a **chain** (`§S2`: `iw17`'s carried term *is* `iw16`'s result) and **cannot** read
>    the same coefficient (both carry `cur+`; `§175` measures the two coefficient ranges as
>    different). The one comparison the corpus offers is confounded **by construction**.
> 3. **The arbiter cannot adjudicate.** The model has **no `f98` term** on these words, so
>    the emulator executes both identically and any printed difference is 0 % `f98`. The
>    only route the project has used successfully is `§147`/`§156`'s: an **independently
>    computed prediction** from the ROM, matched by a model change. That route is open for
>    `f98`; the A/B route is not.
>
> ⇒ **`f98` is not blocked by the corpus. It is blocked by the absence of a hypothesis.**
> ★ **The one reading that exists is `f98 == 1`** — spec-mask bit 59 (`§148`/`§156`),
> `SRC 0x00 = C-RAM[cursor]` gated on `f98 == 1 && coeff_consumer`, **in the shipping default**
> (`m_specmask = 0xb910e446a39b440f`, `upd6383.h:1035`), `§145` **FIRED 4 705 920 times** in
> arm K. Any future `f98` work should extend **that** line — the `f98 == 1` ⇒
> *"coefficient-consuming filter context"* reading — not run a cross-unit A/B.

---

## 8. COULD ANY *OTHER* PAIRING OF THE TWO RESIDENT IMAGES WORK?

Asked explicitly by the brief. Answer: **no pairing improves on the kernel pair, and the
cross-unit route is the worst of the seven candidates.** Enumerated from §1.2's 17:

| candidate | cost | why it is not better |
|---|---|---|
| `KERNEL w16/w17` | **0 selections** | **the best available** — and §2.3 shows even it is a chain with an unavoidable coefficient confound |
| `a01 CHORUS iw122/iw127` (`102`/`202.2.00.000`) | **0** (CHORUS is the cold-boot unit-0 default) | ★ same image, same unit, 5 slots apart — but **`§104` measures BOTH as `0..0 / 0..0` on `acc`, `mem` and `L`**, i.e. both halves are in body 0's dead region. **MEASURED** |
| `KERNEL w4` ↔ `a01`/`a05` (`104`/`204.2.02.1CE`) | 0–1 | one half is the **audio input latch** read (`kernel.dsm w4`); mixing the port read into a field test is a different confound, not a smaller one |
| `KERNEL w13` ↔ `a04/a48/a50/…` (`182`/`282.2.00.000`) | 1 | `KERNEL w13` is inside the `§S2` overflow window (`1.870 xFS`); the body half sits in the dead region |
| `012/212.A.00.1D5` (**the review's**) | 1 | §2.1 + §2.2 — **worst on every axis, and one half is a nine-arm zero** |
| `102/202.2.4B.1CD`, `104/204.2.00.000`, `182/282.A.00.000` | 1 | all put the `f98 = 2` half in `a16` (unit 1) at `iw` ≥ 205 ⇒ **same third-death problem** |
| the remaining 8 | — | **structurally impossible**: both halves are unit-0-only, one image at a time |

★ **Note for the queue, NOT run here (queue item 6):** `hi12` **bit 5** remains the better
target — `000.2.00.000` ↔ `020.2.00.000`, co-resident **inside `a15 ROCK ROTARY`**, on the
word `instruction-set.md` renders as `nop`. It has the property `f98` lacks: a **falsifiable
prediction** ("a `nop` that is not a `nop`"). Verified present in this pass's self-test
(bit 5: 2 pairs, 1 co-resident, 2 images ✓). **Not mine to run.**

---

## 9. ⚠ ERRORS FOUND IN THE BRIEF AND IN THE REVIEW — reported as required

| # | statement | source | verdict |
|---|---|---|---|
| 1 | *"`f98` … with **no reading at all**"* | brief §CONTEXT | ★★ **FALSE.** `f98 == 1` is read by spec-mask bit 59, **in the shipping default**, `§145` FIRED 4 705 920× (§0 D) |
| 2 | *"`f98` was **closed on a technicality that does not hold**"* / *"mislabelled as closed"* | review `:13` | **HALF RIGHT.** `:619-620`'s *"no single loaded program can ever…"* **is** false (§1.2) — but `:621-622` already said *"any `f98` experiment must compare two different loaded effects — an experimental-design fact"*, so the note never claimed impossibility. And the closure is falsified by a pair the review did **not** find (`KERNEL w16/w17`), not by the cross-unit route it proposes |
| 3 | *"`0212A001D5` occurs in `a16 ROOM REVERB 1`"* | review `:13` | **INCOMPLETE.** It also occurs in `a10 MULTI TAP DELAY` (unit 0) at `w7`. `CORPUS-PATTERNS-SPECULATIVE.md:629` has `{a10, a16}` correctly (§1.1) |
| 4 | *"any type-walk run pools **~1.76 M** frames of the boot program with ~0.4 M"* | brief §5 | **WRONG NUMBER.** The recorded figure is **~1.4 M / ~0.4 M** (`INSTRUMENT-AUDIT_findings.md:196`) (§5) |
| 5 | *"**this is where it most likely dies**" (the vehicle)* | brief §5 | **WRONG PREDICTION.** The vehicle is constructible: unit 1 **always** holds `a16`, and `TYPE 6 = GATED REVERB` sits below the off-by-one boundary. It dies at §2/§3 instead (§5) |
| 6 | *"`§104`'s sampler … prints the selected program's WORD beside the boot program's NUMBERS"* | brief §5 | ✓ **CORRECT**, confirmed at `upd6383.cpp:5176` |
| 7 | *"`SRC = lo12[10:6]`, `ACT = lo12[4:0]`" (RULE 18); MALFORMED = `{79,88,89,90,91}`; `programs.tsv:14`; `41.9 %`; "both pass `alu_decoded()`"; "otherwise byte-identical"* | brief + review | ✓ **ALL CORRECT AND REPRODUCED** (§1.1) |

---

## 10. TEN-LINE SUMMARY

1. **The pair is REAL.** `012.A.00.1D5` (`a08 GATED REVERB` `w85`) ↔ `212.A.00.1D5` (`a16 ROOM REVERB 1` `w7`), XOR popcount **1** at bit 33 = `f98` msb, both pass `alu_decoded()`. It also occurs in `a10` — the review omitted that.
2. **Detector self-tested first (RULE 20):** all **12** rows of the published one-bit table reproduce blind, including the `hi12` bit-7 control (12 pairs / 3 co-resident / 9 images), over **759** distinct words.
3. **CONFOUND VERDICT: fatal.** The two sites differ in unit (`m_acc` vs `m_accb`), I-RAM slot (**169 vs 207**), ladder depth (**×12.1** in executed words, **×6.7** in cursor advances), coefficient bank (both effect-dependent), pointer and descriptor index. **A difference there is not attributable to `f98` at all.**
4. **One half is a measured ZERO.** `iw207` reads `acc/mem/L = 0..0` in **both** buckets over **1 020 000** samples, in **nine** archived arms — three slots past `iw205`'s third death, `dp = 0xD0`. RULE 21: degenerate in *both* buckets ⇒ dead, not input-dependent.
5. **The vehicle CAN hold both** — unit 1 has exactly one image and is loaded every frame; `TYPE 6 = GATED REVERB` is below `TYPE_MAP.md`'s off-by-one boundary. **The vehicle is not what kills it.**
6. **It is superseded:** `KERNEL w16 = 0192A00455` (`f98=1`) and `w17 = 0292A00455` (`f98=2`) are **adjacent** in the always-resident header — an `f98` minimal pair co-resident in **every run ever made**, at **zero** selections.
7. **Discriminator: none exists.** `§104`/`§S1`/`§S2`/`§175` already print both kernel sites; what is missing is a **hypothesis** and an independently computed predicted number. A co-resident pair is convenience, not evidence.
8. **The NULL:** across the `f98` change every non-coefficient channel is **bit-identical** (`nq/nl`, `dp`, `mem`, `§175 hits/nz/L/m_dp`, both `live`); only `coef`, `P` and the pre-clamp value move — exactly what the cursor advance explains.
9. **Control passes, wrong number named:** `iw18 → iw19` reproduces the `P` sign flip with `f98` held **constant** ⇒ any claim resting on **`P = −497 064 679 562` at `iw17`** is void; for the cross-unit route the wrong number is **`0..0`**.
10. ⛔ **NOT VIABLE — do not build.** `f98`'s closure is restated as **"no discriminator: no candidate semantics, and the pair that exists is a chain with an unavoidable coefficient confound"** — *not* "no co-resident pair". `f98 == 1` already has a shipped reading (bit 59, `§145` FIRED 4 705 920×); extend that line instead.
