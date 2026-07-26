# R1 — the 8-word all-pass motif, forced by constraint solving

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Roadmap item **R1**
(`kn7000_mame/notes/dsp-next-steps-roadmap.md` §4). Date: 2026-07-26.
Tool: [`../tools/r1_allpass_solve.py`](../tools/r1_allpass_solve.py) — stdlib only,
re-runnable, prints every number quoted here.

Every claim carries a label: **MEASURED** (read out of the ROM),
**PROVEN BY CONSTRUCTION** (the firmware builds the value and we read the builder),
**FORCED** (every survivor of the exhaustive search agrees), **CONSISTENT** (some
survivors have it, some do not), **FREE** (the constraints say nothing),
**INFERRED**, or **OPEN**. Where the constraint system admits several assignments
they are all enumerated; none is silently picked.

No hardware was available. Nothing here is a recording.

---

## 0. Result in one page

The motif's **6-word core** is a **software-pipelined one-multiplier all-pass
stage**. Repetition *r* carries the arithmetic and the delay-line **write** of
stage *r−1* together with the delay-line **read** and the **multiply** of stage
*r*. That is not a story fitted to the code: it is the only shape the word order
allows, and it comes out of an exhaustive search that was told the mathematics of
an all-pass and nothing else.

**FORCED in every model tried** — the 36 machines of the base model, the 336 of
the 3-input-ALU variant and the 454 of the ALU-on-the-DRAM-word variant all agree:

| # | statement |
|---|---|
| F1 | `880.1.60.2D4` (slot 0) is the external-DRAM **READ**; `880.1.20.655` (slot 4) is the **WRITE**. The direction is not free — the opposite assignment has zero survivors in every model. |
| F2 | The `hi12` bit-4 store on `012.2.00.680` (slot 3) takes the accumulator **BEFORE** that word's own ALU step. `store = after` has zero survivors in every model. |
| F6 | The external-DRAM read data becomes visible **2 to 5 words** after the `880.1.60` word (`land ∈ {2,3,4,5}`; 0 and 1 have zero survivors). |

**FORCED by construction, not by the search** — these are how the constraint
system is set up, and each is argued in §4.2 / §4.3 rather than discovered:

| # | statement |
|---|---|
| F3 | The delay-line **write trails the read by exactly one stage**: at repetition *r* the machine reads line *r* and writes line *r−1*. Trailing by ≥1 is forced (the multiply is at slot 5, both DRAM words are before it); trailing by exactly 1 is the minimal choice and is **assumed**. |
| F5 | `P` at repetition entry is the **previous stage's product** — only the class-A word writes it, and there is exactly one per repetition. |
| F7 | One D-RAM cell serves an entire ladder: `addr8 == 0` on all four class-2/A core words (**MEASURED**), so the pointer never moves inside a ladder. |

**FORCED under a two-input ALU, NOT under a three-input ALU** — labelled as
model-dependent, because they are:

| # | statement |
|---|---|
| F4 | The accumulator at the repetition boundary holds **s[r] = x[r] + w[r]**, the multiplier's operand — not x, not y (36/36). |
| F8 | The class-A word's **multiplicand is the ALU result of that same word** (`msrc = acc_after`, 36/36). |

Both fall to the 3-input ALU together, and for the same reason: with three ALU
inputs an *earlier* word can build `s[r] = D − P + N` in one step and the store
can park it in `mem[ptr]`, so 260 of the 336 3-input survivors take the
multiplicand from `mem[ptr]` and leave the accumulator free. F4 and F8 are
therefore properties of the **model**, not of the data, and are labelled so.

**NOT determined — two families survive, and the numbers cannot separate them.**
Both reproduce a textbook all-pass cascade at **max|err| = 0.000e+00** over all
12 preset coefficient banks and both ladder lengths:

* **Family A** (32 of 36 machines) — `mem[ptr]` carries the inter-stage signal
  *x*; the DRAM write takes the **accumulator**. `104.2.00.000` (slot 1) then has
  **no job**: all 33 modelled ALU operations work there, in 24 of the 36
  machines — every family-A machine with `land ∈ {3,4,5}`.
* **Family B** (4 of 36 machines) — `mem[ptr]` is a **one-word staging register
  for the DRAM write**; the accumulator carries *s*. Every one of the six words
  does necessary work.

