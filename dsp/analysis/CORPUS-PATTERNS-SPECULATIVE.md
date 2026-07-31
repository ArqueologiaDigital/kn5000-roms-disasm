# CORPUS PATTERNS — a SPECULATIVE candidate inventory, ranked by testability × payoff

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date **2026-07-31**.
**Static ROM-corpus analysis only** — no MAME source was written, nothing was
built, nothing was run, no hardware. Read-only pass.

> ⚠ **THIS IS A GENERATIVE PASS, NOT A VERIFICATION PASS.** Nothing here is
> offered as evidence for a decode. Every item is a *candidate*: a regularity in
> the words with a stated population, a stated denominator, and a proposed cheap
> test. The counts are **MEASURED**; every *reading* of a count is **SPECULATIVE**
> and is labelled as such at the point of use.

---

## 0. Population, method, prior art, and the things this pass deliberately did not do

### 0.1 Population — stated once, used everywhere

| set | words | note |
|---|--:|---|
| **38 distinct IC311 body images** | **2974** | the primary population for every count below |
| KERNEL (I-RAM 0..59) | 60 | quoted separately, never pooled into a body statistic |
| EPILOGUE / output stage (I-RAM 60..82) | 23 | idem |
| **corpus total** | **3057** | |
| of the body corpus: **PLAIN** words | **2837** | not C-format **and** `lo12` bit 11 clear — see §0.4 |

* The **five IC310 / MN19413 streams `{79, 88, 89, 90, 91}`** are **EXCLUDED**
  (`pat_corpus.MALFORMED`). No statistic in this note mixes the two chips.
* The **twelve NAMED stub effects** (MODULATION DELAY, SLOW ATTACKER, PITCH
  SHIFTER, STRING, CEL/CELM, PEDAL WAH, DS_D, OVER_D …) ship a program
  **byte-identical to NO OPERATION** (`bit11-family.md` item G) and therefore
  collapse into `a00` before any measurement is taken. **They contribute ZERO
  distinct images**, so no structural-analogy claim in §3 can be contaminated by
  them, and none of them is cited as an "analogy". Likewise the twelve reverb
  presets collapse into the single unit-1 image `a16 ROOM REVERB 1`.
* Replication is never counted as evidence: `a00` is one image, not 42 slots.

Word format used throughout: `hi12[35:24] . class4[23:20] . addr8[19:12] .
lo12[11:0]`; `SRC = lo12[10:6]`, `ACT = lo12[4:0]`; `f98 = hi12[9:8]`,
`f31 = hi12[3:1]`; bit 4 = store, bit 10 = END, bit 11 = format escape;
**C-format** = `hi12[11:8] == 0xC`.

### 0.2 Controls — the method reproduces four known answers before it claims anything

| known answer | source of record | what this pass measured, blind | verdict |
|---|---|---|---|
| `hi12` bit 7 has **12** byte-identical minimal pairs | `instruction-set.md` (`hi12` table, bit 7) | **12** one-bit pairs at bit 7 over 759 distinct words | **PASS, exactly** |
| the state block sits at **ENTRY+75** | `output-stage-decode.md` §3 | the signed `addr8` delta `+75` exists as a single instruction step in 14 images, and under the FORCED walk **15 of 15** land in `0x50..0x5A` / `0xD0` | **PASS** |
| `DISTORTION ≡ FUZZ` up to four `addr8` bytes | `data/SPECULATIVE_PATTERNS.md` §5 | the **only** skeleton-identical pair in 703 unordered pairs | **PASS** |
| the 9-word biquad section | §124 / `data/SPECULATIVE_PATTERNS.md` §3.4 | recovered blind as the splice unit of §3.1 | **PASS** |

A pattern-finder that misses these is measuring noise. All four come out.

### 0.3 Prior art — checked FIRST, and cited rather than re-claimed

Read before anything was computed, and used to strike duplicates out of this
inventory: [`data/SPECULATIVE_PATTERNS.md`](data/SPECULATIVE_PATTERNS.md)
(2026-07-30, the immediately preceding corpus sweep — its §§1–13 and SP1–SP12 are
**not** repeated here), [`bit11-family.md`](bit11-family.md),
[`r2-output.md`](r2-output.md) §4, [`../instruction-set.md`](../instruction-set.md),
[`data/F31_HIGH_findings.md`](data/F31_HIGH_findings.md) (another worker's **live**
pass — deferred to, never duplicated), [`ROADMAP-2026-07-29.md`](ROADMAP-2026-07-29.md),
[`LEDGER-HEAD.md`](LEDGER-HEAD.md) TIER 0b (the dead-end list) and TIER 0c
(the standing rules), [`dark-words.md`](dark-words.md),
[`output-stage-decode.md`](output-stage-decode.md),
[`action00-discriminator.md`](action00-discriminator.md).

**Struck out of this note because it is already owned elsewhere** (each was
computed here, found, and then deleted on discovering the owner):

* the **terminator `hi12` census** (9 forms, `f31 = 4` on 12 images, the
  `hi12[3:2]` sub-code inside the bit-5-set family) — **owned by
  `data/F31_HIGH_findings.md` §3.2**, a live pass. Not duplicated.
* the terminator's **bit-4 store, 5 of 38 bodies**, and the `602`/`612` minimal
  pair — **owned by `r2-output.md` §4.4**.
* the **`8BC` / `C63` / `839` / `864` / `921` family census and its
  modulating-vs-linear split** — **owned by `bit11-family.md`** §2, §3.
* the **`ACT 0x15` word at −2 from every lookup**, the **class-6 `0x18`/`0x28`
  selector accounting**, the **CHORUS 7-word voice macro**, the **combi
  concatenation test**, the **per-body net displacement distribution**, the
  **`addr8 = 0xEE` combi-exclusive value**, the **COMPRESSOR 5-word detector
  block** — all **owned by `data/SPECULATIVE_PATTERNS.md`** §§3, 4, 6, 8, 9.

### 0.4 ⛔ Known-closed, respected as context, NOT reopened

* **`f31 = 4/5` is UNDECIDABLE** on the clean vehicle (`f31 = 4` fires zero times
  there). §2 tabulates *where such words are*; it does not propose a decode.
