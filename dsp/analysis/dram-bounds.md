# ADDRESSES versus BOUNDS — the descriptor bank splits two ways, and the fake lines are the two bounds paired with each other

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis of the Sub CPU ROM, the 100 canned parameter
streams and the 38 body images only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Target 1 of round 6 — *the bounds question*. Builds directly on
[`adjudication-round5.md`](adjudication-round5.md) items **B** (the cell↔word map
is the identity at δ = 0) and **D** (`addr8` bit 6 is the delay-DRAM direction,
`0x60` = WRITE), on [`dram-matching.md`](dram-matching.md) (opcode `0x67`'s
evaluator and its 24-bit `BASE24` line base) and on
[`host-side.md`](host-side.md) (the opcode → address-space map, and the warning
that host-priming is not a dichotomy).

Tool: [`../tools/bounds.py`](../tools/bounds.py) — stdlib plus the repo's own ROM
parsers. **Every number below comes out of it.**

```
python3 dsp/tools/bounds.py census      #  1     populations, region test, direction census
python3 dsp/tools/bounds.py roles       #  2 ★★★ CEILING / LIMIT / FLOOR, enumerated
python3 dsp/tools/bounds.py classify    #  3 ★★★ the per-cell classification (deliverable a)
python3 dsp/tools/bounds.py lines       #  4 ★★★ the corrected line set     (deliverable b)
python3 dsp/tools/bounds.py host        #  5 ★★★ THE LEVER — what the firmware names
python3 dsp/tools/bounds.py invariants  #  6     idx 1 / idx 3 / idx 5 / idx 30
python3 dsp/tools/bounds.py rivals      #  7 ★★★ RULE 7, scored only on disagreement
python3 dsp/tools/bounds.py control     #  8 ★★★ every control, shown saying NO
python3 dsp/tools/bounds.py predict     #  9     PREDICT-THEN-CHECK, hits AND misses
python3 dsp/tools/bounds.py export      # 10     dsp/analysis/descriptor-cell-classes.json
python3 dsp/tools/bounds.py all         # ~40 s

python3 dsp/verify.py                   # BYTE-MATCH OK
```

**Nothing was applied.** No MAME source touched, neither disassembler mirror
edited, `dsp/verify.py` reports **BYTE-MATCH OK**, and **zero dark slots are
recovered** — the 42 delay-DRAM words still trap. This pass classifies *data*,
not instructions; under method rule 6 that is not a licence to decode anything.

---

## 0. Result in one page

