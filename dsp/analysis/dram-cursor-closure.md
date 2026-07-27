# THE DESCRIPTOR CURSOR — closure applied to the second pointer, and a direction oracle that does not exist

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis, the ROM corpus, constraint solving and the live
emulator only.

Target: the **42 delay-DRAM words** — rank 1 on all three of
[`dark-words.md`](dark-words.md)'s metrics and rank 1 for 37 of 37 unit-0 bodies.
Adjudicates [`r3-delaydram.md`](r3-delaydram.md) §5.1/§6.3 and
[`dark-words.md`](dark-words.md) §4.1/§6.

Tool: [`../tools/dram_cursor.py`](../tools/dram_cursor.py) — stdlib only. Every
number below comes out of it.

```
python3 dsp/tools/dram_cursor.py align     # the alignment and THE PHASE TEST
python3 dsp/tools/dram_cursor.py closure   # ★★★ THE DESCRIPTOR-CURSOR CLOSURE TEST
python3 dsp/tools/dram_cursor.py carrier   # where can a PER-UNIT base come from?
python3 dsp/tools/dram_cursor.py dirtest   # ★★★ direction — and why it failed
python3 dsp/tools/dram_cursor.py comb      # the echo train the comb model predicts
python3 dsp/tools/dram_cursor.py control   # every control, each shown saying NO
python3 dsp/tools/dram_cursor.py all       # ~90 s
python3 dsp/verify.py                      # BYTE-MATCH OK
```

