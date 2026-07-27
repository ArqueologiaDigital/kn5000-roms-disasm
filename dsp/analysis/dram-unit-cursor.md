# THE UNIT-1 CURSOR RELOAD — one word, two bases, and the wrap that does it; and MODEL M5 IS DEAD

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis of the Sub CPU ROM, the 100 canned parameter
streams and the 38 body images only.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **FALSIFIED** / **OPEN**.

Answers TARGET 3 of round 6 — task A (the unit-1 reload), task B (model **M5**)
and task C (the wrap). Adjudicates
[`dram-cursor-closure.md`](dram-cursor-closure.md) items C/D/E,
[`adjudication-round5.md`](adjudication-round5.md) §15 items 3 and 4, and
consumes [`dram-bounds.md`](dram-bounds.md).

Tool: [`../tools/cursor_units.py`](../tools/cursor_units.py) — stdlib plus the
repo's own ROM parsers. **Every number below comes out of it.**

```
python3 dsp/tools/cursor_units.py ptr      # 1 ★★★ EVERY pointer write in the ROM
python3 dsp/tools/cursor_units.py reload   # 2 ★★★ TASK A -- the enumeration
python3 dsp/tools/cursor_units.py alt      # 3 where the alternation BREAKS
python3 dsp/tools/cursor_units.py m5       # 4 ★★★ TASK B -- M2 versus M5
python3 dsp/tools/cursor_units.py wrap     # 5 TASK C -- the wrap, per unit
python3 dsp/tools/cursor_units.py control  # 6 the controls, each shown saying NO
python3 dsp/tools/cursor_units.py predict  # 7 PREDICT-THEN-CHECK
python3 dsp/tools/cursor_units.py all      # ~60 s

python3 dsp/verify.py                      # BYTE-MATCH OK
```