Family B is **ranked first** on two pieces of corpus evidence (§7), not asserted.
Family A reproduces the annotation currently in the `.dsm` listings; family B
swaps slots 2 and 3. **This is the honest state: R1 narrows the motif from
"6 unknown words" to a 2-way choice, with three facts forced in every model
tried, three more forced by the construction of the constraint system, and two
that hold only under a 2-input ALU. It does not close the 2-way choice.**

---

## 1. The motif — MEASURED

`tools/r1_allpass_solve.py census motif`.

The 6-word **core**, `addr8` wildcarded:

```
   slot0   880.1.60.2D4      external-DRAM word #1
   slot1   104.2.00.000      the "all-pass marker"
   slot2   000.2.00.419
   slot3   012.2.00.680      hi12 bit 4 = store acc -> mem[ptr]
   slot4   880.1.20.655      external-DRAM word #2
   slot5   102.A.00.64B      THE multiply (class A -> coefficient cursor +1)
 [ slot6   000.2.00.000      nop ]
 [ slot7   000.2.00.000      nop ]
```

**114 occurrences of the core, in 13 programs, all of them reverbs** — the twelve
reverb presets (algos 16–27, which share one 133-word image byte-for-byte) at
9 each, and GATED REVERB (algo 8) at 6. 113 of the 114 carry the two trailing
nops.

Per-word corpus frequency:

```
   880.1.60.2D4   115 occurrences  13 programs      <- reverb-exclusive
   104.2.00.000   122              16 programs      <- also ENHANCER, PHASER
   000.2.00.419   115              13 programs      <- reverb-exclusive
   012.2.00.680   115              13 programs      <- reverb-exclusive
   880.1.20.655   115              13 programs      <- reverb-exclusive
   102.A.00.64B   101              13 programs      <- reverb-exclusive
   000.2.00.000   273              27 programs      <- the generic nop
```

The only field that ever varies across the 114 core occurrences is **`addr8` of
slot 5**: `0x00` ×101, `0xBA` ×12 (once per reverb preset, at the head of
ladder 1), `0xC4` ×1 (GATED REVERB). Every other field of every other word is
constant.

The four-word run `104.2.* | 000.2.00.419 | 012.2.00.680 | 880.1.20.655` is
**exceptionless**: `000.2.00.419` is preceded by a `104.2.*` word 115/115 and
followed by `012.2.00.680` 115/115; `012.2.00.680` is followed by
`880.1.20.655` 115/115. The group never decomposes.

### 1.1 Three corrections to the existing write-ups — PREDICT-THEN-CHECK misses

I started from `dsp/algorithms/reverb.md` and
`kn7000_mame/notes/kn5000-dsp-reverb.md` and re-measured everything. Three
published statements do not survive:

| published | measured | where |
|---|---|---|
| "GATED REVERB … 4 occurrences" | **6** cores (5 with trailing nops) | `-reverb.md` §1.2 |
| "the motif is **byte-identical** at every repetition" | slot 5's `addr8` varies (`0xBA`, `0xC4`); `-reverb.md` §1 states this correctly, `algorithms/reverb.md` does not | `algorithms/reverb.md` |
| "two ladders of **five** all-pass diffusers"; "strictly descending gain ladders" | ladder 1 has **four** core repetitions, and the gains are **not** descending in PLATE REVERB 2 or BRIGHT REVERB 1 | `algorithms/reverb.md` |

None of these changes the R1 result; they are reported because they were the
inputs I would otherwise have trusted.

---

## 2. The coefficients — MEASURED, with the bank base PROVEN BY CONSTRUCTION

The coefficient cursor advances +1 per class-A word from the unit-1 bank base, so
the C-RAM cell each repetition reads is arithmetic, not a guess:

```
   ladder 0 (5 core repetitions)  C-RAM 0x98 0x99 0x9A 0x9B 0x9C
   ladder 1 (4 core repetitions)  C-RAM 0xA1 0xA2 0xA3 0xA4
```

