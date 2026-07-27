# The ACCUMULATOR IS AN ADDER, not a sequence — adjudicating two passes that contradicted each other

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-26**.
No hardware. Static analysis, the ROM corpus, constraint solving and the live
emulator only.

Tool: [`../tools/acc_adjudicate.py`](../tools/acc_adjudicate.py) — stdlib only,
re-runnable, prints every number quoted below. Also
[`../tools/r1_allpass_solve.py adjudicate`](../tools/r1_allpass_solve.py), the
new section that exposed the clash in the older model.

```
python3 dsp/tools/acc_adjudicate.py biquad     # what the 57 dB really constrains
python3 dsp/tools/acc_adjudicate.py single     # SINGLE DELAY, with a real D-RAM
python3 dsp/tools/acc_adjudicate.py lfo        # all 29 LFO blocks
python3 dsp/tools/acc_adjudicate.py joint      # ★ the intersection  (~35 min)
python3 dsp/tools/r1_allpass_solve.py adjudicate   # the older model, order enumerated
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** (every survivor of
an exhaustive search agrees) / **CONSISTENT** / **FALSIFIED** / **OPEN**.

> ⚠ **SUPERSEDED IN ONE ROW — read `action00-discriminator.md` (2026-07-27) with
> this note.** Item **C** below ("the joint search has a unique answer … all 18
> agree … `ACTION 0x00 = load`") is **NOT FORCED**. Its space enumerated four
> readings of the bit-7 store gate and none of them let a *suppressed* store
> clear the accumulator at the **end** of the word; with that fifth reading
> present the same three contexts leave **33** survivors and `act00` takes three
> values (`load` 15, `add` 12, `rload` 6), with `add`/`rload` occurring **only**
> on a late-clearing gate. The later pass reproduces every number in §3 and §3.4
> inside this note's own sub-space (LFO **1224**, joint **9**, and 9 × 2 = 18
> where the 2 is `op2`), so nothing else here moves — the **adder** (item B),
> the **store timing**, `ACTION 0x19` and the gate's agreed part all stand.
> Item **F** is also sharpened: the biquad's forcing of the store timing survives
> replacement of the bit-identity criterion by the designer's own transfer
> function (24/24; `clear late` is 51.090 dB wrong, not merely different).

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★ **TWO CONCURRENT PASSES REACHED OPPOSITE DETERMINATIONS ABOUT THE SAME CODE, and neither could see it.** TARGET 3 (the LFO ramp) FORCED that the `lo12` ACTION acts **before** the `hi12[3:1]` operation and that ACTION `0x00` is `acc ← bus`. TARGET 2 (SINGLE DELAY) FORCED that ACTION `0x00` routes the bus into the accumulator — but every one of its 5145 survivors was computed at the **opposite** order, because `sec_singledelay()` calls `mach(...)` without an `actfirst` argument. No sequential order satisfies both blocks. | **MEASURED** |
| **B** | ★ **BOTH ARE RIGHT ABOUT THE ANSWER AND WRONG ABOUT THE MECHANISM.** At the word where each block's sum forms, both demand the *same expression*: `acc = bus + P`. The LFO's `082.2.00.1C0` has `hi12[3:1] = 1`; SINGLE DELAY's `000.2.48.000` has `hi12[3:1] = 0`. An ordering cannot give `bus + P` at both. **A single adder whose accumulator-feedback input is overridden by the operand bus gives it at both.** | **FORCED** |
| **C** | ★ **THE JOINT SEARCH HAS A UNIQUE ANSWER.** Three independent numeric contexts — bit-identity with the PARAMETRIC EQ biquad, the SINGLE DELAY comb, the 29 LFO blocks — over 2160 × 3240 × 181 440 enumerated points, leave **18 survivors**, and all 18 agree: `order = adder`, `ACTION 0x00 = the bus replaces the accumulator's own feedback term`, `store timing = BEFORE the ALU` (the shipped one). Only the store gate (3), `hi12[3:1] == 2` (2) and the store wrap (3) remain free. | **FORCED** |
| **D** | ★ **THE OLD SINGLE DELAY MODEL COULD NOT HAVE ADJUDICATED IT.** Run with the order enumerated it has **22 050** survivors at act-first — but there ACTION `0x00` becomes *unconstrained* (35 of 35 values) and `SRC 0x00` too (6 of 6): the block matches by writing `fb·(x + v[n−D])`, which is the comb reference **times fb**, and the matcher allowed an arbitrary scale. Injecting *x* into one of six registers and starting every sample from an all-zero state is what let that through. | **MEASURED** — a **FALSIFICATION** of the older model's forcing power |
| **E** | With the input delivered through the **MEASURED pointer walk** into a real 256-cell D-RAM and every unset register randomised per sample, SINGLE DELAY forces **more** than it did before: `ACTION 0x19 = tempA ← bus` at **72/72** (the previous model could force only the destination) and `SRC 0x00 = mem[ptr]` at **72/72** (previously 3430 of 5145, CONSISTENT). And act-first drops to **0**. | **FORCED** |
| **F** | ★ **THE BIQUAD FORCES THE STORE TIMING AND NOTHING ELSE ABOUT THIS.** Of 2160 enumerated models, the 480 that are bit-identical on the PARAMETRIC EQ section are **exactly** those with the store and clear taken BEFORE the ALU; `order`, `act00` and the gate are invisible to it (the section carries no ACTION-`0x00` word and all its store words are `bit7 = 0`). It does kill one thing: `hi12[3:1] == 2` as "AND the coefficient". | **MEASURED** |
| **G** | The LFO's bit-7 store gate survives re-derivation in a differently-parameterised space: `stgate = always` has **0 of 181 440** survivors here too, and the same three gates come through. A fourth candidate this pass added — *suppress the store but KEEP the clear* — also survives, and is indistinguishable from the other two wherever ACTION `0x00` is present. | **MEASURED** |