**NOTHING WAS APPLIED.** Neither disassembler mirror was touched, the 42
delay-DRAM slots still trap, `dsp/verify.py` reports **BYTE-MATCH OK**, and no
word gains or loses an executable semantic. Method rule 6: the task-A result is
FORCED only *within* an enumerated model class and the task-C result is not
forced at all, so nothing ships.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE WHOLE ROM CONTAINS THREE WRITES TO THE DESCRIPTOR POINTER, AND NOT ONE OF THEM IS INSIDE A BODY IMAGE.** I-RAM 44 `801.0.25.825`, I-RAM 52 `801.0.25.825`, I-RAM 62 `801.0.26.825`. Every pointer write of any kind (`lo12 = 0x82x`) in the corpus is in the 60-word header or the 23-word epilogue; the 38 body images contain **zero**. Population: the whole ROM, nothing sampled. This one measurement carries both tasks. | **MEASURED** (§1) |
| **B** | ★★★ **TASK A, ANSWERED: THE PER-UNIT DIFFERENCE IS CARRIED BY A WRAP, NOT BY THE WORD — AND THAT IS WHY NO FIELD OF THE WORD COULD EVER CARRY IT.** Exhaustive over 766 576 machines in the class *(increment PRE/POST) × (wrap RESET/MOD) × (wrap-on-load y/n) × (per-unit ring `[B_u, L_u)`) × (do I-RAM 46/54 consume)*: **4440 survivors, and in every single one `B_1 = 0x00` and `L_1 ≤ 0x26`.** Unit 1's cursor ring **ends where unit 0's block begins**. The payload `0x25` is simultaneously *"one below unit 0's base"* and *"the last cell of unit 1's ring"*, so **one immediate starts both units on their own base**. | **FORCED** within the printed class (§2) |
| **C** | ★★★ **AND THE WRAP IS NECESSARY, DEMONSTRATED BY THE TWIN.** Same sweep with the wrap switched off: **0 survivors** on the real anchors, **8** on a fake unit-1 anchor of `0x26` that needs no wrap. The control can say yes and it says no here. ⚠ **My FIRST version of this control could not fail** and is printed in §6 rather than deleted. | **MEASURED** (§6 control 1) |
| **D** | ★★★ **TASK B, ANSWERED: MODEL M5 IS REFUTED, ON THREE INDEPENDENT ROUTES.** (1) Every M5 shape except the parity split needs a *per-algorithm* second cursor base, and item A says there is nowhere in the ROM to keep one. (2) The parity split — the only algorithm-independent shape — **cannot even ADDRESS 22 of the 83 aligned algorithms**, the twelve reverbs among them, **and for both C-format polarities**. (3) Where it can, the host anchors beat it **5 : 0** on the sites where the two models disagree, with O1 `5/5 : 1/5` and O3 `4/4 : 0/4`. **The published cell assignments for the non-alternating regions stand unchanged; nothing in TARGET 2's constraint set moves.** | **FORCED** (§4) |
| **E** | ★★ **AND WHERE THE ALTERNATION ACTUALLY BREAKS, PRINTED.** 55 of 83 aligned algorithms alternate strictly; **28 do not**, and the same 28 have unequal read and write counts. `RRRWRWRW` (ENHANCER), `RWRRRRW` (MULTI TAP), `RR` ×8 (the `[128, 32768]` blocks with no write at all), `RRW` (RING MODULATOR), and the five `S.DELAY+…` composites. The reverbs are `RWRW…R??R??RW`. Census `READ 416 / WRITE 365 / trapping 48` — **round 5 §7 reproduced exactly from an independent walk**. | **MEASURED** (§3) |
| **F** | ★★★ **`dram-cursor-closure.md` ITEM D IS FALSIFIED — AND BY A WORD ITS OWN ITEM C QUOTES.** Item D derives *"the frame-entry cursor is `0x20`, with no free parameter"* from *"the run from the unit-1 reload to the frame boundary is **reload-free**"*. **I-RAM 62 `801.0.26.825` sits inside exactly that run.** `|R| ≥ 3`, not 2. Sweep: **0 of the entire model class** can put the header's consumers inside the `0x20..0x25` gap given that reload. Item D's *value* dies; its *measurement* (that gap is the file's only gap) survives — and item B gives it a better reason. | **FALSIFIED** (§2 sweep 3) |
| **G** | ★★ **THE GAP `0x20..0x25` IS THE UNUSED TOP OF UNIT 1's OWN PARTITION.** Unit 1's ring `[0x00, 0x26)` holds **38** cells and the reverbs use **32**; the remaining **6** are exactly `0x20..0x25`. Unit 0's `[0x26, 0x40)` holds 26 and GATED REVERB uses 20. `38 + 26 = 64`, and the corpus maximum cell is `0x39`. | **CONSISTENT** (the arithmetic; `L_0` is only bounded below, §5) |
| **H** | ★★ **`I-RAM 46` AND `54` (`800.1.60.00B`) — THE FLAG IS NOT FREE.** In the **PRE** family no survivor has them consuming a descriptor cell: `dram-cursor-closure.md` §3.6's option **(a)**, labelled CONSISTENT there, is **FORCED** here. In the **POST** family both branches survive. Reported as two branches and not collapsed to the one I preferred. | **FORCED given PRE**; **OPEN** given POST (§2 sweep 4) |
| **I** | ★★ **AND A THIRD HEADER WORD THE R2 CONSUMER PREDICATE GETS WRONG.** `I-RAM 40 = C4A.1.C0.820` matches the predicate (`class4 == 1` + `hi12` escape) but its `lo12` is `0x820` — it is a **pointer load, selector `0x20`**, not a descriptor consumer. The header's consumer count is a parameter, not a constant, and every closure argument that quotes `h1 = 4` is quoting an upper bound. | **MEASURED** (§1) |
| **J** | ★ **THE REVERBS POKE THE DESCRIPTOR POINTER TWICE** — `cell 0x00`, then `cell 0x1E`. Their 32 cells arrive as **30 + 2**. Nobody had noticed, and it is the host-side counterpart of the thing round 5 §6 had to explain with a `+9` offset: cells `0x1E`/`0x1F` are a separately-addressed tail. | **MEASURED** (§1) |
| **K** | ★ **TASK C: TWO DIFFERENT REGISTERS SHARE THE WORD `wrap`, AND THIS NOTE SEPARATES THEM.** The **descriptor** cursor's wrap is answered by item B. The **delay-DRAM** rotation `G` is a different register in a different memory; TARGET 1's CEILING cells (`32768` ×71 in unit 0, `32767` ×12 in unit 1) are one physical boundary written as the exclusive bound on each side, three readings survive, and the instruction that consumes them still traps. **Nothing applicable.** | **OPEN** (§5) |
| **L** | ★ **THE FRAME TALLY DOES NOT MOVE, AND SAYING SO IS PART OF THE RESULT.** 0 of 1 536 349 frames complete, 42 delay-DRAM slots still trap, `dsp/verify.py` BYTE-MATCH OK, both mirrors untouched. The `DRAM-ADDR` family now needs only the **datapath** and the **read latency** — the map, the direction, the bounds and now the cursor are all settled. | **MEASURED** |

---

## 1. ★★★ Every pointer write in the ROM — `cursor_units.py ptr`

**POPULATION (method rule 9):** the 38 distinct body images, the 60-word frame
header, the 23-word epilogue and all 100 canned parameter streams. Nothing is
sampled; this is the whole ROM.

### 1.1 Host side — where the two anchors come from

A 5-byte parameter entry is `[e0 kind][24 bits of payload, split 7+8+8+1][7-bit
register tag]`. Tag `0x4C` writes a descriptor **cell**; tag `0x25` sets the
**destination pointer**, whose bits `[16:5]` are the cell index.

```
   unit 0   79 algorithms   0204D0 -> cell 0x26
   unit 1   12 algorithms   020010 -> cell 0x00    0203D0 -> cell 0x1E
```

⇒ **the two anchors of task A are host-side ground truth**; no instruction field
enters them. And item J: the reverbs set the pointer **twice**.

### 1.2 Program side — the fact that carries both tasks

```
   HDR 15  C0A.2.92.820   selector 20   HDR 42  801.0.70.821   selector 21
   HDR 22  C04.3.12.820   selector 20   HDR 43  801.0.6C.827   selector 27
   HDR 29  C42.4.57.820   selector 20   HDR 44  801.0.25.825   selector 25 ***
   HDR 31  C0A.4.B1.820   selector 20   HDR 50  801.0.50.821   selector 21
   HDR 40  C4A.1.C0.820   selector 20   HDR 51  801.0.64.827   selector 27
                                        HDR 52  801.0.25.825   selector 25 ***
   EPI 62  801.0.26.825   selector 25 ***
   EPI 69  801.0.90.821   selector 21
   EPI 77  859.0.86.822   selector 22

   pointer writes inside any of the 38 BODY IMAGES: 0
```

★ **NOT ONE BODY IMAGE TOUCHES A POINTER REGISTER.** Every cursor reload in the
machine is one of those header/epilogue words, and **all of them are
algorithm-independent**. That is what makes §4's refutation of M5 structural
rather than statistical, and it is why §2 can enumerate the model class
exhaustively instead of hoping.

Item I falls straight out of the same list: `I-RAM 40` is in it.

---

## 2. ★★★ TASK A — the enumeration, and the answer

### 2.1 The anchors and the collision

```
   unit-0 body, consumer 0 -> cell 0x26    aligned block sizes [2,3,6,7,8,10,11,15,20]
   unit-1 body, consumer 0 -> cell 0x00    block size 32 x12
   BOTH reloads carry payload 0x25, and they are the SAME 36 bits.
```

### 2.2 THE MODEL CLASS, PRINTED BESIDE THE CLAIM (method rule 3)

Five independent choices, swept as a full cross product:

| # | choice | values |
|---|---|---|
| (i) | increment discipline | `PRE` (cell = ++cur) · `POST` (cell = cur++) |
| (ii) | wrap style | `RESET` (cur ← B) · `MOD` (cur ← cur − (L−B)) |
| (iii) | wrap applied at | increment only · increment **and** load |
| (iv) | ring | per-unit `[B_u, L_u)`; `B_1` 0x00..0x08, `L_1` 0x20..0x41, `B_0` 0x00..0x28, `L_0` 0x3A..0x41 |
| (v) | do `I-RAM 46/54` consume | yes · no (one flag: they are the same word) |

`L_0 ≥ 0x3A` because GATED REVERB reaches cell `0x39` and must not wrap inside
its own body.

★ **WHAT IS DELIBERATELY NOT IN THE LIST, ASKED EXPLICITLY (rule 3):** a
**per-algorithm** reload. §1 *measures* that no body image writes a pointer
register, so there is no such object to sweep. A **per-unit BASE added to the
payload** — the shape the D-RAM operand pointer really uses, and the brief's
first candidate — **is** in the list; it is solved in closed form in §2.4.

### 2.3 The sweep

```
   766 576 combinations evaluated.  SURVIVORS: 4440

   inc  wrap   wrap-load 46/54?    ring pairs
   POST MOD    False     consumes  312
   POST MOD    True      consumes  312
   POST RESET  False     no         48
   POST RESET  False     consumes  304
   POST RESET  True      no         48
   POST RESET  True      consumes  304
   PRE  MOD    False     no        312
   PRE  MOD    True      no        312
   PRE  RESET  False     no       2184
   PRE  RESET  True      no        304

   ACROSS EVERY SURVIVOR:
      B_1 = 0x00                       <- the model recovering the measurement
      L_1 in 0x20 .. 0x26              <- FORCED to a 7-value range, top 0x26
      B_0 in 0x00 .. 0x26              <- unconstrained: unit 0 never reaches
                                          its own wrap in any shipped algorithm
      L_0 in 0x3A .. 0x41
   and under the MOD flavour of the wrap alone:
      L_1 = 0x26                       <- a SINGLE value
```

★ **THE INVARIANT IS THE ANSWER.** `B_1 = 0x00` and `L_1 ≤ 0x26` in **every**
surviving machine. Unit 1's cursor ring **ends where unit 0's block begins**, so
the single payload `0x25` means *"the cell before unit 0's base"* to unit 0 and
*"the last cell of my ring"* to unit 1, and the pre-increment that follows
delivers `0x26` to one and wraps to `0x00` for the other. **The per-unit
difference is carried by the ring — which is exactly why no field of the word can
carry it, and why `dram-cursor-closure.md` item B's clash (`880.1.30.00B` is
body-word-0 of both a unit-0 and a unit-1 body) was never going to be resolved
inside the instruction.**

