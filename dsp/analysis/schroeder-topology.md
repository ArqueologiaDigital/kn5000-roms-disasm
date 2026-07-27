# The reverb core is a COMB NETWORK — the obstruction, read forwards

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus, constraint solving and the live
emulator only.

**Why this pass exists.** The exhaustive search for a FIRST-ORDER ALL-PASS in
the reverb core returned zero survivors twice — 0 of 20 580 000 under the
sequential model ([`action-field.md`](action-field.md)) and 0 again under the
adder from a *larger* candidate set ([`allpass-adder-rerun.md`](allpass-adder-rerun.md)).
That note also **located** the obstruction exhaustively: slot 4's delay-DRAM
write shares `tempA` with slot 5's multiply, so *the value stored into the delay
line is the value being multiplied by that same line's coefficient*. This pass
takes that seriously and asks the forward question: **what IS a stage that
stores what it multiplies?**

Tool: [`../tools/r1_allpass_solve.py`](../tools/r1_allpass_solve.py), section
`schroeder2`.

```
SCH_PARTS=facts,theory,refs      python3 dsp/tools/r1_allpass_solve.py schroeder2
SCH_PARTS=degeneracy             python3 dsp/tools/r1_allpass_solve.py schroeder2
SCH_PARTS=control                python3 dsp/tools/r1_allpass_solve.py schroeder2
SCH_PARTS=search SCH_ROW=1       python3 dsp/tools/r1_allpass_solve.py schroeder2   # strict, ~4 min
SCH_PARTS=search SCH_ROW=0       python3 dsp/tools/r1_allpass_solve.py schroeder2   # generous, ~1 h
SCH_PARTS=search SCH_ROW=2       python3 dsp/tools/r1_allpass_solve.py schroeder2   # sequential
SCH_PARTS=search SCH_ROW=3       python3 dsp/tools/r1_allpass_solve.py schroeder2   # ★ the JOINT row
```

> **NAMING.** `sec_schroeder` was already taken — by section 9 of the same
> tool, which asked a different question (*can a **Gardner** machine have
> `WVAL == MULT`, inside R1's four-register model* — answer no, and that answer
> is this note's premise, not its subject). The new section is `sec_schroeder2`
> so that section 9's published reproduce line keeps working.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** (every survivor
of an exhaustive search agrees) / **CONSISTENT** / **FALSIFIED** / **OPEN**.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE REVERB CORE IS A COMB NETWORK, AND IT IS NOT EMPTY.** Against the two published zeros: **16 520 of 20 580 000** machines reproduce a comb topology in the GENEROUS space (the apples-to-apples re-run), and **112 of 823 200** in the STRICT sub-space that actually ships — at two independent delay sets, with the all-pass reference carried inside the same reference set and matched by **0** of them. The multiplicand and the written value are both `w[r] + t[r−1]`: the fresh delay read plus the previous stage's product. | **MEASURED** |
| **B** | ★★★ **AND IT UN-BREAKS THE `ACTION 0x00` CONTRADICTION, IN FAVOUR OF WHAT SHIPS.** `ACTION 0x00`'s accumulator half is **`acc ← bus`** — **`load`** — in **16 520 of 16 520** generous survivors and **112 of 112** strict ones. That is exactly what `acc-adder.md`'s three-context joint solve forced 18/18 and exactly what `exec_alu()` implements. The all-pass hypothesis was the *only* thing demanding an `add`-like code, and the all-pass hypothesis is falsified. **Live contradiction #1 is RESOLVED.** | **FORCED** |
| **C** | ★★ **AND IT FALSIFIES THE STRICT VOCABULARY — via a THIRD contradiction that then resolves.** The strict sub-space forces `ACTION 0x19 = tB ← bus`, which contradicts SINGLE DELAY's **tempA** (5 635/5 635, and `tA<-acc` 22 050/22 050 at act-first). Enumerated rather than assumed: restrict `0x19`'s capture to tempA and re-run the whole search — **12 740 comb machines survive**, and every one of them forces `ACTION 0x19`'s capture half to **`tA ← acc`** *and* requires `0x19` to **route the bus into the accumulator**. So `"only ACTION 0x00 routes the bus"` — the reading the device implements — is **FALSIFIED**, conditional on the comb plus SINGLE DELAY. | **FORCED (joint) / a FALSIFICATION** |
| **D** | **`SRC 0x00` still reads the delay-RAM data register — 16 520/16 520 and 112/112.** So live contradiction #2 (the reverb needs `DR`, SINGLE DELAY forbids it) is **NOT** resolved; it now has a fifth independent witness, and it is the last one standing. | **FORCED** |
| **E** | ★★ **A DEGENERATE CONTROL, FOUND IN THE PUBLISHED WORK.** `sec_control` and `sec_strict_control` run the all-pass reference with the ROM's real ladder-0 delays `[127, 435, 489, 183, 522]` over **64 samples**. `min(delay) = 127 > 64`, so **not one delay line ever recirculates** — every read returns 0 and the reference collapses to `y = x·Π(−g_k)`, a pure scalar. Those controls were asserting *"the machine's output is a scalar multiple of x"*. **They could not fail.** | **MEASURED**, a **FALSIFICATION** |
| **F** | **The control survives repair; its published figures do not.** Re-run at delays that recirculate, both controls still MATCH — but at `extract = M, scale = −1.000`, not the published `extract = P, scale = +1.000`, which was the zero-delay artefact. **The searches are unaffected**: `action_search` uses delays `[3, 5]` over 32 samples, which do recirculate. | **MEASURED** |
| **G** | **The controls of THIS pass are shipped with the cases where they say NO.** The comb-cascade control is accepted; its twin — identical except that `tA` is captured *before* the accumulate, so that **write == multiplicand** — is **REJECTED at 6 of 6** configurations. The pipe-comb control is accepted with the correct `(b, c)` label; flipping `b` **moves** the label; dropping the product from the loop, storing a raw read, removing the pipeline trail and mis-landing the read each **REJECT at 6 of 6**. | **MEASURED** |
| **H** | ★ **AND THE ADDER HAS A DEGENERACY THAT MATTERS TO THE CONTRADICTION.** At any word with `hi12[3:1] == 0` the accumulator's feedback input is already zero, so `+bus`, `bus` (**load**) and `bus−acc` (**rload**) all compute `P + bus` and are **the same machine there**. Found because two of this pass's own "wrong twins" turned out not to be twins. Motif slots 0, 2, 6 and 7 are `hi12[3:1] == 0`; only slots 1 and 3 can see the difference. | **PROVEN BY CONSTRUCTION**, found by a control |
| **I** | **Preset-independence is not at risk, and it is re-measured here.** Algos 16–27 are twelve reverb presets with a **byte-identical** 133-word image; the whole symbolic stage reads only that image. | **MEASURED** |

