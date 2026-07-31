# CORPUS PATTERNS, ROUND 2 — the MACRO CELL-MAP census

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). **Static ROM-corpus analysis
only** — no MAME source was read or written, nothing was built, nothing was run,
no hardware. Read-only pass; one new file; nothing committed.

> ⚠ **GENERATIVE PASS, NOT A VERIFICATION PASS.** Every *count* here is
> **MEASURED**; every *reading* of a count is **SPECULATIVE** and is labelled at
> the point of use. **RULE 19 is respected by vacuity: this pass produces no
> audio quantity of any kind and makes no audio claim.**

---

## 0. Method, population, and the one instrument this pass deliberately did NOT build

### 0.1 Population — unchanged from round 1, restated once

38 distinct IC311 body images = **2974** words; KERNEL 60; EPILOGUE 23; corpus
**3057**; PLAIN body words (not C-format, `lo12` bit 11 clear) **2837**. The five
IC310/MN19413 streams `{79, 88, 89, 90, 91}` are **EXCLUDED**
(`pat_corpus.MALFORMED`). The twelve stub effects collapse into `a00` before
measurement and contribute **zero distinct images**. Loader `dsp/tools/pat_corpus.py`.
`SRC = lo12[10:6]`, `ACT = lo12[4:0]` (RULE 18). All three reproduced exactly.

### 0.2 ★ THE INSTRUMENT — a static D-RAM operand-address machine, and its four controls

Everything new in this note comes from **one** derived quantity: the **static
D-RAM cell each word addresses**.

```
   offset(word i) = SUM over j < i of (s8)addr8(j)   for j a mode-2 word
   cell           = (ENTRY + offset) mod 256          ENTRY = 0x05 / 0x85
```