⚠ **`B_1 = 0x00 is FORCED` is not a discovery** and is not presented as one: the
ring base is a free parameter and the sweep simply re-bases onto whatever anchor
it is handed. Control 1 caught that, and the control that survives tests the
thing actually claimed — **is the wrap necessary** — and rejects.

### 2.4 The rival family, solved in closed form

Without a wrap, a per-unit BASE added to the payload needs

```
   PRE  : BASE[0] = 0x00, BASE[1] = 0xDA   difference 0x26
   POST : BASE[0] = 0x01, BASE[1] = 0xDB   difference 0x26
```

so the family is not empty — it needs a per-unit register whose two values differ
by exactly `0x26 = 38`. **The carrier search, re-run and widened** (every
differing field of every paired word of the two setup blocks, against three
target pairs, `|scale| ≤ 8`):

```
   differing fields across the paired setup words          : 12
   of those admitting an affine map with |scale| <= 8      : 0
```

`dram-cursor-closure.md` §4 got 0 of 14 with a narrower field set and a narrower
target set; this gets **0 of 12** with a wider one. A **1-bit unit selector
indexing a two-entry table of hardwired bases** is not refutable by any such
search — but it is *exactly as unfalsifiable* as a hardwired per-unit ring, and
only the ring explains why the payload is `0x25` rather than `0x00` or `0xDA`.
**CONSISTENT, and it is not evidence.**

