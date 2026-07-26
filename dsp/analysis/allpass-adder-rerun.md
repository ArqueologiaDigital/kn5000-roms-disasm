# The all-pass search, RE-RUN under the ADDER — and the obstruction that was never the one we named

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-26**.
No hardware. Static analysis, the ROM corpus, constraint solving and the live
emulator only.

**Why this pass exists.** `action-field.md` concluded that *the reverb core
cannot be a first-order all-pass* and named the cause: hi12 bit 4 *"stores the
accumulator AND CLEARS IT"* right before tempA is last writable. That result was
committed at 21:27. At 23:03 `acc-adder.md` replaced the accumulator model the
clear was part of. **The strongest negative result on this chip had therefore
been proved against a model that no longer exists**, and its honest status was
UNKNOWN, not established. This pass re-decides it.

Tool: [`../tools/r1_allpass_solve.py`](../tools/r1_allpass_solve.py), section
`adder` — the existing machine enumeration, the existing delay-loop filter and
the existing numeric matcher, with `order = adder` added and transcribed from
`acc_adjudicate.py` term for term.

```
python3 dsp/tools/r1_allpass_solve.py control              # the old control, unchanged
ADDER_PARTS=gate,control  python3 dsp/tools/r1_allpass_solve.py adder   # ~1 min
ADDER_PARTS=count         python3 dsp/tools/r1_allpass_solve.py adder   # ~25 min
ADDER_PARTS=route         python3 dsp/tools/r1_allpass_solve.py adder   # ~10 min
ADDER_PARTS=search ADDER_ROW=0|1  python3 dsp/tools/r1_allpass_solve.py adder
ADDER_PARTS=forms         python3 dsp/tools/r1_allpass_solve.py adder
python3 dsp/tools/r1_allpass_solve.py singledelay adjudicate   # the harness-leak retest
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** (every survivor of
an exhaustive search agrees) / **CONSISTENT** / **FALSIFIED** / **OPEN**.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★ **THE NEGATIVE RESULT SURVIVES THE ADDER, AND IT SURVIVES IT FROM A LARGER SET OF CHANCES.** Re-run with the same 20 580 000-machine enumeration, the same loop filter and the same matcher: **0 survivors**. Every *multiplicand* count is identical to the sequential model's digit for digit — 70 560 hold the fresh read, **0** hold both reads via the read-data register, 52 920 hold both by any route. The one count that does move moves the *helpful* way: **74 508** machines pass the delay-loop filter under the adder against 52 696 before, and the numeric test rejects all 74 508. | **MEASURED** |
| **B** | ★ **BUT THE PUBLISHED DIAGNOSIS IS FALSIFIED.** `action-field.md` §3.3/§5/D presented *"the multiplicand contains BOTH N and D in **0** of 5 145 000 — exhaustive, no numeric run required"* as the located cause, and blamed the accumulator CLEAR. That count asks only whether the previous read survives **in the DRAM read-data register**. The previous read can also cross the repetition boundary **in the accumulator**, and route-agnostically **52 920 of 5 145 000 settings DO carry both reads** — *with the clear in force*. The obstruction is real; the reason given for it was not the reason. | **MEASURED**, a **FALSIFICATION** of this project's own headline explanation |
| **C** | ★ **WHAT DOES BLOCK IT IN THE SHIPPED ALU IS ONE NAMED BIT, AND IT IS `ACTION 0x00`.** Of the 52 920 settings that can carry both reads, **every single one** has `ACTION 0x00` *keeping* the accumulator (`+bus` 4410, `−bus` 4410, `bus−acc` 4410 per slice); `acc ← bus` (**`load`**) and "no effect" have **ZERO**. Of the 9 660 that reach the exact all-pass multiplicand (item G), 9 520 need `−bus` and 140 `+bus`; `load` again **ZERO**. `load` is exactly what `acc-adder.md`'s joint solve FORCED at 18/18 and what ships. **Under the shipped ALU the previous delay read cannot reach the multiplicand by any route at all** — not because of the clear, but because `load` discards the accumulator that was carrying it. | **MEASURED / FORCED** |
| **D** | ★ **THE HARNESS HAD A DEFECT, AND IT IS IN THE PUBLISHED SINGLE DELAY NUMBERS.** `exec_rep` selected the `s1op` relaxation **by slot position** (`s == 1`), so it applied to whatever program was loaded. SINGLE DELAY's slot 1 is `202.A.B8.655` (`hi12[3:1] = 1`) and was being executed with `hi12[3:1] = 2` instead. Found because a newly built control tripped over it. See §8 for the retest and the price. | **MEASURED** |
| **E** | **BOTH CONTROLS PASS UNDER THE ADDER.** The hand-built Gardner ladder is accepted at 2, 4 and 5 stages under `order = adder`, at `inject=P extract=P scale=+1.000`, identically to the sequential model, and it passes the delay-loop filter. A **second, newly built control** that uses only the STRICT vocabulary — one bus-routing ACTION code plus captures — is also accepted at 2/4/5. A search that cannot succeed proves nothing; both of these can. | **MEASURED** |
| **F** | **The store GATE never reaches this motif.** The motif's only storing word is slot 3, `012.2.**.680`, and `hi12` bit 7 = **0** there, where all three surviving gates agree on STORE + CLEAR. The brief's premise — *"under the adder there is no unconditional clear and the store bit is GATED"* — is true of the ISA and **false of this motif**. | **MEASURED** |
| **G** | ★★ **AND THE MULTIPLICAND CAN BE EXACTLY GARDNER'S.** Asking the question the old count's answer made look pointless: **9 660** settings compute precisely `±(w[r] + w[r−1] − t[r−1])` on the multiplier input, with no other term, and **4 148 of those also satisfy every condition of the delay-loop filter** — and the numeric test still rejects all of them. The impossibility is real but it lives *downstream* of the multiplicand and of the structural feedback conditions. | **MEASURED** |
| **H** | ★★★ **AND HERE IS WHERE IT ACTUALLY LIVES — THE WRITE, NOT THE CLEAR.** Of those 9 660, the number that can also store `d_in[r] = x[r] + t[r]` into the delay line, over all four write-data sources, is **0**. The obstruction is the coupling between slot 4's DRAM-write operand and slot 5's multiplicand — **the same `tempA`, fixed by the ROM word itself**. That is precisely what `action-field.md` §3.1 proved model-free (*"a delay line cannot store the value that its own stage multiplies"*, a THEOREM of the decode at 5 145 000/5 145 000) and then walked past in favour of §5's accumulator clear. **The right diagnosis was already in the note; the wrong one was the one that got the star.** | **MEASURED, exhaustive** |

---

## 1. The prediction, recorded before anything ran

Written from `action-field.md` and `acc-adder.md` alone, before a line of code
was read or run. Reproduced verbatim in the **Appendix**; the reasoning was:

> The adder differs from the sequential model only at words that are `ACTION
> 0x00` **and** `hi12[3:1] == 1` **and** do not store — there it discards the
> entering accumulator where the sequential model kept it. **The all-pass core
> contains no such word.** Slot 3 is `ACTION 0x00` / `hi12[3:1] = 1` but it
> *does* store, and there the CLEAR made the sequential model produce `bus + P`
> anyway. So at this motif the adder is a **point inside** the space section 10
> already searched.

That reasoning is **right in its conclusion and wrong in one detail**: the adder
is a subset of the old space at slots 1, 2, 3, 6 and 7, but at slot 5 — the
multiply — it reaches two forms the sequential model could not (§2), which is why
21 812 *more* machines reach the numeric test. The conclusion survives the
correction; the argument needed it.

**PC-1 (the obstruction survives) — HIT.** **PC-2 (BOTH-reads stays 0) — HIT.**
**PC-3 (dropping the clear no longer moves the count) — see §10; the reasoning
was right about the `load` branch and wrong about the search space, which keeps
`add`/`sub`/`rload`.** **PC-4 (the brief's premise does not hold at this motif) —
HIT, and MEASURED in §3.** **PC-5 (the control breaks) — MISS**, and the refined
prediction made after reading the control (that it ports over unchanged) is the
one that held.

---

## 2. What the adder changes IN THIS MOTIF — word by word

The motif as the decoder reads it (MEASURED, printed by `action`):

```
   slot 0  880.1.**.2D4  ESC  src=0B dram-rd   act=14  accop=0   DRAM-RD
   slot 1  104.2.**.000       src=00 (OPEN)    act=00  accop=2
   slot 2  000.2.**.419       src=10 acc       act=19  accop=0
   slot 3  012.2.**.680       src=1A tempB     act=00  accop=1   ST
   slot 4  880.1.**.655  ESC  src=19 tempA     act=15  accop=0   DRAM-WR
   slot 5  102.A.**.64B       src=19 tempA     act=0B  accop=1   <- THE multiply
   slot 6,7 000.2.**.000      src=00 (OPEN)    act=00  accop=0
