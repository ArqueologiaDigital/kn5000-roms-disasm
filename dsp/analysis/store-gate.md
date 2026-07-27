# THE BIT-7 STORE GATE — enumerated as a function, and priced

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus and constraint solving only.

Tool: [`../tools/gate_settle.py`](../tools/gate_settle.py) — standard library
only, re-runnable, and it prints **every number quoted below**:

```
python3 dsp/tools/gate_settle.py control    # ★ RUN FIRST -- can the tests say NO?
python3 dsp/tools/gate_settle.py enum       # ★ THE ENUMERATION + the measured quotient
python3 dsp/tools/gate_settle.py census     # ★ THE GATE DECIDABILITY CENSUS
python3 dsp/tools/gate_settle.py price      # ★ what settling it is WORTH, in words
python3 dsp/tools/gate_settle.py condition  # the `f31==1' vs `f31!=2' half
python3 dsp/tools/gate_settle.py dead       # the STRUCTURAL criterion + its base rate
python3 dsp/tools/gate_settle.py biquad     # class (0,1), against the designer
python3 dsp/tools/gate_settle.py mirror     # reproduce the published numbers  (~8 min)
python3 dsp/tools/gate_settle.py lfo        # classes (1,1)/(1,2), EXHAUSTIVE  (~25 min)
python3 dsp/tools/gate_settle.py joint      # ★ the intersection               (~30 min)
python3 dsp/tools/gate_settle.py vacuity    # ★ the f31 == 0 vacuity sweep
python3 dsp/tools/gate_settle.py hostmix    # ★ SRC 0x00 -- the host's own parameter table
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** (every survivor of
an exhaustive search agrees) / **CONSISTENT** / **FALSIFIED** / **OPEN**.