### 2.5 ★★★ Sweep 3 — the epilogue reload falsifies closure item D

`dram-cursor-closure.md` item D: *"in the surviving |R| = 2 family the run from
the unit-1 reload to the frame boundary is **reload-free**, so entry = 0x00 + 32
+ 0 = 0x20."* **`I-RAM 62 = 801.0.26.825` sits inside exactly that run** — and
the same note's item C quotes the word, three items earlier. `|R| ≥ 3`.

```
   machines in the whole class putting 1..3 header consumers
   wholly inside the 0x20..0x25 gap, given the I-RAM 62 reload : 0
```

Where they *do* land, both readings printed and **neither chosen**:

```
   PRE , unit-0 ring [0x26,0x40) : 0x27 0x28 0x29    (the unit-0 block's rel 1..3)
   PRE , unit-1 ring [0x00,0x26) : 0x00 0x01 0x02    (the reverb's rel 0..2)
   POST, unit-0 ring [0x26,0x40) : 0x26 0x27 0x28
   POST, unit-1 ring [0x00,0x26) : 0x00 0x01 0x02
```

Either way the reload at I-RAM 44 resets the cursor before the body runs, so
neither reading disturbs the `#cells == #consumers` identity. **What dies is item
D's derived value `0x20`; what survives is its measurement that `0x20..0x25` is
the only gap in the whole descriptor file — and item G gives that gap a better
reason than a coincidence of counts.**

### 2.6 Sweep 4 — I-RAM 46 and 54

```
   PRE  + `46/54 do not consume' : 3112 surviving ring pairs
   PRE  + `46/54 consume'        :    0
   POST + `46/54 do not consume' :   96
   POST + `46/54 consume'        : 1232
```

The flag is **not independent**: `PRE` forces *"they consume nothing"*, which is
`dram-cursor-closure.md` §3.6's option (a), there labelled CONSISTENT. `POST`
leaves both branches alive. Reported as two branches.

---

## 3. Where the alternation breaks — `cursor_units.py alt`

**POPULATION:** 91 algorithms ship descriptor cells; **83** have
`#cells == #consumers` and carry every test; **829 cells**.

```
   CENSUS: READ 416   WRITE 365   still trapping (C format) 48
   -> adjudication-round5 sect. 7 reproduced EXACTLY, independently

   strictly alternating (ignoring the C-format cells) : 55 of 83
   ALTERNATION BREAKS                                 : 28 of 83
   unequal READ and WRITE counts                      : 28 of 83   (the same 28)
```

The 28, in full:

```
   a3  ENHANCER          n=8  RRRWRWRW            R5  W3
   a10 MULTI TAP DELAY   n=7  RWRRRRW             R5  W2
   a54 RING MODULATOR    n=3  RRW                 R2  W1
   a64 S.DELAY+CHORUS    n=15 RWRWRWRRWRWRWRW     R8  W7
   a65 S.DELAY+S.DELAY   n=11 RWRWRWRWRRW         R6  W5
   a67 S.DELAY+VIBRATO   n=11 RWRWRRWRWRW         R6  W5
   a68 S.DELAY+PHASER    n=7  RWRRWRW             R4  W3
   a70 AUTO WAH+S.DELAY  n=7  RWRRWRW             R4  W3
   a5 a32 a33 a34 a35 a39 a48 a52   n=2   RR      R2  W0   <- no WRITE at all
   a16..a27 the twelve reverbs  n=32  RWRW...RWR??R??RW  R15 W13 ?4
```

★ **THE DEGENERACY, STATED BEFORE ANY SCORE (method rule 4).** On the 55
strictly-alternating algorithms a single `+1` cursor and two `+2` cursors visit
the same cells in the same order — **M2 and M5 are one machine counted twice
there**, and that includes every block anyone has actually studied. Control 2
demonstrates it (55 identical maps, 0 different). Every head-to-head below is
scored only where the two models disagree.

---

## 4. ★★★ TASK B — M5, refuted three ways

### 4.1 The enumeration of M5 itself (method rule 3)

A cursor is `(start, stride)`. M5 = two of them partitioning the block.
Enumerated: `aR, aW ∈ [0,8)`, `sR, sW ∈ [1,4]`, plus the two **block** shapes
(reads first / writes first). A cursor may not leave its algorithm's block,
because the ring is per **unit** and far larger than any block.

★ **THE CONSTRAINT THAT DOES THE WORK: the parameters must be
ALGORITHM-INDEPENDENT**, because §1 measures that the whole ROM has three pointer
writes and none of them is in a body. **M5 with a per-algorithm partition is not
a model — it is one free parameter per cell, and it predicts nothing.**

```
   1024 tuples tried.  How many of the 83 aligned algorithms each can ADDRESS:
      aR=0 sR=2 aW=1 sW=2 : 61 of 83   <- the PARITY split
      aR=0 sR=1 aW=3 sW=1 : 57
      aR=1 sR=2 aW=0 sW=2 : 55        <- the parity split, other polarity
      aR=3 sR=1 aW=0 sW=1 : 52
      M5-BLOCK, reads first : 83 of 83
      M2 (ONE cursor, +1)   : 83 of 83  by construction
```

### 4.2 Route 1 — counting, with no oracle at all

The parity split cannot address **22 of 83**:

```
   a3  ENHANCER        R5 W3 -- parity needs R4 W4
   a10 MULTI TAP DELAY R5 W2 -- parity needs R4 W3
   a5 a32 a33 a34 a35 a39 a48 a52  R2 W0 -- parity needs R1 W1
   a16..a27 the twelve reverbs     R15 W13 (+4 trapping) -- parity needs R16 W16
```

★ **AND THE TWELVE REVERBS ARE REFUTED FOR *BOTH* C-FORMAT POLARITIES.** That
matters because the C format is still OPEN. Their four `C40.1.80.000` cells carry
**one identical word**, so all four take the same direction:

```
   C format = READ  : R19 W13     parity needs R16 W16
   C format = WRITE : R15 W17     parity needs R16 W16
```

**No decode of the C format can rescue the parity M5.**

### 4.3 Route 2 — the head-to-head, scored only where they disagree (rule 7)

Parity-M5 is feasible **and** differs from M2 on exactly `{54, 64, 65, 67, 68,
70}`.

```
   HOST-ANCHOR, on the 5 tap sites where the two models give
   DIFFERENT verdicts:                       M2  5 : 0  M5

   ROUND-5 ORACLES, restricted to those 6 algorithms:
      O1 tap coherence        M2  5/5     M5  1/5
      O2 tap/base opposition  M2  7/10    M5  8/10   <== FAVOURS M5
      O3 equal-value pairs    M2  4/4     M5  0/4
```

The host-anchor statistic asks *does the model put each host-named `op-0x67` tap
on a line whose base cell holds that record's own `BASE24 − 2`?* — host-side
ground truth, and nothing in either model was fitted to it.

★ **O2 COMES OUT IN M5's FAVOUR AND IS PRINTED AS A FAILED DISCRIMINATOR**
(control 5), not buried. Two of three oracles reject; one does not.

### 4.4 Route 3 — M5-BLOCK dies differently, and it is not a score