The **base 0x90 is now proven, not inferred**. Each type-2 coefficient block in
the parameter stream is immediately preceded by a literal 5-byte packet
`08 01 0N N8 21`, which *is* the instruction word `801.0.NN.821` in the writer
encoding proven by construction in [`k5-output-stage.md`](k5-output-stage.md) —
i.e. `ldptr #$NN`. For all twelve reverb presets that packet reads **`ldptr #$90`**
followed by 30 cells (0x90..0xAD) and then `ldptr #$AE` followed by 7 more.
GATED REVERB, a unit-0 program, says `ldptr #$00`. *(This falls out of K5 for
free; it was not part of R1's brief.)*

The gains the firmware actually loads:

| preset | ladder 0 (0x98..0x9C) | ladder 1 (0xA1..0xA4) |
|---|---|---|
| ROOM REVERB 1 | 0.7500 0.6300 0.5200 0.5000 0.4000 | 0.6300 0.6200 0.5200 0.4000 |
| ROOM REVERB 2 | 0.7500 0.6300 0.5200 0.5000 0.4000 | 0.6300 0.6200 0.5200 0.4000 |
| PLATE REVERB 1 | 0.7500 0.6300 0.5200 0.5000 0.4000 | 0.6300 0.6200 0.6200 0.4000 |
| PLATE REVERB 2 | 0.7500 0.5000 0.5200 0.6300 0.4000 | 0.4000 0.6200 0.5200 0.6300 |
| CONCERT REVERB 1 | 0.7500 0.6300 0.6200 0.6000 0.5000 | 0.7300 0.7200 0.7000 0.6000 |
| CONCERT REVERB 2 | 0.7500 0.6300 0.5200 0.5000 0.4000 | 0.6300 0.6200 0.5200 0.4000 |
| DARK REVERB 1 | 0.7500 0.6300 0.5200 0.5000 0.4000 | 0.6300 0.6200 0.5200 0.4000 |
| DARK REVERB 2 | 0.7500 0.6300 0.5200 0.5000 0.4000 | 0.6300 0.6200 0.5200 0.4000 |
| BRIGHT REVERB 1 | 0.6000 0.6300 0.3000 0.4000 0.7500 | 0.6300 0.6200 0.4200 0.5200 |
| BRIGHT REVERB 2 | 0.2000 0.7500 0.6300 0.5200 0.5000 | **−0.2526** 0.6300 0.6200 0.5200 |
| WAVE REVERB 1 | 0.7500 0.6300 0.5200 0.5000 0.4000 | 0.6300 0.6200 0.5200 0.4000 |
| WAVE REVERB 2 | 0.7500 0.6300 0.5200 0.5000 0.4000 | 0.6300 0.6200 0.5200 0.4000 |

All are inside the unit circle, so every stage is a stable all-pass.

**MEASURED, unexplained:** BRIGHT REVERB 2 (algo 25) writes **38** cells where
every other preset writes 37, from the same `ldptr #$90`. Its whole bank therefore
sits one cell later and every coefficient role in it is shifted by one — which is
why its ladder-1 head reads −0.2526 and its "input scaling triple" runs
0.25 / 0.2968 / 0.81 instead of the 0.25 / 0.5 / 0.5 the other eleven share.
Either a firmware bug or an undecoded extra parameter. **Reported, not repaired**;
it does not affect the solve (the search never uses a coefficient value, and the
numeric check passes for this preset too because an all-pass works for any |g|<1).

---

## 3. The delay lines — MEASURED

From the parameter stream (external-DRAM `(end, start)` address pairs, two
interleaved contiguous chains):

```
   ROOM REVERB 1     chain 0   127  435  489  183  522     (5 buffers)
                     chain 1  4452  264  626  180  337 488 (pre-delay + 5)
   CONCERT REVERB 1  chain 0   452  978 1077  691  789
                     chain 1  4578  638 1462  496  774 870
   GATED REVERB      chain 0   858 1263 1120 1780          (4 buffers)
```

5 buffers ↔ 5 core repetitions in ladder 0. Chain 1 has 5 recirculating buffers
after its ≈4.5 k-word pre-delay head against **4** core repetitions in ladder 1 —
the "9 stages vs 10 buffers" off-by-one the reverb note flagged is real and R1
does not close it (§8).

Taken raw the payloads are 17-bit word addresses. The host-poke decode of the
*same* 5-byte packet would give `(payload<<1)|(sel>>7)`, one bit wider, and the
`sel` byte does alternate 0x4C/0xCC exactly as an LSB would. **17 vs 18 delay
address bits remains OPEN** (roadmap R3/H3). **The all-pass solve does not depend
on it** — it constrains only the read/write line *offset*, which it forces to one
stage (F3).

---

## 4. The constraint system

### 4.1 The mathematics, stated before looking at the code

A first-order all-pass with delay *D* and coefficient *g*:

```
    y[n] = -g·x[n] + x[n-D] + g·y[n-D]        H(z) = (z^-D - g)/(1 - g z^-D)
```

The realisation costing **one** multiply (Gardner / Dattorro) is

```
    w    = delay_read(D)
    s    = x + w
    t    = g · s                    <- the single multiply
    d_in = x + t                    -> delay_write
    y    = w - t                    -> the next stage's x
```

(Transfer check: `D_in = (1+g)X + gW`, `W = z^-D D_in` ⇒
`Y = (1-g)W - gX = X(z^-D - g)/(1 - g z^-D)`. Unit modulus. ✔)

### 4.2 What the word order forces *before* any search

`t[r]` is produced by the only class-A word in the core, at **slot 5**. Both
external-DRAM words sit at slots 0 and 4, i.e. **before** it. Therefore the
delay-line write performed in repetition *r* **cannot** carry `d_in[r]`; the most
recent value it can carry is `d_in[r−1]`. The core is **software pipelined** and
the write trails the read. (Trailing by 2 or more is not excluded by this
argument alone, but would need a second register to hold `d_in` across a whole
repetition; the search assumes the minimal offset of 1. **Stated as an
assumption.**)

Two consequences fall out immediately and are used as the search's acceptance
tests:

```
    x[r] = y[r-1] = w[r-1] - t[r-1] = D - eta·P
    s[r] = x[r] + w[r]              = D - eta·P + N
    the delay write must emit  d_in[r-1] = x[r-1] + t[r-1]
```

where at repetition entry `P` is the previous product, `D` the previous DRAM read,
and `N` the value this repetition's read returns. `eta = ±1` is a **label**, not a
machine decision: it records whether the product register is read as `+t` or `−t`.
Both values survive by symmetry, as they must.

### 4.3 The machine model — declared, with each assumption argued

* **Visible state**: `acc`, `P` (the pending product), `M = mem[ptr]`,
  `DR` (the external-DRAM read-data register). Four registers.
  *Argued*: `mem[ptr]` is the only D-RAM the core can touch (F7); `P` is
  established by the three DETERMINED multiply forms; `DR` must exist because the
  read and its use are separated by whole words.
* **ALU**: a slot may compute `acc ← signed sum of at most two of the four`.
  33 operations including identity and `acc ← 0`. *Argued*: nothing a
  two-input ALU with an accumulator can do in one word is excluded. The
  three-input variant is run as a sensitivity check (§6.3).
* **Slot 3** carries `hi12` bit 4 (MEASURED elsewhere): `mem[ptr] ← acc`, taken
  either before or after that word's own ALU step. Both searched.
* **Slot 5** is class A: it consumes the cursor coefficient and writes `P`. Its
  multiplicand is searched over `{acc before, acc after, mem[ptr], DR}`.
* **Slots 0 and 4** are the external-DRAM words; one is the read and one the
  write, both directions searched. In the base model they perform **no** ALU step.
  *Argued*: `hi12 = 0x880` has **bit 11 set**, the MEASURED **FORMAT ESCAPE** —
  "bits [10:0] mean something else" (`instruction-set.md`). Letting them drive the
  ALU anyway is run as a sensitivity check (§6.3).
* **Read latency**: the read data becomes visible in `DR` at a searched slot.

### 4.4 The acceptance tests

Exactly three, all pure algebra, applied to the symbolic result of running the six
slots over the entry atoms:

```
  1.  MULT   ==  eta·D - P + eta·N            the multiplicand is s[r]
  2.  DR at exit == N                          the fresh read has landed
  3.  substitute(WVAL) == D - eta·P + eta·Q    the INDUCTIVE STEP
```

Test 3 advances the written value by one repetition (`A→A_exit, P→Q, M→M_exit,
D→N`) and demands it equal `d_in[r] = x[r] + t[r]`. **No word is told what to
do.** The search enumerates every assignment and keeps whatever passes.

---

## 5. The result of the search

`tools/r1_allpass_solve.py solve` — 1000 expression tuples survive, collapsing to
**36 distinct machines** (two tuples are the same machine when they leave the same
symbolic value in every register).

Distribution of each decision over the 36:

```
   read_slot   0 ×36                     <- FORCED  (F1)
   store       old ×36                   <- FORCED  (F2)
   msrc        acc_after ×36             <- FORCED under a 2-input ALU (F8)
   A_exit      ±(D - P + N) ×36          <- FORCED  (F4)
   MULT        ±(D - P + N) ×36
   eta         +1 ×18, -1 ×18            <- a labelling symmetry, not a choice
   land        2 ×8, 3 ×8, 4 ×10, 5 ×10  <- CONSISTENT, bounded to [2,5]  (F6)
   WVAL        ±P±M ×32,  ±(A+P-D) ×4    <- the two families
```

### 5.1 Family B — every word does necessary work (4 machines, ranked first)

Canonical member (`land = 4 or 5`, `eta = +1`; the other members differ only in
the sign of the intermediate and in whether slot 1 or slot 2 performs the `+P`):

```
   entry invariant:  acc = s[r-1]   P = t[r-1]   DR = w[r-1]   mem[ptr] = d_in[r-2]

   slot0  880.1.60.2D4   start the DRAM read of line r     (data visible slot 4/5)
   slot1  104.2.00.000   acc <- acc + P              = s[r-1] + t[r-1]
   slot2  000.2.00.419   acc <- acc - DR             = x[r-1] + t[r-1] = d_in[r-1]
   slot3  012.2.00.680   mem[ptr] <- acc  (BEFORE)   ; acc <- DR - P = y[r-1] = x[r]
   slot4  880.1.20.655   DRAM write line r-1 <- mem[ptr]
   slot5  102.A.00.64B   acc <- acc + DR = x[r] + w[r] = s[r]
                         ; P <- coef[cursor++] · acc
   slot6/7 nop nop

   exit:  acc = s[r]   P = t[r]   DR = w[r]   mem[ptr] = d_in[r-1]     <- closes
```

`mem[ptr]` is a **one-word staging register between the store and the DRAM
write**. The two nops cover the remaining DRAM read latency.

### 5.2 Family A — `mem[ptr]` carries *x* (32 machines)

```
   entry invariant:  mem[ptr] = x[r-1]   P = t[r-1]   DR = w[r-1]   acc = s[r-1]

   slot0  880.1.60.2D4   start the DRAM read of line r
   slot1  104.2.00.000   (FREE -- all 33 modelled operations work)
   slot2  000.2.00.419   acc <- DR - P               = y[r-1] = x[r]
   slot3  012.2.00.680   mem[ptr] <- acc  (BEFORE)   ; acc <- P + mem[ptr] = d_in[r-1]
   slot4  880.1.20.655   DRAM write line r-1 <- acc
   slot5  102.A.00.64B   acc <- mem[ptr] + DR = s[r] ; P <- coef[cursor++] · acc
```

This family reproduces the annotation already in the `.dsm` listings
(`000.2.00.419` = "y ← d_out − t", `012.2.00.680` = "d_in ← x + t"). Its cost is
that `104.2.00.000` does nothing: slot 1 is completely free in 24 of the 36
machines, and in every family-A machine at `land ∈ {3,4,5}`.

### 5.3 What is FREE even inside a family

* the order of the two accumulate steps at slots 1 and 2 (family B);
* the sign of the intermediate value in `acc` after slots 1 and 3;
* `eta`, the sign convention on `P`;
* `land` within [2,5];
* in family A, the whole of slot 1.

---

## 6. Falsification

`tools/r1_allpass_solve.py verify`.

### 6.1 The test

Each surviving machine is **run** as a 5-stage and a 4-stage ladder over all
**12** preset coefficient banks and the ROM-measured delay lengths, and compared
sample by sample with a textbook all-pass cascade written independently from the
mathematics. Priming is **derived from each machine's own invariant** (a virtual
stage −1 with `x = 0`, `t = 0`, `w = input`), never chosen; the output is accepted
up to sign.

