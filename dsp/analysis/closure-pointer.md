# The FRAME-CLOSURE constraint, and the missing D-RAM pointer reload

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-26**.
No hardware. Static analysis, the ROM corpus and constraint solving only; nothing
here is a recording or a measurement on a live chip.

Tool: [`../tools/closure_pointer.py`](../tools/closure_pointer.py) — stdlib only
apart from the ROM parser it borrows, re-runnable, and it prints every number
quoted below:

```
python3 dsp/tools/closure_pointer.py walk      # the per-slot frame walk
python3 dsp/tools/closure_pointer.py pools     # ★ the unit pools and their nets
python3 dsp/tools/closure_pointer.py sites     # ★ the ADMISSIBLE-SITE SET
python3 dsp/tools/closure_pointer.py demand    # what payload each site would need
python3 dsp/tools/closure_pointer.py variants  # is the failure a walk artefact?
python3 dsp/tools/closure_pointer.py window    # do the bodies clobber the latches?
python3 dsp/tools/closure_pointer.py fields    # exhaustive field search, five words
```

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **FORCED** / **CONSISTENT** /
**INFERRED** / **EDUCATED GUESS** / **OPEN**. Where the constraints admit several
assignments they are enumerated, not chosen.

---

## 0. Result in one page

| # | statement | label |
|---|---|---|
| **A** | ★ **The closure equation is DEGENERATE in the payload.** A single absolute reload at slot `S` gives `X = V + Δ(S+1..end)` for *any* `V`, so closure never determines what a load loads. What it determines is the set of admissible **SITES**. The brief's framing — "solve the payload from the closure constraint" — has no solution, and that is the finding, not a failure to find one. | **FORCED** |
| **B** | ★ **FALSIFICATION — the five `lo12 = 0x820` header words CANNOT be the frame-closing D-RAM pointer load, whatever their payload field is.** `X` must not depend on which algorithm is loaded (the DI latches are at fixed chip addresses). A reload at I-RAM 15/22/29/31/40 puts *both* body nets in its tail, and the unit-0 pool has **8 distinct net displacements over 37 distinct images**. The favoured candidate P-1 of `dsp-frame-advance.md` §3.3 / blocker #4 dies on siting, before payload is even reached. | **FORCED** (given the walk), **MEASURED** (the pool) |
| **C** | ★ **The admissible site set is I-RAM 50…78**, of which **60…78 (the output stage) is admissible unconditionally**. The upper bound comes from K6 §5's cross-frame feedback, which is genuinely origin-free; the lower bound from **B**. I-RAM 50…59 survives only because the unit-1 pool is **12 algorithms sharing ONE image** — a degenerate confirmation with no discriminating power, and it is labelled as such. | **FORCED** |
| **D** | ★ **The epilogue's tail is exactly −1** — `w79` is the only pointer-moving word in I-RAM 60…81 — so an epilogue-sited reload gives **`X = V − 1`**. That is, to the unit, the relation K6 §5 derived from the one-sample feedback loop by a completely different argument (`Y` = pointer at `w79`, `X = Y − 1`). **PREDICT-THEN-CHECK: HIT.** | **FORCED** + **MEASURED** |
| **E** | ★ **The identical problem is ALREADY SOLVED for the sibling resource, and the answer is a REGISTER, not an immediate.** K4 FORCED (items A–D) that the coefficient cursor must be rebased, that the rebase is in no body, that it **cannot carry its value as an instruction immediate**, and therefore that the chip holds a per-unit **base register** which something copies into the cursor. Every step of that argument transfers to the D-RAM pointer, and this pass supplies the missing measurements for the transfer. | **FORCED** (K4, for the cursor); **INFERRED (strong)** for the pointer |
| **F** | ★ **The closure criterion's own FORCED status does not survive.** It rests on K6 finding 4, whose step 1 is explicitly flagged "not origin-free — it uses the standing reading that `801.0.NN.821` loads the data pointer". **K3 withdrew that reading** (`0x821` is a C-RAM pointer, FORCED). With the premise gone and the pointer shared across the CALL boundary, **79 of 79 unit-0 images enter the kernel's I/O window `X+0..X+6`** and **10 of 79 touch an input latch**; the unit-1 image touches both latches at the cold-boot entry. "Read and never written" is false under the completed walk. | **MEASURED** — a **FALSIFICATION** of finding 5 as stated |
| **G** | **The failure is not an artefact of the walk model.** Six post-increment variants plus the save/restore sequencer were measured: residues **+121, +96, +11, +121, +121, +3, +7**. **None closes**, and the two that come closest destroy the pool constancy (29 and 31 distinct unit-0 nets instead of 8). A re-establishing mechanism is FORCED regardless of which variant is right. | **MEASURED** |
| **H** | **The five `0x820` words are not solved, and the field search says so cleanly.** Every contiguous bit-field of the 36-bit word was enumerated: **no field** makes all five "one past an END-OF-BLOCK word", "their own block's end", or "their own block's end + 1". K3's ζ reading does not become 5-of-5 under any alternative field. The one payload "hit" in the demand table is **below chance** (1 observed, ≈2.3 expected). | **MEASURED** |
| **I** | Housekeeping, both re-run after this pass: `dsp/verify.py` **BYTE-MATCH OK** (kernel + epilogue + 91 valid algorithm streams, 38 distinct images) and `tools/upd6383d_diff.sh` **MIRRORS AGREE — 3057/3057**. No `.dsm` was regenerated and neither disassembler was touched. | **MEASURED** |

