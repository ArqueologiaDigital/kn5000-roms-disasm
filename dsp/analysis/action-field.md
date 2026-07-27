# The `lo12` ACTION field — solved against the all-pass, and what that falsifies

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Target: **the `lo12[4:0]`
ACTION field**, the largest blocker in `kn7000_mame/notes/dsp-frame-advance.md`
§4 (#1, 61 frame slots, 31 distinct words). Date: **2026-07-26**.
Tool: [`../tools/r1_allpass_solve.py`](../tools/r1_allpass_solve.py) sections
`control`, `action`, `singledelay`, `price` — stdlib only, re-runnable, prints
every number quoted here.

No hardware. Static analysis, the ROM corpus, constraint solving and the live
emulator only. Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED**
(every survivor of an exhaustive search agrees) / **CONSISTENT** (some survivors
have it) / **INFERRED** / **FALSIFIED** / **OPEN**.

---

## 0. Result in one page

| # | what | label |
|---|---|---|
| **A** | ★ **The all-pass core cannot be an all-pass, in the model that ships.** With the `lo12` SRC map and the accumulator-operation map held fixed, an exhaustive search over **20 580 000** machines — every assignment of ACTION `0x00`/`0x19`/`0x0B` from a 35-effect space, six readings of SRC `0x00`, four DRAM write-data sources, five read latencies, both escape-word conventions, both tempB shifts, and then both written lines on every survivor — produces **ZERO** machines that reproduce a first-order all-pass ladder. 52 696 pass the delay-loop filter; **0 of 105 392 pass the numeric test**, with the match relaxed from "up to sign" to "up to an arbitrary scale" and with both register-persistence conventions. | **MEASURED** |
| **B** | ★ **The harness can say yes.** A hand-built Gardner all-pass ladder, expressed in the SAME executor with the same delay lines, the same reference and the same matcher, is accepted at 2, 4 and 5 stages and passes the delay-loop filter. **A is therefore a statement about the MODEL, not about the search.** | **MEASURED** |
| **C** | ★ **R1's families A and B are BOTH falsified by the SRC decode.** Both require the delay-read register `DR` as an ALU operand at slots whose `lo12` SRC names something else — `000.2.00.419` reads **acc**, `012.2.00.680` reads **tempB**, `102.A.00.64B` reads **tempA**. R1 gave every slot a free choice of operands; the routing field says the operand is *not* free. Neither family survives contact with it. (Conditional on one thing, stated: that SRC names the operand on *every* word, which is anchored on five DETERMINED forms and is what the shipped executor does.) | **FORCED** under the SRC decode |
| **D** | ★ **The obstruction is LOCATED and it is EXHAUSTIVE, no numeric run required.** The all-pass multiplicand is `s[r] = x[r] + w[r] = (D − eta·P) + N`, so it must contain the **previous** delay read `D` and the **fresh** one `N` at once. Over all 5 145 000 parameter settings the multiplicand contains `N` in **70 560** of them and contains **both** `N` and `D` in **0**. The cause is the accumulator CLEAR: tempA is last writable at slot 3, which carries `hi12` bit 4 — *store the accumulator AND CLEAR IT* — after which the only live values are `P` and the current bus. | **MEASURED, exhaustive** |
| **E** | ★ **A second context gives four FORCED results — the positive half of this pass.** SINGLE DELAY (algo 9) carries the same three codes in a five-word block whose algorithm is not in doubt. Exhaustively, **5 145** assignments reproduce `v[n] = x[n] + fb·v[n−D]` exactly, and every one of them agrees that: the delay-RAM read is **BLOCKING**; **ACTION `0x19` captures into tempA**; **ACTION `0x00` routes the bus into the accumulator** (a null accumulator effect has zero survivors); and **SRC `0x00` is not the delay-read register**. | **FORCED** |
| **F** | The literal §9 reading (`d_in` and the multiplicand are one register) turns out to be **not a hypothesis but a THEOREM of the decode**: with the DRAM write taking the latched bus, the written value equals the multiplicand in **5 145 000 of 5 145 000** settings — slots 4 and 5 read the same SRC and nothing between them can rewrite it. It is falsified anyway, because **D** kills every reading of the core, and separately, if the value written to a line is the value multiplied by *that same line's* coefficient, the stage cannot be a first-order all-pass at all (§3.1). | **MEASURED** / **FORCED** |
| **G** | **R1's F6 (`land ∈ [2,5]`) does not survive.** The delay-loop filter forces `land ∈ {0,1}` in the reverb (26 348 / 26 348 each) and SINGLE DELAY needs `land = −1`, a *blocking* read whose own word already sees the returned word. F6 was a property of R1's model, which had no tempA/tempB and demanded the data land inside `DR`. | **MEASURED** |

**What did NOT happen: no ACTION code was decoded from the reverb.** The
deliverable is a located impossibility, a price list for it, and one reading that
is forced inside a *different* program. That is the honest state.

---

## 1. The motif as the decoder reads it — MEASURED

`r1_allpass_solve.py action` prints this, decoded mechanically from the words:

```
   880.1.**.2D4  ESC  src=0B dram-rd   act=14  accop=0   DRAM-RD
   104.2.**.000       src=00 (OPEN)    act=00  accop=2
   000.2.**.419       src=10 acc       act=19  accop=0
   012.2.**.680       src=1A tempB     act=00  accop=1  ST
   880.1.**.655  ESC  src=19 tempA     act=15  accop=0   DRAM-WR
   102.A.**.64B       src=19 tempA     act=0B  accop=1
   000.2.**.000       src=00 (OPEN)    act=00  accop=0     (x2, the trailing nops)
```

Three of the six ACTION codes are anchored (`0x14` = `tempB ← bus`, `0x15` = no
side effect) or open (`0x00`, `0x19`, `0x0B`). Everything else in the word is
decoded: the operand source, the accumulator operation, the store, the class-A
fetch. **This is what makes the target tractable and what makes the failure
meaningful**: only three unknowns remain, and they were searched exhaustively.

The observation this pass was sent to exploit — *the DRAM write and the multiply
carry the same SRC* — is visible in that table and is not a hypothesis: `655`
and `64B` both read **tempA**, and slots 4 and 5 are adjacent.

---

## 2. The model — declared, and every part of it anchored elsewhere

Held **FIXED** (this is `upd6383_device::exec_alu()`, verbatim in spirit; the
biquad reproduces its own designer's transfer function to 0.094 dB under it):

```
   bus  := SRC[ lo12[10:6] ]                        latched FIRST
   if hi12 bit 4 :  mem[ptr] <- acc ; acc := 0      store AND clear
   hi12[3:1]     :  0 -> acc <- P   1 -> acc += P   2 -> acc unchanged
   lo12[4:0]     :  the ACTION                      <-- the unknown
   if class4 == A :  P := coef[cursor++] * bus
```

**ENUMERATED** (the search space, 20 580 000 machines):

| parameter | values |
|---|---|
| ACTION `0x00`, `0x19`, `0x0B` | 35 each: `acc` op ∈ {none, `+bus`, `−bus`, `←bus`, `←bus−acc`} × capture ∈ {none, `tA←bus`, `tB←bus`, `tA←acc`, `tB←acc`, `M←bus`, `M←acc`} |
| SRC `0x00` reads | zero, `P`, `mem[ptr]`, `acc`, `DR`, `tempA` |
| the DRAM write data | the latched bus, `acc` before, `acc` after, `mem[ptr]` |
| the written line | `r` or `r−1` |
| read latency `land` | 0, 1, 2, 7, 8 slots (plus −1, a blocking read, in §8) |
| an ESCAPE word's `lo12` | honoured / ignored |
| the tempB bus `>>1` | on / off |

The effect space **contains the five anchored codes** — `0x13` = `('', tA←bus)`,
`0x14` = `('', tB←bus)`, `0x07` = `('', M←bus)`, `0x12`/`0x15` = `('', '')` —
which is the sanity property a semantic space must have before it is used to
solve for the codes it does not know.

**`acc ← bus − acc` is not decoration.** R1's family B needs `acc ← DR − P` in
one word; with the accumulator operation living in `hi12[3:1]`, which only ever
*adds* `P`, a reversed subtract is the only way the ACTION field could supply it.
Leaving it out of the first run made the search **vacuously empty** — reported
here because that is exactly the failure mode that would have turned into a
false "impossible".

---

## 3. The filters that do the work — and why they are model-free

A first-order all-pass stage is `(z^-D − g)/(1 − g z^-D)`. The denominator is
exact, so around delay line *k* there is **one** feedback path and it runs
through the multiply. With the write trailing the read by one repetition:

```
   C1   the class-A word's bus carries the FRESH read with coefficient +-1
        -- w_k must reach the multiplier that consumes g_k
   C2   the value written one repetition later carries that product with
        coefficient +-1                    -- g_k w_k must reach the line
   C3   and carries NO DIRECT copy of the fresh read -- an unmultiplied path
        from w_k back to d_k puts the pole on the unit circle
```

All three are properties of the **filter**, not of the ALU model, so they stay
valid under every relaxation §7 applies.

### 3.1 The model-free half of the §9 falsification

Suppose the value written to line *k* is exactly the value multiplied by line
*k*'s own coefficient — the literal §9 reading, un-pipelined. Write the line
input as `M = a·x + b·W + c·t` with `t = g·M` and `a,b,c ∈ {−1,0,+1}` (the ALU
adds; only the multiplier scales). Then

```
    M (1 - c g - b z^-D) = a x        =>   pole at  z^-D = (1 - c g)/b
```

and a first-order all-pass needs that pole at `1/g`, i.e. `g − c g² = b`. No
`b, c ∈ {−1,0,+1}` satisfies it for a general `g`. **Whatever else is true, a
delay line cannot store the value that its own stage multiplies.** What this does
*not* settle by itself is the pipelined variant, in which the write at repetition
*r* lands on line *r−1* while the multiply consumes `g_r` — that one is killed by
**D** instead, along with every other reading of the core.

### 3.2 What the filter forces among its survivors

**52 696 of 5 145 000** parameter settings pass C1–C3. Among them, two things are
FORCED *as necessary conditions*:

```
   SRC 0x00 reads the delay-RAM data register    52696 / 52696
   the read lands at slot 0 or slot 1            26348 / 26348
```

The first is structural: tempA is latched at slot 2, the delay read arrives at
slot 0 into tempB, and tempB is not read until slot 3 — so the **only** path by
which the fresh read can reach the multiplicand in time is the slot-1 word's
operand, whose SRC code is `0x00`. Note what this collides with in §8.

### 3.3 The obstruction, as an exhaustive count

The multiplicand must be `s[r] = x[r] + w[r] = (D − eta·P) + N`: it needs the
**previous** delay read and the **fresh** one at once. Over the whole space
(`r1_allpass_solve.py price`, first line of every row):

```
   the multiplicand contains the fresh read N            70560 / 5145000
   the multiplicand contains BOTH N and the previous D       0 / 5145000
```

Zero. Not "few" — **none**, and it takes no numeric run and no all-pass
reference to establish. §5 says why.

### 3.4 One caveat on the acceptance test, stated

The reference pairs `gains[k]` with `delays[k]`, in the order the coefficient
cursor and the descriptor cursor deliver them. If the real ladder were an
all-pass cascade under a *different* coefficient-to-stage alignment, the test
would fail for a reason unrelated to the ACTION field. That hole is closed by
re-running the numeric test with **every gain equal** (`equal.py` in the
scratch harness, quoted in §4), which makes the alignment question vacuous.

---

## 4. The search result — EMPTY, and the control that makes it mean something

```
   nothing relaxed:  20580000 enumerated
                        52696 pass the delay-loop filter
                            0 reproduce a 2-stage cascade
```

and, re-run with the match relaxed from "up to sign" to "up to an arbitrary
non-zero scale", with the coefficient sign free, and with the registers allowed
to persist across samples instead of being re-initialised:

```
   SCALE-FREE + persistence:                        0 of 52696
   sign-only, both written lines (wtrail 0 and 1):  0 of 105392
   EQUAL GAINS (0.50 and 0.75, two delay sets):     0 of 52696 x 4
```

The last line closes §3.4: with every stage gain equal, the coefficient-to-stage
alignment cannot be the reason for the failure.

**The positive control** (`r1_allpass_solve.py control`) builds an eight-slot
program that *is* a Gardner one-multiplier all-pass — deliberately using SRC
codes the real motif does not have, because it tests the harness and not the ISA
reading — and runs it through the same executor, delay lines, reference and
matcher:

```
   2-stage ladder, ROM gains 0.75 0.63:            MATCH  inject=P extract=P scale=+1.000
   4-stage ladder, ROM gains 0.75 0.63 0.52 0.50:  MATCH
   5-stage ladder, ROM gains 0.75 0.63 0.52 0.50 0.40: MATCH
   loop filter on the control:                     ['bus']
```

A search that cannot succeed proves nothing. This one can.

> ⚠ **RETRACTED IN PART (2026-07-27, [`schroeder-topology.md`](schroeder-topology.md) §3).**
> This control was run with the ROM's **real** ladder-0 delays
> `[127, 435, 489, 183, 522]` over 64 samples. `min(delay) = 127 > 64`, so **not
> one delay line ever recirculated** — every read returned 0 and the reference
> collapsed to `y = x·Π(−g_k)`, a pure scalar. The control was asserting only
> that the machine's output is a scalar multiple of `x`; **it could not fail.**
> Re-run at delays that do recirculate the control still MATCHES, so the search
> keeps a valid positive control — but the figures above are wrong: the true
> extraction point is **M** and the true scale **−1.000**. The SEARCH itself is
> unaffected (`action_search` uses delays `[3, 5]` over 32 samples).

---

## 5. ★ The obstruction, located

The multiplicand is the bus of `102.A.**.64B`, i.e. **tempA**, latched before
that word does anything. tempA can only be written by slots 1, 2 or 3 (slot 0 is
the read, slot 4 the write, and slot 5's own action lands after its bus latch).
Slot 3 carries `hi12` bit 4 — **store the accumulator AND CLEAR IT**.

So at the moment tempA can last be written:

```
   acc = 0  (cleared)  +  P  (the accumulator operation)  +- the current bus
   the current bus at slot 3 is tempB, i.e. the delay-line word
```

Every value tempA can hold is therefore built from `P` and reads — and
`x[r] = w[r−1] − t[r−1]` needs `w[r−1]`, a read from the **previous** repetition,
which the clear has already destroyed and which nothing else preserves: tempB is
overwritten by slot 0 of the current repetition, `mem[ptr]` by the store itself.

That is a one-line diagnosis of a 20-million-machine empty set, and it names the
assumption to attack first: **the CLEAR**, which `dsp-alu-biquad.md` §4 itself
flags as "the one genuinely new hardware claim", forced by a section in which the
store and the clear always coincide.

---

## 6. ★ SINGLE DELAY — the same three codes, in a block that works

The all-pass core is not the only place these codes occur. SINGLE DELAY (algo 9)
carries all three in a five-word block that needs no pipelining argument, and
whose algorithm is not in doubt — a delay line with feedback:

```
   w5  880.1.60.2D9  ESC  src=0B dram-rd  act=19  accop=0   DRAM READ
   w6  202.A.B8.655       src=19 tempA    act=15  accop=1   P = fb x tempA ; acc += P
   w7  000.2.48.000       src=00 (OPEN)   act=00  accop=0   acc <- P
   w8  212.2.00.419       src=10 acc      act=19  accop=1  ST
   w9  880.1.20.64B  ESC  src=19 tempA    act=0B  accop=0   DRAM WRITE
```

Read with

```
   ACTION 0x19  =  tempA <- bus
   ACTION 0x00  =  acc   += bus
   SRC    0x00  =  a memory operand (mem[ptr])
   the DRAM write data = the LATCHED BUS, i.e. tempA
   the read is BLOCKING: w5's own bus already carries the returned word
```

the block computes, exactly,

```
   w5  tempA <- d_out              w6  P = fb * d_out
   w7  acc <- P ; acc += x         w8  tempA <- acc = x + fb*d_out ; mem[ptr] <- acc
   w9  the line receives tempA
   =>  v[n] = x[n] + fb * v[n-D]
```

and the tool's numeric check on the values actually written to the line agrees
with a textbook feedback delay to the last bit (`singledelay`).

**Enumerated, not asserted.** The same exhaustive treatment over this block —
every effect for ACTION `0x00` and `0x19`, six readings of SRC `0x00`, four read
latencies, six injection points — leaves **5 145 assignments** that reproduce
`v[n] = x[n] + fb·v[n−D]` exactly. What they agree on:

```
   the read latency          FORCED   land = -1, a BLOCKING read: the DRAM read
                                      word's own bus already carries the word
                                      it just fetched                5145/5145
   ACTION 0x19, capture half FORCED   tempA  5145/5145  (tA<-bus x2940,
                                                          tA<-acc x2205)
   ACTION 0x00, acc half     FORCED   it TOUCHES the accumulator with the bus:
                                      "no accumulator effect" has ZERO survivors
                                      (+bus 2205, -bus 1960, <-bus 735,
                                       <-bus-acc 735)
   SRC 0x00 reads            4 values  mem[ptr] x3430  P x980  acc x490  zero x245
                                      -- the delay-read register: 0 of 5145
   ACTION 0x0B               35 values (i.e. UNCONSTRAINED -- it occurs in this
                                      block only on the last word, so the block
                                      cannot see it.  Stated, not searched away)
   ACTION 0x00, capture half  7 values (free)
   ACTION 0x19, acc half      5 values (free)
   the ladder input arrives   mem[ptr] x3185   acc x1960
```

**These four are the positive result of this pass**, and they are the first hard
constraints on the ACTION field beyond the five codes the biquad anchored:

1. the external delay-RAM read is **blocking** — which contradicts R1's F6
   (`land ∈ [2,5]`) outright;
2. **ACTION `0x19` captures into tempA** — §9 of `dsp-alu-structure.md`
   proposed it, `dsp-frame-advance.md` §2 priced it at 13 frame slots and called
   it "INFERRED, and internally contradicted"; here it is FORCED by a block
   whose algorithm is not in doubt;
3. **ACTION `0x00` is not a no-op** — every survivor routes the bus into the
   accumulator. This is the first direct evidence for the largest open code in
   the ISA (824 corpus words), and it is what `dsp-alu-structure.md` §6 argued
   from the LFO without being able to force;
4. SRC `0x00` is **not** the delay-RAM read register.

Note what (2) settles: the `lo12[2:0]`-as-destination pattern puts tempA at
`[2:0] == 3` and `0x19` has `[2:0] == 1`, which is why the reading was called
"internally contradicted". The contradiction is now resolved **against the
`[2:0]` pattern** — `0x19` captures tempA regardless of what `[2:0]` suggests,
and `0x1A` (§6.1) captures tempB with `[2:0] == 2`. Reading `0x19`/`0x1A` as a
second capture pair beside `0x13`/`0x14`, differing in `lo12[4:3]`, fits both.

**This is the reading `dsp-alu-structure.md` §9 proposed for `L = 0x19`, and it
survives here.** It also explains R1 §7.1's 44/44-versus-0/56 split without a
coincidence: the two write forms whose SRC is tempA (`64B`, `655`) are always
preceded by a word that *loads* tempA, because tempA is the write-data register.

### 6.1 A pattern across all three delay blocks — and the core is the odd one out

Every external-delay block in the corpus has the shape *read → … → multiply*, and
in two of the three the **read word's ACTION captures the returned word into
exactly the register the following multiply names through SRC**:

| block | the DRAM read word | its ACTION | the next multiply's SRC |
|---|---|---|---|
| SINGLE DELAY w5/w6 | `880.1.60.2D9` | `0x19` | **tempA** (`202.A.B8.655`) |
| reverb separator w11/w12 | `880.1.60.2DA` | `0x1A` | **tempB** (`000.A.00.695`) |
| **the all-pass core** slot 0/5 | `880.1.60.2D4` | `0x14` = tempB **(anchored)** | **tempA** (`102.A.00.64B`) — *mismatch* |

Read as a rule this says `0x19` captures **tempA** and `0x1A` captures **tempB**,
i.e. they are a second pair of capture codes beside the anchored `0x13`/`0x14`,
with the same two destinations and `lo12[4:3]` = 3 instead of 2. The arithmetic
of the codes agrees: `0x19 = 0x13 + 6`, `0x1A = 0x14 + 6`.

The separator's case has independent support: at the *first* separator the tap
gain `C-RAM[0x96] = 0.500` (role PROVEN) multiplies tempB, and it is the tap data
that a tap gain must scale. **Caveat, stated:** three earlier words in that body
(`0x0B`, `0x0D`, `0x0E`) carry unanchored ACTION codes and could in principle
have written tempB, so this is CONSISTENT and not FORCED.

And the third row is the one that does not fit — the same core the search cannot
make work. Two independent symptoms of one thing being wrong is worth more than
either alone.

---

## 7. ★ The price list — one fixed assumption relaxed at a time

`r1_allpass_solve.py price` re-runs the whole thing with exactly one FIXED
assumption changed. The middle column is §3.3's exhaustive count — how many
settings can put both delay reads into the multiplicand, which is the minimum
requirement for `s[r] = x[r] + w[r]`.

| # | assumption relaxed | multiplicand can hold BOTH reads | pass the loop filter | reproduce a cascade |
|---|---|---|---|---|
| 0 | *(nothing — the shipped model)* | **0** / 5 145 000 | 52 696 | **0** (measured) |
| 1 | the two trailing nops are INERT | **0** / 5 145 000 | | 0 (implied) |
| **2** | ★ **`hi12` bit 4 stores WITHOUT clearing acc** | **8 400** / 5 145 000 | **29 548** | **0** (measured) |
| 3 | slot 1's `hi12[3:1]=2` is `acc ← P` | **0** / 5 145 000 | | 0 (implied) |
| 4 | slot 1's `hi12[3:1]=2` is `acc += P` | **0** / 5 145 000 | | 0 (implied) |
| 5 | slot 1's `hi12[3:1]=2` is `acc := 0` | **0** / 5 145 000 | | 0 (implied) |
| 6 | the ACTION acts BEFORE `hi12[3:1]` | **0** / 5 145 000 | | 0 (implied) |
| 7 | the DRAM read/write directions swapped | **0** / 5 145 000 | 0 | **0** (measured) |
| 8 | an ESCAPE word honours `hi12[3:1]` too | **0** / 5 145 000 | | 0 (implied) |
| 9 | an ESCAPE word ignores `lo12` entirely | **0** / 2 572 500 | | 0 (implied) |

*"implied" is not a shrug*: `BOTH reads = 0` means no setting can put `s[r]` in
the multiplicand, and a cascade of first-order all-passes needs `s[r]` there, so
the numeric count is **zero by the same argument that makes row 0 zero** — it was
measured for rows 0, 2 and 7 and derived for the rest, which is stated rather
than presented as seven more measurements.

**Eight of the nine relaxations change nothing at all. One changes everything.**
The obstruction is not diffuse and it is not "the ACTION codes" — it is a single
modelling decision, and the price list names it without being asked to:

> **`hi12` bit 4 CLEARS the accumulator.**

That claim is the newest and least-supported part of the shipped ALU.
`dsp-alu-biquad.md` §4 introduces it as *"the one genuinely new hardware claim
here"* and is explicit that the biquad only ever exercises it where the store and
the clear coincide, so the section cannot tell a store-and-clear from a store.
The all-pass core is a place where they do **not** coincide — and there the clear
makes the algorithm impossible.

Row 7 is worth reading as a control: swapping the DRAM read and write directions
takes the fresh read out of reach entirely (`0/5 145 000` even for the weaker
condition), and its loop filter and numeric stage both collapse to zero. R1's F1
survives; it was never in doubt here.

**But dropping the clear is NECESSARY, not SUFFICIENT.** With it removed, 29 548
machines pass the delay-loop filter and **still 0 reproduce the cascade**. So the
clear is *a* wrong thing in the model, and something else is wrong as well. The
core is not decoded by this pass and this note does not pretend otherwise.

### 7.1 What the multiplicand becomes once the clear is gone

The 8 400 settings produce **25 distinct multiplicand forms**, and every single
one of them is

```
   +-A  +- k*P  +- D  +- N          k in {0,1,2},  and D sometimes as 0.5*D
                                    (the machines that keep the tempB >>1)
```

— always with the **entry accumulator `A`** in it. The form the all-pass needs,
`D − P + N`, has no `A` and never appears. That is the residual obstruction in
one line: with the clear gone the two reads can only meet *inside the
accumulator*, which also drags in whatever the accumulator was carrying, and
nothing in the core can subtract that back out again. The `0.5*D` variants are
exactly the machines that keep the biquad's tempB `>>1`, so that shift is not the
problem either.

---

## 8. ★ The collision, stated plainly

> ⚠ **RE-READ 2026-07-27 — it is not a collision** (`action00-discriminator.md`
> §5.3). Both of the reverb's "demands" below are **necessary conditions of the
> first-order all-pass hypothesis**, and that hypothesis is refuted by the same
> tool, exhaustively and twice (0 of 20 580 000 sequential, 0 again under the
> adder, obstruction located in slot 4's write — `allpass-adder-rerun.md` §6.3).
> A necessary condition of a false premise carries no information, so there is
> nothing here for SINGLE DELAY to contradict. The same applies to the
> `9520 of 9660` demand that `ACTION 0x00` keep the accumulator. **The reverb
> imposes no *unconditional* constraint on `SRC 0x00` or on `ACTION 0x00`.**
> (What *did* move is SINGLE DELAY's side: its `SRC 0x00 = mem[ptr]` is forced
> only while the block's input-mix coefficients are the zeros the ROM loads —
> give them a gain and `acc` becomes equally admissible. `DR` still has zero
> survivors under every variant.)

Two contexts, two different demands on the same code:

| | the reverb ladder demands | SINGLE DELAY demands |
|---|---|---|
| `SRC 0x00` | the **delay-RAM read register**, 52 696/52 696 — the only path by which the fresh read reaches the multiplicand in time | **not** the delay-RAM read register: **0 of 5 145**. `mem[ptr]` in 3 430, otherwise `P`, `acc` or nothing |
| the read latency | `land ∈ {0,1}` | `land = −1`, a **blocking** read, FORCED 5 145/5 145 |

> ## ⚠ ★★ THE TWO ROWS ARE ONE ROW — 2026-07-27, `blocking-read.md`
>
> The second row **causes** the first, and printing them side by side is what
> made it visible. `land = −1` is the **BLOCKING read**: the DRAM read word's own
> operand bus already carries the word it fetched. `action_search` enumerates
> `LANDS = (0,1,2,7,8)` and **omits it**, so inside the reverb's space the fresh
> sample could reach the ALU by exactly one route — `SRC 0x00 = DR` at slot 1.
> The two blocks were being solved **under different read models**, and the one
> whose read model could not deliver the word is the one that "required" a second
> route for it.
>
> Restore the blocking read and the reverb reaches slot 3 through the read word's
> **own anchored ACTION `0x14` (`tempB ← bus`)**: **3 206** comb machines survive
> (against 112 published) with `SRC 0x00` at **six** values, and in the sequential
> model **2 310** with `SRC 0x00` perfectly uniform, 385 each. **The reverb has no
> opinion about `SRC 0x00`.** `DR` is now refused by SINGLE DELAY (0/5 832),
> by `dark-words.md`'s H-DIR/R3 structural test, and by nothing at all in the
> reverb — a 3-0 agreement where there used to be a deadlock.
>
> Also: `land ∈ {0,1}` is **one machine counted twice** (`exec_rep` makes both
> first visible at slot 1; 4 000/4 000 symbolically identical), so the row's left
> cell was never a two-valued freedom either.

They cannot both be right, and one of them is not. The SINGLE DELAY reading is
the one that produces a working algorithm end-to-end with no free parameters
left over; the reverb "requirement" is a *necessary condition of an assumption
that the same search then refutes*. The honest reading is therefore:

> **the reverb core is not doing what the all-pass model says it is doing**,
> under the shipped ALU — and §5 says exactly which part of the shipped ALU to
> suspect.

---

## 9. What this pass FALSIFIES

| claim | where it came from | status now |
|---|---|---|
| all-pass core **family A** (`mem[ptr]` carries *x*) | `r1-allpass-motif.md` §5.2 | **FALSIFIED** — needs `DR` and `mem[ptr]` as ALU operands at slots whose SRC reads `acc` and `tempB` |
| all-pass core **family B** (`mem[ptr]` stages the write) | `r1-allpass-motif.md` §5.1, ranked first | **FALSIFIED** — same reason; slot 2 must compute `acc − DR` but its operand is `acc` |
| **F6**: the DRAM read data becomes visible 2–5 words later | `r1-allpass-motif.md` F6, "0 and 1 have zero survivors" | **FALSIFIED as general** — model-dependent; both contexts here need 0, 1 or a blocking read |
| **F8**: the multiplicand is the word's own ALU result | `r1-allpass-motif.md` F8 (2-input ALU only) | **INCOMPATIBLE** with the shipped ALU, in which the multiplicand is the bus latched *before* the word acts. One of the two must go; the bus reading is anchored on three DETERMINED forms (`mac`, `mac.lb`, `mulst`) and F8 was already labelled model-dependent |
| the literal §9 reading (`d_in` = the multiplicand) | `dsp-alu-structure.md` §9 | **FALSIFIED**, now twice and the second time model-free (§3, C3) |

**Not falsified, and worth saying so:** §9's *other* proposal — `L = 0x19` =
"capture into latch A" — comes out of SINGLE DELAY intact and load-bearing.

---

## 10. What is FORCED, CONSISTENT, and OPEN

**FORCED**

* No assignment of ACTION `0x00`/`0x19`/`0x0B` makes the reverb core a
  first-order all-pass stage under the shipped ALU (§4), and the immediate reason
  is the accumulator clear (§5, §7). Dropping the clear is **necessary** — it is
  the only one of nine relaxations that changes the count at all — and **not
  sufficient**: 29 548 machines then pass the loop filter and none reproduces the
  cascade.
* A delay line cannot store the value that its own stage multiplies (§3.1) — the
  un-pipelined literal reading of §9, killed by two lines of algebra.
* The result is robust to the coefficient-to-stage alignment: with every gain
  equal (0.50 and 0.75, two delay sets), still **0** of 52 696 (`equal.py`).

**FORCED inside SINGLE DELAY** (5 145/5 145 survivors, §6) — the block is a
second context and these are the pass's positive results:

```
   ACTION 0x19  captures into tempA          (tA<-bus or tA<-acc; which is free)
   ACTION 0x00  routes the bus into the accumulator, i.e. it is NOT a no-op
                (+bus / -bus / <-bus / <-bus-acc; which is free)
   the external delay-RAM read is BLOCKING   (land = -1)
   SRC 0x00     is NOT the delay-read register
```

**CONSISTENT, not forced**

* `SRC 0x00 = mem[ptr]` — 3 430 of 5 145 survivors, the largest group, and the
  only one that makes the block's input arrive where the pointer walk puts it;
* the DRAM write takes the **latched bus** (tempA) — used by the positive
  control and by every SINGLE DELAY survivor, and it is what makes R1 §7.1's
  44/44-versus-0/56 store-adjacency split non-coincidental;
* `ACTION 0x1A` captures into **tempB** (§6.1, from the reverb separator's tap
  gain; three earlier unanchored codes could also have written tempB).

**OPEN**

* every ACTION code except the five already anchored — **this pass decoded none
  of them from the reverb**, which was the target, and says so;
* whether `hi12` bit 4 really clears the accumulator outside the biquad — now the
  single highest-value question in the ALU, because it is the only assumption
  whose removal moves the count off zero (§7);
* what the reverb core actually computes. It is not a Gardner all-pass stage
  under this decode, and the two independent symptoms of §5 and §6.1 say the
  fault is in the core's reading, not in the three unknown codes.

---

## 11. What this constrains for the other two targets

* **TARGET 3 (the LFO ramp).** The LFO's two words `092.A.dd.200` and
  `094.A.dd.200` carry ACTION `0x00`, and this pass **FORCES** that `0x00` routes
  the bus into the accumulator (§6) — so the LFO solve should treat `0x00` as an
  accumulator-writing action with four candidate signs, not as a no-op, and the
  ramp `phase += increment` has a mechanism available to it. The second, harder
  transfer is the **warning**: the reverb ladder and SINGLE DELAY demand
  *different* things of SRC `0x00` (delay-read register vs anything but), so the
  LFO must solve SRC `0x00` for itself rather than inherit either.
* **The ACTION field generally.** `0x19` captures **tempA** (FORCED) and `0x1A`
  captures **tempB** (CONSISTENT). Those are worth `dsp-frame-advance.md` §4's
  13 + n frame slots — but note that adopting them in the executor is a separate
  decision from decoding them, and the core's `0x00`/`0x0B` are still OPEN, so
  the words that carry them must keep trapping.
* **TARGET 1 (frame closure).** Nothing here moves the pointer walk: every word
  examined has `addr8 == 0` inside a ladder (F7, MEASURED), so the closure
  residue is untouched. The one transferable item is methodological — the
  positive control. A closure solve should carry one too.

---

## 12. PREDICT-THEN-CHECK

| | prediction, recorded before the solver ran | result |
|---|---|---|
| **P-1** | the survivor set will be NON-EMPTY | **MISS.** 0 of 20 580 000 |
| **P-2** | zero survivors will have `WVAL == MULT` | **vacuously true, and therefore not evidence** — there are no survivors at all. Replaced by the model-free argument of §3 (C3), which is the claim that actually holds |
| **P-3** | `ACTION 0x19 = tempA ← bus` will be FORCED | **HIT, in the second context.** Not forced by the reverb (nothing is), but SINGLE DELAY forces the *destination* at 5 145/5 145 — `tempA`, `bus` or post-op `acc` |
| **P-4** | some ACTION must route the bus into the accumulator | **HIT, and forced.** ACTION `0x00` does, in 5 145/5 145 SINGLE DELAY survivors; a null accumulator effect has zero |
| **P-5** | `tb_shift = 0` will be required | **UNRESOLVED.** No reverb survivors to force it; SINGLE DELAY never reads tempB |
| **P-6** | the DRAM write data will be FORCED to the latched bus | **partial.** Forced in neither direction by the empty reverb search; it is what the positive control and SINGLE DELAY both use, and what makes R1 §7.1's split non-coincidental |
| **P-7** | `land` will not be forced into R1's [2,5] | **HIT.** `{0,1}` in the reverb filter, `−1` in SINGLE DELAY |
| **P-8** | *(during the run)* leaving `acc ← bus − acc` out of the effect space is harmless | **MISS, and the important one.** It made the search vacuously empty. Recorded because an unnoticed too-small space is how a false impossibility gets published |
| **P-9** | *(before the price list ran, from §5)* the accumulator CLEAR is the assumption that blocks it | **HIT, and cleanly.** It is the only one of nine relaxations that moves the count off zero: 8 400 / 5 145 000 against 0 for every other |
| **P-10** | with the clear removed, machines will reproduce the cascade | **MISS.** 29 548 pass the loop filter, **0** reproduce it. Necessary, not sufficient |

---

## 13. Reproducing

```
python3 dsp/tools/r1_allpass_solve.py control       # the harness must say yes  (~5 s)
python3 dsp/tools/r1_allpass_solve.py action        # the main search           (~10 min)
python3 dsp/tools/r1_allpass_solve.py singledelay   # the second context        (~5 min)
python3 dsp/tools/r1_allpass_solve.py price         # one assumption relaxed at a time
python3 dsp/verify.py                               # the tree still byte-matches
```

Inputs: `original_ROMs/kn5000_subprogram_v142.rom` (microcode + parameter
streams), `original_ROMs/kn5000_v10_program.rom` (effect names), and the ROM
parsers in `~/compartilhado/kn7000_mame/tools`.

Neither disassembler was touched by this pass and no `.dsm` was regenerated, so
`dsp/verify.py` still reports **BYTE-MATCH OK** and
`kn7000_mame/tools/upd6383d_diff.sh` still reports **3057/3057**.
