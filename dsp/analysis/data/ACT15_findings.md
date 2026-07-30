# `ACT 0x15` — the census, what it CANNOT be, and the correction that matters more

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Target: the ACTION code
`lo12[4:0] == 0x15` — **707 words, 23.7 % of the corpus, 39 of the 40 images**,
the second-largest ACTION code, decoded by the MAME device as *nothing*
(`LO_ACT_NONE_5`, `upd6383d.h:343`). Handed over by
`SPECULATIVE-APPLIED-REGISTER.md` §169. Date **2026-07-30**.

Method: **static only** — no emulator was run and nothing outside this file and
`dsp/tools/act15_*` was touched. Tool:
[`../../tools/act15_census.py`](../../tools/act15_census.py) (stdlib only, prints
every number quoted here). Corpus via `pat_corpus.load()`: **3057 words / 40
images / 91 effect slots**, IC310 (MN19413) streams {79, 88, 89, 90, 91} already
excluded, C-format words excluded from every ACTION statistic ⇒ **ACTION
population = 2989**.

Grades: **MEASURED** / **FORCED** (every alternative is excluded by an
independent constraint) / **INFERRED** / **SPECULATIVE**.

---

## 0. Result in one page

| # | what | grade |
|---|---|---|
| **A** | ⛔⛔ **§169 §2 IS A SOURCE-LEVEL ERROR, and it is the most important thing in this file.** The class-A multiply is gated by `coeff_consumer(word)` = `class4 == 0xA`, **never by the ACTION** (`upd6383.cpp:3334`, `:3437`). **419 of the 548 `alu_decoded()`-admitted `ACT 0x15` words are class A with `f31 != 2` — the multiply already issues on every one of them.** So `ACT 0x15 = no-op` **cannot** be why `m_p = 0, chg = 0` at CHORUS's class-6 site. Decoding `ACT 0x15` will not move the LFO index path. | **FORCED** (source, quoted) |
| **B** | And the owning note already said so. `lfo-ramp.md` §10 reads `000.A.00.1D5` as *"`ACTION 0x15` (no side effect), class A — so it **multiplies the phase by a coefficient and leaves the product in P**"*. §169 cited that sentence and then contradicted it. Standing rule 3, eleventh occurrence. | **MEASURED** (quotation) |
| **C** | ★★ **`ACT 0x15` is NOT `ACT 0x13`'s effect and NOT `ACT 0x14`'s effect** — whatever those are named. Forced by a *perfect adjacent minimal pair inside the PARAMETRIC EQ biquad*, a section that reproduces its designer's transfer function to 0.094–0.198 dB: `202.A.01.**1D4**` (w8) and `202.A.01.**1D5**` (w7) differ in the ACTION field and in nothing else, and the section's state shift requires w8's register write and requires w7 **not** to make it. Same for `000.A.00.1D3` vs `000.A.00.1D5`. | **FORCED**, conditional on the biquad decode (§4) |
| **D** | The biquad extends C to a full exclusion set: `ACT 0x15` does **not** write `tempA`, `tempB`, the accumulator, the D-RAM pointer or the coefficient cursor, and does **not** scale the product. Everything the biquad reads is accounted for with `0x15` inert. | **FORCED** under the same condition |
| **E** | ★ The one strong positive signature: **`ACT 0x15` is the coefficient-fetch word's default action.** 56.8 % of the 893 `class4 & 8` words carry it against 9.5 % elsewhere (**5.95×**); class-A co-occurrence is 472 against a null of 199.4 (**z = +19.3**); 35 of 44 class-8 words; **53 of 54** class-1 delay-DRAM `ACT 0x15` words are immediately followed by a fetch word (null 47.0 %, z = +5.5). | **MEASURED**, nulls computed first |
| **F** | ★ The sharpest negative in the whole table: **`ACT 0x15` never co-occurs with `SRC 0x00` — 0 of 622, against an expectation of 147.1.** `SRC 0x00` is the coefficient (`C-RAM[cursor]`, §145). The complementary code `ACT 0x00` takes `SRC 0x00` 580 times. | **MEASURED** |
| **G** | *"How it differs from `0x12` is OPEN"* stays open, and the corpus **cannot** close it. `ACT 0x12` is essentially one form (`212.{A,2}.01.412`, 64 of 85) and contrasts with `0x15` in exactly **two** places corpus-wide, one word each. | **MEASURED** |
| **H** | **Ranked answer: `ACT 0x15` most probably has no architecturally visible side effect** — it is the "no capture" member of the ACTION field, the plain-MAC code, and its 23.7 % share is exactly what that predicts. The shipped decode is, on this evidence, **right**; what is wrong is the *comment* that says the difference from `0x12` is the interesting question, and §169's use of it as a blocker. | **INFERRED** — §8 gives the ranking, §9's E3 the falsifier |

**What did NOT happen:** no new side effect was decoded for `ACT 0x15`. This pass
delivers an exclusion set, a structural signature, a retraction of the reason the
task was raised, and the experiment that would overturn the ranking.

---

## 1. Orientation — what the owning notes already say  (rule: check them FIRST)