**Nothing here is applied to the MAME device.** No word gains a semantic, no
frame is made to complete, and every currently-trapping word keeps trapping. The
product of this pass is a falsification, a localisation and a corrected label.

---

## 1. The closure equation, written out

Let `X` be the D-RAM operand pointer at PC-restart. The frame is a fixed slot
sequence; each slot `k` has a known displacement `d_k` (`class4 & 7 == 2` on a
non-C-format word moves the pointer by `(s8)addr8` — MEASURED; every other word
moves it by 0). Write `Δ(a..b) = Σ d_k` over slots `a..b`.

**With no absolute reload anywhere**, the pointer simply carries over:

```
   X_{n+1} = X_n + Δ(0..end)          =>  closure  <=>  Δ(0..end) ≡ 0  (mod 256)
```

MEASURED, cold-boot frame (chorus in unit 0, room reverb in unit 1), 285 slots:

```
   header  0..49        +6      dp X+0   -> X+6
   unit-0 body (CHORUS) -9      dp X+6   -> X-3
   header 50..59        +2      dp X-3   -> X-1
   unit-1 body (REVERB) -133    dp X-1   -> X-134
   epilogue 60..81      -1      dp X-134 -> X-135
   ------------------------------------------------
   net                  -135  =  +121 (mod 256)          FAILS
```

which is the ADVANCE pass's number, and matches the live core's `+121 on
1 130 880 of 1 130 880 complete frames` to the unit.

**With one absolute reload at slot `S` carrying payload `V`**, the pointer at the
end of the frame is `V + Δ(S+1..end)`, and that *is* the next frame's `X`:

```
   X = V + Δ(S+1..end)                              (★)
```

★ is satisfied by **every** `V`. It does not constrain the payload at all — it
*defines* `X` in terms of it. **This is the central structural fact of the pass
and it is why the brief's experiment cannot succeed as posed.** The previous
pass's `solve` subcommand already printed this degeneracy ("any V works") without
drawing the consequence; the consequence is drawn here.

So the question has to be re-aimed: **which `S` are admissible?**

---

## 2. ★ `X` must not depend on the algorithm — and that kills the header sites

### 2.1 The constraint

The two audio input latches sit at **fixed chip addresses**: the serial receivers
write them, no instruction does (K6 finding 4), and the kernel reads them at
`ptr+2` and `ptr+5` in its first twelve words. The kernel is *shared* — the same
60 words run for every effect. Therefore

> **`X` must be the same number no matter which algorithm pair is loaded.**

Apply that to ★: `X = V + Δ(S+1..end)`. `V` is an instruction immediate, fixed.
So **`Δ(S+1..end)` must be algorithm-independent**. And `Δ(S+1..end)` contains
whichever body nets lie downstream of `S`.

### 2.2 The measurement — `closure_pointer.py pools`

