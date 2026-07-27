# `ACTION 0x00` — the fourth context, and why there is not one

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus and constraint solving only.

Tool: [`../tools/action00_discriminate.py`](../tools/action00_discriminate.py) —
standard library only, re-runnable, and it prints **every number quoted below**:

```
python3 dsp/tools/action00_discriminate.py control   # ★ RUN FIRST -- can the tests say NO?
python3 dsp/tools/action00_discriminate.py census    # ★ the DECIDABILITY census
python3 dsp/tools/action00_discriminate.py biquad    # the biquad, INDEPENDENT criterion
python3 dsp/tools/action00_discriminate.py lfo       # the 29 LFO blocks, WIDENED space
python3 dsp/tools/action00_discriminate.py single    # SINGLE DELAY, two windows
python3 dsp/tools/action00_discriminate.py sdmix     # ... and with a NON-ZERO input mix
python3 dsp/tools/action00_discriminate.py joint     # ★ the intersection  (~15 min)
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** (every survivor of
an exhaustive search agrees) / **CONSISTENT** / **FALSIFIED** / **OPEN**.

**Nothing here is applied to the MAME device and neither disassembler was
touched.** No word gains or loses an executable semantic in this pass, every
currently-trapping word still traps, `dsp/verify.py` is **BYTE-MATCH OK**, and
the rendered audio cannot have moved. §10.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE 18/18 FORCING OF `ACTION 0x00 = load` IS FALSIFIED, AND THE CAUSE IS A GATE NOBODY ENUMERATED.** Re-run in a space that differs from `acc-adder.md`'s in exactly one place — a bit-7-suppressed store whose **CLEAR is deferred to the end of the word** — the three-context joint solve has **33** survivors and `act00` takes **three** values: `load` ×15, `add` ×12, `rload` ×6. | **MEASURED** |
| **B** | ★ **THE MIRROR CHECK SAYS THE MODEL IS NOT THE DIFFERENCE.** Restricted to `acc-adder.md`'s own sub-space (5 `act00` values, 4 gates) this tool returns **9** survivors, **all** `adder / load / before`, over the **same three gates and three wraps** it published; and the LFO stage returns **1224**, its published number, to the digit. The factor 2 between 9 and 18 is `op2` alone, which the independent criterion of **F** resolves. So the only thing that moved `load` off FORCED is the sixth gate. | **MEASURED** |
| **C** | ★★★ **THE TWO OPEN QUESTIONS ARE ONE QUESTION.** In all 33 survivors `act00` and the store gate are **locked together**: `add` and `rload` occur **only** with a gate in which a suppressed store still clears, *late*; `load` occurs with any of five. "Is `ACTION 0x00` a load or an add?" **is** "does a bit-7-suppressed store clear the accumulator, and when?" — one bit, **130** corpus words. This is the same shape as the adder adjudication: a contradiction that dissolved because a *shared assumption* was wrong. | **FORCED** (33/33) |
| **D** | ★★★ **THE DECIDABILITY CENSUS — AND IT IS WHY THREE PASSES FAILED.** On an `ACTION 0x00` word with `hi12[3:1] == 0` the two readings are **IDENTICAL BY CONSTRUCTION** (`load` gives `bus + P`, `add` gives `0 + P + bus`). **257 of 806** corpus `ACTION 0x00` words are blind for that reason or because `hi12[3:1] > 2`; of the remainder only **359** can bear a difference at all, and **221** carry it to an observable. ★ **ZERO of those 221 are in PARAMETRIC EQ or SINGLE DELAY** — the only two programs whose arithmetic is known independently of the DSP. **A FOURTH CONTEXT WITH KNOWN MATHEMATICS DOES NOT EXIST IN THE CORPUS.** The one known-mathematics discriminator is the LFO, which is context three. | **PROVEN BY CONSTRUCTION** + **MEASURED** |
| **E** | **SINGLE DELAY IS BLIND to `load` vs `add` and always was.** Its `ACTION 0x00` word `000.2.48.000` has `hi12[3:1] == 0`; the census gives it **0** discriminating sites; and its own solve leaves `act00` at four values (`add` 36, `sub` 36, `load` 18, `rload` 18) in **both** windows. The biquad is blind too — it carries **no** `ACTION 0x00` word (MEASURED: its ACTION codes are `07 12 13 14 15`). **The published "three-context" forcing of `load` was a one-context forcing with a store-timing pin.** | **MEASURED** |
| **F** | ★ **THE BIQUAD, RE-SCORED AGAINST ITS OWN DESIGNER INSTEAD OF AGAINST THE SHIPPED MODEL, UPHOLDS THE STORE TIMING.** `acc_adjudicate.py` scores the section by **bit-identity with the shipped ALU**, which is a conservatism test and can only reject; here it is scored against the transfer function the firmware's bilinear designer computes, on **11 real coefficient banks**. `sttime = before` is still **FORCED**, 24/24, and `store early / clear late` is rejected at **51.090 dB** — not merely "different". New: `op2 = hold` is **FORCED** (`AND 2^23−1` fails), and **all six gates pass**, so the section's blindness to the gate is *measured* rather than assumed. | **MEASURED** |
| **G** | ★ **AN ENUMERATED RECONCILING MECHANISM, TESTED AND FALSIFIED.** `bsel` — `ACTION 0x00` replaces the **product** term rather than the accumulator feedback, i.e. a MAC adder with a selector on *each* input, which is precisely the shape the last contradiction turned out to have — survives the LFO (72 machines) and dies in SINGLE DELAY: **0 of 5832**, in every window and every mix setting. | **FALSIFIED** |
| **H** | ★ **`SRC 0x00 = mem[ptr]` IS NOT FORCED; IT IS FORCED *GIVEN THE LOADED COEFFICIENTS*.** MEASURED: the corpus holds **23** instances of the SINGLE-DELAY motif, and in **20** of them every class-A word in the three slots before the DRAM read — the words that could build an input **mix** in the accumulator — multiplies by exactly **0.0000** in the ROM-loaded C-RAM image, while the feedback word multiplies by 0.5000 (20 of 23; the other three are 0.9991, 0.9629 and 0.0000). Give those words a non-zero gain — which the host's parameter writer can do at run time (`kn5000-dsp-parameters.md` §2) — and `SRC 0x00`'s marginal goes from **FORCED `mem` 108/108** to **`mem` 108 / `acc` 108**. | **MEASURED** |
| **I** | **`SRC 0x00` is a REAL source, and it is not the delay-RAM register.** `zero` has **0** survivors and `DR` has **0**, in every SINGLE DELAY variant tried (both windows, both mix settings). So the tempting "`lo12 == 0x000` is a null routing" reading — which the encoding census supports (**572 of 599** `SRC 0x00` words are exactly `lo12 == 0x000`, and `SRC 0x00` pairs with `ACTION 0x00` in 572 of 599) — is **FALSIFIED** by the one block that needs it to carry data. | **FORCED** / **FALSIFIED** |
| **J** | ★★ **NEITHER OF THE BRIEF'S "TWO LIVE CONTRADICTIONS" IS A CONTRADICTION BETWEEN TWO BLOCKS.** Both are a **conditional whose antecedent is independently false** set against an unconditional determination. The reverb "REQUIRES `SRC 0x00 = DR`" (52 696/52 696) and "REQUIRES `ACTION 0x00` to keep the accumulator" (9520 of 9660) are *necessary conditions of the first-order all-pass hypothesis*, and that hypothesis has **0 survivors of 20 580 000, twice, under two different accumulator models**, with the obstruction located in the write (`allpass-adder-rerun.md` §6.3). A necessary condition of a refuted premise is not evidence. **They share a root cause, and the brief's item 4 is answered: yes.** | **FORCED**, from published counts |
| **K** | And the widened space **strengthens** that falsification rather than weakening it: the all-pass's preferred reading is `−bus` (9520 of 9660), and **`sub` has 0 survivors in the LFO** and is absent from all 33 joint survivors. Even with `load` un-forced, the reverb core still cannot be a first-order all-pass. | **MEASURED** |
| **L** | Housekeeping: `dsp/verify.py` **BYTE-MATCH OK**; no `.dsm` regenerated; no device or disassembler file touched; the DSPCFG-off audio is untouched **by construction** (no code that runs in the emulator was modified). | **MEASURED** |

---

## 1. Why a "fourth context" was the wrong thing to look for first

The brief names the fourth context as the highest-value experiment left. Before
hunting for one it is worth asking which words in the corpus **could** be one,
and that question has an exact, cheap answer.

Write `DELTA = acc_add − acc_load`. Under the adder (the reading the joint solve
forced and the one that ships):

```
   load :  acc  <-  bus           +  P·[f31 != 2]
   add  :  acc  <-  FB(f31) + bus +  P·[f31 != 2]      FB = 0 if f31 == 0 else acc