M5-BLOCK (reads take the first `R` cells, writes the last `W`) addresses **83 of
83**. Its write cursor must start at `block_base + R`, where `R` is *that
algorithm's* read count. Corpus `R` values: `[2, 3, 4, 5, 6, 8, 10, 15]` —
**8 distinct start values, and one reload word exists**. Refuted by the pointer
census. For the record it also loses the score: **16 : 0** on the 16 disagreeing
host-anchor sites.

### 4.5 The whole-corpus picture, populations printed

```
   M2         HOST-ANCHOR 33/36   O1 10/10  O2 30/33  O3 133/133
   M5-parity  HOST-ANCHOR 12/20   O1  5/9   O2 15/17  O3   7/11
   M5-block   HOST-ANCHOR 17/36   O1  9/10  O2 14/33  O3  20/88
```

M5's smaller *totals* are themselves the refutation: the algorithms it cannot
address contribute nothing.

M2's `33/36` reproduces `bounds.py`'s host-anchor **exactly**, and its `O1 10/10`
and `O3 133/133` reproduce `adjudication-round5.md` §1 — from an independent
implementation, which is the check that this is the same instrument (control 6).
M2's three anchor misses, printed rather than asserted:

```
   a9  SINGLE DELAY     cell 0x28  BASE24 16352
   a65 S.DELAY+S.DELAY  cell 0x2C  BASE24 24513
   a67 S.DELAY+VIBRATO  cell 0x2B  BASE24 16352
```

— `dram-matching.md` §2's firmware inconsistencies, re-derived.

★ **WHERE THIS PASS DOES *NOT* REPRODUCE, SAID PLAINLY:** my `O2` has **33**
pairs where round 5's had 28, because mine pairs a tap with *any* cell of the
same algorithm holding `BASE24 − 2` while round 5 used its 28 curated anchored
pairs. Its three misses (`a64` cell `0x2D`, `a68` `0x29`, `a70` `0x29`) are the
`+4 geometry` sites round 5 §4 already flagged. **My O2 is the looser instrument
and its absolute score must not be quoted against round 5's.**

### 4.6 What this hands the datapath agent

> **M5 is dead. The `δ = 0` identity map holds in the non-alternating regions
> too, so every published cell assignment stands and TARGET 2's constraint set is
> unaffected.** The 28 algorithms of §3 are the ones where the question was live;
> they are now closed the same way as the other 55.

---

## 5. TASK C — the wrap. Two different registers, separated

The brief's *"where does the cursor wrap"* and `r3-delaydram.md`'s rotation
register `G` are **not the same register and not the same memory**. Conflating
them is exactly the class of error rule 10 keeps catching here.

**(a) The DESCRIPTOR cursor's wrap** — answered by §2. Per unit; unit 1's ring is
`[0x00, L_1)` with `L_1 ∈ [0x20, 0x26]`, and `= 0x26` under the MOD flavour; unit
0's base is `0x26`. The wrap fires **exactly once per frame**, on the
pre-increment immediately after I-RAM 52's reload, and that single firing is the
whole mechanism by which one word serves two units. **CONSISTENT arithmetic, not
forced:** a 64-cell descriptor RAM split **38 / 26** at `0x26`; unit 1 uses 32 of
its 38 and the remainder is the gap; GATED REVERB uses 20 of unit 0's 26; the
corpus maximum cell is `0x39` and `0x3A..0x3F` are never written.

**(b) The DELAY-DRAM rotation `G`** — a different register in the audio memory.
TARGET 1's contribution, re-read from `descriptor-cell-classes.json`:

```
   unit 0  CEILING = 32768   x71        unit 0 owns DRAM [0, 32767]  -> top + 1
   unit 1  CEILING = 32767   x12        unit 1 owns [32768, 65535]   -> floor - 1
```

**One physical boundary, written as the exclusive bound on whichever side the unit
is on.** ENUMERATION of what the pair can be (rule 3):

1. each unit's ring is its own region and the cell is the exclusive limit *in the
   direction of travel* — which needs the two units to travel in **opposite**
   directions;
2. **one shared partition constant**, handed to each unit in the polarity that
   unit needs, the hardware deriving its own limit;
3. not a limit at all, but a null / no-line **sentinel**.

(2) and (3) survive. (1) needs a direction asymmetry nothing in the corpus shows
and the rotation sign `s = −1` is corpus-wide. **The wrap POINT is MEASURED, the
MECHANISM is OPEN, the instruction that consumes the ceiling cell still traps,
and therefore nothing here can be applied.**

---

## 6. Controls, each shown saying NO