**Nothing was applied.** `git status -- src/` in `kn7000_mame` is empty, neither
disassembler mirror was touched, `dsp/verify.py` reports **BYTE-MATCH OK**, and
no word gains or loses an executable semantic. Method rule 6: nothing here is
FORCED *outside* a model class, so nothing ships.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE DESCRIPTOR CURSOR CANNOT FREE-RUN, AND IT CANNOT BE RELOADED ONCE PER FRAME EITHER.** Exhaustive over the enumerated model class — 10 reload positions × every ring size `N ∈ (0x39, 256]` × every value — **0 survivors at \|R\|=0 and 0 at \|R\|=1**, against all **948** frames the machine can form (79 unit-0 algorithms × 12 unit-1). The frame therefore contains **≥ 2 descriptor-cursor reloads**. | **FORCED** *within the enumeration printed in §3* |
| **B** | ★★★ **THE DESCRIPTOR BASE IS PER-UNIT STATE, NOT AN INSTRUCTION FIELD.** `880.1.30.00B` is the **first DRAM word of 63 bodies** — of the twelve reverbs, where the alignment gives it cell **0x00**, *and* of unit-0 algorithms (NO OPERATION, ENHANCER, SINGLE DELAY, MULTI TAP …), where it must take cell **0x26**. Same 36 bits, two different bases. No function of the word can produce both. | **FORCED** (MEASURED clash) |
| **C** | ★★ **R3 CANDIDATE (i) IS DEAD, TWICE.** *"`…825` in-program **is** the cursor with pre-increment"*: (1) both per-unit setup blocks load the **same** payload `0x25` and each is followed by exactly **one** consumer — and it is the **same word** `800.1.60.00B` at I-RAM 46 and 54 — so both units would get the same base; (2) **new**: the epilogue's own load is `801.0.26.825`, so the frame-entry cursor would be `0x26` and the header's four consumers would land on `0x26..0x29`, **on top of** the descriptors every one of the 79 unit-0 algorithms ships starting at exactly `0x26`. | **FALSIFIED** |
| **D** | ★★★ **CLOSURE PINS THE FRAME-ENTRY CURSOR AT `0x20`, WITH NO FREE PARAMETER**, in the surviving \|R\|=2 family: the run from the unit-1 reload to the frame boundary is reload-free, all twelve reverbs consume exactly **32** cells and the epilogue consumes **0**, so entry `= 0x00 + 32 + 0 = 0x20` in all 948 frames. And `0x20..0x25` are **the only six cells below `0x3A` that no algorithm in the ROM ever writes** — R3 candidate (iii)'s postulated slack, now derived instead of postulated. The header's 4 consumers fit inside it. | **FORCED given \|R\|=2** / the slack is **MEASURED** |
| **E** | ★★★ **THE SINGLE-RELOAD MODEL MISSES BY EXACTLY 2, AND THAT IS A TESTABLE PREDICTION.** A reload sitting between the two anchors needs `0x26 − 0x00 = n1 + e + h1`, i.e. `38 = 32 + 0 + h1` → **h1 = 6**. The R2 consumer predicate finds **4**. Six is also exactly the slack size. **Two more descriptor consumers anywhere in the epilogue or header 0..49 would resurrect a one-reload machine with no free parameter at all.** 16 header/epilogue words carry the hi12 FORMAT-ESCAPE bit without an assigned role; §3 lists them. | **FALSIFIED under the R2 predicate**, with a named resurrection |
| **F** | ★★★ **THE DIRECTION ORACLE DOES NOT EXIST — AND THIS IS THE MOST VALUABLE LINE IN THE PASS.** The plan was to score direction rules against the descriptor **values** (host pokes; no instruction field enters them) and hand `H-DIR` hundreds of rows instead of four. It scores well — **93.0 %, 62 of 74 algorithms clean**, and only **1 of 400** random labellings reaches that. **But `C-CELLPAR`, a control that never looks at the instruction at all** (label by the parity of the cell index) **scores 94.5 %, 61 clean.** Both are detecting the ladder's *alternation*. The test has power against noise and **no power to say which rule finds it**. | **FALSIFIED** (my own instrument) |
| **G** | ★★ **`DRAM-DIR` IS EXACTLY WHERE `dark-words.md` §6 LEFT IT: `H-DIR` = CONSISTENT ON FOUR ROWS.** This pass adds **zero** rows. Publishing *"H-DIR confirmed on 890 corpus words"* was one query away and would have been the fourth degenerate control in four rounds. | **CONSISTENT, 4 of 4, unchanged** |
| **H** | ★★ **A NEW MEASUREMENT THAT CONTRADICTS R3 §5.1.** Every algorithm's descriptor block was scanned for cells whose **value** is exactly its unit's region floor or ceiling: **76 of 91 ship exactly two**, 14 ship one, 1 ships three. All twelve reverbs ship **32768** (their floor) **and 32767** (one below it). R3 §5.1 states *"Nothing in the descriptor stream is a length, a mask or a wrap limit — every cell is an address."* A per-algorithm **(base, limit) pair** is the obvious reading. | **MEASURED**; the ring-bound reading is **INFERRED** |
| **I** | ★★ **THE ROTATION SIGN IS IN CONTRADICTION INSIDE THE CORPUS.** MULTI TAP DELAY's four tap cells are 6000/12000/18000/24000 (= 136/272/408/544 ms) against a line base of **0** — its reads sit **above** its write. ROOM REVERB's ladder puts R1's FORCED read on the region **floor** with its writes above — reads **below** writes. Corpus-wide, `R > W` beats `R < W` by **62 clean algorithms to 10** under the identical rule, i.e. against the sign R3 §5.1 asserts. At least one of {the alignment, H-DIR, R1's forced read slot, the rotation sign} is wrong. | **OPEN**, a live contradiction |
| **J** | ★ **THE COMB PREDICTION IS WRITTEN DOWN AND CANNOT BE RUN.** ROOM REVERB 1's descriptor file gives 16 write→read cell pairs, `D` from **110** to **8905** samples (2.5 ms .. 201.9 ms). A frame still does **not** complete (0 of 1 344 001) and all 42 DRAM slots still TRAP, so the line is never written. The test, when it can run: impulse in, **≥ 4 × 8905 = 35 620 samples** long — anything shorter amputates the longest line, which is `schroeder-topology.md` §3's published defect. | **CONDITIONAL prediction**, recorded |
| **K** | ★ **THE FRAME TALLY DOES NOT MOVE.** `dark-words.md` D asked for 108 → 133 if `DRAM-ADDR` resolved. It has not: the addressing model is now sharply constrained but the per-unit base carrier is still unnamed (§4), and `DRAM-DIR` is untouched. **Nothing is handed to the Apply agent.** | **MEASURED** |
| **L** | Housekeeping: `dsp/verify.py` **BYTE-MATCH OK**; no MAME source touched; neither disassembler mirror edited, so the 3057-word mirror diff is unaffected; DSPCFG-Off audio bit-identical *by construction*. | **MEASURED** |

---

## 1. What closure was asked, stated before it was run

Part 93's lesson is that **a reload at slot `s` defines the cursor for
everything downstream of `s`**, so closure can never say what a reload *loads*
once that reload dominates both anchors. Written down before anything was run,
closure was asked for exactly two things:

* **(a)** whether a model with **too few reloads** can hold at all — because
  then the two per-unit bases are joined by a consumption count that **varies
  over the corpus**, and a varying quantity cannot equal a constant;
* **(b)** once the reloads are fixed, the **reload-free run** from the last
  reload to the frame boundary — i.e. the frame-entry cursor, and hence exactly
  which cells the header's own consumers take.

It was **not** asked what any reload loads. It cannot answer that and it was
not allowed to try.

---

## 2. The alignment, and its phase — `dram_cursor.py align`

MEASURED over the corpus:

```
   91 algorithms ship descriptor cells
   cell index set CONTIGUOUS                        : 91 of 91
   #cells == #consumers  (R2 predicate)             : 83 of 91
   lowest cell index: unit 0 base 0x26 x79 | unit 1 base 0x00 x12
```

**The C-format question, settled by counting.** `C40.1.80.000` matches R2's
predicate (`class4 == 1` + hi12 escape bit) *and* the C-format guard, so
`dark-words.md` files it under group B while `r3-delaydram.md` counts it in
group A. Every reverb ships **32** cells and has **28** non-C-format consumers.
**`C40.1.80.000` must consume, or four cells per reverb are dead.** Excluding
the C format drops the identity from 83/91 to 75/91.

### 2.1 ★ A control of my own, caught before publication

The first version of the phase test scored a candidate phase δ by the set of
descending consecutive differences of the **cell values**. That set **does not
depend on δ at all** — δ relabels which *word* takes a cell, it does not touch
the cell sequence — so the test returned *"11 of 11 R1 delays reproduced"* for
every δ from −3 to +3. **IT COULD NOT FAIL. Withdrawn.** Method rule 1, and it
is the fourth such catch in four rounds.

The replacement pairs cells using R1's **two FORCED words**
(`880.1.60.2D4` = READ, `880.1.20.655` = WRITE; `r1_allpass_solve.py:250`,
forced 36/36 with the swap at zero), so moving δ moves the labels against the
values and the delays change sign:

```
   delta   off the shipped set    ROOM REVERB 1, R1's forced pairs
    -3          268               0 of 11 R1 delays,  7 impossible
    -2          186               7 of 11,            0 impossible
    -1          103               0 of 11,            8 impossible
    +0           20               7 of 11,            0 impossible
    +1          111               0 of 11,            8 impossible
    +2          202               7 of 11,            0 impossible
    +3          282               0 of 11,            7 impossible
```

**Read in two halves, because it is two facts.** The delay-sign column FORCES
only the **parity** of δ — −2, 0 and +2 are indistinguishable to it, and
reporting *"δ = 0 FORCED"* off that column would be the same degenerate move
again. The off-the-shipped-set column then picks **δ = 0**, at 20 against
186/202 for the two even rivals. The residual 20 are the eight algorithms whose
consumer count and cell count already disagree.

> **δ EVEN: FORCED. δ = 0: CONSISTENT and strongly favoured.**

---

## 3. ★★★ The closure test — `dram_cursor.py closure`

### 3.1 The frame, and the enumeration

```
   R0 header 0..49      h1 = 4
   R1 unit-0 body       n0 = [2,3,4,5,6,7,8,10,11,13,15,20]   (79 algorithms)
   R2 header 50..59     h2 = 1
   R3 unit-1 body       n1 = [32]                             (12 algorithms)
   R4 epilogue 60..81   e  = 0
   -> 79 x 12 = 948 distinct frames must ALL close.
```

**THE ENUMERATION, printed next to the claim (method rule 3).**

*Reload sites.* A reload cannot sit strictly **inside** a body: the body's cells
are contiguous and ascending and `#cells == #consumers`, so any reload there
would have to be a no-op. That leaves, exhaustively,

```
   R0+0 R0+1 R0+2 R0+3 R0+4 | R1+0 | R2+0 R2+1 | R3+0 | R4+0     = 10 positions
```

*Reload values.* `V-const` (one value everywhere) · `V-unit` (one value per
site) · `V-word` (a function of the reloading word's fields) · `V-ptr` (the last
value written to the `…825` pointer).

*Ring size.* `N ∈ [2, 256]` with `N > 0x39`, because GATED REVERB ships cell
`0x39` and a cursor cannot address it in a smaller ring.

### 3.2 |R| = 0 — no reload

```
   survivors: NONE of the 199 ring sizes
   CONTROL (must be able to say YES): drop the two anchors, keep only
   closure on one frame -> survivors [3, 13, 39]
```