```

| slot | sequential reachable set | adder value | verdict |
|---|---|---|---|
| 1 (`act 00`, `f31 = 2`) | `{acc, acc±bus, bus, bus−acc}` | the same five, term for term | **identical set** |
| 3 (`act 00`, `f31 = 1`, **ST**) | store+CLEAR ⇒ `{P, P±bus, bus, bus−P}` | store+clear, then `{P, P±bus, bus+P, bus+P}` | **adder ⊂ sequential** |
| 6,7 (`act 00`, `f31 = 0`) | `{P, P±bus, bus, bus−P}` | `{P, P±bus, bus+P}` | **adder ⊂ sequential** |
| 2 (`act 19`, `f31 = 0`) | `{P, P±bus, bus, bus−P}` | `{P, P±bus, bus+P}` | **adder ⊂ sequential** |
| 5 (`act 0B`, `f31 = 1`) | `{acc+P, acc+P±bus, bus, bus−acc−P}` | `{acc+P, acc+P±bus, bus+P, bus+P−acc}` | ★ **two forms the sequential model did not have** |

Slot 5 is the *only* word of the motif at which the adder reaches somewhere the
sequential model could not, and that is where the extra 21 812 loop-filter
survivors of §5.2 must come from — PROVEN BY CONSTRUCTION from this table, since
everywhere else the adder's reachable set is a subset or equal.

At slot 3 — the word the published diagnosis blamed — the sequential model
already produced `bus + P`, *because the clear had zeroed the accumulator first*.
The adder produces `bus + P` **without needing the clear**. The two models agree
on the value and disagree on why. That is precisely the situation in which a
diagnosis can be wrong while the measurement it explains is right, and it is what
happened.

---

## 3. Does the store gate even reach the motif? — MEASURED, and it does not

`acc-adder.md` adopts a bit-7 gate on the bit-4 store, and the brief that
commissioned this pass took that to mean the clear is no longer unconditional.
Measured, not assumed:

```
   slot 3  012.2.**.680     hi12 bit7 = 0 -> all three surviving gates say STORE + CLEAR
```

`0x012 >> 7 = 0`. The three gates differ only where bit 7 is **set**. **The
gating adopted in the device changes nothing here**, and the clear is in force at
this motif under every reading that survived the LFO solve. The brief's stated
premise is FALSIFIED as applied to this motif — which does not make the re-run
pointless, because the *other* half of the adder (ACTION `0x00` as a selector) is
what turns out to matter, in a direction nobody predicted.

---

## 4. The controls — the harness must be able to say YES in the new model

```
   ORDER = ADDER, the existing hand-built Gardner ladder
     2-stage ladder, ROM gains 0.75 0.63:                 MATCH  inject=P extract=P scale=+1.000
     4-stage ladder, ROM gains 0.75 0.63 0.52 0.50:       MATCH  inject=P extract=P scale=+1.000
     5-stage ladder, ROM gains 0.75 0.63 0.52 0.50 0.40:  MATCH  inject=P extract=P scale=+1.000
     loop filter on the control: ['bus']
```

Identical to the sequential model's, down to the extraction point and the scale.
Stronger than "identical results": the control's **output arrays are
bit-identical** across the two orders, for all six injection points and all six
extraction registers, at five stages —

```
   control output arrays BIT-IDENTICAL across sequential vs adder: True
