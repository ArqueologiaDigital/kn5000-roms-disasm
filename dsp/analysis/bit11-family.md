# `lo12` bit 11 — the 80-site form the corpus statistics have been mixing in, and what it selects for

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis and the ROM corpus only.

**Why this note exists.** [`output-stage-io.md`](output-stage-io.md) §9 claimed
`ACT 0x04` had a second IC311 site and was therefore *reachable*. **It does
not.** The "second site" carries `lo12` bit 11, and on this chip that bit changes
what `lo12` *is*. Chasing the retraction turned up the family the bit marks:
**80 sites in 27 of the 38 distinct IC311 images**, the most common undecoded
form on the chip, and its distribution across programs is not random.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **CONSISTENT** / **INFERRED** /
**OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ⛔ **RETRACTION of [`output-stage-io.md`](output-stage-io.md) §9's ★ half.** `w73`'s `ACT 0x04` has **no** second IC311 site. `MULTI TAP DELAY w026` = `040.0.00.864` carries **`lo12` bit 11**; `w73` = `E30.C.00.404` does **not**. `alu_decoded()` (`dsp_disasm.py:568`) refuses every bit-11 word *because* `lo12` is not the ALU route there, and [`k3-pointers.md`](k3-pointers.md) item A proves **by construction** that the firmware assembles bit 11 as a **separate flag** (`INC 8, WA` into byte 3's low nibble). Matching the two on `lo12[4:0]` matches a field that is only known to be the ACTION when the flag is clear. **`lo12[4:0] == 0x04` occurs exactly ONCE in the 6344-word IC311 body corpus, and that once is bit-11-set.** | **MEASURED** |
| **B** | ★★ **So BOTH output-stage presentation unknowns are undecidable by comparison**, not one. §9.1's ranking — "pursue `ACT 0x04`, drop `SRC 0x0A`" — is void; neither is reachable that way. | **MEASURED** |
| **C** | ★★★ **The bit-11 form is 123 raw words in FIVE `lo12` shapes — and the raw count is inflated 42-fold by ONE image.** `C63`×54, `839`×42, `8BC`×25, `864`×1, `921`×1. But all 42 `839` sites are **42 slots sharing one 49-word image**, byte-identical in program image, coefficients, program record *and* parameter record. In distinct-image terms the family is **80 sites**: `C63` 53, `8BC` 24, `839` **1**, `864` 1, `921` 1. | **MEASURED** |
| **D** | ★★ **Every image that contains an LFO contains `C63` — 16 of 16.** `lfo_ramp.py sites` finds 29 LFO blocks in 16 images; all 16 carry `C63`. The containment is exact and one-directional. | **MEASURED** |
| **E** | ⛔ **But the COUNTS do not match, and the miss is systematic.** `C63` count == LFO count in **11 of 16**; in the other 5 `C63` is **always greater**, never smaller, and all 5 are the **CHORUS family**. `C63` is **exactly 2** in 20 of its 25 images — which is the shape of a *per-channel* constant, not a per-LFO one. **`C63` is not "the LFO's table read".** | **MEASURED** (a predict-then-check MISS) |
| **F** | ★★ **The 11 images with NO bit-11 word are the linear, unmodulated effects** — ROOM REVERB, GATED REVERB, SINGLE DELAY, COMPRESSOR, PARAMETRIC EQ, AUTO WAH, S.DELAY+S.DELAY, PEQ+S.DELAY, PEQ+COMPRESSOR, MULTI TAP DELAY's siblings — **with one counterexample, ENHANCER**, which is a nonlinear effect and carries none. | **MEASURED** |
| **G** | ★★★ **Twelve NAMED effects ship a program byte-identical to NO OPERATION.** MODULATION DELAY, SLOW ATTACKER, NOISE FLANGER, CEL, CELM, PITCH SHIFTER, PEDAL WAH, HARS EFFECT, STRING, PEDAL WAH+DELAY, DS_D, OVER_D — identical **image, coefficients, program record and parameter record**, and **no IC310 record**. The twelve reverbs prove the shared-image mechanism *can* differentiate (1 program payload, **12** parameter payloads); these 42 slots have **1 and 1**. | **MEASURED** |

---

## 1. The retraction, and why the check was cheap

`w026` and `w73` were matched on `lo12[4:0] == 0x04`. Their `lo12` values are:

```
   w73   E30.C.00.404      lo12 = 0x404      bit 11 CLEAR
   w026  040.0.00.864      lo12 = 0x864      bit 11 SET
```

Three independent things on file say that difference is not cosmetic:

1. `alu_decoded()` **refuses** bit-11 words — `if lo12(w) & 0x800: return False`.
   The project's own decoder declines to read `SRC`/`ACTION` out of them.
2. [`k3-pointers.md`](k3-pointers.md) item A, **PROVEN BY CONSTRUCTION**: the Sub
   CPU assembles the low byte and *then* ORs in bit 11 as a separate flag. It is a
   modifier the writer adds on top, not part of an opcode.
3. In the **register-load family** the same bit demonstrably re-purposes `lo12`
   entirely — there it is `lo_imm`, "`addr8` carries a payload", with `lo12`
   splitting as selector + flag rather than SRC + mode + ACTION.

So the honest count is: **`lo12[4:0] == 0x04` occurs once in 6344 IC311 body
words, in a form whose `lo12` decode is not the ALU route.** `w73` has no twin.

**This is the same defect as the one §9 itself diagnosed, one level down.** §9
corrected a denominator that spanned two *chips*; it then compared two words
across a *form* boundary on the same chip. Restricting the corpus was necessary
and not sufficient — the words also have to be the same kind of word.

## 2. The family, deflated by replication

Raw, over the 6344 non-`c_format` IC311 body words:

```
   lo12   sites   hi12 seen              class   addr8      images
   C63      54    040 x47, 142 x7          0      00          25
   839      42    80B x42                  0      00           1   <- ONE image x42
   8BC      25    880 x18, 040 x6, 050 x1  1/0    30/00        24
   864       1    040                      0      00           1   MULTI TAP DELAY
   921       1    050                      0      00           1   MULTI TAP DELAY
```

★ **`839` is not the second-most-common shape. It is a single word.** All 42
slots carry the same 49-word image *and the same coefficient vector*, so the raw
census counts one instruction forty-two times. **In distinct images the family is
80 sites, not 123**, and `839` ranks last, tied with the two `MULTI TAP DELAY`
singletons.

That is method rule 9 again, in its third distinct guise this week: first the
denominator spanned two chips, then it spanned two forms, and here it counts
**replicated slots as independent evidence**.

## 3. What the family selects for

Grouping the 38 distinct IC311 images by which shapes they contain:

```
   {8BC, C63}   23 images   CHORUS, MODULATED CHORUS, FLANGER, PHASER, ENSEMBLE,
                            ROCK ROTARY(=ROTARY SPEAKER), DISTORTION, OVERDRIVE,
                            FUZZ, EXCITER, AUTO PAN, VIBRATO, RING MODULATOR,
                            S.DELAY+{FLANGER,VIBRATO,PHASER}, PEQ+{CHORUS,FLANGER,
                            VIBRATO}, PEQ+COMPR+{DIST,OVERDR}, PEQ+{DIST,OVERDR}+DELAY
   {C63}         2 images   MIX UP, S.DELAY+CHORUS
   {8BC}         1 image    AUTO WAH+S.DELAY
   {864, 921}    1 image    MULTI TAP DELAY
   {839}         1 image    NO OPERATION            (x42 slots)
   {none}       10 images   ROOM REVERB (x12 slots), ENHANCER, GATED REVERB,
                            SINGLE DELAY, COMPRESSOR, PARAMETRIC EQ, AUTO WAH,
                            S.DELAY+S.DELAY, PEQ+S.DELAY, PEQ+COMPRESSOR
```

**The split is a clean one: everything that modulates or distorts is on one side,
everything linear and unmodulated on the other.** The 25 `C63` images are every
chorus/flanger/phaser/vibrato/pan/rotary/ring-mod **plus** every
distortion/overdrive/fuzz/exciter. The 10 `{none}` images are reverb, delay, EQ,
compressor and auto-wah.

⛔ **ENHANCER is the counterexample** and it is named, not buried: a harmonic
enhancer is nonlinear and carries no bit-11 word. Whatever the family is, it is
not simply "this program needs a nonlinearity".

### 3.1 The LFO test — containment holds, counting fails

The natural hypothesis, and the one the corpus can actually score, is that `C63`
reads the **sine table** that turns the LFO's ramp into a waveform. The LFO is a
known context: [`lfo_ramp.py sites`](../tools/lfo_ramp.py) locates 29 blocks in 16
images.

**Containment: 16 of 16.** Every LFO-bearing image carries `C63`.

**Counting: 11 of 16.**

```
   image              C63   LFO           image              C63   LFO
   FLANGER              2    2   =        CHORUS               2    1   MISS
   PHASER               2    2   =        MODULATED CHORUS     3    2   MISS
   AUTO PAN             2    2   =        ENSEMBLE             4    1   MISS
   VIBRATO              2    2   =        S.DELAY+CHORUS       2    1   MISS
   RING MODULATOR       2    2   =        PEQ+CHORUS           2    1   MISS
   MIX UP               3    3   =
   S.DELAY+{FLA,VIB,PHA} 2   2   =  (x3)  DISTORTION           2    0   no LFO
   PEQ+{FLANGER,VIBRATO} 2   2   =  (x2)  FUZZ / OVERDRIVE     2    0   no LFO
```

★ **The miss is one-directional — `C63` ≥ LFO in all 16, never below — and all
five misses are the CHORUS family.** Combined with `C63 == 2` in 20 of 25 images,
including every image with **zero** LFOs, the count behaves like a **per-channel**
quantity (stereo) rather than a per-LFO one. ENSEMBLE at 4 and MIX UP at 3 are
then the multi-voice cases.

**So `C63` is not the LFO's table read.** Containment being perfect while counting
fails is exactly the signature of a *co-occurrence*: `C63` is in every LFO program
because it is in every program of that whole class, not because the LFO uses it.

## 4. The twelve stubs

`{839}`'s 42 slots are byte-identical at every level the host can address. The
comparison that makes this conclusive is the **twelve reverbs**, which share one
133-word image and are unmistakably twelve different effects:

```
                                    program-record payloads   parameter-record payloads
   the 12 reverbs   (one image)              1                        12
   the 42 slots     (one image)              1                         1
```

★ **The reverbs prove the shared-image mechanism exists and works. The 42 slots
demonstrably do not use it.** Their program image, coefficient vector, program
record and parameter record are one and the same object, forty-two times.

Twelve of those slots carry real effect names — **MODULATION DELAY, SLOW ATTACKER,
NOISE FLANGER, CEL, CELM, PITCH SHIFTER, PEDAL WAH, HARS EFFECT, STRING,
PEDAL WAH+DELAY, DS_D, OVER_D** — and none carries an IC310 (`0x30`) record, so
they are not implemented on the second DSP either.

### 4.1 What this does NOT establish

* That the user can *select* them. The UI parameter-list capture is partial — it
  lacks `NO OPERATION` itself — so absence from it proves nothing. **`SLOW
  ATTACKER` IS present in the capture**, which makes it the one case where a
  user-selectable effect is confirmed to carry the NO OPERATION program.
* That the real instrument is silent on them. It is possible these names are
  reached through a path that substitutes another algorithm, or that they are
  vestigial names never wired to the effect menu.

### 4.2 ★ A hardware-testable prediction — for Felipe

**Select `SLOW ATTACKER` on the real KN5000 and it should be indistinguishable
from no effect at all.** If it audibly does something, this section is wrong and
the algorithm-selection path substitutes a program the algorithm table does not
name. Owner testimony is ground truth here and this is a one-minute test.

## 5. Predict-then-check

- **P1 HIT.** I predicted, before running it, that the replication check would
  deflate at least one group — the 12 reverbs on one image made that the obvious
  hazard. It removed 41 of 42 `839` sites.
- **P2 MISS.** I predicted `C63` count would equal LFO count. 11 of 16, and the
  residual is structured (item E). The hypothesis is refuted, not weakened.
- **P3 unforeseen.** I did not expect the family to *partition the effect
  catalogue by signal-processing class*, nor to find twelve named stubs on the way.

## 6. What the next pass needs

1. ★ **`C63` is now the highest-value undecoded form on the chip** — 53 sites in
   25 of 38 images, against `ACT 0x0D`'s 76 shapes with no anchored pair and the
   presentation codes' one site each. [`dark-words.md`](dark-words.md) §4.4 sees
   it as **2 slots** of one frame's Group E; corpus-wide it is the single most
   common thing this chip does that we cannot read.
2. **`8BC` co-occurs with `C63` in 23 of 24 of its images** and is *exactly one*
   per image. A once-per-program word alongside a twice-per-program one is the
   shape of **setup + per-channel use**. That pairing is testable against the
   pointer state, which is decoded.
3. ⛔ **The reverb does not contain a single bit-11 word.** None of this touches
   the reverb's remaining unknowns, and nothing here should be spent on it.
4. **Do not re-run the presentation-code comparison.** Item B closes it: `w73` and
   `w78` each have one IC311 site in their own form, and the corpus cannot decide
   either.

---

## 7. Can anything decide this family? A decidability census — two routes closed, one open

Item 6 ranked `C63` "the highest-value undecoded form". That ranking was by
**frequency** and it skipped the question this project exists to ask first: *is
there any instrument that could score it?* Three routes, tested before any search
was written.

### 7.1 ⛔ Both known-mathematics contexts are blind to the whole family

* **The LFO: 0 of 29 block windows contain a bit-11 word.** Identical verdict to
  the one [`three-codes.md`](three-codes.md) §1.2 reached for `0x0D`/`0x0E`/`0x1A`.
* **PARAMETRIC EQ carries no bit-11 word at all** — it is a `{none}` image (§3).

So the two contexts on this chip whose output is known as a number **cannot see a
single one of the family's 80 sites.** No acceptance test can be built on either,
and one should not be attempted.

### 7.2 ⛔ No minimal pair across the flag — 0 of 8

For each of the 8 distinct bit-11 words, the same 36 bits with bit 11 **cleared**:

```
   080B000839  ->  080B000039   present 0 times
   08801308BC  ->  08801300BC   present 0 times
   0040000C63  ->  0040000463   present 0 times
   0142000C63  ->  0142000463   present 0 times
   00400008BC  ->  00400000BC   present 0 times
   00500008BC  ->  00500000BC   present 0 times
   0040000864  ->  0040000064   present 0 times
   0050000921  ->  0050000121   present 0 times
```

**Zero of eight.** The flag cannot be isolated by whole-word comparison either.

### 7.3 ★★ But there IS a controlled comparison — the `w000` slot

**`w000` is a fixed structural slot.** 28 of the 38 distinct images begin with
`880.1.<30|60>.<lo12>` — a delay-DRAM access — and `lo12` there is one of exactly
two values:

```
   880.1.30.8BC   x17    CHORUS, MODULATED CHORUS, PHASER, ROCK ROTARY, EXCITER,
                         AUTO PAN, S.DELAY+{FLANGER,VIBRATO,PHASER}, AUTO WAH+S.DELAY,
                         PEQ+{CHORUS,FLANGER,VIBRATO}, PEQ+COMPR+{DIST,OVERDR},
                         PEQ+{DIST,OVERDR}+DELAY
   880.1.30.00B   x10    NO OPERATION, ENHANCER, FLANGER, GATED REVERB, SINGLE DELAY,
   880.1.60.00B   x 1    MULTI TAP DELAY, ROOM REVERB, MIX UP, S.DELAY+S.DELAY,
                         PEQ+S.DELAY, ENSEMBLE
```

Same `hi12`, same `class4`, same `addr8`, same position, same program role — 27 of
them differing in **nothing but `lo12`**. ★ **This is the only controlled
comparison the bit-11 family has, and it is far stronger than any of the
whole-corpus statistics above**, because position and surrounding role are held
fixed by construction rather than by argument.

### 7.4 ⛔ And the descriptor is NOT what differs — the addressing hypothesis is dead

[`dram-cursor-closure.md`](dram-cursor-closure.md) §3.5 already resolves both
words to a delay descriptor cell:

```
   880.1.30.8BC   x18   ->  {0x26}
   880.1.30.00B   x63   ->  {0x00, 0x26}
```

★ **Both read cell `0x26`.** (`00B`'s second base, `0x00`, is the twelve reverbs',
and §3.5 flags that clash as its own falsification of `V-word`.) So the bit-11
choice at `w000` does **not** select a different delay descriptor, a different
base, or a different cell.

**That removes the entire addressing hypothesis space.** Whatever distinguishes
the two is on the **routing/ALU side**, not the addressing side — which is a real
narrowing, and it came from a note already on file rather than from a new search.

### 7.5 One `lo12`, two unrelated host words

`8BC` also occurs in a **non-DRAM** shape: `040.0.00.8BC` ×5 (DISTORTION,
OVERDRIVE, FUZZ, VIBRATO, RING MODULATOR) and `050.0.00.8BC` ×1 (ENSEMBLE), with
`class4 = 0` and no DRAM role at all.

**The same `lo12` therefore rides on two structurally unrelated words.** That is
exactly what [`k3-pointers.md`](k3-pointers.md) item A's "assembled as a separate
flag" predicts, and what any single-instruction reading of `0x8BC` forbids.

### 7.6 And the split is not the LFO

FLANGER, MIX UP and ENSEMBLE all contain LFO blocks and all take the `00B` side of
the `w000` pair. Consistent with item E: `C63`'s and `8BC`'s distribution
correlates with the effect class, not with the presence of an oscillator.

---

## 8. Revised handover — §6 item 1 corrected

§6 ranked `C63` first on frequency. With §7 measured, the ranking changes:

1. ★ **The `w000` pair is the tractable object, and it is `8BC`, not `C63`.** 27
   images, one held-fixed slot, one held-fixed descriptor cell, one free field.
   Its **addressing is already excluded** (§7.4), so the question is narrowed to
   what the word routes.
2. **`C63` remains the most FREQUENT undecoded form** — 53 sites, 25 of 38 images —
   but it has no controlled comparison and no scoring context. Frequency is not
   tractability, and §6 item 1 conflated them.
3. ⛔ **Do not build an acceptance test on the LFO or the biquad for anything in
   this family.** Measured blind: 0 of 29 windows, and no site at all in the EQ.
4. ⛔ **Do not look for a bit-11 minimal pair.** 0 of 8, measured.

---

## 9. ★★★ `lo12` bit 11 SELECTS A SECOND ENCODING — and five "codes" therefore do not exist

§7.3 identified the `w000` pair as the only controlled comparison. Enumerating
what could differ there — addressing excluded (§7.4), direction excluded
(`dram_dir` is a function of `addr8` alone, and both words carry `0x30` = READ),
`hi12` identical — leaves the difference **entirely inside `lo12`**. Three readings
were on the table:

* **(i)** `lo12` is the ALU route on these words too → `0x8BC` = SRC `0x02`,
  ptrmode 1, ACT `0x1C`.
* **(ii)** bit 11 switches `lo12` to a **different encoding**, as it demonstrably
  does in the register-load family.
* **(iii)** bit 11 is an independent modifier on an otherwise-ALU `lo12`.

Two measurements decide between them.

### 9.1 Bits 11 and 5 co-vary — 80 of 80, and the single exception is a proven-different family

```
   over 2917 non-c-format words in the 38 distinct IC311 images

                       bit 5 SET     bit 5 CLEAR
      bit 11 SET            80             0
      bit 11 CLEAR           1          2836
```

★ **Every bit-11 word has bit 5 set; no bit-11 word has it clear.** Under (i) or
(iii), bit 5 is the pointer mode — an *independent* field — and there is no reason
for all 80 to agree.

The lone off-diagonal cell is `algo 39 PARAMETRIC EQ w058 = 801.0.00.021`, and it
is **`is_regload` — the cursor reset**, named in [`k3-pointers.md`](k3-pointers.md)
item K as one of only two body words in the whole `0x_2x` selector block. In that
family `lo12` is **PROVEN BY CONSTRUCTION** to be selector + flag rather than
SRC/mode/ACTION, so bit 5 there is part of the *selector*. **Excluding the one
family whose `lo12` encoding is already known to be different, the co-occurrence is
exceptionless.**

### 9.2 The ALU reading needs five field values attested nowhere else

Parsing the five bit-11 shapes as SRC/mode/ACTION triples:

```
   lo12   would be                                   attested among the 2836 bit-11-CLEAR words
   8BC    SRC 0x02, ptrmode 1, ACT 0x1C              SRC 0x02: 0x     ACT 0x1C: 0x
   C63    SRC 0x11, ptrmode 1, ACT 0x03              SRC 0x11: 70x    ACT 0x03: 0x
   864    SRC 0x01, ptrmode 1, ACT 0x04              SRC 0x01: 35x    ACT 0x04: 0x
   921    SRC 0x04, ptrmode 1, ACT 0x01              SRC 0x04: 0x     ACT 0x01: 36x
   839    SRC 0x00, ptrmode 1, ACT 0x19              SRC 0x00: 598x   ACT 0x19: 87x
```

**Four of the five require a field value that occurs nowhere else in the corpus**,
and all five require the ptrmode that §9.1 shows is not free. Reading (ii) explains
every one of those facts with a single rule; (i) and (iii) must post-hoc admit five
codes that appear only, and exactly, where the flag is set.

★★★ **`lo12` bit 11 selects a second `lo12` encoding. On bit-11 words there is no
SRC field and no ACTION field**, and bit 5 is part of the alternate form rather
than the pointer mode.

### 9.3 Consequence — five "codes" are parse artefacts

Every site of these is a bit-11 word:

```
   ACT 0x03    54 sites   100% bit-11    (all C63)
   ACT 0x1C    25 sites   100% bit-11    (all 8BC)
   ACT 0x04     1 site    100% bit-11    (MULTI TAP DELAY w026)
   SRC 0x02    25 sites   100% bit-11    (all 8BC)
   SRC 0x04     1 site    100% bit-11    (MULTI TAP DELAY w033)
```

⛔ **`ACT 0x03`, `ACT 0x04`, `ACT 0x1C`, `SRC 0x02` and `SRC 0x04` do not exist.**
They are what you get by applying the bit-11-clear encoding to bit-11 words. This
independently explains [`output-stage-io.md`](output-stage-io.md) §10's retraction
from the other direction: `ACT 0x04` had no anchored pair and no context **because
it is not an action**.

### 9.4 Partial contamination — the denominators that move

```
   SRC 0x11    231 sites,  54 bit-11  (23.4%)  -> 177     (the C63 words)
   ACT 0x19    425 sites,  42 bit-11  ( 9.9%)  -> 383     (the 839 word x42)
   SRC 0x00   1653 sites,  42 bit-11  ( 2.5%)  -> 1611
   ACT 0x01     40 sites,   1 bit-11           -> 39
   SRC 0x01     39 sites,   1 bit-11           -> 38
```

★ `ACT 0x19` is `LO_ACT_CAP_TA2`, whose semantics ship on the owner's 2026-07-27
decision. **Its count falls from 425 to 383.** No semantics change — the 42 removed
sites are 42 replicas of one word in one image (§2) — but the published figure was
wrong twice over, by replication and by form.

### 9.5 ★ And the codes under active investigation are CLEAN

```
   ACTION with ZERO bit-11 contamination:
      0x00 0x07 0x08 0x0B 0x0C 0x0D 0x0E 0x11 0x12 0x13 0x14 0x15 0x16 0x1A 0x1D
```

**Every code this project has been trying to decode — `0x0D`, `0x0E`, `0x1A`,
`0x0B`, `0x00` — is uncontaminated.** [`three-codes.md`](three-codes.md)'s counts,
the `ACT 0x0B` work and the `ACT 0x00` LFO adjudication are untouched by this. The
contamination is confined to codes that turn out not to be codes.

## 10. Predict-then-check

- **P4 HIT.** §8 predicted the option space at `w000` was "small enough to
  enumerate rather than search". Three readings, two measurements, one survivor.
- **P5 unforeseen.** I expected to *narrow* `8BC`'s meaning. Instead the
  enumeration removed the question's premise: there is no ACTION field to decode.
- **P6 residue.** What the alternate encoding *means* is still **OPEN**. §9 says
  what `lo12` is not on 80 words; it does not say what it is.

## 11. Handover

1. ★ **The alternate `lo12` encoding is the object now.** 80 words, 5 shapes, and
   the `w000` pair (`8BC` vs `00B`, 27 images, same slot, same descriptor cell,
   same direction) is still the controlled comparison — but the question is now
   "what does the alternate form encode", not "which ACTION is this".
2. ⛔ **Delete `ACT 0x03/0x04/0x1C` and `SRC 0x02/0x04` from any working ISA table.**
   `dsp_disasm.py` now carries `alt_lo12()` and `PHANTOM_ACT`/`PHANTOM_SRC` so the
   parse cannot be re-applied silently.
3. **Restate `SRC 0x11` as 177 and `ACT 0x19` as 383** wherever they are published.
4. ⛔ Still no scoring context (§7.1) — this was decided by *enumeration and
   parsimony*, not by an acceptance test, and it is labelled accordingly.
