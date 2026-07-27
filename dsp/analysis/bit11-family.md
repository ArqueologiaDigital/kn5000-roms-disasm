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