Each algorithm stream **hard-codes its own I-RAM load address** in its upload
record (PROVEN BY CONSTRUCTION, K5's bytecode rule), so the load address *is* the
unit the algorithm can occupy:

```
   load I-RAM  84 (unit 0):  79 algorithms,  37 distinct images,  8 distinct nets
       net   +5   x  1   algos [5]
       net   +6   x  1   algos [4]
       net +112   x  1   algos [39]
       net +240   x  2   algos [15, 53]
       net +247   x  4   algos [1, 2, 64, 71]
       net +249   x  5   algos [3, 50, 56, 67, 74]
       net +251   x 64   algos [0, 6, 7, 9, 10, 11, ...]
       net +252   x  1   algos [8]
       ==> NOT CONSTANT

   load I-RAM 200 (unit 1):  12 algorithms,  1 distinct image,  1 distinct net
       net +123   x 12   algos [16..27]
       ==> CONSTANT  -- but see 2.4
```

**Independent cross-check:** 79 + 12 = **91** and 37 + 1 = **38**, which is
exactly what `dsp/verify.py` reports (`91 valid algorithm streams (38 distinct
images)`). Two different code paths, same partition.

### 2.3 The conclusion — FORCED

| site region | tail contains | algorithm-independent? |
|---|---|---|
| I-RAM 0…49 (before the unit-0 CALL) | **both** body nets | **NO** — 8 distinct unit-0 nets |
| I-RAM 50…59 (between the calls) | the unit-1 body net | yes, degenerately (§2.4) |
| I-RAM 60…82 (the output stage) | nothing but kernel words | **YES, unconditionally** |

> ★ **The five `lo12 = 0x820` words are at I-RAM 15, 22, 29, 31 and 40. All five
> are in the excluded region. They cannot be the frame-closing D-RAM pointer
> load, and no choice of payload field can change that** — the exclusion is
> about *where the word is*, not what it carries.

That is the answer to TARGET 1's first question, and it is a **FALSIFICATION** of
`dsp-frame-advance.md` §3.3's favoured candidate **(P-1)** and of blocker **#4**'s
"could close the frame outright". K3 §5.3 was already unable to place these
words' payload; this pass says the closure constraint will never place it either,
so that avenue can be closed and the effort moved.

### 2.4 The honest weakness in the unit-1 row

The unit-1 pool's net is "constant" because **all twelve reverb presets share one
133-word image**. A constant computed from a single sample is not evidence. So
I-RAM 50…59 is *not excluded*, but neither is it *confirmed*: the corpus contains
no second unit-1 program with which to test it. Stated as a limit, because the
temptation is to read "CONSTANT" as support.

### 2.5 The upper bound: K6's cross-frame feedback excludes 79…82

K6 §5 derived, with no assumption about any pointer-load word: `w79` stores at
the cell the *next* frame's `iw2` reads — a one-sample feedback path. That
requires the pointer at `w79` to be `X + 1`. A reload sited at 79, 80 or 81 makes
the pointer at `w79` equal to `X + Δ(0..78)`, MEASURED **+122**, and the store
becomes an orphan. So:

```
   ADMISSIBLE SITES  =  I-RAM 50 .. 78      (unconditional part: 60 .. 78)
```

---

## 3. ★ The epilogue's tail is −1, and that is K6's equation

`closure_pointer.py sites`, tails computed slot-exactly:

```
   I-RAM  50  801.0.50.821   tail +124    X = V +124
   I-RAM  51  801.0.64.827   tail +124    X = V +124
   I-RAM  52  801.0.25.825   tail +124    X = V +124
   I-RAM  56  C64.6.A2.007   tail +123    X = V +123
   I-RAM  62  801.0.26.825   tail   -1    X = V   -1
   I-RAM  69  801.0.90.821   tail   -1    X = V   -1
   I-RAM  74  C16.9.AB.000   tail   -1    X = V   -1
   I-RAM  76  C00.9.84.000   tail   -1    X = V   -1
   I-RAM  77  859.0.86.822   tail   -1    X = V   -1
```

Every epilogue tail is **−1**, because `w79` (`012.2.FF.1CE`, −1) is the *only*
pointer-moving word in I-RAM 60…81 — `w80` and `w81` both carry `addr8 = 0`.

**PREDICT-THEN-CHECK.** Before computing the tails I predicted (scratch file,
Pred-4/Pred-5) only that closure would not pin `V`. What I did **not** predict,
and what fell out, is that the epilogue tail is exactly −1 — which makes the
closure relation `X = V − 1`, *identical* to K6 §5's `X = Y − 1` derived from the
feedback loop. Two independent routes, same equation, to the unit. **HIT.**

This matters because it means the two analyses are not merely compatible: the
closure constraint and the feedback loop are the **same statement seen from two
ends**, and any reload sited in 60…78 satisfies both automatically.

---

## 4. ★ The closure criterion's foundation — a label that does not survive

`dsp-frame-advance.md` §3.1 upgrades closure from "assumed" to **FORCED** via K6
finding 4: *X+2 and X+5 are read and never written across the whole frame,
therefore they are externally supplied, therefore their addresses are chip
constants, therefore the pointer must return.* K6's own §4.1 flags the soft step:

> "1. *A body writes them.* **No.** Simulated for all 38 images: 0 of 38 touch any
> of X+0..X+6 … **(This one step is not origin-free — it uses the standing reading
> that `801.0.NN.821` loads the data pointer**, which fixes the offset between `X`
> and the bodies' origins.)"

**K3 withdrew that reading.** `0x821` is a C-RAM pointer (item E, FORCED: its
three in-program payloads `0x70` / `0x50` / `0x90` are exact structural bases of
the host's C-RAM map, P ≈ 4e-6). With `ldptr` gone, the bodies no longer have an
origin of their own — under the ADVANCE pass's completed walk they inherit the
kernel's pointer, entering at `X + 6`.

`closure_pointer.py window`, re-running K6's step 1 with that origin:

```
   unit-0 body entry = X +6;  kernel I/O window = X+0..X+6;  latches X+2, X+5

   UNIT-0 POOL, 79 algorithms:
      images whose walk enters X+0..X+6 : 79 of 79
      images that touch an INPUT LATCH  : 10 of 79

   UNIT-1 POOL (1 image), at each of the 8 possible entries:
      unit-0 net  -16 -> entry X -8   window hits [0, 2]              LATCH [2]
      unit-0 net   -9 -> entry X -1   window hits [1,2,3,4,5,6]       LATCH [2, 5]   <- cold boot
      unit-0 net   -7 -> entry X +1   window hits [1,3,4,5,6]         LATCH [5]
      unit-0 net   -5 -> entry X +3   window hits [3,5,6]             LATCH [5]
      unit-0 net   -4 -> entry X +4   window hits [4,6]
      unit-0 net   +5 -> entry X +13  window hits []
      unit-0 net   +6 -> entry X +14  window hits []
      unit-0 net +112 -> entry X +120 window hits [1]
```

> ★ **K6 finding 5 ("the whole I/O window is touched by 0 of the 38 body images")
> is FALSE under the completed walk: 79 of 79.** And the cold-boot frame's reverb
> touches **both** latches. Finding 4 inherits it: "read and never written" is not
> a property of the corpus any more, it was a property of a withdrawn origin
> model.

### 4.1 The two packages — enumerated, neither chosen

The system is over-determined and there are exactly two coherent readings.

**PACKAGE A — the pointer really is shared, and there is no per-unit reload.**
Consequences, all forced: the bodies write into `X+0..X+6`; `X+2`/`X+5` are not
"externally supplied only"; K6 finding 4's FORCED label falls and with it §3.1's
justification of the closure criterion; the residue `+121` might then not be a
defect at all. Against it: the machine would be scribbling on its own input
window, and the two body entries would differ by an algorithm-dependent amount
(§5), which no sane kernel would rely on.

**PACKAGE B — the pointer IS re-established per unit, and by something we have
not decoded.** Consequences: K6 findings 4/5 survive intact, closure is FORCED,
and the `+121` residue is exactly the size of the hole. Against it: the three
named pointer registers are all spoken for — `0x821` is C-RAM (K3, FORCED),
`0x825` is the delay-DRAM descriptor pointer (K3/R3), `0x822 ← 0x86` is the
unit-1 output level (R2) — and `0x827` was **falsified** as the D-RAM origin at
**0 of 85** streams (`isa-adjudication.md` §5.1). So Package B needs a **fourth**
mechanism.

**Package B is the better bet, and §6 says what the fourth mechanism most likely
is.** But the choice is not made here, because the evidence that would make it is
a hardware trace or the datasheet, and we have neither.

---

## 5. TEST B corrected: not load-independent, but it forces a disjunction

The previous pass's tool printed "TEST B — the two-body-entry difference test.
**LOAD-INDEPENDENT**" and reported it FAILING (249 instead of 128). It is **not**
load-independent: the per-unit setup triple at I-RAM 50…52 sits between the two
entries, so a reload there rescues it trivially. The tool has been corrected.

What the test *does* force is worth more than what it claimed. The difference
between the two body-entry pointers is `net(body0) + Δ(50..58) = net(body0) + 2`,
and MEASURED over the pool that is

```
   {7, 8, 114, 242, 249, 251, 253, 254}          (8 values)
```

while `0xD0 − 0x50 = 128` is a constant. **128 is in none of them.** Therefore:

> **FORCED disjunction — EITHER a D-RAM pointer reload exists in I-RAM 50…58,
> OR the per-unit state-block bases `0x50` / `0xD0` are not reached through the
> mode-2 pointer at all** (i.e. the mode-1 register index space and the mode-2
> D-RAM are *not* one RAM, which `isa-adjudication.md` §5.1 leaves OPEN).

The kernel's own choice of addressing mode is **CONSISTENT** with the second
branch, and it is the neatest structural hint in this note. `w45` and `w53` do
the same job for the two units — same `lo12 = 0x20C`, same `hi12 = 0x010`
(accumulator store), K6 finding 7 identifies `w45`'s cell as the unit-0 body's
entry cell — yet `w45` is **class A = mode 2 (via the pointer)** and `w53` is
**class 9 = mode 1 (absolute index `0xD0`)**. The only structural difference
between the two sites is that a body has run in between. A designer whose
pointer is unpredictable after a body call would be *obliged* to switch to
absolute addressing for the second send, which is exactly what the microcode
does. **CONSISTENT, not FORCED** — the counter-argument is that `w55` and `w57`
(both class 2, +1 each) use the pointer right after `w53` anyway.

---

## 6. ★ The same hole is already closed for the coefficient cursor — and the answer is a REGISTER

This is the most useful thing in the note, and it is not new work: it is K4,
applied to the resource next door.

The **coefficient cursor** has the identical problem. MEASURED by the frame walk:
**73 cursor advances per frame**. The cursor-reset word form exists —
`801.0.00.021`, K3 item B, the register-load word with `lo12` bit 11 clear — and
**it is nowhere in the kernel**; corpus-wide it occurs **once**, in one effect
body (algo 39). So the cursor cannot be re-based by an instruction immediate in
the shared kernel either. K4 turned that into four FORCED items:

| K4 | statement |
|---|---|
| A | **A rebase must exist.** The unit-1 base is `0x90` in 12 of 12 reverb streams while the number of class-A words executed before the unit-1 body varies over 6…60 (24 distinct values). |
| B | **The rebase is in no effect body** (the intersection of the prefixes is empty; one image's first word *is* its first class-A word). |
| C | ★ **The rebase cannot carry its value as an instruction immediate.** Exhaustive search of every contiguous 8-to-16-bit field of all ten words in I-RAM 50…59: `0x90` appears **nowhere**. |
| D | ★ **Therefore the chip holds a per-unit BASE REGISTER and the rebase copies it into the cursor.** |

Every step transfers, and this pass supplies the missing measurements for the
transfer:

* **A′ — a re-establishment must exist for the D-RAM pointer**: §2, from the
  fixed-address latches and the 8 distinct unit-0 nets. **FORCED**, on the same
  logical shape as K4-A (a constant downstream requirement against a varying
  upstream count).
* **B′ — it is in no effect body**: K3 item K measured `lo12 ∈ {820,821,822,825,827}`
  at **0 of 2974** body words; and §2.3 excludes everything before I-RAM 50 anyway.
* **C′ — it does not carry its value as an immediate**: `closure_pointer.py demand`
  computes the payload each admissible site would need under each absolute anchor
  and checks it against every candidate field extraction. One "hit" (I-RAM 31,
  `V = 0x4B`, field bits[23:16] — the three extraction names that report it are
  literally the same field). Priced against its null: ~20 sites × ~15 distinct
  fields × 2 anchors ≈ 600 trials at ~1/256 each, so **≈2.3 hits are expected by
  chance and 1 was observed**. That is *below* chance and is **not evidence**.
  And the site it lands on is one of the excluded five.
* **D′ — therefore a per-unit POINTER-BASE register, loaded by something outside
  the setup blocks, is copied into the pointer.** **INFERRED (strong)**, by exact
  analogy with a FORCED result about the sibling resource in the same kernel.

### 6.1 And the epilogue is where this machine re-primes for the next frame

Three independent findings already say so, and closure now says it a fourth time:

| finding | what the output stage does for the *next* frame |
|---|---|
| K5 §2.4 | loads the two **CALL VECTORS** at I-RAM 64 / 71 — "the vector loaded in frame *n* is the one used in frame *n+1*, since the output stage runs after both calls" |
| `isa-adjudication` §6 | `w62 = 801.0.26.825` aims the **descriptor pointer** at unit 0's first descriptor cell `0x26` — "the frame *ends* by aiming the descriptor pointer at unit 0's first cell" |
| K4 §3.3 | the only word in the whole 3057-word machine carrying `0x90` as an aligned field is **I-RAM 69**, which runs *after* the unit-1 body — dismissed for the cursor rebase because that must precede the body, but it is exactly the shape of a **base-register load for the next frame** |
| **this pass** | the D-RAM pointer's re-establishment is admissible **only** at I-RAM 50…78, and unconditionally only at **60…78** |

So the favoured resolution, stated as a whole and as a prediction rather than a
claim:

> **The output stage I-RAM 60…78 re-primes the per-frame state — call vectors,
> descriptor pointer, coefficient base — and the D-RAM operand pointer is
> re-established by the same mechanism, from a register rather than from an
> immediate.** Under it `X = V − 1` (§3), which is K6 §5's relation.

**EDUCATED GUESS for which word.** Under the three named registers being taken,
the load is either an **undecoded epilogue word** or a **second use of a decoded
one**. The epilogue words at 60…78 that are not otherwise assigned are
`w63 (2A7.9.05.1C3)`, `w65 (200.1.8F.1C1)`, `w67 (980.5.20.402)`,
`w70 (2A6.1.85.0C7)`, `w73 (E30.C.00.404)`, `w74 (C16.9.AB.000)`,
`w75 (82E.8.0F.000)`, `w76 (C00.9.84.000)` and `w78 (A3C.D.9F.287)`. Three of
them (`w67`, `w73`, `w75`) are in the ADVANCE pass's blocker **#6** (other escape
words, mode ≠ 1) and two (`w74`, `w76`) are the unnamed pair in blocker **#4**.
Nothing selects among them, so nothing is selected.

---

## 7. Is any of this an artefact of the walk model?

It must not be, or it proves nothing. `closure_pointer.py variants` re-walks the
same frame under six alternative post-increment predicates plus the structural
alternative that the CALL/RETURN sequencer saves and restores the pointer:

```
   variant                                                  residue  u0 nets  u1 nets  closes?
   V0 baseline: (not C-format) and class4&7 == 2               +121        8        1   no
   V1 class4 == 2 only (class A does NOT move the pointer)      +96       29        1   no
   V2 C-format words post-increment too                         +11       10        1   no
   V3 END-tagged words do NOT post-increment                   +121        8        1   no
   V4 ESCAPE words do NOT post-increment                       +121        8        1   no
   V5 accumulator-store (hi12 bit 4) words do NOT post-inc       +3       31        1   no
   V6 CALL/RETURN saves+restores the pointer (kernel-private)    +7      n/a      n/a   no
```

**No row closes.** V2 and V5 come nearest numerically (+11, +3) and are the worst
on the criterion that actually matters — they take the unit-0 pool from 8
distinct nets to 10 and 31, making `X` *more* algorithm-dependent, not less. V6
is worth its own line: even if bodies were perfectly walled off from the kernel's
pointer, the kernel alone nets **+7** and still does not close.

> **A re-establishing mechanism is FORCED independently of which walk variant is
> correct.** The conclusion of §2 and §6 does not rest on the baseline predicate.

---

## 8. The five `lo12 = 0x820` words — an exhaustive negative

Since closure cannot place them (§2.3), the only cheap thing left is to test
K3 §5.3's readings directly. `closure_pointer.py fields` enumerates **every**
contiguous bit-field of the 36-bit word (lsb 0…32, width 4…13) and scores the
five values it yields:

```
   I-RAM  15  0C0A292820   C0A.2.92.820
   I-RAM  22  0C04312820   C04.3.12.820
   I-RAM  29  0C42457820   C42.4.57.820
   I-RAM  31  0C0A4B1820   C0A.4.B1.820
   I-RAM  40  0C4A1C0820   C4A.1.C0.820

   header END-OF-BLOCK words : [6,11,14,19,21,23,24,28,33,36,39,41,49,59]
   header BLOCK STARTS       : [0,7,12,15,20,22,24,25,29,34,37,40,42,50]
```

| predicate (K3 §5.3's ζ reading and its neighbours) | fields that satisfy it |
|---|---|
| all five are **END + 1** | only `bits[35:31]` = `[24,24,24,24,24]` and `bits[35:32]` = `[12,12,12,12,12]` — **constant across all five**, i.e. the top of the word, carrying no payload |
| all five are a **BLOCK START** | the same two constants, plus `bits[3:0]` = all zero |
| all five are **their own block's end** | **none** |
| all five are **their own block's end + 1** | **none** |
| all five are a multiple of 32 (K5's `0xC40`-family rule) | only constant or degenerate fields (`bits[12:6]` is just `addr8` bit 0 riding on the fixed `lo12 = 0x820`) |

> **K3's ζ reading does not become 5-of-5 under any contiguous field.** Its 4-of-5
> match was found under K5's `A = imm13>>5`, a rule K3 itself measured as
> `0xC40`-family-local (57/57 in, 2/11 out) and these five are in the "out" set.
> The reading stays an **EDUCATED GUESS**, and it now has an exhaustive negative
> against its strong form. **PREDICT-THEN-CHECK: MISS** — I expected some
> alternative alignment to rescue it to 5/5.

For the record, the published extractions:

```
   addr8  bits[19:12]   [146, 18, 87, 177, 192]
   imm13  bits[24:12]   [658, 786, 1111, 1201, 448]
   K5 'A' bits[24:17]   [ 20, 24, 34, 37, 14]
   K5 'B' bits[16:12]   [ 18, 18, 23, 17,  0]
```

**Disclosure, because predict-then-check demands it:** the `addr8` and `A` series
were already printed in `notes/dsp-frame-advance.md` §3.3, which the brief
ordered read first. So "predict the five values" was contaminated before this
pass began and no such prediction is claimed. What was predicted, and checked
below, is what the *closure equation demands* — a quantity nobody had computed.

---

## 9. What is FORCED / CONSISTENT / OPEN

**FORCED**

1. Closure is degenerate in the payload: one absolute reload closes the frame for
   any `V` (§1).
2. `X` must be algorithm-independent, therefore any site whose tail contains a
   varying body net is excluded; the unit-0 pool varies over 8 nets and 37 images
   (§2).
3. **The five `lo12 = 0x820` words cannot be the frame-closing load** (§2.3).
4. Admissible sites are I-RAM 50…78; 79…82 excluded by K6's cross-frame feedback
   (§2.5).
5. The epilogue tail is −1, so an epilogue-sited reload gives `X = V − 1`, the
   same equation K6 §5 reached independently (§3).
6. The two body entries differ by `net(body0) + 2 ∈ {7,8,114,242,249,251,253,254}`,
   never 128, so **either** a reload exists in I-RAM 50…58 **or** `0x50`/`0xD0` are
   not mode-2 addresses (§5).
7. A re-establishing mechanism exists under every walk variant tested (§7).

**CONSISTENT, not forced**

* The `w45` / `w53` mode split (mode 2 for unit 0, mode 1 absolute for unit 1)
  reads as "the pointer is not predictable after a body call" (§5).
* Package B (a per-unit re-establishment) over Package A (§4.1).
* `X = 0x8F` (from `w69`'s `0x90` and `X = V − 1`) — K6 §5's "for reference only"
  value, which this pass reaches by a different route but cannot confirm, because
  `w69`'s `0x821` is C-RAM (K3, FORCED) and must not be re-borrowed for the D-RAM
  pointer just because the arithmetic is tidy.

**INFERRED (strong)**

* By exact analogy with K4 items A–D for the coefficient cursor: the chip holds a
  **pointer-base register**, loaded from outside the setup blocks, and a kernel
  word copies it into the operand pointer — rather than any word carrying the
  origin as an immediate (§6).

**OPEN**

* Which word does it, and whether the mechanism is an instruction at all
  (a PC-restart hardware reset is not excluded; K6 §5 argues against it and the
  completed walk gives that argument a number — it would need `Δ(0..78) ≡ 1` and
  MEASURED it is **122** — but the argument is only as good as the walk).
* Whether the mode-1 register index space and the mode-2 D-RAM are one RAM
  (`isa-adjudication` §5.1) — §5's disjunction turns on it.
* What the five `lo12 = 0x820` words do. Closure says only what they are *not*.
* The absolute value of `X`.

---

## 10. PREDICT-THEN-CHECK log

Predictions were written to a scratch file before the corresponding measurements.

| | prediction | result |
|---|---|---|
| **P-1** | The closure equation is degenerate in the payload; it constrains the site set, not `V`. | **HIT.** §1 ★ |
| **P-2** | The admissible site set is exactly the epilogue (I-RAM 60…82), because both body pools vary. | **PARTIAL MISS, and the miss is informative.** The unit-**1** pool does *not* vary — it has one image — so the bound is I-RAM ≥ **50**, not ≥ 60. My prediction over-read `cells`' unwrapped body table (which mixes in the five malformed streams) as if both pools varied. Corrected in §2.4, and the degeneracy is flagged rather than counted as support. |
| **P-3** | All five `0x820` words are excluded regardless of payload field. | **HIT.** §2.3 |
| **P-4** | Nothing in the closure system pins `V`; the only absolute anchor is the conditional `dp@45 == 0x50`, giving `X = 0x4A`. | **HIT** on the structure. The anchor gives `X = 0x4A` (unit-0 form) and `X = 0xD3` (unit-1 form) — two *different* values from the same premise, which is itself a small result: the state-base anchor is **internally inconsistent** under the completed walk, exactly as §5's disjunction predicts. |
| **P-5** | K6 finding 9 adds no information about `V` because `w80`/`w81` have zero delta. | **HIT**, and sharper than predicted: finding 9's *within-frame* half ("`iw0` writes `X+0` and `w80`/`w81` read `X+0` in the same frame") is **equivalent to closure**, not independent of it — it is true iff the frame closes, and MEASURED it fails by exactly the residue. Its *cross-frame* half (`w79` → next frame's `iw2`) is genuinely origin-free and is what excludes sites 79…82. A label correction, not a falsification. |
| **P-6** | If the sequencer saved/restored the pointer, the residue would be the kernel-only **+7**, still not 0. | **HIT, to the unit.** V6 in §7. |
| **P-7** | (mine, immediately falsified) the C-format word `w15`, being class 2, post-increments by `s8(0x92) = −110` and the walk double-counts it. | **MISS.** `dsp_disasm.ptr_postinc()` is `(not c_format(w)) and (class4(w)&7)==2` — C-format words were already excluded. Recorded because I would otherwise have "found" a −110 that is not there. |
| **P-8** | Some alternative contiguous field rescues K3's ζ reading to 5-of-5. | **MISS.** §8: no field does, and the two that formally satisfy "END+1" are constant across all five words. |
| **P-9** | The demand table would contain a payload hit worth taking seriously. | **MISS, correctly priced.** 1 hit observed against ≈2.3 expected under the null, on an excluded site. Below chance. |

---

## 11. What this constrains in the other two targets

**TARGET 2 (the `lo12` ACTION field, the all-pass motif).** Two hard facts from
this pass bear on R1:

* **All twelve reverb presets share ONE 133-word image** (MEASURED here: unit-1
  pool = 12 algorithms, 1 distinct image). So *nothing* that distinguishes one
  reverb preset from another is in the microcode — it is entirely in the
  coefficient bank. Any role assignment R1 makes for the all-pass motif must
  therefore be **preset-independent**, and a candidate resolution that needs
  different behaviour per preset is falsified on sight.
* **The reverb body touches only 14 distinct D-RAM cells** in 133 words, spread
  over a 256-wide unwrapped span. The all-pass **delay line is therefore not in
  D-RAM** — it is the external delay DRAM, which is what R1's one-multiplier
  Schroeder reading assumes. And `880.1.20.655`, the all-pass core DRAM write, is
  **class 1 = mode 1 and moves the pointer by 0** (MEASURED), so the DRAM write
  and the D-RAM pointer walk are independent: the solver can vary one without
  disturbing the other.

**TARGET 3 (the LFO ramp).** The coefficient cursor has the **same closure hole**
as the pointer: **73 advances per frame** and no cursor-reset word anywhere in the
shared kernel (K3 item B's reset form `801.0.00.021` occurs once in the whole
corpus, in one body). K4 has already FORCED that a per-unit coefficient **base
register** must exist. Consequence for the LFO work: **do not assume the cursor is
0 at frame start, or that C-RAM `[+0]` / `[+1]` are absolute cells** — they are
cursor-relative, and where the cursor is when the LFO block runs is set by a
rebase this project has not decoded. The LFO's *rate* argument (114 / 2^23 ×
44100 = 0.5993 Hz) is unaffected, because it depends on the two constants' values,
not on their addresses.

---

## 12. Safety and housekeeping

* **Neither disassembler was touched**, and no `.dsm` was regenerated. Both were
  re-checked anyway:
  * `kn7000_mame/tools/upd6383d_diff.sh` → **MIRRORS AGREE — 3057/3057**
  * `dsp/verify.py` → **BYTE-MATCH OK** — kernel + epilogue + 91 valid algorithm
    streams, 38 distinct images
* **Nothing was applied to the MAME device.** No word gained a semantic; every
  currently-trapping word still traps; the `+121` residue is unchanged and is now
  *explained as a located hole* rather than treated as a defect to be patched.
* `closure_pointer.py` gained six subcommands (`pools`, `sites`, `demand`,
  `variants`, `window`, `fields`) and one correction (`anchors`' TEST B was
  labelled load-independent and is not). All eleven subcommands run clean.