**Nothing here is applied to the MAME device and neither disassembler was
touched.** No word gains or loses an executable semantic, every currently
trapping word still traps, `dsp/verify.py` is **BYTE-MATCH OK**, and the
rendered audio cannot have moved. §11.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE GATE IS NOT A LIST, IT IS A FUNCTION — AND THE FUNCTION HAS ONLY FIVE ARGUMENTS.** A bit-4 store word is characterised for the ALU by `(hi12 bit 7, hi12[3:1])`; `hi12[3:1] > 2` traps, so there are **six** addressable store classes and the corpus occupies **five**: `(0,0)` 12 words, `(0,1)` 486, `(1,0)` 2, `(1,1)` 130, `(1,2)` 29. `(0,2)` has **zero** words — a gate's behaviour there is unobservable **by construction**. Enumerating an EFFECT per class (memory op ∈ {none, store, **load**} × value {acc, bus} × destination {ptr, elsewhere} × timing {before, after} × clear {never, before, after} = **33** canonical effects) gives **33⁵ = 39 135 393** gates and absorbs the global `sttime`, which the published parameterisation double-counted. The published space was **18 (name, sttime) pairs**, all inside. | **PROVEN BY CONSTRUCTION** + **MEASURED** |
| **B** | ★★★ **THE DECIDABILITY CENSUS, AND IT DECIDES WHAT IS ANSWERABLE AT ALL.** Three of the five occupied classes have a witness whose arithmetic is known independently of the DSP and **two do not**. PARAMETRIC EQ's 22 store words are **all** class `(0,1)`; SINGLE DELAY's are **all** class `(0,1)`; the 29 LFO ramp blocks carry **only** `(0,1)`, `(1,1)` and `(1,2)`. **Nothing with known mathematics sees `(0,0)` (12 words) or `(1,0)` (2 words)** — they are reachable only structurally. The biquad's measured blindness to the bit-7 gate is therefore not luck: PARAMETRIC EQ has **no bit-7 store word at all**. | **MEASURED** |
| **C** | ★★★ **bit 7 IS IN THE GATE CONDITION — FORCED, and by two blocks that disagree about the same `hi12[3:1]`.** Class `(0,1)` and class `(1,1)` differ **in bit 7 and in nothing else**. The biquad REQUIRES `(0,1)` to store to `mem[ptr]` (suppressing it is **51.090 dB** wrong against the designer); the LFO REQUIRES `(1,1)` **not** to write `mem[ptr]`. Checked, not asserted: all **nine** conditions in the enumeration are run against both witnesses and exactly **two survive** — `b7 & f31 == 1` and `b7 & f31 != 2`. The two bit-7-free ones (`f31 == 1`, `NOT b7`) are killed by the **biquad at 52.381 dB**; `always`, `b7 alone`, `b7 & f31 == 0`, `b7 & f31 == 2` and `f31 == 2` are killed by the **LFO**. Each witness kills conditions the other accepts, so neither is doing the work alone. This is the first *positive* determination about what bit 7 is for. | **FORCED** |
| **D** | ★★★ **THE LFO DOES NOT FORCE "THE STORE IS SUPPRESSED". IT FORCES "THE STORE DOES NOT REACH `mem[ptr]`".** Exhaustively over **19 758 816** machines (33 × 33 class effects × 18 144 non-gate settings), **17 928** survive all 29 blocks and the 2²³ wrap, and class `(1,1)` takes **21 of 33** effects — but **not one survivor writes `mem[ptr]`**. What survives is `none`, `store → elsewhere`, and ★ `load` — *the memory access is a READ into the accumulator*. The third reading is new: **bit 7 as a DIRECTION bit on the memory port**, which explains the bit instead of merely fitting it. `lfo-ramp.md` item K said "suppressed-or-redirected"; that disjunction is now measured, and it has a third arm. | **FORCED** (negative) / **MEASURED** |
| **E** | ★★ **CLASS `(1,2)` IS FORCED, AND IT IS THE ORDINARY STORE.** 17 928/17 928 survivors give `(1,2)` = **store the accumulator to `mem[ptr]`, BEFORE the word's own ALU step**; only the clear is free (never/before/after, 5 976 each). Class `(0,1)` is FORCED by the biquad to **store the accumulator to `mem[ptr]` with the clear taken BEFORE the ALU** — with a measured blindness: at PARAMETRIC EQ's store words the bus *is* the accumulator, so `store the BUS` is bit-identical (**0.198 dB**, accepted) and the store's *source* is not decidable there. | **FORCED** (both) + **MEASURED** (the blindness) |
| **F** | ★★★ **THE CONDITION QUESTION — `b7 & f31 == 1` vs `b7 & f31 != 2` — IS WORTH ONE CORPUS WORD, AND ITS STORE IS DEAD.** `lfo-ramp.md` item K and `acc-adder.md` §8 leave it open as *"13 corpus words, nine of them the COMPRESSOR's envelope step at `hi12[3:1] == 5`"*. MEASURED: the disagreement set is **11**, not 13; **9** of them trap because `hi12[3:1] > 2` is an undecoded accumulator operation and **1** more (`090.2.FB.40E`) because ACTION `0x0E` is not anchored — **both reasons independent of bit 7 and of the gate**. Exactly **one** word's behaviour changes: `090.A.00.1D5`, ROOM REVERB 1 `w107`, and its cell is overwritten by `w108` at the same pointer with no read in between. **A dead store.** | **MEASURED**, a **FALSIFICATION** of the published count |
| **G** | ★★★ **THE WHOLE GATE IS WORTH 17 WORDS IN 9 PROGRAMS, NOT 130.** Of the 130 class-`(1,1)` words, **114 trap for reasons that have nothing to do with bit 7** — SRC `0x1C` ×46, SRC `0x00` ×31, SRC `0x08` ×29, ACTION `0x1A` ×6, ACTION `0x0E` ×2, none of them anchored. Words the shipped decoder refuses **and would accept if the gate were settled — refused by guard 7 and by nothing else — number 17** (16 at class `(1,1)`, 1 at `(1,0)`). ★ And **not one of the 16 carries ACTION `0x00`**, so guard 7's *"`f31 == 1` requires ACTION `0x00`"* clause refuses every one of them today. | **MEASURED** |
| **H** | ★★ **THE MIRROR CHECK PASSES EXACTLY — AND ONLY AFTER IT CAUGHT A BUG IN THIS PASS.** Restricted to the published spaces this tool returns `4416 → 4416 → 3312` (`action00-discriminator.md` published **3312**) and `1632 → 1632 → 1224` (`acc-adder.md` published **1224**), with the `(act00, gate)` table reproduced **row for row**. It did not on the first run: mapping `(condition, effect, sttime)` as an independent product gave 3456, because in the published tool the global `sttime` also moves a **gated** word's clear. Fixing that exposed two defects in the published space. ★ **DEGENERACY:** the 18 `(gate name, sttime)` pairs are only **16 distinct machines** — `b7_f31_1_keepclear` and `b7_f31_1_clrlate` coincide at `sttime ∈ {after, st_before_clr_after}`. ★ **HOLE:** `action00-discriminator.md`'s `STGATE` list has `b7_f31_1_{off, keepclear, clrlate}` but only `b7_ne2_{off, clrlate}` — **`b7_ne2_keepclear` was never enumerated.** Method rule 3, in the file that wrote method rule 3. | **MEASURED** |
| **I** | ★ **AND THE OBSERVATIONAL QUOTIENT IS `act00`-DEPENDENT — WHICH IS THE COUPLING, MEASURED AS A NUMBER.** At the LFO's `092.A.00.200` the 33 effects collapse to **15** distinguishable machines under `act00 = load` and **23** under `act00 = add`: with `load` the word's own ALU overwrites the accumulator and a third of the gate becomes invisible. `action00-discriminator.md` item C said the two questions are one; here is *how much* of the gate each reading of `ACTION 0x00` lets you see. The coupling itself re-derives exactly: `add` and `rload` occur **only** with a late clear, `bsel` **only** with an early one, `load` with all three. | **MEASURED** |
| **J** | ★★★ **SECOND TASK — `SRC 0x00`: THE AMBIGUITY DOES NOT CLOSE, AND THE CELL HAS A NAME ON THE FRONT PANEL.** `blocking-read.md` item G makes `SRC 0x00 = mem[ptr]` forced *only while SINGLE DELAY's two "input-mix" coefficients are 0.0000*, and names an emulator capture. A capture can only SAMPLE; the firmware's own parameter table decides, exhaustively. MEASURED: SINGLE DELAY's `w3` coefficient is **C-RAM cell `0x00`**; algorithm 9's T2 stream writes it with `op 73 #00`; and `register-space.md`'s UI alignment names opcode `0x73` **`FEEDBACK L`** (`FEEDBACK L`/`FEEDBACK R`/`RESONANCE`, 28 of 28). ★ **The "input-mix coefficient that happens to be zero" is the SINGLE DELAY FEEDBACK knob, and `0.0000` is simply *feedback = 0* as the shipped default.** Corroborated by a control that could fail: at all **28 of 28** `op 0x73` targets the ROM-loaded C-RAM value lies inside that record's own `(lo, hi)` pair — **0 outside**, against 85 % corpus-wide — and **8 of the 28 are already non-zero** (`+0.3000`, `+0.0250`). **`SRC 0x00 = mem[ptr]` stays CONSISTENT, the 30 PARTIAL + 10 TRAP slots keep trapping, and the capture is superseded.** | **MEASURED** |
| **J′** | ★★ **AND IT PUTS A PUBLISHED NAME IN DOUBT — flagged as a lead, not a result.** `action00-discriminator.md` §0-H calls `w3`/`w4` "the two input-mix coefficients" and `w6` (cell `0x02`, `0.5000`) "the feedback". The host calls cell `0x00` **FEEDBACK L** and cell `0x09` **FEEDBACK R**, and does not name cell `0x02` at all. Either the SD motif's roles are mis-assigned or algorithm 9's image contains more than one delay whose cells do not line up with the first motif instance. **OPEN**, and it belongs to whoever next touches SINGLE DELAY. | **OPEN** |
| **K** | ★ **THIRD TASK — THE VACUITY SWEEP: NO NEW HEADLINE FALLS.** The theorem (`load`, `add` and `rload` are the same expression wherever `hi12[3:1] == 0`) is verified at 3 000/3 000 random states at SINGLE DELAY `w7` and shown able to say *different* at the LFO's `082` and the reverb's slot 1 (0/3 000 each). Swept over every published ACTION determination: `action-field.md` §6's SINGLE DELAY forcing is stated at exactly the strength its `f31 == 0` site can bear (*"not a no-op"*, and `none` **is** distinguishable there) and **survives**; `ACTION 0x19`'s two determinations sit at `f31 == 1` and survive; `schroeder-topology.md` §0-B and `allpass-adder-rerun.md` §0-C rest on motif slots 1 and 3 (`f31 = 2` and `1`) and survive. **152 of the field's 806 ACTION-`0x00` words (18.9 %) are structurally incapable of deciding their own accumulator half.** Reported as a **MISS**: the sweep was expected to catch one and caught none. Attribution: the theorem is `schroeder-topology.md` item H. | **MEASURED** / a **MISS** |
| **L** | Housekeeping: `dsp/verify.py` **BYTE-MATCH OK**; no `.dsm` regenerated; no device or disassembler file touched; the DSPCFG-off audio is untouched **by construction**. §11. | **MEASURED** |