**36 of 36 machines match at max|err| = 0.000e+00.**

That is the correct outcome and it must be read correctly: the numeric pass is a
**correctness check on the algebra, not a discriminator**. Every survivor is a
genuine all-pass ladder; the numbers cannot tell them apart, because they were
selected for exactly that property.

### 6.2 The controls — the test must be able to fail

Each perturbs exactly one decision of one accepted machine, to a value that
machine does not have:

```
   (unperturbed)                            max|err| = 5.551e-17   <- accepted
   slot1 forced to acc<-acc                 max|err| = 1.514e-01
   slot2 forced to acc<-acc                 max|err| = 3.425e-01
   slot3 forced to acc<-acc                 max|err| = 2.698e-01
   slot5 forced to acc<-acc                 max|err| = 1.391e+00
   store takes acc AFTER its ALU            max|err| = 2.146e-01
   DRAM write source -> acc_before          max|err| = 2.146e-01
   multiplicand -> mem[ptr]                 max|err| = 5.202e-01
   multiplicand -> DR                       max|err| = 2.698e-01
   multiplicand -> acc_before               max|err| = 1.791e-01
   read data lands at slot 1 (too early)    max|err| = 2.698e-01
   read/write roles swapped                 max|err| = 6.060e-01
   ladder gains reversed                    max|err| = 2.565e-01
   one ladder gain perturbed by 1e-6        max|err| = 4.377e-07
```