```

— and that is **PROVEN BY CONSTRUCTION** once the control is traced: every one of
its eight words is either an escape word, or `hi12[3:1] == 2` with an ACTION that
supplies the bus term, or `f31 = 0` with `+bus`. On all of those the adder and
the sequential model coincide exactly (§2).

**Which means the control was never a test of the order** — the same blind spot
`acc-adder.md` §3.1 found in the biquad, in the one place a project is least
likely to look for it. A control that a model change cannot move validates the
executor and the matcher, and says nothing about the model. That is still worth
having, and it is worth saying which of the two it does.

### 4.1 A control the STRICT sub-space can build — because an inexpressive space empties for free

The shipped reading is stronger than "the accumulator is an adder": it is that
**only `ACTION 0x00` routes the bus**, with `0x19` and `0x0B` capture-only. An
empty survivor set in a space too poor to express a one-multiplier all-pass at
all would be worthless. So a second control was built inside exactly that
vocabulary — a single bus-routing ACTION code (`0x00`, one mode `bus−acc`, one
capture half), capture-only codes, `hi12[3:1]`, and a blocking DRAM read:

```
   s0  read (blocking)                     DR <- line[r]
   s1  f31=0, act 12                       acc <- P              = t[r-1]
   s2  f31=2, act 00, src tempB            acc <- tB - acc       = x[r]
   s3  act "M<-acc"                        M   <- x[r]
   s4  f31=2, act 00, src 0x00 = zero      acc <- 0 - acc        = -x[r]
   s5  f31=2, act 00, src DR               acc <- DR - acc       = w[r] + x[r] = s[r]
   s6  write                               line[r-1] <- tA = d_in[r-1]
   s7  class A, src acc                    P   <- g * s[r]       = t[r]
   s8  f31=0, act 00, src M                acc <- P + M          = d_in[r]
   s9  act "tA<-acc"                       tA  <- d_in[r]
   s10 act 14, src DR                      tB  <- w[r]
```

```
   2-stage / 4-stage / 5-stage ladders:  MATCH  inject=P extract=P scale=+1.000
   loop filter on the strict control:    ['bus']
```

**The strict sub-space can express a Gardner one-multiplier all-pass.** Its empty
survivor set is therefore a statement about the corpus words, not about the
vocabulary.

---

## 5. The re-run

### 5.1 The multiplicand counts

`ADDER_PARTS=count`. The middle column is the count `action-field.md` §3.3
published; the last column is the same question asked **without assuming which
register carries the previous read**.

| model | enumerated | multiplicand holds the FRESH read | holds BOTH, **via DR** | holds BOTH, **any route** |
|---|---|---|---|---|
| sequential (§10, reproduced) | 5 145 000 | **70 560** | **0** | **52 920** |
| **ADDER, generous** | 5 145 000 | **70 560** | **0** | **52 920** |
| ADDER, strict | 205 800 | 1 568 | 0 | 1 176 |
| sequential + no clear | 5 145 000 | 85 260 | **8 400** | 65 930 |
| **ADDER, generous + no clear** | 5 145 000 | **85 260** | **8 400** | **65 930** |
| ADDER, strict + no clear | 205 800 | 1 568 | **0** | 1 176 |
| ADDER, generous + **no store at all** | 5 145 000 | 85 260 | 8 400 | 65 930 |

The first two rows are the headline: **the adder reproduces the sequential
model's counts exactly.** `70 560` and `0` are the published numbers, re-derived
in the new model without being aimed at. Rows 4 and 5 do it again for the one
relaxation that mattered in the old price list: `8 400` reappears, unchanged.
**PC-3 predicted `0` there and is a MISS** — see §10.

Row 6 is the interesting one. In the STRICT sub-space the DR-route count stays
**0 even with the clear removed**, and the reason is structural: slot 2
(`000.2.**.419`) has `hi12[3:1] = 0`, i.e. `acc ← P`, which **wipes the
accumulator between slot 1 and slot 3** whatever the clear does. Only an ACTION
`0x19` with an accumulator half — which the strict reading denies it — can carry
slot 1's fresh read across slot 2. So in the shipped ISA the clear is not merely
*not the cause*; it is not even *reachable* as a cause.

### 5.2 The searches

```
   [0] ADDER, generous -- nothing else relaxed
       20580000 enumerated   74508 pass the delay-loop filter   0 reproduce a 2-stage cascade
   [1] ADDER, strict   -- nothing else relaxed
         823200 enumerated    2268 pass the delay-loop filter   0 reproduce a 2-stage cascade
```

against the published sequential result

```
       20580000 enumerated   52696 pass the delay-loop filter   0 reproduce a 2-stage cascade
```

**Same enumeration, same answer — and the adder is the *more* permissive of the
two at the structural stage.** 74 508 machines pass the delay-loop filter under
the adder against 52 696 under the sequential model: **+21 812 machines that the
old search never even offered to the numeric test**, and the numeric test rejects
every one of them. The negative result is therefore not an artefact of the model
that was replaced; it got a strictly larger set of chances in the new one and
still returned zero.

The STRICT sub-space — what actually ships — returns zero from a space that
**can** express a one-multiplier all-pass (§4.1) and whose loop filter is not
empty (2 268 survivors).

### 5.3 What the loop-filter survivors force — and one thing the reverb CAN force after all

Marginals over the survivors of the structural filter alone
(`ADDER_PARTS=forms`, and the scratch enumeration it reproduces):

```
   sequential            52696 loop survivors
       SRC 0x00 reads        FORCED    DR x52696
       the read lands at     2 values  0 x26348   1 x26348
       the DRAM write data   4 values  acc_before x16824  acc_after x16824  M x14008  bus x5040
       ACTION 0x00 acc op    4 values  bus x14560  +bus x12712  -bus x12712  bus-acc x12712
       ACTION 0x19 acc op    5 values  +bus x12208  -bus x12208  bus-acc x12208  (none) x8344  bus x7728
       ACTION 0x19 capture   4 values  tA<-bus x25200  tA<-acc x22176  tB<-acc x3360  tB<-bus x1960

   ADDER, generous       74508 loop survivors
       SRC 0x00 reads        FORCED    DR x74508
       the read lands at     2 values  0 x37254   1 x37254
       the DRAM write data   4 values  acc_before x25232  acc_after x25232  M x17184  bus x6860
       ACTION 0x00 acc op    4 values  bus x36372  +bus x12712  -bus x12712  bus-acc x12712
       ACTION 0x19 capture   4 values  tA<-bus x35280  tA<-acc x31808  tB<-bus x5740  tB<-acc x1680

   ADDER, strict          2268 loop survivors
       SRC 0x00 reads        FORCED    DR x2268
       the read lands at     2 values  0 x1134    1 x1134
       the DRAM write data   4 values  M x992  acc_before x624  acc_after x624  bus x28
       ACTION 0x00 acc op    4 values  bus x756  +bus x504  -bus x504  bus-acc x504
       ACTION 0x19 capture   2 values  tA<-bus x1904   tB<-bus x364