### 3.3 |R| = 1 — one reload, exhaustive over site × value × N

```
   survivors: NONE
```

and in closed form, which is what makes it a *theorem* rather than a search
result. Write `x`, `y` for the consumers passed from the reload forward to each
anchor.

* A reload **upstream of both anchors** gives `y − x = n0 + h2`, so
  `N | (0x26 + n0 + h2)`. Over the 79 unit-0 algorithms that is
  `N | {41,42,43,44,45,46,47,49,50,52,54,59}` → **gcd = 1**. Dead.
* A reload **between the anchors** gives `x − y = n1 + e + h1`, which does not
  contain `n0` and so survives the varying-`n0` argument. It requires
  `0x26 − 0x00 = n1 + e + h1`, i.e. `38 = 32 + 0 + 4 = 36` → `N | 2`. Dead.

### 3.4 ★ The sharpest number in the pass: it misses by exactly 2

The single-reload machine would hold **for every ring size and with no free
parameter at all** if

```
   h1 + e  =  0x26 - n1  =  38 - 32  =  6
```

descriptor consumers sat between the epilogue's reload point and the unit-0
body. The R2 predicate finds `h1 + e = 4`. **Six is also exactly the size of the
slack `0x20..0x25` that no algorithm in the ROM ever writes** (§3.6). So the
single-reload model is FALSIFIED *under the R2 consumer predicate*, and would be
**resurrected exactly by finding two more consumers** in the header or the
epilogue.

The candidates — header/epilogue words carrying the hi12 FORMAT-ESCAPE bit but
**not** `class4 == 1`, with no assigned role (16 of 26; the other 10 are the
`…821`/`…825`/`…827` pointer loads and the two host-patched `setvec`s):

```
   I-RAM  1 C0A.0.E0.000   I-RAM 15 C0A.2.92.820   I-RAM 22 C04.3.12.820
   I-RAM 29 C42.4.57.820   I-RAM 31 C0A.4.B1.820   I-RAM 38 809.0.00.839
   I-RAM 47 800.8.0C.000   I-RAM 48 C64.5.A2.000   I-RAM 56 C64.6.A2.007
   I-RAM 67 980.5.20.402   I-RAM 73 E30.C.00.404   I-RAM 74 C16.9.AB.000
   I-RAM 75 82E.8.0F.000   I-RAM 76 C00.9.84.000   I-RAM 77 859.0.86.822
   I-RAM 78 A3C.D.9F.287
```

**PREDICTION.** Exactly two of those are delay-DRAM accesses. It is the cheapest
test left on this family and it is handed to the round that decodes the C format
and the mode-1 space — five of the sixteen are C-format words and four are in
the epilogue, i.e. **both sibling agents are sitting on it.**

**And one consumer is already forced into the header**: `880.1.20.2D5` occurs 24
times in bodies — twice in every reverb — and dropping it breaks the reverbs'
32-cells/32-consumers identity. It is also **I-RAM 12**. So the header really
does touch delay memory, and the `0x20..0x25` slack really is addressed by
something.

### 3.5 `V-word` and `V-ptr` — both FALSIFIED

The body's **first** consumer, and the cell the alignment gives it:

```
   880.1.30.000  x2    ->  {0x26}
   880.1.30.00B  x63   ->  {0x00, 0x26}      *** CLASH ***
   880.1.30.407  x6    ->  {0x26}
   880.1.30.447  x1    ->  {0x26}
   880.1.30.8BC  x18   ->  {0x26}
   880.1.60.00B  x1    ->  {0x26}
```

`880.1.30.00B` is the first DRAM word of the twelve reverbs (cell `0x00`) **and**
of NO OPERATION / ENHANCER / SINGLE DELAY / MULTI TAP … (cell `0x26`). Identical
36 bits, two bases. **`V-word` FALSIFIED — item B.**

`V-ptr` — R3 candidate (i) — is refuted twice, and the second refutation is new:

```
   I-RAM 44  801.0.25.825   payload 0x25   unit-0 setup
   I-RAM 52  801.0.25.825   payload 0x25   unit-1 setup
   I-RAM 62  801.0.26.825   payload 0x26   EPILOGUE     <- the new one
```

See item C.

### 3.6 |R| = 2, `V-unit` — what survives, and what closure then fixes

Both anchors are now defined by their own reload, so **closure cannot speak to
the values**. Stated before the result, as the brief requires. What it *does* fix:

```
   frame-entry cursor = base(unit1) + n1 + e = 0x00 + 32 + 0 = 0x20
   ... the same value in all 948 frames, because all 12 reverbs ship n1 = 32.

   unwritten cells in [0x20, 0x26)      : 0x20 0x21 0x22 0x23 0x24 0x25
   total unwritten cells below 0x3A     : 0x20 0x21 0x22 0x23 0x24 0x25
```

**The slack is not postulated any more — it is where the reload-free run lands,
and it is the only gap in the whole file.** The header's four consumers fit:

```
   I-RAM 12  880.1.20.2D5  -> cell 0x20
   I-RAM 26  880.1.20.40B  -> cell 0x21
   I-RAM 40  C4A.1.C0.820  -> cell 0x22
   I-RAM 46  800.1.60.00B  -> cell 0x23
```

**★ And the one word that does not fit — reported, not smoothed over.** I-RAM 54
(`800.1.60.00B`) sits after the unit-0 body and before the unit-1 reload, so it
takes cell `0x26 + n0`: with unit-0 = GATED REVERB that is `0x3A`, past the
corpus maximum, and for every other unit-0 algorithm it is one cell past that
algorithm's own allocation. Two ways out: **(a)** `800.1.60.00B` consumes
nothing — and then so does I-RAM 46, because it is the same word, dropping `h1`
to 3; or **(b)** the unit-1 reload sits at or before I-RAM 54, which costs the
reverb its 32/32 identity. **(a) is the survivor. CONSISTENT, not forced.**

---

## 4. The per-unit base — `dram_cursor.py carrier`

Closure forces the base to be per-unit state (item B). The two setup blocks are
the only place the frame distinguishes the units before the body runs:

```
   I-RAM 42 801.0.70.821      I-RAM 50 801.0.50.821
   I-RAM 43 801.0.6C.827      I-RAM 51 801.0.64.827
   I-RAM 44 801.0.25.825      I-RAM 52 801.0.25.825
   I-RAM 45 010.A.00.20C      I-RAM 53 010.9.D0.20C
   I-RAM 46 800.1.60.00B      I-RAM 54 800.1.60.00B
   I-RAM 47 800.8.0C.000      I-RAM 55 000.2.01.007
   I-RAM 48 C64.5.A2.000      I-RAM 56 C64.6.A2.007
   I-RAM 49 400.1.0E.000      I-RAM 57 000.2.01.000
                              I-RAM 58 000.1.8A.007
                              I-RAM 59 400.1.0F.007
```

Fourteen fields differ. Every one is put through **every integer affine map**
over a mask/shift family, solved exactly rather than enumerated:

```
   |scale| <= 8 maps onto {0x26, 0x00} : 0 of 14 carriers
   CONTROL, same solver, reachable targets:
      {0x05, 0x85} the FORCED D-RAM operand bases : 10 of 14
      {0x70, 0x50} the C-RAM payloads themselves  :  8 of 14
```

★ **And a methodological correction to `blocking-read.md` item J.** That search
enumerated the scale over a small range. Any carrier whose two payloads differ
by ±1 — `class4` `0x0A`/`0x09`, the CALL tags `0x0E`/`0x0F` — is solved by
`k = ±38` and a bounded-scale search would have reported a **dishonest NONE** for
those rows. Item J's *conclusion* stands (its carrier, `0x827`, has Δ = 8 and
admits no small-scale map either) but its *method* would not have detected a
±1 carrier. Both columns are now printed.

**The 1-bit CALL tag is a selector wearing an affine map's clothes.** It can
index a two-entry table of hardwired bases and no search can refute that. It is
**CONSISTENT and it is not evidence.** `DRAM-ADDR`'s base carrier remains
**OPEN**.

---

## 5. ★★★ Direction — the oracle that does not exist

### 5.1 The plan, and why it looked sound

Under R3 §5.1's global rotation, a read at cell `R` returns data written at cell
`W`, so the **cell values** constrain read-vs-write. The values are host pokes —
no instruction field enters them. `dark-words.md` §6 scores `H-DIR` on **four**
rows; this promised hundreds.

Scoring is symmetric by construction: **both** rotation signs are scored, and a
read counts as matched if **any** write cell of the same algorithm sits on the
correct side of it — never "the nearest", because which `W` serves which `R` is
exactly what is unknown. The two boundary cells (§6) are excluded.