---

## 1. The enumeration, and why the old one could not have worked

`acc-adder.md` enumerated **four** gates, `action00-discriminator.md` **six**,
each a hand-named lambda over `(bit 7, hi12[3:1])`, and each carried the global
store timing `sttime` as a **separate** parameter. That shape has three defects,
and this pass hit all three:

1. **it mixes a CONDITION with an EFFECT**, so "which words are gated" and "what
   the gate does" cannot be answered separately even though they have different
   witnesses;
2. **it double-counts**, because `sttime` also moves a *gated* word's clear — two
   of the eighteen published points are literally the same machine (§0-H);
3. **it is not closed**: the list has `b7_f31_1_{off, keepclear, clrlate}` and
   only `b7_ne2_{off, clrlate}`. `b7_ne2_keepclear` is missing.

### 1.0 The mirror check — this tool reproduces both published passes

```
   the biquad control, three published numbers
      shipped (store+clear before)  :  0.198 dB   (published  0.198)  OK
      store and clear AFTER         : 84.768 dB   (published 84.768)  OK
      store early, clear LATE       : 51.090 dB   (published 51.090)  OK

   the LFO, on the PUBLISHED spaces, carrying the (gate name, sttime) PAIRS with
   their duplicates -- which is what the published tools enumerate:
      action00-discriminator.md : 18 pairs x 18144 = 326592 -> 4416 -> 4416 -> 3312
                                                              (it published 3312)
      acc-adder.md              : 12 pairs x 15120 = 181440 -> 1632 -> 1632 -> 1224
                                                              (it published 1224)
      the (act00, gate) table   : reproduced ROW FOR ROW
         add/b7_f31_1_clrlate 432   add/b7_ne2_clrlate 432   add/keepclear 216
         load x288 on all five gates    rload/clrlate 288 x2   rload/keepclear 144
         bsel/b7_f31_1_keepclear 72
```

★ **It did not pass on the first run**, and that is why the section exists: the
first mapping of the published space into this one treated `(condition, effect,
sttime)` as an independent product and returned 3456. In
`action00_discriminate.step()` the global `sttime` also moves a **gated** word's
clear, so `stgate = keepclear` with `sttime = st_before_clr_after` *is*
`stgate = clrlate`. Composing them correctly gives 3312 to the digit — and
exposes defects 2 and 3 above.

Replace it with the honest object. A bit-4 store word is characterised for the
ALU by `(b7, f31)` alone, because `f31 > 2` is undecoded and the word traps
before the gate is consulted. So:

```
   G : (b7, f31)  ->  EFFECT

   EFFECT = mem_op   in {none, store, load}
            value    in {acc, bus}          (store only)
            dest     in {ptr, elsewhere}    (store only)
            mtime    in {before, after}     relative to the word's own ALU step
            clear    in {never, before, after}
          = 33 canonical effects
```

`mem_op = load` is the mechanism no published pass enumerated: **bit 7 as a
DIRECTION bit on the memory port**, so that a bit-4 word with bit 7 set *reads*
`mem[ptr]` into the accumulator instead of writing it. It is as physical as a
gate, it is a better answer to *"what does bit 7 MEAN"* than "it inhibits", and
§4 shows it runs the LFO.

```
   corpus store words by class, over the 38 distinct body images
      b7=0 f31=0 :   12
      b7=0 f31=1 :  486
      b7=0 f31=4 :   12   <- hi12[3:1] > 2: the word TRAPS, the gate never runs
      b7=1 f31=0 :    2
      b7=1 f31=1 :  130
      b7=1 f31=2 :   29
      b7=1 f31=5 :    9   <- ditto
      TOTAL      :  680

   addressable classes                : 6
   classes that OCCUR with a store    : 5   (0,0) (0,1) (1,0) (1,1) (1,2)
   ★ classes that are VACUOUS         : (0,2) -- 0 words, unobservable
   size of the gate space             : 33^5 = 39 135 393
   the published space                : 18 (name, sttime) pairs = 16 machines
```

### 1.1 The observational quotient — measured, not asserted

Method rule 4 says check for degeneracy *before* reporting a split. Each of the
33 effects is run on 400 random states at a real corpus word and effects with
identical `(acc, P, memory)` traces are merged:

```
   class (1,0)  090.A.00.1D5  act00=load : 13 of 33 distinguishable
                              act00=add  : 13 of 33
   class (1,1)  092.A.00.200  act00=load : 15 of 33
                              act00=add  : 23 of 33     ★
   class (0,1)  212.A.00.415  act00=load : 17 of 33
                              act00=add  : 17 of 33
```

Two things fall straight out.

* **At `hi12[3:1] == 0` the clear is VACUOUS.** The word's own ALU writes
  `acc ← 0 + P`, so a clear taken *before* it — and a read *into* it before it —
  cannot be seen. Classes `(0,0)` and `(1,0)` therefore have exactly one live
  question: **does the store happen at all.**
* **The quotient depends on `ACTION 0x00`,** and that is the coupling of
  `action00-discriminator.md` item C expressed as a number: under `load` the
  gate's own word erases the accumulator and 18 of the 33 effects become
  indistinguishable; under `add` only 10 do.

---

## 2. The decidability census