Every control breaks it, including a 1 ppm change to a single gain — so the check
really does depend on the MEASURED coefficients and not merely on the structure.

One entry deliberately does **not** fail:

```
   sign convention eta flipped              max|err| = 5.551e-17
```

That is correct and is stated rather than hidden: `eta` labels how the product
register is *read*, not what the chip *does*. A "control" that flipped it and
failed would have meant the harness was wrong.

**A miss I made and am reporting.** The first version of this harness applied
`eta` twice — once as the label and once as a factor on the product — and
therefore rejected all 18 `eta = −1` machines and made "eta flipped" look like a
passing control. It also ran the "DRAM write source" control against a machine
that already had that source, so the control was a no-op that returned 0.000e+00.
Both were found by asking why a control had *not* failed. Fixed; the numbers above
are from the corrected run.

### 6.3 Sensitivity to the model

All three counts are of *distinct machines* under the same equivalence
(`canonical()`: read/write slots, latency, store timing, write source,
multiplicand source, sign label, and all four symbolic outputs).

| model | machines | F1 read@slot0 | F2 store=old | F6 land ∈[2,5] | F8 multiplicand |
|---|---|---|---|---|---|
| base: 2-input ALU, DRAM words inert | **36** | 36/36 | 36/36 | 36/36 | `acc_after` 36/36 |
| + slot 4 (the DRAM write) may also drive the ALU | **454** | 454/454 | 454/454 | 454/454 | — |
| 3-input ALU, DRAM words inert | **336** | 336/336 | 336/336 | 336/336 | `mem[ptr]` 260, `acc_after` 76 |