Two MEASURED rules and nothing else: `ptr_postinc` = `class4 & 7 == 2`
(`instruction-set.md`), and **the operand is fetched BEFORE the word's own
post-increment** (the brief's pre-increment trap; `IW205-DRAM-D0_findings.md`).

★ **The machine is validated against four known answers before anything is
claimed. All four come out, and one of them caught a real defect in my own code.**

| # | known answer | source of record | blind result |
|---|---|---|---|
| C-1 | `lo12 0x1CD` = the body's INPUT PICKUP at **base+0, 38 of 38** | `IW205-DRAM-D0_findings.md` | **38/38** — but only after wrapping mod 256: `a16 ROOM REVERB 1`'s pickup sits at raw offset **−256**, which is IW205's own "one full D-RAM wrap". Un-wrapped I got 37/38 |
| C-2 | the state block sits at **ENTRY+75** = cell `0x50` | `output-stage-decode.md` §3 | the biquad section's base lands on **+75 in 12 of the 12** images that carry one |
| C-3 | **PARAMETRIC EQ `w058` is the corpus's only in-body `rstcur`** | `bit11-family.md` §9.1, `r2-output.md` | ⚠ **my first transcription of `is_regload` found ZERO.** `lo_sel` is `lo12 & 0xFF`, not `(lo12>>5) & 0x7F`. Corrected → **1 of 1**, at `a39 w058 = 801.0.00.021` |
| C-4 | the **9-word biquad's S0..S3 cell walk**, graded **PROVEN** | `algorithms/biquad-eq.md` | reproduced **exactly**, 33/33 — see §0.4, where it is **dropped as prior art** |

⚠ **C-3 is the detector self-test the brief demanded, and it failed first.** A
census that silently reports "0 of 3057" is indistinguishable from a correct
negative. It was caught only because a known answer existed.

### 0.3 ⛔ THE INSTRUMENT THIS PASS DID **NOT** BUILD

`ROADMAP-2026-07-29.md` **R3** records the static def-use / D-RAM cell-liveness
instrument over the FORCED pointer walk as a **cannot-fail instrument that must
never be rebuilt** (control base rate 43.2 %; `SRC 0x07` 38.2 %; `SRC 0x10`
42.8 % — two anchored codes with opposite semantics separated neither from each
other nor from the null). **It was not rebuilt, and no item here decides any
`SRC` code.**

★ **And this pass supplies R3 with an independent confirmation it did not have.**
Over all **374** mode-2 `ACT 0x07` writes, the fraction whose cell is touched
again later by any mode-2 word is **166/374 = 44.4 %** — sitting on R3's 43.2 %
control base rate. **N-1 below.** The distinction that makes the rest of this
note legitimate is:

> ⛔ a **program-wide** read/write liveness statistic is at the null and is dead.
> ★ a **within-macro RELATIVE cell map** is a different object: it is
> exceptionless per macro, it uses no base-rate comparison, and it decides
> *addresses*, never `SRC` semantics.

Also not touched: the output-stage null (a separate pass owns it); `f31 = 4/5`;
the bit-11 ALU route (dead end 15); `ACT 0x15` as a no-op gate (dead end 11);
dead end 16 — **every SRC/ACT statistic here is over PLAIN words only**.

### 0.4 ★ WHAT THIS PASS FOUND AND THEN DELETED AS PRIOR ART

Each of these was computed here, found, and struck on discovering the owner.
**Reporting them is a result.**

1. ★★★ **The 9-word biquad's per-slot D-RAM cell assignment.** My census gave
   `S0 = base+0, S1 = base+1, S2 = base+2, S3 = base+3` with reads at
   `+0,+1,+2,+3` and writes `S0 ← acc` (bit-4 store), `S3 ← tempB`, `S2 ← acc`,
   `S1 ← tempA` — **33 of 33 sections, 12 images, exceptionless**, using only
   ANCHORED codes. **`algorithms/biquad-eq.md` already owns all of it**, word for
   word, grades the cell walk **PROVEN**, and names `212.A.01.412` and
   `212.A.FF.407` as the two folded state writes. **DELETED as a finding and
   promoted to control C-4.** It is the reason the machine can be trusted.
2. `182.2.**.407` is the writer of the cell the `C63` word reads — **`data/SPECULATIVE_PATTERNS.md` SP1** owns it (from the `addr8 = 0x00` argument at
   CHORUS `w29`). T-1 below extends it to the *read-back*; SP1 keeps priority.
3. The **C-RAM coefficient-index machine** — already implemented as
   `dsp_disasm.cursor_addresses()`; the map is `k4-cursor.md`'s. My re-derivation
   agrees (max unit-0 index **0 of 37** images exceeds the host's largest written
   cell `0x2C`, once the `rstcur` is honoured). No claim made.
4. `rstcur` occurs **once in 3057 words** — `r2-output.md`, `bit11-family.md` §9.1.
5. `lo12 0x1CD` at base+0, 38/38 — `IW205-DRAM-D0_findings.md`.
6. The LFO **phase cell Q is selected by address**, with the per-image offsets —
   `lfo-ramp.md`, graded **FORCED**.
7. "written and never read" is common — **21 of 38 bodies, 32 cells** —
   `r2-output.md`. This is why no item here reads anything into an unread write.
8. The **62 / 41 nop-guard split** and its 46.3 % bit-4-STORE successor rate —
   `NOP-GUARD_findings.md`. Only the *cell* view is added, as N-2 (a negative).
9. `addr8 = 0xEE`, the per-body net displacement distribution, the CHORUS
   7-word voice macro, the COMPRESSOR 5-word block, the class-6 selector
   accounting — **`data/SPECULATIVE_PATTERNS.md`** §§3, 6, 8, 9.
10. The biquad's **+4 per section = 4 DF-I state words** and the host's 40-cell
    fill `0x50..0x77` — `k3-pointers.md` item I, `instruction-set.md`, SP12.

---

## 1. THE RANKED INVENTORY — ranked by testability × payoff

**Null used throughout for cell-coincidence claims.** Over the 374 mode-2
`ACT 0x07` writes, a mode-2 word **4 slots later** addresses the same cell in
**23 of 374 = 6.1 %**. That empirical rate is the null for T-1 and T-2 and is
conservative (it is measured on the same corpus, not assumed uniform).

---

### ★★★ T-1 — THE TABLE-LOOKUP MACRO IS CELL-CLOSED: it writes a scratch cell and reads the SAME cell back, 21 of 21 — and the other 25 sites have NO writer at all

**MEASURED.** The 5-word table-lookup macro, `addr8` masked:

```
   slot                                       static D-RAM cell
    0  182.2.**.407   SRC 0x10 (acc) / ACT 0x07  -> mem[ptr]     base+0   WRITE
    1  040.0.**.C63   bit-11 word, mode 0                        (no pointer access)
    2  000.6.**.4CD   mode 6, table selector                     (no pointer access)
    3  012.4.**.1CE   mode 4                                     (no pointer access)  ST
    4  104.2.**.1CE   SRC 0x07 (mem[ptr]) / ACT 0x0E             base+0   READ BACK
```

* **21 instances in 12 images. The cell written at slot 0 and the cell read at
  slot 4 are the SAME cell in 21 of 21.**
* The absolute cell, per image — **and it independently reproduces §168's own
  number**:

```
   CHORUS 0x0C · MODULATED CHORUS 0x0C, 0x05 · PHASER 0x0E, 0x08 · ENSEMBLE 0x13
   MIX UP 0x0D, 0x0F, 0x10 · S.DELAY+CHORUS 0x0C · S.DELAY+FLANGER 0x0E, 0x14
   S.DELAY+VIBRATO 0x0D, 0x13 · S.DELAY+PHASER 0x0E, 0x08 · PEQ+CHORUS 0x0C
   PEQ+FLANGER 0x0E, 0x14 · PEQ+VIBRATO 0x0D, 0x13
```

★ §168 reported *"`C63` reads cell `0x0C`"* from the emulator. **The static
machine says CHORUS's macro is closed on cell `0x0C` — from the ROM alone, with
no run.**

* ★★ **AND THE POPULATION SPLITS EXCEPTIONLESSLY.** Over all **46 non-chained
  lookup sites in 25 images**, the word at −1 is:

```
   182.2.00.407   21   SRC 0x10 / ACT 0x07  = a mode-2 WRITE  -> the macro CLOSES, 21 of 21
   182.2.**.000   25   SRC 0x00 / ACT 0x00  = NOT a write     -> no producer in the macro
```

  **21 + 25 = 46, no third case.** `data/SPECULATIVE_PATTERNS.md` §3.1 already
  measured the 21/25 split on the `−1` word; **what is new is that the 21 are
  exactly the sites whose scratch cell is closed, and that the 25 have no
  producer for the cell their own lookup reads back.**

**Population** 21 of 21 closing / 46 sites / 25 images. **Denominator** null
6.1 % ⇒ `P(21/21) ≈ 10⁻²⁵·⁷`. **Strength: the strongest item in the note** — it
is an exceptionless address identity, not a correlation, and it is derived from
two MEASURED addressing rules with no ALU assumption.

**SPECULATIVE reading.** The macro is *"deposit the index in a scratch cell →
look up → read the result back from that cell"*, i.e. the class-0/6/4 words
address memory **through the pointer** and the scratch cell is the lookup's
argument-and-result slot. Under that reading the 25 producerless sites read a
cell **the macro itself never writes** — they must be fed from outside, or they
are reading stale state.

**Proposed cheap test.** Instrument `a56 MIX UP`, which carries **three** closed
sites at three different cells (`0x0D`, `0x0F`, `0x10`) in one image. Log the
value written at slot 0 and the value read at slot 4 of each. **P1:** they are
the same datum (possibly transformed). **Arm 2:** the read at slot 4 returns
something unrelated to the write ⇒ the class-0/6/4 words do not address that cell
and the closure is layout, not dataflow — which is the bigger result. **Control
that can fail:** any of the 25 open sites must show the slot-4 read with no
preceding write in the macro; a probe that fires identically at both populations
is measuring code density, not memory (`three-codes.md` §5's dead end).

⚠ **Defers to SP1** for the write half and to §166 for the `C63` ↔ class-6
bijection. Neither is re-claimed. ⛔ No claim is made about `ACT 0x15`
(dead end 11) or about the bit-11 words' encoding (dead end 15).

---

### ★★★ T-2 — THE CHORUS VOICE MACRO IS ALSO CELL-CLOSED, 29 of 29 — and this EXPLAINS round 1's S-5 band

**MEASURED.** The 7-word CHORUS voice macro (`data/SPECULATIVE_PATTERNS.md` §3.3
owns the macro; the cell map is new):

```
   slot                                          static D-RAM cell
    0  900.1.**.1D5   delay-DRAM (mode 1)          (no pointer access)
    1  192.A.**.000   SRC 0x00 / ACT 0x00          base+0
    2  082.2.**.1C0   SRC 0x07 / ACT 0x00          base+K     <- the LFO phase read
    3  C40.3.**.44C   C-format immediate           (no pointer access)
    4  A00.0.**.041   DARK (SRC 0x01 / ACT 0x01)   (no pointer access)
    5  880.1.**.2C7   delay-DRAM READ              (no pointer access)
    6  102.A.**.4C8   SRC 0x13 (table port)/ACT 08 base+K     <- SAME CELL as slot 2
```

**Slot 2 and slot 6 address the same D-RAM cell in 29 of 29 instances, 10
images.** `K` ranges over `+60 … +91`; the absolute cells are
`0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x58, 0x59, 0x5A, 0x5B, 0x61` — **every one
inside the per-unit STATE BLOCK at ENTRY+75** (`output-stage-decode.md` §3).

★★ **This graduates round 1's S-5.** S-5 measured the third word's displacement
as a *tight negative band* `[−99, −61]` at 35 of 35 and proposed it was "the
distance back to the tap's own coefficient block". **It is not a coefficient
distance — it is the return path that lands the pointer back on the cell slot 2
read.** S-5's band is the arithmetic of this closure. Its *count* survives; its
proposed reading is superseded.

**Population** 29/29, 10 images. **Denominator** same 6.1 % null at distance 4 ⇒
`P ≈ 10⁻³⁵`. **Strength: very strong**, and it costs nothing that round 1's S-5
did not already pay for.

**Proposed cheap test — free, static, and it can fail.** Check the 11 absolute
cells against the host's per-algorithm tag-`0x15` zero-fill for those 10
algorithms (`register-space.md` E1: 881 writes over 65 cells). **P1:** all 11
lie inside the fill. **Falsifier:** any lies outside ⇒ the voice reads state the
host never clears, and "private per-voice phase cell" dies. Then, live: one run
on `a01 CHORUS` logging that one cell across the four voices.

---

### ★★ T-3 — THE REVERB ALL-PASS MOTIF IS A ONE-CELL MOTIF: all four of its pointer words address a SINGLE cell, 15 of 15

**MEASURED.** The 6-word all-pass motif (`r1-allpass-motif.md` owns the algebra
and the polarity; the cell map is new):

```
   0  880.1.**.2D4   delay-DRAM        (no pointer access)
   1  104.2.**.000   SRC 0x00/ACT 0x00   base+0
   2  000.2.**.419   SRC 0x10/ACT 0x19   base+0
   3  012.2.**.680   SRC 0x1A/ACT 0x00   base+0   ST
   4  880.1.**.655   delay-DRAM        (no pointer access)
   5  102.A.**.64B   SRC 0x19/ACT 0x0B   base+0
```

**All four mode-2 words sit at the same offset in 15 of 15 instances** (2 images:
`a16 ROOM REVERB 1` ×9, `a08 GATED REVERB` ×6). The five distinct absolute cells
are `0x14, 0x50, 0x8B, 0x94, 0xD1`.

**SPECULATIVE reading.** The all-pass stage owns **exactly one** D-RAM word of
private state; its delay memory is entirely in the **external** delay DRAM (slots
0 and 4). ⇒ a core that traps the two delay-DRAM words has lost the whole tank
and retained only a scalar. This sharpens SP12's *"all-pass stages net 0 (state
addressed as offsets from a fixed base)"* from "net zero" to **"one cell, and
here is which"**.

**Population** 15/15, 2 images — ⚠ **honest limit: only two images carry it**, so
portability is not demonstrated and this is deliberately ranked below T-1/T-2.
**Proposed cheap test — free, static:** 15 instances over 5 cells means stages
**share** cells; list which stages share which, and check the sharing pattern
against `dram-datapath.md` C's 12-line accounting. A stage sharing a cell with a
non-adjacent stage would refute "private state".

---

### ★★ T-4 — THE COMPRESSOR-FAMILY 4-WORD BLOCK IS A SAME-CELL READ-MODIFY-WRITE ON HOST-WRITTEN CELLS `0x07` / `0x08`

**MEASURED.** A 4-word macro, every word on the **same** cell, 12 instances /
8 images:

```
   0  018.A.**.1D5   SRC 0x07 / ACT 0x15   base+0   ST
   1  104.A.**.1D5   SRC 0x07 / ACT 0x15   base+0
   2  C40.2.**.000   C-format immediate     base+0
   3  182.A.**.000   SRC 0x00 / ACT 0x00   base+0
  [4  000.2.**.447   SRC 0x11 / ACT 0x07   base+0   -- the 5-word form, 6 instances / 5 images]
```

```
   cell 0x07 : COMPRESSOR, PEQ+COMPRESSOR, PEQ+COMPR+DIST, PEQ+COMPR+OVERDR   (4 images)
   cell 0x08 : the same four images                                            (4 images)
   cell 0x12 : GATED REVERB, AUTO WAH ·  0x13 : AUTO WAH+S.DELAY ·  0x14 : NO OPERATION
```

★ **The dynamics family puts its block on `0x07` and `0x08` — one per channel —
and `0x07`/`0x87` is a host-written bit-7-paired cell** (`r2-output.md`'s nine
observed unit pairs `05/85 06/86 **07/87** 0A/8A 0B/8B 14/94 50/D0 51/D1 52/D2`).
No other image places this block on `0x07`.

**SPECULATIVE reading.** The compressor's envelope state is **not** in the state
block at `0x50+`; it lives in the low host-written parameter region, which is
what lets the host initialise it. Payoff: it puts a named macro on the roadmap's
**rank-1-overall P1.1 host poke port** with a specific pair of cells to watch.

**Proposed cheap test — free, static.** For algos 36/75/96/97, check whether the
tag-`0x15` stream writes `0x07` and `0x08`. **P1:** it writes both. **Falsifier:**
it writes neither ⇒ the block is on cells the host never touches and the
"host-initialised envelope" reading dies for free.

⚠ `data/SPECULATIVE_PATTERNS.md` §9 owns the *other* COMPRESSOR block
(`0A2.2.00.000 | … | 000.A.00.219 | 09A.A.00.200 | C40.1.E0.451`, 8 instances).
This is a **different, disjoint** 4-word block; the two are not the same object.

---

### ★★ T-5 — A SECOND SAME-CELL BLOCK LANDS EXACTLY ON THE STATE-BLOCK CELLS `0x50..0x53`

**MEASURED.** 8 instances / 4 images, all four words on one cell:

```
   0  000.A.**.1D5   SRC 0x07 / ACT 0x15   base+0
   1  212.A.**.415   SRC 0x10 / ACT 0x15   base+0   ST
   2  202.A.**.1D5   SRC 0x07 / ACT 0x15   base+0
   3  202.2.**.407   SRC 0x10 / ACT 0x07   base+0   WRITE

   a09 SINGLE DELAY   0x50 0x51 0x52 0x53   <- FOUR consecutive state cells, one block each
   a08 GATED REVERB   0x50 0x51
   a10 MULTI TAP DELAY      0x51
   a16 ROOM REVERB 1        0xD1            <- the unit-1 mirror of 0x51
```

★ **`SINGLE DELAY` instantiates the block once on each of `0x50, 0x51, 0x52,
0x53`** — and `0x50`/`0xD0` is the MEASURED per-unit state-block base
(`output-stage-decode.md` §3), with `0x51`/`0xD1` and `0x52`/`0xD2` among
`r2-output.md`'s bit-7 unit pairs.

**SPECULATIVE reading.** This is the **generic one-cell accumulate-and-store
step**, and the state block is an array of independent single-word accumulators
that a program allocates one at a time. `SINGLE DELAY`'s four are its four taps.

**Proposed cheap test — free, static.** `SINGLE DELAY` is 48 words with a host
fill; check that its zero-fill covers exactly `0x50..0x53` and no more.
**Falsifier:** the fill is 8 cells (CHORUS's shape, `k3-pointers.md` item I) ⇒
the one-block-per-cell reading under-counts.

---

### ★ T-6 — THE MACRO CELL-MAP CENSUS IS ITSELF THE DELIVERABLE, and most macros are exceptionless

**MEASURED.** Over the **140** maximal repeats (m8 key, length ≥ 4, in ≥ 3
images), the per-slot **relative** cell offset is a **single value at every
mode-2 slot** in the large majority, including every macro in T-1…T-5 and the
control C-4. The macros whose offsets *vary* between instances are the ones
spanning a chain boundary.

**Payoff.** This is a reusable generator of T-1-shaped candidates: any future
macro added to the library gets its private state footprint for free, statically.
**Proposed cheap test — free:** publish the table and check every entry against
the owning algorithm note; a macro whose census disagrees with a `PROVEN` note is
a bug in the machine, not a finding (that is how C-3 was caught).

---

### ★ T-7 — THE 12-WORD LFO/LOOKUP MACRO CARRIES **TWO** CLOSED LOOKUPS ON TWO DIFFERENT CELLS, 11 apart

**MEASURED**, 4 instances / 4 images, exceptionless; cells touched `{−5, 0, +6}`
relative to the macro base:

```
    0  182.2.**.407  WRITE base+0  \
    1..4  C63 | 4CD | 1CE | 1CE     > lookup #1, closed on base+0        (T-1)
    5  102.2.**.000        base+6
    6  000.A.**.415        base+6
    7  092.2.**.700  ST    base-5
    8  212.A.**.1D5  ST    base-5
    9  182.2.**.407  WRITE base+6  \
   10..  C63 | 4CD | …               > lookup #2, closed on base+6       (T-1)
```

**SPECULATIVE reading.** Two table lookups per LFO tail, on two private scratch
cells, with a two-store excursion to a third cell 5 below the first. ⚠ `lfo-ramp.md`
owns the LFO waveform tail (8 of 29 blocks) and the `092.2.**.700` word (28
sites, on Q in 18 of 29); this adds only the **cell identities**, and defers on
everything about the LFO's semantics. **Cheap test:** the `base−5` cell should be
the LFO's own phase cell Q — `lfo-ramp.md` has Q per image already, so this is a
**free table join, no run**.

---

### ★ T-8 — SAME-CELL RUN STRUCTURE: the corpus addresses D-RAM in long constant-offset runs

**MEASURED.** Maximal windows of consecutive words whose static cell is constant:

```
   length  1:647  2:320  3:107  4:91  5:76  6:10  7:25  8:6  9:4  10:3  11:7
          16:2  17:2  24:1  29:1  33:1  44:1
   longest: a16 ROOM REVERB 1 w18 (44 words, cell 0x94) · a08 GATED REVERB w12
            (33, cell 0x50) · a16 w75 (29, 0x8B) · a08 w45 (24, 0x14)
            · a96 PEQ+COMPR+DIST w24 and w69 (17 each, cell 0x12)
```

**SPECULATIVE reading.** The two reverbs spend 44 and 33 consecutive instructions
on **one** D-RAM cell — consistent with T-3 (the tank is external; D-RAM holds a
scalar). **Cheap test — free, static:** the run boundaries should coincide with
the delay-line chain heads `dram-datapath.md` G marks with `addr8` bit 4.

---

### ★ T-9 — NO D-RAM CELL IS WRITTEN BY EVEN 25 OF THE 37 UNIT-0 BODIES

**MEASURED.** Over the **374** mode-2 `ACT 0x07` words (the ANCHORED explicit
write), **59 distinct cells** are written. Cells written by ≥ 20 of 37 unit-0
images: **`0x10`, `0x12`, `0x51` — and that is all.** At ≥ 25: **none.**

★ **There is no universal per-body output cell in the ACT-0x07 population.** That
is a hard constraint on any "the body deposits its result at cell X" reading, and
it is consistent with `r2-output.md`'s FORCED result that the per-unit result
travels in a **register**, never through D-RAM.

⚠ **This is a write-SITE map and it deliberately excludes the bit-4 store**,
because `IW205-DRAM-D0_findings.md` §222 MEASURED that *a static write-site map
which ignores the store GATES over-counts* (6 vs 4 writers of `D-RAM[0x05]`).
`ACT 0x07` is not gated; bit-4 is. **Cheap test:** free — use the three surviving
gates from `lfo-ramp.md` to add the bit-4 stores and re-run; if a universal cell
appears, it is a gated one.

---

## 2. NEGATIVE RESULTS — looked for, NOT found

* **N-1 ★ THE PROGRAM-WIDE WRITE→READ STATISTIC IS AT ROADMAP R3's NULL.**
  166 of 374 = **44.4 %** of mode-2 `ACT 0x07` writes are followed by any
  same-cell mode-2 access; R3's control base rate is **43.2 %**. **R3 is
  CONFIRMED from a second direction and the instrument was not rebuilt.** The
  distance-to-first-re-access histogram is diffuse (`1:30, 4:23, 9:16, 8:11 …`)
  with no exceptionless distance. ⇒ **cell dataflow is decidable INSIDE a macro
  and undecidable ACROSS a program.** That contrast is the methodological result
  of this pass.
* **N-2 — the nop-guard 62/41 split does NOT separate on the cell.** The 62
  (`addr8 = 0`) touch 15 distinct cells, the 41 touch 15, and **9 cells carry
  both**. No cell-based discriminator exists. (`NOP-GUARD_findings.md` owns the
  population; this closes one route it left open, negatively.)
* **N-3 — no cell is written by ≥ 25 of 37 unit-0 images** (T-9). There is no
  corpus-wide "output cell".
* **N-4 — the accumulator def-use chain yields no exceptionless rule.** Of 691
  `SRC 0x10` (accumulator) readers, **59 in 16 images** have no preceding
  `ACT 0x0D` in their body, and the distance histogram to the nearest one is flat
  (`1:117, 4:71, 3:28, 10:26, 11:26 …`). Now that `ACT 0x0D = acc ← L<<16` is
  MEASURED this looked promising; it is not. **Do not spend a pass on it.**
* **N-5 — delay-DRAM reads and writes are NOT balanced per body.** Over 38
  images the `(rd 0x20, x 0x30, wr 0x60)` triples take 15 distinct values; 11
  images have `(0,2,0)` — no read and no write at all — while others run
  `(12,0,3)` and `(14,1,13)`. **No conservation law.**
* **N-6 — no macro's cell map crosses the unit boundary**, and this is
  **untestable, not confirmed**: there is exactly **one** unit-1 body image
  (`a16 ROOM REVERB 1`), so every "unit-1" count in this note has n = 1. Stated
  so nobody reads T-3/T-5's `0xD1` as replicated evidence.
* **N-7 — the C-RAM cursor never overruns the host's written extent.** With the
  `rstcur` honoured, **0 of 37** unit-0 images reach a coefficient index past the
  host's largest written cell `0x2C`. A promising "the body reads uninitialised
  coefficients" lead, **closed negatively, free**.
* **N-8 — offset 0 is not a general attractor.** Over the 29 `lo12` families with
  n ≥ 20, the **median number of images with any site at ENTRY+0 is 0**. Only
  `0x1CD` (37/38 raw, 38/38 wrapped — C-1) and the two structurally-first-word
  families `0x8BC` (24/24) and `0x00B` (16/38) score. The pickup result is not an
  artefact of a busy cell.

---

## 3. ROUND-1 ITEMS: graduate, supersede, or leave standing

| round-1 item | this pass says |
|---|---|
| **S-1** (`xxx.2.00.000` `hi12` bench, `a70` carries 9 forms) | **UNCHANGED, still the cheapest live test.** Untouched here. |
| **S-2** (`0x1CD → 0x40E`, 78/78) | ★ **ALREADY GRADUATED** by `IW205-DRAM-D0_findings.md`: the "latch" is the **accumulator**, `ACT 0x0D = acc ← L<<16` MEASURED EXACT. Reproduced here as a control (78/78, 37 images). **Retire the "separate latch" wording wherever it survives.** |
| **S-3** (`ACT 0x0C` → delay READ, 12/12) | **UNCHANGED.** Not re-measured. |
| **S-4** (`ACT 0x19` brackets a delay READ) | **UNCHANGED.** |
| **S-5** (the `102.A.dd.4C8` band `[−99, −61]`) | ★★ **GRADUATE the count, SUPERSEDE the reading.** T-2: the band is the **return path to the cell slot 2 read**, 29/29 — not a distance to a coefficient block. |
| **S-6** (`4C8` adjacent to a `SRC 0x0B` word, 41/41) | **UNCHANGED**, and T-2 is complementary: S-6 is about the neighbour, T-2 about the address. |
| **S-7** (C-format immediate is a function of `lo12`) | **UNCHANGED.** ⚠ Note T-4 slot 2 is a `C40.2.**.000` word sitting on the block's own cell — a context S-7 did not have. |
| **S-8** (`SRC` nearly a function of `ACT`) | **UNCHANGED**; still the cheapest filter on any candidate decode table. |
| **S-9 / S-10 / S-11** (class-6 `0x407` containment; MULTI TAP's two singletons; `SEL 0xBC` at w0/w1) | **UNCHANGED.** ⚠ `0x8BC`'s 24/24 at ENTRY+0 (N-8) is **structurally forced** by its w0/w1 position and is not independent support for S-11. |
| **S-12** (`f31 ∈ {3,7}` class-2 only; high `f31` hides on `ACT 0x00`) | **UNCHANGED.** |
| round 1 §0.2 control "state block at ENTRY+75, 14 images" | ★ **CORROBORATED independently**: the biquad section's base is +75 in **12 of the 12** biquad-carrying images (C-2). |

---

## 4. Files and how to reproduce

Everything came from `dsp/tools/pat_corpus.py` (the shared loader and field
decode) plus the addressing predicates transcribed from `dsp/tools/dsp_disasm.py`
(`ptr_postinc`, `coeff_consumer`, `is_regload`/`is_rstcur`, `cursor_addresses`),
driven by throwaway scripts in a scratch directory. **No tool was added to the
tree, no existing file was modified, nothing was committed.** The three
components are: the static offset walk of §0.2; a maximal-repeat enumerator on
the `(hi12, class4, lo12)` key; and the per-slot relative-offset tabulator.

---

## 5. SUMMARY — ten lines

1. **The three strongest NEW candidates are T-1, T-2 and T-4.**
2. **T-1:** the 5-word **table-lookup macro is CELL-CLOSED** — the `182.2.**.407`
   write and the `104.2.**.1CE` read-back name the **same D-RAM cell, 21 of 21,
   12 images** (`P ≈ 10⁻²⁵`) — and the remaining **25 of 46** lookup sites have
   **no producer at all** for the cell they read. The static machine names
   CHORUS's cell as **`0x0C`**, reproducing §168's live number from ROM alone.
3. **T-2:** the **CHORUS voice macro is cell-closed too** — slots 2 and 6 address
   one cell, **29 of 29, 10 images**, all inside the state block — which
   **explains round 1's S-5 band `[−99, −61]`** as the return path, superseding
   S-5's coefficient-distance reading.
4. **T-4:** the dynamics family's 4-word block is a **same-cell read-modify-write
   on host-written cells `0x07`/`0x08`**, one per channel, 8 images — putting a
   named macro directly on the roadmap's rank-1 **P1.1 host poke port**.
5. ★ **THE SINGLE CHEAPEST TEST: instrument `a56 MIX UP` once and log its three
   closed lookup cells `0x0D`, `0x0F`, `0x10`.** One image, one run, three sites,
   two-sided — and the 25 open sites are the control that can fail.
   Free static tests needing no emulator: **T-2** (are the 11 voice cells inside
   the host fill?), **T-4** (does the host write `0x07`/`0x08` for algos
   36/75/96/97?), **T-5** (is SINGLE DELAY's fill exactly `0x50..0x53`?).
6. **Dropped as prior art, having been found here first:** the **9-word biquad's
   whole per-slot cell map** (`algorithms/biquad-eq.md` owns it, graded PROVEN —
   it became my control C-4), the `182.2` write half (SP1), the C-RAM cursor
   machine (`dsp_disasm`/`k4-cursor`), the `rstcur` singleton, `0x1CD` at base+0
   (IW205), the LFO phase-cell offsets (`lfo-ramp`, FORCED), "written and never
   read is common" (`r2-output`), and the 62/41 nop-guard split.
7. ★ **My detector failed its own control first** — `is_regload` mis-transcribed,
   reporting **0** in-body `rstcur` where the known answer is **1**
   (`a39 w058`). A census reporting a clean zero is indistinguishable from a
   correct negative; only the known answer caught it.
8. **Round-1 items to move:** **S-5 → graduate the count, retire the reading**
   (T-2); **S-2 → already graduated** by IW205, and its "separate latch" wording
   should be retired everywhere — the latch is the accumulator.
9. **Negatives worth their cost:** the program-wide write→read statistic lands at
   **44.4 % against ROADMAP R3's 43.2 % null** — R3 confirmed, instrument not
   rebuilt; the accumulator def-use chain has no rule (N-4); the nop-guard cells
   do not separate (N-2); no cell is written by 25 of 37 bodies (N-3); the C-RAM
   cursor never overruns the host's extent (N-7).
10. **Nothing here is evidence.** Every reading is SPECULATIVE, every count has
    its denominator, **no audio quantity is produced or claimed (RULE 19)**, and
    the closed questions (R3, dead ends 11/15/16, `f31 = 4/5`, the output-stage
    null) are cited as context and left closed.