Which corpus words can tell two gate readings apart at all? Two gates differ only
where their effects differ, and an effect is attached to a class — so the
question is per class.

```
   class       words  progs  known-mathematics witness WINDOW
   b7=0 f31=0   12     8     ★ NONE
   b7=0 f31=1   486    38    PARAMETRIC EQ biquad; SINGLE DELAY comb window;
                             LFO ramp, 29 blocks
   b7=0 f31=2   0      0     ★ NONE  (and no words either)
   b7=1 f31=0   2      1     ★ NONE
   b7=1 f31=1   130    30    LFO ramp, 29 blocks
   b7=1 f31=2   29     16    LFO ramp, 29 blocks

   PARAMETRIC EQ store words, by class : {b7=0,f31=1: 22}
   SINGLE DELAY  store words, by class : {b7=0,f31=1: 10}
   LFO ramp      store words, by class : {b7=0,f31=1: 6, b7=1,f31=1: 45,
                                          b7=1,f31=2: 37}
```

**Read the first two columns of that table against the third and the pass plans
itself.** `(0,1)`, `(1,1)` and `(1,2)` — 645 of the 659 decodable store words —
have a witness. `(0,0)` and `(1,0)` have none, and never will until one of
CHORUS, ENSEMBLE, MULTI TAP DELAY, AUTO WAH or the reverb has its algorithm
reverse-engineered.

★ **And the census yields a forcing before any search runs.** Classes `(0,1)`
and `(1,1)` differ in **bit 7 and in nothing else**. §3 shows the biquad demands
that `(0,1)` store and §4 shows the LFO demands that `(1,1)` not write
`mem[ptr]`. **No condition that ignores bit 7 can satisfy both.** Checked rather
than asserted — every condition in the enumeration run against both witnesses:

```
   condition            biquad (class (0,1))       LFO
   always (no gate)        0.198 dB  accepts      REJECTED
   b7 & f31==1             0.198 dB  accepts      runs        <- SURVIVES
   b7 & f31!=2             0.198 dB  accepts      runs        <- SURVIVES
   b7 alone                0.198 dB  accepts      REJECTED
   b7 & f31==0             0.198 dB  accepts      REJECTED
   b7 & f31==2             0.198 dB  accepts      REJECTED
   f31==1  (NO bit 7)     52.381 dB  REJECTED     runs
   f31==2  (NO bit 7)      0.198 dB  accepts      REJECTED
   NOT b7                 52.381 dB  REJECTED     REJECTED
```

**Two of nine survive, and both read bit 7 *and* `hi12[3:1]`.** Each witness
kills conditions the other accepts — the biquad kills the two bit-7-free ones,
the LFO kills the four that are wrong about `hi12[3:1]` — so neither is doing the
work alone. This is the first positive statement anyone has made about what
`hi12` bit 7 is *for*, and §5 prices the remaining choice between the two
survivors at one corpus word.

The two words of class `(1,0)`, in full:

```
   algo 16  ROOM REVERB 1  w107  090.A.00.1D5   cell -179
   algo 16  ROOM REVERB 1  w120  090.2.FB.40E   cell -248
```

Both at `hi12[3:1] == 0`, so by §1.1 only their *store* is a question.

---

## 3. Class `(0,1)` — the biquad, against its own designer

`PARAMETRIC EQ`'s nine-word section is scored against the transfer function the
firmware's bilinear designer computes, on **11 real coefficient banks** read out
of the ROM, at 12 frequencies. This is an independent criterion, not a
conservatism test, and it is shown able to say NO:

```
   the shipped model                          :    0.198 dB   accepts
   store and clear AFTER the ALU              :   84.768 dB   REJECTED
   store early, CLEAR LATE                    :   51.090 dB   REJECTED
   the store SUPPRESSED                       :   51.090 dB   REJECTED
   the store goes ELSEWHERE                   :   51.090 dB   REJECTED
   bit 4 READS mem[ptr] into the accumulator  :   51.090 dB   REJECTED
   the store writes the BUS                   :    0.198 dB   accepts   <- BLIND
```

Enumerating class `(0,1)`'s effect over all 33, jointly with `op2` and `wrap`:

```
   12 of 396 triples reproduce the designer to < 0.5 dB
   class (0,1) effect : 3 values, all of them `store -> ptr, clear BEFORE'
        ST(acc->ptr)@before/clr:before
        ST(bus->ptr)@before/clr:before
        ST(bus->ptr)@after/clr:before
   op2   FORCED  hold
   wrap  4 values (the biquad cannot see it)
```

**FORCED: a class-`(0,1)` bit-4 word writes `mem[ptr]` and clears the
accumulator BEFORE its own ALU step.** The store's *source* is **not** decidable
here and the last control row says why: at PARAMETRIC EQ's store words `SRC` is
`0x10` (the accumulator) or `0x00`, so the bus **is** the accumulator and the two
readings are bit-identical. That blindness is measured, not assumed.

---

## 4. Classes `(1,1)` and `(1,2)` — the LFO ramp, exhaustively

The 29 LFO blocks are the only witness for the bit-7 classes. Their store words
are all `(1,1)` or `(1,2)`, so classes `(0,*)` are invisible here and are held at
the shipped effect while the two visible ones are enumerated over all 33 × 33.

```
   non-gate settings enumerated : 18 144    (order x act00 x op2 x src08 x wrap
                                             x src11 x dest07)
   TOTAL candidate machines     : 19 758 816
   stage 0 (1 block, 2 frames)   : 29 816 survive   [694 s]
   stage 1 (2 blocks, 10 frames) : 29 784
   stage 2 (all 29 blocks, 30 f) : 23 904
   stage 3 (the 2**23 wrap)      : 17 928
```

```
   eff(1,2)  FORCED to ONE memory behaviour:
        ST(acc->ptr)@before/clr:never  x5976
        ST(acc->ptr)@before/clr:before x5976
        ST(acc->ptr)@before/clr:after  x5976
        -- store the ACCUMULATOR to mem[ptr], BEFORE the ALU.  Only the clear
           is free, and by §1.1 it is nearly free by construction.

   eff(1,1)  21 of 33 effects survive, and they partition into exactly three
             families -- NONE of which writes mem[ptr]:
        -/clr:{never,before,after}                     no memory access
        ST(acc->else) and ST(bus->else), @{before,after}, clr:{never,before,after}
        LD@{before,after}/clr:{never,before,after}     ★ the memory access is a
                                                          READ into the accumulator
   ★ ST(...->ptr) at class (1,1) : 0 of 17 928