```

so on an `ACTION 0x00` word

* `hi12[3:1] == 0` → **the two readings are the same expression**. `DELTA` cannot
  even be born. *(This is exact under `adder` and under `act_first`; under
  `act_last` it does not hold, and SINGLE DELAY already refuses `act_last` +
  `load` — its 108 survivors put `load`/`rload` only on `adder`.)*
* `hi12[3:1] > 2` → the word is not decoded and traps.
* the word's **own** bit-4 store clears the accumulator before its ALU step →
  the entering accumulator is 0 and again `DELTA = 0`.

`DELTA` then propagates forward until something kills it (`hi12[3:1] == 0`, or a
clear) or observes it (a bit-4 store, a `SRC 0x10` read of the accumulator, the
end of the body — the output stage presents the accumulator, `output-stage-decode.md`
item H).

```
   ACTION-0x00 words in the 38 distinct body images : 806
      by hi12[3:1] : 0:152  1:472  2:77  3:20  4:29  5:43  6:1  7:12
      BLIND BY CONSTRUCTION (hi12[3:1] == 0 or > 2)                : 257
      can BEAR a difference (gate b7_f31_1_off)                    : 359
         of those, DELTA reaches an observable                     : 221   (35 programs)
         killed before it does                                     : 138
```

**★ And the distribution is the result.** Of the 221, **not one** is in
`algo 39 PARAMETRIC EQ` or `algo 9 SINGLE DELAY`:

```
   algo 39  PARAMETRIC EQ  : 0 site(s) reach an observable
   algo  9  SINGLE DELAY   : 0 site(s) reach an observable
   algo 16  ROOM REVERB 1  : 9 sites -- all of them w20/w28/.../w94  104.2.00.000
                             f31=2, OBSERVED one word later by `SRC 0x10'
```