```

`SRC 0x00 = DR` at 52 696/52 696 and `land ∈ {0,1}` at 26 348/26 348 reproduce
`action-field.md` §3.2 exactly, and the adder re-forces both from its own larger
survivor set (74 508/74 508 and 37 254/37 254).

★ **Three things in those tables are new, and all three are positive results the
earlier pass said the reverb could not give** — `action-field.md` §0 states flatly
that "no ACTION code was decoded from the reverb":

1. **`ACTION 0x00` touches the accumulator — FORCED by the reverb.** Its
   accumulator half has four values among the survivors and **"no accumulator
   effect" has ZERO**, in all three spaces. The delay-loop filter is a property of
   the *filter*, not of the ALU, so this is the reverb forcing it on its own. It
   is the same conclusion SINGLE DELAY reached (`action-field.md` §6, point 3) and
   **the two contexts agree** — the first agreement between them on this code.
2. **`ACTION 0x19` captures from the BUS — FORCED in the strict space**, 2 268 of
   2 268 (`tA<-bus` 1 904 + `tB<-bus` 364); `tA<-acc` and `tB<-acc` are in the
   enumeration and have zero survivors. `acc-adder.md` narrowed `0x19` to
   `tA<-bus` at 72/72 in SINGLE DELAY; the reverb independently kills the `<-acc`
   half. **Second agreement.**
3. **A new tension, stated rather than resolved**: the DRAM write data. SINGLE
   DELAY and both controls take the **latched bus**, and in the strict reverb
   space `bus` is the *rarest* survivor — 28 of 2 268 — behind `mem[ptr]` (992).
   Nothing here decides it; it is logged because it is the kind of quiet
   disagreement that turns into a false forcing later.

### 5.4 What the loop-filter survivors actually multiply

`ADDER_PARTS=forms` — the symbolic multiplicand of every machine that reaches the
numeric test, and how many of them can carry both reads at steady state:

```
   sequential        52696 loop survivors, 38136 can hold BOTH reads
        A+N x8708   A-N x8708   -A+N x8708   N x4480
        P+N x3360   P-N x3360   -P+N x3360   -A+P+N x2716

   ADDER, generous   74508 loop survivors, 38136 can hold BOTH reads
        P+N x15904  N x15540    A+N x7420    A-N x7420    -A+N x7420
        -A+P+N x5432   A+P-N x5152   P-N x4368

   ADDER, strict      2268 loop survivors,  1512 can hold BOTH reads
        N x644   A+N x476   A-N x476   -A+N x476   P+N x112
```

Every form carries `N` with coefficient ±1 — that is condition C1 and the filter
enforces it. **38 136 of the 52 696 machines the old search sent to the numeric
test could carry both delay reads**, and the note that reported that search said
*none* could. The two statements are about different questions; only one of them
was labelled.

---

## 6. ★ The route the old count could not see

`ADDER_PARTS=route`, and one worked example printed from the symbolic algebra:

```
   ACTION 0x00 = acc += bus    ACTION 0x19 = tA<-bus    SRC 0x00 = DR    land = 0

      multiplicand, one repetition   =  A + N
      accumulator at repetition exit =  N + Q
      multiplicand at steady state   =  N + Q + N'
```

`A` is the accumulator at repetition entry. The machine leaves `N + Q` in the
accumulator, so at the next repetition the multiplicand is `N' + N + Q`: **the
fresh read, the previous read and the previous product, all three.** The previous
read never touches the DRAM read-data register on that path — it rides in the
accumulator — and `mult_can_be_s`'s atom-`D` test cannot see it.

That form is one sign away from what a first-order all-pass needs:

```
   the chip's motif can build       s[r] = w[r] + w[r-1] + t[r-1]
   a Gardner all-pass stage needs   s[r] = w[r] + w[r-1] - t[r-1]
```

and `hi12[3:1]` only ever **adds** `P`.

### 6.1 What carrying both reads FORCES — and the single bit that forbids it

Marginals over the 13 230 settings (per `escact`×`tbsh` slice; 52 920 in total)
that carry both reads by any route:

```
   order = sequential   13230 settings
       SRC 0x00 reads        FORCED    DR x13230
       the read lands at     2 values  0 x6615   1 x6615
       ACTION 0x00 acc half  3 values  +bus x4410   -bus x4410   bus-acc x4410
       ACTION 0x19 capture   4 values  tA<-bus x5250  tA<-acc x4200  tB<-bus x2100  tB<-acc x1680

   order = adder        13230 settings      <- identical, term for term
```

★ **`ACTION 0x00 = acc ← bus` (`load`) appears ZERO times. "No accumulator
effect" appears ZERO times.** Every setting that can carry the previous read
forward needs `ACTION 0x00` to *keep* the accumulator and *add to* it.

`acc-adder.md` §3.4 FORCED the opposite — `act00 = load`, 18 of 18 survivors of
the three-context joint solve, and it is what SHIPS in
`upd6383_device::exec_alu()`.

> **So the obstruction is not the clear and never was. It is `ACTION 0x00`.**
> Under the ALU that ships, the accumulator is *reloaded* at slots 1, 3, 6 and 7,
> and the previous delay read has nowhere to live across the repetition boundary.
> Route-agnostically, the shipped ALU carries both reads in **0** settings.

This is the same *shape* of collision as `action-field.md` §8 (the reverb and
SINGLE DELAY want different things from `SRC 0x00`) but sharper: it is one bit of
one code, and both readings of it are FORCED — in different contexts.

### 6.2 ★★ And the multiplicand can be EXACTLY Gardner's — so the obstruction is downstream

Having asked "can both reads meet", the obvious next question is the one the
earlier pass never got to ask, because it believed the answer to the first was
no: **can the multiplicand be exactly `s[r] = w[r] + w[r−1] − t[r−1]`, and
nothing else?** Enumerated, up to an overall sign, with no other atom allowed:

```
   sequential   52920 carry both reads;  9660 reach the EXACT Gardner
                multiplicand +-(N' + N - Q)

   the steady-state multiplicand forms, most common first:
       N+Q+N'  x9520     -N+Q-N' x9520    -N+Q+N' x9380    N+N'   x3920
       -N-N'   x3080     N+2*Q+N' x2380   -N+N'   x2380
       0.5*N+0.5*Q+0.5*N'  x1680          -N+2*Q-N' x1540  -N+2*Q+N' x1540
```