F1, F2 and F6 survive every model tried. **F4 and F8 do not** — they are
consequences of limiting the ALU to two inputs, and are labelled accordingly.

---

## 7. The corpus evidence that ranks family B first

Neither piece is a proof. Both are stated with their *n*.

### 7.1 The store→write pairing is exceptionless, and exclusive

Counted over the **42 distinct images** (so that the twelve presets sharing one
reverb image count once, not twelve times), for every `880.1.20.*` word, is the
immediately preceding word one that carries the `hi12` bit-4 store?

```
   base rate over all words          724 / 3195 = 22.7 %

   880.1.20.64B    28 sites   28 preceded by a store   100 %
   880.1.20.655    16 sites   16 preceded by a store   100 %
   880.1.20.2C7    40 sites    0                         0 %
   880.1.20.40B     7 sites    0                         0 %
   880.1.20.2D9     6 sites    0                         0 %
   880.1.20.2D5     3 sites    0                         0 %

   880.1.60.2D4 (the READ)  16 sites    0                 0 %
```

44/44 versus 0/56, against a 22.7 % base rate, and split cleanly by `lo12`. Under
family B the store is a **data dependency** of the write (it is what puts the
value in `mem[ptr]`), and the split says `lo12` selects the write-data source.
Under family A the adjacency is a scheduling coincidence — and a coincidence has
no reason to be exceptionless on two `lo12` values and absent on four.

**Caveat, stated:** the four zero-percent forms may not be writes at all, in which
case the 0/56 half of the split carries no information and only the 44/44 half
does.