PARAMETRIC EQ's seven `ACTION 0x00` words, in full:

```
   w2   212.2.00.000  f31=1 b7=0 ST     its OWN bit-4 store clears the accumulator first
   w3   02A.2.00.000  f31=5             undecoded
   w50  028.2.00.000  f31=4             undecoded
   w52  000.2.F7.000  f31=0             `load' and `add' are the same expression
   w55  212.2.02.000  f31=1 b7=0 ST     its OWN bit-4 store clears the accumulator first
   w56  02A.2.00.000  f31=5             undecoded
   w104 428.1.0E.000  f31=4             undecoded
```

Two of the three kinds of blindness, and no fourth. SINGLE DELAY's are all
`hi12[3:1] == 0`.

So the corpus contains exactly **one** block family that (i) can tell the two
readings apart and (ii) has arithmetic known independently of the DSP: the **LFO
ramp**, whose nine increments are each `floor(f · 2^23 / 44100)` for a round
decimal *f*. That is context three. **There is no fourth.** Everything else that
can discriminate sits in a block whose algorithm would have to be
reverse-engineered first — which is the same problem, one level down.

*(Control — the census must be able to say both things. It returns
`SINGLE DELAY w7 000.2.48.000 → BLIND BY CONSTRUCTION` and
`LFO 082.2.00.1C0 → OBSERVED at +1 (bit-4 store writes the accumulator)`, the two
cases whose answers are known from outside it.)*

---

## 2. So what *was* forcing `load`? — the biquad's store timing, and one gate

Given §1, the published 18/18 has to come from the LFO, because the other two
contexts cannot see the parameter. It does, and the mechanism is worth writing
out because it is what the widened space breaks.

```
   092.A.dd.200   f31 = 1, b7 = 1, bit 4        class A, SRC 0x08 (unity)  ACTION 0x00
   082.2.00.1C0   f31 = 1, b7 = 1, no bit 4     SRC 0x07 = mem[Q] = phase  ACTION 0x00
   094.A.dd.200   f31 = 2, b7 = 1, bit 4        class A, SRC 0x08 (unity)  ACTION 0x00  <- publishes