**Adopted in the MAME device**: the adder, ACTION `0x00`, ACTION `0x19`, and the
agreed part of the gate. **Refused, with the price stated**: `SRC 0x00`,
`SRC 0x08`, `hi12[3:1] == 2` off class 8, the store wrap, and the disputed clear.
See §6.

---

## 1. The clash, exactly

`r1_allpass_solve.py`'s `sec_singledelay()` builds its machines with

```python
   m = mach(i00, i19, i0b, s0, "bus", 0, ld)          # no actfirst=
```

and `mach()`'s default is `actfirst=0`. So the note's

> *ACTION `0x00` routes the bus into the accumulator … a null accumulator effect
> has ZERO survivors (+bus 2205, −bus 1960, ←bus 735, ←bus−acc 735)*

is a statement about the machine **in which the ACTION acts after the hi12[3:1]
operation**. `lfo_ramp.py`'s `publish` enumerates `ORDER` and reports
`order : ['act_first']` as a **singleton** over 432 survivors. The two passes
were solving in models that differ in the one parameter neither varied jointly.

Why it matters, in three lines of each block:

```
   LFO    092.A.00.200   f31 = 1   ACTION 00   bus = unity      bit 4
          082.2.00.1C0   f31 = 1   ACTION 00   bus = mem[Q] = phase
          094.A.00.200   f31 = 2   ACTION 00   bus = unity      bit 4  <- publishes

   SD     880.1.60.2D9   f31 = 0   ACTION 19   bus = DRAM read  (blocking)
          202.A.B8.655   f31 = 1   ACTION 15   bus = tempA
          000.2.48.000   f31 = 0   ACTION 00   bus = mem[p-72] = x
          212.2.00.419   f31 = 1   ACTION 19   bus = acc        bit 4
          880.1.20.64B   f31 = 0   ACTION 0B   bus = tempA      -> the line
```

*The LFO*: the value published at `094` must be `phase + INC`, and the only word
that can add them is `082`, which has `f31 = 1`. Under act-last that word gives
`acc + P + phase` and the entering accumulator is randomised, so it fails; under
act-first it gives `phase + P` and works.

*SINGLE DELAY*: the value written to the line is tempA, captured at `w8` from the
bus, which is the accumulator `w7` left. `w7` has `f31 = 0`, i.e. `acc ← P`.
Under act-first that **overwrites** whatever the ACTION did, so *x* has no path
in; under act-last it gives `P + x` and works.

**Both blocks need `bus + P` at the word that adds. One has `f31 = 1` there and
the other `f31 = 0`.** That is the whole contradiction, and it is not about the
ACTION field at all.