```
   rule                                            R<W (R3 5.1 sign)   R>W
   H-DIR-W   SRC 0x0B => READ, everything else W    71.7%  10/74    93.0%  62/74
   H-DIR-R   ... but SRC 0x00 is a READ too         82.8%  10/74    67.5%  13/74
   H-SRC19   SRC 0x19 => WRITE, everything else R   82.3%   0/64    65.8%   0/64
   H-ADDR8   addr8 in {0x30,0x60} => READ           78.9%   0/74    61.2%   1/74
   H-HI7     hi12 bit 7 => WRITE                    87.0%  14/23   100.0%  23/23
   H-ACT     ACTION in {0x14,0x15} => READ          87.6%   4/24    98.0%  19/24
   C-INV     H-DIR-W INVERTED  (** degenerate **)   87.5%  53/74    58.5%   5/74
   C-CELLPAR label by CELL PARITY (word-blind)      76.0%   0/74    94.5%  61/74
   C-LOW     label by lo12 bit 0 (nonsense)         62.9%   3/75    75.3%  12/75
```

### 5.2 Two things that must be said before that table is read

**(1) `C-INV` is degenerate with reading the other column.** Inverting every
label and flipping the convention is very nearly the same machine — which is
why `C-INV`'s `R<W` number sits next to `H-DIR-W`'s `R>W` number. **Method rule
4.** It is not a control here, it is a restatement, and it is labelled as one.
The residual gap (62 vs 53 clean) comes only from the boundary exclusion and the
"any partner" quantifier, and **nothing is hung on it**.

**(2) `C-CELLPAR` is the control that earns its keep.** It knows nothing
whatever about the instruction — it labels by the parity of the *cell index*.

### 5.3 ★★★ The randomised null, and the result

400 random labellings, same number of reads per algorithm as `H-DIR-W`, same
convention, same exclusions:

```
   clean algorithms : min 39   median 50   max 64
   reads matched    : min 80.0%  median 87.0%  max 94.3%
   H-DIR-W          : clean 62, matched 93.0%
   random runs reaching H-DIR-W's clean count: 1 of 400
```

**In two halves, because it is two facts:**

* the test **has** power against noise — 1 of 400. The descriptor values really
  do carry read/write structure;
* the test has **no** power to say **which rule** finds it. `C-CELLPAR`, which
  never looks at the instruction, lands in the same tail (**94.5 %, 61 clean**
  against **93.0 %, 62**). What both detect is the ladder's **alternation**, and
  `H-DIR` agrees with the alternation almost everywhere.

> **THEREFORE: the descriptor values are NOT a direction oracle. The thing this
> section was built to be does not exist. `DRAM-DIR` stays OPEN; `H-DIR` keeps
> exactly the four rows `dark-words.md` §6 gave it and this pass adds NONE.**

Publishing *"H-DIR confirmed on 890 corpus words"* was **one query away**.

### 5.4 What the values do say about `SRC 0x00`

`H-DIR-W` and `H-DIR-R` differ **only** in whether `SRC 0x00` is a read.
`H-DIR-R` lands at **13** clean algorithms, *below* the random null's median of
~50 — so on this test `SRC 0x00 = the delay-RAM read` is **worse than chance**,
which agrees in sign with `blocking-read.md` item F. But the same test cannot
tell `H-DIR-W` from a word-blind rule, so this is a **weak fourth vote**,
recorded as CONSISTENT and **not** as a determination. Nothing applied.

---

## 6. ★★ A new measurement: the boundary cells, and R3 §5.1

Every algorithm's descriptor block scanned for cells whose **value** is exactly
its unit's region floor or ceiling:

```
   boundary-valued cells per algorithm : {1: 14, 2: 76, 3: 1}
   which boundary                      : floor 79, ceiling 78, floor-1 12
   -> 76 of 91 algorithms ship EXACTLY TWO
```

All twelve reverbs ship **32768** (their floor) **and 32767** (one below it).
SINGLE DELAY ships `0` and `32768`; MULTI TAP ships `32768` and `0`; CHORUS ships
`0` and `32768`.

`r3-delaydram.md` §5.1: *"Nothing in the descriptor stream is a length, a mask or
a wrap limit — every cell is an address, and the delays are differences."* A
per-algorithm **(base, limit) pair** is the obvious reading of 76-of-91-ship-
exactly-two, and it is not an address pair. **MEASURED; the ring-bound
interpretation is INFERRED and filed as a falsification *candidate* for R3 §5.1,
not as a decode.**

### 6.1 ★ And the rotation sign is in contradiction