```

`094` stores `phase + INC`, so `082` must produce exactly `phase + INC`.

* under **`load`**: `082` gives `bus + P` = `phase + INC` whatever the
  accumulator was carrying. ✔ — and the accumulator entering it is *irrelevant*.
* under **`add`**: `082` gives `acc + INC + phase`, so the accumulator entering
  it must be **0**. `092` does not store (the gate suppresses it) — so the only
  way for the accumulator to be zero at `082` is for the *suppressed* store to
  still clear, and to clear **after** `092`'s own ALU step (clearing before it
  leaves `0 + P_old`, and `P_old` is the previous, unrelated product).

`acc-adder.md` enumerated four gates. Three of them — `b7_f31_1_off`,
`b7_ne2_off`, `b7_f31_1_keepclear` — clear either not at all or *early*, so
`add` could only be reached by moving the **global** store timing to
`st_before_clr_after`; and the biquad kills that outright. Hence 18/18 `load`.

**The fourth possibility is that the gate changes the clear's TIMING rather than
its presence.** That is not exotic: a store that is inhibited has no reason to
carry the write-port's timing, and `lfo-ramp.md` already found it necessary to
split "suppress the store" from "suppress the clear". Adding

```
   b7_f31_1_clrlate :  (b7, f31) == (1, 1) -> no store, and the CLEAR is taken
                       at the END of the word instead of before the ALU
   b7_ne2_clrlate   :  the same, on the `unless f31 == 2' gate
```

is one line, and it is what this pass adds. The biquad cannot see it — **all 22
of the section's store words have `b7 = 0`** — and neither can SINGLE DELAY.

```
   LFO, 326 592 candidates -> 4416 -> 4416 -> 3312 (the 2**23 wrap)
      act00   4 values   load x1440  add x1080  rload x720  bsel x72
      the (act00, stgate) pairs:
         act00=add    gate=b7_f31_1_clrlate     x432
         act00=add    gate=b7_ne2_clrlate       x432
         act00=add    gate=b7_f31_1_keepclear   x216      <- these need clr-late TIMING
         act00=load   gate=b7_f31_1_off         x288
         act00=load   gate=b7_ne2_off           x288
         act00=load   gate=b7_f31_1_keepclear   x288
         act00=load   gate=b7_f31_1_clrlate     x288
         act00=load   gate=b7_ne2_clrlate       x288
         act00=rload  gate=b7_f31_1_clrlate     x288
         act00=rload  gate=b7_ne2_clrlate       x288
         act00=rload  gate=b7_f31_1_keepclear   x144
         act00=bsel   gate=b7_f31_1_keepclear   x72
   ★ CROSS-CHECK: restricted to acc-adder.md's published sub-space -> 1224
                  (acc-adder.md published 1224)
```

The 216 `add` + `keepclear` survivors are exactly `acc-adder.md`'s 216 — they are
the ones at `sttime = st_before_clr_after`, and the biquad removes them. The
**432 + 432** at the two `clrlate` gates are new, and they are at
`sttime = before`, which the biquad *requires*.

---

## 3. The joint solve, re-run

```
   biquad-admissible 6-tuples : 432        (24 real models x order x act00 broadcast)
   LFO               6-tuples : 414
   SINGLE DELAY      4-tuples : 108        (identical for w5..w9 and w3..w9)
   biquad AND lfo             : 63
   ★ ALL THREE                : 33
      order    2 values  adder x27  act_last x6
      act00    3 values  load x15  add x12  rload x6
      sttime   FORCED    before x33
      stgate   5 values  b7_f31_1_clrlate x12  b7_ne2_clrlate x12
                         b7_f31_1_keepclear x3  b7_f31_1_off x3  b7_ne2_off x3
      op2      FORCED    hold x33
      wrap     3 values  wrap23 x11  f31_2_and_coef x11  b7_and_coef x11
```

and the coupling, which is the point:

```
   act00=add    gate=b7_f31_1_clrlate    x6     act00=load  gate=b7_f31_1_clrlate   x3
   act00=add    gate=b7_ne2_clrlate      x6     act00=load  gate=b7_ne2_clrlate     x3
   act00=rload  gate=b7_f31_1_clrlate    x3     act00=load  gate=b7_f31_1_keepclear x3
   act00=rload  gate=b7_ne2_clrlate      x3     act00=load  gate=b7_f31_1_off       x3
                                                act00=load  gate=b7_ne2_off         x3
```

**Every `add` and every `rload` sits on a late-clearing gate; `load` sits on all
five.** No survivor pairs `add` with a gate that does not clear late, and none
pairs `load` uniquely with anything. That is the whole remaining structure of the
question.