```

**So the published "the store is suppressed" is a special case of what is
actually forced: the class-`(1,1)` word's memory access does not deliver the
accumulator to `mem[ptr]`.** `lfo-ramp.md` item K already hedged
"suppressed-**or-redirected**"; the hedge is now measured and has a third arm
that nobody wrote down — `bit 7 = READ`.

### 4.1 The controls, and the ones that say NO

```
   SHIPPED  (1,1) -> no store, no clear                  act00=load  : runs
   the gate never fires (always store)                   act00=load  : REJECTED
   gated at bit 7 ALONE, so (1,2) stops publishing       act00=load  : REJECTED
   gated at b7 & f31==0 (leaves (1,1) storing)           act00=load  : REJECTED
   (1,1) suppressed, act00 = add, NO late clear          act00=add   : REJECTED
   (1,1) suppressed, act00 = add, CLEAR LATE             act00=add   : runs
   ★ (1,1) READS mem[ptr] into the accumulator           act00=load  : runs
   ★ ... the same, with act00 = add                      act00=add   : REJECTED
   ★ (1,1) stores the accumulator ELSEWHERE              act00=load  : runs
   ★ (1,1) stores the BUS to mem[ptr]                    act00=load  : REJECTED
   is_ramp(correct inc = 114) : True   is_ramp(wrong inc = 115) : False
```

The last two of the starred rows are the point: the LFO **can** reject a
mechanism (`store the BUS to mem[ptr]` dies; `bit 7 = READ` under `act00 = add`
dies) and it **does not** reject the two new ones under `act00 = load`. This is
a real widening, not a criterion that accepts everything.

### 4.2 The coupling, re-derived in a 60× larger space

```
   act00=add    eff(1,1) = 7 effects, EVERY ONE with clr:after      x648 each
   act00=rload  eff(1,1) = 7 effects, EVERY ONE with clr:after      x432 each
   act00=bsel   eff(1,1) = 6 effects, EVERY ONE with clr:before     x216 each
   act00=load   eff(1,1) = 21 effects, clr in {never, before, after} x432 each
```

`action00-discriminator.md` item C found this in a space of 18 gate points. It
survives verbatim in a space of 1 089: **`add` and `rload` require a LATE clear;
`load` requires nothing.** Its cause is now visible — §1.1's quotient: `load`
erases the accumulator at the gated word itself, so the gate's timing stops
mattering.

---

## 5. The condition half — `b7 & f31 == 1` vs `b7 & f31 != 2`

```
   words where the two conditions disagree
   (bit 4 set, bit 7 set, hi12[3:1] not in {1,2})       : 11
      by hi12[3:1] : 0:2   5:9
      ★ published count: 13.  MEASURED: 11.

   how many of them can EXECUTE at all?  Two reasons to trap, both INDEPENDENT
   of bit 7 and of the gate:
      hi12[3:1] > 2, the accumulator operation is undecoded : 9
         algo 36 COMPRESSOR x2   algo 75 PEQ COMPRESSOR x2
         algo 96 PEQ COMPR DIST x2   algo 97 PEQ COMPR OVERDR x2
         algo 0  NO OPERATION x1
      the lo12 ACTION is not one of the seven anchored codes : 1
         algo 16 ROOM REVERB 1 w120  090.2.FB.40E   ACTION 0x0E
      ★ WORDS WHOSE BEHAVIOUR THE CONDITION CHANGES        : 1
         algo 16 ROOM REVERB 1 w107  090.A.00.1D5
```

`acc-adder.md` §8's *"they differ on 13 corpus words, nine of them the
COMPRESSOR's envelope step at `hi12[3:1] == 5`"* is **FALSIFIED twice**: the
count is 11, and **the nine COMPRESSOR words are words the decoder already
refuses because `hi12[3:1] = 5` is an undecoded accumulator operation.** A gate
cannot disagree about a word it never reaches. Pricing a question at words that
cannot execute is the same defect as a control that cannot fail.

And the one survivor is a **dead store** (§6): `w107` writes cell −179 and `w108`
overwrites cell −179, with no read in between.

---

## 6. The structural criterion, and its base rate

A store whose cell is overwritten before anything reads it computes nothing. That
is a property of the program text, independent of the ALU model — so it can
disagree with the ramp and the biquad, which is what makes it worth running.

```
   ★ CONTROL, and it says NO.  Without the correction the ramp INDEPENDENTLY
   forces -- that the `xxx.2.dd.447' SRC-0x11 word is inert on the phase cell --
   the census reads class (1,2) as 29 of 29 DEAD, which is FALSE: those are the
   LFO's own publishing stores.  With the correction it reads 13 of 29.

   dead-store rate by class (src11_inert = True), 38 distinct images
      b7=0 f31=0 :  12 stores,   6 dead ( 50.0 %),   2 opaque
      b7=0 f31=1 : 486 stores, 139 dead ( 28.6 %),  97 opaque
      b7=1 f31=0 :   2 stores,   1 dead ( 50.0 %),   1 opaque
      b7=1 f31=1 : 130 stores,  13 dead ( 10.0 %),  35 opaque
      b7=1 f31=2 :  29 stores,  13 dead ( 44.8 %),  11 opaque
      TOTAL      : 680 stores, 172 dead ( 25.3 %)

   residual PROVABLY-DEAD stores, by gate condition
      always (shipped)      172 dead of 525 surviving stores (32.8 %)
      b7 only               145 of 411 (35.3 %)   -27
      b7 & f31==1           159 of 430 (37.0 %)   -13
      b7 & f31!=2           158 of 429 (36.8 %)   -14
      b7 & f31==0           171 of 524 (32.6 %)    -1
      b7 & f31==2           159 of 507 (31.4 %)   -13
      f31==1 (no bit 7)      20 of  41 (48.8 %)  -152   <- biquad kills it
      NOT b7                 27 of 114 (23.7 %)  -145   <- biquad kills it
```