**POPULATION for everything below (method rule 9): 91 algorithms ship descriptor
cells; 870 cells in total; 83 algorithms have `#cells == #consumers` and carry
829 cells — that 829 is the denominator of every classification here, and it is
the same population `adjudication-round5.md` §7 censused (READ 416 / WRITE 365 /
48 C-format, reproduced exactly). The 8 unaligned algorithms {4, 6, 36, 66, 73,
75, 96, 97} are deliberately NOT classified.**

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE BANK SPLITS TWO WAYS AND THE SPLIT IS TWO CELLS WIDE. Every algorithm carries exactly ONE `CEILING` and exactly one of {`LIMIT`, `FLOOR`}; everything else is a delay-line endpoint or still traps.** Residue over the 83 aligned algorithms: `{CEILING 1, LIMIT 1}` ×61, `{CEILING 1, LIMIT 1, TRAP 4}` ×12 (the reverbs' four C-format cells), `{CEILING 1, FLOOR 1}` ×8, plus ENHANCER and RING MODULATOR which carry one DISPUTED cell each. **166 BOUND / 613 ADDRESS / 50 UNKNOWN of 829.** | **MEASURED**; the classification **FORCED** per row below |
| **B** | ★★★ **THE `CEILING` IS A SINGLE CONSTANT PER UNIT AND IT IS OUTSIDE THAT UNIT'S OWN DRAM REGION.** `32768` in **71 of 71** unit-0 algorithms, `32767` in **12 of 12** unit-1 algorithms; **83 ceiling cells, one per algorithm, never two and never zero**. Position: relative index **n−2** in 75 algorithms, **n−1** in the 8 with `n = 2`. Unit 0 owns `[0, 32767]` and unit 1 owns `[32768, 65535]`, so each constant is the partition boundary named from its own side, and **an address outside a unit's region is not an address of that unit's delay line**. | **FORCED** (§1, §2) |
| **C** | ★★★ **THE `LIMIT` IS AN IN-REGION WRITE THAT NO READ CAN REACH — and it is cell index 1.** **62 of the 63** in-region cases sit at **relative index 1** (the one exception is ENHANCER's, at rel 3, where the value is `30875 = max read + 1`), and by construction all **63** have an address **above every READ address of their own algorithm**, so the buffer each would open can never be read. The eleven reverbs' rel-1 = `0` is the same conclusion by the other route — below unit 1's floor. Total `LIMIT` cells **74**. | **FORCED within the allocation model** (enumeration printed, §2); **CONSISTENT** outside it |
| **D** | ★★★ **BOTH FAKE LINES THE BRIEF NAMES ARE EXACTLY `CEILING − LIMIT`.** SINGLE DELAY's bogus 897 = `32768 − 31871`; PLATE REVERB's 32767 = `32767 − 0`. They are the two BOUND cells paired **with each other**, and in **50 of 83** algorithms those two cells sit exactly **+3** apart — precisely the offset the anchored `+3` rule pairs, which is why the artefact was systematic rather than sporadic. | **MEASURED** (§4) |
| **E** | ★★★ **THE CORRECTED LINE SET: 324 delay lines over 83 algorithms, and PARTIAL BUFFER OVERLAPS GO 21 → 0.** Under the old reading (every cell an address, rigid +3, direction ignored) **21 of 83** algorithms allocate two buffers that partially overlap. Under the classification, **0 of 83**. The 19 that still show *any* interval intersection are **nesting only** — MULTI TAP DELAY's four taps on one base, and the reverbs' early reflections inside the pre-delay buffer — which is what a tap *is*. | **MEASURED** (§4) |
| **F** | ★★★ **AND THE `+3` RULE FALLS OUT AS AN OUTPUT.** The model never mentions a cell offset; it matches on values. The offsets it produced: **+3 ×273**, +8 ×12, +9 ×12, +11 ×12, +4 ×7, +2 ×7, +6 ×1, of **324**. `dram-matching.md` C measured "+3 in 30 of 38" and had to name seven exceptions; here the exceptions are not exceptions, they are multi-tap reads and wrapped closures the allocation model resolves. **ROOM REVERB 1's eleven ladder segments, its 800-sample pre-delay and its early reflections are all re-derived without a `+3` assumption and without a wrap special case.** | **MEASURED** (§4) |
| **G** | ★★ **THE LEVER PAYS, BUT ONLY ONE HALF OF IT.** The **UI NAME** separates: **0 of 36** host-named `op-0x67` taps lands on a bound cell (permutation-free null `p = 2.8 × 10⁻⁴`), and all 36 classify ADDRESS. The **T1 ALLOCATION does not**: **12 of 109** reservations point straight at a forced bound. The brief's hoped-for "even cleaner separator" (*bounds are written by a different opcode, or by none*) **does not exist**. And naming is one-sided anyway — only 36 of 829 cells carry a name, so it can convict a bound and cannot acquit the other 793. | **MEASURED**; the brief's premise **FALSIFIED** (§5) |
| **H** | ★★★ **`dram-matching.md` B2's READING OF idx 5 = 41590 AS AN ALLOCATION CEILING IS REFUTED — IT IS A LINE BASE.** Three legs: (1) its consumer word is `880.1.60.2D4` in 12 of 12 reverbs, and that *byte-identical* word also consumes cells `0x03 0x07 0x09 0x0B 0x0F 0x11 0x13 0x15` of ROOM REVERB 1 — of which `0x03` is the **host-anchored** PRE DELAY line base (`BASE24 − 2`, 12/12) and the rest are ladder bases; (2) it is a WRITE under the FORCED direction rule and read cell `0x02 = 41673` takes it as its base, `41673 − 41590 = 83` = ladder segment 1; (3) delete it and read cell `0x02` is orphaned. **The dichotomy in the question was false**: this allocator abuts its buffers (`dram-matching` B, 171 abutting joins), and a boundary between abutting buffers is one buffer's ceiling *and* the next one's base. | **MEASURED**; B2's *reading* **FALSIFIED** (§6) |
| **I** | ★★ **AND A RULE-8 CATCH ON THE `200.00 ms EXACTLY` THAT CAME WITH IT.** `41590 − BASE24(32770) = 8820 = 200.0000 ms`, but `41590 − cell 0x03 (32768) = 8822 = 200.0454 ms`. The roundness exists **only** against `BASE24`, i.e. only if you already accept the `+2` address-generator offset that `dram-matching.md` §1 itself labels **INFERRED** and says is not statically separable. So the exactness is **CONSISTENT, not MEASURED**, and it is not evidence about idx 5's role either way — an abutting allocator produces it under both readings. | **the constant re-derived; its evidential weight RETRACTED** |
| **J** | ★★ **CELL INDEX 1 IS DECIDED AS `not an address`, AND ITS SEMANTICS ARE NOT.** The brief's "ring limit is the obvious reading and the eleven zeros refuse it" dissolves: the eleven zeros and ROOM REVERB 1's `45464` fail to be addresses **in two different ways** (below the floor / above every read) and the classification only needs *not an address*. But a ring-**top** register predicts `max + 1` everywhere, and that holds in **3 of 74** LIMIT cells. **The ring-top reading is NOT supported; what the data carries is the weaker `an address no read can reach'.** | **FORCED** (not an address); the ring reading **FALSIFIED**; semantics **OPEN** (§6) |
| **K** | ★★ **A THIRD CANNED CONSTANT NOBODY HAD NOTICED: `128`.** It appears in **10** algorithms; in **8** of them (`n = 2`: PHASER, DISTORTION, OVERDRIVE, FUZZ, EXCITER, PARAMETRIC EQ, AUTO PAN, AUTO WAH) the entire descriptor block is `[128, 32768]` and contains **no WRITE-direction cell at all**, so nothing can be read there. In the two where a `128` cell *does* get matched (ENHANCER rel 1, RING MODULATOR rel 0) this pass calls the cell **DISPUTED** and hands the solver nothing. | **MEASURED**; those 2 cells **OPEN** (§2) |
| **L** | ★ **RULE 7, AND THE ANSWER IS UNCOMFORTABLE: MY TEST DOES NOT SEPARATE MY RULE FROM THE INSTRUCTION-BLIND POSITIONAL RIVAL.** `R1 = "bounds are rel 1 and rel n−2"` — which never looks at the instruction and never looks at the value — agrees with this pass on **777 of 829** cells and scores **163/163** on the ground-truth set, identically. The 52 disagreements carry **no** ground truth. What the test *does* separate, and does decisively: `R3` all-ADDRESS (the incumbent that made the fake lines) **94–0**, `R4` "the value 32768 is a bound" **23–0**, `R5` "the largest value is a bound" **23–0**. | **MEASURED**, reported as a non-separation (§7) |
| **M** | ★★ **AND A BONUS FOR THE NEXT PHASE: THE REVERBS' DEAD T1 RESERVATION IS OFF BY EXACTLY ONE, WHICH NAMES THE 48 STILL-TRAPPING CELLS.** `T1[0x67]` of all twelve reverbs is `[0x00, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E]`; the six cells that actually behave as early-reflection taps off the pre-delay base are the contiguous block `0x18..0x1D`. Same length, shifted by one — which is why the last entry lands on cell `0x1E = 32767`, a forced bound. So the host itself says `0x19 / 0x1A / 0x1C / 0x1D` are delay **taps**, i.e. their C-format words are **READS** — a CONSISTENT direction for **48 of the 48** still-trapping cells. **NOT APPLIED** (method rule 6). | **MEASURED** (the two blocks); the off-by-one **INFERRED**; the direction **CONSISTENT**, **OPEN** (§5) |

---

## 1. The region test, and the control that gives it its force

```
python3 dsp/tools/bounds.py census
```

The whole classification rests on one FORCED negative: **a cell whose value lies
outside its own unit's DRAM region cannot be an endpoint of a line in that
unit.** Unit 0 owns `[0, 32767]`, unit 1 owns `[32768, 65535]`
(`adjudication-round4.md` §2).

A region test is worthless unless the things already known to be addresses obey
it. They are the `op-0x67` taps and their `BASE24` line bases — addresses **by
construction**, because the evaluator is `cell = round(ms × 44100/1000) +
BASE24`:

```
   host-named endpoints inside their unit's region:  72 of 72
```

Not one host-anchored address violates the partition. Only then is the negative
worth anything:

```
   OUT-OF-REGION CELLS, the whole set, by (unit, value)
      unit 0  value 32768   x71
      unit 1  value     0   x11
      unit 1  value 32767   x12
      total 94 of 829 aligned cells = 11.3 %
```

**THREE distinct values in the entire corpus.** That is the first sign the bank
is structured rather than arbitrary.

---

## 2. The three roles — `bounds.py roles`

### 2.1 `CEILING` — one per algorithm, one constant per unit

```
   cells per algorithm holding 32767/32768 out of region : {1: 83}
      unit 0 -> 32768   x71
      unit 1 -> 32767   x12
   position : rel n-2  x75      rel n-1  x8   (the eight n=2 algorithms)
```

`32768` = unit 0's top + 1 = unit 1's floor. `32767` = unit 1's floor − 1 = unit
0's top. **The same partition boundary, named from the two sides.** Every aligned
algorithm has exactly one, never two, never zero.

### 2.2 `LIMIT` — an in-region write no read can reach

```
   position of every in-region WRITE above every READ : rel 1 x62,  rel 3 x1
   total 63 ; equal to (max read + 1) : 3
   algorithms with no such write : 20  (the 12 reverbs, whose rel-1 = 0 is caught
                                        by the region test; and the 8 n=2
                                        algorithms, which hold no WRITE at all)
```

**THE ENUMERATION, printed beside the claim (method rule 3).** What else could an
in-region WRITE cell that no READ can reach be?

| option | verdict |
|---|---|
| (i) a line base whose read tap lives in **another algorithm** | **REFUTED** — the descriptor block is per-algorithm and the cursor is reloaded per body (round 5 H) |
| (ii) a line base whose read tap is one of the **C-format cells whose direction still traps** | **ADMITTED** as residual risk, and **PRICED**: only the 12 reverbs have such cells, and their rel-1 is out of region anyway, so it changes no classification |
| (iii) a base for a read produced **at run time by a knob** | **REFUTED** — opcode `0x67` is the only parameter opcode that reaches the descriptor space (`host-side.md` A1) and it never targets rel 1 (§5) |
| (iv) **not a line base at all — a bound** | **ADMITTED** |

### 2.3 `FLOOR` — the mirror image, and the third canned constant

A READ with no WRITE anywhere below it in the block cannot be the read end of any
line *this algorithm* writes. There are 9:

```
   value   128  x8      value  0  x1  (ENHANCER rel 0)
```

`128` occurs 10 times in 10 algorithms. In **8** of them the whole descriptor
block is `[128, 32768]` and holds no WRITE at all. It is a **third canned
constant** beside `32768` and `32767`. In the two algorithms where a `128` cell
*does* get matched — ENHANCER rel 1, RING MODULATOR rel 0 — this pass marks the
cell **DISPUTED** and refuses to hand it to the solver either way.

### 2.4 The residue, which is the whole result in one table

```
   {'CEILING': 1, 'LIMIT': 1}                             x61
   {'CEILING': 1, 'LIMIT': 1, 'TRAP': 4}                  x12   <- the reverbs
   {'CEILING': 1, 'FLOOR': 1}                             x8    <- the n=2 blocks
   {'CEILING': 1, 'DISPUTED': 1, 'FLOOR': 1, 'LIMIT': 1}  x1    <- ENHANCER
   {'CEILING': 1, 'DISPUTED': 1}                          x1    <- RING MODULATOR
```

Nothing else is left over and nothing is missing.

---

## 3. The classification, and what may be used as a constraint

```
python3 dsp/tools/bounds.py classify      # human-readable, per cell
python3 dsp/tools/bounds.py export        # dsp/analysis/descriptor-cell-classes.json
```

```
   over 829 aligned cells in 83 algorithms:
      ADDRESS 613   BOUND 166   UNKNOWN 50
   label census:
      FORCED           149   36 host-named taps + 83 ceilings + 30 BASE24 bases
      FORCED-IN-MODEL   83   74 LIMIT + 9 FLOOR
      CONSISTENT       547   matched by the allocation model alone
      OPEN              50   48 still-trapping C-format + 2 DISPUTED
```

**Deliverable (c), stated so the solver cannot be handed a guess:**

* **FORCED** — safe as a hard constraint.
* **FORCED-IN-MODEL** — forced *given* the allocation model A4; the model is
  named in the JSON and in §2's enumeration. Safe as a hard constraint only if
  A4 is accepted; otherwise treat as strong prior.
* **CONSISTENT** — the cell is an endpoint under A4, but nothing outside A4
  anchors it. **Do not use as a hard constraint.**
* **OPEN** — the 48 C-format cells whose direction still traps, and the 2
  DISPUTED `128` cells. **Do not constrain at all.**

The JSON carries, per algorithm: `unit`, `n`, and per cell `rel / cell / value /
word / dir / class / role / why / label / host_named / base24`, plus the corrected
`lines` with `read_cell, write_cell, read_addr, write_addr, samples, ms`. The 8
unaligned algorithms are listed under `not_classified` with the reason.

---

## 4. The corrected line set — `bounds.py lines`

**324 delay lines over 83 aligned algorithms.**

### 4.1 The fake lines, named and explained

```
   algo  9 SINGLE DELAY     CEILING(rel  4) 32768 - LIMIT(rel 1) 31871 =   897
   algo 17..27 the reverbs  CEILING(rel 30) 32767 - LIMIT(rel 1)     0 = 32767
```

Both artefacts the brief names are **the two bound cells paired with each
other**. No search was needed to remove them. And the reason SINGLE DELAY's was
the conspicuous one: **in 50 of 83 algorithms the LIMIT and the CEILING sit
exactly `+3` apart**, which is exactly the offset the anchored `+3` rule pairs,
so the old model manufactured a bound-to-bound line in every one of them.

### 4.2 `+3` comes back out as an output

```
   offset (write_rel - read_rel) mod n over the 324 lines:
      +3  x273     +8 x12     +9 x12     +11 x12     +4 x7     +2 x7     +6 x1
```

### 4.3 Overlap, before and after

```
   OLD (every cell an address, rigid +3, direction ignored)
        21 of 83 algorithms have a PROPER (partial) buffer overlap;  23 have any
   NEW (bounds removed, direction honoured, allocation model)
         0 of 83 algorithms have a PROPER overlap;                   19 have any
```

A memory allocator does not hand out two buffers that *partially* overlap; it
routinely hands out a buffer **inside** another, which is what a multi-tap and an
early-reflection tap are. Proper overlap is the defect; nesting is not.

### 4.4 ROOM REVERB 1, re-derived (method rule 8 — do not quote, re-derive)

```
   read 0x00 33568  <- base 0x03 32768    800 samples   18.14 ms   PRE DELAY
   read 0x02 41673  <- base 0x05 41590     83
   read 0x04 41845  <- base 0x07 41673    172
   read 0x06 42201  <- base 0x09 41845    356
   read 0x08 42714  <- base 0x0B 42201    513
   read 0x0A 43453  <- base 0x0D 42714    739
   read 0x0C 43693  <- base 0x0F 43453    240
   read 0x0E 43812  <- base 0x11 43693    119
   read 0x10 44059  <- base 0x13 43812    247
   read 0x12 44487  <- base 0x15 44059    428
   read 0x14 45103  <- base 0x17 44487    616
   read 0x16 45463  <- base 0x1F 45103    360       <- the +9 closure, found by itself
   read 0x18 33418  <- base 0x03 32768    650       <- early reflection
   read 0x1B 33308  <- base 0x03 32768    540       <- early reflection
   14 lines, 5863 samples
```

This is `adjudication-round5.md` H's ladder — `800` + `83 172 356 513 739 240 119
247 428 616 360` — **reproduced without the `+3` rule and without a wrap special
case**, and the two early reflections round 5 reported (540, 650) fall out of the
same pass. Cells `0x01` and `0x1E` are bounds and take no part.

---

## 5. ★ THE LEVER: what the firmware names, and what it merely reserves

```
python3 dsp/tools/bounds.py host
```

Two host-side facts, and **they do not give the same answer.**

**(A) The UI NAME** — a T2 record, a knob a player can actually turn.
Population **36** (algorithm, `op-0x67` record) sites over 22 algorithms, of the
38 in the whole ROM — the other 2 are both in algorithm 66 S.DELAY+FLANGER,
which is unaligned (`#cells 11 != #consumers`) and out of scope here.

```
   classification of the named cells : {'ADDRESS': 36}
   named cells this pass calls a BOUND : 0
   relative index of every named tap : {0:22, 2:6, 3:3, 4:2, 5:1, 6:1, 7:1}
   named taps on rel 1 or on the ceiling slot : 0
   null: place each named tap uniformly among its own algorithm's n cells,
         P(no tap lands on a bound) = prod (n-2)/n = 2.8e-4
```

**(B) The T1 ALLOCATION** — a cell the firmware *reserved* for opcode `0x67`,
used or not. Population **109**.

```
   classification of the allocated cells : {'ADDRESS': 49, 'UNKNOWN': 48, 'BOUND': 12}
```

The 12 bound reservations are all cell `0x1E` of the twelve reverbs, whose
`T1[0x67]` is the seven-entry list `[0x00, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E]`.
Only operand 0 (`PRE DELAY`) appears in any T2 stream, so entries 1..6 are **dead
reservations**.

### ★ and the dead reservation is off by exactly one

ROOM REVERB 1's cells that read off the PRE DELAY base (`0x03`) are `0x18` and
`0x1B`; the four whose direction still traps are `0x19 0x1A 0x1C 0x1D`. Together
that is the **contiguous block `0x18..0x1D`, six cells, six early reflections**.
`T1[0x67]` reserves `0x19..0x1E` — same length, shifted by one, which is exactly
why its last entry falls on the ceiling. **MEASURED:** the two blocks and their
offset. **INFERRED:** a dormant off-by-one in a table no T2 record reaches.

**Use for the next phase (NOT APPLIED):** the host itself calls `0x19 / 0x1A /
0x1C / 0x1D` delay taps, so their C-format words are **READS** — a CONSISTENT
direction for 48 of the 48 still-trapping cells, and the delays that follow are
`975, 1082, 1084, 1625` samples off the pre-delay base in ROOM REVERB 1.

### The answer to the brief's question, as found

* *"If every ADDRESS cell has a UI name and no BOUND cell does, the split falls
  out with no search"* — the second half is **TRUE** (0 of 36) and the first half
  is **FALSE**: only 36 of 829 cells carry a name at all, so the name cannot
  classify the other 793.
* *"If bounds are written by a different opcode, or by no opcode at all, that is
  an even cleaner separator"* — **FALSIFIED.** There is no other opcode: `0x67`
  is the only one routed to the descriptor writer (`host-side.md` A1), and its
  reservation table points at a forced bound 12 times.
* The separator that works is the one the host does **not** supply: the **value
  against the unit's own region**.

---

## 6. The four cells the brief asks about

```
python3 dsp/tools/bounds.py invariants
```

| cell | value across the 12 reverbs | direction | verdict |
|---|---|---|---|
| **idx 1** | `45464` in ROOM REVERB 1, `0` in the other eleven | WRITE | **BOUND** |
| **idx 3** | `32768`, invariant | WRITE | **ADDRESS** — the pre-delay line base |
| **idx 5** | `41590`, invariant | WRITE | **ADDRESS** — ladder segment 1's base |
| **idx 30** | `32767`, invariant | READ | **BOUND** — below unit 1's floor |

### 6.1 idx 3 — and the sharpest form of the whole result

`BASE24` of every reverb's `PRE DELAY` is `32770`; `BASE24 − 2 = 32768 = cell
0x03`. So `0x03` **is** the pre-delay line's base, anchored 12 of 12 by the
firmware. It is also unit 1's region floor — because the allocator starts at the
floor, not because the cell is a floor *register*.

> **The value `32768` is an ADDRESS in the 12 unit-1 reverbs and a BOUND in 71
> unit-0 algorithms.** Any classifier that keys on the value alone is wrong; the
> unit decides. §7's rival `R4` is exactly that classifier, and it loses 23–0.

### 6.2 idx 5 — refuted as a ceiling, and the `200.00 ms` re-priced

Item **H** above carries the three legs. The rule-8 arithmetic:

```
   41590 - BASE24 32770   = 8820 samples = 200.0000 ms
   41590 - cell 0x03 32768 = 8822 samples = 200.0454 ms
```

The roundness exists only against `BASE24`, i.e. only if the `+2`
address-generator offset (labelled **INFERRED** by `dram-matching.md` §1, and
explicitly not statically separable) is already granted. **Do not quote
`200.00 ms exactly` as a confirmation of anything.**

### 6.3 idx 1 — decided as *not an address*, undecided as *what*

```
   algo 16 ROOM REVERB 1   idx1 = 45464  in region             max read 45463
   algo 17..27             idx1 =     0  OUT of unit 1 region  max read 49140..64899
```

Two mechanisms, one conclusion. But the *ring-top* reading predicts `max + 1`
everywhere and delivers it in **3 of 74** LIMIT cells (ROOM REVERB 1, GATED
REVERB, ENHANCER). **The ring-top reading is FALSIFIED as stated.** What survives
is `an address no read can reach`. Its semantics stay **OPEN**.

### 6.4 "Does the bank have a per-unit ceiling register at all?"

**Yes, and it is now located:** one cell per algorithm, at relative index `n−2`
(`n−1` when `n = 2`), holding `32768` in unit 0 and `32767` in unit 1, 83 of 83.
**Where the rotation/wrap happens is still OPEN** — this pass locates the
register and its constant; it does not decode the instruction that consumes it,
and that instruction still traps.

---

## 7. ★ RULE 7 — where the test separates and where it does not

```
python3 dsp/tools/bounds.py rivals
```

**GROUND TRUTH, and it is not this pass's own output.** ADDRESS: the 36
host-named `op-0x67` taps (PROVEN BY CONSTRUCTION — the evaluator adds a canned
line base to a millisecond count) plus the cells holding those `BASE24 − 2` line
bases → 69. BOUND: out of the unit's region → 94. **Total 163 of 829.**

```
   STATISTIC 1  straight score -- printed first and NOT the argument
      H-REGION+ALLOC (this pass)     163 / 163
      R1 positional {1, n-2}         163 / 163
      R2 value extremes              142 / 163
      R3 all-ADDRESS (the incumbent)  69 / 163
      R4 value in {32767,32768}      140 / 163
      R5 largest value               140 / 163

   STATISTIC 2  scored ONLY on the sites where the rival disagrees with H
      H vs R1     0 disagreement sites in the truth set   --   0 - 0
      H vs R2    21 disagreement sites                    H  21 - 0
      H vs R3    94 disagreement sites                    H  94 - 0
      H vs R4    23 disagreement sites                    H  23 - 0
      H vs R5    23 disagreement sites                    H  23 - 0
```

### ★ The uncomfortable part, said first

`R1` — *"the bounds are relative index 1 and relative index n−2"* — never looks
at the instruction, never looks at the value, and only counts cells. It agrees
with this pass on **777 of 829** aligned cells and matches it exactly on the
ground truth. The 52 disagreements are 48 C-format cells (H says UNKNOWN, R1
guesses ADDRESS) and 4 cells in ENHANCER and RING MODULATOR — **none of which
carries ground truth.**

> **MY TEST DOES NOT SEPARATE H FROM R1.** I am not entitled to say the
> value-based route beat the positional one. What I am entitled to say is that
> two independent routes — position, and value-against-region — land on the same
> set. In this project that convergence has repeatedly been the signature of a
> right answer rather than of a good test, and it is reported as such.

### Where the test does separate, demonstrated

`R3` (all-ADDRESS, the incumbent that produced the fake lines) loses **94–0** —
it is refuted only by the *negative* truth set, which is why the region test had
to exist before anything was scored. `R4` ("the value 32768 is a bound") loses
**23–0**, because that value is the host-anchored PRE DELAY base in unit 1. `R5`
("the largest value is a bound") loses **23–0**, because unit 1's largest value
is the top of the ladder.

---

## 8. The controls, each shown saying NO — `bounds.py control`

**CONTROL 1 — the deliberately-wrong twin of the direction rule.** Swap round 5
D (`0x60` READ instead of WRITE) and rerun the identical pipeline.

```
   SHIPPED  : clean residue 81 of 83, 324 lines, 0 partial overlaps, HOST-ANCHOR 33 of 36
   REVERSED : clean residue 69 of 83, 279 lines, 0 partial overlaps, HOST-ANCHOR  0 of 36
```

The **HOST-ANCHOR** statistic is the sharp one and nothing in the model was
fitted to it: for each of the 36 named taps the firmware *also* hands us that
line's base as the record's `BASE24`; the statistic asks whether the model put
the tap on a line whose base cell holds `BASE24 − 2`. **33 of 36 shipped, 0 of 36
reversed.** The 3 misses are exactly the firmware inconsistencies
`dram-matching.md` §2 already named, re-derived here rather than quoted:

```
   algo  9 SINGLE DELAY     cell 0x28  BASE24 16352 -> base 16350, real base 15935  (417 stale)
   algo 65 S.DELAY+S.DELAY  cell 0x2C  BASE24 24513 -> base 24511, real base 24509  (BASE24-4)
   algo 67 S.DELAY+VIBRATO  cell 0x2B  BASE24 16352 -> base 16350, real base 16150  (200 stale)
```

This is an independent re-confirmation of round 5's polarity from a route round 5
did not use.

> **AND THE HONEST PART: the partial-overlap statistic DID NOT REJECT (0 versus
> 0).** I built it expecting it to. Reversing the labels permutes the same value
> set into a different but still-nested layout. It is printed as a failed
> discriminator rather than deleted.

Note also *which half* can respond at all: the CEILING half of the
classification is direction-**blind** (it is a region test), so only the
LIMIT/FLOOR half and the line geometry are under test in control 1.

**CONTROL 2 — the phase.** Round 5 B forces δ = 0. Shift the cell↔word map:

```
   delta = -3 : clean residue 65 of 83, HOST-ANCHOR  0 of 36
   delta = -2 : clean residue 75 of 83, HOST-ANCHOR 30 of 36
   delta = -1 : clean residue 72 of 83, HOST-ANCHOR  0 of 36
   delta = +0 : clean residue 81 of 83, HOST-ANCHOR 33 of 36    <- shipped
   delta = +1 : clean residue 70 of 83, HOST-ANCHOR  3 of 36
   delta = +2 : clean residue 78 of 83, HOST-ANCHOR 24 of 36
   delta = +3 : clean residue 66 of 83, HOST-ANCHOR  3 of 36
```

δ = 0 is the maximum on both statistics — an independent re-confirmation of round
5 B, and note that δ = −1 (the phase `dram-matching.md` originally published and
round 5 falsified) scores **0 of 36** on the anchor.

**CONTROL 3 — the matching rule's own twin.** A4 says *largest WRITE **strictly**
below*. The non-strict variant is what you write if you have not noticed that two
cells can hold the same boundary address:

```
   STRICT     :   0 zero-length lines of 324
   NON-STRICT : 133 zero-length lines of 325     -> REJECTS
```

**CONTROL 4 — a classifier that cannot fail, printed so it is never mistaken for
evidence.** `all-ADDRESS` scores **36/36 = 100 %** on every positive
ground-truth site and **0/94 = 0 %** on the negative one. It is exactly the model
that produced the fake lines. A test built only from the positive sites could
never have caught it.

**CONTROL 5 — the permutation null.** Shuffle each algorithm's cell *values*
among its own cells (multiset preserved, the binding to the instruction
destroyed):

```
   ROM      : 81 of 83 algorithms clean
   shuffled : mean 19.8   min 9   max 30   over 400 trials
   trials reaching 81 : 0 of 400
```

**CONTROL 6 — the degeneracy check (method rule 4).** Is `CEILING` the same
statement as `LIMIT` counted twice?

```
   CEILING : direction {READ: 83}    2 distinct values corpus-wide
   LIMIT   : direction {WRITE: 74}  18 distinct values
```

Opposite direction, opposite value behaviour. Not one thing counted twice.

---

## 9. PREDICT THEN CHECK

Each prediction was written down before the experiment that tests it was run.

| # | prediction | measured | |
|---|---|---|---|
| **P1** | every host-named `op-0x67` tap classifies ADDRESS | 36 of 36 | **HIT** |
| **P2** | no host-named tap sits on rel 1 or the ceiling slot | 0 violations of 36 | **HIT** |
| **P3** | the T1 allocation also avoids the bounds — the brief's *cleaner separator* | **12 of 109 land on a forced bound** | **MISS** |
| **P4** | the anchored `+3` offset would be **needed** to build the lines | the allocation model builds all 14 ROOM REVERB 1 lines, incl. the `+9` one, without it | **MISS** |
| **P5** | cell index 1 is a ring-TOP register, i.e. `max + 1` | **3 of 74** | **MISS** |
| **P6** | idx 5 = 41590 is an allocation ceiling (the brief's reading) | it is a WRITE, it is ladder segment 1's base, deleting it orphans read cell `0x02` | **MISS** |
| **P7** | idx 30 = 32767 is a BOUND | below unit 1's floor, 12 of 12 | **HIT** |
| **P8** | every algorithm carries exactly ONE ceiling cell | 83 of 83 | **HIT** |
| **P9** | the two named fake lines are `CEILING − LIMIT` | `897 = 32768−31871`, `32767 = 32767−0`; the two bounds are `+3` apart in 50 of 83 | **HIT** |
| **P10** | the host NAME lever alone settles the split | it convicts (0 of 36, null `p = 2.8e-4`) but only 36 of 829 cells carry a name | **PARTIAL** |
| **P11** | the ceiling constant is the same number in both units | `32768` unit 0, `32767` unit 1 — same boundary, different number | **MISS** |
| **P12** | the bank has exactly two canned constants, 32767 and 32768 | there is a **third**, `128`, in 10 algorithms | **MISS** |

**The two misses that changed the model.**

* **P4** — I started from `dram-matching.md`'s `+3` rule and it could not close
  ROOM REVERB 1's eleventh segment (offset `+9`) or the early reflections.
  Replacing *"pair at +3"* with *"the read belongs to the buffer it falls
  inside"* closed both, and turned `+3` into an **output** (273 of 324) instead
  of an input. This is method rule 3 biting again: the offset was a parameter I
  had been treating as part of the model.
* **P3** — I expected the firmware's own reservation table to name the addresses.
  It reserves a forced bound twelve times. Chasing *why* produced item **M**, the
  off-by-one, which is the most useful thing this pass hands forward.

---

## 10. What is still OPEN, stated so the next phase does not re-derive it

1. **What the LIMIT cell *means*.** Not an address — settled. Ring top —
   falsified. Semantics — OPEN.
2. **What the CEILING register *does*.** Located and its constant measured; the
   instruction that consumes it still traps, so *where the rotation/wrap happens*
   is OPEN.
3. **The 48 C-format cells.** Item **M** gives a CONSISTENT reading (they are
   early-reflection taps, hence READS) from the host's own reservation table.
   Not applied. If a later pass forces the C-format direction, the reverbs'
   line count goes 14 → 18 per algorithm and the ER set becomes
   `540 650 975 1082 1084 1625` samples in ROOM REVERB 1.
4. **ENHANCER rel 0/rel 1 and RING MODULATOR rel 0** — the two DISPUTED `128`
   cells. Two independent readings, no ground truth, deliberately unresolved.
5. **The 8 unaligned algorithms** {4, 6, 36, 66, 73, 75, 96, 97} are not
   classified at all: `#cells != #consumers`, so the δ = 0 map does not apply.
6. Nothing here moves the frame tally. **107 FULLY / 92 addressing-only / 86
   dark, unchanged; 0 of 1 536 349 frames complete.** The bank is now
   *described*; no word of the microprogram executes because of it.