### 7.2 `104.2.00.000` outside the reverb always follows a multiply

`104.2.00.000` occurs 122 times; **114** are the motif's slot 1 (one core, GATED
REVERB w63, uses the `0x407` variant instead — see below). The other **8** are in
ENHANCER (algo 3, ×4), PHASER (algo 5, ×2) and S.DELAY+PHASER (algo 68, ×2), and
**all 8** sit in the pattern

```
   102.2.xx.1CD | 212.A.xx.412 | 104.2.00.000 | ...
```

— immediately after a class-A multiply-and-store, i.e. exactly where "add the
pending product to the accumulator" belongs. That is family B's reading of slot 1
(`acc ← acc + P`), and it also **resolves the order ambiguity** of §5.3 in favour
of slot 1 doing the `+P` and slot 2 the `−DR`. Under family A the word is inert,
and the machine already has a nop it uses twice per motif (`000.2.00.000`,
273 occurrences) — a second, different encoding for "do nothing" in a family
(`hi12 = 0x104`) that has 42 distinct productive members is an odd thing to find.

There is also exactly **one** minimal pair: the core at GATED REVERB w63 has
`104.2.00.**407**` in slot 1 rather than `104.2.00.000` — every other field of
every other word identical. A *variant* of an inert word, in one place, is hard to
motivate; a variant of a word that routes an operand is ordinary. Note that
`lo12 = 0x407` is exactly the `mulst` multiplicand route "operand = acc"
(§9), which is what a route field would say here. *n = 1; noted, not leaned on.*

---

## 8. The separator — the cross-check that half fails

Every ladder is bracketed by a five-word separator, the same shape three times in
the reverb:

```
   @ 11  880.1.60.2DA | 000.A.00.695 | 000.2.BA.000 | 212.2.00.419 | 880.1.20.64B
   @ 59  880.1.60.2DA | 000.A.00.695 | 000.2.F3.407 | 212.2.00.419 | 880.1.20.64B
   @101  880.1.60.2DA | 000.A.00.695 | 000.2.FE.407 | 212.2.00.419 | 880.1.20.64B
```

**What fits.** The separator is `[DRAM 60] X Y Z [DRAM 20]` — the same three-word
window between the same two DRAM words as the core — and its last word before the
write carries the bit-4 store. That is precisely the **drain** of the software
pipeline the search forces: the store stages the last stage's `d_in` and the
`0x20` word pushes it to the line. Read that way the separator completes stage
K−1 exactly:

```
   w60 : acc <- acc - DR = x[K-1]
   w61 : acc <- acc + P  = d_in[K-1]
   w62 : mem[ptr] <- acc ; acc <- DR - P = the ladder output
   w63 : DRAM write line K-1 <- mem[ptr]
```

**What does not fit.** `w60` is a **class-A** word: it issues a new product and so
overwrites `P` before `w61` and `w62` can consume `t[K-1]`. The drain reading
therefore requires the product register to keep its old value for at least three
words after a class-A word — which is **in tension with the DETERMINED `mac` form**
(`acc += P ; P = coef·mem[p]`), whose consecutive use in the biquad implies a
one-word latency. Either the latency is per-`lo12`, or there is a second product
register (the block diagram has ACCA and ACCB), or the drain reading is wrong.
**OPEN.** It is reported because it is the one place the model visibly does not
close, not because it can be resolved here.

The same tension explains why the 9-repetition / 10-buffer off-by-one of §3 is not
closed: what the separators do with their own DRAM read (`lo12 = 0x2DA`, a
different address than the core's `0x2D4`) and their own coefficient (the
0.5 "DRAM tap gain") is a **different** question from R1's.

---

## 9. What the disassembler could adopt

Stated in the form `upd6383d.cpp` / `tools/dsp_disasm.py` would need, with the
bit patterns that select each form. **Nothing here should be adopted as a decode
until family A vs B is settled** — but the four FORCED items can be, because they
hold in both families.

**Safe now (both families, all models):**