### 6.1 A new discriminator for class `(1,1)`, tried and empty

The LFO leaves class `(1,1)` at three families and only one of them — `LOAD` —
*reads* `mem[ptr]`. Under it an earlier store to the same cell is **live** where
the other two leave it dead. That is a structural test, independent of every
numeric criterion, and it can fire:

```
   class (1,1) = no memory access : dead 128  live 302  opaque 120
   class (1,1) = LOAD (reads it)  : dead 128  live 302  opaque 120

   class-(1,1) words preceded on the same cell by a write with no read
   between -- sites where the test CAN fire                      : 35
   ... of which the earlier store is DEAD under `none'           :  0
```

**It fires at 35 sites and finds nothing**: at every one of them the earlier
store is already live. The structural criterion is therefore **measurably** blind
to the `LOAD` reading, not silently blind — and class `(1,1)` keeps all three
families. Recorded as a **MISS**.

### 6.2 The condition, priced against the base rate

Both class-`(1,0)` words are dead if they fire, and the marginal `b7 & f31 != 2`
removes exactly **one** more dead store than `b7 & f31 == 1`. **With a base rate
of 32.8 %, two-of-two dead is p ≈ 0.11 under the null** — evidence, not a
forcing. Stated at that strength: `b7 & f31 != 2` is **CONSISTENT and slightly
preferred**, and by §5 the choice cannot change any executable word's behaviour
except one dead store.

---

## 7. What settling the gate is WORTH

The brief prices the gate at *"130 corpus words and 11 frame slots"*. That is
the size of class `(1,1)`, not the price.

```
   class (1,1) words over the 38 distinct images : 130
      SRC 0x1C is not anchored            46
      SRC 0x00 is not anchored            31
      SRC 0x08 is not anchored            29
      EXECUTABLE once the gate is settled 16
      ACTION 0x1A is not anchored          6
      ACTION 0x0E is not anchored          2

   ★ words the shipped decoder refuses and would accept if the gate were
     settled -- refused by guard 7 and by NOTHING ELSE:
        17 of 2974 words in the 38 distinct body images
           x4 292.A.01.412   x3 192.A.03.1D5   x3 292.A.01.1D5
           x2 092.2.FF.1D5   x2 192.A.F7.1D5   x1 192.A.FB.1D5
           x1 292.A.00.1D3   x1 090.A.00.1D5
        by class : {b7=1,f31=0: 1, b7=1,f31=1: 16}
        9 programs : NO OPERATION 1, ENHANCER 4, FLANGER 2, GATED REVERB 1,
                     ROCK ROTARY 2, ROOM REVERB 1 1, S DELAY FLANGER 2,
                     PEQ FLANGER 2, PEQ COMPR OVERDR 2
```

★ **And none of the 16 carries `ACTION 0x00`**, so guard 7's *"`f31 == 1`
requires `ACTION 0x00`"* clause refuses every one of them today. The 31 + 29 + 46
words behind unanchored SRC codes join only if `SRC 0x00`, `SRC 0x08` and
`SRC 0x1C` are settled first — and §8 says `SRC 0x00` is **not** about to be.

---

## 8. `SRC 0x00` — the second task, answered from the ROM

`blocking-read.md` item G: `SRC 0x00 = mem[ptr]` is forced **only while** SINGLE
DELAY's two input-mix coefficients are `0.0000`; the host can overwrite them at
run time; the named experiment is an emulator capture of the host's C-RAM writes
while algorithm 9 is linked.

**A capture samples. The firmware's own per-algorithm parameter table decides.**

```
   MEASURED -- SINGLE DELAY's C-RAM offsets, from the cursor walk:
      w3  212.A.01.1D5   C-RAM offset 0x00 = +0.000000   INPUT MIX
      w4  202.A.48.1D5   C-RAM offset 0x01 = +0.000000   INPUT MIX
      w6  202.A.B8.655   C-RAM offset 0x02 = +0.500000   the feedback

   MEASURED -- algorithm 9: T1 = 0001811E   T2 = 000180D0
      T1 op 21 -> 90
      T1 op 63 -> 06
      T1 op 67 -> 26 28
      T1 op 73 -> 00 01 09 0A     <- TARGETS AN INPUT-MIX CELL
      T1 op 74 -> 1D 00 00 00     <- (never named by the T2 stream)
      T1 op 76 -> 03 06 0C 0F

   MEASURED -- algorithm 9's T2 parameter bytecode records:
      @0180D0 op67#00 -> addr 26  imm=000002
      @0180D8 op67#01 -> addr 28  imm=003FE0
      @0180E0 op73#00 -> addr 00  imm=C28F5C3D70A3   ★ WRITES AN INPUT-MIX CELL
      @0180EB op73#02 -> addr 09  imm=C28F5C3D70A3
      @0180F6 op76#00..03 -> addr 03 06 0C 0F
      @01810C op63#00 -> addr 06  imm=01
      @018112 op21#00 -> addr 90  imm=000000666666

   C-RAM offsets algorithm 9's parameter stream writes : 00 03 06 09 0C 0F 26 28 90
   of which are SINGLE DELAY input-mix cells            : 00
```

**The cell is a user-parameter target.** The `0.0000` in the image is the
ROM-loaded default, not a property of the running machine — so *"the host
provably never writes a non-zero value there"* cannot be established, and by
item G's own logic **the ambiguity does not close. The 30 PARTIAL + 10 TRAP
slots keep trapping and `SRC 0x00 = mem[ptr]` stays CONSISTENT.** Nothing is
applied.

Three controls, one of which is only partly satisfied and is reported that way:

```
   CONTROL 1 -- a cell that must NOT be a target and one that must:
      cell 02 (the 0.5000 coefficient) is a target : False
      cell 90 (op 0x21) is a target                : True

   CONTROL 2 -- is a 6-byte immediate a (lo, hi) RANGE?  Over EVERY algorithm,
   does the ROM-loaded C-RAM value at the target lie between the halves?
      INSIDE  : 123      OUTSIDE : 22      no ROM value : 42
      e.g. algo 5 op 66#1 -> 06  [+0.3000, +0.4350]  value +0.4380