---

## 2. ★ The resolution — the ACTION is a selector on the accumulator's adder

```
   acc  <-  SRC_TERM  +  P_TERM

      SRC_TERM = bus                       if ACTION == 0x00
               = 0                         if hi12[3:1] == 0     (acc <- P)
               = acc                       otherwise

      P_TERM   = 0                         if hi12[3:1] == 2     (no product)
               = P                         otherwise
```

Check it against the two blocks:

```
   LFO   082  f31=1 ACT00 :  SRC=phase  P=INC   ->  phase + INC        ✔
   LFO   094  f31=2 ACT00 :  stored BEFORE the ALU, so `phase + INC'   ✔ publishes
   SD    w7   f31=0 ACT00 :  SRC=x      P=fb·d  ->  x + fb·d_out       ✔
   SD    w8   f31=1 ACT19 :  bus latched first = x + fb·d_out -> tempA ✔
   SD    w9                :  the line receives tempA                   ✔
```

**On every word whose ACTION is not `0x00` this is the shipped model exactly** —
`f31 = 0` gives `0 + P`, `f31 = 1` gives `acc + P`, `f31 = 2` gives `acc + 0`.
PROVEN BY CONSTRUCTION, and it is why nothing that already worked can move.

A **testable consequence**, stated because it is a prediction and not a
convenience: on an ACTION-`0x00` word `hi12[3:1] == 0` and `== 1` become
**indistinguishable** (both give `bus + P`), and the corpus emits both. If a
later context separates them, this reading is wrong.

---

## 3. The three contexts, and what each one can see

### 3.1 The biquad — it forces the STORE TIMING, and only that

`acc_adjudicate.py biquad` runs the nine-word PARAMETRIC EQ section (the same
array `kn7000_mame/tools/kn5000_dsp_alu_mirror.py` builds its acceptance test
from) under 2160 models and asks which give a **bit-identical impulse response**
to the shipping one. Any such model inherits the 0.094 dB validation without
re-earning it.

```
   the section's ACTION codes                    : 07 12 13 14 15   (no 0x00)
   its bit-4 store words, by (bit7, hi12[3:1])   : {(0, 1): 2}

   480 of 2160 are BIT-IDENTICAL
      order    3 values   act_last x160  act_first x160  adder x160
      act00    5 values   (all)
      sttime   FORCED     before x480
      stgate   4 values   (all)
      op2      2 values   hold x240  and_mask23 x240      <- `and_coef' is OUT
      wrap     4 values   (all)
```

So the strongest numeric result in this project is **silent** about the order and
about ACTION `0x00` — which is exactly why two passes could disagree without
either noticing. What it does say is worth having: the store and the clear happen
**before** the word's own ALU step, and `hi12[3:1] == 2` is not a mask against the
coefficient.

### 3.2 SINGLE DELAY — strengthened, and it forces more

The previous model injected *x* into one of six **registers**, started every
sample from an all-zero state, had a single `M` register standing in for all of
D-RAM, and accepted a match up to an arbitrary scale. This pass:

* puts the input in the **D-RAM cell the measured pointer walk reads** — `w6`
  post-increments by `s8(0xB8) = −72` and `w7` by `+72`, so `w7`'s `SRC 0x00`
  reads `mem[p−72]` and `w8` stores at `mem[p]`;
* gives the block a real 256-cell D-RAM;
* **randomises** the accumulator, the product latch and both temporaries every
  sample, and feeds any source the ISA does not decode a fresh random value.

```
   72 of 3240 machines reproduce  v[n] = x[n] + fb*v[n-D]
      order    2 values  adder x48  act_last x24        <- act_first: ZERO
      act00    4 values  add x24  sub x24  load x12  rload x12
      sttime   3 values
      stgate   4 values
      act19    FORCED    tA<-bus x72
      src00    FORCED    mem x72
```

`act19` and `src00` are **new** forcings — the older model could force only that
`0x19` captures *into* tempA, and left `SRC 0x00` at 3430/5145.

### 3.3 The 29 LFO blocks — re-derived in a different parameterisation