| pattern | render | status |
|---|---|---|
| `880.1.60.xxx` | `dramrd` — external delay-DRAM **READ**; data visible 2–5 words later | FORCED (F1, F6) |
| `880.1.20.64B` / `880.1.20.655` | `dramwr` — external delay-DRAM **WRITE**; always immediately preceded by a bit-4 store | FORCED (F1) + MEASURED 44/44 |
| any word with `hi12` bit 4 | the store takes the accumulator **before** that word's own ALU step | FORCED (F2) |
| `102.A.**.64B` | class-A multiply whose multiplicand is a **sum of two registers**, not `mem[p]` and not the incoming `acc` — i.e. a fourth multiply form beside `mac` (`lo12 = 0x1D5`), `mac.lb` (`0x1D4`) and `mulst` (`0x407`) | FORCED under a 2-input ALU (F8) |

That last row is the load-bearing new fact for the ISA: it says **`lo12` selects
the multiplicand route** — `0x1D5 → mem[p]`, `0x407 → acc`, `0x64B → the ALU
result of this word` — which is the "`lo12` = route, `class4` = arithmetic"
hypothesis ranked #2 on the worklist in `-core-draft.md` §6, now supported by an
independent case. *(Falls out for free; flagged as such.)*

**Only after A vs B is settled:**

```
   family B                              family A
   104.2.00.000   acc <- acc + P         104.2.00.000   (unknown, acc-only)
   000.2.00.419   acc <- acc - DR        000.2.00.419   acc <- DR - P
   012.2.00.680   mem[p] <- acc          012.2.00.680   mem[p] <- acc
                  acc <- DR - P                         acc <- P + mem[p]
   880.1.20.655   dram <- mem[p]         880.1.20.655   dram <- acc
   102.A.00.64B   acc <- acc + DR        102.A.00.64B   acc <- mem[p] + DR
                  P <- coef * acc                       P <- coef * acc
```

**To sync to MAME later** (`src/devices/cpu/upd6383/upd6383d.cpp`, NOT touched by
this pass): the `880.1.60` / `880.1.20` annotation should stop saying
"bracket OPEN/CLOSE" — the bracket reading is already falsified
(roadmap §1.6) — and say **READ** / **WRITE** with the `lo12` write-source note.
`104.2.00.000`'s "all-pass marker — step UNKNOWN" can become "all-pass stage,
slot 1 of 6". Nothing else should move until §7 is settled. `dsp_disasm.py` and
`upd6383d.cpp` must be changed together; this pass changed neither, and no `.dsm`
was regenerated, so `dsp/verify.py` still reports BYTE-MATCH OK.

---

## 10. Open, and what would settle it

| # | question | what settles it |
|---|---|---|
| O-1 | family A vs family B | **H1** — the reverb impulse response. The two families differ in *what is written to the delay line*, so they differ in the tail after the first pass. A single `ROOM REVERB 1` impulse with the delays 127/435/489/183/522 known would separate them. Statically: decoding any other `880.1.20.*` form, which would say whether `lo12` selects a write-data source. |
| O-2 | the exact DRAM read latency inside [2,5] | a datasheet, or a cycle-accurate trace. Not obtainable from this board (`SETRDY` open, `BR-RQ` strapped). |
| O-3 | the separator's class-A word clobbering `P` (§8) | whether the multiply latency is per-`lo12`, or whether a second product/accumulator register exists. |
| O-4 | the 9-repetition / 10-buffer off-by-one | decoding the block heads (w16–18, w64–68) and the separators' own DRAM tap. |
| O-5 | 17 vs 18 delay address bits | **H3** — the maximum `SINGLE DELAY` time. R1 is independent of it. |
| O-6 | BRIGHT REVERB 2's 38-cell bank | read the level-2 parameter translator for algo 25. |

---

## 11. Reproducing

```
python3 dsp/tools/r1_allpass_solve.py                        # all sections, ~2 min
python3 dsp/tools/r1_allpass_solve.py census motif banks delays   # the MEASURED half
python3 dsp/tools/r1_allpass_solve.py solve verify           # §5 and §6
python3 dsp/tools/r1_allpass_solve.py discriminator          # §7, both measurements
python3 dsp/tools/r1_allpass_solve.py --terms 3 solve        # the 3-input ALU check (~6 min)
python3 dsp/verify.py                                        # the tree still byte-matches
```

Inputs: `original_ROMs/kn5000_subprogram_v142.rom` (microcode + parameter
streams), `original_ROMs/kn5000_v10_program.rom` (effect names), and the ROM
parsers in `~/compartilhado/kn7000_mame/tools` (`--tools`).