```

So corpus-wide the range reading is **CONSISTENT (85 %), not proven** — which is
exactly what makes the third control worth running.

### 8.1 ★ The cell has a name, and the name is a front-panel knob

`register-space.md` (sibling pass, the same day) aligns each algorithm's T2
record list against the captured UI parameter list — 49 of 49 algorithms align,
and the alignment is checked by a *unit* control that could scatter. It binds
opcode `0x73` to **`FEEDBACK L` / `FEEDBACK R` / `RESONANCE`, 28 of 28**.
Algorithm 9's seven records, with their names:

```
   op 67#0 -> cell 0x26   DELAY L            (ms)
   op 67#1 -> cell 0x28   DELAY R            (ms)
   op 73#0 -> cell 0x00   FEEDBACK L         <- SINGLE DELAY w3's OWN COEFFICIENT
   op 73#2 -> cell 0x09   FEEDBACK R
   op 76#0 -> cell 0x03   HIGH DAMP GAIN
   op 63#0 -> cell 0x06   VOLUME
   op 21#0 -> cell 0x90   REV SEND
```

★ **The "input-mix coefficient that happens to be `0.0000`" is the SINGLE DELAY
FEEDBACK knob.** `0.0000` is not an accident of the image and not a structural
zero — it is *feedback = 0* as the shipped default of a user control that spans
`(−0.4800, +0.4800)`.

**CONTROL 3, and it could have failed.** If `op 0x73`'s addresses really are
C-RAM *coefficient* cells then the ROM-loaded value at each of the 28 targets
must lie inside that record's own `(lo, hi)` pair — and corpus-wide that test
scores only 85 %, so it is not automatic:

```
   op 0x73 targets INSIDE their own (lo, hi) pair : 28
   ...                            OUTSIDE          :  0
      algo 4  FLANGER          #0 -> 0x00  [-0.4900,+0.4900]  loaded +0.300000
      algo 5  PHASER           #0 -> 0x02  [-0.4900,+0.4900]  loaded +0.300000
      algo 9  SINGLE DELAY     #0 -> 0x00  [-0.4800,+0.4800]  loaded +0.000000
      algo 9  SINGLE DELAY     #2 -> 0x09  [-0.4800,+0.4800]  loaded +0.000000
      algo 10 MULTI TAP DELAY  #0 -> 0x07  [-0.1200,+0.1200]  loaded +0.025000
      algo 64 S.DELAY+CHORUS   #0 -> 0x02  [-0.4500,+0.4500]  loaded +0.300000
```

**8 of the 28 are already non-zero in the ROM image**, so the address space is
not merely plausible — the opcode demonstrably lands real gains in C-RAM
coefficient cells. Caveat still stated: `kn5000-dsp-parameters.md` §6 marks the
opcode→helper binding INFERRED and partially wrong, and `0x73`'s helper is a
*block* writer at `0x039ABD` whose code has not been read; 28/28 with 8 non-zero
is strong corroboration, not a disassembly.

### 8.2 A lead for whoever next touches SINGLE DELAY

`action00-discriminator.md` §0-H calls `w3`/`w4` **the two input-mix
coefficients** and `w6` (cell `0x02`, `0.5000`) **the feedback**. The host calls
cell `0x00` **FEEDBACK L** and cell `0x09` **FEEDBACK R**, and never names cell
`0x02`. Either the motif's roles are mis-assigned, or algorithm 9's 133-word
image holds more than one delay and the first motif instance is not the one the
parameter map addresses. **OPEN.** It does not change §0-J either way: whatever
`w3` is *for*, its coefficient is host-written.

---

## 9. The vacuity sweep — the third task

**THE THEOREM.** Under the adder, at a word with `hi12[3:1] == 0` the
accumulator feedback is cut, so

```
   load  : FB <- bus              -> acc = bus + P
   add   : B  <- +bus             -> acc = P + bus     IDENTICAL
   rload : FB <- -FB = 0, B <-bus -> acc = P + bus     IDENTICAL
   sub   : B  <- -bus             -> acc = P - bus     distinguishable
   none  :                        -> acc = P           distinguishable
```

Verified, and shown able to say *different*:

```
   SINGLE DELAY w7  000.2.48.000 (f31 == 0)  load/add/rload agree 3000 of 3000
   the LFO's        082.2.00.1C0 (f31 == 1)  agree    0 of 3000
   reverb slot 1    104.2.00.000 (f31 == 2)  agree    0 of 3000