```
   --- MULTI TAP DELAY (algo 10) ---
      cell 0x26 =   6000  880.1.30.00B  SRC 0x00  write
      cell 0x27 =  32685  880.1.60.000  SRC 0x00  write
      cell 0x28 =  12000  880.1.20.2C7  SRC 0x0B  READ
      cell 0x29 =  18000  880.1.20.2C7  SRC 0x0B  READ
      cell 0x2A =  24000  880.1.20.2C7  SRC 0x0B  READ
      cell 0x2B =  32768  880.1.20.2C7  SRC 0x0B  READ   <- boundary cell
      cell 0x2C =      0  880.1.60.000  SRC 0x00  write  <- boundary cell

   --- ROOM REVERB 1 (algo 16) ---
      cell 0x03 =  32768  880.1.60.2D4  SRC 0x0B  READ   <- boundary cell, and
                                                            R1's FORCED read
      cell 0x04 =  41845  880.1.20.655  SRC 0x19  write
```

MULTI TAP's tap cells `6000/12000/18000/24000` are `136/272/408/544 ms` against a
line base of **0** — reads **above** the write. ROOM REVERB puts R1's FORCED read
on the region **floor** with every write above it — reads **below**. **They cannot
both hold under one rotation sign.** Corpus-wide `R > W` wins 62 clean to 10,
i.e. against the sign R3 §5.1 asserts. At least one of {the alignment, `H-DIR`,
R1's forced read slot, the rotation sign} is wrong. **OPEN, and it is the next
experiment on this family.**

---

## 7. The comb prediction — `dram_cursor.py comb`

**The label on these numbers.** The *differences* are MEASURED. Calling them
*delays* needs (a) the alignment (§2, δ = 0, CONSISTENT), (b) a direction rule
(§5, unimproved) and (c) the rotation sign (§6.1, contradictory). So: **MEASURED
differences, CONDITIONAL delays.** Printed because a refutable wrong prediction
is worth more than none.

ROOM REVERB 1, 16 write→read cell pairs:

```
   0x02->0x03  D=8905 (201.93 ms)   0x04->0x05  D= 255 ( 5.78 ms)
   0x06->0x07  D= 528 ( 11.97 ms)   0x08->0x09  D= 869 (19.71 ms)
   0x0A->0x0B  D=1252 ( 28.39 ms)   0x0C->0x0D  D= 979 (22.20 ms)
   0x0E->0x0F  D= 359 (  8.14 ms)   0x10->0x11  D= 366 ( 8.30 ms)
   0x12->0x13  D= 675 ( 15.31 ms)   0x14->0x15  D=1044 (23.67 ms)
   0x16->0x17  D= 976 ( 22.13 ms)   0x18->0x1B  D= 110 ( 2.49 ms)
   0x19->0x1B  D= 544 ( 12.34 ms)   0x1A->0x1B  D=1085 (24.60 ms)
   0x1C->0x1E  D= 976 ( 22.13 ms)   0x1D->0x1E  D=1083 (24.56 ms)
```

Two structural facts fall out and neither was expected: the **tail section**
`0x18..0x1F` is two output taps (cells `0x1B` and `0x1E`) each served by **two or
three** write cells — a multi-tap output stage, not a ladder stage — and the
ladder proper is **eleven** stages, R1's two interleaved chains
(`[255,869,979,366,1044]` and `[8905,528,1252,359,675,976]`) reproduced **to the
LSB R1's `raw24` reading discarded**.

**THE TEST, and why it cannot run.** A frame does not COMPLETE — 0 of
1 344 001 — and all 42 delay-DRAM slots still TRAP, so the line is never written
and there is no echo train to measure. When the family executes: impulse in,
capture out, **and the excitation must be at least `4 × 8905 = 35 620` samples
(0.81 s)**. `schroeder-topology.md` §3's published defect was a 64-sample test
against a 127-sample shortest line; the number to beat here is the **longest**
line, not the shortest.

---

## 8. PREDICT-THEN-CHECK — hits and misses, at equal prominence

| # | prediction, written before the experiment | result |
|---|---|---|
| P1 | closure kills R3 candidate **(iii)** outright, as the brief suggested it might | ★ **MISS, and backwards.** (iii) is the *only* family left standing, and closure **derives** its postulated `0x20..0x25` slack instead of assuming it (item D). What closure killed was candidate **(i)**. |
| P2 | the descriptor cursor free-runs and closes mod `N` | ★ **MISS.** 0 survivors at \|R\|=0 *and* \|R\|=1, over 948 frames. §3.2–3.3 |
| P3 | the per-unit base is carried by `801.0.PP.827` or `801.0.PP.821` | **MISS**, and it was already half-known: 0 of 14 carriers admit a small-scale affine map. §4 |
| P4 | the reload value is a field of the reloading word | ★ **MISS, and this one is a theorem.** `880.1.30.00B` is body-word-0 of both a unit-1 body (cell `0x00`) and of 51 unit-0 bodies (cell `0x26`). Item B. |
| P5 | the cell values give `H-DIR` hundreds of rows and settle `DRAM-DIR` | ★★★ **THE BIG MISS. The instrument does not work.** A word-blind control scores as well as the rule. §5.3. This was the pass's headline experiment and its failure is its most valuable output. |
| P6 | R1's forced read/write pair and R3's cell alignment agree everywhere | ★ **MISS.** They agree in ROOM REVERB and disagree in MULTI TAP: the two demand **opposite rotation signs**. §6.1 |
| P7 | the phase δ is settled by the delay-sign test | ★ **MISS, caught before publication twice over.** The first version of the test could not fail at all (§2.1); the second fixes only the **parity** of δ. |
| P8 | descriptor cells are all addresses (R3 §5.1) | ★ **MISS.** 76 of 91 algorithms ship exactly two cells holding a region boundary exactly. §6 |
| P9 | the frame tally moves 108 → 133 | **MISS.** Nothing is FORCED outside a model class, so nothing is applied and the tally is unchanged. Item K. |
| P10 | closure fixes the frame-entry cursor with no free parameter | ★ **HIT.** `0x20`, identical in all 948 frames, and it coincides with the only gap in the descriptor file. Item D. |
| P11 | a single reload per frame is possible | **HIT on the arithmetic, MISS on the answer**: it is possible *iff* `h1 + e = 6`, and the measured value is 4. The miss-by-2 is the most actionable number in the pass. §3.4 |

**Nine of eleven are misses, one is a hit, one is half of each.** Four of the
misses (P5, P6, P7, P8) are corrections to instruments or to published claims,
which is what the brief asks the misses to be — and P5 is a correction to the
instrument this pass was built around.

---

## 9. What this hands the other agents

* **To the bit-7 store-gate agent.** `dark-words.md` §6's `H-DIR` is *unchanged*
  by this pass — do not treat it as strengthened. And `SRC 0x00` gets a fourth,
  **weak** vote against being the delay-RAM read (§5.4); it does not close the
  question and `action00-discriminator.md` §0-H's run-time-coefficient caveat is
  untouched.
* **To the C-format / register-space agent — this one is direct and cheap.**
  §3.4 predicts that **exactly two** header/epilogue words are delay-DRAM
  accesses that the R2 predicate misses. **Nine of the sixteen candidates are
  C-format** (`C0A.0.E0.000`, `C0A.2.92.820`, `C04.3.12.820`, `C42.4.57.820`,
  `C0A.4.B1.820`, `C64.5.A2.000`, `C64.6.A2.007`, `C16.9.AB.000`,
  `C00.9.84.000`) and **seven are in the epilogue** (`980.5.20.402`,
  `E30.C.00.404`, `C16.9.AB.000`, `82E.8.0F.000`, `C00.9.84.000`,
  `859.0.86.822`, `A3C.D.9F.287`). Deciding any of those decides whether the descriptor cursor is
  reloaded **once** per frame or **twice**, which is the whole shape of
  `DRAM-ADDR`.
* **To whoever next touches `r3-delaydram.md`.** Two of its statements are now
  in tension with the corpus: §5.1's *"no length, mask or wrap limit"* (§6 here)
  and §5.1's rotation **sign** (§6.1 here). Neither is asserted false; both are
  filed as falsification candidates with the measurement attached.
* **To the Apply agent.** **Nothing.** No result in this note is FORCED outside
  a model class, so the 42 words keep trapping and the device is unchanged.

---

## 10. Files

* `dsp/tools/dram_cursor.py` — regenerates every number above.
* `dsp/analysis/dram-cursor-closure.md` — this note.
* Unchanged and verified: `dsp/verify.py` **BYTE-MATCH OK**;
  `src/devices/cpu/upd6383/upd6383d.cpp` and `dsp/tools/dsp_disasm.py` not
  touched, so the 3057-word mirror agreement is unaffected;
  `kn7000_mame/src/` clean.