Read before any statistic was computed: `LEDGER.md` (all four tiers), §169,
`action-field.md`, `adjudication-round7.md`/`round8.md`, `lfo-ramp.md` §10–§11,
`capture-signature.md`, and `upd6383d.h` / `upd6383.cpp` at every `0x15` site.
**§171 landed from a parallel worker while this pass was running** and is
re-verified and used in §5.3.

`ACT 0x15` **is already written down twice**, and neither entry is a decode:

* `action-field.md` §0/§2 lists `0x12`/`0x15` = `('', '')` among *"the five
  anchored codes"* and uses them as the sanity property of the search space. It
  is honest that this is the *shipped* reading, not a solved one: §10's OPEN list
  begins *"every ACTION code except the five already anchored"*.
* `upd6383d.h:343` — `LO_ACT_NONE_5 = 0x15, // ditto -- how it differs from 0x12
  is OPEN`.

`ACT 0x15` was held **FIXED at no-op** in every exhaustive search this project has
run (`r1_allpass_solve.py action` / `singledelay`; 20 580 000 and 5 145 000
machines). It has therefore never been *searched*, only *assumed*. §9's **E3**
turns that into the falsifier.

**Nothing in `LEDGER.md`'s dead-end list touches `ACT 0x15`**, so nothing here
re-proposes a refuted idea.

---

## 2. The population, and the ACTION field  — MEASURED

`act15_census.py pop`

```
  programs (2 kernel + 38 distinct body images):  40
  effect SLOTS covered by the bodies:             91
  words total:                                    3057
  C-format words (hi12[11:8] == 0xC), EXCLUDED:     68
  ACTION population:                              2989
```

| ACT | count | % | images | decode as shipped |
|---:|---:|---:|---:|---|
| `0x00` | 820 | 27.4 | 40 | `acc ← bus` (the adder's input term) |
| **`0x15`** | **707** | **23.7** | **39** | ★ **NO-OP** |
| `0x07` | 455 | 15.2 | 40 | `STORE mem[ptr] ← bus` |
| `0x0E` | 227 | 7.6 | 40 | `P ← bus` (§144) |
| `0x0D` | 203 | 6.8 | 39 | `acc ← bus` (§144) |
| `0x19` | 91 | 3.0 | 21 | `tempA ← ???` (destination NOT measured) |
| `0x12` | 85 | 2.8 | 19 | NO-OP |
| `0x0B` | 82 | 2.7 | 27 | OPEN |
| `0x14` | 58 | 1.9 | 17 | `tempB ← bus` |
| `0x03` | 54 | 1.8 | 26 | `tempB ← bus` (`m_tb = L`) |
| `0x13` | 40 | 1.3 | 16 | `tempA ← bus` |
| … | | | | 14 further codes, 1–52 words each |

§169's figures reproduce exactly. The only image without an `ACT 0x15` word is
the **EPILOGUE** (the 23-word output stage); every one of the 38 body images and
the KERNEL carries it. `ACT 0x15` spans **168 distinct word forms** — it is not
one idiom repeated.

**No positional signature.** Normalised position in the frame: `ACT 0x15` median
**0.525** (q1 0.275, q3 0.761) against the whole population's **0.500** (0.245,
0.750). **No run structure**: 183 adjacent `0x15,0x15` pairs against a null of
161.4 (z = +1.7). Both are negative results and both are reported.

---

## 3. The structural signature — `ACT 0x15` is the FETCH word's default

### 3.1 Class, with the null first

`act15_census.py mi`. Null = the ACT's own total × the class marginal.

```
  ACT 0x00  n= 820   class-A  117   EXPECTED  231.3   z=  -7.5
  ACT 0x07  n= 455   class-A   38   EXPECTED  128.3   z=  -8.0
  ACT 0x0D  n= 203   class-A    1   EXPECTED   57.3   z=  -7.4
  ACT 0x0E  n= 227   class-A    3   EXPECTED   64.0   z=  -7.6
  ACT 0x13  n=  40   class-A   36   EXPECTED   11.3   z=  +7.4
  ACT 0x14  n=  58   class-A   42   EXPECTED   16.4   z=  +6.3
  ACT 0x12  n=  85   class-A   55   EXPECTED   24.0   z=  +6.3
  ACT 0x15  n= 707   class-A  472   EXPECTED  199.4   z= +19.3   <-- the target
  ---- corpus class-A rate = 843/2989 = 0.282
```

`class4 == 0xA` is the coefficient consumer (K4, FORCED). **472 of the 843
class-A words in the corpus — 56.0 % — carry `ACT 0x15`**, and the code is
absent from classes 0, 4, 6 and 9 entirely.

### 3.2 Widened to every coefficient-FETCH word (`class4 & 8`)

`act15_census.py disc`. This is the cleanest cut in the data: the ACTION field
splits into a *multiply* population and a *non-multiply* population.