* **the bit-11 family had all four decidability routes closed**, and
  **"model the bit-11 encoding on an ALU route" is impossible** — those words
  carry no SRC and no ACTION (LEDGER dead end #15).
* **LEDGER dead end #16: `ACT 0x03`, `ACT 0x04`, `ACT 0x1C`, `SRC 0x02`,
  `SRC 0x04` DO NOT EXIST** — they are parse artefacts of reading the
  bit-11-clear encoding out of a bit-11 word. ★ **This pass therefore excludes
  every bit-11 word from every SRC/ACT statistic** (that is what "PLAIN = 2837
  words" means in §0.1). A first draft of §1 and §2 did not, and produced three
  items that were entirely artefacts of `0x8BC` (`ACT 0x1C` "is the body's first
  word, 22 of 24") and `0xC63` (`SRC 0x11 / ACT 0x03`). They are deleted.
  ⚠ Readers of `data/SPECULATIVE_PATTERNS.md` §3.1 should note that its
  assembled table still renders `040.0.**.C63` as `SRC 0x11 / ACT 0x03` and
  `012.4.01.1CE` as `SRC 0x07 / ACT 0x0E`; the first of those is a dead-end-#16
  label. Its *counts* are unaffected.
* **`ACT 0x15` is not a no-op gate** — the multiply's condition is
  `class4(w) == 0xA && !c_format(w)` (LEDGER dead end #11).
* **`addr8` on the class-6 word is not the table EXTENT** (dead end #3).

### 0.5 What this pass deliberately did NOT build

* ⛔ **The static def-use / D-RAM cell-liveness instrument over the FORCED pointer
  walk.** The brief's item 3 suggests "cells always written before read, or never
  read". `ROADMAP-2026-07-29.md` (the closed-instrument list) records that this
  exact instrument **cannot decide `SRC 0x00`** — calibration: control base rate
  43.2 %, `SRC 0x07` (anchored `mem[ptr]`) 38.2 %, `SRC 0x10` (anchored `acc`,
  not a memory read at all) 42.8 % — two anchored codes with opposite semantics
  are not separated from each other or from the null — and that it **must never
  be rebuilt**. It was not rebuilt. The only pointer-walk arithmetic used here is
  the *displacement* arithmetic of C-4, which is a known-answer control.
* Anything touching the **output-stage null**: a separate pass owns that. §1
  item S-2 brushes it in one sentence and is explicitly flagged there.

---

## 1. THE RANKED INVENTORY

Ranked by **testability × payoff**, not by how interesting the reading sounds.
"Testability" = can a *future* run decide it cheaply, with a two-sided outcome.
"Payoff" = how many corpus words / undecoded fields the answer unblocks.

Every row: **population · denominator · strength · proposed cheap test.**

---

### ★★★ S-1 — `xxx.2.00.000` IS THE MACHINE'S BUILT-IN `hi12` TEST BENCH, and one image exercises nine of its forms

**MEASURED.** Hold `class4 = 2`, `addr8 = 0x00`, `lo12 = 0x000`
(`SRC 0x00 / ACT 0x00`) fixed and vary **only `hi12`**. The corpus contains
**17 distinct `hi12` values on that one otherwise-identical instruction, over
354 words**:

```
   hi12  f98 f31 b4 b5 b7    n   images        hi12  f98 f31 b4 b5 b7    n   images
   000    0   0   0  0  0    62    15          102    1   1   0  0  0    35    20
   020    0   0   0  1  0     2     2          104    1   2   0  0  0    23     5
   022    0   1   0  1  0    14     8          182    1   1   0  0  1    12     6
   024    0   2   0  1  0     2     2          202    2   1   0  0  0    18    11
   026    0   3   0  1  0    18     9          204    2   2   0  0  0    13     7
   028    0   4   0  1  0    17    13          212    2   1   1  0  0    88    29
   02A    0   5   0  1  0    28    15          282    2   1   0  0  1     1     1
   02E    0   7   0  1  0    11     6          292    2   1   1  0  1     2     2
   0A2    0   1   0  1  1     8     4
```

Every `f31` value except `6` is attested on this carrier (`f31 = 6` has only
**2 words in the entire body corpus**). Both states of `f98`'s low bit, both
states of the store bit 4, both states of the gate bit 7, and **both states of
residue bit 5** appear.

★★★ **And the corpus hands over a single-program vehicle.** Distinct forms of
this family carried by one image:

```
   a70 AUTO WAH+S.DELAY   9 forms   000 020 022 026 02A 202 204 212 292
   a48 AUTO PAN           8 forms   000 024 028 02A 102 182 202 212
   a52 AUTO WAH           8 forms   022 024 026 02A 202 204 212 292
   a96 PEQ+COMPR+DIST     7 forms   026 028 02A 0A2 102 182 212
   a35 EXCITER            6 forms   022 026 028 02A 102 212
   a97 PEQ+COMPR+OVERDR   6 forms   026 028 02E 0A2 102 212
```

**Population** 38 images / 354 words. **Denominator** 17 of 17 forms share
`class4`, `addr8` and all twelve `lo12` bits — there is no confound to control
for. **Strength: this is the strongest item in the note**, because it is not a
correlation at all: it is a controlled experiment already present in the ROM.

**Proposed cheap test (this is the cheapest test in the whole inventory).**
Load `a70 AUTO WAH+S.DELAY`; log the full machine delta (`acc`, `m_p`,
`mem[m_p]`, `tempA`, `tempB`, cursor) across its **nine** `xxx.2.00.000` sites in
**one** instrumented run. Nine `hi12` codes, one instruction, one program, one
frame. Two-sided: if all nine deltas are identical, `hi12` carries nothing on a
`SRC 0x00 / ACT 0x00` word and the "horizontal microword" reading is narrowed;
if they differ, the differing bit names itself.

⚠ **Honest limit, and it must be checked before the run.**
`action00-discriminator.md` establishes that on an `ACTION 0x00` word
`hi12[3:1] == 0` and `== 1` are **indistinguishable**, and that 257 of the 806
`ACT 0x00` words are structurally blind. This bench sits **entirely** inside the
`ACT 0x00` population, so some of its 36 pairwise comparisons cannot resolve.
The blindness theorem should be applied *first*, to strike the blind pairs; the
remainder are free. ★ This is a **design input for the live `f31` pass
(`data/F31_HIGH_findings.md`)**, not a claim about `f31`, and nothing about
`f31`'s semantics is asserted here.

---

### ★★★ S-2 — `lo12 0x1CD` → `lo12 0x40E` is an EXCEPTIONLESS producer/consumer pair across 37 of 38 images

**MEASURED.**

```
   producer   xxx.2.dd.1CD    SRC 0x07 (mem[ptr], ANCHORED)   ACT 0x0D   152 words, 38 images
   consumer   xxx.2.dd.40E    SRC 0x10 (acc,     ANCHORED)   ACT 0x0E    78 words, 37 images
```

* **Every class-2 `lo12 0x40E` word in the body corpus — 78 of 78, in 37 of 38
  images — is immediately preceded by a `lo12 0x1CD` word.**
* Widened to all 81 `0x40E` words of any class: **79 of 81**. The two exceptions
  are the same word in one image (`a48 AUTO PAN` w10 and w45,
  `026.2.00.1D5 → 192.A.00.40E`).
* Widened to all 222 `ACT 0x0E` words: **213 of 222** are preceded by an
  `ACT 0x0D` or `ACT 0x0E` word; the 9 exceptions are **enumerated and
  structural** — 7 are the chained class-6 `lo12 0x407` lookups feeding
  `012.4.01.1CE` (CHORUS, MODULATED CHORUS, ENSEMBLE ×3, S.DELAY+CHORUS,
  PEQ+CHORUS) and 2 are AUTO PAN's.
* **The converse is FALSE and that is the point**: only **79 of 152** `0x1CD`
  words are followed by a `0x40E` (52 %). `0x1CD` is a producer with several
  consumers; `0x40E` is a consumer with exactly one producer.

**Denominator / null.** Base rate of `lo12 0x1CD` = 152/2974 = **5.11 %**.
Binomial `P(78/78 | p = 0.0511)` = **10⁻¹⁰⁰·⁷**. Both ACTIONs are in the
17-of-24 undecoded set.

**SPECULATIVE reading.** `ACT 0x0D` deposits `mem[ptr]` into a latch that
`ACT 0x0E` then consumes together with the accumulator. Payoff: `ACT 0x0E` alone
is 222 words in 38 of 38 images and `ACT 0x0D` is 200 in 38 of 38 — between them
**14.9 % of the plain corpus**, second only to `ACT 0x00`/`0x15`.

**Proposed cheap test.** Instrument any `0x40E` site (they exist in 37 images —
pick the vehicle the current handoff already uses). Log (a) the value the
preceding `0x1CD` word read from `mem[ptr]`, (b) `acc` in, (c) every register out.
**P1:** the output is a function of both. **Arm 2** (output depends only on `acc`)
says `ACT 0x0D` is not a producer for it and the 78/78 adjacency is layout, not
dataflow — which is a *bigger* result than a hit, because it would mean the
machine's most portable two-word idiom is not a dataflow pair.
**Control that can fail:** `a48 AUTO PAN`, whose two `0x40E` words have a
*different* predecessor. The probe must fire there and show the other behaviour.

---

### ★★★ S-3 — `ACT 0x0C` has 14 sites in 3057 words, and 12 of 12 are immediately followed by a delay-DRAM READ

**MEASURED.** Excluding bit-11 words, `ACT 0x0C` occurs **12 times in the body
corpus, and all 12 are the same word `000.2.00.44C`** (`SRC 0x11`), in **4
images**: `a04 FLANGER` (w10, w56), `a06 ENSEMBLE` (w9, 19, 29, 67, 77, 87),
`a66 S.DELAY+FLANGER` (w34, w88), `a73 PEQ+FLANGER` (w29, w78).

```
   all 12 successors are class-1 + ESC with addr8 = 0x20 (the DELAY READ):
       880.1.20.40B   x6   (the FLANGER family)
       880.1.20.2D9   x6   (ENSEMBLE)
```

**12 of 12.** Base rate of a `cls1+ESC addr8 0x20` READ = 104/2974 = **3.50 %**;
`P(12/12) ≈ 3 × 10⁻¹⁸`.

The **only other two `ACT 0x0C` words in the entire 3057-word corpus** are
`KERNEL w45 = 010.A.00.20C` and `KERNEL w53 = 010.9.D0.20C` — the two words
`r2-output.md` §4.5 identifies as the per-unit sends, "the same destination from
different sources". Their `SRC` is `0x08`, not `0x11`.

**SPECULATIVE reading.** `ACT 0x0C` = *present the operand to an external
interface* — the body sites hand something to the delay port one slot before the
read issues; the kernel sites hand a unit result to the send. ⚠ **The kernel half
touches the send / output-stage question that a separate pass owns.** It is
recorded here as a *distribution fact* (14 sites, two contexts) and no claim is
made about the send.

**Proposed cheap test.** Purely static first, free: confirm no `ACT 0x0C` word
anywhere in the corpus lacks either an adjacent delay word (body) or a unit
register (kernel). Then instrument `a06 ENSEMBLE`, which carries **6 of the 12**
sites in one image: log what `000.2.00.44C` writes and whether the following
`880.1.20.2D9` read consumes it. Two-sided: if the read's address or datum is
unaffected, the adjacency is layout and the reading dies.

---

### ★★ S-4 — the two `ACT 0x19` flavours bracket a delay READ from OPPOSITE sides

**MEASURED.** `ACT 0x19` is one of only two ANCHORED actions
(`acc-adder.md`: `tempA ← L`). It comes in two SRC flavours and they sit on
opposite sides of the delay read:

| flavour | `lo12` | n | images | relation to the nearest `cls1+ESC addr8 0x20` READ |
|---|---|--:|--:|---|
| `SRC 0x0B` (delay-read register) | `0x2D9` | 36 | — | its consumer `0012201655` follows a READ, **13 of 13** — *already recorded*, LEDGER §215 |
| `SRC 0x10` (accumulator, ANCHORED) | `0x419` | **44** | **13** | a READ follows it at **+1 (28 sites) or +2 (16 sites)**, **44 of 44**, and **never precedes it** |

**Denominator / null.** `P(a READ within the 2 slots after) = 1 − (1 − 0.035)²
= 6.88 %`; `P(44/44) ≈ 10⁻⁵¹`.

**SPECULATIVE reading.** The delay read clobbers state that the accumulator
flavour saves first: `0x419` = "stash `acc` into `tempA`, *then* issue the read";
`0x2D9` = "capture the datum the read produced". One ACTION, one register, two
directions. This is testable and it is **complementary to §215**, not a
re-derivation of it — §215's family is the `SRC 0x0B` half and says nothing about
`0x419`.

**Proposed cheap test.** At any `0x419` site, log `tempA` before and after, and
`acc` before; then log `tempA` again after the following READ. **P1:** `tempA`
takes `acc` at the `0x419` word and is *not* disturbed by the READ. **Arm 2:**
the READ overwrites `tempA`, which would make the stash pointless and kill the
reading. Both arms are one instrumented run on any of 13 images.

---

### ★★ S-5 — the DARK word `A00.0.00.041` heads a FIXED 3-word template, and the third word's reach is a tight negative band

**MEASURED.** 35 sites in 13 images.

```
        A00.0.00.041     class 0, SRC 0x01 / ACT 0x01     <- DARK (dark-words.md 4.4)
   +1   880.1.20.2C7     delay-DRAM READ                  35 of 35   (already SP9)
   +2   102.A.dd.4C8     class A, SRC 0x13 (table port) / ACT 0x08
                                                          35 of 35   NEW
                         dd over 19 distinct values, ALL in [0x9D .. 0xC3]
                                                          = signed −99 .. −61
   −1   C40.3.20.44C  x29   /   104.2.00.1D5  x6          (already SP9)
```

The `+1` half is `data/SPECULATIVE_PATTERNS.md` **SP9** and is credited, not
re-claimed. **What is new is `+2`**: the template closes on a table-port multiply
at 35 of 35, and that multiply's signed pointer displacement never leaves a
39-wide negative band, across 13 different effects.

**Denominator / null.** `102.A.**.4C8` base rate = 41/2974 = 1.38 %;
`P(35/35) ≈ 10⁻⁶⁵`. The band: 19 distinct values inside a 39-wide window out of
256 possible — `P` under a uniform `addr8` is astronomically small and is not the
interesting number; the interesting number is that **no site leaves the band**.

**SPECULATIVE reading.** `[apply an offset] [read the swept tap] [scale it by an
interpolation coefficient fetched from the table port]` — a fractional-delay
tap. The `−99 .. −61` band is then the *distance back to the tap's own
coefficient block*.

**Proposed cheap test — free, static.** For the 13 images, compare `[−99, −61]`
against the host's per-algorithm zero-fill block. **P1:** the band lies inside
the fill. **Falsifier:** it reaches state the host never clears, which would make
it a hand-off, not a private coefficient. This needs no emulator at all.

---

### ★★ S-6 — `102.A.**.4C8` is adjacent to a `SRC 0x0B` word at 41 of 41, which extends the CHORUS voice macro beyond its own macro

**MEASURED.** The table-port multiply `102.A.**.4C8` (`SRC 0x13 / ACT 0x08`,
class A) has a **`SRC 0x0B` word — the delay-read data register — immediately
adjacent at 41 of 41 sites in 14 images**: at −1 in 35, at +1 in 6.

Why this is not just S-5 again: `data/SPECULATIVE_PATTERNS.md` §3.3 records the
7-word CHORUS voice macro at **29 instances in 10 images**. The adjacency here
holds at **41 sites in 14 images** — i.e. **12 sites in 4 further images** carry
the relation *without* carrying the macro. The relation is more portable than the
macro that contains it.

**Denominator / null.** `SRC 0x0B` base rate = 104/2974 = 3.50 %;
`P(adjacent) = 6.88 %`; `P(41/41) ≈ 10⁻⁴⁷`.

**Proposed cheap test — free, static.** List the 12 non-macro sites and check
whether they are a *reduced* voice (fewer words, same core) or a different
construction. If they are reduced, the macro library has a second, shorter voice
form and `pat_ngram`'s maximal-repeat list is missing it.

---

### ★★ S-7 — the C-FORMAT immediate is a FUNCTION of `lo12`, in 15 of 16 forms; the one exception splits exactly on the UNIT

**MEASURED.** Over the whole 3057-word corpus, C-format words (`hi12[11:8] == 0xC`,
68 words). Within the **38 bodies** there are only **six** distinct forms:

| `lo12` | `imm13` | sites | images | note |
|---|--:|--:|--:|---|
| `0x44C` | **800** (A = 25) | 29 | 10 | one value, ten different effects |
| `0x451` | **480** (A = 15) | 8 | 4 | the compressor family |
| `0x1DA` | **0** | 2 | 1 | ROCK ROTARY |
| `0x647` | **1280** | 1 | 1 | GATED REVERB |
| `0x359` | **928** | 1 | 1 | NO OPERATION |
| `0x000` | **704** (A = 22) | 12 | 8 | every one a **unit-0** image |
| `0x000` | **384** (A = 12) | 4 | **1** | `a16 ROOM REVERB 1` — **the only unit-1 image** |

★ **`lo12` determines `imm13` in five of the six body forms; the sixth is the
only `lo12` with two immediates and its split is exactly unit 0 (704) vs
unit 1 (384).** No image mixes them. The remaining ten C-format forms in the
corpus are **ten further forms, 11 words, every one confined to the kernel or the
epilogue** (opcodes `600`, `602`, `605`, `60B`, `621`, `625`, `632`; nine of the
ten are singletons). 57 body + 11 kernel/epilogue = the 68 C-format words.

`instruction-set.md` already establishes that `C40.1.80.000` (A = 12) and
`C40.2.C0.000` (A = 22) are **the same instruction differing only in the
immediate** — that argument is what forced the wide C-format predicate. What is
new is the **distribution**: 12 sites/8 images at A = 22 against 4 sites/1 image
at A = 12, with the boundary exactly the unit boundary.

**SPECULATIVE reading.** The `lo12 = 0x000` C-format immediate is a **per-unit**
constant (a limit, a length, or a base), and the other five destinations take a
**global** constant that the effect designer never varied.

**Proposed cheap test — free, static.** Two-sided and it can fail: check the two
values against the per-unit quantities already pinned — ENTRY `0x05` / `0x85`,
`X = 0xFF`, the state block at ENTRY+75. **P1:** `704 − 384 = 320` or the values
themselves correspond to a unit-scaled quantity in `output-stage-decode.md` §3.5.
**Arm 2:** they correspond to nothing, in which case `lo12 0x000`'s destination is
not unit-scoped and the reading dies for free.

---

### ★ S-8 — `SRC` is very nearly a function of `ACT` for four source codes

**MEASURED**, PLAIN words only (2837).

| `SRC` | n | images | the ACTIONs it ever carries |
|---|--:|--:|---|
| `0x01` | 35 | 13 | **`0x01` only, 35 of 35** |
| `0x1C` | 46 | 25 | **`0x00` only, 46 of 46** |
| `0x13` (table port) | 87 | 26 | **only `0x08` (41) and `0x0D` (46)** |
| `0x00` | 598 | 38 | `0x00` ×572, `0x0B` ×25, `0x01` ×1 — 95.7 % one action |

and the mirror, `ACT` × `class4`:

| `ACT` | n | classes |
|---|--:|---|
| `0x01` | 36 | **class 0 only, 36 of 36** |
| `0x0C` | 12 | **class 2 only, 12 of 12** (S-3) |
| `0x0D` | 200 | classes 2 (154) and 6 (46) only |
| `0x0E` | 222 | class 2 (166), 4 (53), A (2), 1 (1) |

⚠ `SRC 0x1C`'s *meaning* is not claimed: LEDGER dead end #6 records that the
brief's "`SRC 0x1C` = LFO out" anchor exists nowhere in this repository.

**Proposed cheap test — free, static.** These are hard constraints on any
proposed decode: a reading of `SRC 0x13` that requires a third action is wrong by
construction. Use them as a **filter on candidate decode tables**, not as an
experiment. Zero cost, immediate payoff.

---

### ★ S-9 — the class-6 `lo12 0x407` selectors lie strictly INSIDE the two `0x4CD` selectors

**MEASURED.** Class 6 is 53 words, two `lo12` sub-families:

```
   lo12 0x4CD   addr8  0x18 x29   0x28 x17          (SP2/SP3's pair; NOT extended)
   lo12 0x407   addr8  0x1A x1    0x1E x3   0x20 x3
```

★ **All three `0x407` selectors are strictly inside the open interval
(`0x18`, `0x28`)**, at offsets +2, +6, +8 from `0x18` — spacings that are *not*
multiples of 16.

**Relation to prior art.** `data/SPECULATIVE_PATTERNS.md` **SP3** proposes that
`0x18` and `0x28` are two **bases** in one table space (`0x28 − 0x18 = 0x10`) and
names its falsifier as *"a third class-6 `4CD` value appearing that is not
`0x18 + 16k`"*. **That falsifier does NOT fire** — `0x4CD` still takes only
`{0x18, 0x28}`, 46 of 46. But the sibling sub-family's three values fall between
them at non-16-aligned offsets, which is what a **base + small offset** reading
predicts and what a **two-independent-selectors** reading has to explain away.
This is a *refinement* of SP3, not a falsification, and SP3 keeps priority.

**Proposed cheap test — free, static.** Check whether an image carrying `0x407`
also carries `0x18` and never `0x28` (containment), and whether the three offsets
`{+2, +6, +8}` match the voice count of the image that carries them (ENSEMBLE
carries all three).

---

### ★ S-10 — `MULTI TAP DELAY` owns BOTH of the corpus's unique alternate-`lo12` selectors, seven slots apart

**MEASURED.** Decomposing the 90 bit-11 words as `FLAG(11) | SUB[10:8] |
SELECTOR[7:0]` with `addr8` as the VALUE, the **SUB field takes only three values
in 3057 words**: `SUB = 0` (36 words), `SUB = 4` (53 — every `C63`),
`SUB = 1` (**1 word**).

```
   a10 MULTI TAP DELAY  w26   040.0.00.864    SUB=0 SEL=0x64 VALUE=0x00   corpus-unique
   a10 MULTI TAP DELAY  w33   050.0.00.921    SUB=1 SEL=0x21 VALUE=0x00   corpus-unique
                                              (SEL 0x21 = the C-RAM pointer-load
                                               selector, PROVEN BY CONSTRUCTION,
                                               otherwise only in KERNEL/EPILOGUE
                                               with VALUEs 0x50 / 0x70 / 0x90)
```

`bit11-family.md` item C already lists `864` and `921` as singletons in MULTI TAP
DELAY and credit is theirs. **New here:** (a) the `SUB` decomposition, which makes
`921` the corpus's **only** `SUB = 1` word and puts it on the *same selector* as
`ldptr`/`rstcur`; (b) the two singletons sit **7 slots apart in the same image**;
(c) `programs.tsv` describes exactly this image with a *"partial-cursor-rewind
idiom"* that is documented and undecoded.

**SPECULATIVE reading.** `SUB` is a modifier on the pointer-load: `SUB = 0` loads
an absolute value, `SUB = 1` does something else to the same pointer (a rewind, a
save/restore, or a relative load) — and only the four-tap program needs it.

**Proposed cheap test.** Instrument `a10 MULTI TAP DELAY` w26 and w33; log the
C-RAM pointer and the coefficient cursor before and after each. **P1:** one of
them moves at w33 in a way `ldptr` cannot produce. **Arm 2:** neither moves,
which makes both words inert and removes the "partial-cursor-rewind" reading from
`programs.tsv`'s role string. One image, one run, two words.

---

### ★ S-11 — selector `0xBC` appears exactly once per image, always in the first two words, on two complementary carriers

**MEASURED.** 24 of the 38 images carry exactly one `SEL 0xBC` word, and it is at
word 0 or word 1 in **24 of 24**.

```
   class-1 carrier, VALUE 0x30   880.1.30.8BC    17 images   (and it IS the body's
                                                              first delay access)
   class-0 carrier, VALUE 0x00   040.0.00.8BC x5, 050.0.00.8BC x1, at w0/w1
                                                   7 images
   overlap: 0 images.   neither: 14 images.
```

`bit11-family.md` §3 owns the family census and the modulating-vs-linear split;
credit is theirs. **New here:** the **positional** fact (24 of 24 in the first two
slots) and the **exact disjointness** of the two carriers. Also new: the body's
first delay access takes exactly two `lo12` values corpus-wide — `0x00B` (plain)
and `0x8BC` (alternate) — in complementary distribution.

**SPECULATIVE reading.** `SEL 0xBC` is a **body-entry configuration write**, and
the VALUE field says which of two entry modes; the class-1 carrier fuses it with
the first delay access, the class-0 carrier issues it standalone.

**Proposed cheap test.** Two images, one run: `a01 CHORUS` (class-1 carrier at w0)
and `a50 VIBRATO` (class-0 carrier at w0). Log every architectural register at
body entry. **P1:** both write the same register with different values.
**Arm 2:** they write different registers, in which case `0xBC` is two things and
the "one selector" reading dies.

---

### ★ S-12 — `f31 ∈ {3, 7}` occurs ONLY on class 2, and the high `f31` codes hide on the ACTION that cannot see them

**MEASURED** (PLAIN words, 2837). See §2.1 for the full table. Two facts:

* **`f31 = 3` (32 words) and `f31 = 7` (15 words) occur on class 2 and nowhere
  else — 47 of 47.** (`f31 = 6` is 2 words split class 1 / class 2, so the clean
  statement is `{3, 7}`, not `{3, 6, 7}`.)
* **`f31 ≥ 3` is 149 words, and 105 of them — 70.5 % — carry `ACT 0x00`,
  against a base rate of 806/2837 = 28.4 %.**

★ The second fact is a **structural explanation of why `f31` has resisted**: the
high codes are concentrated on exactly the ACTION where
`action00-discriminator.md` proves the field is blind. It is a *negative* result
and it costs nothing to record.

**Proposed cheap test — free, static.** Cross-tabulate `f31 ≥ 3` against
`action00-discriminator.md`'s own blindness census (257 blind / 359 can bear a
difference / 221 carry it to an observable) and report how many of the 149 high-
`f31` words fall in each bucket. If the answer is "almost all blind", the `f31`
pass has a **completeness bound**, which is worth more than another experiment.
⛔ This is offered to the owners of `data/F31_HIGH_findings.md`; nothing about
`f31`'s semantics is claimed here.

---

## 2. FIELDS WE CANNOT DECODE — distributions only, no decode attempted

The brief asks for the *distribution* of `f31`, `f98` and the bit-11
SUB/SELECTOR space, and specifically whether any value **partitions cleanly by
effect family**. Answer up front: **it does not** (§4, N-4). What *does* partition
is the class. And the most useful thing the distributions produce is a
**testability ranking**, §2.3.

### 2.1 `f31` × `class4` (PLAIN body words)

```
   f31   n      images   class4 breakdown
   0     1204   38       cls0:91  cls1:282 cls2:576 cls6:53  clsA:202
   1     1288   38       cls0:7   cls1:8   cls2:675 cls4:53  clsA:545
   2      275   37       cls1:7   cls2:179 cls8:39  clsA:50
   3       32   10       cls2:32                                  <- class 2 only
   4       46   21       cls1:12  cls2:18  clsA:16
   5       55   19       cls0:1   cls2:42  cls8:3   clsA:9
   6        2    1       cls1:1   cls2:1
   7       15    7       cls2:15                                  <- class 2 only
```

Constants worth having written down: **class 4 is `f31 = 1` in 53 of 53** and
**class 6 is `f31 = 0` in 53 of 53** (the class-6 half is already in
`data/SPECULATIVE_PATTERNS.md` §10; the class-4 half is not).

### 2.2 `f98` × `class4` (PLAIN body words)

```
   f98   n      images   class4 breakdown
   0     1656   38       cls0:57 cls1:262 cls2:899 cls4:53 cls6:53 cls8:42 clsA:290
   1      493   35       cls0:7  cls1:36  cls2:305                        clsA:145
   2      766   38       cls0:35 cls1:12  cls2:334                        clsA:385
   3        2    1                                                        clsA:2
```

* **`f98 = 3` is 2 words in one image** (`a15 ROCK ROTARY`, class A). The field is
  effectively ternary in this corpus.
* **`f98 = 0` on 148 of 148 class-4/6/8 words** — the three single-form classes
  never vary it.
* **`f98 = 1` never occurs on classes 4, 6 or 8** (0 of 148).

### 2.3 ★★ THE TESTABILITY RANKING — one-bit `hi12` minimal pairs, and whether one image carries both halves

**MEASURED** over the 759 distinct 36-bit words of the whole corpus. A *minimal
pair* = two corpus words identical in all 36 bits except one `hi12` bit. A
*co-resident* pair = one image contains both halves, so a **single loaded
program** can show the difference.

| `hi12` bit | field | minimal pairs | co-resident pairs | images that carry both halves |
|--:|---|--:|--:|---|
| 0 | "`addr8` absolute" / imm MSB | **0** | 0 | — |
| 1 | `f31` lsb | 6 | **3** | 11 |
| 2 | `f31` bit 1 | 6 | **1** | 3 |
| 3 | `f31` msb | 10 | **2** | 4 |
| 4 | STORE (**decoded**) | 23 | 4 | 10 |
| **5** | **residue, no reading** | **2** | **1** | **2** |
| **6** | **residue, no reading** | **0** | 0 | — |
| 7 | store gate (**decoded**) | 12 | 3 | 9 | ← *control: matches the published 12* |
| **8** | **`f98` lsb** | **1** | **0** | **none** |
| **9** | **`f98` msb** | **4** | **0** | **none** |
| 10 | END (**decoded**) | 2 | 0 | — |
| 11 | FORMAT ESCAPE (**decoded**) | **0** | 0 | — |

Three conclusions, all **MEASURED**, all free:

1. ★★★ **`f98` has 5 minimal pairs and ZERO co-resident ones.** No single loaded
   program can ever exhibit an `f98` difference on otherwise-identical words.
   **Any `f98` experiment must compare two different loaded effects** — which is
   an experimental-design fact, not a hypothesis, and it explains why `f98` has
   resisted. The five pairs, for whoever runs it:
   ```
      202.A.00.655 {8 delay/combi images}  <->  302.A.00.655 {a15 ROCK ROTARY}
      002.A.03.1D5 {a10 MULTI TAP DELAY}   <->  202.A.03.1D5 {a52 AUTO WAH}
      002.A.FF.1D5 {a10 MULTI TAP DELAY}   <->  202.A.FF.1D5 {7 images}
      012.2.AF.447 {a03 ENHANCER}          <->  212.2.AF.447 {a97 PEQ+COMPR+OVERDR}
      012.A.00.1D5 {a08 GATED REVERB}      <->  212.A.00.1D5 {a10, a16}
   ```
2. ★★ **`hi12` bit 5 — a bit with no reading at all — HAS a co-resident pair**,
   and on the corpus's most common word:
   ```
      000.2.00.000  x62 in 15 images   <->   020.2.00.000  x2 in 2 images
      co-resident in:  a15 ROCK ROTARY,  a70 AUTO WAH+S.DELAY
   ```
   `000.2.00.000` is the word `instruction-set.md` renders as **`nop` (INFERRED)**.
   If bit 5 does anything, `020.2.00.000` is a `nop` that is not a `nop`, and two
   images run both in the same frame. **SPECULATIVE**, and the cheapest possible
   falsifier of an inference the disassembler prints 62 times.
3. **Bits 0 and 6 have zero minimal pairs in 759 distinct words** — formally
   undecidable by comparison, the same shape of closure as the `f31 = 4/5` route.
   Record it so nobody spends a pass discovering it.

### 2.4 The bit-11 alternate `lo12` space — the full 90-word census

`FLAG(11) | SUB[10:8] | SELECTOR[7:0]`, `addr8` = VALUE. Carriers:
**class 0 / VALUE 0x00 ×64**, **class 1 / VALUE 0x30 ×17**, and **9 kernel /
epilogue words with non-zero VALUEs** — 90 total, matching the established count.

| SUB | SEL | n | VALUEs | where |
|--:|---|--:|---|---|
| 4 | `0x63` | 53 | `00` ×53 | 25 body images — the `C63` word (§166 owns it) |
| 0 | `0xBC` | 24 | `30` ×17 (cls1), `00` ×7 (cls0) | 24 body images, all at w0/w1 — S-11 |
| 0 | `0x39` | 2 | `00` ×2 | `KERNEL w38` + `a00 NO OPERATION w18` |
| 0 | `0x21` | 3 | `50`, `70`, `90` | KERNEL ×2, EPILOGUE ×1 — `ldptr` |
| 0 | `0x25` | 3 | `25` ×2, `26` | KERNEL ×2, EPILOGUE — `ldptr.d` |
| 0 | `0x27` | 2 | `64`, `6C` | KERNEL |
| 0 | `0x22` | 1 | `86` | EPILOGUE w17 (`0x86` = the unit-1 output level) |
| 0 | `0x64` | 1 | `00` | `a10 MULTI TAP DELAY w26` — S-10 |
| **1** | `0x21` | **1** | `00` | `a10 MULTI TAP DELAY w33` — S-10, the only `SUB = 1` |

★ **`SEL 0x39` is a two-word family and it is an exact one-bit `f31` minimal
pair**: `809.0.00.839` (KERNEL w38, `f31 = 4`) ↔ `80B.0.00.839`
(NO OPERATION w18, `f31 = 5`), differing in `hi12` bit 1 and nothing else.
⛔ **Recorded as a DISTRIBUTION fact only.** The `f31 = 4/5` question is formally
closed on the clean vehicle, and this note does not reopen it. What the corpus
says, and only this: both halves *execute* — the kernel one every frame from cold
boot, the other in the image shared by 42 effect slots. Whether that changes
anything is for the owners of the closure to decide, not for this pass.

★ The corpus's **other** exact `f31 = 4 ↔ 5` minimal pair is
`028.2.00.000` ↔ `02A.2.00.000`, and **nine images carry both**
(EXCITER, COMPRESSOR, PARAMETRIC EQ, AUTO PAN, RING MODULATOR, PEQ+COMPRESSOR,
PEQ+COMPR+DIST, PEQ+DIST+DELAY, PEQ+OVERDR+DELAY). Same ⛔ caveat, same reason:
distribution only. ⚠ Note both are `ACT 0x00` words, i.e. inside the blind
population — see S-12.

---

## 3. STRUCTURAL ANALOGIES — measured with an alignment, not a similarity score

Method: reduce each image to its **skeleton** — the `(hi12, class4, lo12)`
sequence, `addr8` masked out — and align pairs with a diff. This says *where* two
programs differ and by how many words, which a coverage number cannot.
703 unordered pairs; median skeleton-LCS coverage **0.266**.

### 3.1 ★★★ The 9-word biquad section is a SPLICE UNIT, and the DRIVE family is one program plus two splices

```
   a32 DISTORTION  ->  a33 OVERDRIVE      |A|=42  |B|=63
        matched 39 words in 5 aligned blocks (1, 11, 11, 9, 7)
        REPLACE  A[13:14] -> B[16:25]     ONE word  ->  NINE words
        REPLACE  A[34:35] -> B[47:56]     ONE word  ->  NINE words
        INSERT   B[36:38] (2 words) + one 4-word head difference
```

The replaced word is `102.2.00.000` **both times**. The nine words that replace it
are, both times:

```
   102.A.00.1D3 | 212.A.01.412 | 202.A.01.1D5 | 202.A.01.1D4 | 202.A.00.1D5
   102.2.FF.687 | 804.8.16.415 | 212.A.FF.407 | 000.2.B4.647   (w24 / w55: B4 / B0)
```

which matches the documented 9-word biquad skeleton on `class4` **and** all
twelve `lo12` bits, **9 of 9** (only the first word's `hi12` differs, `102` vs
`000`).

★★★ **And the same edit appears in the combi pair:**
`a98 PEQ+DIST+DELAY → a99 PEQ+OVERDR+DELAY` matches **84 of 92** words in 5 blocks
and contains **two more 1→9 replacements** at `A[23:24]→B[23:32]` and
`A[69:70]→B[75:84]`. **4 of 4 splices are 1 word → 9 words**, two per program
(one per channel), in both the standalone pair and the combi pair.

**SPECULATIVE reading.** The microcode was assembled by a tool that can splice a
biquad section into a chain at a marked slot, and OVERDRIVE *is* DISTORTION with
a per-channel tone section spliced in. `programs.tsv` says as much for `a99`
(*"2 copies of OVERDRIVE, byte-for-byte"*); what is new is that the splice is
**one word wide on the receiving side**, which makes `102.2.00.000` a **splice
marker**, not a `nop`.

**Proposed cheap test — free, static.** Census every `102.2.00.000` in the corpus
and ask whether each sits where a section *could* be spliced (i.e. at a chain
boundary). If some sit mid-section, the marker reading dies. Second, free test:
the same 1→9 edit predicts that any future "X + tone" variant differs from X by
exactly two 9-word blocks.

### 3.2 ★★ The FLANGER stage ↔ VIBRATO stage substitution is 10 words → 4 words, 6 of 6 sites

| pair | shared contiguous run | the substitution |
|---|--:|---|
| `a04 FLANGER` ↔ `a50 VIBRATO` | **32** | 10 → 4, twice |
| `a66 S.DELAY+FLANGER` ↔ `a67 S.DELAY+VIBRATO` | **40** | 10 → 4, twice |
| `a73 PEQ+FLANGER` ↔ `a74 PEQ+VIBRATO` | **35** | 10 → 4, twice |

**3 of 3 pairs, 2 of 2 sites each = 6 of 6.** The FLANGER 10-word block is
```
   000.A.FF.1D5 202.A.48.1D5 202.A.B5.1D5 900.1.60.2D9 192.A.03.1D5
   182.2.48.000 000.2.00.44C 880.1.20.40B 012.2.01.655 104.2.00.1D5
```
and it **contains the `ACT 0x0C` word of S-3**, which is exactly why `ACT 0x0C`
exists in only four images. The VIBRATO 4-word block is the head of the chorus
voice macro (`900.1.60.1D5 | 192.A.41.000 | 082.2.00.1C0 | C40.3.20.44C`).

**SPECULATIVE reading.** "Modulated tap" is a macro with (at least) two
implementations — an all-pass form (10 words, with a delay-port hand-off) and a
delay-line form (4 words) — and the assembler substitutes one for the other
per effect, per channel.

**Proposed cheap test — free, static.** Predict: any *other* pair of effects
whose names differ only by FLANGER↔VIBRATO must show the same 10→4 edit twice.
The corpus has exactly three such pairs and all three obey; a fourth would be a
genuine out-of-sample test if the KN6000/KN7000 corpora carry one.

### 3.3 ★★ `MODULATED CHORUS` is `CHORUS` plus five insertions

`|CHORUS| = 70`, `|MODULATED CHORUS| = 85`. **69 of CHORUS's 70 words are
recovered in order**, in six aligned blocks of 5, 29, 4, 4, 1, 26; the differences
are five insertions totalling 16 words and **one** replaced word. This is the
closest non-identical pair in the corpus (skeleton coverage **0.986**).

**SPECULATIVE reading.** MODULATED CHORUS is CHORUS with a second modulation
source spliced in at five points; the "dual-rate ensemble" of `programs.tsv` is
one program, not two.

**Proposed cheap test — free, static.** Check whether the five insertions are
themselves instances of one macro (they should be an LFO block plus its
consumers). If they are five *different* things, the reading is wrong.

### 3.4 ★★ The "PEQ" in a PEQ+X combi is exactly TWO biquad sections and nothing else of PARAMETRIC EQ

`a39 PARAMETRIC EQ` (105 words) vs `a71 PEQ+CHORUS` (93): **22 words matched**,
and the two largest matched blocks are **9 words each** — `A[5:14]↔B[9:18]` and
`A[14:23]↔B[60:69]`, i.e. the two channels' heads, 51 words apart in the combi.
Same shape for `a72 PEQ+S.DELAY` (16 matched).

This is the **mechanism** behind `data/SPECULATIVE_PATTERNS.md` §4's number
(declared-base coverage 0.076–0.125) and behind its **SP8**: the head is not a
truncated PARAMETRIC EQ, it is **two instances of PARAMETRIC EQ's own 9-word
section macro**, which is 18 of 105 words — hence 0.086. SP8 keeps priority; what
is new is that the residual 4 words are all that is left over and the two blocks
are per-channel.

### 3.5 Near-twin table (skeleton coverage, top of 703 pairs)

```
   1.000  a32 DISTORTION      / a34 FUZZ                lcr 42   (control)
   0.986  a01 CHORUS          / a02 MODULATED CHORUS    lcr 29
   0.929  a33 OVERDRIVE       / a34 FUZZ                lcr 11
   0.929  a32 DISTORTION      / a33 OVERDRIVE           lcr 11
   0.925  a36 COMPRESSOR      / a75 PEQ+COMPRESSOR      lcr 20
   0.914  a01 CHORUS          / a71 PEQ+CHORUS          lcr 19
   0.913  a98 PEQ+DIST+DELAY  / a99 PEQ+OVERDR+DELAY    lcr 25
   0.884  a66 S.DELAY+FLANGER / a67 S.DELAY+VIBRATO     lcr 40   <- largest non-twin run
   0.864  a75 PEQ+COMPRESSOR  / a96 PEQ+COMPR+DIST      lcr 24
   0.844  a73 PEQ+FLANGER     / a74 PEQ+VIBRATO         lcr 35
```

★ **The largest shared CONTIGUOUS runs are between sibling combis (40, 35, 32),
not between a combi and its declared base.** This is the contiguous-statistic
version of `data/SPECULATIVE_PATTERNS.md` §4's *"every combi resembles another
combi more than it resembles its own bases"*, which was measured on subsequence
coverage only.

---

## 4. NEGATIVE RESULTS — looked for, NOT found

Cheap to record, expensive to rediscover.

* **N-1 — No image is a SUBSEQUENCE of another.** Over all **1406 ordered pairs**
  of the 38 images, under the skeleton key, the only containments are
  `DISTORTION ⊆ FUZZ` and `FUZZ ⊆ DISTORTION` (they are equal). **0 of 1404
  proper containments.** This is the strongest available form of "the combis are
  not their components concatenated" and it strengthens SP8 from a coverage
  statistic to an absolute.
* **N-2 — No image's word MULTISET is a subset of another's.** 0 of 1406. So no
  program is another program "with words removed", either — not even ignoring
  order.
* **N-3 — No second skeleton-identical pair.** Only `DISTORTION ≡ FUZZ`, out of
  703 unordered pairs.
* **N-4 — ★ NO FIELD VALUE PARTITIONS BY EFFECT FAMILY.** The brief asks whether
  any `f31` / `f98` value is confined to one family; testing every value of
  `f31`, `f98`, `class4`, `ACT` and `SRC` against the `programs.tsv` family
  column, **the only confinements are singletons**: `f31 = 6` → dynamics
  (2 words, 1 image), `f98 = 3` → rotary (2 words, 1 image), `ACT 0x16` and
  `ACT 0x1D` → rotary (1 and 2 words). **No value with more than 2 occurrences is
  family-confined.** ⇒ `f31` and `f98` are **poor targets for a family-based
  attack**; the testability ranking of §2.3 is the better route, and it says
  `f31` is tractable and `f98` is not.
* **N-5 — SP3's falsifier did not fire.** Class-6 `lo12 0x4CD` still takes only
  `{0x18, 0x28}`, 46 of 46. (What was found instead is S-9, a refinement.)
* **N-6 — No further exceptionless neighbour rule at |offset| ≥ 2 survives
  de-duplication.** The miner produced 70 exceptionless rules at offsets ±1..±3;
  after collapsing every rule that is a restatement of a known contiguous macro
  (the table-lookup core, the 9-word biquad, the 3-word LFO block, the CHORUS
  voice, the SINGLE DELAY head/tail), the survivors are exactly S-2 … S-6. There
  is no second `2D9`-shaped family hiding at distance.
* **N-7 — The D-RAM cell-liveness instrument was not built** (§0.5). Recorded
  here so the next reader of the brief's item 3 does not build it either.
* **N-8 — `f31` and `f98` show no positional preference worth reporting.** Their
  distribution over normalised body position is flat within noise once the
  terminator (which is owned by `data/F31_HIGH_findings.md`) is excluded.
* **N-9 — The stub effects contribute nothing and could not have contaminated
  anything.** All twelve collapse into `a00` before measurement (§0.1). Stated as
  a check that was run, not as an assumption.

---

## 5. Files and how to reproduce

Everything in this note was produced from `dsp/tools/pat_corpus.py` (the shared
loader and field decode) by throwaway scripts in a scratch directory; no new
tool was added to the tree and nothing was committed. The measurements are
reproducible from the loader plus:

* the neighbour miner: for every anchor family (exact word / `m8` /
  `lo12` / `(class4, SRC, ACT)`) with n ≥ 8, for offsets −3..+3, the most frequent
  value of each neighbour predicate, kept only when `k == n`, scored against the
  predicate's corpus-wide base rate by an exact binomial tail;
* the window miner: the same, for *"a word satisfying Q within ±K"*, null
  `1 − (1 − rate)^{2K}`;
* the minimal-pair census: all 759 distinct 36-bit words, XOR one `hi12` bit,
  membership test, then per-image co-residency;
* the skeleton aligner: `difflib` over the `(hi12, class4, lo12)` sequence.

---

## 6. SUMMARY — ten lines

1. **The three strongest candidates are S-1, S-2 and the bit-5 pair in §2.3(2).**
2. **S-1:** one instruction — `class 2, addr8 0x00, lo12 0x000` — carries **17
   distinct `hi12` values over 354 words**, and `a70 AUTO WAH+S.DELAY` carries
   **nine of them**. It is a controlled `hi12` experiment already sitting in ROM.
3. **S-2:** `lo12 0x1CD → lo12 0x40E` is **78 of 78** in 37 of 38 images
   (`P ≈ 10⁻¹⁰⁰`), and the converse is only 52 % — a producer/consumer pair on two
   undecoded ACTIONs covering 14.9 % of the plain corpus.
4. **§2.3(2):** `hi12` **bit 5 has no reading at all, yet two images run both
   halves of its minimal pair** — and the pair is `000.2.00.000`, the word the
   disassembler prints as `nop` 62 times.
5. ★ **THE SINGLE CHEAPEST TEST: load `a70 AUTO WAH+S.DELAY` once, instrumented,
   and log the machine delta across its nine `xxx.2.00.000` sites.** One image,
   one run, one instruction, nine `hi12` codes — and it settles S-1 *and* the
   bit-5 half of §2.3(2) in the same trace, because `a70` carries both `000` and
   `020`. Apply `action00-discriminator.md`'s blindness census first to strike the
   pairs that cannot resolve.
6. Free static tests that need no emulator at all: **S-5** (is the −99..−61 band
   inside the host's zero-fill?), **S-7** (do 704/384 correspond to a per-unit
   quantity?), **S-8** (use the SRC→ACT functional constraints as a filter on any
   candidate decode table), **§3.1** (is `102.2.00.000` a splice marker?).
7. **`f98` is the worst remaining target and now we know why:** 5 minimal pairs,
   **0 co-resident** — no single loaded program can ever show the difference.
8. **`f31` is far more tractable than `f98`** — 22 minimal pairs, 6 co-resident,
   12 images — but 70.5 % of its high codes sit on `ACT 0x00`, the blind ACTION.
9. **Negatives worth as much as the positives:** no image is a subsequence or a
   multiset subset of another (0 of 1406); no field value with n > 2 is confined
   to one effect family; `hi12` bits 0 and 6 have **zero** minimal pairs.
10. **Nothing here is evidence.** Every reading is SPECULATIVE, every count has
    its denominator, and the closed questions (`f31 = 4/5`, the bit-11 ALU route,
    `ACT 0x15`, dead ends #3 and #16) are cited as context and left closed.