### 3.1 The mirror check, in full

```
   this tool, restricted to acc-adder.md's space (act00 in 5, stgate in 4) : 9
      adder  act00=load  st=before  gate=b7_f31_1_keepclear  op2=hold  wrap={wrap23,f31_2_and_coef,b7_and_coef}
      adder  act00=load  st=before  gate=b7_f31_1_off        op2=hold  wrap={...}
      adder  act00=load  st=before  gate=b7_ne2_off          op2=hold  wrap={...}
   acc-adder.md sect. 3.4                                                : 18
      order FORCED adder ; act00 FORCED load ; sttime FORCED before
      stgate 3 values (the same three) ; op2 2 values (hold, and_mask23) ; wrap 3 values
```

9 × 2 = 18, and the 2 is `op2`. `acc-adder.md`'s biquad test scored bit-identity
with the shipped ALU, in which the accumulator has **no fractional alignment**
(`P = coef·bus >> 23`); this pass scores against the designer at the alignment
that reproduces it (`ACC_SHIFT = 16`, `P_SHIFT = 6`, total 22 — FORCED elsewhere),
and there `AND 2^23−1` on the class-8 word is no longer the identity and fails.
**Caveat, stated:** "the mask lives in the accumulator's domain" is a modelling
choice; a mask applied to the *datum* rather than to the 44-bit accumulator would
behave as before. `op2 = hold` is therefore FORCED **within the acc-domain
reading of the mask** and not absolutely.

---

## 4. The controls — every test is shown able to say NO

```
   1. the biquad criterion (11 real coefficient banks, DFT at 12 frequencies)
      SHIPPED (store+clear before the ALU)         0.198 dB   accepts   (0.0941 at 4096)
      store and clear AFTER the ALU               84.768 dB   REJECTS
      store early, clear LATE                     51.090 dB   REJECTS
      hi12[3:1] == 2 ANDs the coefficient        999.000 dB   REJECTS   (total failure)
      the store GATE always fires                  0.198 dB   accepts   <- the blindness
                                                                          is MEASURED
   2. the LFO criterion
      the shipped model on algo 1       : is_ramp(inc=114) = True
      the same history, WRONG increment : is_ramp(inc=115) = False
      ACTION 0x00 = `no effect'         : is_ramp        = False
   3. SINGLE DELAY
      108 of 5832 survive -- it rejects 98 % of the space, and it rejects
      `none' and `bsel' outright (0 each)
   4. the census
      SINGLE DELAY w7 -> BLIND BY CONSTRUCTION      (known independently)
      LFO 082.2.00.1C0 -> OBSERVED at +1            (known independently)
```

The fourth row of the biquad control is the one that earns its keep in this
pass: it shows the section really is silent about the gate, so the fact that all
six gates pass is a measurement and not an artefact of the criterion.

---

## 5. `SRC 0x00` — the same treatment, and it moves too

### 5.1 What the encoding says

```
   SRC 0x00 occurs                                : 599 times
      of which lo12 == 0x000 exactly              : 572
      the ACTION on a SRC-0x00 word               : 0x00 x572  0x0B x25  0x19 x1  0x01 x1
   when ACTION == 0x00, the SRC is                : 0x00 x572  0x07 x100  0x08 x66
                                                    0x1C x46   0x1A x22
   words with lo12 == 0x000 exactly               : 572
      of which post-increment by a non-zero delta : 127   (pure pointer moves)