```
  coefficient-FETCH words (class4 & 8): 893      everything else: 2096
  ACT     fetch    %      other    %     ratio
  0x13      36    4.0        4    0.2   21.12x        \
  0x08      43    4.8        9    0.4   11.21x         |  the FETCH family
  0x14      42    4.7       16    0.8    6.16x         |  695 of 893 = 77.8 %
  0x15     507   56.8      200    9.5    5.95x   <--   |
  0x1A      12    1.3        6    0.3    4.69x         |
  0x12      55    6.2       30    1.4    4.30x        /
  0x0B      16    1.8       66    3.1    0.57x
  0x00     122   13.7      698   33.3    0.41x        \
  0x19       9    1.0       82    3.9    0.26x         |  the NON-FETCH family
  0x07      39    4.4      416   19.8    0.22x         |
  0x0E       3    0.3      224   10.7    0.03x         |
  0x0D       1    0.1      202    9.6    0.01x        /
```

**`ACT 0x15` is the majority action of a multiply word and a rarity elsewhere.**
`0x0D`/`0x0E` — the two codes §144 decoded as *"the entry hands the sample over
in `P`"* — are its exact mirror image, at 0.01× and 0.03×.

### 3.3 The delay-DRAM words agree, and this one has its own null

`act15_census.py disc`, class 1 only (the external delay-RAM escapes):

```
  ALL class-1: 285 words, 134 followed by a coefficient-fetch word (base 47.0 %)
   ACT 15:  54 words,  53 followed by a fetch   EXPECTED 25.4   z= +5.5
   ACT 19:  35 words,  29                       EXPECTED 16.5   z= +3.1
   ACT 0B:  50 words,   4                       EXPECTED 23.5   z= -4.0
   ACT 00:  39 words,   2                       EXPECTED 18.3   z= -3.8
   ACT 14:  16 words,   0                       EXPECTED  7.5   z= -2.7
```

**53 of 54.** A delay-DRAM word carrying `ACT 0x15` is, with one exception,
always immediately followed by the multiply that consumes what it fetched. The
null is 47 %, not 0 %, and it was computed before the table was read.

### 3.4 The sharpest negative

`act15_census.py census`, ACT × SRC:

```
  SRC 00  C-RAM[cursor] = the COEFFICIENT (S145)   corpus 622
      ACT 0x15 :   0     EXPECTED 147.1        <-- exceptionless
      ACT 0x00 : 580     EXPECTED 170.6
```

Zero of 622. `ACT 0x15` and the coefficient source **never** appear in the same
word; `ACT 0x00` and the coefficient source appear together 580 times. Whatever
`0x15` does, it is not something you do to a coefficient.

---

## 4. ★★ THE FORCED EXCLUSION — the biquad's adjacent minimal pair

`act15_census.py known` prints one PARAMETRIC EQ section verbatim. This is the
single most constraining context in the corpus: §124/§125/§127 established the
block, §127 verified its coefficient chain end to end, and it **reproduces its
designer's transfer function to 0.094–0.198 dB** under the shipped ALU.

```
  w5   0000A001D3  000.A.00.1D3 clsA addr8=00 SRC=07 mem  ACT=13  tempA <- bus     f31=0
  w6   0212A01412  212.A.01.412 clsA addr8=01 SRC=10 acc  ACT=12  NO-OP            f31=1 ST
  w7   0202A011D5  202.A.01.1D5 clsA addr8=01 SRC=07 mem  ACT=15  NO-OP        ★   f31=1
  w8   0202A011D4  202.A.01.1D4 clsA addr8=01 SRC=07 mem  ACT=14  tempB <- bus     f31=1
  w9   0202A001D5  202.A.00.1D5 clsA addr8=00 SRC=07 mem  ACT=15  NO-OP        ★   f31=1
  w10  01022FF687  102.2.FF.687 cls2 addr8=FF SRC=1A tB   ACT=07  STORE            f31=1
  w11  0804816415  804.8.16.415 cls8 addr8=16 SRC=10 acc  ACT=15  NO-OP        ★   f31=2 ESC
  w12  0212AFF407  212.A.FF.407 clsA addr8=FF SRC=10 acc  ACT=07  STORE            f31=1 ST
  w13  0000203647  000.2.03.647 cls2 addr8=03 SRC=19 tA   ACT=07  STORE            f31=0
```

**w7 and w8 are a perfect minimal pair**: `202.A.01.1D4` and `202.A.01.1D5` agree
in `hi12`, `class4`, `addr8` and `SRC` and differ **only** in the ACTION field —
and they are *adjacent*, so no intervening word can explain a difference.
Corpus-wide the two forms occur 35 and 36 times.

### 4.1 The argument, stated so that it does not depend on the names

Write `R13` for the register `ACT 0x13` writes and `R14` for the one `ACT 0x14`
writes. The section's pointer walk (`addr8` is the mode-2 post-increment) puts
the four state cells at `p0 … p0+3`, and the two writes that shift the state are

```
   w8  captures m[p0+2] into R14   -->  w10 stores R14 into m[p0+3]
   w5  captures m[p0]   into R13   -->  w13 stores R13 into m[p0+1]
```

Between w5 and w13 the only words that could rewrite `R13` under the shipped
decode are w7, w9 and w11, and **all three carry `ACT 0x15`**. Their buses are
`m[p0+1]`, `m[p0+3]` and `acc` — three different values, none equal to `m[p0]`.