```
   181440 candidates -> 1632 (2 blocks) -> 1632 (all 29) -> 1224 (the 2**23 wrap)
      order    3 values  act_first x576  adder x576  act_last x72
      act00    3 values  load x864  add x216  rload x144
      sttime   2 values  st_before_clr_after x792  before x432
      stgate   3 values  b7_f31_1_keepclear x648  b7_f31_1_off x288  b7_ne2_off x288
      src08    FORCED    unity x1224
```

`stgate = always` — the shipped, unconditional store — has **0** survivors, in a
space built independently of `lfo_ramp.py`'s. `src08 = unity` is re-forced.
`act_last` appears here only in combination with the store-timing variants the
biquad then removes.

### 3.4 The intersection

```
   biquad-identical (6 params)        480
   LFO              (6 params)        153
   SINGLE DELAY     (4 params)         72
   biquad AND lfo                      36
   ★ ALL THREE                         18

      order    FORCED   adder x18
      act00    FORCED   load  x18
      sttime   FORCED   before x18
      stgate   3 values  b7_f31_1_keepclear / b7_f31_1_off / b7_ne2_off
      op2      2 values  hold / and_mask23
      wrap     3 values  b7_and_coef / f31_2_and_coef / wrap23
```

---

## 4. ★ Why the older SINGLE DELAY search could not have caught this

`r1_allpass_solve.py adjudicate` re-runs it with the order enumerated:

```
   actfirst = 0 (the shipped order)  : 5145 survivors   -- the note's result
       ACTION 0x19 capture  2 values  tA<-bus x2940  tA<-acc x2205
       SRC 0x00 reads       4 values  M x3430 ...

   actfirst = 1 (the LFO's order)    : 22050 survivors
       ACTION 0x00          35 values  -- UNCONSTRAINED, "no effect" included
       SRC 0x00 reads        6 values  -- UNCONSTRAINED
       ACTION 0x19 capture  FORCED     tA<-acc x22050
```

**PREDICT-THEN-CHECK, and a MISS I am glad I recorded.** I predicted zero
survivors at act-first and reasoned it out on paper first. There are 22 050,
and the reason is instructive: with *x* injected directly into a register and the
match allowed an arbitrary scale, the block can pass by computing
`v[n] = fb·(x[n] + v[n−D])`, which is the comb reference **scaled by fb**. So the
older model does not merely fail to decide the order — at act-first it *forces
the opposite capture semantics* (`tA ← acc`) with equal formal confidence. A
determination that flips when a parameter nobody varied is flipped is not a
determination.

The strengthened model (§3.2) removes both loopholes and act-first goes to zero.

---

## 5. What this changes about earlier claims

| claim | where | status now |
|---|---|---|
| "`ACTION 0x00` = `acc ← bus` taken **before** the `hi12[3:1]` operation" | `lfo-ramp.md` Part I/II, DETERMINED | **CORRECTED, not withdrawn.** The value it computes is right; the *mechanism* is an adder selector, not an ordering. Under the adopted model the LFO block still runs |
| "`ACTION 0x00` … `+bus / −bus / ←bus / ←bus−acc`, which is free" | `action-field.md` §6, FORCED | **NARROWED to one**: the joint solve leaves `load` only |
| "`ACTION 0x19` captures into tempA (`tA<-bus` or `tA<-acc`; which is free)" | `action-field.md` §6, FORCED | **NARROWED to `tA ← bus`**, 72/72 |
| "`SRC 0x00 = mem[ptr]` — CONSISTENT, 3430 of 5145" | `action-field.md` §10 | **FORCED inside SINGLE DELAY**, 72/72 — but still one context, and the reverb wants the opposite (§8 of that note). **Not adopted** |
| "the gate reads `hi12` bit 7 **and** `hi12[3:1]`" | `lfo-ramp.md` Part II §8.3, FORCED | **HOLDS**, re-derived at 0 of 181 440 for `always`. A fourth gate (suppress the store, keep the clear) joins the survivor set |
| "`hi12[3:1] == 2` … a 2²³ AND and a conditional subtract" | `instruction-set.md` | the **coefficient AND** is now **FALSIFIED** by the biquad (it changes the section); `hold` and `AND 0x7FFFFF` both survive |
| `ACTION 0x00` is the LFO's and the all-pass core's largest blocker | `dsp-frame-advance.md` §4 | **28 frame slots delivered** (80 → 108 fully-decoded words per frame) |