```

Every ACTION code, with the `hi12[3:1]` histogram of the words that carry it, is
printed by `gate_settle.py vacuity`. Four codes — `0x01` (37 words), `0x04` (1),
`0x0C` (12), `0x1C` (24) — have **no decidable site anywhere in the corpus**:
their `{load, add, rload}` reading can never be determined by any block.

The published determinations, one by one:

| note | claim | verdict |
|---|---|---|
| `acc-adder.md` §0-C | `ACTION 0x00 = load`, FORCED 18/18 | already retracted. The sweep **agrees and supplies the mechanism without a search**: SINGLE DELAY's only ACTION-`0x00` site is `f31 == 0`, so that context never had a vote |
| `action-field.md` §6/§10 | `ACTION 0x00` *routes the bus into the accumulator, i.e. NOT a no-op*, 5145/5145 | **SURVIVES.** The site is `f31 == 0`, but the claim only separates `none`, and `none` **is** distinguishable there. Stated at exactly the strength the site can bear |
| `acc-adder.md` §0-E | `ACTION 0x19 = tempA ← bus`, 108/108 | **SURVIVES** — capture half, and `f31 == 1` anyway |
| `blocking-read.md` §0-D | `ACTION 0x19`'s accumulator half = *no effect*, 3206/3206 | **SURVIVES** — sites at `f31 == 1` |
| `blocking-read.md` §0-I | `ACTION 0x00`'s capture half = `tA ← acc` | **SURVIVES** the theorem (capture half); the note's own caveats stand |
| `schroeder-topology.md` §0-B | `ACTION 0x00 = load` FORCED given the clear | **SURVIVES.** Motif slots 1 and 3 are `f31 = 2` and `1`; slots 6/7 are `f31 = 0` and contribute nothing. The note applied the correction itself (its item H) |
| `allpass-adder-rerun.md` §0-C | every all-pass-admissible setting KEEPS the accumulator; `load` = 0 | **SURVIVES**, same two decidable slots |

**152 of the field's 806 ACTION-`0x00` words (18.9 %) are structurally incapable
of deciding their own accumulator half. No published headline falls that had not
already fallen.** Recorded as a **MISS** — the sweep was commissioned on the
expectation that it would catch one, and it caught none. Its value is the
negative: the notes were already clean on this axis, and the four
never-decidable ACTION codes are new.

---

## 10. PREDICT-THEN-CHECK

| | prediction, recorded before the measurement | result |
|---|---|---|
| **P-1** | the biquad will force class `(0,1)` to store, so bit 7 must be in the gate condition | **HIT.** Suppressing `(0,1)` is 51.090 dB wrong; `f31 == 1 (no bit 7)` and `NOT b7` both die |
| **P-2** | the LFO will force class `(1,1)` to "no store" | ★ **MISS, and the most useful one.** It forces only that `mem[ptr]` is not written: `store → elsewhere` and `READ into the accumulator` both run, 0 of 17 928 survivors write `mem[ptr]` |
| **P-3** | `bit 7 = a DIRECTION bit on the memory port` will run the LFO and will therefore have to be carried | **HIT** under `act00 = load`, **and it dies under `act00 = add`** — which I did not predict and which sharpens the coupling |
| **P-4** | the `f31==1`-vs-`f31!=2` condition question will be decidable only structurally | **HIT**, and much more strongly than expected: it is worth **one** word, and that word's store is dead |
| **P-5** | the published "13 corpus words" disagreement count will be right | **MISS.** It is 11, and 10 of the 11 trap for gate-independent reasons |
| **P-6** | the vacuity sweep will catch at least one published headline | **MISS.** None. The notes were already clean; `schroeder-topology.md` item H had the theorem |
| **P-7** | this tool will reproduce `action00-discriminator.md`'s LFO count on the first attempt | ★ **MISS, and the mirror check is why it exists.** My first mapping treated `(condition, effect, sttime)` as an independent product; in the published tool `sttime` also moves a *gated* word's clear. Corrected, and the correction exposed the degeneracy in §0-H |
| **P-8** | the class-`(1,0)` words will turn out to be dead stores | **HIT**, 2 of 2 — but the base rate is 32.8 %, so it is reported as `p ≈ 0.11` evidence, not a forcing |
| **P-9** | the emulator capture will be needed to settle `SRC 0x00` | **MISS.** The firmware's own parameter table answers it exhaustively and in the direction that keeps the ambiguity **open**; no capture was run |
| **P-12** | *(recorded after reading the sibling pass)* the cell will turn out to be an obscure internal coefficient with no user name | ★ **MISS, and the best miss of the pass.** It is `FEEDBACK L` — a named front-panel knob spanning ±0.48, with 8 of the 28 `op 0x73` targets already non-zero in the ROM image |
| **P-13** | the dead-store census will separate `LOAD` from `none` at class `(1,1)`, because only `LOAD` reads the cell | **MISS.** The test can fire at 35 sites and changes **0** verdicts: at every one the earlier store is already live. Reported because the blindness is now *measured* rather than assumed |
| **P-10** | the gate is worth ~130 words | **MISS by 8×.** 17, in 9 programs, and none of the 16 class-`(1,1)` ones carries `ACTION 0x00` |
| **P-11** | no frame completes and no audio moves | **HIT, by construction** — nothing that runs in the emulator was edited |

---

## 11. Housekeeping

* `dsp/verify.py` → **BYTE-MATCH OK**.
* No file under `src/devices/cpu/upd6383/` was touched; both disassembler
  mirrors are unchanged and therefore still agree word-for-word over the 3057-word
  corpus.
* No `.dsm` regenerated. No word gains or loses an executable semantic: every
  word that trapped before this pass still traps, including all 17 of §7.
* The DSPCFG-off audio is bit-identical **by construction** — no code that runs
  in the emulator was modified.
* Method rule 6 observed: **nothing in §0 that is not FORCED is applied**, and
  the two FORCED results that could be applied — class `(0,1)` stores to
  `mem[ptr]` with an early clear, class `(1,2)` stores the accumulator to
  `mem[ptr]` before the ALU — are what the device already does, so applying them
  is a no-op.

---

## 12. What this leaves for the other targets

* ★ **The gate's remaining question is one class and one word each.** Class
  `(1,1)`: *which of `{none, store→elsewhere, load}`*, 21 effects, 16 executable
  words, and no second witness in the corpus. Class `(1,0)`: *does the store
  happen*, one word, dead either way. Class `(0,0)`: 12 words, no witness.
  **Everything else about the gate is settled.**
* ★ **`store → elsewhere` and `load` are testable, and not by the LFO — nor by
  the dead-store census, which §6.1 shows *measurably* blind (35 sites, 0
  verdicts changed).** Both predict a *value* the current model discards. The
  material exists — the census classifies 82 of the 130 class-`(1,1)` stores as
  live and 35 as opaque — but what is missing is a block whose arithmetic is
  known independently, and §2 says the corpus has none.
* **For `ACTION 0x00`.** It is still coupled, and §1.1 quantifies the coupling:
  choosing `load` makes 18 of 33 gate effects unobservable. Any future solve must
  enumerate `act00` and the class-`(1,1)` effect **jointly** — 21 × 4, not 3 × 6.
* **For the reverb.** `090.A.00.1D5` (`w107`) is the single word the condition
  half touches, it is in the reverb body, and its store is dead. A Schroeder
  solve does not need it.
* **For `SRC 0x00`.** §8 closes the *experiment* and not the question: the
  emulator capture named in `blocking-read.md` item G is superseded and should
  not be run. `SRC 0x00 ∈ {mem[ptr], acc}` stands, `= mem[ptr]` is CONSISTENT,
  and the 40 slots keep trapping.
* **For anyone pricing an open question.** §5 and §7 are the same lesson twice:
  a word that traps for an independent reason is not in the disagreement set, and
  a class size is not a price. Both published prices for this question were
  overstated — one by 13 → 1, one by 130 → 17.