```

```
   distinct ACTIONs ever seen with SRC 0x07 : 00 08 0D 0E 11 13 14 15 1A   (nine)
   distinct ACTIONs ever seen with SRC 0x00 : 00 01 0B 19                  (four,
                                              and 572 of the 599 are `00')
```

`SRC 0x07` — the anchored `mem[ptr]` — appears with nine different ACTIONs.
`SRC 0x00` appears with essentially one. That is what a **null routing**
encoding looks like, and 127 of its words are doing nothing but moving the
pointer. It is a good hypothesis and SINGLE DELAY kills it: `zero` has **0**
survivors, in both windows and at both mix settings. `SRC 0x00` carries data.

### 5.2 What SINGLE DELAY forces, and what that rests on

`acc-adder.md` excises `w5..w9` and deposits *x* in the D-RAM cell `w7`'s
measured pointer walk reads; `SRC 0x00 = mem[ptr]` then comes out at 72/72. Two
things about that were untested:

* the block boundary — `w3` and `w4` are class-A macs that could build an input
  **mix** in the accumulator, which `SRC 0x00 = acc` would then pick up;
* the coefficients — the searcher supplied its own.

Both are now tested. With the block's **own** coefficients:

```
   w3  212.A.01.1D5   coef[0] = +0.000000
   w4  202.A.48.1D5   coef[1] = +0.000000
   w6  202.A.B8.655   coef[2] = +0.500000        <- the feedback
```

and the same holds across the corpus: of the **23** SD-motif instances, **20**
have every class-A coefficient in the three slots before the DRAM read at exactly
`0.0000` (18 of them two such words, 2 of them one), one has a single `0.2500`,
and two have no class-A word there at all; the `…655` feedback word is `0.5000`
in **20 of 23** (`0.9991`, `0.9629`, `0.0000` in the rest). So in the loaded image
the accumulator route is inert, `w3`/`w4` contribute nothing, and the wider window
`w3..w9` returns **exactly** the narrow window's numbers:

```
   w5..w9 (published) : 108 of 5832    src00 FORCED mem x108   act19 FORCED tA<-bus x108
   w3..w9 (wider)     : 108 of 5832    src00 FORCED mem x108   act19 FORCED tA<-bus x108
```

**But the host writes C-RAM at run time** (`kn5000-dsp-parameters.md` §2: the
`801.0.NN.821` pointer-set plus `A??…` datum pair is MEASURED, and the
per-algorithm maps target C-RAM addresses). Give those two words a real gain:

```
   input-mix gain = 0.0 : 108 survive    src00 FORCED  mem x108
   input-mix gain = 1.0 : 216 survive    src00 2 values  mem x108  acc x108
```

**So `SRC 0x00 = mem[ptr]` is FORCED *given* that the two mix coefficients are
zero when the block runs, and only then.** It is still never `DR`, never `zero`,
never `P`. Status: **`SRC 0x00 ∈ {mem[ptr], acc}`, FORCED; `= mem[ptr]`,
CONSISTENT and conditionally forced.**

### 5.3 ★ And the "contradiction" with the reverb was never one

`action-field.md` §8 sets "the reverb ladder demands `SRC 0x00 = DR`,
52 696/52 696" against "SINGLE DELAY demands not-`DR`, 0 of 5145" and calls them
irreconcilable. `allpass-adder-rerun.md` §7 adds a "third independent witness"
(13 230/13 230).

All three of those counts are conditioned on the same antecedent: *if the reverb
core is a first-order all-pass stage, then …*. And that antecedent is refuted, by
the same tool, exhaustively and twice — 0 of 20 580 000 under the sequential
model and 0 again under the adder, with the obstruction proved model-free (a
delay line cannot store the value its own stage multiplies) and located in slot
4's write. **A necessary condition of a false premise carries no information**,
so there is nothing for SINGLE DELAY to contradict.

The identical argument applies to `ACTION 0x00`: the "9520 of 9660 need `−bus`"
count is a necessary condition of the same refuted premise. **The brief's two
live contradictions have one root cause, and it is not a disagreement between two
blocks — it is a conditional being read as a claim.**

Two consequences worth carrying:

1. the reverb imposes **no unconditional constraint** on `SRC 0x00` or on
   `ACTION 0x00`. Whatever settles them will not come from there until the core's
   *actual* structure is known;
2. and the widened space makes the all-pass falsification **stronger**: the
   all-pass wants `−bus` in 9520 of its 9660, and `sub` has **0** survivors in
   the LFO and appears in **none** of the 33 joint survivors.

---

## 6. Enumerated mechanisms, and which ones died

The brief asks for the "adder lesson" hypothesis explicitly: what single
mechanism would let `ACTION 0x00` look like `load` in one block and `add` in
another? Four were enumerated; two are dead, one is alive and one is the answer.

| # | mechanism | verdict |
|---|---|---|
| **M1** | ★ **the gate changes the clear's TIMING, not its presence.** A bit-7-suppressed store still clears, at the *end* of the word. Then `add` runs the LFO under the biquad's forced store timing, and `load` runs it too. | **ALIVE — and it is the resolution.** 12 of the 33 joint survivors |
| **M2** | **`bsel` — a MAC adder with a selector on EACH input.** `hi12[3:1]` picks the A input from {0, acc} and `ACTION 0x00` swaps the B input from `P` to `bus`. This is literally the shape of the previous adjudication, so it was tested first. It runs the LFO (`092` leaves `INC`, `082` gives `INC + phase`) — and it cannot run SINGLE DELAY, whose `w7` needs `P + bus` at `hi12[3:1] == 0` and gets `bus` alone. | **FALSIFIED**, 0 of 5832 |
| **M3** | **`SRC 0x00`/`ACTION 0x00` is a null routing** (`lo12 == 0x000` = "no operand, no action"), which would make 572 words pure pointer moves and dissolve the question. | **FALSIFIED**, 0 of 5832 — SINGLE DELAY needs `SRC 0x00` to carry *x* |
| **M4** | **the global store timing is `st_before_clr_after`** (`acc-adder.md`'s own route to `add`). | **FALSIFIED** by the biquad at **51.090 dB** against its designer — not merely non-bit-identical |

---

## 7. What is FORCED, CONSISTENT and OPEN, after this pass

**FORCED**

* `sttime = before` — the bit-4 store **and** its clear are taken before the
  word's own ALU step. 24/24 under the **independent** criterion, and the two
  alternatives are rejected at 84.768 dB and 51.090 dB.
* `ACTION 0x19 = tempA ← bus` — 108/108, in both SINGLE DELAY windows and at
  both mix settings. Unchanged and re-confirmed.
* `SRC 0x00 ∈ {mem[ptr], acc}` — `zero`, `P`, `DR` and `tA` all have 0 survivors
  in every SINGLE DELAY variant.
* `ACTION 0x00 ∈ {load, add, rload}` — `none`, `sub` and `bsel` are dead across
  the three contexts.
* **the coupling**: `add`/`rload` ⇒ a gate whose suppressed store clears late;
  33/33.
* the blindness theorem of §1, and the census that follows from it.
* `op2 = hold`, **within the acc-domain reading of the mask** (§3.1).

**CONSISTENT, not forced**

* `ACTION 0x00 = load` — 15 of 33, the plurality, and the only reading that
  survives with **every** gate. That is a real argument for keeping it in the
  device; it is not a forcing, and `instruction-set.md` must stop calling it one.
* `SRC 0x00 = mem[ptr]` — forced only while the input-mix coefficients are zero.
* the gate's suppressed-store **clear**: five gates survive the joint.

**OPEN**

* ★ **whether a bit-7-suppressed store clears the accumulator, and when.** 130
  corpus words carry `(b7, f31) = (1, 1)` with bit 4. By **C** this is now the
  *same* question as `ACTION 0x00`, so it is the single highest-value item in the
  ALU — ahead of `ACTION 0x00`, which is downstream of it.
* what `hi12` bit 7 means. The gate reads it without reading it, and now the
  clear's timing hangs on it too.
* what the reverb core computes (`sec_schroeder`, untouched here).
* the 221 discriminating sites in 35 programs are all in blocks whose algorithms
  are unknown. Decoding **any one** of those algorithms settles `ACTION 0x00` and
  the gate together; the shortest routes are listed in §9.

---

## 8. PREDICT-THEN-CHECK

| | prediction, recorded before the measurement | result |
|---|---|---|
| **P-1** | the biquad's `sttime = before` will survive replacement of the bit-identity criterion by the designer's transfer function | **HIT.** 24/24, and `clear late` is 51.090 dB wrong |
| **P-2** | a gate in which the suppressed store clears LATE will let `ACTION 0x00 = add` run the LFO at `sttime = before` | **HIT.** 432 + 432 survivors, and 12 of the 33 in the joint |
| **P-3** | SINGLE DELAY will be blind to `load` vs `add`, from the `hi12[3:1] == 0` argument alone | **HIT.** 4 `act00` values, and 0 census sites |
| **P-4** | the `bsel` mechanism (a selector on each adder input) will reconcile the two readings | **MISS.** It runs the LFO and dies in SINGLE DELAY, 0 of 5832 |
| **P-5** | PARAMETRIC EQ's seven `ACTION 0x00` words will provide the fourth context | **MISS.** All seven are blind — `hi12[3:1] ∈ {0, 4, 5}` or their own bit-4 clear |
| **P-6** | widening SINGLE DELAY's window to `w3..w9` will change the `SRC 0x00` marginal | **MISS with the ROM's own coefficients** — 108/108 either way — and the *reason* is measured: both mix gains are `0.0000` in all 20 instances. It changes only when the mix is given a gain (108 → 108 `mem` + 108 `acc`) |
| **P-7** | this tool will reproduce `acc-adder.md`'s numbers inside `acc-adder.md`'s sub-space | **HIT, exactly.** LFO 1224/1224; joint 9, and 9 × 2 = 18 with the 2 explained |
| **P-8** | *(during the run)* every `ACTION 0x00` word with `hi12[3:1] ∈ {1,2}` can bear a difference | **MISS, and the one that mattered.** A word carrying its **own** bit-4 store has its entering accumulator cleared first. The uncorrected census said 549 sites and put PARAMETRIC EQ among the candidates; corrected, it says 359 and PARAMETRIC EQ has none. An over-broad census manufactures fourth contexts that do not exist |
| **P-9** | the FLANGER's `900.1.60.2D9 / 192.A.03.1D5 / 182.2.48.000 / … / 880.1.20.40B` block — a delay block whose `ACTION 0x00` word is at `hi12[3:1] = 1` and which writes the **accumulator** to the line — will be a known-mathematics fourth context | **MISS.** The next word, `000.2.00.44C`, has `hi12[3:1] == 0` and kills the difference one word later. Recorded because it looked exactly right |
| **P-10** | no frame completes and no audio moves | **HIT, by construction** — nothing that runs in the emulator was edited |

---

## 9. What this constrains for the other two targets

* ★ **TARGET 1 / the reverb (`sec_schroeder`).** `ACTION 0x00` must now be
  enumerated over **{load, add, rload}** *and* the gate over **six** values,
  **jointly**, because they are coupled (**C**). Fixing `act00 = load` because
  "it ships" would repeat exactly the error this pass found, and it is method
  rule 2 verbatim. Note also that the reverb's own nine discriminating sites are
  all the same word, `104.2.00.000` at `hi12[3:1] = 2`, observed one word later
  by `SRC 0x10` — so a Schroeder solve that gets the core right settles
  `ACTION 0x00` as a by-product.
* **The all-pass is not rescued by any of this.** `sub` (the 9520/9660 reading)
  has 0 survivors everywhere. The widened space moves `load`, not the
  falsification.
* **TARGET 3 / the frame and the gate.** The 130 `(b7, f31) = (1, 1)` store words
  are now the top item. Any context that shows whether one of them clears — for
  instance a block that reads the accumulator immediately after one — decides
  `ACTION 0x00` too. `092.2.00.700` (SRC `0x1C`, the LFO output) is such a word
  and PHASER `w53`/`w54` is such a pair; its arithmetic is not independently
  known, which is the obstacle, not the shortage of sites.
* **For the device.** `ACTION 0x00 = load` should be **relabelled FORCED →
  CONSISTENT** in `instruction-set.md` and in the device comment. Whether to
  *withdraw* it is a separate decision and is **not taken here**: it remains the
  plurality reading (15/33) and the only one compatible with all five surviving
  gates, so keeping it costs nothing that is proven, while withdrawing it would
  re-trap 107 corpus words that no evidence has actually falsified. The
  enumeration is what changed, not the ranking.

---

## 10. Safety

* No file under `src/devices/cpu/upd6383/` was touched; `upd6383d.cpp` and
  `dsp/tools/dsp_disasm.py` are unchanged, so the two disassemblers cannot have
  drifted and the mirror diff is unaffected.
* `dsp/verify.py` → **BYTE-MATCH OK** (kernel + epilogue + 91 valid algorithm
  streams, 38 distinct images).
* No `.dsm` or `.sym` regenerated. No emulator was run: this pass is entirely
  static, so the DSPCFG-off rendered audio is bit-identical **by construction**.

---

## 11. Reproducing

```
python3 dsp/tools/action00_discriminate.py control     # ~2 min, the controls
python3 dsp/tools/action00_discriminate.py census      # ~5 s
python3 dsp/tools/action00_discriminate.py biquad      # ~3 min
python3 dsp/tools/action00_discriminate.py single      # ~1 min
python3 dsp/tools/action00_discriminate.py sdmix       # ~1 min
python3 dsp/tools/action00_discriminate.py joint       # ~15 min, the deliverable
python3 dsp/verify.py                                  # the tree still byte-matches
```

Inputs: `original_ROMs/kn5000_subprogram_v142.rom` (microcode, C-RAM streams and
parameter tables). Nothing else is read and nothing is written.