> ⇒ **If `ACT 0x15` wrote `R13`, w13 would store the wrong cell into `m[p0+1]`
> and the `z⁻²` state would stop advancing.** Identically, if it wrote `R14`,
> w10 would store `m[p0+3]` into `m[p0+3]` — a self-copy — and the other `z⁻²`
> state would freeze at its initial value.

Either failure **removes a whole second-order branch from every one of the
section's ten instances**. That is not a 0.2 dB effect. The section fits its
designer at 0.198 dB, so it did not happen.

**This is non-circular**: it never uses "R13 is tempA". It only uses "w5 writes
the register w13 reads", which the state shift itself forces, and the fact that
the ACTION field is the only place w7/w8 differ.

### 4.2 The exclusion set that follows

The same nine words exclude the rest of the architecturally visible state:

| candidate reading of `ACT 0x15` | why the biquad refuses it |
|---|---|
| `R13 ← bus` (i.e. `0x13`'s effect) | §4.1 — the `x`-state shift dies |
| `R14 ← bus` (i.e. `0x14`'s effect) | §4.1 — the `y`-state shift dies |
| `acc ← bus` / `acc ± bus` (i.e. `0x00`/`0x0D`'s effect) | w7 and w9 sit **inside** the MAC chain; either would discard the running sum and the section stops being a biquad at all |
| `STORE mem[ptr] ← bus` (`0x07`) | w7/w9 would write over live state cells at `p0+1`/`p0+3` |
| advance the coefficient cursor | the section consumes exactly six coefficients; §127 verified the chain end to end |
| move the D-RAM pointer | the walk `+0,+1,+1,+1,+0,−1,·,−1,+3` is what puts the four states where w10/w12/w13 write them |
| scale / re-round the product (a Q-format select) | w7 and w9 are the `b₂` and `a₂` taps; a wrong scale on exactly two taps is a large, band-shaped error |
| **gate the multiply itself** | ⛔ **REFUTED outright**: w5, w6, w8 and w12 are class A **without** `ACT 0x15` and every one of them must multiply (`b₁`, `b₀`, `a₁`, and the section gain) |

**What survives:** *no side effect at all*, or a write to a register that the
biquad neither reads nor is scaled by — the multiplier input latches `m_k`/`m_l`,
`ACCB`, an output port. Those are enumerated and ranked in §7.

⚠ **The one condition, stated.** All of §4 is conditional on the biquad decode
(§124–§129) being right. It is the best-validated block on this chip, but it is
not hardware.

---

## 5. ★★ THE CORRECTION — why §169 named the wrong thing

§169 §2 says: *"The word that must issue `scale × phase` does nothing, so `m_p`
stays 0."* **The premise is false in the shipped source.**

`upd6383.cpp`, the multiply, immediately after the ACTION dispatch:

```
   3334:  if ((m_speculative && (m_specmask & 4)) ? coeff_fetch(word)
                                                  : coeff_consumer(word))
   ...
   3437:      m_p = u64((s64(util::sext(coef, 24)) * s64(L)) >> P_SHIFT) & ...;
   3441:      if (coeff_consumer(word)) m_cursor++;
```

with `coeff_consumer(w) = class4(w) == 0xa && !c_format(w)` (`upd6383d.h:841`).
**The ACTION field is not in that condition.** The ACTION dispatch's own default
arm is three lines earlier:

```
   3322:      break;                  // 0x12 and 0x15: no temp / memory side effect
```

`act15_census.py decoded` counts what that means for the target:

```
  guard  0    548   DECODED -- executes the ALU        of 707 ACT 0x15 words
  ...
  decoded ACT 0x15 words:              548
  ... of which class A:                419
  ... of which class A AND f31 != 2:   419   <- the multiply DOES issue
```

**419 of 419.** Not one class-A `ACT 0x15` word is prevented from multiplying by
the ACTION being a no-op.

### 5.1 The specific word §169 blames

§169 §4's own table says CHORUS carries the phase **24 and 28 words** from its
lookup — so the word `000.A.00.1D5` it quotes is the **gap-6** family's
(`lfo-ramp.md` §10: FLANGER / AUTO PAN / VIBRATO / RING MODULATOR), not the
vehicle's. `act15_census.py known` prints CHORUS's actual tail:

```
  w25  000.A.00.415  clsA SRC=10 acc   ACT=15  f31=0
  w26  212.A.F3.1D5  clsA SRC=07 mem   ACT=15  f31=1 ST
  w27  092.2.00.700  cls2 SRC=1C       ACT=00  f31=1 b7|ST
  w28  202.A.07.1D5  clsA SRC=07 mem   ACT=15  f31=1     <-- the index multiply
  w29  182.2.00.407  cls2 SRC=10 acc   ACT=07  f31=1 b7
  w30  040.0.00.C63  cls0 SRC=11       ACT=03            <-- the C63 idiom (S166)
  w31  000.6.18.4CD  cls6 SRC=13       ACT=0D            <-- the lookup
```

`202.A.07.1D5` has `hi12 = 0x202` ⇒ `f31 = 1`, no bit 4, `SRC 0x07` and `ACT
0x15` both anchored, class A, `lo12 & 0x800 == 0`, no pointer-mode ⇒
`alu_decoded()` **admits it**, and `coeff_consumer()` **fires**. Nothing between
w28 and w31 is a fetch word, so `m_p` at the class-6 site *is* w28's product.

> ⇒ **`m_p = 0` at the lookup means `coef == 0` or `L == 0` at w28** — an
> operand-supply defect, not an ACTION defect. That points straight back at
> §168's own diagnosis (*"`C63` reads a cell that never changes"* — an
> **addressing** defect), and at §165's prediction of the shape of the remaining
> gap. Three lines of evidence already agreed on addressing; §169 is the outlier.

### 5.2 And the owning note said it first

`lfo-ramp.md` §10, verbatim:

> `000.A.00.1D5` is `SRC 0x07 = mem[Q]`, ACTION `0x15` (no side effect), class A
> — so it **multiplies the phase by a coefficient and leaves the product in `P`**

§169 quotes that paragraph for the coefficient `24` and then asserts the opposite
of its main clause. **Standing rule 3, eleventh occurrence** — and this time the
note that had the answer is the one being cited.

### 5.3 ★ Cross-check against §171, and it decides §171's open question

§171 (parallel worker, landed mid-pass) generalises §169's one word into a
**46-site family**: a class-A `ACT 0x15` word sits at offset **−3** from the
class-6 lookup, 46 times, against a null of 8.4. Re-verified here independently
(`act15_census.py` corpus, class-6 sites with the C-format kernel word excluded):

```
   offset from the class-6 word :  -5:13   -4:0   -3:46   -2:0   -1:0   0:0
   at offset -3:  000.A.00.415 x17 (SRC 0x10 acc)   +  29 SRC-0x07 forms
                  -- 16 distinct forms, TOTAL 46, by SRC: 07:29  10:17
   class-A ACT-0x15 base rate 0.1579 -> null over 53 sites = 8.4
```

Exact reproduction, including CHORUS's `202.A.07.1D5` appearing once. §171's
**§2 stands**: `ACT 0x15` at the index slot is a 46-site, 25-image family with
*two already-decoded sources*, not a one-word special case.

⛔ **But §171 §4 does not.** Its rival account of §168 is:

> *"There is no addressing defect. The cell `C63` reads is frozen because the
> dead `ACT 0x15` multiply never produces the value that would be written into
> it. One cause, not two."*

**Its premise is false.** §5 shows the multiply at those 46 words is not dead —
`coeff_consumer()` fires on every one of them and the ACTION field is not in the
gate. So "the dead `ACT 0x15` multiply" names something that does not exist, and
the one-cause account collapses at its first clause.

⇒ **§168's addressing diagnosis is NOT displaced**, and §171 §4's "do not carry
§168 forward as settled" should be narrowed to: the *rival* is withdrawn, and the
one experiment that separates them (E2) is now a measurement of operands, not of
a gate.


---

## 6. Minimal pairs, in full — MEASURED

`act15_census.py pairs`. Groups of words identical in `hi12`, `class4`, `addr8`
and `SRC`, differing only in ACTION, that contain `0x15`:

| `hi12.cls.addr8` SRC | the ACTION codes that share it |
|---|---|
| `000.2.00` SRC `0x10` acc | `0x07`:2 `0x0B`:1 `0x0E`:52 `0x13`:4 **`0x15`:22** `0x19`:16 |
| `202.A.01` SRC `0x07` mem | `0x14`:35 **`0x15`:36** ← ★ §4, the biquad pair |
| `000.A.00` SRC `0x07` mem | `0x13`:28 **`0x15`:22** ← ★ §4, the other pair |
| `880.1.20` SRC `0x0B` dram-rd | `0x07`:40 **`0x15`:3** `0x19`:6 |
| `880.1.20` SRC `0x19` tempA | `0x0B`:28 **`0x15`:16** |
| `104.2.00` SRC `0x07` mem | `0x0E`:23 **`0x15`:14** |
| `212.A.00` SRC `0x07` mem | `0x13`:2 **`0x15`:2** |
| `012.2.FF` SRC `0x07` mem | `0x00`:2 `0x0E`:2 **`0x15`:1** |
| `012.A.00` SRC `0x07` mem | `0x00`:1 **`0x15`:1** |
| `000.A.0A` SRC `0x10` acc | `0x12`:1 **`0x15`:2** |
| `000.A.FF` SRC `0x11` | `0x12`:1 **`0x15`:1** |

**11 groups.** The decoded codes `0x15` contrasts with are `0x00` (`acc ← bus`),
`0x07` (store), `0x0E` (`P ← bus`), `0x13`, `0x14` and `0x19` — i.e. every anchor
the project has. §4 discharges `0x13`/`0x14`; the biquad's MAC chain discharges
`0x00` and `0x07`; `0x0E` survives (see §7, candidate C4).

The **complement test** is worth recording as a null: `ACT 0x15` shares a form
key with eight other codes, more than any code except `0x07`, so it is not
syntactically isolated — the minimal pairs are real contrasts, not a population
artefact.

### 6.1 One population warning, found and priced

27 of the 40 `ACT 0x13` words, 27 of 58 `0x14` and 27 of 85 `0x12` lie **inside**
the 8-word biquad section, which occurs **27 times** across ten images (10 in
PARAMETRIC EQ itself — two parallel five-section banks, §125 — and 1–2 in each
PEQ combi). Any statistic over `0x12`/`0x13`/`0x14` is therefore one idiom
counted up to 27 times.

Re-run over the **outside-the-biquad** population only, the couplings hold:

```
  ACT 13 (n=9 class A, +4 class 2)   addr8 = 00 in 13 of 13   -- and 40 of 40 corpus-wide
  ACT 14 (n=15 class A, +16 class 1) addr8 = 01:8 60:16 FF:3  -- NOT coupled
  ACT 15 (n=418 class A)             addr8 = 00:195 01:44 ... -- NOT coupled
```

`ACT 0x13 ⇒ addr8 == 0x00`, **40 of 40**, across 16 images. Null: the corpus
`addr8 == 0x00` rate is 0.407, so p = 0.407⁴⁰ ≈ **2.5 × 10⁻¹⁶**. That is an
exceptionless encoding fact about `0x13` and it is **not shared by `0x15`**
(302 of 707 at `addr8 == 0x00`, i.e. 42.7 % against a 40.7 % base rate — pure
noise). Recorded here because it is a lead for `0x13`, not for the target.

---

## 7. `0x12` vs `0x15` — the device's own question, and why the corpus cannot answer it

`act15_census.py disc`:

```
  class4  0x12: A:55 2:30                    0x15: A:472 2:146 1:54 8:35
  SRC     0x12: 10:79 11:3 1A:3              0x15: 07:435 10:205 19:54 1A:5 11:4 0B:3
  addr8   0x12: 01:74 (87 %)                 0x15: 00:302 01:86 16:35 FF:31 ...
  bit4    0x12: ST in 77 of 85 (91 %)        0x15: ST in 107 of 707 (15 %)
  f98     0x12: 2 in 80 of 85                0x15: 0:324 2:275 1:106
  ESC     0x12: 0 of 85                      0x15: 89 of 707
```

`ACT 0x12` is **one idiom**: `212.A.01.412` (34) + `212.2.01.412` (30) = 64 of
85, i.e. *"store the accumulator, multiply it, `p += 1`"*. It never takes a
memory source (0 of 85 at `SRC 0x07`, expected 26.4) and never appears on an
escape word.

`ACT 0x15` is a **superset**: it covers `0x12`'s register sources and adds
`mem[ptr]`, the delay-read register and the escape forms.

**The two contrast in exactly two places in the whole corpus** (§6, last two
rows), one word each:

```
  000.A.0A.415  GATED REVERB w1, ROCK ROTARY w1   |  000.A.0A.412  ROCK ROTARY w66
  000.A.FF.455  AUTO WAH w50                      |  000.A.FF.452  ROOM REVERB 1 w127
```

Four words, four different programs, no shared algorithm. **There is no corpus
evidence that separates `0x12` from `0x15`, and this pass does not manufacture
any.** The honest statement is that `0x12` is a rare form of the same
no-side-effect action, or that the distinction lives in a register the corpus
never reads back.

---

## 8. Ranked candidate meanings

Ordered by posterior after §3–§7. Every one is compatible with the FORCED
exclusion set of §4.2.

### C1 — `ACT 0x15` has no architecturally visible side effect (the shipped reading)   ★ RANK 1

*It is the "no capture" member of the ACTION field: the plain-MAC code.*

**For.** (i) §4: the biquad reads out completely, coefficient chain and state
shift included, with `0x15` inert, at 0.198 dB. (ii) SINGLE DELAY's core is three
*consecutive* class-A `ACT 0x15` words (`000.A.00.1D5`, `212.A.00.415`,
`202.A.00.1D5`, w10–w12 and again at w15–w17, w33–w35, w38–w40) — a textbook MAC
chain that works with them inert, and `action-field.md` §6 forces the rest of
that block at 5 145/5 145. (iii) §3: 56.8 % of fetch words, and a MAC word by
construction needs no capture — the share is *predicted*, not merely compatible.
(iv) It explains F (never with `SRC 0x00`) trivially: the coefficient is
delivered by `class4`, so a coefficient-sourced word is never the multiplicand
word.

**Against.** It is the status quo, so no observation can *confirm* it; and it
leaves `0x12` unexplained (§7). ⚠ It has also never been *searched* — every
exhaustive solve on this project pinned `0x15` at no-op by construction (§1).
That is what §9's E3 fixes.

### C2 — `ACT 0x15` latches the bus into the multiplier input register (`m_l`/`m_k`)   ★ RANK 2

*Observationally identical to C1 under the shipped multiply, which bypasses the
latch and uses the freshly-read `coef` and the live bus (`upd6383.cpp:3126`,
`:3136` — "a latched-coefficient MAC with the latch bypassed").*

**For.** Every signature in §3 is exactly what a multiplicand latch would look
like: 5.95× on fetch words, 53 of 54 on the delay-DRAM words that precede a
multiply, never on a coefficient source. `m_k`/`m_l` are declared *"multiplier
input latches"* (`upd6383.h:451`) and are currently written by nothing on the
main path — a declared register with no writer is exactly the hole a 23.7 %
undecoded code could fill.

**Against, and it is a strong argument.** The biquad's **w6** (`212.A.01.412`,
class A, `SRC 0x10 acc`, `ACT 0x12`) must multiply `acc` — it is the `b₀` tap. If
only `ACT 0x15` latched, w6's multiply would consume the *stale* latch left by w5
and the section would break. So C2 requires `0x12` to latch as well — at which
point `0x12` and `0x15` are the same operation again and C2 explains nothing that
C1 does not. ⚠ Also relevant: `LEDGER.md` dead end #10 already **REFUTED** mask
bits 54 and 54+4, the two gates that route a latch into the multiplier.

### C3 — `ACT 0x15` writes a register nothing in the corpus reads back (`ACCB`, an output port)   RANK 3

Compatible with everything and predicts nothing. Recorded so it is not
re-proposed; **not** worth a run until C1 and C2 are settled.

### C4 — `ACT 0x15` is `P ← bus` (a second spelling of `0x0E`)   RANK 4

Not refuted by the biquad: on a class-A word the multiply overwrites `P` in the
same word (the ACTION runs *before* the multiply), and at the class-8 w11 the
value is discarded by w13's `acc ← P`. But 419 of the 548 executable `0x15` words
are class A, so the code would be a no-op on **76 %** of its own occurrences —
and `ACT 0x0E` already means `P ← bus` and is the most fetch-*depleted* code in
the corpus (0.03×), i.e. the two are in perfect complementary distribution
*because* `0x0E` is the non-multiply spelling. Keep, rank low.

### C5 — `ACT 0x15` enables the multiply   ⛔ REFUTED

The biquad's w5, w6, w8 and w12 are class-A words *without* `ACT 0x15` and all
four must multiply (§4.2, last row). Dead.

### C6 — `ACT 0x15` writes `tempA` / `tempB` / the accumulator / `mem[ptr]`, moves the pointer or the cursor, or rescales the product   ⛔ REFUTED

§4.1–§4.2.

---

## 9. Three experiments, each with a two-sided criterion

All three are for the main loop; **none was run here**.

### E1 — the known-answer control for §4  (emulator, ~20 min)

*Purpose: prove that the PARAMETRIC EQ vehicle can SEE a side effect on
`ACT 0x15`, so that §4's exclusion is a measurement and not an assumption.*

Add one speculative mask bit that makes `ACT 0x15` execute `m_ta = L` (i.e.
`0x13`'s effect). Select PARAMETRIC EQ (⚠ §126: it is **not** the default effect —
it must be selected and running, §127's three pre-registered checks first), and
run the existing transfer-function harness (`peq_tf.py` / `peq_ab.py`) against
the control.

* **PREDICT (mine):** the fit degrades from 0.198 dB to **> 3 dB** peak
  |Δ| somewhere in the band, because both `z⁻²` branches lose their state shift.
* **REFUTED IF:** peak |Δ| **< 0.5 dB**. That would mean the biquad cannot
  observe a `tempA` write at all, §4 is over-claimed, and the whole exclusion set
  of §4.2 must be withdrawn.
* Fired-count guard: the gate must fire ≥ 3 × (sections executed) per frame, or
  the run says nothing (rule: an absolute count is not a falsifier — pre-register
  the *ratio* to the section count, §161).

### E2 — re-measure §169 at the right word   ★ HIGHEST VALUE  (emulator, ~30 min)

*Purpose: this is the experiment that decides what the LFO work does next, and it
needs no code change at all — only instrumentation.*

Arm nothing. Instrument, at the **offset −3 word of §171's 46-site family** —
in CHORUS that is `202.A.07.1D5` (**w28**), *not* the class-6 word: the
execution count, `m_mul_issued`, the two multiply operands (`coef` and
`L`), and `m_p` **immediately after** the word. Cold boot, notes playing (rule
12 — a DSP test with no notes is not a test), traces armed by frame count.

* **PREDICT (mine):** the word executes ~1.13 M times, `m_mul_issued` fires on
  every one, and `m_p` is **non-zero at least once**. ⇒ §169 §2 is retracted and
  `ACT 0x15` is not the LFO blocker.
* **REFUTED IF:** the execution count is 0 (the word is not on the path — then
  §169 is right for a *different* reason and the frame walk is the defect), or
  `m_mul_issued` never fires at that word (then the ACTION *is* in the gate
  somewhere I did not find, and A is wrong).
* **The diagnostic split, pre-registered:** if the multiply issues but `L == 0`,
  the defect is the **D-RAM pointer** — §168's addressing diagnosis, and the next
  task is `m_dp` at w28, not the ACTION field. If `coef == 0`, the defect is the
  **coefficient cursor** and the next task is §130's per-unit rebase. Either
  branch is a decision; neither is an absence.

### E3 — the falsifier for C1: search `ACT 0x15` instead of assuming it  (offline, ~10 min)

*Purpose: C1 is the status quo, and a hypothesis that cannot lose is not a
hypothesis. This is how it loses.*

Re-run `dsp/tools/r1_allpass_solve.py singledelay` with **`ACT 0x15` added to the
free variables**, over the same 35-effect space (`acc` op ∈ {none, `+bus`,
`−bus`, `←bus`, `←bus−acc`} × capture ∈ {none, `tA←bus`, `tB←bus`, `tA←acc`,
`tB←acc`, `M←bus`, `M←acc`}). SINGLE DELAY carries `ACT 0x15` on **18** of
its 48 words (37.5 %, the highest share of any image) including three consecutive class-A words in each of four MAC
chains, and its algorithm is not in doubt.

* **PREDICT (mine):** `('', '')` — no effect — is among the survivors, and every
  surviving `0x15` effect is confined to registers the block does not read back.
* **REFUTED IF:** `('', '')` has **zero** survivors. Then `ACT 0x15` is *not*
  inert, C1 is dead, and the survivor set names the alternatives directly. This
  is the only experiment here that can promote C2/C3/C4 over C1.
* Positive control: the same run must still reproduce `action-field.md` §6's
  5 145 survivors when `0x15` is pinned back to no-op, or the harness changed
  and the run is void.

**Order:** E2 first (it is free and it redirects the LFO work), then E3 (offline,
cheap, and it is the one that can overturn the ranking), then E1 only if E3 comes
back non-trivial.

---

## 10. SPECULATIVE — recorded, not claimed

Clearly marked; none of this is used above.

* **S1.** The ACTION field may be a **destination register index in the same
  5-bit namespace as `SRC`**. Three anchors agree — `ACT 0x07` = `mem[ptr]` and
  `SRC 0x07` = `mem[ptr]`; `ACT 0x19` = tempA and `SRC 0x19` = tempA; `ACT 0x1A`
  = tempB and `SRC 0x1A` = tempB — and the two `0x19`/`0x1A` destinations are the
  ones `upd6383d.h` itself says are **NOT MEASURED**, so this would *supply* them
  rather than assume them. It fails on `ACT 0x13` (`SRC 0x13` is the class-6
  table read port, §162) and on `ACT 0x00`. Under S1, **`ACT 0x15` is a register
  that is never used as a source** — i.e. write-only. `SRC 0x15` does not occur
  in the corpus. **SPECULATIVE**; the null (how many random 5-bit assignments
  would score 3 of 6?) has not been computed.
* **S2.** `0x12`/`0x13` and `0x14`/`0x15` are bit-0 pairs, and the *odd* member
  of every observed pair is the high-count one (`0x07`:455 vs `0x06`:1;
  `0x0D`:203 vs `0x0C`:14; `0x15`:707 vs `0x14`:58; `0x03`:54 vs `0x02`:2). If
  ACT bit 0 were a modifier rather than part of an opcode, `0x15` would be
  `0x14`'s modified form — which §4 refutes for any modifier that preserves the
  `R14` write. **SPECULATIVE and partly refuted**; recorded because the bit
  algebra is the first thing a reader reaches for.
* **S3.** §169 §5's S2 — *"`0x00` and `0x15` are the two halves of one
  operand-order choice"* — gains real support from §3: they are in near-perfect
  complementary distribution on `class4 & 8` (`0x15` 5.95× enriched, `0x00`
  0.41× depleted) and on `SRC 0x00` (0 vs 580). A reading in which `0x00` routes
  the bus to the **adder** and `0x15` routes it to the **multiplier** is exactly
  that shape. ⚠ It is **not** adopted, because the biquad's w6 (`ACT 0x12`) and
  w5 (`ACT 0x13`) must both multiply their bus, so "route to the multiplier"
  cannot be `0x15`'s exclusive job. **SPECULATIVE.**

---

## 11. Reproducing

```
python3 dsp/tools/act15_census.py pop        # the population + the ACTION field
python3 dsp/tools/act15_census.py census     # ACT x {class4, SRC, flags, addr8}, with nulls
python3 dsp/tools/act15_census.py forms      # 168 distinct forms carrying 0x15
python3 dsp/tools/act15_census.py mi         # class-A co-occurrence + mutual information
python3 dsp/tools/act15_census.py pairs      # the minimal pairs and the complement test
python3 dsp/tools/act15_census.py context    # neighbours, runs, lag to the next class-A
python3 dsp/tools/act15_census.py bits       # the bit algebra
python3 dsp/tools/act15_census.py decoded    # alu_decoded() over the 0x15 population
python3 dsp/tools/act15_census.py disc       # 0x12 vs 0x15; the fetch-word default
python3 dsp/tools/act15_census.py known      # PEQ / SINGLE DELAY / CHORUS, field by field
```

Inputs: `original_ROMs/kn5000_subprogram_v142.rom` through
`kn7000_mame/tools/kn5000_dsp_extract.py`, plus `dsp/programs.tsv`. Nothing was
regenerated and no disassembler was touched, so `dsp/verify.py` still reports
**BYTE-MATCH OK**.