| # | control | shown rejecting |
|---|---|---|
| **K1** | ★ **THE FIRST VERSION COULD NOT FAIL, AND IS PRINTED BEFORE THE ONE THAT WORKS.** I fed the task-A sweep a deliberately wrong unit-1 anchor (`0x01`) expecting zero survivors; it found **42**, because the ring **base** is a free parameter and the model simply re-bases onto any anchor it is handed. Method rule 1, caught before publication — the sixth such catch on this chip. |
| **K1′** | The replacement, testing the thing actually claimed — **is the wrap necessary?** wrap ON, real anchors: **26** survivors; wrap OFF, real anchors: **0**; wrap OFF, **fake** anchors `0x26/0x26` (which need no wrap): **8**. It rejects, *and* it can still say yes. |
| **K2** | **The degeneracy check, run before any M5 score is believed** (rule 4): on the 55 strictly-alternating algorithms M2 and parity-M5 produce **55 identical maps, 0 different**. Any test that "separated" them there would be measuring nothing — and that set contains every reverb. |
| **K3** | **A rival that ignores program order**: reverse each block's consumer list. HOST-ANCHOR M2 33/36 vs reversed **5/36**, and **28 : 0** on the 28 disagreeing sites. |
| **K4** | **A permutation null for the host-anchor statistic** (400 trials, words shuffled within each algorithm, all values preserved): min **2**, median **8**, max **15**, against M2's **33**. **0 of 400** reach it. |
| **K5** | ★ **ONE OF MINE THAT DID NOT DO WHAT I BUILT IT FOR, PRINTED RATHER THAN DELETED.** I expected all three round-5 oracles to reject parity-M5 where it is feasible. O1 and O3 do, decisively; **O2 comes out slightly in M5's favour**. O2 is a failed discriminator for this question and is labelled one. Its three corpus-wide misses are an artefact of *my* looser reconstruction of it, not of the map — a different miss set from the host anchor's. |
| **K6** | **The instrument itself.** This pass re-implements the host-anchor statistic and all three oracles from scratch. If it had not reproduced `bounds.py`'s 33/36 and round 5's O1 10/10 and O3 133/133 exactly, nothing else here could be believed. §4.5 prints them. |

---

## 7. PREDICT-THEN-CHECK — 5 hits, 7 misses/splits of 12

| # | prediction | outcome |
|---|---|---|
| **PA1** | the per-unit base is carried by a setup-block register — `0x21` (`0x70`/`0x50`) or `0x27` (`0x6C`/`0x64`) | ★ **MISS.** The two differences are `0x20` and `0x08`; neither makes `0x26`, and the widened affine search finds **0 carriers among the 12 differing fields**. The difference is not in anything the frame writes. |
| **PA2** | the unit-0 anchor plus the reload FORCE pre-increment | ★★ **MISS, and instructive.** POST survives if the ring also clamps on load. Two families — and in the PRE family *"I-RAM 46/54 consume nothing"* is FORCED while in the POST family both branches survive. |
| **PA3** | a per-unit ring with unit-1 top `= 0x26` is the unique single-parameter fix | ★★ **HIT on the invariant** (`B_1 = 0x00`, `L_1 ≤ 0x26` in every survivor), **MISS on uniqueness**: the anchors pin `L_1` only to `0x20..0x26`; only the MOD flavour pins it to `0x26`. |
| **PA4** | the epilogue reload is consistent with the header's consumers landing in the `0x20..0x25` gap | ★★★ **MISS, and it falsifies a published result.** **Zero** machines in the whole class put them there; `dram-cursor-closure.md` item D's *"reload-free run"* contains a reload. |
| **PA5** | there is a second, overlooked write to the descriptor pointer somewhere | ★★ **MISS** — three in the entire ROM, none in any body image. **That miss is exactly what kills M5.** |
| **PA6** | my task-A control rejects a deliberately wrong unit-1 anchor | ★★★ **MISS, a method-rule-1 failure of my own.** 42 survivors for a fake anchor, because the ring base is free. See K1/K1′. |
| **PB1** | parity-M5 is refuted by counting alone | ★★ **HIT.** 22 of 83 unaddressable. |
| **PB2** | block-M5 survives counting and is killed by the host anchors | ★ **HIT on survival, MISS on the mechanism** — the anchors are not what kills it; the pointer census is. |
| **PB3** | the reverbs do not separate M2 from M5 | ★★ **HIT** (a rule-4 degeneracy, K2) **and then a surprise**: they refute parity-M5 anyway, by counting, for both C-format polarities. |
| **PB4** | the round-5 oracles reject parity-M5 where it is feasible | ★ **SPLIT.** O1 and O3 reject; O2 favours M5. K5. |
| **PB5** | the census `416 / 365` reproduces | ★ **HIT**, exactly — as do the host-anchor `33/36` and `O1 10/10`, `O3 133/133`. |
| **PC1** | the descriptor-cursor wrap and the rotation `G` are the same question | ★ **MISS.** Different registers, different memories; only one is answerable today. |