---

## 1. The prediction, recorded before anything was written or run

Reproduced verbatim in the [Appendix](#appendix--the-prediction-verbatim). The
substance:

* **P0/P1** — with `line ← u` and `t = g·u`, the multiplier's output can never
  re-enter the line it just wrote *inside* a repetition, so within a repetition
  the loop gain is 0 or ±1 and ±1 is a pole on the unit circle. A legal loop
  gain can therefore only come from the **pipeline**: with the write trailing
  the read by one repetition and `u_r = a·x + b·w_r + c·t_{r−1}`,

  ```
      d_k[n] = (b·c·g_k)·d_k[n−D_k] + (terms not involving line k)
  ```

  — loop gain `b·c·g_k`, through the multiplier exactly once, **across the
  repetition boundary**. That is the comb denominator `1 − g z^-D`.
* **P2 — CANNOT:** a first-order all-pass, a Schroeder all-pass, a Gardner
  one-multiplier all-pass (all the *same* transfer function, already zero
  twice); a two-multiply Schroeder all-pass (same function again, and two
  multiplies where the core has one class-A word); a bank of *independent*
  parallel combs (the loop needs `b ≠ 0`, and the same `b` unavoidably
  cross-couples the neighbouring line).
* **P2 — CAN:** a feedback comb per line, cross-coupled to its neighbours — a
  nested/series comb network, the *comb* half of a Schroeder reverberator
  rather than its all-pass half.
* **P3** — `loop_ok`'s C1/C2/C3 are **denominator** conditions, not all-pass
  conditions; the all-pass lives in the numerator and only the numeric matcher
  ever tested it. So the existing loop-filter survivor set should be able to
  return a NON-zero comb count.
* **P4** — comb survivors will *also* refuse `load`, sharpening contradiction #1.
* **P5** — the output tap and series-vs-parallel will have to be enumerated.

### 1.1 PREDICT-THEN-CHECK — every hit and every miss

| # | prediction | outcome |
|---|---|---|
| **PC-1** | the all-pass, Schroeder all-pass and Gardner form are the same transfer function and must stay at zero | **HIT** — the all-pass reference is carried inside the same reference set and is matched by **0** survivors in every row |
| **PC-2** | `loop_ok` is a denominator filter, so a comb test over its survivors can be non-empty | ★ **HIT** — 112 of 2 268 in the strict space |
| **PC-3** | the surviving stage is `u = b·w + c·t_prev` with `b, c = ±1` | ★ **HIT, exactly** — the forced multiplicand is `P + N` = `t[r−1] + w[r]`, i.e. `b = c = +1` |
| **PC-4** | comb survivors will *also* refuse `load`, sharpening contradiction #1 | ★★ **MISS — and this is the pass's best result.** They force `load` in every row, under both accumulator models. The contradiction does not sharpen; it **dissolves**, in favour of the shipped ALU. |
| **PC-5** | the tap and the series/parallel choice will need enumerating | **HIT** — three taps survive (`u_last`, `t_last`, `w_last`) and the *write source* selects between two different comb networks |
| **PC-6** | (implicit) the controls would behave | **MISS** — two of the four "wrong twins" were not twins at all (§0-H), and the *published* controls turned out to be degenerate (§0-E) |
| **PC-7** | `SRC 0x00 = DR` would again be forced | **HIT** — every row, and the contradiction with SINGLE DELAY survives untouched |
| **PC-8** | (not predicted at all) | ★★ **UNFORESEEN** — the pass produced a *third* contradiction, at `ACTION 0x19`, and resolved it against the **strict vocabulary** rather than against either block (§6.6). Nothing in the prediction anticipated that the shipped "only `0x00` routes the bus" reading would be what breaks. |

---

## 2. The difference equation the obstruction produces — stated first

Slot 4 (`880.1.20.655`, DRAM WRITE, `src = 0x19 = tempA`) and slot 5
(`102.A.00.64B`, THE MULTIPLY, `src = 0x19 = tempA`) are adjacent, and slot 4's
`ACTION 0x15` is anchored to `('','')` — **no capture half at all**, so the
three unknown codes are not even reachable at that word. Nothing between them
can rewrite tempA.

> **PROVEN BY CONSTRUCTION: when the write takes its data from the bus, the
> value stored into the delay line and the value handed to the multiplier are
> the same number.** Spot-measured anyway on 20 000 random settings drawn from
> the same 5 145 000-setting space: **20 000 / 20 000 agree** (`SCH_PARTS=theory`).

Write that number `u`:

```
      line <- u ,   t = g*u ,   w = u[n-D]        =>    g*w[n] = t[n-D]
```

A first-order all-pass stage stores `x + t` and multiplies `x + w` — **two
different numbers** — so it is excluded, and that is the published zero, twice
over. A **comb** is not excluded, because the comb's numerator is trivial and
its only requirement is that the loop close through the multiplier once. §1's
P1 shows the pipeline supplies exactly that.

---

## 3. ★ A DEGENERATE CONTROL, IN THE PUBLISHED WORK

`sec_control` (10a / 13's "gardner ladder") and `sec_strict_control` (13a) run
the reference with the ROM's real ladder-0 delays over 64 samples:

```
   ladder-0 delays used by the CONTROLS: [127, 435, 489, 183, 522]
       2-stage, 64 samples: non-zero reads per line = [0, 0]
       4-stage, 64 samples: non-zero reads per line = [0, 0, 0, 0]
       5-stage, 64 samples: non-zero reads per line = [0, 0, 0, 0, 0]
```

`min(delay) = 127 > 64`, so no line ever returns a value that was written to it.
`allpass_ref` collapses to `y = x·Π(−g_k)`; the control machine's output does
the same; and the "MATCH" was the statement *"one scalar multiple of x equals
another"*. Measured directly: the 5-stage reference is `−0.049140·x` with a
worst residue of `6.9e-18`.

**This is the third recurrence of the same defect in this project** — after the
biquad's blind spot (`acc-adder.md` §3.1) and the order-insensitivity of this
very control (`allpass-adder-rerun.md` §4). It is worth naming the general form:
*a control is only evidence about the thing it varies, and a delay network whose
delays never elapse varies nothing.*

**What survives.** Re-run with delays short enough to recirculate:

```
   gardner (sec_control)  delays [127, 435, 489, 183, 522]  MATCH inj=P ext=P sc=+1.0000
   gardner (sec_control)  delays [3, 5, 7, 11, 13]          MATCH inj=P ext=M sc=-1.0000
   gardner (sec_control)  delays [11, 17, 23, 29, 31]       MATCH inj=P ext=M sc=-1.0000
   strict  (13a)          delays [127, 435, 489, 183, 522]  MATCH inj=P ext=P sc=+1.0000
   strict  (13a)          delays [3, 5, 7, 11, 13]          MATCH inj=P ext=M sc=-1.0000
   strict  (13a)          delays [11, 17, 23, 29, 31]       MATCH inj=P ext=M sc=-1.0000
```

* the controls **are** one-multiplier all-pass ladders and the harness **does**
  accept them — the negative result keeps its positive control;
* **RETRACTED:** the published `extract = P, scale = +1.000` in
  `action-field.md` §4, `allpass-adder-rerun.md` §4 and §4.1. The real
  extraction point is `M` and the real scale `−1.000`; `P` and `+1.000` are the
  zero-delay artefact;
* **the searches are unaffected**: `action_search` uses delays `[3, 5]` over 32
  samples, which recirculate ~10 and ~6 times respectively.

---

## 4. The references, and the proof that they can tell each other apart

Six textbook structures plus the family the obstruction itself implies, each
transcribed from its difference equation with the same `Line` class the ladder
uses, none of them derived from the executor or from a search result:

| reference | what it is |
|---|---|
| `allpass` | the published zero, carried along as a **negative control** |
| `comb cascade, tap = stored` / `tap = delayed` | `Π_k 1/(1 − g_k z^-D_k)` in series |
| `comb bank, parallel` | Schroeder's `Σ_k 1/(1 − g_k z^-D_k)` |
| `Moorer lowpass comb bank` | the same with a fixed `(1 + z^-1)/2` in each loop — the one lowpass the chip could build with the tempB `>>1` and no second multiplier |
| `nested all-pass (Gardner)` | an all-pass inside the delay of an all-pass |
| `pipe-comb b±1 c±1 {hold,zero} {u,t,w}_last…` | §1-P1's own recursion, `u_r = b·w_r + c·t_{r−1}`, written out |

A **LATTICE is deliberately absent, with the reason stated rather than
assumed**: a Gray–Markel one-multiplier lattice *realises* the same all-pass
transfer function, and the matcher only ever compares input to output, so it is
the same test as `allpass_ref` — already zero, twice. The same argument retires
the two-multiply Schroeder all-pass.

The matcher grants an arbitrary scale over 6 × 6 injection/extraction pairs, so
two references that are proportional would make a hit meaningless. Measured:

```
   40 references; closest pair residue 0.00997; duplicate pairs 0
   fast matcher vs plain _proj: 0 disagreements over 86400 reference tests
```

(12 genuine duplicates were found and **merged, not hidden**: the pipe-comb
family is symmetric under `(b,c) → (−b,−c)`, which the free scale absorbs, and
at `drain = zero` `u_K = c·t_{K−1}` makes `u_last` and `t_last` the same array.)

---

## 5. ★ THE CONTROLS — each one shipped with the case where it says NO

Delays `[3,5,7,11,13]` and `[2,3,4,5,6]` over 64 samples, so every line
recirculates many times — §3's defect must not be repeated here.

**(a) a comb cascade, built where the write and the multiplicand DIFFER** — the
multiplicand is the fresh read `w`, the written value is the running
accumulator. ACCEPTED at 2, 3 and 5 stages on both delay sets, as
`comb cascade, tap = delayed`, and it passes the delay-loop filter.

**(a′) the same program with `tA` captured BEFORE the accumulate**, so that
**write == multiplicand** — the exact property this whole pass is about:

```
   comb cascade, write==mult   2-stage [3, 5]            NO MATCH   <- SAYS NO
   comb cascade, write==mult   3-stage [3, 5, 7]         NO MATCH   <- SAYS NO
   comb cascade, write==mult   5-stage [3, 5, 7, 11, 13] NO MATCH   <- SAYS NO
   comb cascade, write==mult   2-stage [2, 3]            NO MATCH   <- SAYS NO
   comb cascade, write==mult   3-stage [2, 3, 4]         NO MATCH   <- SAYS NO
   comb cascade, write==mult   5-stage [2, 3, 4, 5, 6]   NO MATCH   <- SAYS NO
```

**6 of 6.** The reference set rejects on precisely the parameter under study.

**(b) the pipelined comb the obstruction implies** (write == multiplicand, the
write trailing the read by one repetition): ACCEPTED at 2/3/5 stages on both
delay sets, and — the part that matters — accepted **with the correct label**,
`pipe-comb b+1 c+1 hold`.

**(b′) its wrong twins:**

| twin | verdict |
|---|---|
| `b = −1` (slot p1 does `acc ← P − DR`) | matches `pipe-comb **b−1** c+1` — the label **MOVES**, 6/6 |
| `c = 0` (`hi12[3:1] = 3`, the product dropped from the loop) | **NO MATCH**, 6/6 |
| the line stores a RAW read (a pure delay chain) | **NO MATCH**, 6/6 |
| the write does not trail (`wtrail = 0`) | **NO MATCH**, 6/6 |
| the read lands too late (`land = 7`) | **NO MATCH**, 6/6 |

### 5.1 ★ And two "twins" that were not twins — a fact about the adder

The first attempt used `bus−acc` for `c = −1` and `bus` for `c = 0`. Both
behaved identically to `+bus`, and the reason is structural:

> **At a word with `hi12[3:1] == 0` the accumulator's feedback input is already
> zero, so `+bus` (`fb=0, bt=bus`), `bus` (**load**: `fb=bus, bt=0`) and
> `bus−acc` (**rload**: `fb=−0, bt=bus`) all compute `P + bus`. They are the
> same machine there.** PROVEN BY CONSTRUCTION from `exec_alu`'s adder branch.

Motif slots **0, 2, 6 and 7** are `hi12[3:1] == 0`. **Only slots 1
(`hi12[3:1] = 2`) and 3 (`= 1`) can distinguish `load` from `add` at all** — a
fact that bears directly on the `ACTION 0x00` question and that no earlier note
states.

---

## 6. ★★★ THE SEARCH

Structural stage: `action_search`'s own enumeration and its delay-loop filter,
unchanged and delay-independent. Numeric stage: the ladder is run **once** per
survivor and compared against every reference; a hit is reported only if it also
survives a **second** run at a different delay set (`[3,7]`) with twice the
samples — the guard against a numerical accident at one delay pair.

### 6.1 GENEROUS — the apples-to-apples re-run against 0 of 20 580 000

```
   [0] ADDER, generous
       74508 machines pass the delay-loop filter
       16520 machines reproduce SOME topology at BOTH delay sets
          pipe-comb b+1 c+1 hold u_last     x34512      comb cascade, tap = delayed  x2940
          pipe-comb b+1 c+1 hold w_last     x18960      comb cascade, tap = stored   x2464
          pipe-comb b+1 c+1 hold t_last     x12972      pipe-comb b-1 c+1 hold …     x10676
       SRC 0x00 reads       FORCED   DR x16520
       ACTION 0x00 acc op   FORCED   bus x16520
       read lands +n        2        0 x8260  1 x8260
       write data from      4        bus x6860  M x4780  acc_before x2440  acc_after x2440
       ACTION 0x00 capture  7        tB<-bus x3080  tB<-acc x3080  - x2840  tA<-acc x2660 …
       ACTION 0x19 acc op   5        +bus x4340  bus x4340  bus-acc x4340  -bus x2940  - x560
       ACTION 0x19 capture  3        tA<-acc x12740  tB<-bus x2660  tB<-acc x1120
       ACTION 0x0B acc op   5        (all five, x3304 each)
```

★ **Exactly two things are FORCED over the whole 35×35×35 space: `SRC 0x00 =
DR` and `ACTION 0x00 = load`.** Everything else is a majority, not a forcing.
This is the count that stands directly against `action-field.md`'s and
`allpass-adder-rerun.md`'s **0 of 20 580 000** for the all-pass, from the same
enumeration, the same loop filter and the same matcher.

### 6.2 STRICT — the sub-space that actually ships

```
   [1] ADDER, strict
       2268 machines pass the delay-loop filter
       112 machines reproduce SOME topology at BOTH delay sets
          pipe-comb b+1 c+1 hold u_last     x192
          pipe-comb b+1 c+1 hold t_last     x144
          pipe-comb b+1 c+1 hold w_last     x144
          comb cascade, tap = stored        x48
          comb cascade, tap = delayed       x48
       SRC 0x00 reads    FORCED   DR x112
       read lands +n     2        0 x56  1 x56
       write data from   4        bus x28  acc_before x28  acc_after x28  M x28
       ACTION 0x00       FORCED   acc <- bus ; tA<-acc x112
       ACTION 0x19       FORCED   tB<-bus x112
       ACTION 0x0B       7        - x16 tA<-bus x16 tB<-bus x16 tA<-acc x16 …
       ACTION 0x00 acc op    FORCED   bus x112
       ACTION 0x00 capture   FORCED   tA<-acc x112
       ACTION 0x19 acc op    FORCED   - x112
       ACTION 0x19 capture   FORCED   tB<-bus x112
       ACTION 0x0B acc op    FORCED   - x112
```

**112, against the 0 the same space returns for the all-pass.** The all-pass
reference is inside this very reference set and no survivor matches it — the
published zero is reproduced by the run that overturns its interpretation.

### 6.3 The decoded core, slot by slot

The symbolic trace of a survivor (`SRC 0x00 = DR`, `land = 0`, write from the
bus). `N` = this repetition's delay read `w[r]`; `P` at entry = `t[r−1]`, the
previous stage's product; `Q` = this repetition's product `t[r]`:

```
   slot 0  880.1.60.2D4  DRAM READ    DR <- w[r]
   slot 1  104.2.00.000  acc <- bus(SRC 0x00 = DR) = w[r] ;  tA <- acc
   slot 2  000.2.00.419  acc <- P = t[r-1] ;  ACTION 0x19: tB <- bus = w[r]
   slot 3  012.2.00.680  ST: mem[ptr] <- t[r-1] ;  acc <- tB + P = w[r] + t[r-1] ;  tA <- acc
   slot 4  880.1.20.655  DRAM WRITE   line[r-1] <- tA = w[r] + t[r-1]
   slot 5  102.A.00.64B  MULTIPLY     P <- g[r] * tA = t[r]
   slot 6,7  000.2.00.000  housekeeping; overwritten at the next slot 1
```

★ **`u[r] = w[r] + t[r−1]`, stored into the delay line AND multiplied by
`g[r]`.** With `d_{k}[n] = u_{k+1}[n]` and `w_k[n] = d_k[n−D_k]`:

```
      u_k[n] = u_{k+1}[n − D_k] + g_{k−1}·u_{k−1}[n]
```

Every delay line carries a self-loop of gain **`g_k z^-D_k`** (line k → its own
read → `u_k` → `t_k` → `u_{k+1}` → line k). The signal runs *backward* through
the delay lines and *forward* through the product chain: **a chain of nested
feedback combs**, which is the recirculating half of a Schroeder reverberator,
not its all-pass half. The ladder input enters as `t[−1]`, i.e. through the
product register — which is exactly what the five-word separator in front of
every ladder supplies (one DRAM read + one class-A multiply).

### 6.4 The write source selects WHICH comb network — and it is not forced

| write data from | what the line stores | topology |
|---|---|---|
| `bus` / `acc_before` / `acc_after` (84 of 112) | `u[r] = w[r] + t[r−1]` — **write == multiplicand** | the nested chain of §6.3 |
| `mem[ptr]` (28 of 112) | `t[r−1]` — the previous product | **`t_k = g_k·t_{k−1}/(1 − g_k z^-D_k)`: a textbook cascade of feedback combs**, `comb_series_ref` up to one overall constant |

Both are comb networks with per-line loop gain `g_k`; **"the core is a comb
network" is FORCED, "which comb network" is not.** The `mem[ptr]` branch is the
one route by which the write value can differ from the multiplicand at all, and
it is what makes a textbook cascade reachable.

### 6.5 SEQUENTIAL — the same answer in the model the adder replaced

```
   [2] sequential, generous
       52696 machines pass the delay-loop filter
       10080 machines reproduce SOME topology at BOTH delay sets
       SRC 0x00 reads       FORCED   DR x10080
       ACTION 0x00 acc op   FORCED   bus x10080
       ACTION 0x19 acc op   3        +bus x3360  -bus x3360  bus-acc x3360   ("-": ZERO)
       ACTION 0x19 capture  2        tA<-acc x6720  tB<-acc x3360
```

★ **`ACTION 0x00 = load` and `SRC 0x00 = DR` are FORCED in all three spaces and
under BOTH accumulator models.** Whatever else is uncertain, those two do not
depend on the model that `acc-adder.md` replaced — the failure mode that made
the all-pass zero's *diagnosis* worthless is not present here.

### 6.6 ★★ THE JOINT ROW — and a THIRD contradiction, which then resolves

`action-field.md` §6 / `allpass-adder-rerun.md` §8 FORCE, from SINGLE DELAY — a
five-word block *whose algorithm is not in doubt* — that **`ACTION 0x19`
captures into tempA**: 5 635/5 635 at the shipped order and `tA<-acc`
22 050/22 050 at act-first.

★ **The STRICT comb survivors say `tB ← bus`, 112/112 (§6.2). That is a direct
contradiction, and it is new.** It is *not* a contradiction of the comb: it is a
contradiction of the STRICT VOCABULARY, because in that sub-space `ACTION 0x19`
is forbidden an accumulator half, and then the only way to get `w[r]` to slot 3
is through tempB.

Rule, from the brief and earned twice before: **a parameter settled in another
context is not settled inside your search.** So it is *enumerated*, restricted —
row 3 re-runs the whole search with `ACTION 0x19`'s capture half restricted to
tempA and everything else free:

```
   [3] ADDER, generous + SINGLE DELAY's ACTION 0x19 -> tempA
       67088 machines pass the delay-loop filter
       12740 machines reproduce SOME topology at BOTH delay sets
       SRC 0x00 reads       FORCED   DR x12740
       ACTION 0x00 acc op   FORCED   bus x12740                     (load)
       ACTION 0x19 capture  FORCED   tA<-acc x12740
       ACTION 0x19 acc op   4        +bus x3500  bus x3500  bus-acc x3500  -bus x2240
                                     -- "no accumulator effect": ZERO
       ACTION 0x00 capture  5        tB<-bus 3080  tB<-acc 3080  - 2840  M<-acc 2020  M<-bus 1720
                                     -- tA<-bus and tA<-acc: ZERO
       read lands +n        2        0 x6370  1 x6370
       write data from      4        bus 5600  M 3660  acc_before 1740  acc_after 1740
```

**12 740 survive.** So the contradiction is not between the comb and SINGLE
DELAY at all — it is between **the strict vocabulary** and SINGLE DELAY. What
the joint row then forces:

* ★ **`ACTION 0x19 = ⟨an accumulator op⟩ ; tA ← acc`** — the capture half is
  FORCED to `tA ← acc`, which is *exactly* the value SINGLE DELAY's act-first
  arm forces at 22 050/22 050 and one of the two the shipped-order arm allows.
  **Two independent blocks now agree on a whole half-code.**
* ★★ **`ACTION 0x19` must ALSO route the bus into the accumulator** — "no
  accumulator effect" has **ZERO** survivors among the 12 740. That
  **FALSIFIES the STRICT reading** (*"only `ACTION 0x00` routes the bus; `0x19`
  and `0x0B` are capture-only"*, `allpass-adder-rerun.md` §4.1, and what the
  device currently implements) **conditional on the comb topology plus SINGLE
  DELAY's tempA** — and both of those are now the best-evidenced things on this
  chip. It is also the same demand SINGLE DELAY makes of `ACTION 0x00`.
* ★ **`ACTION 0x00` must NOT capture into tempA** — `tA<-bus` and `tA<-acc` have
  ZERO survivors once `0x19` owns tempA. Its capture half is one of
  `{none, tB←bus, tB←acc, M←bus, M←acc}`.

The §0-C result (`ACTION 0x00 ; tA ← acc` FORCED in the strict space) is
therefore **the strict space's answer, not the chip's**, and it is withdrawn as
a determination — see §8.

---

## 7. What is now FORCED, CONSISTENT and OPEN

**FORCED**

* ★ **The reverb core is a COMB network, not an all-pass.** 16 520 / 20 580 000
  generous, 10 080 / 20 580 000 sequential, 112 / 823 200 strict, 12 740 joint —
  against **0** for the all-pass in every one of them, at two delay sets, with a
  positive control that is demonstrated to reject the write==multiplicand
  property and accept the comb.
* ★ **`ACTION 0x00`'s accumulator half is `acc ← bus` (`load`).** 16 520/16 520,
  10 080/10 080, 112/112, 12 740/12 740 — **all three spaces and both
  accumulator models.** Agrees with the 18/18 three-context joint solve and with
  the shipped `exec_alu()`. **Live contradiction #1 is resolved.**
* **`SRC 0x00` reads the delay-RAM data register** — FORCED in every row.
  Contradiction #2 is untouched and now has a fifth witness.
* **The multiplicand is `w[r] + t[r−1]`** — the fresh read plus the previous
  stage's product, and (when the write takes the bus) the same number is written
  to the line.
* **At `hi12[3:1] == 0`, `+bus`, `load` and `rload` are indistinguishable** —
  PROVEN BY CONSTRUCTION; only motif slots 1 and 3 can separate them.

**FORCED CONDITIONALLY** — inside the comb hypothesis *and* SINGLE DELAY's
`ACTION 0x19 → tempA` (§6.6, row 3, 12 740 machines):

* ★ **`ACTION 0x19`'s capture half is `tA ← acc`** — 12 740/12 740, and SINGLE
  DELAY's act-first arm forces the identical value at 22 050/22 050.
* ★ **`ACTION 0x19` also routes the bus into the accumulator** — "no accumulator
  effect" has ZERO survivors, which **falsifies the strict vocabulary**.
* **`ACTION 0x00` does NOT capture into tempA** — zero survivors.

**CONSISTENT, not forced**

* The write data source (`bus` / `acc_before` / `acc_after` / `mem[ptr]`), the
  read landing slot (0 or 1), `escact`, `ACTION 0x0B` in both halves, and
  `ACTION 0x19`'s accumulator op (4 values).
* The closed-form transfer function of §6.3's chain — derived from one FORCED
  assignment, not independently measured.
* The delay line living in the **external DRAM**: every survivor's loop runs
  through `DR`, and the reverb touches only 14 distinct D-RAM cells in 133
  words. The 133-word image contains **32** escape/class-1 external-DRAM words.
* **Preset-independence** — MEASURED here (one byte-identical 133-word image for
  algos 16–27) and structural: no preset enters the symbolic stage at all.

**OPEN**

* **`SRC 0x00`.** The last unresolved contradiction. The reverb needs `DR`
  (52 696/52 696, 13 230/13 230, and now 16 520/16 520); SINGLE DELAY forbids it
  (0 of 5 635). A **third** kind of block that reads `SRC 0x00` is now the
  highest-value experiment left on this chip.
* **`ACTION 0x19`'s accumulator op** — 4 values, and SINGLE DELAY does not pin it
  either. Its *capture* half is now joint-forced; its *accumulator* half is the
  next cheap win.
* **Which comb network** — the write-source choice (§6.4).
* **What feeds the ladder** and what the output stage does with it: this pass
  decodes the *core*, not the 133-word program around it.
* **Whether any of this can be turned on.** Nothing here is adopted into the
  device: an unproven word must keep trapping, and the codes above are forced
  *inside a topology hypothesis that is now well supported but not unique*.

---

## 8. What this changes about earlier claims

| claim | where | status |
|---|---|---|
| "the reverb core is not a first-order all-pass" | `action-field.md`, `allpass-adder-rerun.md` | **STANDS** — reproduced inside this pass's own reference set, 0 matches |
| "the obstruction is the WRITE, not the clear" | `allpass-adder-rerun.md` §6.3 | **STANDS**, and is now read *forwards*: the same coupling that forbids an all-pass is what makes a comb |
| positive control "MATCH inject=P extract=P scale=+1.000" | `action-field.md` §4, `allpass-adder-rerun.md` §4/§4.1 | ★ **RETRACTED** — the delays never recirculated; the true figures are `extract=M, scale=−1.000` |
| "`ACTION 0x00` = `load` is refuted by the all-pass hypothesis" | `allpass-adder-rerun.md` §7 | ★ **SUPERSEDED** — the all-pass hypothesis is falsified and the *comb* hypothesis forces `load`. The two determinations now agree. |
| "any fourth context separating `load` from `add` decides both questions" | `allpass-adder-rerun.md` §7 | **DELIVERED**, and the answer is `load` |
| "`sec_schroeder` is the obvious next acceptance test" | `allpass-adder-rerun.md` §7 | **DONE** — and it needed a *new* section, because the existing `sec_schroeder` tests a different proposition |
| "only `ACTION 0x00` routes the bus; `0x19` and `0x0B` are capture-only" (the STRICT reading, and what the device implements) | `allpass-adder-rerun.md` §4.1 | ★★ **FALSIFIED, conditionally** — it forces `ACTION 0x19 = tB ← bus`, contradicting SINGLE DELAY's tempA (5 635/5 635 and 22 050/22 050). Restricting `0x19` to tempA instead leaves 12 740 comb survivors, every one of which needs `0x19` to route the bus too |
| "`ACTION 0x00` also captures `tA ← acc`, FORCED 112/112" | **this note, §0-C, strict row** | ★ **WITHDRAWN by this note itself** (§6.6). That is the strict space's answer; once `0x19` owns tempA, `ACTION 0x00` capturing into tempA has ZERO survivors |

---

## 9. What this constrains for the other two targets

* **`ACTION 0x00 = load` is now agreed by four contexts and both accumulator
  models** (biquad + LFO + SINGLE DELAY jointly, and the reverb comb in three
  spaces). Any pass holding the `load`/`add` question open can close it.
* ★ **`ACTION 0x19 = ⟨bus op⟩ ; tA ← acc`** — the capture half is now agreed by
  two independent blocks. Any block that assumed `0x19` was capture-only, or
  that it captured from the bus rather than the accumulator, should be re-run.
* ★★ **The strict vocabulary is falsified conditionally** — `0x19` routes the
  bus. This is a constraint on *every* remaining ACTION solve, and it enlarges
  the space each of them must search.
* ★ **`hi12[3:1] == 0` hides the `load`/`add`/`rload` distinction entirely.** Any
  determination of an ACTION's accumulator half made at such a word is
  **vacuous**, in any block. This is worth sweeping for.
* ★ **Check every numeric control for delay degeneracy.** The rule: a delay
  network run for fewer samples than its shortest delay is not a delay network.
  `output_stage.py`, `lfo_ramp.py` and `closure_pointer.py` should be audited
  for the same pattern.
* **`SRC 0x00`** is the one contradiction left; a third context for it is the
  highest-value remaining experiment on this chip.

---

## Appendix — the prediction, verbatim

> # PREDICTION — written before a single line of the new code was written or run
>
> Recorded 2026-07-27, from `action-field.md`, `allpass-adder-rerun.md` and the
> brief alone.  Nothing below was informed by a run of the new section.
>
> ## P0. What the located obstruction says, as a difference equation
>
> Slot 4 (`880.1.**.655`, DRAM WRITE, `src = 0x19 = tempA`) and slot 5
> (`102.A.**.64B`, the class-A MULTIPLY, `src = 0x19 = tempA`) are ADJACENT and
> nothing between them writes tempA.  Whenever the write takes its data from the
> BUS, the value stored into the delay line and the value presented to the
> multiplier are **one and the same number**.  Call it `u`.
>
>     line  <- u
>     t      = g * u          (the product; visible to LATER slots as P)
>     w      = u[n - D]       (what the line returns D samples later)
>
> Two immediate consequences, both pure algebra:
>
>   (i)  `g*w[n] = t[n-D]`.  The delayed product is NOT recomputed — it is what the
>        line already holds, scaled.  But the chip never stores `t`, so it cannot
>        READ `g*w`; it can only read `w`.
>   (ii) Within ONE repetition the multiplier's output cannot re-enter the line it
>        just wrote (the write precedes the multiply by one slot, and each line is
>        touched once per sample).  Therefore, **within a repetition, the loop gain
>        around a line is whatever the ALU can supply — and the ALU only adds, so
>        it is 0 or ±1.**  ±1 puts the pole ON the unit circle: not a filter.
>
> ## P1. So where CAN a legal loop gain come from?  Only from the pipeline.
>
> With the write trailing the read by one repetition (`wtrail = 1`, what the
> searches use), repetition `r` reads line `r` and writes line `r-1`.  Writing
> `u_r = a·x + b·w_r + c·t_{r-1}` (coefficients ±1/0, the only ones the ALU has):
>
>     d_k[n] = u_{k+1}[n] = a·x + b·w_{k+1}[n] + c·t_k[n]
>     t_k[n] = g_k·u_k[n] = g_k·(a·x + b·w_k[n] + c·t_{k-1}[n])
>     w_k[n] = d_k[n - D_k]
>
>   =>  d_k[n] = (b·c·g_k)·d_k[n-D_k] + (terms not involving line k)
>
> ★ **THE LOOP GAIN AROUND LINE k IS `b·c·g_k`.**  The recirculation exists, it is
> properly damped, and it closes through the multiplier exactly once — via the
> path `w_k -> u_k -> t_k -> u_{k+1} -> line k`, i.e. ACROSS the repetition
> boundary.  This is the denominator `1 - g z^-D`: **a FEEDBACK COMB.**
>
> ## P2. Which classical structures the 6-word core CAN and CANNOT express
>
> **CANNOT — committed predictions:**
>
> * **A first-order all-pass / a Schroeder all-pass / a Gardner one-multiplier
>   all-pass.**  These are the SAME transfer function `(z^-D − g)/(1 − g z^-D)`,
>   and the published zeros already reject that transfer function twice.  A
>   "Schroeder all-pass" tested as a REFERENCE therefore cannot be a new result:
>   the numeric matcher only ever sees input/output, so re-testing it must return
>   the same zero.  ★ **Anything the new section can add must be a DIFFERENT
>   transfer function.**
> * **A two-multiply Schroeder all-pass (comb + feed-forward, `y = w − g·c`).**
>   Same transfer function again, and it needs `g` twice per stage; the core has
>   ONE class-A word.
> * **A bank of INDEPENDENT parallel combs.**  P1's loop needs `b ≠ 0`, and `b` is
>   the same coefficient at every repetition, so `b·w_{k+1}` necessarily also
>   lands in line k's input: the lines are unavoidably CROSS-COUPLED.  A structure
>   with `d_k` a function of `x` and `d_k` only is not reachable.
>
> **CAN — committed predictions:**
>
> * **A feedback comb (`1/(1 − g z^-D)`) per line, cross-coupled to its
>   neighbours** — a nested / series comb network, which is exactly the
>   Schroeder-reverberator *comb* half rather than its all-pass half.
> * Consequently a **nested comb / lattice-like chain** in which the product chain
>   runs FORWARD through the ladder while the delay reads feed BACKWARD (rep `r`
>   reads line `r`, writes line `r-1`).
>
> ## P3. What that predicts about the existing filter — the sharpest one
>
> `loop_ok`'s C1/C2/C3 are, read carefully, conditions on the DENOMINATOR only:
> C1 the fresh read reaches the multiplier with ±1; C2 the product reaches the
> line one repetition later with ±1; C3 nothing unmultiplied gets back.  Together
> they say precisely "the only loop through line k has gain ±g_k".  **They are the
> COMB conditions, not the all-pass conditions** — the all-pass part lives entirely
> in the numerator and is tested only by the numeric matcher.
>
> ★ **PREDICTION P3:** the 74 508 machines that pass the delay-loop filter under
> the adder (52 696 sequential) ALREADY have a correct comb denominator, and the
> numeric test rejected them ONLY on the numerator.  So a comb reference tested
> over that same survivor set should be able to return a NON-ZERO count.  If it
> returns zero as well, the obstruction is deeper than the numerator and the next
> suspect is the injection/extraction topology, not the stage algebra.
>
> ## P4. What survivors, if any, must force
>
> If any comb survivor exists it must have `b ≠ 0` and `c ≠ 0`, i.e. the fresh
> read reaches the multiplicand AND the previous product reaches the write.  By
> `allpass-adder-rerun.md` §6.1 that is the same demand that forced
> `ACTION 0x00 ∈ {+bus, −bus, bus−acc}` and forbade `load` — so **I predict comb
> survivors will ALSO refuse `load`,** and the `ACTION 0x00` contradiction will
> sharpen rather than resolve.  `SRC 0x00 = DR` should again be forced (the fresh
> read has no other path to slot 1's operand).
>
> ## P5. Failure modes I expect to have to report
>
> * The comb reference has a free choice of OUTPUT tap (stored value vs. delayed
>   value vs. product) and of whether stages are SERIES or PARALLEL; I expect to
>   have to enumerate those rather than pick, and I expect at most one of them to
>   survive if any does.
> * I expect the OLD `sec_schroeder` (section 9 of the tool) to be a different
>   test from this one — it asked whether a GARDNER machine can have
>   `WVAL == MULT`, and answered no.  That is P2's first bullet, not P1's comb.