**9 660 settings compute precisely the multiplicand a first-order all-pass
stage needs.** The sample machine printed by the tool —
`ACTION 0x00 = acc += bus ; tA<-acc`, `0x19 = acc −= bus ; tB<-acc`,
`SRC 0x00 = DR`, `land = 0` — has exactly `±(N' + N − Q)` on the multiplier's
input, and **`loop_ok` returns `[]`**: not one of the four DRAM write-data
sources gets `g·w_k` back to the line without also getting an unmultiplied copy
of `w_k` there.

Enumerated over the whole space, with the loop filter applied on top:

```
   sequential  EXACT Gardner multiplicand:  9660   of which ALSO pass the loop filter: 4148
        ACTION 0x00 acc half among them:  -bus x9520   +bus x140      (load: ZERO, none: ZERO)
        ACTION 0x19 acc half among them:  bus x3080  -bus x1820  +bus x1680  bus-acc x1540  (none) x1540

   adder       EXACT Gardner multiplicand:  8400
```

★★★ **4 148 machines put exactly `±(w[r] + w[r−1] − t[r−1])` on the multiplier
input AND satisfy every condition of the delay-loop filter — and the numeric
test still rejects all of them.** So the obstruction is not that the two reads
cannot meet (they can, 52 920 ways), not that the multiplicand cannot be the
all-pass `s[r]` (it can, 9 660 ways), and not that the structural feedback
conditions cannot be met at the same time (4 148 ways). It is **downstream of all
three**, and the remaining candidate is the *value written back to the delay
line*: `loop_ok` only requires the write to carry `g·w_k` with coefficient ±1 and
no unmultiplied `w_k`; it does **not** require it to be `x[r] + t[r]`, which is
what a Gardner stage stores. §6.3 asks that, and gets an answer.

### 6.3 ★★★ And there it is: the write-back can NEVER be `x[r] + t[r]`

One more symbolic predicate, asked of the same enumeration. A Gardner stage
stores `d_in[r] = x[r] + t[r]`; at steady state, in the same atoms, that is
`±(N − Q + Q')`. Over all four DRAM write-data sources:

```
   sequential   exact-Gardner MULTIPLICAND  9660
                | of those, also pass the loop filter        4148
                | of those, exact-Gardner WRITE-BACK            0
                | BOTH exact AND loop-consistent                 0
                | write source when the write-back is exact:  {}   (empty)
```

**ZERO.** Not one of the 9 660 machines that computes the correct multiplicand
can put `x[r] + t[r]` into the delay line, from `bus`, from `acc` before the
word, from `acc` after it, or from `mem[ptr]`.

That is the obstruction, located, and it is a **different word from the one
`action-field.md` §5 named**: slot **4**, the DRAM write `880.1.**.655` whose
SRC is `tempA` — the same register the multiply consumes one slot later — not
slot 3's store-and-clear.

And it is exactly what that same note **already proved model-free** and then
walked past. §3.1's two lines of algebra: *"whatever else is true, a delay line
cannot store the value that its own stage multiplies"* — because slots 4 and 5
carry the same SRC and nothing between them can rewrite it, a fact §0-F called
"not a hypothesis but a THEOREM of the decode", true in 5 145 000 of 5 145 000
settings. **The exhaustive search now confirms it from the other end**: the write
data and the multiplicand cannot be made to differ by the `w[r] − t[r]` that a
Gardner stage requires between them.

> **`action-field.md` §3.1 was right and §5 was looking at the wrong word.** The
> obstruction was never the accumulator clear; it is the coupling between the
> DRAM write's operand and the multiplier's operand, which the ROM word itself
> fixes.

Note also what the 9 660 force about the code this pass has been circling:
**`ACTION 0x00`'s accumulator half is `−bus` in 9 520 of them and `+bus` in 140 —
and `load` in none.** The same single bit, from a fourth direction, saying the
same thing: the shipped reading and the all-pass reading are incompatible.

---

## 7. What is now FORCED, CONSISTENT, and OPEN

**FORCED**

* **The reverb core is not a first-order all-pass stage under the adder either.**
  0 of 20 580 000 in the generous space (74 508 loop survivors), 0 of 823 200 in
  the strict space (2 268 loop survivors). Both spaces have a positive control
  that the same executor, the same delay lines, the same reference and the same
  matcher ACCEPT at 2, 4 and 5 stages.
* **The adder is not the difference.** Every multiplicand count section 10
  published is reproduced digit for digit under `order = adder` — 70 560 fresh,
  0 both-via-DR, and 85 260 / 8 400 with the clear removed. The one count that
  moves — the loop-filter survivors, 52 696 → 74 508 — moves in the direction
  that would have *helped*.
* **If the multiplicand is ever to carry both delay reads, `ACTION 0x00` must
  KEEP the accumulator.** 52 920 of 52 920 route-agnostic settings have its
  accumulator half in `{+bus, −bus, bus−acc}`; `acc ← bus` (`load`) and "no
  effect" have **0**. `load` is what the three-context joint solve FORCED and
  what ships. Under the shipped ALU the count is **0 by any route**.
* **`SRC 0x00` must read the delay-RAM data register** for both reads to meet:
  13 230 / 13 230, the same demand the delay-loop filter makes (52 696/52 696)
  and the same one SINGLE DELAY refuses (0 of its survivors). §8 of
  `action-field.md` now has a **third independent witness** and is unresolved in
  the same direction.
* **The read must land at slot 0 or slot 1** (6 615 / 6 615 of the both-reads
  settings), which remains incompatible with SINGLE DELAY's blocking read.
* **The store GATE does not reach this motif** (`hi12` bit 7 = 0 at the only
  storing word).
* ★ **The impossibility is downstream of the multiplicand.** 9 660 settings reach
  the exact all-pass multiplicand and 4 148 of those also pass the delay-loop
  filter, and the numeric test rejects all of them. Whatever forbids the all-pass
  is therefore *not* any of: the two reads meeting, the multiplicand's form, or
  the structural feedback conditions C1–C3.