---

## 8. What moves in the other notes

| source | claim | was | now |
|---|---|---|---|
| `dram-cursor-closure.md` **D** | *"closure pins the frame-entry cursor at `0x20` with no free parameter"* | **FORCED given \|R\|=2** | ★ **FALSIFIED.** I-RAM 62 is a reload inside the run item D calls reload-free. `\|R\| ≥ 3`; **0** machines in the class put the header consumers in the gap |
| `dram-cursor-closure.md` **D** (the slack) | *"`0x20..0x25` is the only gap below `0x3A`"* | MEASURED | ★ **SURVIVES**, with a better explanation: it is the unused top of unit 1's 38-cell ring |
| `dram-cursor-closure.md` **B** | the descriptor base is per-unit **state**, not an instruction field | FORCED | ★ **SURVIVES and is explained** — the state is the RING, §2 |
| `dram-cursor-closure.md` §3.6 (a) | I-RAM 46/54 consume nothing | CONSISTENT | ★ **FORCED in the PRE family**, OPEN in POST |
| `dram-cursor-closure.md` §4 | 0 of 14 carriers admit an affine map | MEASURED | ★ **SURVIVES**, re-run wider: 0 of 12 differing fields, 3 target pairs |
| `adjudication-round5.md` §1.3 / §15.4 | **M5** is the one live alternative to the identity map | **not refuted** | ★ **REFUTED**, §4 |
| `adjudication-round5.md` §15.3 | the unit-1 cursor reload — *"one of the two is not the reload, or the reload is conditional"* | OPEN | ★ **ANSWERED**: both are the reload and neither is conditional; the **ring** differs |
| `adjudication-round5.md` §7 | the census 416 / 365 / 48 | MEASURED | ★ **REPRODUCED** independently |
| `dram-bounds.md` (all) | the CEILING/LIMIT split, the host anchor 33/36 | FORCED / MEASURED | ★ **ALL SURVIVE.** The host-anchor statistic is re-implemented here and returns 33/36 with the same three misses |
| `r3-delaydram.md` §6.3 (i)/(ii)/(iii) | the cursor's per-unit phase, question **O-1** | OPEN | ★ **CLOSED** to *"a per-unit ring whose unit-1 top is unit-0's base"*, within the §2.2 class |
| the R2 consumer predicate | `class4 == 1` + `hi12` escape ⇒ descriptor consumer | 324/324 | ★ **THREE HEADER FALSE POSITIVES**: I-RAM 40 is a pointer load; I-RAM 46/54 consume nothing in the PRE family |

---

## 9. What the other agents need

* **To the datapath agent (TARGET 2).** ★ **M5 is dead — your constraint set is
  intact.** The identity map at `δ = 0` holds in the 28 non-alternating
  algorithms exactly as in the 55 alternating ones, so no published cell
  assignment changes. §3 lists the 28 in case you want the hard cases first;
  MULTI TAP DELAY (`RWRRRRW`) and ENHANCER (`RRRWRWRW`) are the sharpest.
* **To whoever next runs `r1_allpass_solve.py` with `land ∈ [6,24]`.** The
  descriptor addresses you now supply as constraints are stable: task A does not
  move a single cell assignment, it only explains where the cursor comes from.
* **To the bounds agent.** Your 8 `RR` algorithms (`[128, 32768]`, no WRITE at
  all) are also 8 of the 22 that refute parity-M5 — the same anomaly seen from a
  different side, and it is now two independent reasons to treat those blocks as
  bound pairs rather than lines.
* **To the C-format agent.** §4.2 is a *free* constraint on you: whatever
  `C40.1.80.000` turns out to be, its four reverb cells all take the **same**
  direction, and neither polarity makes the reverbs parity-addressable. Also,
  `I-RAM 40 = C4A.1.C0.820` is a **pointer load, selector `0x20`** — one of the
  five `…820` slots `register-space.md` §3.4 assigns to group D, and it should be
  removed from every descriptor-consumer count.
* **To the Apply agent.** **Nothing.** Task A is FORCED only inside the §2.2
  class, task C is not forced at all, and the 42 words keep trapping.

---

## 10. Files

* `dsp/tools/cursor_units.py` — regenerates every number above.
* `dsp/analysis/dram-unit-cursor.md` — this note.
* Unchanged and verified: `dsp/verify.py` **BYTE-MATCH OK**;
  `src/devices/cpu/upd6383/upd6383d.cpp` and `dsp/tools/dsp_disasm.py` not
  touched, so the 3057-word mirror agreement is unaffected.