---

## 6. What was ADOPTED in the device, and what was refused

**ADOPTED** (`kn7000_mame/src/devices/cpu/upd6383/`):

1. the **adder** form of the accumulator step — behaviour-preserving on every
   word whose ACTION is not `0x00` (PROVEN BY CONSTRUCTION, and MEASURED: the
   generated biquad mirror's impulse response is bit-identical to the
   pre-change one on all 16 candidate banks);
2. **ACTION `0x00`** = the accumulator's input term comes from the bus;
3. **ACTION `0x19`** = `tempA ← bus`;
4. the **bit-7 store gate**, in the part where all three surviving gates agree
   (`bit7 = 0` → store; `bit7 = 1, f31 = 2` → store; `bit7 = 1, f31 = 1` → no
   store) — and words where they disagree now **TRAP**, which costs 19 corpus
   words their decode. The disputed CLEAR is unobservable exactly when the
   ACTION is `0x00`, so those 107 words execute and the other 31 do not.

**REFUSED, and the price:**

| refused | evidence | price in frame slots |
|---|---|---|
| `SRC 0x00 = mem[ptr]` | FORCED in SINGLE DELAY (72/72), but the reverb ladder's filter demands the delay-read register (52 696/52 696) and that contradiction is unresolved. 30 of the 37 remaining SOURCE slots | **30** |
| `SRC 0x08 = unity` | FORCED by the LFO (1224/1224) but **only on class-A words**; the corpus has `SRC 0x08` off class A (`010.9.D0.20C`) and nothing tests it there | 8 |
| `hi12[3:1] == 2` off class 8 | two survivors (`hold`, `AND 0x7FFFFF`) that differ | 3 |
| the store WRAP | three survivors | 0 (invisible until a frame completes) |
| the CLEAR at `(bit7, f31) = (1, 1)` with ACTION ≠ `0x00` | two survivors | 9 |

---

## 7. PREDICT-THEN-CHECK log

| | prediction, written before the measurement | result |
|---|---|---|
| **A-1** | SINGLE DELAY at `actfirst = 1` has **zero** survivors in the OLD model | **MISS.** 22 050 — and the reason (§4) is the result: an arbitrary-scale match plus free register injection lets `fb·(x + v[n−D])` pass |
| **A-2** | at `actfirst = 0` the old search reproduces its published 5145 | **HIT**, exactly |
| **A-3** | the clash is not an artefact of the zero-initialised entry: SINGLE DELAY survives randomisation, because `w7`'s `acc ← P` clears contamination | **HIT.** It survives, and act-first still dies |
| **A-4** | the adder model runs SINGLE DELAY | **HIT** |
| **A-5** | the adder model needs the CLEAR at the END of the word to run the LFO | **MISS.** I had not seen that `load` *replaces* the feedback term rather than adding to it, which kills the contamination without any clear. The shipped timing is enough |
| **A-6** | …and with the clear at the end it runs the LFO | vacuous, superseded by A-5 |
| **A-7** | store/clear at the end BREAKS the biquad | **HIT**, and stronger than predicted: `store early, clear late` breaks it too, so the biquad FORCES the shipped timing outright |
| **A-8** | ACTION `0x00` will not be adoptable this pass | **MISS, and the good one.** The unification makes it adoptable in three contexts at once |
| **A-9** | the closure residue stays **+121** | **HIT.** Nothing adopted moves a pointer |
| **A-10** | no frame completes | **HIT.** 0 of 1 368 001 |

---

## 8. What is still OPEN

* which of the three store gates — they differ on 13 corpus words, nine of them
  the COMPRESSOR's envelope step at `hi12[3:1] == 5`;
* whether the suppressed store still CLEARS;
* `SRC 0x00` — the largest open routing code, and the one place two contexts
  give contradictory answers;
* what `hi12` bit 7 *means*. The gate reads it without reading it;
* what the reverb all-pass core computes. `action-field.md` §5's obstruction is
  untouched by this pass: its slot-3 word `012.2.00.680` has `bit7 = 0`, so the
  gate does not reach it, and the accumulator CLEAR there is still the single
  highest-value open question in the ALU.