* ★★ **It is the WRITE-BACK, exhaustively.** 0 of those 9 660 can store
  `x[r] + t[r]`, over all four write-data sources — the exhaustive form of
  `action-field.md` §3.1's model-free algebra, and it names slot 4 rather than
  slot 3.

**CONSISTENT, not forced**

* `ACTION 0x19` capturing into **tempA**: 9 450 of the 13 230 both-reads settings
  do (`tA<-bus` 5 250 + `tA<-acc` 4 200) against 3 780 into tempB. The
  multiplicand *is* tempA, but tempA is writable by more than one code, so this
  is a majority and not a forcing.
* The delay line lives in the **external DRAM**, not D-RAM: every route by which
  the two reads can meet runs through `DR` and the accumulator, and none through
  `mem[ptr]`. Consistent with the reverb touching only 14 distinct D-RAM cells in
  133 words.
* **Preset-independence is not at risk here.** All twelve reverb presets share
  ONE 133-word image (MEASURED elsewhere), and every number in this note is
  computed from the word image alone — no preset, no coefficient value, no
  parameter stream enters the symbolic stage at all.

**OPEN**

* **What the reverb core actually computes.** Still not decoded. Two *half*-codes
  now are (§5.3) — `ACTION 0x00` touches the accumulator, `ACTION 0x19` captures
  from the bus — and both merely agree with what SINGLE DELAY already said, so
  neither buys a frame slot that was not already priced.
* **`ACTION 0x00`'s accumulator half** is now the parameter to attack: `load` is
  FORCED by the biquad+LFO+SINGLE-DELAY joint solve and refuted by the all-pass
  hypothesis. Since the all-pass hypothesis is independently falsified, `load`
  stands — but any fourth context that separates `load` from `add` decides both
  questions at once, and it is the highest-value experiment this pass identifies.
* **Whether `hi12` bit 4 clears the accumulator** — still open, but **DEMOTED**.
  It is not what blocks the all-pass (§6), and in the shipped ISA it is not even
  reachable as a cause (§5.1, row 6).
* **What the reverb core *does* write to its delay lines.** §6.3 settles what it
  cannot write; it does not say what the ROM intends instead. The motif stores
  the multiplicand itself, which is a Schroeder/nested-comb shape rather than a
  Gardner all-pass — `sec_schroeder` in the same tool is the obvious next
  acceptance test, and it now has a *reason* to be run rather than a hunch.

---

## 8. ★ A harness defect, found by a control, and what it costs

```python
   op = m[S1OP] if s == 1 else sl["accop"]        # <- the defect
```

`s1op` is a **relaxation of one word of the reverb motif** — slot 1's
`104.2.**.000`, whose `hi12[3:1] = 2`. `exec_rep` selected it **by slot
position**, and four sections of the tool swap `MSLOTS` out for a different
program. SINGLE DELAY's slot 1 is `202.A.B8.655`, `hi12[3:1] = 1`, and it was
being executed with `hi12[3:1] = 2` — every published SINGLE DELAY number was
computed with that word's accumulator operation silently replaced.

**How it was found**: not by inspection. The strict-vocabulary control of §4.1
was designed on paper to need `acc ← P` at its second word, ran, and "matched" at
scales of −0.270 / −0.028 / −0.008 instead of the ±1 the design predicted. A
match at an unexplained scale is a failed prediction, not a pass; chasing it
found the leak. (Fixed by testing `MSLOTS is MOTIF_MSLOTS`; the control then
matches at exactly +1.000, as designed.)

**The reverb numbers are untouched** — PROVEN BY CONSTRUCTION: on the motif the
identity test is true, and the nominal `s1op = 2` equals slot 1's own `accop`,
so the expression is unchanged in every reverb run in this note and in
`action-field.md`.

**PC-9, recorded before the retest ran:** SINGLE DELAY's published **5 145**
should be *unchanged* at the shipped order, because `w6`'s accumulator result is
overwritten one word later by `w7`'s `acc ← P`; but the `actfirst = 1` arm of
`acc-adder.md` §4 **can** move, because there `w7`'s ACTION runs first and its
capture half may read the accumulator `w6` left.

**The retest — and PC-9 is a MISS:**

```
   BEFORE the fix (the code that produced the published numbers)
      5145 assignments make the block  v[n] = x[n] + fb*v[n-D]  exactly
        SRC 0x00 reads       4 values  M x3430  P x980  acc x490  zero x245
        read lands +n        FORCED    -1 x5145
        ACTION 0x00 acc op   4 values  +bus x2205  -bus x1960  bus x735  bus-acc x245
        ACTION 0x19 capture  2 values  tA<-bus x2940  tA<-acc x2205
        x arrives in                   M x3185  acc x1960

   AFTER the fix
      5635 assignments make the block  v[n] = x[n] + fb*v[n-D]  exactly
        SRC 0x00 reads       4 values  M x3430  acc x980  P x980  zero x245
        read lands +n        FORCED    -1 x5635
        ACTION 0x00 acc op   4 values  +bus x2450  -bus x2205  bus x735  bus-acc x245
        ACTION 0x19 capture  2 values  tA<-bus x3430  tA<-acc x2205
        x arrives in                   M x3185  acc x1960  P x490
```

**The published cardinality 5 145 is wrong; it should read 5 635.** PC-9
predicted no change and was wrong about why: `w6`'s accumulator result *is*
overwritten by `w7`'s `acc ← P`, but restoring `w6`'s `acc += P` opens a **new
injection point** — the 490 extra survivors are exactly the ones in which the
ladder input arrives in `P` (`x arrives in … P x490`), which the leak had
suppressed by removing the only word that adds `P` into the accumulator.

**All four FORCED results of `action-field.md` §6 survive the fix, unchanged:**

```
   the external delay-RAM read is BLOCKING        land = -1   5635/5635
   ACTION 0x19 captures into tempA                            5635/5635
   ACTION 0x00 is NOT a no-op                     "no accumulator effect": ZERO
   SRC 0x00 is NOT the delay-read register        DR absent from all survivors
```

and so do `acc-adder.md`'s narrowings, which were derived in the separate,
strengthened model of `acc_adjudicate.py` and never went through this code path
at all. **Nothing has to be withdrawn — but the number does, and a survivor count
that moves by 10 % when a harness bug is fixed is a reminder that a marginal is
only as exhaustive as the executor under it.**

**Still to retest**: `acc-adder.md` §4's `actfirst = 1` arm (22 050 survivors).
`w7`'s ACTION runs *before* its `acc ← P` there, so its capture half can read the
accumulator `w6` left — the one place the leak can change a conclusion rather
than a count. `python3 dsp/tools/r1_allpass_solve.py adjudicate` re-runs it; the
number is expected to move and the adjudication's *verdict* is not, because the
verdict rests on the strengthened `acc_adjudicate.py` model, which never used
this code path.

*(One further correction while re-reading: `action-field.md` §6's tuple
"(+bus 2205, −bus 1960, ←bus 735, ←bus−acc 735)" sums to 5 635, not to the 5 145
it annotates. The BEFORE run gives ←bus−acc = **245**. The published tuple was
internally inconsistent.)*

---

## 9. What this pass changes about earlier claims

| claim | where | status now |
|---|---|---|
| "an exhaustive search over 20 580 000 machines … produces **ZERO** machines that reproduce a first-order all-pass ladder" | `action-field.md` §0-A, MEASURED | **UPHELD, and re-earned in the new model.** 0 of 20 580 000 under the adder, from a *larger* loop-survivor set (74 508 vs 52 696) |
| "the multiplicand contains BOTH `N` and the previous `D` in **0** of 5 145 000 … it takes no numeric run and no all-pass reference to establish" | `action-field.md` §0-D, §3.3, MEASURED-exhaustive | **NARROWED to one route, and misleading as published.** True for the DRAM read-data register; route-agnostically **52 920** settings carry both, and **38 136 of the 52 696 loop survivors** can |
| "SINGLE DELAY … **5 145** assignments" | `action-field.md` §6, §0-E | **CORRECTED to 5 635** (§8). The four FORCED conclusions drawn from it all survive |
| "(+bus 2205, −bus 1960, ←bus 735, ←bus−acc 735)" | `action-field.md` §6 | **CORRECTED**: `←bus−acc` is **245**, and the quoted tuple summed to 5 635 while annotating 5 145 |
| "no ACTION code was decoded from the reverb" | `action-field.md` §0, closing line | **SUPERSEDED, in part.** The delay-loop filter alone forces that `ACTION 0x00` touches the accumulator (0 survivors for "no effect", all three spaces) and that `ACTION 0x19` captures from the **bus** (2 268/2 268 in the strict space). Both agree with SINGLE DELAY |
| "The cause is the accumulator CLEAR: tempA is last writable at slot 3, which carries `hi12` bit 4" | `action-field.md` §5, "a one-line diagnosis of a 20-million-machine empty set" | ★ **FALSIFIED as the cause.** 52 920 settings carry both reads *with the clear in force*, 9 660 reach the exact all-pass multiplicand, 4 148 also pass the loop filter. The cause is slot 4's write (§6.3); `ACTION 0x00 = load` is what additionally forbids it in the *shipped* ALU |
| "a delay line cannot store the value that its own stage multiplies" — and "the value written equals the multiplicand in 5 145 000 of 5 145 000 settings" | `action-field.md` §3.1, §0-F, model-free / THEOREM | ★ **UPHELD, and promoted.** It is the actual obstruction, now exhaustive: 0 of 9 660 exact-multiplicand machines can write `x[r] + t[r]`. The note proved it and then argued the wrong cause in §5 |
| "**`hi12` bit 4 CLEARS the accumulator** … the only one of nine relaxations that moves the count at all" | `action-field.md` §7, §10 OPEN | **DEMOTED.** It moves the *DR-route* count (0 → 8 400, reproduced here under the adder) and moves the numeric count not at all; and in the STRICT ISA it cannot be the cause even in principle, because slot 2's `acc ← P` wipes the accumulator first |
| "the accumulator CLEAR there is still the single highest-value open question in the ALU" | `acc-adder.md` §8, last bullet | **FALSIFIED for this problem.** `ACTION 0x00`'s accumulator half is |
| "P-9 … the accumulator CLEAR is the assumption that blocks it — **HIT, and cleanly**" | `action-field.md` §12 | **RETRACTED.** It was a hit against a question that had been asked too narrowly; asked route-agnostically, the clear is not the blocker |
| "SINGLE DELAY … **5 145** assignments reproduce `v[n] = x[n] + fb·v[n−D]` exactly" and the marginals derived from them | `action-field.md` §6; `acc-adder.md` §4 | see §8 — the harness was executing that block's slot 1 with the wrong `hi12[3:1]` |
| "the two trailing nops are INERT / the ACTION acts BEFORE `hi12[3:1]` / … change nothing at all" (price rows 1, 3–9) | `action-field.md` §7 | **not retested here**; the rows that were retested under the adder (0, 2) reproduce exactly |

---

## 10. PREDICT-THEN-CHECK

PC-1…PC-7 were written and stored **before any code was read or run** (verbatim
in the Appendix); PC-8 and PC-9 were recorded later but each before the
measurement it names. **Overall: 5 HITS, 4 MISSES, 1 PARTIAL.**

| | prediction | result |
|---|---|---|
| **PC-1** | the obstruction **SURVIVES**; 0 survivors under the adder | **HIT.** 0 of 20 580 000 generous, 0 of 823 200 strict |
| **PC-2** | the BOTH-reads count stays 0 | **HIT** for the published (DR-route) count: 0 under both models. And the reason it is a hit turns out to be the reason the count was the wrong question |
| **PC-3** | ★ dropping the CLEAR no longer moves the count off zero, because `load` discards the accumulator anyway | **MISS.** 8 400 again, identical to the sequential model. The reasoning was right about the `load` branch and wrong about the *search space*, which still enumerates `add`/`sub`/`rload` for `ACTION 0x00`. The prediction silently assumed the parameter it was reasoning about was fixed at its adopted value — the exact error `acc-adder.md` §4 diagnosed in the older SINGLE DELAY pass, committed again one pass later |
| **PC-4** | the brief's premise ("no unconditional clear, the store is gated") does not hold at this motif | **HIT, and MEASURED.** `hi12` bit 7 = 0 at slot 3; all three gates store and clear |
| **PC-5** | the control as written FAILS under the adder and must be rebuilt | **MISS.** It ports over unchanged and its output arrays are **bit-identical** across the two orders. The refined prediction made after reading `CONTROL_SLOTS` — that every one of its words lies in the region where the two models coincide — is the one that held |
| **PC-6** | the adder search space is far smaller, order 10⁴–10⁵ | **MISS as stated.** The generous space is the same 20 580 000; only the strict sub-space is smaller (823 200). The prediction conflated "the adder settles parameters" with "the re-run should enumerate fewer" — settling them is what the *other* contexts did, and importing that into this search would have begged the question |
| **PC-7** | if PC-3 holds, the residual obstruction points at slot 2 as the only tempA writer | **partially, and better than predicted.** Slot 2 is indeed decisive, but as the word whose `hi12[3:1] = 0` **wipes the accumulator**, not as a tempA writer — and that is what makes the STRICT DR-route count 0 even without the clear |
| **PC-8** | *(recorded in `mult_can_be_s`'s docstring when the second column was written, before any count was run — "a machine that carries the previous read forward in tempA is invisible to `n_ND` and visible here")* the route-agnostic count will be non-zero | **HIT.** 52 920, and one worked example printed symbolically (§6) |
| **PC-9** | *(recorded in §8 before the retest ran)* SINGLE DELAY's **5 145** is unchanged by the harness fix at the shipped order, because `w6`'s accumulator result is overwritten by `w7`'s `acc ← P` | **MISS.** 5 145 → **5 635**. The overwrite argument is correct and incomplete: restoring `w6`'s `acc += P` opens a new *injection* point, and the 490 extra survivors are exactly those whose input arrives in `P`. Every FORCED conclusion survives; the cardinality does not |

---

## 11. What this constrains for the other two targets

* **`SRC 0x00` is now contradicted by three contexts, not two.** The reverb needs
  it to be the delay-RAM read register (52 696/52 696 in the loop filter,
  13 230/13 230 in the both-reads condition); SINGLE DELAY forbids it (0 of
  **5 635**, and 0 of 72 in the strengthened model). Any pass that adopts
  `SRC 0x00` in either direction is adopting one context over another, and the
  price list in `acc-adder.md` §6 (30 frame slots) is still the right way to
  state it.
* **`ACTION 0x00`'s accumulator half is the single highest-value discriminator
  left in the ALU** — `load` versus `add`. It is FORCED to `load` by three
  contexts jointly and would have to be `add`-like for the reverb ever to be an
  all-pass. A fourth context that separates them settles the reverb question as a
  by-product. Note `acc-adder.md` §2 already flagged the *testable consequence*
  that on an ACTION-`0x00` word `hi12[3:1] == 0` and `== 1` become
  indistinguishable; this is the same seam, seen from the other side.
* **A harness pattern to check everywhere**: `r1_allpass_solve.py` selected a
  relaxation **by slot position**, and it leaked into every program the tool
  loaded (§8). A **second instance of the same shape** was in the same file: the
  `nopi` relaxation was guarded by `len(MSLOTS) == 8`, which `CONTROL_SLOTS` also
  satisfies — latent, harmless today only because `nopi` is never set in that
  section, and now gated on the same identity test. **Any tool that swaps a slot
  list must not carry position-indexed parameters.** `closure_pointer.py`,
  `lfo_ramp.py` and `acc_adjudicate.py` should be swept for the same shape.
* **Nothing here moves the closure residue.** Every word examined has
  `addr8 == 0` inside a ladder (F7, MEASURED), so the `+121` on 1 130 880 of
  1 130 880 frames is untouched, as predicted.
* **Nothing here is preset-dependent, and nothing here could be**: the twelve
  reverb presets share one 133-word image, and the whole symbolic stage runs on
  the word image with no coefficient value of any kind.

---

## 12. Reproducing

Inputs: `original_ROMs/kn5000_subprogram_v142.rom` (microcode + parameter
streams), `original_ROMs/kn5000_v10_program.rom` (effect names), and the ROM
parsers in `~/compartilhado/kn7000_mame/tools`. Neither disassembler was touched
by this pass and no `.dsm` was regenerated:

```
python3 dsp/verify.py                       -> BYTE-MATCH OK (kernel + epilogue + 91 streams, 38 images)
bash kn7000_mame/tools/upd6383d_diff.sh     -> MIRRORS AGREE 3057/3057
```

No MAME source was touched, so the DSPCFG-off audio path, the 384-slot cap, the
I-RAM-overrun guard and `-validate kn5000` are unchanged by construction; the two
checks above are the ones this pass could actually move and both are clean.

---

## Appendix — the prediction, verbatim

Recorded at 23:19, before any code was read and before anything was run.

```
PC-1  the obstruction SURVIVES, it does not weaken and it does not vanish.
      Survivor count under the adder = 0, against the previous 0 of 20 580 000.
PC-2  the BOTH-reads count stays 0.  The multiplicand can hold the fresh read N
      but never N and D together.
PC-3  * THE STRONG ONE.  Under the adder, dropping the CLEAR no longer moves the
      count off zero.  Old price-list row 2 gave 8 400 / 5 145 000; I predict the
      adder gives 0 there.  Reason: at slot 3 `ACTION 0x00 = load' REPLACES the
      accumulator's feedback term, so the entering accumulator is discarded
      whether or not the clear ran.  The clear is unobservable exactly where
      sect. 5 blamed it.
PC-4  the brief's stated premise is partly wrong.  "Under the adder there is no
      unconditional clear" -- the clear is still in the shipped model
      (sttime = before, FORCED by the biquad); only the STORE is gated, and the
      gate passes at slot 3.
PC-5  the positive control.  Not yet read.  Prediction: the hand-built Gardner
      ladder uses ACTION codes as free accumulator ops, which the adder abolishes
      for every ACTION except 0x00 -> the control as written FAILS under the
      adder, and a control rebuilt inside adder semantics is ACCEPTED at 2/4/5.
PC-6  the adder search space is far smaller ... I expect a space of order
      10^4-10^5, not 2x10^7.
PC-7  the residual obstruction, if PC-3 holds, points at slot 2
      (`ACTION 0x19 = tempA <- bus' reading acc) as the ONLY tempA writer.
```

Score: **4 hits, 3 misses, 1 partial** — and the two misses that matter (PC-3 and
PC-6) share a single fault: both assumed that a parameter *settled in another
context* was settled *inside this search*. That is the same error `acc-adder.md`
§4 identified in the older SINGLE DELAY pass, made again one pass later by the
same hand. The corrective is mechanical and worth stating as a rule: **a
re-run must enumerate every parameter the original enumerated, whatever else has
since been forced — otherwise the re-run is testing a conclusion, not a model.**
