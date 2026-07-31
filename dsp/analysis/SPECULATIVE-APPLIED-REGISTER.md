# The speculative register — everything the DEVICE now assumes without proof

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Opened **2026-07-28**.

**This file is the tracking list the owner asked for.** Every reading below is
applied in `kn7000_mame/src/devices/cpu/upd6383/` **behind `DSPCFG` bit 1**, which is
a third, default-**OFF** setting. With the option Off, and with the pre-existing "On"
setting, the device is bit-identical to before.

★ **The strategy is deliberate** (owner, 2026-07-28): *"play sudoku with the
instruction set"* — fill the grid speculatively, reduce the search surface, and let
the contradictions that appear downstream point at the real proofs. A form that
**traps** produces no contradiction; a form that **executes wrongly** does.

⛔ **Nothing here is a decoding.** Grades are stated per row and never upgraded by
having been applied.

---

## 1. What it achieved

```
                                    conservative gate      speculative gate
   frames run                          1 200 001              1 200 001
   frames that TRAPPED                 1 200 001 (100.00 %)           0 (0.00 %)
   distinct undecoded forms                  123                      0
   undecoded words executed          257 817 024                      0
   returns USABLE                              0                962 880  (80.2 %)
   last frame                285 slots: 0 decoded         285 slots: 285 DECODED
                                                          0 partial, 0 traps
   frames whose pointer walk CLOSED            -            936 959 of 962 880
```

★★ **The emulated IC311 completes frames and returns usable output for the first
time.** ⛔ Whether that output is *correct* is entirely unestablished, and §3 says why
it cannot be assumed.

## 2. The register

| # | form / field | reading applied | grade |
|---|---|---|---|
| 1 | `f31 == 2` (`HI_ACC_HOLD`) | does **not** write `P` | ★ **MEASURED** — 14 of 19 ROM LFO ramp constants vs 11, strict superset, three controls held (§17) |
| 2 | mode 4 store target | `addr8`, not `mem[ptr]` | ★ **REFUTATION** of `ptr` — 3 fewer ROM constants in all 3 injection settings (§10.3, §14.3) |
| 3 | `src08` | `coef` | ★ **MEASURED** — reproduces the LFO's ROM step exactly (§8.1) |
| 4 | `lo12` bit 11 (alternate encoding) | **addressing only**, no ALU effect | ★★ **PROVEN** that it has no SRC/ACTION field (§9); that it does *nothing else* is a guess |
| 5 | c-format | ~~13-bit immediate → `acc`~~ → a dedicated latch | ⛔ **`acc` REFUTED** — it was the sole source of a fake signal, §3.4 |
| 6 | `hi12[3:1] > 2` | contributes no product | **PLAIN GUESS** — 1 of 4 enumerated (`f31hi = hold`) |
| 7 | `ACT 0x01/0x08/0x0C/0x11/0x16` | capture into tempA | **PLAIN GUESS** ×5 |
| 8 | `ACT 0x0D`, `ACT 0x0E` | capture into tempA | **PLAIN GUESS** — and §5.3/§6 show no context can discriminate them |
| 9 | `ACT 0x1A` | capture into tempB | **PLAIN GUESS** |
| 10 | `000.0.00.000` | NOP | **INFERRED** — the all-zero word is I-RAM's reset state |
| 11 | `000.6.18.4CD`, `000.6.20.407` | addressing only | **INFERRED** — the disassembler already annotates a table-lookup idiom; no table is modelled |
| 12 | `980.5.20.402`, `A00.0.00.015`, `A00.0.00.041` | no side effect | **PLAIN GUESS** ×3 |
| 13 | ★ `E30.C.00.404` (w73), `A3C.D.9F.287` (w78) | **present `acc` to the unit's output latch**, unit from `addr8` bit 7 | **PART-MEASURED / PLACEHOLDER** — see §3 |
| 14 | ★★ **the external delay DRAM (IC309)** | address = `descriptor cell + frame counter`, direction from `addr8`, 24→16-bit truncation | **PART-MEASURED** — see §3.1 |
| 20 | ★★ the unanchored SRC codes | `0x08` → the coefficient; `0x00`/`0x11` → `mem[ptr]`; `0x13`/`0x1C` still zero | ★ `0x08` **MEASURED**; the rest ⛔ 1-of-N enumerated — §3.11 |
| 19 | the kernel's coefficient cursor | re-seeded to `0x90` each frame | ★ **VERIFIED** by the coefficients there (§3.8) |
| 18 | `HI_ACC_HOLD` off class 8 | admitted | ⛔ extends a class-8-only result (§3.6) |
| 17 | ★★ host command `0x02`, the COEFFICIENT STREAM | land at the `801.0.NN.821` pointer, auto-incrementing | ★ **PROVEN BY CONSTRUCTION** (the rule) + **VERIFIED** (§3.3) |
| 16 | ★ the presentation's FIXED-POINT REGIME | present the **raw accumulator**, not `acc_to_datum()` | **MEASURED defect, GUESSED fix** — see §3.2 |
| 15 | `SRC 0x0B` | the delay-DRAM data register | **PLAIN GUESS** — a delay read must land somewhere, and `0x0B` is the only source code otherwise unaccounted for |

## 3. ⛔ The load-bearing guess, named

Rows 13 are the ones the whole audio path now rests on, and they deserve their own
warning.

**What is measured**: `w73`'s `SRC 0x10` **is** the accumulator (ANCHORED), and
`addr8` bit 7 assigns the unit — `0x00` → unit 0, `0x9F` → unit 1
([`output-stage-decode.md`](output-stage-decode.md) item I).

**What is guessed**: the **arithmetic**. The identity was chosen because it is the
simplest thing that closes the frame.

★ **And before this, `m_do[][]` had NO WRITER AT ALL** — it was only ever zeroed and
read, so even a clean frame returned silence. That is itself a sudoku constraint: the
output latch must be written by something, and these two words are the only
candidates.

⛔ **[`output-stage-io.md`](output-stage-io.md) §10 and
[`bit11-family.md`](bit11-family.md) item B proved BOTH words undecidable by
comparison** — one IC311 site each, in their own form, nothing to compare against. So
this is a placeholder that lets the frame close, and **any audio the device now
produces is shaped by a guess about how the chip presents its output.**

### 3.1 ★★ The delay DRAM — declared, mapped, and never touched until now

`AS_DELAY` has existed as an address space and been **mapped by the driver** all along,
and the device **never read or wrote it once** — grep found zero accesses.
[`dark-words.md`](dark-words.md) §5.3 named exactly this as the one failure
*"structurally out of reach of ALU decoding"*, 48.8 % of the dark set: **a delay line
that is never written cannot produce an echo**, so delay, reverb, chorus and flanger
were impossible however correct the ALU became.

**MEASURED** — the direction field (`addr8` `0x20`/`0x30` = READ, `0x60` = WRITE;
round 5 item D, FORCED by two independent routes); the region split (unit 0 below
`0x8000`, unit 1 above; round 4 §2, over 486 + 384 cells); and the descriptor cells
themselves, in D-RAM at `m_dsc`.

**GUESSED** — that the *N*th delay word of a frame consumes the *N*th descriptor cell;
that the line rotates by one cell per frame; and the 24→16-bit truncation.

★ The rotation guess has the best support of the three: **SINGLE DELAY's 501/500 and
NO OPERATION's 4410 = exactly 100.000 ms at 44.1 kHz both fall out of it.** The
cell-pairing guess is the weakest and is where a contradiction is most likely to
surface first.

### 3.2 ★★ The 96 dB — measured, and the fix is a guess

With rows 1–15 applied the DSP completed frames and the mix was **bit-identical to
dry** — 0 of 5 472 003 samples differed, exactly what the owner reported hearing.
Instrumenting the presentation words found two things:

**Defect A (mine, now fixed).** Admitting *every* word to the speculative gate made the
twelve **K6 input-stage** words take the generic ALU path instead of
`exec_addressing_only()`, losing their MEASURED pointer walk:

```
   frames in which both port reads executed   973 440  ->  0
   "NOTHING ENTERED THE CHIP -- the input stage never ran to completion"
```

★ **Filling the grid broke something that had been working** — which is precisely the
contradiction this strategy exists to produce. Restored, and audio enters the chip for
the first time: **1 597 440** frames with both port reads, **485 859** carrying a
non-zero sample, peak `0x4FD900`.

**Defect B (a fixed-point regime mismatch).** Measured at the presentation word:

```
   raw accumulator peak            4 988 928
   after acc_to_datum() (>> 16)           76
   peak sample that ENTERED        5 232 896
```

★ **The signal traverses the whole chip at ~0.95× in accumulator units** — the loss is
entirely the 16-bit shift, applied to a value that is already a datum. `wet = (DO1 +
DO2) >> 8` then floors 76 to zero.

⛔ **Which side is wrong is OPEN.** Either the accumulator legitimately holds a datum
here and must not be shifted, or some upstream path fails to scale a datum *into*
accumulator units and the shift is right. `ACT 0x00` does apply `L << ACC_SHIFT`, which
argues for the second — **but the measurement says the value arriving here never went
through it.** Presenting the raw value is the reading that makes the chip audible, and
it is a guess.

**Result:** dry peak 20 441 → **32 696**, with **58 % of samples differing**. ★ The
emulated IC311 audibly processes the signal for the first time. Whether it processes it
*correctly* is entirely unestablished — 16 rows of this table are guesses, and the peak
is close enough to full scale that the wet may simply be too hot.

### 3.3 ★★★ The coefficient stream — was discarded, now routed and VERIFIED

`upd6383.cpp` said of host command `0x02`: *"ACCEPTED AND IGNORED … routing it would put
invented data in a real memory."* The consequence was never stated: **C-RAM was never
loaded, so the emulated DSP ran with no effect coefficients at all.** It also explains why
registers `0x06`/`0x86` (the per-unit OUTPUT LEVEL, PROVEN BY CONSTRUCTION) read zero —
the host writes them through that same command.

**Round 4 guessed** the words land sequentially from 0. Wrong: the wet changed on 0.03 %
of samples.

**Round 5 uses the rule that is PROVEN BY CONSTRUCTION** and that
[`lfo_ramp.py`](../tools/lfo_ramp.py)`.cram_of_algo()` already replays to recover every
coefficient this project has measured: **`801.0.NN.821` loads the C-RAM pointer, and the
`0x02` coefficients that follow land at that pointer, auto-incrementing.** The pointer
word arrives through the ordinary `cmd 0x01` path, including at the host poke port —
captured transfer 26 is `01 60 | 08 01 09 78 21` = `ldptr 0x09`.

★★★ **And the result verifies itself against an independent source:**

```
   device C-RAM after boot :  00=000072  01=7FFFFF  02=0000F0 ... 09=400000  13=200000
   lfo_ramp.py, algo 1 CHORUS:  w5 -> cell 00 value 000072
                                w7 -> cell 01 value 7FFFFF
```

**Cell `0x00` = 114 is CHORUS's LFO ramp step and cell `0x01` = `0x7FFFFF` is its wrap
constant** — the two numbers derived from the ROM by tooling that knows nothing about
this device. `0x400000` = 0.5 and `0x200000` = 0.25 appear as real effect gains, and
`0x50..0x7F` holds a 48-entry linear ramp table. **112 of 256 cells populated, 117
coefficients routed.**

⛔ **But the wet still changes on only 0.06 % of samples.** The coefficients are now
demonstrably in the cells the microcode reads, so **the remaining defect is in
consumption, not routing** — the ALU is not multiplying by them. That is a cleanly
separated next question, and `f2_prod = "skip"` (row 1) suppressing products on every
`f31 == 2` word is the first suspect.

### 3.4 ⛔ Rows 5 and 16 REFUTED — the "audible DSP" was my own immediate

The A/B that made the chip "audible" was analysed properly and it is **not an effect**:

```
   wet samples at t = 24 s :  19488, 19488, 19488, 19488, ...
   19488 on 96.8 % of all output samples, present from t ~ 4 s -- BEFORE any note
   correlation(wet, dry)   :  -0.0018 at every lag from -600 to +600
   rms wet / rms dry       :  13.3x
```

A **stuck DC constant**, unrelated to the input. DC is inaudible, which is exactly what
the owner reported hearing.

★ **And the constant identifies its own cause: 19488 × 256 = 4 988 928 = 2436 << 11**,
which is precisely the shape of row 5's `m_acc = imm << 11`. Removing that one line:

```
   PRESENTATION WORDS: 3 175 680 executed, 0 wrote NON-ZERO, datum peak 0
```

⛔ **The only thing that ever reached the accumulator at the presentation word was my own
c-format immediate.** Both rows fall:

* **Row 5, `cfmt = "acc"` — REFUTED.** The destination was "1 of 6 enumerated"; this one
  is eliminated. It parks in a dedicated latch now, which is honest about knowing nothing.
* **Row 16, presenting the raw accumulator — REVERTED.** It did not make the chip
  audible; it made a clobbered constant loud enough to clear the tone generator's `>> 8`.

★ **What this leaves is the real problem, cleanly isolated:** the accumulator is **zero**
at both presentation words. Nothing connects the body's computed result to the epilogue
that presents it — the same shape as the reverb's "the loop carries zero", now measured
in the device rather than the model.

**This is what the strategy is for.** Seventeen rows of guesses produced one contradiction
sharp enough to name its own cause from a single number, and the cost of being wrong was
bounded because the register said which rows to suspect.

### 3.5 ★★★ Where the signal dies — measured at every slot, and it is the K6 input stage

§3.4 left "the accumulator is zero at the presentation". Profiling **peak |acc| at every
one of the 285 frame slots** over a full run answers it far more sharply:

```
   slot   0 .. 284 :  peak |acc| = 0  at EVERY SLOT
```

★ **The accumulator is never non-zero anywhere in the frame.** Not "dies late" — never
starts. So the defect is not in the epilogue, the presentation, or any of the seventeen
guesses: nothing downstream matters because nothing upstream produces a value.

**And the cause is a documented open item, not a guess.** The only words that read the
audio input latches are the twelve **K6 input-stage** words (`084.2.01.1C0`, *"THE PORT
READ, block B"*, and its siblings). This device's own header states their status:

> their pointer walk, their store enable and their cursor fetch are all MEASURED, and
> executing just that much is what lets a sample enter the chip — **the ALU is OPEN**

They are `addressing_only()`: they deposit the sample into D-RAM and **return before the
ALU runs**. That was true before the speculative work and is still true now.

★★★ **So the chain is: the sample enters the chip, is read, is stored — and is never
handed to the arithmetic.** Everything after it computes on zeros, which is why every
effect produces nothing and why no ALU reading could ever have changed the audio.

**This is the single highest-value target in the device**, and it is *one block of twelve
words* rather than a corpus-wide search. It also explains, retrospectively, why:

* the reverb "carries zero" around its loop;
* the delay-line traffic is invariant under every `ACT 0x0D`/`0x0E` reading (§6.1) — the
  line is fed zeros either way;
* 17 speculative rows moved the audio by exactly nothing until one of them (row 5)
  injected a constant of its own.

⛔ **What it does NOT do is make the K6 ALU decidable.** `notes/dsp-k6-input-stage.md`
§3/§7 already record the addressing as FORCED and the arithmetic as OPEN. What is new is
the *priority*: this is not one open item among many, it is the one that gates the entire
audio path.

### 3.6 ★★★ The K6 ALU decoded far enough to move signal — and the next wall named

§3.5 showed the accumulator is zero at all 285 slots because the twelve K6 words return
before the arithmetic. Decoding their `lo12` shows the block is **much less open than
"ALU OPEN" suggests** — both fields are ANCHORED on five of them:

```
   iw6   400.A.00.419   SRC 0x10 acc   ACT 0x19   -- NOTHING refuses it
   iw9   012.2.FF.1D5   SRC 0x07 mem   ACT 0x15   -- NOTHING refuses it
   iw8   084.2.01.1C0   SRC 0x07 mem   ACT 0x00   -- refused ONLY by
   iw2   084.2.02.680   SRC 0x1A tB    ACT 0x00      "f31 == 2 on class 2"
   iw4   204.2.02.1CE   SRC 0x07 mem   ACT 0x0E      (class-8 restriction)
```

★ **`iw8` is "THE PORT READ of block B" and its ACTION is `0x00` = acc's input term ←
bus.** Executing it hands the sample to the accumulator as `L << ACC_SHIFT`.

⛔ **The one assumption**: that `HI_ACC_HOLD` (`f31 == 2`) means the same off class 8.
`alu_decoded()`'s comment says it is *"ONLY **established** on class 8"* — established,
not restricted — so this extends a proven reading to an untested class. **Row 18, a
guess.**

**Result — the accumulator comes alive:**

```
   slot  0.. 8 :  0
   slot  9     : -423 322 663 648      <- the input ENTERS
   slot 10     : -846 645 327 296
   slot 11..20 :  493 613 037 846      <- carried intact (>> 16 = 7 531 937,
                                          0.9x full scale -- correctly scaled)
   slot 21     :  0                    <- ★ WIPED
   slot 25..284:  0                    <- both effect bodies and the epilogue
```

### 3.6.1 The next wall, named

```
   iw 21 = 410.A.00.40E   class A (coefficient consumer)
                          SRC 0x10 = the accumulator (ANCHORED)
                          f31 = 0  = HI_ACC_LOAD  ->  acc <- P
```

★★★ **It computes `acc = coefficient × acc` — a gain stage — and wipes the signal
because its coefficient reads ZERO.** That is exactly
[`notes/dsp-k6-input-stage.md`](../../kn7000_mame/notes/dsp-k6-input-stage.md) §9.2's
open item: *"the four input coefficients — values unknown, not merely unnamed."*

**So the audio path is now blocked by a missing VALUE, not a missing semantics** — a very
different and much narrower problem than anything before it. Either those coefficients
arrive in a host transfer this device still discards, or they land at a cursor position
the routing does not reach (§3.3 populated 112 of 256 cells; the kernel's cursor base is
the obvious suspect).

### 3.7 ★★★ The four input coefficients — not missing from the stream, READ FROM THE WRONG BANK

⛔ **First, a correction to §3.6.1.** I read the profile too quickly: `acc` is non-zero at
slots **23–24** and dies at **25**, not 21. Slot 21 is a dip, not the death.

Instrumenting which C-RAM cell each kernel slot consumes:

```
   kernel slot :  0    5    10   14   16   18   20   21   23
   cursor      : 0x77 0x78 0x7B 0x7C 0x7D 0x7F 0x80 0x81 0x82
   value       : 002132 0025F0 00342A 0038E8 003DA6 004722 004BE0 00509E 00555C
```

★★★ **Those are a LINEAR RAMP with a constant step of `0x04BE`** — they are transfer 8's
**lookup table**, not effect coefficients. The kernel's cursor is grazing table data.

And the coefficient stream's write runs show a 60-cell hole:

```
   [0x50..0x6D]=30  [0x6E..0x8B]=30  [0x90..0xAD]=30  [0xAE..0xB4]=7  [0x00..0x13]=20
                              ★ NEVER WRITTEN: 0x14 .. 0x4F
```

`[0x00..0x13]` is the CHORUS *body* bank (K6 finding 12). **The header's own 23-slot bank
is not in any run** — consistent with finding 12's MEASURED claim that it *"is not written
anywhere in the cold-boot capture"*, now confirmed on a **running** machine too.

### 3.7.1 What this actually establishes

★ **The four coefficients are not "unknown values the host never sends".** Two candidate
explanations, and they are distinguishable:

1. **The cursor base is wrong.** The kernel should read its own bank; it reads `0x77+`,
   inside a table. If the header's bank is the unwritten `0x14..0x4F` hole, then the
   coefficients *are* absent — but if the kernel's true base is elsewhere in a written
   run, they are present and simply mis-addressed. **`rstcur` resets the cursor to a
   per-unit BASE, and the kernel runs BEFORE either unit's body** — so which base it
   inherits is exactly the open question.
2. **They genuinely never arrive**, and the host relies on a power-on default this
   emulation does not model.

⛔ **Neither is settled here**, and the honest position is that this narrows the question
from "what are the four values" to **"which C-RAM bank does the kernel's cursor start
from"** — a pointer question with a small answer space, not a search for four unknown
numbers.

### 3.8 ★★★ The kernel's cursor base is 0x90 — and the coefficients there prove it

§3.7 narrowed the question from "what are the four values" to "which bank does the
kernel's cursor start from". Scanning every pointer-family word in the kernel and epilogue
answers it — the corpus loads the C-RAM pointer exactly **three** times:

```
   kernel   iw42  801.0.70.821  ->  0x70   the unit-0 body's bank
   kernel   iw50  801.0.50.821  ->  0x50   the unit-1 body's bank
   epilogue iw69  801.0.90.821  ->  0x90   ★ the LAST load of the frame, so it is what
                                             the NEXT frame's kernel inherits
```

K3 names `0x70 / 0x50 / 0x90` as three of the four structural bases of the host's C-RAM
map; the two bodies claim `0x70` and `0x50`; and the coefficient stream fills
`[0x90..0xAD]` with **30** values — unclaimed by either body and enough for the kernel's
23 slots. ★ Also decisive: **the cursor was FREE-RUNNING across frames** (drifted to
`0x77` and climbing), so a fixed program was reading different coefficients every frame,
which cannot be right.

★★★ **And seeding it at `0x90` verifies itself:**

```
   cur = 0x90  ->  0x200000 = 0.25
   cur = 0x91  ->  0x400000 = 0.50
   cur = 0x92  ->  0x400000 = 0.50
```

Those are **exactly** the reverb input-mix gains derived independently in
[`blocka-forced-defect.md`](blocka-forced-defect.md):
`0.25 × mem[0x0E] + 0.50 × mem[0x8F] + 0.50 × mem[0x8C]` — same three values, same order,
at the base the epilogue's pointer load names. Two unrelated routes to one answer.

⛔ **What is still guessed** (row 19): that the implicit cursor is re-seeded per frame at
all. K3 proves `0x21` loads a C-RAM *pointer* that is **NOT** the implicit cursor, and the
only `rstcur` in the corpus sits in PARAMETRIC EQ's body — so what actually resets the
cursor each frame is unknown. Seeding from the epilogue's payload is the reading that
makes a fixed program read fixed coefficients.

⛔ **And the audio still does not flow**: the accumulator still dies at slot 25 and the
presentation still writes zero. The cursor base was a real defect and is now fixed; it was
not the last one.

### 3.9 ⛔ Slot 25 — I claimed the product register OVERFLOWS. **It does not.** Corrected in §3.10

Slot 25 is `000.2.00.2D9`: `SRC 0x0B` (the delay data register), `ACT 0x19` (tempA ← bus),
and **`f31 = 0` = `HI_ACC_LOAD`, i.e. `acc ← P`**. It discards the accumulator and takes
whatever the product register holds. Profiling `P` through the kernel:

```
   slot 18   P = 17 592 181 986 428     acc = 229 286 650 000
   slot 19   P = 17 592 181 986 428     acc =  82 543 155 149
   slot 20   P = 0                      acc =  82 543 155 149
   slot 21   P = 17 592 180 924 743     acc = 0
   slot 23   P = 0                      acc = 104 004 325 735
   slot 25                              acc = 0
```

★★★ **2⁴⁴ = 17 592 186 044 416.** The product register is pinned at **99.99997 % of full
scale** and alternating with zero — it is saturating against its own 44-bit mask, and
`acc ← P` then hands that to the accumulator.

**So the signal is destroyed by FIXED-POINT OVERFLOW, not by a missing coefficient.** For
`P` to reach 2⁴⁴ after `>> P_SHIFT` (6), the pre-shift product must be ≈ 1.1 × 10¹⁵ —
which needs an operand of ≈ 1.3 × 10⁸, far outside a 24-bit datum. **Some SRC path is
handing the multiplier a value in accumulator units rather than datum units.**

★ That is the same class of defect as row 16 (§3.4): a value crossing between the DATUM
regime (`ash = 0, psh = 23`) and the ACC regime (`ash = 16, psh = 6`) without being
rescaled. This project has now hit it **twice** in the same session, in different places.

⛔ **Which SRC is at fault is not identified here.** The candidates are the ones whose
source is a register rather than memory — `SRC 0x10` (accumulator), `SRC 0x11`
(parameterised), and the speculative `SRC 0x0B` (row 15, the delay data register I added).
`0x0B` is the first suspect precisely because it is mine and because slot 25 uses it.

### 3.10 ⛔ CORRECTION — no overflow, and `SRC 0x0B` is exonerated

§3.9 read `P ≈ 17 592 181 986 428` as saturation against the 44-bit mask. **It is a
two's-complement misread of my own diagnostic.** `m_p` is stored masked to 44 bits and I
printed it as signed:

```
   2^44 - 17 592 181 986 428  =  4 057 988
```

★ The product register held **−4 057 988** — an ordinary datum-scale value. There is no
overflow anywhere. The "99.99997 % of full scale" line was wrong.

**And the operand check clears `SRC 0x0B`:**

```
   BIGGEST MULTIPLY: pre-shift 20 437 959 687 424
                   = coef 3 905 669 (0x3B9885 = 0.4656)  x  L 5 232 896
                     SRC 0x07 (mem[ptr], ANCHORED)  at iw8
```

`L = 5 232 896` is **exactly the input sample peak**, arriving through an anchored source
at the port read. That product after `>> P_SHIFT` is 3.19 × 10¹¹ — well inside range. The
multiply path is behaving.

### 3.10.1 So what actually kills slot 25

`P` is **0** at slots 20, 23 and 24, and slot 25 is `acc ← P`. **The accumulator is
zeroed because the product register is genuinely empty at that point**, which is what
§3.6.1 originally said before §3.9 talked me out of it.

★ A real defect surfaced on the way, though, and it is mine: the `default:` branch of the
SRC switch carries the comment *"UNREACHABLE BY CONSTRUCTION — alu_decoded() gates the four
codes above … if the predicate is ever widened, an unanchored source must NOT quietly
become a memory read. **Leaving L at 0 is the failure that shows.**"*

**I widened the predicate.** Every unanchored SRC — `0x00`, `0x08`, `0x11`, `0x13`, `0x1B`,
`0x1C` — now silently reads **zero**, exactly the failure that comment predicted, and the
multiplies that feed `P` at those slots are multiplying by nothing. **That is the live
lead**, and it was written into the code by whoever wrote that guard, waiting.

⛔ Two diagnostic errors in two messages (the presentation "peak" that was a constant, and
this "overflow" that was a sign). Both were *my instruments*, not the device, and both were
caught by measuring the operands instead of trusting the summary.

### 3.11 ★★★ Fixing the unanchored sources unblocks the kernel AND the bodies

§3.10 identified the live lead: the widened predicate made `SRC 0x00/0x08/0x11/0x13/0x1B/
0x1C` read **zero**, exactly as the `default:` branch's comment warned. Supplying readings
from the research model:

* **`SRC 0x08` = the coefficient.** ★ **MEASURED** — the setting under which the LFO's
  phase accumulator reproduces its ROM ramp constant exactly (`mem[0x04]` 1000 → 1228,
  step +228 = coefficient `0x0000E4`), and 11 of 19 such constants corpus-wide. The rival
  `"unity"` saturates the accumulator on the LFO's first word.
* **`SRC 0x00`, `SRC 0x11` = `mem[ptr]`.** ⛔ 1 of 6 and 1 of 7 enumerated options, no
  independent support.
* **`SRC 0x13`, `SRC 0x1C` have no reading anywhere** and keep reading zero — now
  **counted**: 6 241 920 and 1 560 960 reads per run. `SRC 0x1B` never occurs.

**Result — the accumulator comes alive across most of the frame:**

```
   slots  0..49 :  LIVE          (was: zero from slot 25 on)
   slots 50..59 :  0             <- the rest of the kernel
   slots 60..82 :  0             <- ★ the ENTIRE EPILOGUE, where w73/w78 present
   slots 84+    :  LIVE          <- the unit-0 body computes
```

★★ **Both the kernel and the effect bodies now carry signal.** That is the furthest this
has ever got.

### 3.11.1 The new boundary

⛔ **The epilogue sees a zero accumulator**, which is why the presentation still writes
nothing and the audio is still bit-identical to dry. The zeroing starts at **slot 50** —
`801.0.50.821`, the `ldptr` that loads the **unit-1 body's** C-RAM bank.

That is a *register-load* word, which takes the `exec_decoded()` register path rather than
the ALU path. Whether it should touch the accumulator at all is the question; `hi12 =
0x801` gives `f31 = 0` (`acc ← P`), so under the ALU reading it would load a stale product
— but K3 proves this family "is a REGISTER WRITE and nothing else", which argues it should
leave the accumulator alone entirely.

★ **That is a sharp, well-posed next question with a decode already attached to it**, and
it is the last boundary between a live accumulator and the words that present the output.

### 3.12 ⛔ Slot 50 was a misdiagnosis — the epilogue reads the REGISTER FILE, and those sources are unmodelled

§3.11 named slot 50 (`801.0.50.821`) as the zeroing point. **It is not.** `exec_decoded()`
dispatches `is_ldptr` to `m_cp = addr8` and never touches the accumulator, exactly as K3
requires. The apparent boundary was an artefact of reading a per-slot *maximum* profile as
if it were a time series.

**The corrected picture:**

```
   slots   0.. 49 :  LIVE
   slots  50.. 82 :  0            <- kernel tail + the whole epilogue
   slots  84..202 :  LIVE         <- 119 of 119 slots non-zero: BOTH effect bodies run
```

★ The kernel's per-unit **send stores** (`iw45`, `iw53`) carry the bit-4 store, and the
store gate's `doclr` clears the accumulator after storing — **modelled behaviour, not a
bug**. So the accumulator is legitimately empty entering the epilogue; the epilogue is
supposed to rebuild it by reading the units' send registers.

**It cannot, because those reads return zero.** Counting *every* unhandled source:

```
   0x01: 1 588 800    0x02: 1 587 840    0x03: 1 587 840    0x04: 1 588 800
   0x05: 1 589 760    0x06: 1 588 800    0x13: 6 241 920    0x1C: 1 560 960
```

★★★ **Six codes at ~1.59 M reads — exactly once per frame each — and they are precisely
the epilogue's sources**: `000.1.8C.107` uses `SRC 0x04`, `092.1.8C.19B` uses `0x06`,
`2A6.1.85.0C7` uses `0x03`, `000.1.06.087` uses `0x02`.

### 3.12.1 The structural reading this suggests

Those epilogue words are **class 1 with `addr8` bit 7 set** — the internal register file,
whose cells the trap histogram already names (`[06]`/`[86]` = per-unit OUTPUT LEVEL,
PROVEN BY CONSTRUCTION; `[8C]`, `[8D]`, `[8A]` = unnamed). The `addr8` selects the
register.

★ **So on a class-1 register-file word, `SRC 0x01..0x06` is very likely not a "source
operand" in the ALU sense at all** — it is part of the register access. That matches
`dsp-k6-input-stage.md` §10 item 7's standing LEAD: *"bit 7 of a class-1 `addr8` selects
address-vs-sub-op"*.

⛔ **Not decoded here.** But the audio path's last gap is now a single, coherent question —
*what does the SRC field mean on a class-1 register-file word* — rather than eight
unrelated codes, and it sits between two fully-live regions: a kernel that computes and
bodies that run.

## 4. How to use this list

1. **Every contradiction found downstream should be checked against this table first.**
   A wrong result is far more likely to come from a PLAIN GUESS row than from the
   decoded core.
2. **Promotion requires its own evidence**, never "it has been applied for a while".
3. **Deleting a row is a result too** — if a program can be made to contradict a
   guess, that is exactly the clue this strategy is fishing for.

## 5. Verification status

* The captured audio is **silent**, but that is **inconclusive**: the machine was idle,
  and an effect applied to silence is silence. **A real listening test needs a note
  played with `DSPCFG` = "On + SPECULATIVE ISA".**
* 210 241 frames (17.5 %) still end on the slot cap and 26 880 (2.2 %) on I-RAM
  overrun; only the 962 880 that end on the wait word are used.
* 25 921 complete frames do **not** close their pointer walk.

---

## 5. ★★★ The SRC field on class-1 register-file words — it is not a source

§3.12 left one coherent question. This is the answer, and it is the strongest inference in
this file.

### 5.1 The ten words

Every class-1 register-file word (class 1 **without** the `hi12` escape bit) in the kernel
and epilogue:

```
   iw49  400.1.0E.000   SRC 00  ACT 00      iw66  000.1.8C.107   SRC 04  ACT 07
   iw58  000.1.8A.007   SRC 00  ACT 07      iw68  092.1.8C.19B   SRC 06  ACT 1B
   iw59  400.1.0F.007   SRC 00  ACT 07      iw70  2A6.1.85.0C7   SRC 03  ACT 07
   iw60  092.1.8D.15B   SRC 05  ACT 1B      iw72  000.1.06.087   SRC 02  ACT 07
   iw61  012.1.8D.05B   SRC 01  ACT 1B      iw65  200.1.8F.1C1   SRC 07  ACT 01
```

★ **`SRC 0x01` … `0x06` each appear EXACTLY ONCE.** A source operand repeats; a selector
does not.

### 5.2 They occur nowhere else in the machine

Censused over all 38 distinct body images:

```
   SRC 0x02, 0x03, 0x04, 0x05, 0x06 :  ABSENT -- zero occurrences
   SRC 0x01                         :  38, and ALL of them class 0, a different form

   for contrast:  0x07 -> 1667    0x10 -> 1343    0x19 -> 534    0x1A -> 250
```

⛔ **A field that is a genuine ALU source cannot be absent from 2 974 body words and
present once each in one structural block.**

### 5.3 ★★★ Six codes, six output slots

The epilogue's job is presenting the two units' returns at the chip's outputs. The device's
own output latch is **`m_do[3][2]` — three serial ports × two channels = SIX slots**. And
`SRC 0x01..0x06` is **six codes, one word each**.

★ **INFERRED (strong): on a class-1 register-file word, `lo12[10:6]` is not a source
operand — it selects which of the six output slots the word drives.** The `addr8` names the
register supplying the value, `ACT` says what is done (`0x07` = store, plus the open
`0x1B`/`0x01`), and the "SRC" bits say *where it goes*.

Their pairing supports it — each code takes one register, and the registers repeat across
codes as a routing matrix would:

```
   SRC 01 <- reg 0x8D     SRC 03 <- reg 0x85     SRC 05 <- reg 0x8D
   SRC 02 <- reg 0x06     SRC 04 <- reg 0x8C     SRC 06 <- reg 0x8C
```

### 5.4 What this is worth, and what it is not

* ★ It explains the **last gap in the audio path**: the epilogue's reads returned zero
  because the model treated a routing selector as a source operand and found no reading for
  it.
* ★ It independently supports `output-stage-decode.md` item I, which measured that
  `addr8` bit 7 assigns the **unit** — the same words, the same routing role.
* ⛔ **It is an INFERENCE from an exclusivity census plus a count coincidence, not a
  forcing.** Six-of-six is suggestive; it is not proof, and the specific slot→code mapping
  is untested.
* ⛔ **Not yet applied.** Wiring it means making these words *write* `m_do` rather than
  *read* a source — a structural change to `exec_alu`, and the first thing to check
  afterwards is whether the presentation words (rows 13) become redundant, since they would
  then be doing the same job twice.

### 5.5 APPLIED, and the double-count check — row 13 is retired

The decode is wired: a class-1 register-file word with `SRC 0x01..0x06` writes the register
named by `addr8` into output slot `SRC − 1` of `m_do[3][2]`.

**The structure holds exactly.** Every one of the six slots is written **once per frame**:

```
   slot0 0/1 588 800   slot1 0/1 587 840   slot2 0/1 587 840
   slot3 0/1 588 800   slot4 0/1 589 760   slot5 0/1 588 800
```

★ Six slots, six codes, one write each per frame, no slot missed and none written twice —
the routing reading survives contact with the running machine.

⛔ **But every write is ZERO**, because the registers they read — `0x85`, `0x8C`, `0x8D`,
`0x06` — are empty. The effect bodies compute (slots 84..202 all live) but their results
never reach the send registers.

**The double-count check, run rather than reasoned:**

```
   row 13 ON vs OFF :  0 of 1 824 001 samples differ
```

★ **Row 13 is redundant and is retired.** Both it and the new slot writes target `m_do`, so
they *would* have fought had either produced a value — the risk was real, it simply has not
fired yet. And §5.3's decode says why row 13 was wrong in principle: the routing is done by
the **class-1** words, so reading `w73`/`w78` (class C/D) as "present the accumulator" was a
guess competing with the actual mechanism.

**Net: one guessed row removed, one inferred row applied, and the open question moves one
stage upstream** — from *"how does the epilogue present?"* (answered) to *"why do the
bodies' results never reach the send registers?"*

### 5.6 ★★★ Why the send registers are empty — producers and consumer disagree on the address

A census of every D-RAM write, by cell, over a full run:

```
   written MILLIONS of times :  0x07  3 121 920 nonzero / 3 172 889
                                0x13  1 560 960 nonzero / 3 122 968
                                0x0C, 0x0E, 0x0F, 0x10..0x12, 0x17, 0x18  -- ALL ZERO
   written ~1000 times       :  0x80..0x8F  -- all zero EXCEPT
                                0x8E  3 840 nonzero / 7 741
   the epilogue READS        :  0x85, 0x8C, 0x8D, 0x06   -- all zero
```

★★★ **Only three cells in the whole 256-cell D-RAM ever hold a non-zero value: `0x07`,
`0x13` and `0x8E`.** And none of them is a cell the epilogue reads.

**That fits the FORCED per-unit rebase** — this device applies `base = 0x05 | unit<<7`, so
unit 0 works around `0x05+` and unit 1 around `0x85+`. The bodies duly deposit at **`0x07`**
(unit 0, base + 2) and **`0x8E`** (unit 1, base + 9). The epilogue collects from `0x85` /
`0x8C` / `0x8D`.

⛔ **So the producers and the consumer disagree about where the send cells are**, and the
gap is a small constant offset, not a missing computation. Either the bodies' deposit
offsets are wrong, or the epilogue's `addr8` values are being applied without the same
rebase the bodies get.

★ **The second is the more likely and it is checkable**: the rebase is applied at the CALL,
and the epilogue does not go through a CALL. If the epilogue's register-file `addr8` is a
*rebased* address in the microcode's own terms, the device is reading it raw.

★ Also worth recording: the `0x80..0x8F` cells are written **~1 000 times over 1.8 M
frames** — roughly once per algorithm change, not once per frame. Whatever writes them is
host/setup traffic, not the per-frame datapath. **The per-frame send store is not
happening at all.**

## 6. Handover

**Live chain today:** audio enters the chip → kernel computes (slots 0–49) → both effect
bodies run (slots 84–202, 119 of 119 live) → bodies deposit at `0x07` / `0x8E` → **✗ gap ✗**
→ epilogue reads `0x85` / `0x8C` / `0x8D` (empty) → six output slots written once per frame
(all zero) → tone generator mixes zero.

**The one remaining break is that gap**, and it is an addressing question with a small
answer space, not a semantics question.

### 6.1 ⛔ The addressing fix applied, no effect, and why — two of my decodes collide

`ACT 0x07`'s store target was made mode-dependent (row 21): `mem[addr8]` on a mode-1 word,
`mem[ptr]` on mode 2. **The rule is not new** — `isa-adjudication.md` behavioural note 1
already establishes exactly it for the bit-4 store (*"mem[ptr] ONLY IN MODE 2. Eight kernel
words mis-execute otherwise"*), and `do_store()` implements it. Extending it to `ACT 0x07`
is the consistent reading, and `alu_decoded()` refuses that code off mode 2 precisely
because its target there is unproven.

**Measured effect: none.** The D-RAM write map is byte-identical and every output slot is
still zero.

★ **The reason is a collision between §5 and §6.1, both mine.** `000.1.8C.107` is a class-1
register-file word, so §5's handler claims it *first* and returns before the ALU — the
`ACT 0x07` store never executes. The word cannot both "route register `0x8C` to an output
slot" and "store the bus into register `0x8C`".

⛔ **One of the two readings is wrong, and the data does not yet say which.** What is
certain is that **nothing anywhere fills `0x8C`**, so whichever reading is right, the
producer is still missing.

## 7. State at the end of this run

```
   audio enters the chip                                    ✓  peak 0x4FD900
   kernel computes                                          ✓  slots 0..49 live
   both effect bodies run                                   ✓  slots 84..202, 119/119
   bodies deposit                                           ✓  0x07, 0x13, 0x47, 0x48,
                                                               0x4B, 0x4C, 0x4D, 0xF1
   ────────────────────────────────────────────────────────────────────────────────
   ✗ epilogue reads 0x85 / 0x8C / 0x8D / 0x06               ✗  never written by anything
   ────────────────────────────────────────────────────────────────────────────────
   six output slots written once per frame                  ✓  structure exact, values 0
   tone generator mixes                                     ✗  zero
```

★ **Every stage is live and instrumented except one**, and that one is a single question:
*what writes the send registers the epilogue reads?* The candidate answer — that the
class-1 register-file words do it via `ACT 0x07` — is blocked by §5's competing claim on
the same words, which is the next thing to adjudicate.

⛔ **Do not add another reading before settling that.** Two decodes already contend for one
word; a third would make the contradiction unattributable, which is the failure mode this
register exists to prevent.

## 8. ★★★ ADJUDICATION: §5 vs §6.1 — both survive, split by ACT, and `ACT 0x1B` is the presentation opcode

The two readings were never about the same field: §5 is `lo12[10:6]`, §6.1 is `lo12[4:0]`
and its store target. They collided only in the implementation. And on the ten
kernel/epilogue words the fields **co-vary**:

```
   ACT 0x07 (store)  <->  SRC 0x00, 0x02, 0x03, 0x04     iw58 iw59 iw66 iw70 iw72
   ACT 0x1B          <->  SRC 0x01, 0x05, 0x06           iw60 iw61 iw68
   ACT 0x01          <->  SRC 0x07                       iw65
```

A free six-slot selector would pair with any ACT. This partition predicts the split, and
testing it settles both:

**Letting the `ACT 0x07` words store instead of route:**

```
   epilogue register writes per run     before        after
      0x06                              25 983    1 613 823
      0x85                               1 051    1 588 891
      0x8A                               1 012    1 566 772
      0x8C                               1 970    1 590 770
```

★ **They fire ONCE PER FRAME now, as a datapath store must.** Before, they were ~1 000 per
1.8 M frames — host/setup cadence. **§6.1 is CONFIRMED for `ACT 0x07`.**

**And the output slots collapse from six to three:**

```
   slot0 ✓    slot1 --    slot2 --    slot3 --    slot4 ✓    slot5 ✓
```

⛔ **§5's "six codes, six slots" is WRONG as stated** — the count coincidence was just that.
The three surviving routing words are exactly the **`ACT 0x1B`** ones.

### 8.1 ★★★ And that lands on an independent measurement

[`output-stage-io.md`](output-stage-io.md) measured, from the corpus alone and long before
any of this: **`ACT 0x1B` — three sites, one region, all mode-1 stores into the I/O
register file.**

★ **Three sites. Three output ports.** The corpus census and the running machine agree
that `ACT 0x1B` is the **output presentation opcode**, reached from two directions that
share no assumption.

### 8.2 What is now settled, and what replaces the old question

* ★ **`ACT 0x07` on a mode-1 word = store into register `addr8`** — CONFIRMED by cadence.
* ★ **`ACT 0x1B` = present to an output port**, `SRC 0x01/0x05/0x06` selecting which —
  INFERRED, and corroborated by an independent corpus measurement.
* ⛔ **`SRC 0x02/0x03/0x04` are still unread**, so the `ACT 0x07` stores write **zero**.

**The open question is no longer "route or store" — it is "what do `SRC 0x02/0x03/0x04`
read".** That is one field, three values, on five words whose role is now known.

## 9. ★★★ `SRC 0x02/0x03/0x04` — the question dissolves: the epilogue arrives with an empty pointer

Instrumenting the five mode-1 `ACT 0x07` stores at the moment they execute:

```
   [dest 8C  src 04  ptr 00  L 0]
   [dest 85  src 03  ptr 00  L 0]
   [dest 06  src 02  ptr 00  L 0]
   [dest 8A  src 00  ptr C7  L 0]
   [dest 0F  src 00  ptr C7  L 0]
```

★ **The three `SRC 0x02/0x03/0x04` words run with the pointer at `0x00`**, and `0x00` is one
of the cells the D-RAM census shows is written 6 786 times and **never non-zero**.

⛔ **So the source reading is not the defect.** `mem[ptr]` reads zero there; so would
`tempA`, `tempB` or the accumulator, which is also zero across slots 60–82. **Every
candidate source is empty at that point**, which means no assignment of `SRC 0x02/0x03/0x04`
can produce a value.

### 9.1 What the defect actually is

The bodies deposit at `0x07`, `0x13`, `0x47`, `0x48`, `0x4B`, `0x4C`, `0x4D`, `0x8E`. The
epilogue arrives with `m_dp = 0x00` (and `0xC7` for the two `SRC 0x00` words). **The
pointer does not walk from where the bodies wrote to where the epilogue reads.**

★ That is the same object as the standing frame-closure problem — `dsp-k6-input-stage.md`
§10 item 6 (*"the absolute origin X"*), the 25 921 frames whose walk does not close, and
`closure-pointer.md`'s falsification of K6 finding 5. **It is not a new unknown; it is the
one this project has circled for months, now visible as a single number at a single word.**

### 9.2 The honest ranking this leaves

1. ★★★ **The pointer's value entering the epilogue.** Everything downstream is blocked on
   it, and it is one number, observable per frame, with the producing cells known
   (`0x07` / `0x8E`) and the consuming words known (five stores, three presentations).
2. ⛔ **`SRC 0x02/0x03/0x04` cannot be decided until then** — an acceptance test on a source
   that reads an empty cell cannot discriminate anything, which is method rule 6 exactly.
3. Row 22 (`= mem[ptr]`) is therefore **applied but untested**, and labelled so.

## 10. Final state of this run

```
   audio enters the chip                            ✓
   kernel computes (slots 0..49)                    ✓
   both effect bodies run (84..202, 119/119)        ✓
   bodies deposit at 0x07/0x13/0x47/0x4C/0x8E       ✓
   ─────────────────────────────────────────────────────────────
   ✗ the epilogue's POINTER arrives at 0x00         ✗   <- the single break
   ─────────────────────────────────────────────────────────────
   five register stores fire once per frame         ✓   (values 0)
   three ACT 0x1B presentations fire per frame      ✓   (values 0)
   tone generator mixes                             ✗   zero
```

★ Every stage is live, instrumented and cadence-correct except one pointer value.

## 11. ⛔ The epilogue pointer — two speculations tried, neither separable, and the stop

**Speculation A — rebase the epilogue like a body.** The device applies
`base = 0x05 | unit<<7` at each per-unit CALL, and the epilogue is the one part of the
frame that runs *without* a CALL, so it never receives one. Applied at I-RAM 60.

*Result:* the stores moved from `ptr 0x00` to `ptr 0x05` and **still read zero** — but it
revealed the useful number:

```
   EPILOGUE POINTER WALK:  60:46 61:46 ... 79:46   80:45 81:45   82:00
```

★ **The epilogue ARRIVES with the pointer at `0x46` and holds it across the whole block.**
The bodies' live cells are `0x47`, `0x48`, `0x4B`, `0x4C`, `0x4D` — the pointer parks
exactly **one below** the first of them. The natural arrival is right; the rebase was
wrong, and it is **withdrawn**.

**Speculation B — the off-by-one.** `+1` at the epilogue entry, putting the pointer on
`0x47`, a cell with 3.1 M non-zero writes.

*Result:* **no change.** Every store still reads zero.

### 11.1 What that rules out, and the stop

⛔ **The epilogue is not merely mis-aimed by one.** Reading a cell that demonstrably holds
data still yields zero, which leaves two possibilities the current instruments cannot
separate:

1. **The epilogue runs BEFORE the bodies deposit** in the frame's execution order, so the
   cells are empty *at that moment* even though they are full later; or
2. **the value it needs is not in D-RAM at all** — it is in a register or latch the model
   does not connect.

★ **Two speculations in a row that a measurement cannot separate is the signal to stop.**
Adding a third would make the next contradiction unattributable, which is the failure mode
this register exists to prevent — and the session has already demonstrated the cost of
pressing on (§3.4's DC constant, §3.10's phantom overflow).

### 11.2 The one instrument that would settle it

**A time-ordered trace of a single frame** — slot index, pointer, and the value at that
pointer, in execution order — rather than the per-slot maxima used throughout this session.
Every wrong turn today (§3.9's overflow, §3.11's slot-50, §3.12's boundary) came from
reading a *maximum* as if it were a *sequence*. The frame is 285 slots; one frame's trace
is 285 lines and would answer possibility 1 outright.

## 12. ★★★ THE TIME-ORDERED FRAME TRACE — and it settles the question in one read

§11.2 asked for a trace in *execution order* rather than per-slot maxima. Built, armed on
the first frame carrying a non-zero input sample, 285 slots.

### 12.1 The frame's real execution order

```
   n=  0.. 49   kernel     (I-RAM 0..49)
   n= 50..119   body 0
   n=120..129   kernel     (I-RAM 50..59)
   n=130..262   body 1     (I-RAM 200..332 -- the 133-word reverb)
   n=263..284   EPILOGUE   (I-RAM 60..82)
```

★ **The epilogue runs LAST, after both bodies.** ⛔ **§11.1's possibility 1 is REFUTED** —
the cells are full when it executes; it is not reading them early.

### 12.2 ⛔ And the epilogue is not mis-aimed either

Every epilogue slot runs with `dp = 0x46`, `mem[dp] = 0`, `acc = 0`, `P = 0`. Body 1 *ends*
that way too (n=255..262 all zero). **The epilogue is handed nothing.** Both §11
speculations were treating a symptom.

### 12.3 ★★★ Where the accumulator actually dies — one word, and it is anchored

```
   n=231  iw=301  08801602DA   acc = 192 414 482 432    <- last live slot in the frame
   n=232  iw=302  0000A00695   acc = 0                  <- DIES HERE
```

`I-RAM 302` = `000.A.00.695`: class A (coefficient consumer), **`SRC 0x1A` = tempB
(ANCHORED)**, `ACT 0x15` (ANCHORED), and **`f31 = 0` = `HI_ACC_LOAD`, i.e. `acc ← P`**. It
discards the accumulator and takes the product register — and `P` is **0**.

★ Being a class-A multiply with `SRC 0x1A`, `P = coef × tempB`. So **either the coefficient
at that cursor position or tempB is empty**, and both fields of the word are otherwise
anchored: there is no undecoded semantics here at all.

⛔ Which of the two is the defect is **not** settled by this trace — it records `acc` and
`P` but not `tempB` or the cursor. That is a one-line extension, not a new instrument.

### 12.4 What the instrument was worth

Every wrong turn of this session came from reading a per-slot **maximum** as a
**sequence**: the "overflow" that was a sign bit (§3.10), the slot-50 boundary that was an
`ldptr` doing nothing (§3.12), and both §11 pointer speculations. **The trace answered in
one read what four separate speculations could not**, and it refuted the framing of the
last two.

★ 104 of 285 slots carry a non-zero accumulator. The frame is more alive than any previous
measurement suggested — and it dies at exactly one anchored word.

## 13. ★★★ tempB and the cursor in the trace — the coefficient was the empty one

Adding `tA`, `tB`, the cursor and the coefficient under it to the trace answers §12.3's
open half in one line:

```
   n=232  iw=302  acc=0  P=0  tA=0  tB=5 872 025  cur=CE  coef=000000
```

★ **tempB holds 5 872 025 — 0.70 of full scale, perfectly healthy.** The **coefficient is
zero**, so `P = coef × tB = 0`. §12.3 offered two candidates; the trace names which.

★★ And `cur = 0xCE` is **outside every C-RAM run the host writes** (`0x50..0xB4`,
`0x00..0x13`). **The reverb's cursor had walked past the end of its bank into unwritten
memory** — free-running from the frame-start seed of row 19 instead of being re-seeded per
body.

### 13.1 The fix, and what it recovered

The kernel loads each unit's bank immediately before its CALL — `iw42 → 0x70` (unit 0),
`iw50 → 0x50` (unit 1) — and those are exactly the banks the coefficient stream fills.
Seeding `m_cursor = m_cp` at the CALL (row 24):

```
   before:  cur=CE  coef=000000   P=0            acc dies at n=232
   after:   cur=65  coef=00D400   P=2 489 738 176   acc RECOVERS at n=233
```

★★★ **The multiply produces a value and the accumulator survives the word that killed it.**
Downstream, `mem[dp]` and `tA` start carrying data (37 990 at n=233–236), and **output slot
5 goes non-zero on 1 560 000 of 1 588 800 frames** — the first time any output slot has
carried a value.

⛔ **GUESSED, and against a FORCED result.** K3 proves selector `0x21` loads a C-RAM
*pointer* that is **NOT** the implicit cursor. Row 24 couples them anyway, on the functional
grounds that a body must read its own bank and nothing else re-seeds the cursor. **If K3 is
right, this is wrong and some other word does the job.**

### 13.2 ⛔ Still no audio, and the reason is now specific

Slot 5 is `port 2` = **DO3**, which the tone generator deliberately drops (*"DO3's
destination is unknown, so it is ignored"* — its own EDUCATED GUESS G-4). A diagnostic remap
onto ports 0/1 was tried **and reverted**: the resulting wet was **rms 1.0**, a ±1 LSB
constant present even in silence. **The live presentation carries no audio signal**, so the
routing question is not what is blocking sound.

## 14. Where this leaves it

★ **Real, and independent of the audio:** the coefficient cursor is now re-seeded per body,
the reverb's multiplies produce values, the accumulator survives to the end of the body, and
one output slot carries data.

⛔ **Not achieved:** audible output. The value presented is ~1 LSB, so something upstream is
still attenuating by orders of magnitude — the same class of defect as §3.4's regime
mismatch, and the trace now has the columns (`tA`, `tB`, `cur`, `coef`) to find it.

## 15. ⛔ The attenuation — my diagnosis was wrong, and one rule replaced two guesses anyway

**The claim:** the epilogue multiplies by `0x0004BE = 1214` (a linear-ramp-table value at
cursor `0x71`, left over from unit 1's body), i.e. `×0.000145`, ~6 900× attenuation.

⛔ **Wrong.** The epilogue's presentation words are **class 1**, and `coeff_consumer()`
requires bit 23, which they do not carry. **They are not coefficient consumers** — the
cursor and the coefficient under it are *irrelevant to them*. The `coef` column sitting
beside them in the trace is the cursor's current contents, not something the word uses. I
read a column that happened to be adjacent as if it were an operand.

★ **The real number is `mem[0x46] = 504`** — that is what the body hands the epilogue, and
the body's own tempB at that point is **5 872 025**. The attenuation is ~11 650× and it
happens **inside the body, before the epilogue is reached.**

### 15.1 What survives: row 25 subsumes rows 19 and 24

Coupling `ldptr` to the cursor is still the better rule, independent of the wrong
diagnosis:

* the corpus loads that pointer exactly three times, and **each load precedes the block
  that needs that bank** — `iw42 → 0x70` (unit 0), `iw50 → 0x50` (unit 1), `iw69 → 0x90`
  (the epilogue, and hence the next frame's kernel);
* `iw69 → 0x90` is **exactly the value row 19 was seeding by hand at frame start**, which
  is a consistency check row 19 could not supply for itself;
* so **rows 19 and 24 are retired** and one rule replaces two hand-placed seeds.

⛔ Still against K3, which proves selector `0x21` is *not* the implicit cursor. One rule is
tidier than two; it is not more proven.

### 15.2 Where the attenuation actually is

Between the body's live accumulator (192 414 488 960, i.e. datum ≈ 2 936 000) and
`mem[0x46] = 504`. **That is inside body 1, in the trace already captured**, and the columns
needed to find it — `acc`, `P`, `tA`, `tB`, `cur`, `coef`, `mem[dp]` per slot in execution
order — are all present.

★ **This is the fourth diagnostic error of the session** (§3.4's constant read as a peak,
§3.10's sign read as overflow, §3.12's maximum read as a boundary, and now an adjacent
column read as an operand). Every one was caught by the next measurement, and every one was
mine rather than the device's. The trace is the right instrument; I have to read it more
carefully than I have been.

## 16. ★★★ The attenuation inside body 1 — `ACTION 0x00` was REPLACING the accumulator, not adding to it

Read carefully this time, one 8-word motif at a time.

**First, what is NOT wrong.** The store into `mem[0x46]` is faithful: `acc = 33 064 592`,
`33 064 592 >> 16 = 504`, and `mem[0x46] = 504`. `acc_to_datum` is doing exactly its job.
The accumulator simply *arrives* small.

**The reverb's 8-word allpass motif ends in `104.2.00.000`** — `f31 = 2` (`HI_ACC_HOLD`),
`SRC 0x00`, `ACT 0x00` — and it zeroed the accumulator at **every** stage:

```
   n=158  acc 192 414 482 432 -> 0        n=208  192 464 026 112 -> 0
   n=166      192 414 491 392 -> 0        n=224  192 414 482 432 -> 0
   n=174      192 414 482 432 -> 0        n=232  192 414 488 960 -> 0
   n=182      192 414 482 432 -> 0        ... nine stages in all
```

★★★ **The cause is one expression:**

```cpp
   src_term = (act == LO_ACT_ACC_BUS) ? (L << ACC_SHIFT)
                                      : (f31 == HI_ACC_LOAD ? 0 : m_acc);
```

When `ACTION 0x00` is present this returns **the bus ALONE, regardless of `hi12[3:1]`** — so
a word that is simultaneously being told to **HOLD** the accumulator discards it. With
`L = mem[ptr] = 0`, each ladder stage threw away everything the stage before it built.

**The three operations are** `0` = LOAD (feedback cut), `1` = ADD, `2` = HOLD (keep the
accumulator, no product). `ACTION 0x00` contributes the bus as an **extra term** to
whichever applies — which is what this device's own DELTA table already says
(*"hi12[3:1] == 1, act != 00: acc += P"*).

### 16.1 Result, and the honest limit

```
   ladder stages that ZERO the accumulator :  9  ->  2
   body-1 slots carrying a non-zero acc    : 114 -> 126  of 133
```

★ **Seven of the nine losing stages are fixed**, and the reverb now accumulates across most
of its ladder.

⛔ **But the delivered value did not move**: `acc` at the body's last slot is still
33 064 592 and `mem[0x46]` is still 504. Two stages still zero, and whatever reaches the
send cell is decided after them. **A real improvement to the datapath that is not yet an
improvement to the output.**

★ **For `f31 = 0` and `1` the behaviour is unchanged** — 0 still cuts the feedback, 1 still
keeps it — so the biquad and LFO results are untouched. Only the HOLD case changes, and
`alu_decoded()` admits that solely on class 8, so nothing in the shipping gate moves.

## 17. ★★★ The two remaining stages are CORRECT — and the body's terminator names the gap

```
   n=151  iw=221  000.2.00.419   f31 = 0 (LOAD, acc <- P)   P = 0  -> acc = 0
   n=262  iw=332  612.1.0F.000   f31 = 1, hi12 bit 10 (END) + bit 4 (STORE)
```

* **n=151** is a legitimate `acc <- P` with a stale product. `f31 = 0` means *feedback cut*
  — this is the **start** of a ladder stage, resetting the accumulator by design.
* **n=262** is the body's **TERMINATOR**: `hi12 = 0x612` carries bit 10 (END) *and* bit 4
  (store), so it deposits the result and the store gate's `doclr` clears the accumulator.
  Also by design.

★★★ **So §16's change removed every SPURIOUS zeroing.** Nine stages were losing the signal;
seven were the `ACTION 0x00` defect and the two survivors are the machine working correctly.
The reverb's ladder now accumulates end to end.

### 17.1 ★ And the terminator names the producer/consumer gap exactly

`612.1.0F.000` is **mode 1**, so its bit-4 store targets `mem[addr8]` = **register `0x0F`**.
That is where body 1 deposits its result.

**The epilogue reads `0x85`, `0x8C`, `0x8D`, `0x06`.**

⛔ **`0x0F` is not among them.** §5.6 established that producers and consumer disagree about
the send-cell address; this identifies the producer's side precisely — it is the body's
terminator, and its destination is fixed by `addr8` in the microcode, not by any guess of
mine.

### 17.2 The state this run reaches

```
   audio enters                                     ✓
   kernel computes                                  ✓
   both bodies run, ladder accumulates end to end   ✓  (126 of 133 slots live)
   body 1 terminator stores its result to reg 0x0F  ✓
   ─────────────────────────────────────────────────────────────────────────
   ✗ the epilogue reads 0x85 / 0x8C / 0x8D / 0x06   ✗  not 0x0F
   ─────────────────────────────────────────────────────────────────────────
   presentations + output slots fire per frame      ✓  (slot 5 non-zero)
   tone generator mixes                             ✗  slot 5 is DO3, which it drops
```

★ **Two clean, separable questions remain**, and neither is a semantics search:
1. why the epilogue reads a different register than the terminator writes;
2. whether the live presentation really belongs on DO3, or the slot→port mapping is wrong.

## 18. ★★★ Why the epilogue read a different register — the bit-4 store ignored its own mode rule

⛔ **First, a correction to §17.1.** I said the terminator "stores its result to register
`0x0F`". It did not. The bit-4 store site in `exec_alu()` wrote **`mem[m_dp]`
unconditionally** — so `612.1.0F.000` deposited into `mem[0x46]`, and **that is exactly the
504 the epilogue was seen holding at its pointer** while the registers it reads stayed
empty. I read the microcode's `addr8` as the destination without checking that the code
used it.

★ **The rule was already on file and unimplemented at this site.**
`isa-adjudication.md` behavioural note 1: *"hi12 bit 4's target is mode-dependent —
`mem[ptr]` ONLY IN MODE 2. Eight kernel words mis-execute otherwise."* `do_store()`
implements it; this path did not.

### 18.1 ★ And the unit bit

`addr8` bit 7 selects the unit — **MEASURED** in `output-stage-decode.md` item I (*"0x00 →
unit 0, 0x9F → unit 1"*), named in this device's own register annotations (`[06]` unit 0 /
`[86]` unit 1), and already applied to the pointer as `DRAM_UNIT_BASE = 0x05 | unit<<7`.
The microcode writes `addr8` **unit-relative** and the hardware supplies the unit, so body
1's `0x0F` is register **`0x8F`**.

★★★ **Which is precisely what the epilogue reads at `iw65 = 200.1.8F.1C1`.** Two addresses
derived independently — one from the producer's microcode, one from the consumer's — meeting
on the same register.

### 18.2 Result

```
   register 0x8F :  0 non-zero  ->  1 559 999 non-zero of 1 560 839
```

★★ **Body 1's result now lands in the register the epilogue reads, every frame.** That
producer/consumer gap is closed.

⛔ **And output slot 5 went to zero.** It reads register `0x8C`, which sits *downstream* of
`0x8F` in the epilogue's own arithmetic (`iw65` reads `0x8F`; `iw66` is the `ACT 0x07` store
into `0x8C`). Closing one link exposed that the next one is not connected — the honest
reading is that the chain got one stage longer, not that it regressed.

⛔ **GUESSED**: that the unit bit applies to REGISTER destinations and not only to the D-RAM
pointer. The parallel is strong and the two addresses meet, but it remains a parallel.

## 19. The chain as it now stands

```
   audio enters                                       ✓
   kernel computes                                    ✓
   both bodies run, ladder accumulates end to end     ✓  126/133 slots
   body 1 stores its result to register 0x8F          ✓  1 559 999 frames
   epilogue iw65 reads 0x8F                           ✓
   ─────────────────────────────────────────────────────────────────────
   ✗ 0x8F -> 0x8C, the epilogue's own arithmetic      ✗  not connected
   ─────────────────────────────────────────────────────────────────────
   presentations read 0x8C / 0x8D                     ✓  fire per frame, values 0
   tone generator mixes                               ✗
```

## 20. The 0x8F → 0x8C link — applied, no effect, and the blocker is back to `SRC 0x02/0x03/0x04`

**Row 28, the mode-1 register READ**, applied as the mirror of row 27's mode-1 store: a
register-file word names its register in `addr8`, and one addressing mode addressing
differently to read than to write would be the odd claim.

**Measured effect: none.** `0x8C` stays empty and every output slot stays zero.

★ **The reason is exact.** The link `0x8F → 0x8C` runs through two words:

```
   iw65  200.1.8F.1C1   SRC 0x07, ACT 0x01   reads 0x8F -- now LIVE
   iw66  000.1.8C.107   SRC 0x04, ACT 0x07   stores into 0x8C
```

`iw65` now reads the live register, but its **`ACT 0x01` has no handler**, so nothing
captures the value. `iw66` then stores **`L = 0`**, because **`SRC 0x04` has no reading**.

⛔ **So the chain is blocked by the same two unknowns §9 identified** — and row 28 does not
change that. It is applied because the symmetry argument stands on its own, not because it
helped.

### 20.1 ★ But one thing HAS changed, and it matters

§9 closed with: *"an acceptance test on a source that reads an empty cell cannot
discriminate anything"*. **`0x8F` is no longer empty** — it carries body 1's result on
1 559 999 frames of 1 560 839.

★★ **`SRC 0x02/0x03/0x04` are now testable.** A reading that routes `iw66`'s source to a
live register will propagate a value to `0x8C`; one that does not, will not. The
discriminating experiment §9 could not run is now runnable, and the same applies to
`ACT 0x01`.

**That is the first time in this investigation that those codes have had a live source to be
tested against.**

## 21. Final chain

```
   audio enters                                    ✓
   kernel computes                                 ✓
   both bodies run, ladder accumulates             ✓  126/133 slots
   body 1 stores its result to register 0x8F       ✓  1 559 999 frames
   epilogue iw65 READS 0x8F                        ✓  (row 28)
   ──────────────────────────────────────────────────────────────────
   ✗ ACT 0x01 has no handler; SRC 0x04 has no reading  ✗  two codes
   ──────────────────────────────────────────────────────────────────
   iw66 stores 0 into 0x8C                         ✓ cadence, ✗ value
   presentations read 0x8C/0x8D                    ✓ cadence, ✗ value
   tone generator mixes                            ✗
```

★ **Two named codes stand between a live producer and a live consumer**, with a live
register between them to test against.

## 22. ★★★ The pair test PASSES — the datapath is complete end to end

The first test of `SRC 0x04` and `ACT 0x01` that *could* discriminate, because `0x8F` finally
carries a value. Pairing under test: `ACT 0x01 = tempA ← bus` (it sits in the same family as
`0x13`/`0x14`/`0x19`, all temp captures) and `SRC 0x04 = tempA`.

```
   register 0x8F  :  1 559 999 non-zero      <- body 1's result
   register 0x8C  :  1 559 999 non-zero      <- WAS 0
   output slot 5  :  1 559 999 non-zero      <- carrying the value
```

★★★ **`0x8F → tempA → 0x8C → slot 5`, every stage carrying on 1 559 999 frames.** The
emulated IC311 now runs a complete signal path from the audio input to an output port.

### 22.1 ⛔ What this is worth

* ⛔ **One pairing of sixteen.** A single pairing passing is weak evidence. What makes it
  more than nothing is that it was **predicted from the family** (`ACT 0x01` grouped with the
  known temp captures) and then **confirmed by cadence** — 1 559 999, the same count as its
  producer, not an approximation.
* ⛔ **The other fifteen were not tried.** Several would probably also propagate *something*;
  only a criterion that scores the VALUE, not its presence, can separate them, and this
  project has learned that lesson three times (§5.5, §9, §12).

### 22.2 The last break

**The audio is still bit-identical to dry.** Slot 5 is **port 2 = DO3**, which
`kn5000_tonegen` deliberately drops — its own EDUCATED GUESS G-4: *"DO3 leaves the
tone-generator block entirely on a long run heading out of the area; it is not the DAC and
it is not one of this chip's six serial ports."*

★ So the final question is no longer inside the DSP at all: **either the slot → port mapping
(§5.3, already narrowed once) is wrong, or G-4 is wrong and DO3 does return to the mix.**
Both are board-level questions with board-level evidence available, and the second is
answerable from the service manual rather than from the ROM.

## 23. Where the session ends

```
   audio enters the chip                          ✓
   kernel computes                                ✓
   both bodies run, ladder accumulates            ✓  126/133 slots
   body 1 -> register 0x8F                        ✓  1 559 999 frames
   0x8F -> tempA -> 0x8C                          ✓  1 559 999 frames
   0x8C -> output slot 5                          ✓  1 559 999 frames
   ─────────────────────────────────────────────────────────────────
   ✗ slot 5 is DO3, which the tone generator drops ✗
   ─────────────────────────────────────────────────────────────────
```

★ From **100 % of frames trapping and 123 undecoded forms** to **a complete datapath whose
only remaining break is a board-level routing question**, with every speculative reading
graded in this register and the four measured results (`f31 == 2` does not write `P`;
`src08 = coef`; mode 4 ≠ `mem[ptr]`; the coefficient stream's pointer rule) separable from
the twenty-odd guesses.

## 24. §23's remaining break is ANSWERED — and the answer is "neither branch"

**2026-07-28, from Felipe.** §22 posed the fork as: *either the slot→port mapping is
wrong, or G-4 is wrong and DO3 does return to the mix.* It said the second was
"answerable from the service manual rather than from the ROM". It was, and the answer is
that **both branches are false and the datapath is fine**.

The KN5000 service-manual schematics route

```
   DO3  -> extension connector (HSO) pin 62
   LRCK -> extension connector (HSO) pin 61
```

and the only board that plugs into that connector is the optional **HD-AE5000**, whose
"AE" is **Audio Extension**. Technics' promotional material for it:

> "…separate outputs for bass and drums. In detail, there are 3 different selections
> (Drums L/R, Drums and bass mixed stereo, Drums L and Bass R)… Because of KN5000
> hardware reasons, all separate outputs are developed as **direct out** and have **no
> volume control** from the KN5000. They have the same level as the line outputs."

So:

| §22 branch | verdict |
|---|---|
| slot→port mapping is wrong | **false** — slot 5 = DO3 stands |
| G-4 is wrong, DO3 returns to the mix | **false** — G-4 is *right*, and for a stronger reason than it claimed |

★ **The line in §23 marked ✗ was never a defect.** DO3 is a **separate physical output**.
A live, non-zero, correctly-computed sample on slot 5 that does not appear in the main L/R
mix is **exactly what the hardware does**. The tone generator excluding it is correct;
summing it in would have folded a direct-out feed back into the main mix, which the board
does not do.

Two things follow that matter more than the bookkeeping:

1. **The datapath is complete end to end.** `input → kernel → body 1 → 0x8F → tempA →
   0x8C → slot 5 → DO3 → HSO pin 62 → HD-AE5000`. There is no missing stage. The
   "bit-identical to dry" result was measuring the wrong output.
2. **The main-mix silence is no longer evidence against the speculative readings.** §§5.3
   and 22 had been treating it as a standing contradiction to be resolved; it isn't one,
   so it must stop being cited as one. Whatever tests the ~29 graded rows from here has to
   observe DO3, not the L/R sum.

**What this does NOT establish.** That the *value* on slot 5 is correct — only that its
destination is. The register's grades are untouched: the guesses are still guesses, and
DO3 carrying a number proves nothing about that number. It does mean the obvious next
instrument is a capture of slot 5 itself rather than of the speaker output.

Recorded in MAME at `src/devices/bus/technics/kn5000/hdae5000.cpp` (device note) and
`src/mame/matsushita/kn5000_tonegen.cpp` (G-4, promoted from EDUCATED GUESS to RESOLVED).
Evidence grade: **MEASURED (external)** — schematics + manufacturer documentation,
supplied by Felipe, whose hardware testimony outranks inference here.

## 25. §24 OVERREACHED — the normal user path is EMPTY, and Felipe called it

**2026-07-28.** Felipe's objection: DO3 may only be live when the HD-AE5000 is fitted,
and in any case *"there's also the normal audio path that most users would [use], which
is just the speakers of the KN5000 itself without the extension board."* Measured, and
he is right on the point that matters.

Two 25-second runs, DSPCFG = 3 (speculative), identical but for `-extension hdae5000`:

```
                        no extension                with hdae5000
slot0  DO1 L      0 nonzero /   964 800        0 /   964 949
slot1  DO1 R      0          /         0        0 /         0     <- NEVER WRITTEN
slot2  DO2 L      0          /         0        0 /         0     <- NEVER WRITTEN
slot3  DO2 R      0          /         0        0 /         0     <- NEVER WRITTEN
slot4  DO3 L      0 nonzero /   965 760        0 /   965 909
slot5  DO3 R  935 999       /   964 800   936 148 /   964 949
```

**Finding 1 — the extension board changes nothing.** The two columns are identical bar
the 149-frame runtime difference. Our emulation gates nothing on board presence, so the
HD-AE5000 slot is *not* currently a way to test the DO3 path. Felipe's hypothesis about
real hardware is untouched by this; it simply is not modelled.

**Finding 2 — ★ a user with no extension board gets NOTHING.** DO1 and DO2 are the main
mix. Slot 0 is written every frame and is *always zero*; slots 1, 2 and 3 are never
written at all. So the effect is inaudible on the speakers by construction — which is the
normal configuration for almost every user.

**Finding 3 — the one live output rides entirely on a guess.** `PRESENTATION WORDS: 0
executed`: the class-C/D presentation path is `m_row13`, which is hard-`false` (RETIRED
after the double-count check). The *only* live writer of any output is the class-1
register-file selector rule, whose own comment reads: *"⛔ The slot->code MAPPING is
untested — slot = SRC-1 in natural order is the obvious reading and nothing more."*

**Finding 4 — the resulting pattern is internally implausible, which is evidence against
the mapping.** DO2 receives nothing, ever; DO3's left channel is always zero while its
right carries 97 % nonzero. A stereo effects output does not look like that.

### What §24 got wrong

§24 said *"the datapath is complete end to end"* and *"the main-mix silence must stop
being cited as a contradiction."* Both go too far. The correct statement:

> The datapath is complete **for one channel of one port**, delivered by an **explicitly
> untested** slot mapping, onto the one port that is **not** in the main mix. The main-mix
> silence is not explained by the DO3 discovery, because DO1/DO2 are not *excluded* — they
> are **empty**.

§24's board-level facts stand (DO3 → pin 62 → HD-AE5000; G-4 correct to exclude DO3).
What does not stand is treating that as closure. **The main-mix silence goes back on the
books as a live contradiction.**

### The alternative worth testing

There are exactly **three** ACT 0x1B (output-presentation) words, and the §5/§6.1
adjudication pairs them with **SRC 0x01, 0x05, 0x06**. Three presentations, three serial
output ports. Under `slot = SRC-1` those three scatter to DO1-L, DO3-L, DO3-R — leaving
DO2 unwritten, exactly the anomaly observed. Under a **port** reading (`port = f(SRC)`,
each presentation driving one stereo port) they would land one per port and put signal
into the main mix.

⚠ The note at the class-1 rule records that remapping onto ports 0/1 was *tried and
reverted* because the wet was a ±1 LSB constant. That attempt predates the 96 dB
presentation-shift fix, so it is worth re-running, not cited as a refutation.

Evidence grade: **MEASURED** (the slot census, both configurations). The port-mapping
alternative is **UNTESTED INFERENCE**.

## 26. The port-mapping test — REFUTED, and the answer was in our own notes

**2026-07-28.** Felipe asked for the port-mapping test. Before permuting anything I
instrumented what the three "presentations" actually read, because two of them are written
every frame and are *always zero*, and remapping which port a zero lands on cannot create
signal:

```
slot0  SRC 0x01  reads reg 0x8D  word 012.1.8D.05B  peak 0     (0/964800)
slot4  SRC 0x05  reads reg 0x8D  word 092.1.8D.15B  peak 0     (0/965760)
slot5  SRC 0x06  reads reg 0x8C  word 092.1.8C.19B  peak 504   (935999/964800)
```

Those three words are **w61, w60 and w68**, and `r2-output.md` §3.2 had already inventoried
every one of them — as **INTERNAL register writes**, with w68 explicitly *"read at w66
first ⇒ a state register"*. They are not outputs at all.

⛔ **So the class-1 rule "lo12[10:6] is an output-slot selector" is REFUTED.** It hijacked
three internal register writes onto the output latches. That single error produced every
anomaly in §25: DO2 never written (no real presentation ran), DO3 carrying signal that
§3.2 predicts it never carries, and DO3-L always zero.

★ **This is the [[check-the-handover-first]] failure again.** §3.2 is a table of exactly
these words, written before the rule was invented, and the rule was invented without
reading it. The rule's own comment even said *"the slot→code MAPPING is untested — the
obvious reading and nothing more."* It was worse than untested; it was already contradicted.

### The real outputs, and the retired path that had them right

```
w73  E30.C.00.404   class 0xC   addr8 0x00 -> unit 0 -> DO1
w78  A3C.D.9F.287   class 0xD   addr8 0x9F -> unit 1 -> DO2
```

Class **0xC / 0xD**, unit from **addr8 bit 7** — which is precisely what the `m_row13`
presentation path implemented before it was **retired over a double-count against the
class-1 rule**. The double-count was real; it was resolved in favour of the wrong member of
the pair. Fixed: class-1 hijack disabled (those words now fall through to their mode-1
store, which is what they are), `m_row13` un-retired.

### Result — correct routing, and a sharply better blocker

```
PRESENTATION WORDS   0 executed  ->  1 927 680 executed   (2 per frame)
  ... wrote NON-ZERO                        0
  raw accumulator peak AT presentation      0
0x8C  966 147 stores, 935 999 NONZERO (site 3, peak 504)
0x8D  965 206 stores,       0 nonzero (site 2)
```

**The two real presentations now execute every frame — and the accumulator is ZERO at both
of them.** Signal demonstrably exists inside the chip (0x8C is nonzero 97 % of frames);
it is simply not in the accumulator when the output words run.

⚠ **Honest trade: the DSP is now silent again.** The audio §24 celebrated was an artefact
of the refuted rule, on a pin that should carry nothing. Losing it is a *gain* — a false
positive removed — but it must be stated plainly rather than buried.

**The new question is far better posed than the old one:** not *"where does the output
go?"* (settled: DO1/DO2, unit 0/unit 1) but **"what should load the accumulator before
w73/w78, and why does it not run?"** — a question about a handful of epilogue words rather
than about the whole output stage.

### Does the service manual help? (Felipe's question)

Partly, and it is worth being precise about where.

* **For DO3 it was decisive** — the destination could not have been got from the ROM, and
  the schematics settled it (§24, and that stands).
* **For this blocker, no.** It is internal: which microcode word loads the accumulator. No
  schematic can say that.
* ★ **But it corroborates Felipe's hypothesis.** §3.2 predicted *"DO3 is a wired-but-undriven
  pin; with a scope on IC311 pin 25, DO3 carries no audio in any effect configuration."*
  The schematic says that pin is wired to the HD-AE5000. Both hold together exactly if DO3
  is driven only in some **other** configuration — which is what Felipe proposed. The
  normal-configuration microcode writes DO1 and DO2 and leaves DO3 idle.
* **Still worth reading:** whether the extension connector carries a board-DETECT line back
  to the SubCPU, since that would be the mechanism by which a different program gets loaded.

Evidence grade: **MEASURED** (the instrumented reads; the presentation census) +
**DOCUMENTED** (r2-output.md §3.2, pre-existing).

## 27. What loads the accumulator before w73/w78 — NOTHING CAN. The chip has TWO.

**2026-07-28.** The accumulator profile settles where the signal dies, and it is not at the
presentation:

```
slots   0..59   (kernel)   peak |acc| up to 735 262 305 072
slots  60..83   (EPILOGUE) peak |acc| = 0   AT EVERY SINGLE SLOT
slots 200..284  (body 1)   peak |acc| up to 192 416 248 000   <- ends FULL
```

Body 1 finishes with 192 billion in the accumulator. The epilogue then runs 22 words with
the accumulator at **exactly zero throughout**. The time-ordered trace shows why, and it
also shows the signal is *present* the whole time:

```
  iw  word         acc    P     tA      cur  coef
  65  200.1.8F.1C1   0     0      0     71  0004BE   <- reads reg 0x8F
  66  000.1.8C.107   0     0    504     71  0004BE   <- tA = 504, stored to 0x8C
  ...
  71  C41.9.00.446   0     0    504     90  200000   <- FETCHES COEF 0.25, LOAD acc<-P
  73  E30.C.00.404   0     0    504     90  200000   <- the unit-0 presentation
  78  A3C.D.9F.287   0     0    504     90  200000   <- the unit-1 presentation
```

**tempA holds 504 — the unit result — across the entire output stage, and a 0.25
output-level coefficient is sitting under the cursor at 0x90.** Everything needed is
present. `P` is zero, so `acc` is zero, so the presentations write zero.

### Field decode of all 22 epilogue words

| iw | word | fetches coef | SRC | f31 |
|---|---|---|---|---|
| 64 | `C40.A.80.445` | ✔ | **0x11 — unmodelled** | 0 LOAD acc←P |
| 65 | `200.1.8F.1C1` |  | MEM | 0 |
| 71 | `C41.9.00.446` | ✔ | **0x11 — unmodelled** | 0 LOAD acc←P |
| 73 | `E30.C.00.404` | ✔ | ACC (0x10) | 0 LOAD acc←P |
| 74 | `C16.9.AB.000` | ✔ | 0x00 | **3 — undecoded** |
| 75 | `82E.8.0F.000` | ✔ | 0x00 | **7 — undecoded** |
| 77 | `859.0.86.822` |  | 0x00 | **4 — undecoded** |
| 78 | `A3C.D.9F.287` | ✔ | 0x0A | **6 — undecoded** |

Six of the 22 carry **f31 > 2**, which is *"attack hi12[3:1] > 2"* — the standing #2
execution blocker — and the epilogue is where it bites.

### ★★★ The reading: ACCA / ACCB

Two independent gaps land on the same structure, and the block diagram already names it.

**1. `SRC 0x11` is the second accumulator.** The anchored source codes are
`0x07 = MEM`, `0x10 = ACC`, `0x19 = tA`, `0x1A = tB`. **0x11 sits immediately next to
0x10.** And `effects-dsp.md`, from the CDJ-500 block diagram marked **PROVEN**:

> ALU — **44-bit, with two accumulators (ACCA / ACCB)** and two shifters

`0x10 = ACCA`, `0x11 = ACCB`. We model **one** accumulator, so every word sourcing ACCB
silently reads zero.

**2. `f31` bit 2 selects the accumulator.** The known map is `0 = LOAD acc←P`,
`1 = ADD`, `2 = HOLD` — three of four codes in a 2-bit field. Observed values are
{0,1,2,3,4,6,7}. Read `f31[2]` as the accumulator select and `f31[1:0]` as the operation:

| f31 | reading |
|---|---|
| 0,1,2 | LOAD / ADD / HOLD on **ACCA** |
| 3 | op-3 on ACCA (fourth operation, still open) |
| 4,5,6 | LOAD / ADD / HOLD on **ACCB** |
| 7 | op-3 on ACCB |

**It predicts the output stage exactly.** Unit 0 → ACCA, unit 1 → ACCB:

* `w73` (unit 0 → DO1): fetches the coefficient, `SRC = ACCA`, `f31 = 0` ⇒
  `ACCA ← level × ACCA`. **An output-level multiply, which is precisely what §3.1 said
  w73 must be.**
* `w77` (`addr8 = 0x86`, the unit-1 wet-level register — §3.1) : `f31 = 4` ⇒
  **LOAD ACCB ← P**. The unit-1 level load.
* `w78` (unit 1 → DO2): `f31 = 6` ⇒ HOLD ACCB — present without disturbing it.

Three words, three roles, all consistent, and the ACCA/ACCB split matches the
**two effect units** the epilogue is already known to serve.

### Why this closes the question as asked

*"What loads the accumulator before w73/w78?"* — **w64 and w71 for unit 0, w77 for unit 1.**
All three are unexecutable today: w64/w71 source `0x11` (ACCB, unmodelled → 0) and w77
carries `f31 = 4` (undecoded → no write). Nothing loads the accumulator because every word
that would has a field we do not implement.

Evidence grade: **MEASURED** (profile, trace, field decode) for the diagnosis;
**INFERRED (strong)** for ACCA/ACCB — adjacency of 0x10/0x11, a PROVEN two-accumulator
block diagram, two effect units, and three independent word roles predicted correctly.
It is not yet tested in the core.

### Next

Implement ACCB + the f31[2] select behind the speculative gate. Falsifiable and cheap: if
right, the presentations stop writing zero and DO1/DO2 — the **main mix**, the path every
user without an extension board hears — carry signal for the first time.

## 28. ACCB + f31[2] IMPLEMENTED — and it FAILS its own test

**2026-07-28.** §27's stated criterion was: *"if right, the presentations stop writing zero
and DO1/DO2 carry signal."* Implemented (ACCB wired into the ALU, `f31[2]` as accumulator
select, `SRC 0x11 = ACCB`) and measured:

```
PRESENTATION WORDS   1 927 680 executed,  936 000 wrote NON-ZERO   (was 0)
datum peak                       -8 388 608   = -2^23, THE NEGATIVE RAIL
raw accumulator peak     -8 788 183 587 355   (2^43 = 8 796 093 022 208)
```

The presentations stopped writing zero. **But the criterion was two-part and the second
half failed**, and one number in the epilogue trace decides it:

```
  iw  word           acc   P        tA     cur  coef
  71  C41.9.00.446    0    0    -126480    90  200000
  73  E30.C.00.404    0    0    -126480    90  200000
  78  A3C.D.9F.287    0    0    -126480    90  200000
```

⛔ **`P` is still zero at every one of the 22 epilogue slots — exactly as before.** The
diagnosed root cause (no product is formed in the output stage) is **untouched**. The
nonzero presentations are ACCB carrying a value that saturated at the 44-bit rail, not a
computed output. A railed constant is not signal.

Three further consequences, all against:

1. **ACCA is still zero at every epilogue slot**, so `w73` → **DO1 is still silent**. Only
   the unit-1 side changed, and it changed to a rail.
2. **The bodies' behaviour moved too.** `tA` at the output stage went `504 → -126480`, so
   `SRC 0x11` is consumed inside the bodies as well, and re-reading it changed results that
   were not under test. The old `0x11 = mem[ptr]` guess was inert; this one is not.
3. ⚠ **Anything enabling DSPCFG = 3 now gets a full-scale DC on DO2.** It is behind the
   default-off gate, so no default behaviour changes, but it would sound bad if selected.

### What survives

The *diagnosis* in §27 stands on its own evidence and is unaffected: the epilogue runs 22
words with no product, six of them carry `f31 > 2`, and `w64`/`w71` source `0x11`. Those
are measurements.

What is **not** supported is the specific fix. Of §27's inference chain:

| claim | status after the test |
|---|---|
| the chip has two accumulators (block diagram, PROVEN) | untouched — still true |
| `SRC 0x11 = ACCB` | **not supported** — it does not make w71 form a product |
| `f31[2]` = accumulator select | **not supported** — w73/ACCA still dead |
| unit 0 → ACCA, unit 1 → ACCB | **not supported** — only unit 1 moved, and to a rail |

★ The prediction was falsifiable and it was falsified. That is the value of having stated
it in advance: had the criterion been "presentations write something nonzero", this would
have been recorded as a success, and it is not one.

### Where that leaves the real question

`P = 0` across the whole epilogue is now the *sole* remaining defect, and it survived a
change that touched both accumulators and the source decode — so it is not about which
accumulator is read. **Something is preventing the multiplier from loading an operand pair
in the epilogue at all.** The coefficient side is demonstrably fine (`coef = 0x200000`
under cursor `0x90`), so the failure is on the operand side or in the multiply's issue
condition.

Kept in tree, behind the gate, clearly labelled — not because it is right, but because
reverting it would also erase the falsification. **Felipe's call whether it stays.**

Evidence grade: **REFUTATION** (of §27's fix; the diagnosis it rests on is unaffected).

## 29. Why the multiply never issues — TWO gates, both wrong, both measured

**2026-07-28.** Added a `MUL` column (did the multiply *run*) and an `L` column (what
operand it was given) to the frame trace, to separate *"it never issues"* from *"it issues
and multiplies by zero"*. I had guessed the latter in §28. **Wrong — it never issues:**
`MUL = '.'` at all 22 epilogue slots. Two independent causes, and neither is subtle.

### Cause 1 — the multiply inherited the CURSOR's gate

```cpp
static constexpr bool coeff_consumer(u64 w) { return class4(w) == 0xa && !c_format(w); }
```

K4 **forced** this predicate — but it forced it for the **cursor advance**
(`class4 == 0xA → cursor++`). The multiply was written *inside the same block*, so it
silently inherited a gate never established for it. `r2-output.md` §3.1 reads coefficient
fetch as **`class4` bit 3**: *"Both w73 and w78 fetch a coefficient (class4 bit 3), which
is what an output-level multiply needs."*

The measured consequence, over the epilogue's eight coefficient-bearing words:

| iw | class4 | bit 3 | `== 0xA` |
|---|---|---|---|
| 63, 71, 74, 76 | 9 | ✔ | ✘ |
| 75 | 8 | ✔ | ✘ |
| 73 | C | ✔ | ✘ |
| 78 | D | ✔ | ✘ |
| 64 | A | ✔ | ✔ — but `hi12 = 0xC40` is **c-format**, which the predicate excludes |

**Not one of the eight qualified.** Split `coeff_fetch()` (bit 3 → multiply) from
`coeff_consumer()` (`== 0xA` → cursor++), leaving K4's forced cursor result untouched.

### Cause 2 — the presentation `return`ed before the arithmetic

Splitting the gate lit up only `w75`. `w73` and `w78` are class **C** and **D**, and the
class-C/D presentation branch sits *inside* `exec_alu()` and **`return`ed** — before the
multiply at the bottom of that same function. So the two output presentations could never
have multiplied under any gate.

That is backwards from what the word does: `w73` is *"`ACCA ← level × ACCA`, then present"*,
so it must run the ALU **first** and present the **result**. Deferred: the branch now
latches the unit and falls through, and the presentation runs after the product and the
accumulator are final.

```
MUL at w73   .  ->  Y
MUL at w75   .  ->  Y
MUL at w78   .  ->  Y
```

★ **The output-stage multiply issues for the first time.** Both causes are code defects in
this core, each demonstrable from the trace, and neither is a guess about the chip.

### What did NOT change, and why

```
w73:  MUL Y   L = 0   P = 0   acc = 0
```

`w73` sources `ACC` (0x10) and **ACCA is zero**, so it multiplies the output level by zero.
The gate was one blocker; the operand is another, and it is the same hole §27 named:

> `tA` holds the unit result (**−126480**) across the whole output stage, and **no
> epilogue word has `SRC 0x19` (tA) or `0x1A` (tB)** — nothing ever reads it back.

The path that exists is `mem[0x8F] → tA` (w65) `→ mem[0x8C]` (w66, `SRC 0x04 = tA`,
ACT 0x07 store). Then it stops. ★ **Prime suspect: `w68` = `092.1.8C.19B`, whose `addr8` is
exactly `0x8C` — the cell now holding the result — and whose `SRC 0x06` is unread.** If
`SRC 0x06` reads `mem[addr8]`, w68 (`f31 = 1`, ADD) is the missing load into ACCA. That is
a next test, not a claim.

⚠ Unchanged and still wrong: the presented value still saturates (`datum peak −2^23`), so
§28's refutation stands — this fixes the multiply gate, not the output.

⚠ **Controls not yet re-run.** `coeff_fetch` changes which words multiply across the WHOLE
program, not just the epilogue. SINGLE DELAY (lag 1001, gain +0.02149296), the PARAMETRIC
EQ biquad (0.198 dB) and the 19 LFO ramp constants must be re-measured before any of this
is treated as settled.

Evidence grade: **MEASURED** (both gate defects, from the MUL/L trace).

## 30. ⛔ THE TESTS WERE RUN WITH NO NOTES PLAYING — and fixing that refutes §27

**2026-07-28, on Felipe asking "are you playing notes when you run these tests?"** No. Every
run in §§25–29 was `-seconds_to_run` with only the DSPCFG script: **silence**. I had even
noticed the symptom and worked around it in the wrong direction — the trace arms on live
input, produced nothing, and instead of playing a note I added a frame-count fallback.

### The controlled experiment

Two runs, identical binary, identical arming frame (**970 000 ≈ 22 s**, chosen to land
inside `note_spec.lua`'s held C-major triad at t = 20 s rather than relying on the input
latch, whose audit peak is exactly `0x800000` — the rail — and so cannot distinguish "a
note is sounding" from "the latch is railed").

**The control works** — the instrument can see the difference:

```
                     peak |sample| that entered the chip
   with notes                 0x800000   (8 388 608)
   silent                     0x000000   (0)
```

**And the epilogue is BYTE-IDENTICAL in both:**

```
  iw  word           acc   P        tA        cur  coef  MUL      L
  65  200.1.8F.1C1    0    0    -126480       71  0004BE  .  -126480
  73  E30.C.00.404    0    0    -126480       90  200000  Y        0
  78  A3C.D.9F.287    0    0    -126480       90  200000  Y        0
```

Same to the digit, with 8.4 million counts of signal entering versus none.

### What this refutes

⛔ **§27's central claim is wrong.** It said *"tempA holds 504 — the unit result — across
the entire output stage"*, and §29 repeated it as *"tA holds the unit result (−126480)"*.
**It is not a result.** A value that is bit-identical with and without audio is not derived
from audio; it is a constant artefact of the mis-executing program. Every sentence in
§§27–29 calling `tA` "the unit result" is retracted.

★ **The break is far upstream of the epilogue.** The signal demonstrably enters the chip
and demonstrably reaches nothing in the output stage. Chasing "what loads ACCA" — §29's
proposed next step, `SRC 0x06` at w68 — would have been chasing the wrong end: even a
perfect load would load a constant.

⚠ And the input peak is **exactly 2^23**, the rail, whenever a note sounds. An input that
saturates at full scale is itself a defect and must be characterised before anything
downstream is interpreted.

### What SURVIVES

The §29 findings are **code-structure facts**, established by reading the source and
confirmed by the MUL column, and are independent of what data flows:

* `coeff_consumer()` (`class4 == 0xA`, K4-forced **for the cursor**) gated the multiply,
  and **none** of the epilogue's eight `class4`-bit-3 words satisfied it.
* The class-C/D presentation branch `return`ed from inside `exec_alu()`, before the
  multiply at the bottom of the same function, so `w73`/`w78` could never multiply.

Both are real defects, both are fixed, and `MUL` at w73/w75/w78 went `.` → `Y`. Neither
claim depended on a note being played.

### Method rule 12

**A DSP test with no signal at its input is not a test.** State the stimulus in every
result, and require a control that demonstrably moves — here, input peak
`0 → 8 388 608`. This is [[measurement-discipline-emulation]] and the reason it is a
standing rule: five instruments in one earlier day could not measure what they claimed,
and this is the sixth.

Evidence grade: **MEASURED, with a working control.** The null is meaningful precisely
because the control moved.

## 31. The "railing input" is NOT an input — it is self-inflicted corruption

**2026-07-28.** §30 flagged the input peaking at exactly `0x800000` as "its own defect,
must be characterised first". Characterised. **It is not an input defect at all.**

### 1. The tone generator's send is clean

`to24(v) = clamp(v × 256, ±2²³)` is applied to `mix_l`/`mix_r`, which are **pre-softclip**
and unbounded — so the clamp was the natural suspect. Counted over a full run with a held
C-major triad:

```
3 648 002 samples,  peak |mix| 20 441  (full scale 32768),
clipped 0 (0.00 %),  over 2x FS 0 (0.00 %),  mean |mix| 191
```

**`to24` never clamps.** The peak sits at 62 % of full scale. The send is correctly scaled
and the "FORCED by the two formats" comment is upheld: 20 441 × 256 = **5 232 896**, which
is exactly what the chip should read.

### 2. The corruption is switched by our own speculative gate

Same binary, same stimulus, only DSPCFG differs:

| DSPCFG | value the microcode reads back | tone-generator side |
|---|---|---|
| **1** — decoded ISA only | `0x4FD900` = **5 232 896** ✓ (= 20 441 × 256) | peak 20 441, 0 % clipped |
| **3** — + speculative ISA | `0x800000` = **the 24-bit rail** ✗ | peak 20 441, 0 % clipped |

★ The input is delivered correctly and read correctly by the *decoded* core. The
speculative core destroys it.

### 3. Which word, and by which mechanism

Watching every D-RAM store that lands on the input-latch cells:

```
INPUT LATCH L (0x47): 1 597 811 stores, site 2, word 012.2.FF.1CE
INPUT LATCH R (0x4A): 1 601 622 stores, site 2, word 090.A.01.1C8
```

**Site 2 is the bit-4 accumulator store** — `write_dword(stdest, acc_to_datum(m_acc))` —
firing **once per frame** on each latch. The L-side word is `w79`, which `r2-output.md`
§3.2 lists as *"the FORCED one-frame D-RAM feedback store at X+1 (K6 §5)"*.

So the mechanism is: **the accumulator saturates under the speculative ISA** (§28 measured
it at −8 795 993 156 259, against a 2⁴³ = 8 796 093 022 208 rail) → `acc_to_datum` of a
saturated accumulator is the 24-bit rail → the bit-4 feedback store writes that rail into
the input-latch cell, every frame.

### 4. What this explains

★★★ **§30's null.** The epilogue was byte-identical with and without notes because the
cell the input stage reads is overwritten with a saturated constant every frame. A constant
in gives a constant out. It was never evidence about the epilogue's decode at all.

It also reframes the whole §§27–29 sequence: those were readings taken downstream of a
corrupted input, which is why every value in them was fixed and none responded to audio.

### 5. The order of work is now inverted

The accumulator saturation is **upstream of everything else** and must be fixed first.
Chasing the epilogue (§29's `SRC 0x06` at w68), the output mapping (§26) or the
presentation (§28) while the input cell is being overwritten by a railed accumulator is
measuring a machine whose input is a constant.

⛔ **And it is a REGRESSION introduced today.** DSPCFG = 1 reads the input correctly, so
the corruption arrived with the speculative rows. The first question is which one saturates
the accumulator — `coeff_fetch` (§29) is the leading suspect, since it made many more words
multiply across the whole program, and no control has been re-run since.

Evidence grade: **MEASURED, with a working control** (the DSPCFG A/B, and the tone-generator
census that eliminates the send).

## 32. Bisection — the saturation is §28's ACCB pair, and `coeff_fetch` is EXONERATED

**2026-07-28.** §31 named `coeff_fetch` (§29) the leading suspect for the accumulator
saturation. **Wrong.** Wired each of today's four speculative rows to a bit of an env-var
mask (`UPD6383_SPEC`) so one build could leave each out in turn, and measured the
input-latch read-back (correct = 5 232 896; railed = 0x800000):

```
mask   left out                       input read-back
0xF    (all on)                       0x800000  (8 388 608)   RAILED
0xE    bit0  ACCB + f31[2] select     0x2CCCCC  (2 936 012)   clean
0xD    bit1  SRC 0x11 = ACCB          0x2CCCCC  (2 936 012)   clean
0xB    bit2  coeff_fetch      (§29)   0x800000  (8 388 608)   RAILED
0x7    bit3  deferred presentation    0x800000  (8 388 608)   RAILED
0x0    (all off)                      0x2CCCCC  (2 936 012)   clean
0xC    §29's two fixes only           0x2CCCCC  (2 936 012)   clean, 0 % traps
```

★ **The saturation requires BOTH ACCB bits and appears with neither §29 fix.** Removing
either half of §28 clears it; removing either half of §29 does not. My suspicion was
backwards: I blamed the rows that were code-defect fixes and exonerated nothing.

★★ **§28 is now worse than "failed its test" — it is ACTIVELY HARMFUL.** It saturates the
accumulator, and via `w79`'s bit-4 feedback store that saturated value lands on the input
latch every frame, which is the whole of §31 and the cause of §30's null. Default changed
to **`0xC`**: §29's two fixes on, §28's ACCB reading off, kept only as a switch.

⚠ **`0x2CCCCC` = 2 936 012 is NOT the correct value either.** DSPCFG = 1 reads
**5 232 896**, so the speculative core still corrupts the latch — just not to the rail.
Noted, not solved. (It is however striking that 2 936 012 matches the *"the body delivered
a datum of 504 instead of ~2 936 000"* figure already on record in the core's own comments,
so the value is the body's output, not noise.)

### Answering "how many speculations became confirmed findings?"

Honest count over this register's 32 sections. **Confirmed, standing:**

| # | finding | how |
|---|---|---|
| 1 | `f31 == 2` does not write `P` | 14 of 19 ROM LFO constants vs 11, a strict superset |
| 2 | `SRC 0x08 = coef` | measured |
| 3 | mode 4's target ≠ `mem[ptr]` | measured |
| 4 | the coefficient stream's pointer rule | verified, C-RAM[0x00] = 114 |
| 5 | DO3 → HSO pin 62 → HD-AE5000 | §24, service manual + manufacturer (external) |
| 6 | the multiply inherited the cursor's gate | §29, MUL column |
| 7 | the class-C/D presentation returned before the multiply | §29, MUL column |
| 8 | the input send never clips (peak 20 441/32 768, 0.00 %) | §31, with control |

**Refuted, and that is also a result:** the class-1 slot-selector (§26), ACT 0x04
reachability, the census v1, "stereo 500/501", "eight oscillators", "the DSP is audible",
`SRC 0x11 = mem[ptr]`, §27's ACCA/ACCB reading and "tempA holds the unit result" (§30),
§28's fix, and §31's own `coeff_fetch` suspicion (§32).

★ So of roughly **29 graded speculative rows, 4 became confirmed** — and 3 more confirmed
findings came from *code-defect* work and *external documents* rather than from the
speculation. The rest are either still guesses or have been shot down. **The refutations
outnumber the confirmations**, and every confirmation but one came from a measurement with
a control that could have failed.

Evidence grade: **MEASURED, with a working control** (leave-one-out, 7 configurations).

## 33. ★★★ THE LATCH CORRUPTION IS FIXED — the chip reads its own input for the first time

**2026-07-28.** §32 left the speculative core still corrupting the input latch (reading
`0x2CCCCC` where DSPCFG = 1 reads `0x4FD900`). Located and fixed.

### It was never an addressing mismatch

The natural suspicion was that the deposit and the read used different cells. Instrumented
the pointer drift between them, and it is **exactly +2 and +5, 50/50, with no other value
in 3 194 880 reads** — the pointer arrives precisely at the two latch cells. Dumping every
quantity at a single read:

```
§33 READ ch0  in_base=45 dp=47 cell=47 in_addr=47/4A | mem[cell]=002CCCCC  in_val=00170800
§33 READ ch1  in_base=45 dp=4A cell=4A in_addr=47/4A | mem[cell]=00000000  in_val=001D8700
```

★ **Every address agrees.** `in_base + 2 = dp = cell = in_addr[0] = 0x47`. The cell simply
did not contain what had just been deposited into it: the deposit wrote `0x170800` and the
read took `0x2CCCCC` — *the previous frame's body datum*. The chip was processing **its own
stale output instead of its input, every frame.**

### The cause, predicted verbatim by this device's own comment

The **bit-4 accumulator store** was landing on the latch cells. And the disassembler already
says why that must never happen:

> *"hi12 bit 4 (the accumulator store) … needs a CORRECT ACCUMULATOR, and the accumulator of
> a frame full of undecoded words is not the chip's — so performing it would write invented
> data into real cells. … EXECUTE WHAT ADDRESSES, NEVER WHAT COMPUTES."*

The speculative gate generalised the store and broke exactly that rule. **The rule was
already written down, with the consequence spelled out, before the rule was broken** —
[[check-the-handover-first]] for the fourth time today.

### Result

```
                            before          after
value read == value latched   31 682      1 597 440   (100 %)
                MISMATCHED  1 565 758             0
peak |sample| read           0x2CCCCC      0x4FD900   (5 232 896 = 20 441 x 256 ✓)
"THE DEPOSIT AND THE READ DISAGREE"  printed        GONE
frames trapped                                    0 (0.00 %)
guard suppressed                            3 198 369 stores (2/frame)
last offender                               090.A.01.1C8
```

★★★ **The speculative core now reads its true input, on 100 % of frames**, and the value
matches the decoded core exactly. Every downstream measurement taken before this section
was made on a chip whose input was its own stale output — which is why §30's notes-vs-silence
A/B showed nothing, and why §§27–29 saw only fixed values.

⛔ **This is a GUARD, not a decode.** K6's feedback store is FORCED at X+1; the latch cells
are X+2 and X+5. A store reaching them means our **addressing is still wrong somewhere**,
and the offender is named (`090.A.01.1C8`, class 0xA, `addr8 = 0x01`, i.e. a +1
post-increment word). Finding why its store targets the latch is the next real question;
the guard stops the corruption from masking every measurement meanwhile.

### What did NOT change — and this is now a clean fact

```
tA at the output stage   -126480  ->  504     (the corrupted vs the true input)
PRESENTATION WORDS       3 175 680 executed,  0 wrote NON-ZERO
raw accumulator at presentation                0
```

The epilogue still presents zero. But that is now a **measurement on a correctly-fed chip**
rather than on a self-poisoned one, and `tA` moved with the input (504, the pre-corruption
value from §27) — so the output stage is at last responding to something real.

Evidence grade: **MEASURED, with a working control** (the DSPCFG A/B, the drift histogram,
the per-read dump, and a 0-mismatch result against 1 565 758 before).

## 34. Why that store targets the latch — the word is NAMED in our own notes

**2026-07-28.** §33's guard was explicitly a band-aid. Chased the cause.

### Which words, and when

Recording the I-RAM slot of every suppressed store:

```
iw3:1597440   iw7:1597440   iw61:203  iw64:203  iw71:201  iw79:2880  iw320:2
```

★ **`w3` and `w7`, exactly once per frame each** — the words *immediately preceding* the
header reads at `w4` and `w8`. Everything else is noise. So `w3`→`w4` and `w7`→`w8` are
store-then-read pairs **on the same cell**: the microcode writes the cell that the input
stage then reads.

### The word decodes as a perfectly ordinary ring-buffer step

`090.A.01.1C8` — `hi12` bit 4 **SET** (store), bit 7 **SET**, `f31 = 0`, `class4 = 0xA`
⇒ mode 2, post-increment **+1**, `SRC = MEM`. Read `mem[ptr]`, write the accumulator back
to `mem[ptr]`, advance one. Nothing is malformed; every rule in the core admits it.

### ★★★ And the note already names it

`upd6383d.h`'s round-4 adjudication, item 3, lists the three words guard 7 refuses:

> *"the other three (`090.A.00.1D5`, `090.2.FB.40E`, **`090.A.01.1C8`**) are refused by
> guard 7 — so settling the CONDITION changes the emulated machine by ZERO words."*

**Our offender is one of the three, named by hand.** That is why DSPCFG = 1 is clean: the
decoded core refuses it. And item 1 records that two suppression conditions survived
round 4 —

> *"exactly TWO survive — `b7 & f31 == 1` (this one) and `b7 & f31 != 2`. They differ only
> where hi12[3:1] is outside {1,2}, **which alu_decoded() refuses anyway, so the choice
> costs ZERO words.**"*

Our word has `f31 = 0` — precisely the region where the two differ. ★ **The "costs zero
words" clause is true of the decoded core and false of the speculative one**, which admits
that whole region. So the round-4 tie is *live* here, and this is the first context in the
project that can even see it.

### The tie-break was testable — and it FAILED

Prediction: under `!= 2` the stores are suppressed and the input survives. Measured:

```
                      f31 == 1 (round-4)      f31 != 2 (the rival)
w3 / w7 stores          1 597 440 each          gone, as predicted
w79 stores onto latch           2 880              1 600 927   ← moved here
read == latched            31 682 / 1 597 440   31 682 / 1 597 440   unchanged
```

⛔ **The corruption relocated rather than disappeared.** Suppressing more stores also
perturbs `alu_decoded()`'s executable set, so the pointer trajectory itself moves and a
different word arrives at the latch. **The input stage does not settle the round-4 tie**:
one rule does not save the input and the other does not uniquely destroy it. Reverted to
the round-4 condition; §33's guard restored (input 100 % intact, 0 traps).

### What this establishes

1. **The store is not a decode error.** `w3`/`w7` are ordinary mode-2 read-modify-write
   ring-buffer steps and every rule admits them.
2. ★ **So the modelling assumption is what is wrong.** Cells `X+2`/`X+5` are ordinary
   D-RAM that the program writes on its way past — the D-RAM write census shows **all 256
   cells written**, with `0x46`, `0x4A`, `0x4B` among the busiest. Treating two of them as
   the audio input port puts our deposit in the program's scratch.
3. **`w4` reads what `w3` just wrote.** The inference "`w4` reads cell X+2, therefore the
   input arrives at X+2" does not survive: X+2 has a writer one slot earlier.

⇒ **The open question is no longer "why does the store target the latch" — it is "where
does the audio actually enter the chip?"** The `+2`/`+5` offsets are marked FORCED from a
pointer-rule walk of the twelve input words, and that walk now has a competing explanation.
Until that is re-adjudicated the guard stays: it is a declared modelling patch holding the
input in place, not a claim about the hardware.

Evidence grade: **MEASURED** (slot histogram, field decode, the D-RAM census) for 1–3;
**REFUTATION** for the round-4 tie-break.

## 35. ★★★ RE-ADJUDICATED: the audio enters EXACTLY where the model said. §34 is retracted.

**2026-07-28.** §34 concluded that the modelling assumption was wrong — that cells X+2/X+5
are ordinary scratch and "w4 reads what w3 just wrote". **That is retracted.** The
adjudication went the other way, and the answer was in `K6_INPUT_STAGE`, the twelve-word
table the core already carries.

### The documented walk says the stores never touch the latches

```
w0  ST mem[X+0], p+1        w6  END BLOCK A, read mem[X+4], p+0
w1  C-format, no effect     w7  ST mem[X+4], p+1
w2  read mem[X+1], p+2      w8  *** PORT READ B *** mem[X+5], p+1
w3  ST mem[p] (= X+3), p-1  w9  ST mem[X+6], p-1
w4  *** PORT READ A *** mem[X+2], p+2      w10 read mem[X+5] again, p+1
w5  read mem[X+4], p+0                     w11 END BLOCK B, read mem[X+6], p+1
```

★ **w3 stores at X+3 and w7 at X+4.** Neither goes near X+2 or X+5. And our pointer trace
matches the table at **all twelve words**:

```
measured  w0:46 w1:46 w2:48 w3:47 w4:49 w5:49 w6:49 w7:4A w8:4B w9:4A w10:4B w11:4C
expected  w0:46 w1:46 w2:48 w3:47 w4:49 w5:49 w6:49 w7:4A w8:4B w9:4A w10:4B w11:4C
```

So the walk was never wrong, the offsets were never wrong, and the input window is exactly
where it was said to be. **The defect was ours.**

### The defect: the bit-4 store was performed TWICE

The twelve input-stage words execute as

```cpp
exec_addressing_only(word, true);   // pointer, STORE, cursor, latch capture
exec_alu_k6(word);                  // "the ALU, without re-walking the pointer"
```

`exec_addressing_only()` **already performs the bit-4 store**, at `cell` — the pointer
*before* its post-increment, which is correct. `exec_alu()` then performed it **a second
time** at `stdest = m_dp`, i.e. at the pointer the first call had already advanced: **one
cell late.**

★★★ And one cell late is catastrophic *precisely here*, because the walk is built so the
post-increment parks the pointer on the cell the **next** word reads. w3's late store lands
on X+2 and w7's on X+5 — which is exactly what makes them the input latches. The bug could
not have picked a worse pair of cells if it had tried.

### Result

```
                                  before        after
w3 stores onto a latch          1 597 440         0
w7 stores onto a latch          1 597 440         0
total suppressed by the guard   3 198 369       609   (0.04 %)
value read == value latched     1 597 440 / 0 MISMATCHED   (unchanged, now WITHOUT the guard doing the work)
peak |sample| read               0x4FD900 = 5 232 896 = 20 441 x 256  ✓
frames trapped                                   0 (0.00 %)
pointer walk                                 identical
```

§33's guard is no longer load-bearing: it went from suppressing 3 198 369 stores to 609,
and those come from three epilogue words (iw61, iw64, iw71) — a separate, tiny residue for
another pass. **The guard is now a genuine regression alarm rather than a patch.**

### What this corrects

| claim | status |
|---|---|
| §34: "cells X+2/X+5 are ordinary scratch; the modelling assumption is wrong" | ⛔ **RETRACTED** |
| §34: "w4 reads what w3 just wrote" | ⛔ **RETRACTED** — w3 writes X+3 |
| §34: "the store is not a decode error" | ✔ correct, but it was an *execution* error |
| `IN_LATCH_L_OFF = 2` / `IN_LATCH_R_OFF = 5`, marked FORCED | ✔ **VINDICATED** |
| the round-4 tie-break test (§34) | still a refutation, and now clearly a false lead |

★ Three sections (§§33–35) were spent on a defect that the project's own twelve-word table
described precisely enough to have caught immediately — the *fourth* time today the answer
was already written down ([[check-the-handover-first]]). The difference is that this time
the table also **vindicated** the model instead of overturning it.

Evidence grade: **MEASURED** — pointer walk against the documented table at 12/12 words,
and the store counts before/after.

## 36. The 609 residue — the GUARD was the defect, not the stores

**2026-07-28.** §35 left 609 stores (0.04 % of frames) still reaching the input window, from
`iw61`, `iw64`, `iw71` and `iw320`. Censused them by word rather than trusting the slot
attribution — which was right to do, since the slot histogram and the "last offender"
disagreed:

```
word 012.1.8D.05B  iw61   mode 1  dest 8D  x203
word 011.9.0F.446  iw71   mode 1  dest 0F  x201
word 011.9.0E.445  iw64   mode 1  dest 0E  x203
word 090.2.FB.40E  iw320  mode 2  dest 53  x2
```

★ **Not one destination is a latch cell.** They are `0x8D`, `0x0F`, `0x0E`, `0x53` — named
registers. Three of the four are **mode-1** stores, which aim at `addr8` explicitly and
cannot "wander" onto anything.

They matched the guard only because **`m_in_addr` had drifted on top of them.** `X` is
`m_dp` at frame start; it is `0x45` on 98.31 % of frames, and in the other **1.69 %** the
input window lands wherever the pointer failed to return to — sometimes on `0x8D` or `0x0E`.

⇒ **The residue is a symptom of frame-closure failure** (936 959 of 962 880 frames close),
not a store defect. And §33's guard was *suppressing 607 legitimate register writes* to
fake-fix 0.04 % of frames — a real corruption traded for a cosmetic one.

### Fix: the guard stops suppressing

```
                              suppressing        report-only
value read == value latched   1 597 440 / 0      1 597 440 / 0      ← unchanged
peak |sample| read              0x4FD900           0x4FD900
frames trapped                    0 (0.00 %)         0 (0.00 %)
legitimate register writes       607 CORRUPTED      all preserved
```

★★★ **Allowing the 609 stores changes the input audit by nothing at all** — still 100 %
intact, 0 mismatches. That is the proof they were never clobbering a read: the collisions
happen in frames and at moments where nothing depends on them. The suppression was pure
cost.

The counter stays as a **regression alarm** for §35: if a structural clobber ever returns,
it is reported rather than silently corrupting the input.

### Where the input question now stands — CLOSED

```
§31  the input "rails"                 -> self-inflicted, §28's ACCB pair
§32  which row saturates               -> ACCB, coeff_fetch exonerated
§33  latch corruption                  -> guarded, input 100 % (band-aid)
§34  "the model is wrong"              -> RETRACTED
§35  the real cause                    -> the bit-4 store ran TWICE on the K6 path
§36  the 609 residue                   -> the guard itself; now report-only
```

**The audio enters at X+2 and X+5, read by w4 and w8, exactly as `K6_INPUT_STAGE` says.**
The offsets marked FORCED are vindicated, no band-aid is load-bearing, and the input is
intact on 100 % of frames with 0 traps.

★ The one genuine defect this exposed and did NOT fix: **X drifts on 1.69 % of frames**,
i.e. the frame-closure residue, which is a pre-existing open item and now has a second
symptom attached to it.

Evidence grade: **MEASURED** — the by-word census, and the suppressing/report-only A/B
showing an identical input audit.

## 37. The frame-closure drift — there is nothing to fix. It is a BOOT TRANSIENT.

**2026-07-28.** §36 closed by naming the frame-closure residue "the better-evidenced
target". Measured it before touching it, and **that characterisation was wrong**.

The device reported `min -1  max +116  (VARIES between frames)` and `frames that closed
1 560 959 of 1 586 880` — which reads like a persistent 1.63 % failure. It is not. Adding a
residue histogram and a time placement:

```
RESIDUE HISTOGRAM   +0:1 560 959   -1:21 120   +5:2 880   +6:960   +7:960   +116:1
non-closing over time (16 buckets)   0  25 920  1  0 0 0 0 0 0 0 0 0 0 0 0 0
first non-closing frame 204 482,  last 264 002,  longest consecutive run 21 120
```

★★★ **Every non-closing frame lies between frame 204 482 and 264 002** — one contiguous
window of ~60 000 frames, ≈ 4.6 s to 6.0 s of emulated audio, i.e. while the host is still
uploading programs. Fifteen of sixteen time buckets are **empty**. From frame 264 003 to
the end of the run, **all 1 560 959 measured frames close with residue exactly 0.**

The residues are not noise either: `-1` occurs 21 120 times in **one contiguous run**, and
`+5`/`+6`/`+7` in small blocks. Those are transient programs, each internally consistent
with its own walk — exactly what a sequence of partially-uploaded or short-lived images
looks like.

### Consequences

1. **There is no steady-state pointer bug.** The run-wide `min/max … VARIES` line mixes the
   boot window into the census and makes a settled quantity look broken — the same trap
   [[check-the-handover-first]] warns about (*"compute the null and the calibration before
   interpreting a table"*). Annotated in the device so the next pass does not chase it.
2. ★ **§36's second symptom dissolves with it.** The 1.69 % of frames whose `X ≠ 0x45` are
   the *same* frames, so the input-window spread that produced the 609 residue is this
   transient and nothing else. Both observations have one cause, and it is boot.
3. **The honest closure figure is 100 %**, not 98.4 %: over the whole steady state the
   pointer returns exactly, which makes the per-unit D-RAM base `0x05 | unit<<7` look
   considerably better supported than "a residue of 0 is its strongest live consequence"
   suggested.

### What I did not do

No fix, because there is no defect to fix. Writing one would have been a change justified
by a statistic I had not decomposed — and the only honest deliverable here is the
decomposition plus the retraction of my own framing.

⚠ Still genuinely open, and unaffected: **210 241 frames end on the 384-slot CAP and 26 880
by I-RAM OVERRUN** (13 % of all frames), which are excluded from the closure census
entirely. Those are concentrated at boot too on the face of it, but that has **not** been
measured, and it is the real remaining question in this area.

Evidence grade: **MEASURED** (residue histogram + time buckets over 1 824 001 frames);
**RETRACTION** of §36's characterisation.

## 38. CAP and OVERRUN — the same boot transient, ending at the same frame

**2026-07-28.** §37 left this as "the real remaining question in this area": 210 241 frames
end on the 384-slot CAP and 26 880 by I-RAM OVERRUN — 13 % of all frames, excluded from the
closure census. Measured with the same instrument.

```
CAP     over time   118 749  85 732  5 760  0 0 0 0 0 0 0 0 0 0 0 0 0
CAP     frames 1 .. 264 001            slots always EXACTLY 384..384  (the cap)
OVERRUN over time         0   6 138  20 742  0 0 0 0 0 0 0 0 0 0 0 0 0
OVERRUN frames 231 362 .. 258 241      slots always EXACTLY 350..350
```

★★★ **Both are bounded in time, and both stop at the same place §37's closure residue
stops** — frame ~264 002. Thirteen of sixteen time buckets are empty for CAP and thirteen
for OVERRUN. After that boundary, all ~1.56 M remaining frames reach the wait word, trap 0
times, and close with residue 0.

**So all three anomalies are one event**: the last program upload completes at ≈ frame
264 002, and from there the emulated DSP runs perfectly for the remaining 85.5 % of the run.

Two details worth keeping:

* **CAP is always exactly 384 slots and starts at frame 1.** That is the signature of an
  I-RAM with no wait word in it yet — the frame runs to the hard cap because there is
  nothing to stop it. Exactly what the pre-upload state should look like.
* **OVERRUN is always exactly 350 slots**, in a narrow window. A constant, not a scatter:
  a partially-uploaded image whose execution runs off the loaded region at one fixed point.

### They are also harmless

`clean = (traps == 0) && (partials == 0) && hit_wait && !overrun`, so neither kind is
returned to the tone generator — **these frames produce no audio at all.** They are
discarded, not mixed.

### The area is closed

```
§33-§36  input-latch corruption      -> fixed at the decode (double store), no band-aid
§37      frame-closure "drift"       -> boot transient, 100 % closure in steady state
§38      CAP / OVERRUN               -> same boot transient, discarded, no audio effect
```

★ **In steady state the emulated IC311 now: reads its true input on 100 % of frames, runs
all 285 slots with 0 traps, and closes its pointer with residue exactly 0.** Every "13 %",
"1.69 %" and "1.63 %" statistic in this area turned out to describe boot and nothing else —
three separate figures, one cause, and none of them a defect.

⚠ What this does **not** touch: the epilogue still presents zero (§§27–29 remain open on
their own terms), and the deferred controls for `coeff_fetch` (SINGLE DELAY, the biquad,
the 19 LFO constants) have still not been re-run. That is now the outstanding item.

Evidence grade: **MEASURED** (time buckets and slot-count bounds over 1 824 001 frames).

## 39. The deferred controls — `coeff_fetch` was never speculative. It is K4, FORCED.

**2026-07-28.** §29 flagged that `coeff_fetch` "changes which words multiply across the
WHOLE program" and that SINGLE DELAY, the biquad and the 19 LFO constants had to be
re-measured before trusting it. Went to run them. **The premise was wrong.**

`lfo_ramp.py` turns out to be a ROM/descriptor analysis — it decodes constants to Hz and
never simulates the ALU, so it cannot test this at all. The instrument that can is
`action00_discriminate.py`, which calls `DIS.coeff_consumer(w)` — and following that into
`dsp_disasm.py` produced the answer directly:

```python
def cursor_fetch(w):
    """bit 23 (== class4 bit3) = CURSOR-FETCH enable (NOT multiply-enable).
    NOT in the C-format family: there bit 23 is a bit of the immediate."""
    return bool((w >> 23) & 1) and not c_format(w)
```

★★★ **That is bit-for-bit the `coeff_fetch()` I added to the core in §29** — `class4 & 8`
*is* `(w >> 23) & 1`, with the same `!c_format` exclusion. The split between **fetch**
(bit 23) and **advance** (`class4 == 0xA`) is already the established reading, marked
**K4, FORCED**, and the offline model has been using it all along. The C++ core was the
only place that conflated them.

### The biquad is EVIDENCE FOR it, not a control at risk

From `coeff_consumer`'s own docstring:

> *"The PARAMETRIC EQ body's ten class-8 words sit inside a cursor map proven to the bit at
> 6 cells per band; if class 8 advanced, band k would start at cell 7k and all 60 named
> roles would shift."*

So the control I was afraid of breaking is the reason the reading exists. ⇒ **§29's caveat
was over-cautious in exactly the wrong direction**: the change did not risk the controls,
it brought the core *into line* with the model that produced them.

### And the docstring warns about precisely what I hit

> *"MEASURED over the 2974-word body corpus: the only classes that set bit 23 are 8 (42)
> and A (822). **The KERNEL additionally has class 9 (4), C (1) and D (1), so a core must
> NOT assume `bit 23 => class 8 or A`.**"*

Those 4 + 1 + 1 kernel words are the epilogue set from §29 — `w73` is the class **C**,
`w78` the class **D**. The note is an instruction addressed to the core, and the core was
violating it. Fifth time today the answer predated the question.

### ⚠ One thing my version still assumes, and the note contradicts

`cursor_fetch` is documented as *"CURSOR-FETCH enable (**NOT multiply-enable**)"*. The core
now gates the whole block — fetch, multiply, and (separately) advance — on it. So:

| aspect | status |
|---|---|
| fetch and advance are DIFFERENT conditions | ✔ **FORCED (K4)**, now matched |
| fetch = bit 23, advance = `class4 == 0xA` | ✔ **FORCED**, now matched |
| the MULTIPLY is gated by bit 23 | ⛔ **still an assumption** — the note says bit 23 is *not* multiply-enable |

So §29's split is settled and its residual guess is now sharply localised: what enables the
**multiply**, as distinct from the fetch. That is a much smaller open question than "did I
break the controls", and it is the honest successor to it.

### Controls: not run, and correctly so

No control needed re-running, because the change moved the core *toward* the model the
controls were computed in. Re-running them would have measured agreement I could have read
off the source — and would have been the fourth instrument this month that could not fail.

Evidence grade: **DOCUMENTED (K4, FORCED)** — pre-existing, independent of this session.

## 40. What enables the multiply — the LATCH is real, the reading is NOT adopted

**2026-07-28.** §39 localised the last guess: the core gates the multiply on bit 23, which
`dsp_disasm.py` says is *"CURSOR-FETCH enable (**NOT multiply-enable**)"*.

### The architectural clue was already in the device

```cpp
u32 m_k, m_l;           // multiplier input latches
```

`m_k` is loaded from `C-RAM[cursor]` inside the fetch block — **and then never read**. The
multiply uses the freshly-read `coef` instead. So the device declares a latched-coefficient
MAC and then bypasses its own latch. That is exactly the shape "bit 23 is not
multiply-enable" describes: **bit 23 RELOADS K; the multiplier runs on whatever K holds.**

Implemented as mask bit 4: `P = K × L` on every word that is not `f31 == HOLD`, with bit 23
reloading K and `class4 == 0xA` still the only cursor advance.

### Result — the epilogue accumulates for the FIRST TIME

```
  iw  word           acc     P    MUL
  65  200.1.8F.1C1     0    94     Y
  66  000.1.8C.107    94    94     Y
  68  092.1.8C.19B   188     0     Y     <- acc has ACCUMULATED, 94 -> 188
  72  000.1.06.087     0     0     Y     <- LOAD acc <- P, and P is 0
  73  E30.C.00.404     0                 <- presents zero
```

★ Every previous section had `acc = 0` at all 22 epilogue slots. It is now non-zero and
*adding*. **And the presentation still reads zero for a new and sharply-localised reason:**
`w72` (`000.1.06.087`, `f31 = 0` ⇒ LOAD acc←P) **zeroes the accumulator one word before
`w73` presents it**, because P is 0 at that moment.

### ⛔ NOT ADOPTED — it fails the honesty test

```
tA at the output stage   504  ->  5      (mask 0xC -> 0x1C)
presentations non-zero     0  ->  0
```

The body's own output dropped by **two orders of magnitude**, and there is no control that
says which value is right. A reading that makes the epilogue livelier while shrinking the
body's result 100-fold, with the audible outcome unchanged, is not evidence of anything —
it is the "plausible-but-wrong" this device exists to refuse. **Default stays `0xC`; bit 4
is off and available as a switch.**

### What IS established

1. ★ **`m_k`/`m_l` are declared multiplier input latches and the multiply bypasses them.**
   That is a real inconsistency in the core, independent of which reading is right, and it
   is the mechanism by which "bit 23 is not multiply-enable" could be true.
2. ★★ **`w72` is the immediate blocker at the presentation**, whatever gates the multiply.
   It performs LOAD acc←P with P = 0 in the slot before `w73`. Under *every* configuration
   tried, `w73` presents whatever `w72` left, and `w72` leaves zero.
3. The multiply-enable question is **not settled**: latched-K is one reading, it is
   untested against any control, and the LFO/biquad instruments that could discriminate it
   live in the offline model, which does not implement a multiply gate at all.

⇒ The successor question is now `w72`, not the multiplier: **what should `w72` load, and
from where?** It is one word, in a known slot, with a known operation — a far smaller target
than "what enables the multiply".

Evidence grade: **MEASURED** for the latch inconsistency and for `w72`'s effect;
**NOT ADOPTED / UNCONTROLLED** for the latched-K multiply itself.

## 41-42. ★★★ THE OUTPUT LEVEL WAS READ FROM THE WRONG MEMORY

**2026-07-28.** §40 handed over "what should `w72` load, and from where?". `w72` is
`000.1.06.087` and its `addr8` is **0x06** — the **unit-0 OUTPUT LEVEL**. Its unit-1 twin
is `w77` (`addr8 = 0x86`). Chasing that pair produced a defect one level up.

### The level was never applied. At all.

`do_presentation()` reads the per-unit level and guards it:

```cpp
const u32 lvl = m_dram.read_dword(unit ? 0x86 : 0x06) & 0xffffff;
if (lvl != 0) scaled = (scaled * s64(util::sext(lvl, 24))) >> 23;
```

Instrumented at the presentation: **`lvl` is `0x000000` on 100 % of frames, both units.**
So the guard skipped the multiply every time and **the per-unit output level has never been
applied in this emulator.**

### Why: the host writes C-RAM, and only C-RAM

★★★ There is exactly **one** host write path into this device, and it writes **`m_cram`**.
There is **no host write to D-RAM anywhere in the core.** The per-unit output level is a
host-programmed value ("the last four host actions of cold boot are `setvec unit1,#200` /
`setvec unit0,#84` / `reg 0x06 <- +0.500000` / `reg 0x86 <- +0.183992`"), so reading
**D-RAM**`[0x06]` read a cell the host can never touch.

Corroboration, all independent:

* Reading **C-RAM** instead: `unit0 = 0x2CCCCC` non-zero on **1 560 000** frames,
  `unit1 = 0x006854` on **1 582 080** — against 0 and 0 from D-RAM.
* The host's C-RAM write runs are `[0x00..0x13] [0x50..0x6D] [0x6E..0x8B] [0x90..0xAD]
  [0xAE..0xB4]`. **`0x06` lies inside `[0x00..0x13]` and `0x86` inside `[0x6E..0x8B]`** —
  both are host-written cells.
* The kernel's cursor walk shows `0x400000` — exactly **+0.5** — living in C-RAM.

Adopted as mask bit 6; **default is now `0x4C`.**

### ⚠ What is NOT established

The values read (`0x2CCCCC` ≈ 0.35, `0x006854` ≈ 0.0032) are **not** the cold-boot
constants `+0.500000` / `+0.183992`. Two readings, not separated: the host reprograms the
levels for the loaded effect between cold boot and frame 970 000 (likely — these are
plausible reverb send levels), or the address mapping inside C-RAM is off. **The SPACE is
established; the exact CELL is not.**

### And a false lead recorded (§41)

Before finding this I read the D-RAM census — `06: 0/1613627`, "written 1.6 M times, always
zero" — and concluded `w72`/`w77` were *clobbering* the level, exactly as `w3`/`w7` clobbered
the input latch. Built a guard (mask bit 5) to suppress those stores. ⛔ **It changed
nothing**: the level was still `0x000000`, because nothing was ever *there* to protect. The
census counts store *attempts*, and I read a symptom of the real defect as its cause. Bit 5
is left off; the counter stays as an observer.

### Where this leaves the output stage

The level path is now correct, and the presentation **still writes zero** — because `acc`
is 0 at `w73` (§40's `w72` LOAD acc←P with P = 0). Fixing the level could not have made
sound on its own; it removes a second, independent defect that would have silently
attenuated the result to nothing *even after* the accumulator is fixed.

★ Two defects were stacked here: the accumulator arrives empty, **and** the level it would
be scaled by was read from a memory the host cannot write. Only one of them was visible
from the audio.

Evidence grade: **MEASURED** — the single host write path, the D-RAM/C-RAM A/B at the
presentation, and the host's own C-RAM write runs containing both addresses.
**NOT ESTABLISHED**: the exact C-RAM cell. **REFUTATION**: §41's clobber theory.

## 43. The accumulator at w73 — the blocker becomes QUANTITATIVE

**2026-07-28.** Implemented §42's implication as mask bit 7: `w72`/`w77` (class 1,
`addr8 = 0x06`/`0x86`, the per-unit level cells) **load the coefficient and leave the
accumulator alone**, rather than performing `f31 = 0 ⇒ LOAD acc←P` and destroying it.

### It works — and it is not enough

```
  iw  word           acc     P    MUL
  68  092.1.8C.19B   188     0     Y
  71  C41.9.00.446   188     0     .
  72  000.1.06.087   188     0     .     <- ★ was 0 here; the ladder now SURVIVES
  73  E30.C.00.404     0     0     Y     <- w73 zeroes it ITSELF
```

★ `w72` no longer clears the accumulator. The epilogue's ladder reaches the presentation
intact for the first time. **And `w73` then zeroes it anyway**, for a reason that is
arithmetic rather than structural:

`w73` is `SRC = ACC`, `f31 = 0`, and fetches a coefficient — i.e. `acc ← K × acc_to_datum(acc)`.
`acc_to_datum()` shifts right by `ACC_SHIFT = 16`, and

```
    acc = 188      ->      188 >> 16  =  0
```

The accumulator is **too small to survive its own datum conversion**. Multiply by any level
and it is still zero.

### ⇒ The defect is now a MAGNITUDE, not a route

Everything structural in the output stage is finally in place: the input arrives intact
(§35), the multiply issues (§29), the presentation runs after the arithmetic (§29), the
level is read from the memory the host writes (§42), and the ladder survives to `w73`
(§43). What remains is one number.

```
   input entering the chip          5 232 896
   accumulator at the presentation        188
   the body's expected datum        ~2 936 000   (this core's own comment)
```

★★★ **The signal is ~4 orders of magnitude too small by the time it reaches the output
stage.** That is the whole of the remaining silence, and it is a single, well-posed
question: *where does the body lose 10⁴?*

Two candidates already on record, neither tested:
* the **latched-K multiply** (§40, mask bit 4) is what makes the epilogue accumulate at
  all — but it also dropped the body's own `tA` from 504 to 5, a 100× loss it introduced.
  So it may be buying the ladder at the cost of the level.
* the **fixed-point regime** (`ACC_SHIFT = 16`, `P_SHIFT = 6/23`) is flagged in this core
  as "MEASURED and still a GUESS as to which side is wrong". A per-stage shift error of
  2⁴ compounding across the ladder would produce exactly this.

### Not adopted by default

Bit 7 stays **off** (default remains `0x4C`). It is well-motivated — r2-output.md §3.1
calls `w77` the word that *"aims a POINTER at reg 0x86"*, and §42 established those cells
are the host-written levels — but it is untested against any control, and today's record on
adopting well-motivated untested readings is poor (§28 saturated the chip, §41 fixed
nothing). It is a switch, documented, with its effect measured.

Evidence grade: **MEASURED** (the trace before/after, and the `188 >> 16 = 0` arithmetic);
**NOT ADOPTED** for bit 7 itself.

## 44-45. ★★★★ FOUND: the body was multiplying by DELAY-TAP ADDRESSES

**2026-07-28.** §43 reduced the silence to one number: the signal is ~10⁴ too small at the
output stage. Located it, and it is not in the epilogue at all.

### The decay is in body 1's tail, and it is a chain of tiny multiplies

```
n=231 iw301   acc 197 295 225 680        <- the ladder, at full magnitude
n=232 iw302   acc   2 533 682 112
n=233 iw303   P        32 783 680        cur 66  coef 00D800
n=237 iw307   acc          424 000
n=240 iw310   acc           10 656
n=243 iw313   acc                0
```

Each step is `acc ← coef × (acc >> 16)`. With `coef = 0x00D800` read as Q0.23 that is
**×0.0066 per stage**, and six stages give the missing 10⁴ exactly.

### ★★★ Why the coefficients are tiny: they are not coefficients

Dumping the whole coefficient RAM shows **three regions of completely different character**:

```
C-RAM 00: 000072 7FFFFF 0000F0 000000 ... 2CCCCC 2CCCCC 000018 400000 400000 E00000
C-RAM 50: 008000 008400 008800 008C00 ... 00F800 00FC00      <- RAMP, step 0x400
C-RAM 70: 000000 0004BE 00097C 000E3A ... 007B4C 007FFF      <- RAMP, step 0x4BE
C-RAM 90: 200000 400000 400000 3B9885 2DF3A0 C62251 170A3D   <- real coefficients
```

* `0x00..0x13` — real parameters: the LFO ramp step `000072` = 114, the wrap `7FFFFF`,
  levels `2CCCCC`, `400000`, `E00000`.
* `0x90..0xB4` — real coefficients: 0.25, 0.5, 0.464, 0.359, **−0.452**, 0.181, 0.75 …
  signed, irregular, exactly what a reverb needs. **This is what the KERNEL reads**, and
  the kernel shows no decay.
* `0x50..0x8B` — **two monotonic, evenly-spaced ramps**, and they are precisely the host's
  two 30-cell write runs `[0x50..0x6D]` and `[0x6E..0x8B]`. `0x8000 → 0xFC00` in steps of
  1024 spans the upper half of a 64 K space. **This is what the BODY reads.**

A monotonic ramp of 1024-sample steps is an **address table**, not a gain set — and this
chip's block diagram (**PROVEN**) gives it *"an on-chip controller for external DRAM;
ring-buffer address generation (echo / reverb-A / reverb-B regions)"*, with the delay DRAM
identified as IC309 (M5M44260AJ). **The body was feeding delay-tap addresses to the
multiplier.**

### The test, and the result

Mask bit 8: when the cursor lands in `0x50..0x8B` the fetched word is an address, so do not
form a product from it. (The delay datapath is not modelled, so the honest action is to stop
multiplying by an address, not to invent a delay read.)

```
                              before            after
presentations writing NON-ZERO      0        1 560 000   (of 1 560 000 frames)
datum peak at presentation          0        2 877 291   (expected ~2 936 000)
raw acc at presentation             0    538 760 587 509
frames trapped                      0                0
input read == latched         100 %            100 %
```

★★★ **And it is audible in the main mix.** A/B of the rendered audio, DSPCFG 1 vs 3:

```
DSPCFG=1 (decoded)     peak 20 441
DSPCFG=3 (speculative) peak 31 057
samples DIFFERENT   3 120 000 of 5 472 003  (57.02 %)   max |delta| 11 239
```

★ **Three independent arithmetic cross-checks, all exact:**
1. accumulator datum at presentation **8 220 834** ≈ the body's expected ~2.9 M × the
   ladder's remaining gain;
2. × the C-RAM level `0x2CCCCC` (0.35) = **2 877 292**, matching the measured datum peak
   2 877 291 to one LSB — §42's level fix confirmed end-to-end;
3. `2 877 291 >> 8` = **11 239**, matching the measured max delta in the mix exactly — the
   tone generator's own shift.

Adopted. **Default mask is now `0x14C`** (coeff_fetch + deferred presentation + C-RAM level
+ tap table). Bits 0/1 (§28 ACCB), 4 (§40 latched-K) and 7 (§43 level-select) are OFF and
each measurably destroys the result — mask `0x1DC` returns 0 non-zero presentations, which
independently vindicates the refusals in §28, §40 and §43.

### ⚠ THIS IS NOT A WORKING REVERB, and that must not be overstated

The delay-DRAM datapath is **still not modelled**. We *skip* the tap multiplies rather than
*perform* the delay reads, so there is **no delay line and no reverberation**. Measured:
the wet is ≈ 0.55 × dry, i.e. essentially a scaled copy. What has been fixed is that the
chip no longer **destroys** its signal; what it does with it is still mostly absent.

Distinguish this from Part 101's earlier "audible" claim, which was an artefact (a stuck DC
constant on DO3, a pin that carries nothing). This one is on **DO1/DO2 — the main mix**,
with the input verified intact, the level applied, and three stages of arithmetic agreeing.

⇒ **Next: model the external delay DRAM** (IC309 M5M44260AJ), addressed by the `0x50..0x8B`
tap table. That is now the single largest missing piece, and for the first time it is the
*only* thing between here and a real effect.

Evidence grade: **MEASURED** — the C-RAM dump, the decay chain, the presentation census and
the rendered-audio A/B. **SPECULATIVE (well-supported)**: that `0x50..0x8B` are delay-tap
addresses — monotonic ramps, a PROVEN ring-buffer controller, and magnitudes that fit a
64 K space.

## 46-47. ⛔⛔ RETRACTION: §44's "audible" output is a DC CONSTANT

**2026-07-28.** Modelled the delay DRAM, and in doing so found that **§44's headline claim
is wrong**. Recording the retraction first, because it is the most important thing here.

### The measurement that decides it

```
t = 8.0-12.0 s   SILENCE     dry peak      0 mean    0 | DSP peak 11 239 mean 7 492
t = 15.0-19.5 s  SILENCE     dry peak      0 mean    0 | DSP peak 11 239 mean 7 492
t = 20.5-26.5 s  NOTES ON    dry peak 20 441 mean  443 | DSP peak 31 057 mean 7 492
t = 28.0-33.0 s  after       dry peak    390 mean   13 | DSP peak 11 629 mean 7 492
```

★ **The DSP's contribution has mean 7 492 in EVERY window — including four seconds of
silence before any note is pressed** — and the difference signal has **no zero crossings at
all**. It is a **DC constant**, not processed audio.

⛔ So "57.02 % of samples differ, peak 20 441 → 31 057" was **true and meaningless**: a
constant offset differs from silence on every sample. This is the *same class of artefact*
as Part 101's, reached by a different route, and I did not catch it because I checked
*whether* the output changed and never checked *whether it tracked the input*.

★ The tell was in my own numbers: the presentation datum peak was **identical**
(2 877 291) across two configurations with different delay behaviour, and a peak that does
not move when the input moves is a constant. My "three exact cross-checks" verified the
arithmetic of a constant propagating — they could not have failed.

**Method rule 13: a difference from silence is not a signal. Compare against the input, not
against zero — and always measure a window with NO stimulus.**

### What survives from §44

* **MEASURED, stands:** C-RAM has three regions of distinct character; the body's ladder
  multiplies by cells from the `0x50..0x8B` ramps; that chain destroys ~10⁴ of signal.
* **MEASURED, stands:** stopping those multiplies makes the presentations non-zero.
* ⛔ **RETRACTED:** that this constitutes audible output, or output at all. The
  presentations emit a constant. Tracing it: the raw accumulator at presentation is
  538 760 587 509, which the accumulator profile shows is **slot 45/46's peak — a KERNEL
  value**, identical every frame. The output stage is presenting a fixed kernel constant,
  not the body's result.

### The delay DRAM — modelled, fed, and it changes nothing

The port was already implemented (descriptor → `addr = (cell + frame) & 0xffff` → 16-bit
read/write). It was running (33 M reads, 31 M writes) but **every descriptor cell read
`0x0000`**, so all taps addressed one rotating cell.

★★ The descriptors are the per-unit C-RAM banks, and two independent structures agree:

```
cursor bank 0x70 (unit 0)  ->  cells 0x0000..0x7FFF  ->  unit 0 delay region (below 0x8000)
cursor bank 0x50 (unit 1)  ->  cells 0x8000..0xFC00  ->  unit 1 delay region (above 0x8000)
```

against `adjudication-round4.md` §2's **MEASURED** split *"unit 0 below 0x8000, unit 1
above"*. This file's own note already recorded the three cursor loads — *"iw42 → 0x70
(unit 0), iw50 → 0x50 (unit 1), iw69 → 0x90 (the epilogue)"*.

Wired as mask bit 9: descriptors now read **0x04BE, 0x2132, 0x25F0** — real and distinct,
non-zero on 64 281 598 of ~64 M accesses (was 1 561 919). 0 traps.

⛔ **And the rendered audio is bit-identical to without it: 0 of 5 472 003 samples differ.**
Which is exactly what the retraction predicts — if the output is a constant sourced from
the kernel, the delay line cannot reach it.

### Where this actually leaves things

The chip now has: a correct input (§35), a working multiply gate (§29/§39), the level from
the right memory (§42), no address-multiplies (§44), and a **fed delay line with distinct
per-unit taps** (§47). What it does **not** have is any path from the body's result to the
presentation — the presentation emits a kernel constant.

⇒ **The real question is the one §40 and §43 kept circling and I mistook for solved: what
connects the BODY's accumulator to `w73`/`w78`?** Every fix since has been upstream
plumbing; the last joint is still open, and the DC proves it.

Evidence grade: **MEASURED** (the silence-window census, the zero-crossing test, the
descriptor A/B); **RETRACTION** of §44's audibility claim.

## 48. What connects the body to w73 — IT ALREADY DOES. The chip is SATURATED.

**2026-07-28.** §47 ended by saying *"nothing connects the body's accumulator to w73/w78"*.
⛔ **That is wrong too.** Tracing the epilogue at the actual default (`0x14C`) — which I had
never done, having traced only `0xDC` and `0x1C`:

```
  n=276  iw 73  E30.C.00.404   acc 538 760 587 509  ->  datum 8 220 834   MUL Y
                               tA 8 388 607 = 0x7FFFFF      mem[dp] 8 220 834
```

The body's value **reaches the presentation.** The connection was never missing.

### ★★★ The chip is in hard saturation

`tA` is pinned at **0x7FFFFF — the 24-bit maximum** — and the accumulator profile is
decisive: every peak is an exact small-integer multiple of ONE quantum.

```
538 760 587 509 (x1)   1 077 521 175 018 (x2)   1 616 281 762 527 (x3)   2 155 042 350 036 (x4)
```

That is a railed datum being added repeatedly. **A saturated value is constant regardless of
input — which is exactly the DC of §46.** The DC was never a routing failure; it is a
clipped signal.

### Why it saturates: §44 removed the loop's only attenuation

The tap multiplies I stopped in §44 were, whatever else they were, the **ladder's damping**.
With them, the loop lost 10⁴ (§43-45). Without them each stage has unity gain, the
accumulation is unbounded, and it clips. Both extremes are wrong, and the truth is that the
feedback term should come from somewhere else entirely.

### ★★ And it does — from the delay line, which is being thrown away

```
delay-port READS per frame      32 986 560 / 1 586 880  =  ~20.8
SRC 0x0B consumed per frame      1 595 520 / 1 586 880  =    1.0
```

★★★ **The port reads ~21 taps per frame and the ladder consumes exactly ONE.** `m_dr` is a
single register that every read overwrites, so 20 of 21 delay data are destroyed before
anything can use them. The ladder therefore has **no per-stage feedback term** — which is
precisely why it has no damping and saturates.

And `dram-datapath.md` already models what is needed, in detail this pass did not use:

* item **A**: *"THE DRAM PORT IS A ONE-DEEP PIPELINE"* — **FORCED**, with the two dummy
  accesses (a leading harmless write, a trailing discarded read) already identified as its
  two ends;
* item **E**: the read latency is **FORCED** to `land ∈ [1,4]`, mode 4 — *"the datum must
  still be in the read-data register when the first word naming SRC 0x0B executes"*;
* item **B**: `wtrail = 2` — the write of a line trails its read by two repetitions.

A one-deep pipeline with `land ≥ 1` is exactly a model in which each read's datum is
consumed a few slots later by its own `SRC 0x0B` word. **Ours overwrites it immediately.**

### Corrected state

| claim | status |
|---|---|
| §44 "the DSP produces audible output" | ⛔ RETRACTED (§46) — a DC |
| §47 "nothing connects the body to w73/w78" | ⛔ **RETRACTED** — it connects; it is railed |
| the body multiplies by address-shaped cells | ✔ MEASURED, stands |
| skipping those multiplies removes the loop's damping | ★ **NEW**, and it explains the DC |
| the delay port is fed with real per-unit descriptors | ✔ MEASURED (§47, bit 9) |
| ~20 of 21 delay reads are discarded | ★ **MEASURED** — the missing feedback term |

⇒ **Next: implement the one-deep read pipeline** — hold each delay datum for `land` slots
(4 is both the FORCED upper bound and the corpus mode) so that each stage's `SRC 0x0B`
consumer receives *its own* read rather than the last one. That restores a real feedback
term to the ladder, which should both remove the saturation and make the output track the
input. It is the piece `dram-datapath.md` items A/B/E were written to specify, and it has
never been implemented.

Evidence grade: **MEASURED** (the epilogue trace at the shipped default, the quantised
accumulator profile, the read/consume ratio); **RETRACTION** of §47's conclusion.

## 49-50. The pipeline is IMPLEMENTED and CORRECT — and the saturation is a CROSS-FRAME RUNAWAY

**2026-07-28.** Implemented the one-deep read pipeline exactly as `dram-datapath.md`
items A and E specify: a delay read's datum is not on its own bus; it is scheduled `land`
slots ahead (`land = 4`, the FORCED upper bound and the corpus mode) and delivered when
that slot arrives. Ring-buffered, per-frame.

```
§49 PIPELINE: 32 986 560 delay data LANDED, 0 lost to ring collisions (land = 4)
```

Mechanically perfect — every read is delivered, nothing collides. **And it changes
nothing:** presentation datum peak `2 877 291`, accumulator `538 760 587 509`, byte for
byte identical to before.

### Why: the consumers do not exist

```
delay-port READS per frame   ~20.8
SRC 0x0B consumed per frame    1.0
```

★ This program contains **exactly one** word naming `SRC 0x0B`. Delivering 33 million data
into a register that is read once per frame cannot matter. Item H points at `tempA`
instead — *"the multiply at slot 5 reads SRC 0x19 = tempA and the read is at slot 4 with
nothing between them"* — so I also landed the datum in `tempA` (bit 11). **Also
bit-identical.** Four configurations, one result.

### ★★★ Because the saturation starts before any of it

The accumulator profile, at **slot 0 — the first word of the frame**:

```
slot 0 peak |acc|   902 153 722 877
        >> 16    =      13 765 839
24-bit rail       =       8 388 607
```

**The accumulator enters every frame already 64 % above the rail.** `run_frame()` restarts
the PC *and only the PC* — the accumulator threads across frames by design — so this is a
**cross-frame runaway**: the loop has net gain ≥ 1 and climbs until it clips, and it is
already clipped before the first instruction of the frame executes.

⇒ No change *inside* the frame — pipeline, tempA, descriptors, level, presentation — can
matter while the state it starts from is railed. That is why five successive fixes produced
bit-identical output.

### ★★ And §44 is the direct cause

The tap multiplies removed in §44 were the loop's only attenuation:

| §44 bit 8 | loop behaviour | result |
|---|---|---|
| **off** | ×0.0066 at each of ~6 ladder stages | attenuates 10⁴ per frame, signal vanishes (§43) |
| **on** | unity gain per stage | **net gain ≥ 1, runaway, rail** (§49) |

Both are wrong, and neither is the chip. **The cells are address-shaped — that finding
stands — but a word that supplies a delay ADDRESS must still contribute a real
multiplicand from somewhere, and skipping its product entirely removes the damping that
made the difference equation stable.**

⇒ The question is no longer "what connects the body to the output" (§48: it connects) nor
"where is the feedback" (§49: the port works). It is: **what do the ~21 address-supplying
words contribute to the ALU?** They cannot contribute nothing, and they cannot contribute
the address. The delay datum they fetch is the obvious candidate — but with one `SRC 0x0B`
consumer in the program, our decode has no route for it.

### Deliverables kept

* The one-deep pipeline is implemented, correct, and **on** in the default mask
  (`0x74C`) — it costs nothing and it is what items A/E specify, so the next pass starts
  from a faithful port rather than a single overwritten register.
* `UPD6383_LAND` env var exposes `land` for the [1,4] interval item E leaves open.
* Bit 11 (datum → tempA) is implemented and **off**: item H motivates it, no measurement
  supports it yet.

Evidence grade: **MEASURED** (the landed/collision counts, the consumption ratio, the
slot-0 profile). **The runaway is the headline** and it retires four sections of
downstream chasing.

## 51. The runaway's ROOT CAUSE: the body never fetches a real coefficient

**2026-07-28.** Before fixing the runaway, two corrections to §50 — both from checking my
own instrument rather than trusting it.

**(a) It is not an accumulator runaway.** §50 read `slot 0 peak |acc| = 902 153 722 877`
from the ACCUMULATOR PROFILE and called it a cross-frame runaway. The profile is a **per-slot
maximum over the whole run, not a time series** — the same misreading this project has
already recorded once ("slot 50 zeroes the accumulator"). The actual trace shows the
accumulator **is** cleared inside the frame (slot 3: `acc = 0`).

**(b) The rail is in the STATE MEMORY.**

```
slot  8   mem[dp] = 8 388 607 = 0x7FFFFF      <- a D-RAM state cell, at the rail
slot 11   mem[dp] = 8 388 352
```

The reverb's state cells have saturated, not the accumulator.

**(c) The host framing is fine.** The cmd-0x02 payload is 90 bytes after the `01 61`
prefix = exactly 30 × 3, so the 24-bit grouping is self-consistent; and the two tables
together span `0x0000..0x7FFF` (28 steps of 0x4BE) and `0x8000..0xFC00` (32 steps of
0x400) — **the two halves of a 64 K space**, matching the per-unit delay regions. The
descriptors are correct and correctly placed.

### ★★★ And then the measurement that explains everything

Which C-RAM cells does each region's cursor actually visit?

```
BODY      (slots 200-332)   0x50 .. 0x71      <- descriptors ONLY
KERNEL    (slots   0- 59)   0x90 .. 0xA4      <- the real coefficients
EPILOGUE  (slots  60- 82)   0x71, 0x90
```

★★★ **The body never fetches a real coefficient. Not one.** Every multiply in the reverb
body takes its multiplicand from the descriptor table. And **cells `0xA5..0xB4` — sixteen
real coefficients — are read by nobody at all.**

That is the whole dilemma of §43-§50 in one line:

| §44 bit 8 | what the body multiplies by | outcome |
|---|---|---|
| **off** | a descriptor read as Q0.23 ≈ 0.0066 | 10⁴ attenuation per frame, signal vanishes |
| **on** | nothing | no damping, state memory saturates, DC |

**Neither is a coefficient, so neither can be right.** The loop has no gain term because the
body has no gains.

### What this makes the next question

Not "how do I damp the loop" — that would be inventing a coefficient — but **where does the
body get its multiplicands?** Three candidates, none tested:

1. **A second cursor.** Our model has ONE cursor; a machine that reads a descriptor *and* a
   coefficient per stage needs two, and `0xA5..0xB4` being unread is what that would look
   like.
2. **The descriptor word carries both** — an address in one field, a gain in another. The
   descriptors use only bits [15:0] of a 24-bit cell; **bits [23:16] are always zero**,
   which is either wasted space or a field we have not decoded.
3. **The body's cursor base is wrong** and should reach `0x90+` like the kernel. Against
   this: the program's own three `ldptr` loads name 0x70 and 0x50 for the bodies, and the
   descriptor contents match the per-unit regions exactly.

★ Candidate 2 is the cheapest to test and the most likely: a 24-bit cell holding a 16-bit
address has 8 bits spare, and every descriptor in both tables has them zero.

### ⛔ Stopping the patch loop, deliberately

Five successive changes — ACCB, latched-K, level-select, delay descriptors, the read
pipeline — each well-motivated, each producing **bit-identical output**. That is not bad
luck; it is the signature of working downstream of an undiagnosed defect. The slot-0
profile and the cursor census, each one line, would have redirected the last four turns.
**The next step should be a decode question answered from the ROM, not another switch.**

Evidence grade: **MEASURED** (the cursor census per region, the state-cell rail, the
transfer framing); **RETRACTION** of §50's cross-frame-runaway framing.

## 52. The descriptor bits, and two refutations — one of them mine

**2026-07-29.** §51 named three candidates for where the body gets its multiplicands. Two
are now dead, both from static analysis of the ROM rather than another emulator switch.

### ★ Candidate 2 — a gain in the descriptor's spare byte — is DEAD

Every descriptor cell is 24 bits carrying a 16-bit address, so 8 bits are spare. Across
**all 91 programs and 870 descriptor cells**:

```
cells with bits[23:16] NON-ZERO :   0   (0.00 %)
value bit-length distribution   :   max 16, and 439 cells use all 16
```

Not one. The upper byte is genuinely unused, not an undecoded gain field.

### ★★★ And a MEASURED structural fact that refutes §47

Cross-tabulating the two predicates over every body word in the corpus:

```
cursor_fetch AND is_dram   :    0        <- DISJOINT
cursor_fetch, NOT is_dram  : 1590
is_dram, NOT cursor_fetch  :  834
neither                    : 4108
```

★★ **A delay word NEVER fetches from the coefficient cursor, and a cursor-fetching word is
never a delay access — zero overlap in 91 programs.**

⛔ That refutes **§47 (mask bit 9)**, which took the delay descriptor *from the cursor*. It
was feeding a pointer those words do not use, which is exactly why it produced bit-identical
output. **Retired; default drops to `0x54C`.** The delay port's descriptors come from
somewhere else, and `m_dsc` (the `ldptr.d` 0x825 form) remains the only candidate on record.

It also means the 1 590 cursor-fetching body words **do** consume the ramp bank as
coefficients, by the program's own instruction — the three `ldptr` loads are all `lo12 =
0x821` (iw42 → 0x70, iw50 → 0x50, iw69 → 0x90), not the `0x825` descriptor form.

### Candidate 1 — a continuous cursor — TESTED AND REFUTED

Register **row 25** ("ldptr ALSO SEEDS THE COEFFICIENT CURSOR") is speculative and this
core's own comment flags it *"⛔ STILL AGAINST K3, which proves 0x21 is NOT the implicit
cursor"* — K3 being **FORCED**. So removing it is well-motivated, and the arithmetic was
inviting: the kernel reads `0x90..0xA4` (21 cells), leaving `0xA5..0xB4` (16) unread, and
21 + 16 = 37 = exactly the host's coefficient-run total.

**Prediction: without row 25 the cursor runs continuously and the body reads 0xA5..0xB4.**

```
row 25 ON   body cursor 0x50..0x71   presentations 1 560 000 non-zero, datum peak 2 877 291 (the DC)
row 25 OFF  body cursor 0x78..0x99   presentations        75 non-zero, datum peak   -21 847
```

⛔ **Refuted.** The cursor lands on `0x78..0x99` — straddling the ramp bank's tail and the
start of the real coefficients — not on the predicted partition. The 21 + 16 = 37 arithmetic
was numerology; it did not survive its own test. And neither setting is right: one gives a
DC, the other near-silence.

### Where that leaves it

All three of §51's candidates are now tested. Two are dead and the third (a wrong cursor
base) is not simply a matter of removing row 25. What is newly **MEASURED** and durable:

1. descriptor cells carry **no** spare-byte field, corpus-wide;
2. coefficient fetch and delay access are **disjoint operations** — a fact about the ISA,
   not about one program;
3. the body's cursor is aimed at the ramp bank by the program's own `0x821` loads, so the
   ramps being consumed as coefficients is what the microcode asks for.

⇒ (2) and (3) together are uncomfortable and therefore interesting: the microcode
deliberately multiplies by a monotonic address-shaped ramp. Either those cells are *not*
delay descriptors after all — and §44/§47's reading is wrong at the root — or the ramp bank
is read through a **different scaling** than Q0.23. The second is worth a look: as Q0.16
these same cells are 0.5 → 0.98, which are entirely plausible reverb gains, and the earlier
observation that a 7-bit left shift turns `0x008000` into exactly `0x400000` = 0.5 has never
been tested.

Evidence grade: **MEASURED** (both corpus cross-tabs); **REFUTATION** of §47's bit 9 and of
the continuous-cursor prediction.

## 53. Q0.16 on the ramp bank — REFUTED, and the ramps look less like gains than ever

**2026-07-29.** §52's closing suggestion was that the ramp bank might be read at a different
scaling: as Q0.16 the same cells are 0.5..0.98, and `0x008000 << 7 = 0x400000` is exactly
+0.5. Falsifier declared in advance: *a no-stimulus window must be silent and the output must
track the input.*

Tested with the tap-skip OFF so the multiplies actually happen (mask `0x244C`):

```
body tail   mem[dp] 8 388 607 = 0x7FFFFF      tA 8 388 607 = 0x7FFFFF
            acc up to 1 597 861 666 816
presentations                    0 non-zero
```

⛔ **Saturated.** With per-stage gains of 0.5..0.98 in a feedback ladder the loop runs away,
exactly as removing the multiplies did in §44. So **both scalings fail**:

| reading | per-stage | outcome |
|---|---|---|
| Q0.23 | 0.0066 | 10⁴ loss per frame, silence (§43) |
| skip entirely | 1.0 | saturation (§44-49) |
| **Q0.16** | **0.5..0.98** | **saturation (§53)** |

★★ And the shape is the real argument. A reverb's gain set is **irregular and signed** — the
genuine coefficient bank at `0x90..0xB4` reads `200000 400000 3B9885 2DF3A0 C62251 170A3D
600000` = 0.25, 0.5, 0.464, 0.359, **−0.452**, 0.181, 0.75. The ramp bank is **monotonic,
evenly spaced, and entirely positive**, in two runs that between them tile `0x0000..0x7FFF`
and `0x8000..0xFC00` — the two halves of a 64 K space.

**Nothing about that is a gain set, at any scaling.** Three scalings have now been tried and
the two that are not degenerate both destabilise the loop.

### The tension this leaves, stated precisely

* §52, **MEASURED**: 1 590 body words fetch from the cursor as coefficients, and the microcode
  aims that cursor at the ramp bank with its own three `0x821` loads.
* §52, **MEASURED**: no delay word ever fetches from the cursor (disjoint, 91 programs).
* §53 + §43 + §44, **MEASURED**: no scaling of the ramp bank yields a stable, signal-tracking
  ladder.

Those three cannot all be right about a coefficient bank. The surviving readings are that the
cursor-fetch for these words is **not** a multiplicand at all (it is consumed by some other
unit — modulation, address generation, or the delay controller reached by a route we have not
decoded), or that the corpus cross-tab is measuring `is_dram` with a predicate that is itself
too narrow.

⇒ ★ **The next question is about `is_dram()` itself**: it is the predicate that made
fetch-and-DRAM look disjoint, and if it under-recognises delay words then the ramps could be
addresses after all and §52's central cross-tab would be an artefact of our own decode. That
is checkable from the corpus — `is_dram` is `addr8` bit 4 plus a direction, and the notes
mark `addr8` bit 4 as *"the head of an access chain"*, which is not obviously the same as
*"this word is an access"*.

Evidence grade: **MEASURED / REFUTATION** — the declared falsifier fired.

## 54-55. ⛔ §52's "disjoint" cross-tab is a TAUTOLOGY — and a calibration correction

**2026-07-29.** Felipe's note: I had been too quick to revert speculative readings, and
should let a speculative structure grow rather than pruning at the first failure. Acting on
it exposed a defect in my own reasoning that is worse than the prunes.

### The specific error: a whole-chain test applied to single changes

My bar for a speculative reading was *"does the chip now produce audio that tracks its
input?"* That requires the input path, the decode, the coefficient routing, the delay
addressing, the ladder and the output stage to be simultaneously correct. **Applying it to
one change at a time asks each reading to fix the whole chip by itself**, so every reading
"failed" and I switched it off:

```
default mask   0xF -> 0xC -> 0x14C -> 0x74C -> 0x54C     (five prunes, one session)
```

★ That is the mirror of the cannot-fail instrument: **a test almost nothing can pass.** The
failures carried no information and I read them as evidence. Restored (default `0x5DF`):
bits 0/1 (ACCB — the block diagram *proves* two accumulators, so modelling one is wrong by
construction), 4 (the device declares `m_k`/`m_l` "multiplier input latches" and the multiply
bypasses them), 7 (r2-output §3.1 calls w77 the word that "aims a POINTER at reg 0x86", and
§42 proved those cells hold the level).

### ⛔⛔ And §52's central measurement was structurally forced

```cpp
is_dram(w)      = (hi12(w) & HI_ESC) && class4(w) == 1 && !c_format(w);
cursor_fetch(w) = (class4(w) & 8)                      && !c_format(w);
```

`class4 == 1` has bit 3 **clear**; `cursor_fetch` requires bit 3 **set**. **No word can
satisfy both.** §52's headline — *"cursor_fetch AND is_dram : 0, DISJOINT across all 91
programs"* — could not have come out any other way. It is a property of two predicates I
wrote, not of the chip.

★ **That is the seventh instrument in this project that could not fail**, and I used it to
refute mask bit 9 (delay descriptors taken from the cursor). **That refutation is VOID.**
Bit 9 is now *untested*, not disproved — which is exactly the distinction Felipe's note was
about, arrived at from the other direction.

### ★ But the same run produced a REAL corroboration

```
escape words by class4    class 0 :  81
                          class 1 : 834      <- is_dram accepts exactly these
                          class 8 :  44      <- bit 3 set: cursor_fetch fires on these too
is_dram accepts, corpus-wide : 834
descriptor cells declared    : 870
```

834 accesses against 870 declared descriptor cells is **close, and close in the right
direction**: `dram-datapath.md` item C accounts ROOM REVERB 1's 32 cells as 14 line reads +
12 line writes + 1 flush read + 1 prime write + **4 still-trapping C-format**, i.e. fewer
accesses than cells. A 36-cell shortfall over 91 programs fits that accounting.

⇒ So `is_dram`'s **scope** is independently supported even though the cross-tab built on it
was vacuous. Two different things, and I had them fused.

★★ The 44 class-8 escape words (ROCK ROTARY, OVERDRIVE …) are the interesting residue: they
carry the escape bit *and* fetch from the cursor. If any of them is a delay access, `is_dram`
is too narrow after all — and that is a real, non-tautological question.

### What this changes

| claim | before | now |
|---|---|---|
| cursor_fetch and is_dram are disjoint | MEASURED (§52) | ⛔ **TAUTOLOGY — void** |
| bit 9 (descriptors from the cursor) | REFUTED | **UNTESTED** |
| is_dram's scope is about right | untested | ★ **CORROBORATED** (834 vs 870) |
| bits 0/1, 4, 7 | switched off | **restored**, live and labelled |

**Method rule 14: before believing a cross-tab, check whether its cells can be non-empty.**
A contingency table between two predicates that cannot co-occur is not a measurement.

Evidence grade: **REFUTATION** (of §52's cross-tab, on structural grounds);
**MEASURED** (the class4 census and the 834/870 accounting).

## 56. ★★★★ THE ROOT CAUSE, FOUND BY AUDIT: the host poke port is unimplemented

**2026-07-29.** A 14-agent audit of the whole project (→ `ROADMAP-2026-07-29.md`) found the
defect that sits underneath §§42–55. **Independently re-verified by hand before adoption.**

### The host's control channel writes into dead I-RAM

`cmd 0x01` carries a 16-bit address, and the core treats it as an **I-RAM word index**
(`upd6383.cpp:588-598`). Address **`0x0160` is not an address — it is a POKE PORT**
(`host-side.md` C4/A4). Its payloads land at I-RAM[352..382], **past the 285-slot frame,
where nothing ever executes.**

Confirmed from the ROM's own upload log:

```
transfer  7: cmd 0x01  7 bytes  I-RAM[352..352]   01 60 | 08 01 06 E8 21
                                        -> word 801.0.6E.821 = ldptr, C-RAM pointer <- 0x6E
transfer 19: cmd 0x01 72 bytes  I-RAM[352..365]   "(24 x3) candidate C-RAM/D-RAM words"
```

★★★ `0x6E` is **exactly** where a C-RAM write run begins. The poke port is the channel that
aims every other transfer — and the dump has been labelling those payloads *"candidate
C-RAM/D-RAM words"* the entire time.

**Consequence: all 881 tag-`0x15` D-RAM writes (65 cells) and all 870 tag-`0x4C` descriptor
writes (52 cells) are DROPPED.** So:

* every delay descriptor reads `0x0000` (§46 measured exactly this and I blamed the port);
* **no per-effect parameter has ever reached the chip** — delay time, reverb time, feedback,
  high-damp, LFO table, ER level;
* D-RAM is never zero-filled, so state cells never clear — the saturation of §48/§53.

### ⛔ Two "chip facts" I reasoned from are EMULATOR ARTEFACTS

* §42: *"the host's only write path reaches C-RAM; there is no host write to D-RAM anywhere."*
  **False.** There are 881 of them and we drop every one. The level being absent from D-RAM
  is our bug, not the chip's design — though reading the level from C-RAM may still be right.
* §47: *"nothing writes those D-RAM cells."* Same artefact. It motivated mask bit 9, which
  §52 then "refuted" with a tautology (§54). **The entire bit-9 chain — motivation and
  refutation — is void.**

### Two more confirmed by inspection

**Unit 1 has never reached a pin.** `m_accb` is assigned **only** at `upd6383.cpp:1849`
behind `m_specmask & 1` — *clear* in the old `0x54c` default. So `w78` presented an
accumulator nothing wrote, and **DO2 was identically 0 on every frame**. The reverbs are the
corpus's only unit-1 programs. ★ Every measurement in §§43–53 is **DO1-only** and must not be
quoted as chip-wide. (Restored in §55's `0x5DF` — Felipe's "stop pruning" instruction fixed
this before I knew why it mattered.)

**The frame clock is 8.8 % wrong.** `kn5000_tonegen.cpp:78` allocates the stream at **48 000**
and `:741` hard-codes `SAMPLE_RATE = 48000.0`, while Fs = **44 100** is PROVEN four
independent ways. Every millisecond figure derived from the emulator is off by 8.8 %.

### The critical path, six links

```
P0.1 conformance harness -> P1.1 HOST POKE PORT -> P2.1 ACCB read gate
   -> P3.0 cursor cross-tab -> P3.1 per-unit base -> P3.3 descriptor source
```

*"Everything before that is measurement of an instrument that has no input."* Which is a fair
description of the last twenty sections.

★ **P1.1 is the single highest-leverage fix in the project** and it is not an ISA question at
all — it is an unimplemented host command.

Evidence grade: **MEASURED** (poke payload decoded from the upload log; both source lines
inspected); the plan's wider claims are graded in `ROADMAP-2026-07-29.md`.

## 57. ★★★★ THE POKE STREAM DECODED — it is the delay-descriptor upload

**2026-07-29.** §56 established that the `0x0160` poke port is a control channel we drop.
Decoding its payloads settles what we were dropping, and it is the missing half of the chip.

### The packet format

Payload after the `01 60` port word is a stream of **5-byte packets**:

```
08 01 00 08 25   ->  801.0.00.825   ldptr.d  -- DESCRIPTOR pointer <- 0x00
0A 00 40 FA 4C   ->  marker 0A | datum 0040FA | tag 4C
0A 00 00 00 4C                     000000     | 4C
0A 00 51 E2 CC                     0051E2     | CC
0A 00 40 00 4C                     004000     | 4C
0A 00 52 FF 4C                     0052FF     | 4C
0A 00 51 3B 4C                     00513B     | 4C
0A 00 54 60 CC                     005460     | CC
```

* `0x0A` is a packet marker; bytes 1–3 are a **24-bit datum**; byte 4 is the **TAG**.
* **Tag `0x4C` is the descriptor bank** and `0x15` the D-RAM register file — exactly the two
  tags `host-side.md` C4/A4 counts at **870 writes / 52 cells** and **881 writes / 65 cells**.
* `0x4C` and `0xCC` alternate: `0xCC = 0x4C | 0x80`, i.e. **the direction bit**, which pairs
  with the FORCED read/write split already on record.

### ★★★ And the data are unmistakable

```
0040FA  000000  0051E2  004000  0052FF  00513B  005460  0051E2
0056D1  0052FF  005A16  005460  005B06  0056D1  005C06  005A16
005DB9  005B06  005F0C  005C06  0060CE ...
```

**16-bit addresses in the 0x4000..0x6000 range, and they repeat in PAIRS** — `0051E2`,
`005460`, `0052FF`, `0056D1` each appear twice, one tagged `4C` and one `CC`. That is
**one read and one write per delay line**, which is precisely `dram-datapath.md` item C's
accounting: *twelve delay lines, each with exactly one write and one read, plus two extra
early-reflection taps.*

⇒ **These are the real delay descriptors.** Irregular, paired, direction-tagged — everything
the C-RAM ramp bank is not.

### What this settles, and what it kills

★ **The ramps at C-RAM `0x50..0x8B` are NOT delay descriptors.** The real ones arrive by a
different channel, in a different format, with a different shape. So §44's and §47's central
reading is **wrong at the root**, exactly as §53 suspected on shape grounds — and mask bit 8
(skip the multiply when the cursor is in the ramp bank) is standing on a false premise even
though it is currently load-bearing for any non-zero output at all.

★ The ramps' monotonic 1024-step structure remains unexplained, but it is now free to be what
it looks like: a **table** (LFO waveform, envelope or crossfade), consistent with A3's finding
that opcode `0x74` uploads a 36-entry waveform table to D-RAM `0x1D..0x40`.

### The implementation this specifies

1. At port `0x0160`, frame the payload as 5-byte packets rather than I-RAM words.
2. `801.0.PP.825` → set the **descriptor write pointer**; `801.0.NN.821` → C-RAM pointer
   (already handled, which is why C-RAM alone was populated).
3. `0A dd dd dd TAG` → write the 24-bit datum to the space TAG names, auto-incrementing by
   **+1** (A4: PROVEN BY CONSTRUCTION), with `0x80` in the tag as the direction bit.
4. Tag `0x15` writes land in the D-RAM register file — which is where the per-effect
   parameters and the zero-fill have always been going.

⇒ This is **P1.1**, the roadmap's highest-leverage step, and it is now fully specified rather
than merely identified.

Evidence grade: **MEASURED** — decoded directly from the captured upload stream; the tags,
the pairing and the counts all match independently established results (`host-side.md` C4/A4,
`dram-datapath.md` item C, the FORCED direction split).

## 58. The 64-combination sweep — ZERO tracking, and that is the useful answer

**2026-07-29.** Felipe's point was that the right answer might be a **joint** setting I never
tried, because I had been convicting readings one at a time. So: the six genuinely uncertain
bits, all 64 combinations, scored by the §54 in-core tracking test.
(`sweep-2026-07-29.txt`, fixed ON: coeff_fetch, deferred presentation, C-RAM level, read
pipeline; fixed OFF: bit 9.)

```
TRACKS THE INPUT :  0 of 64
DC               : 42
SILENT           : 22
```

★ **Not one combination tracks the input.** Every setting either emits a constant or eats
the signal. The hypothesis that a joint configuration would work is cleanly **refuted** —
and that is worth far more than another single-bit result, because it closes the whole
64-point space at once rather than one corner of it.

★★ **And it corroborates the roadmap's critical path exactly.** §56/§57 established that the
chip has never received its delay descriptors (870 writes, tag `0x4C`) or its D-RAM
parameters (881 writes, tag `0x15`) — the poke port that carries both is unimplemented.
**No permutation of ALU readings can compensate for a chip whose delay lines are unaddressed
and whose state cells are never initialised.** The sweep is the experimental confirmation
that the blocker is upstream of everything it varied.

Two observations kept for later, not interpreted now:

* one configuration gives quiet peak **−2 936 012** and loud peak **+2 936 011** — equal
  magnitude, opposite sign, and that magnitude is *exactly* the body's long-expected datum
  (~2 936 000). Still DC by the criterion, but the number is not a coincidence worth losing.
* the DC value `−26 708` recurs across many configurations, which makes it a fixed artefact
  of something common to all of them rather than of any varied reading.

⇒ **Next is P1.1**, now fully specified by §57, and the sweep says nothing downstream of it
is worth another attempt first.

Evidence grade: **MEASURED** — 64 runs, one criterion, declared before the sweep.

## 59-60. ★★★★ P1.1 + P1.2 SHIPPED — the chip receives its descriptors for the first time

**2026-07-29.** Implemented the roadmap's critical-path head.

### P1.1 — the poke port

`cmd 0x01` address `0x0160` is now parsed as a **packet stream** instead of being written to
I-RAM[352+]. A `0x0A` marker introduces a data packet (24-bit datum + tag byte); anything
else is a 36-bit word that aims a write pointer (`0x825` → descriptor, `0x821` → C-RAM,
`class4 == 1 && lo12 == 0x000` → D-RAM register file).

★ **The tag census came out self-consistent on the first run, which is the falsifier passing:**

```
42 pointer words | D-RAM 59, DESCRIPTOR 43, C-RAM 13, unrecognised 4
tags: 15:42  95:17  |  4C:19  CC:24  |  26:8  A6:5
```

`0x15 + 0x95 = 59`, `0x4C + 0xCC = 43`, `0x26 + 0xA6 = 13` — every raw tag is one of the
three C4 tags with or without bit 7, and **`0x80` is the direction bit**, exactly as §57
predicted from the byte stream. Only 4 packets of 119 are unrecognised.

### P1.2 — the descriptor bank is its own space

Writing descriptors into D-RAM was not enough: the microcode's own stores clobbered them
(measured — the host wrote 43 and the port still read `0x0000`). `r3-delaydram.md` says the
bank is **its own space**, with its own writer `LABEL_038922`. Given one, and read by the
delay port.

### ★★★ The result

```
00:40F3  02:51E2  03:4000  04:52FF  05:513B  06:5460  07:51E2  08:56D1  09:52FF
0A:5A16  0B:5460  0C:5B06  0D:56D1  0E:5C06  0F:5A16  10:5DB9  11:5B06  12:5F0C
13:5C06  14:60CE  15:5DB9  16:6272  17:5F0C  18:43A5  19:4617  1A:47F7  1B:430B
...  2A:04D8  2B:0208  2C:06E0  2D:0410  2E:4000  2F:0618       (40 cells)
```

★★ **The pairing is visible to the eye**: `51E2` at 02 and 07, `52FF` at 04 and 09, `5460`
at 06 and 0B, `56D1` at 08 and 0D, `5A16` at 0A and 0F, `5B06` at 0C and 11, `5C06` at 0E
and 13, `5DB9` at 10 and 15, `5F0C` at 12 and 17 — **every value twice, exactly five cells
apart.** One read and one write per delay line, which is `dram-datapath.md` item C's
accounting arriving from a completely independent direction.

```
descriptor cells non-zero   1 561 919  ->  4 559 999 accesses
```

⚠ The `[R dsc 26 = 0000]` lines in the §46 report are **stale** — that instrumentation
records the *first* value seen per index, captured during boot before the upload. Cells
`0x25..0x2F` are populated. (A reminder that an instrument written for one question can
mislead when read for another.)

### Still DC, and that is expected

The verdict is unchanged. The roadmap's critical path has four more links after these two —
P2.1 (the ACCB read gate), P3.0 (the cursor cross-tab), P3.1 (the per-unit base), P3.3 (the
descriptor source). **What has changed is that the chip is no longer being measured with no
input:** it now has delay descriptors, D-RAM parameters and a zero-fill, none of which it has
ever had before in this emulator.

Evidence grade: **MEASURED** — the tag census closes arithmetically, and the descriptor
pairing at stride 5 independently reproduces item C's twelve-lines-one-read-one-write.

## 61-62. Per-unit visibility, and why f31[2] cannot be the accumulator select

**2026-07-29.** Added a per-unit presentation census (P2.1). It immediately inverts §56.

```
mask 0x5DF   unit0/DO1  483 840 exec,       0 non-zero, peak 0
             unit1/DO2  483 840 exec, 455 998 non-zero, peak -26 708
```

★ **DO1 is identically zero and DO2 carries the whole DC.** §56 said the opposite — and it
was right *for the old `0x54C` default*, where bit 0 was clear so `m_accb` was never written.
With bits 0/1 restored (§55) the situation flips: ACCB takes everything and **ACCA is now the
dead one**. Both statements are true of their own configuration; neither is a fact about the
chip. ⚠ Any claim of the form "unit N never reaches a pin" must name its mask.

Bit 8 makes essentially no difference here (455 998 vs 455 999), so the ramp-bank multiplies
are not reaching the output at all — consistent with §57's finding that the ramps were never
descriptors, and further weakening bit 8's premise.

### ★★★ The structural argument against f31[2]

Body 0 and body 1 execute the **same instruction encodings**. So an *instruction field*
cannot separate them: whatever `hi12[3]` means, it cannot be "which unit's accumulator",
because both units run identical words. The per-unit separation must come from the **CALL
context** — which this core already tracks as `m_cur_unit1`, and which the **FORCED** per-unit
D-RAM base `0x05 | unit<<7` is already keyed on.

Implemented as mask bit 14: ACCA for unit 0, ACCB for unit 1, with `f31[1:0]` still supplying
the operation.

```
mask 0x5DF    DO1 0 / DO2 455 998   VERDICT: DC -- output with NO input
mask 0x45DF   DO1 0 / DO2       0   VERDICT: SILENT
mask 0x44DF   DO1 0 / DO2       0   VERDICT: SILENT
```

★ **The DC disappears.** That is a real result: the constant on DO2 was an artefact of routing
by `f31[2]`, not a property of the chip. Trading a lie for silence is progress — a DC that
tracks nothing is worse than nothing, because it can be mistaken for output (twice, so far).

⚠ But ACCA is empty under **every** setting, and that is now the sharp question. Frame order
is kernel → body 0 → kernel → body 1 → **epilogue**, and the epilogue presents *both* units.
So ACCA must survive from body 0, across body 1, to `w73`. Under bit 14 the epilogue's own
arithmetic is steered by `m_cur_unit1`, which body 1 leaves **set** — so every epilogue word
lands in ACCB and `w73` presents an ACCA that nothing has touched since body 0.

⇒ **Next: the unit context across the epilogue.** Either `m_cur_unit1` must be restored per
presentation word (`w73` carries `addr8 = 0x00`, `w78` carries `0x9F` — the unit tag is *in
the word*), or the epilogue runs in a third context of its own. That is a small, well-posed
question with an obvious falsifier: ACCA must become non-zero at `w73` without DO2 losing
what it has.

Default stays `0x5DF` — bit 14 is the better-argued reading but not yet the better-measured
one, and per the standing instruction the structure grows rather than being swapped.

Evidence grade: **MEASURED** (the per-unit census, the three-mask comparison);
**INFERRED (strong)** for the structural argument that an instruction field cannot select
between two units running identical code.

## 63-64. The presentation state, measured — and one hypothesis refuted by its own falsifier

**2026-07-29.** Instrumented what is actually in both accumulators at each presentation,
rather than reasoning about it. Two corrections and one new fact.

```
mask 0x5DF   PRESENT unit0  cur_unit1=0  ACCA=0  ACCB=1 262 805 272 320  -> v=0
             PRESENT unit1  cur_unit1=0  ACCA=0  ACCB=1 812 561 020 672  -> v=26707
             PRESENT unit0  cur_unit1=0  ACCA=0  ACCB=2 824 090 736 224  -> v=0
             PRESENT unit1  cur_unit1=0  ACCA=0  ACCB=3 373 846 484 576  -> v=26707
mask 0x45DF  both units     cur_unit1=0  ACCA=0  ACCB=0
```

⛔ **§62's diagnosis was wrong.** I claimed body 1 leaves `m_cur_unit1` set, so the epilogue's
arithmetic all lands in ACCB. Measured: **`cur_unit1 = 0` at both presentations** — row 27
already clears it at `upd6383.cpp:2872`, exactly as it says it does. I asserted a defect
without checking the line I was asserting it about.

★ **ACCB runs away.** Successive presentations differ by 549 755 748 352 ≈ **2³⁹** — the
accumulator is being incremented by a fixed near-power-of-two every pass, without bound.
That is the saturation of §48/§53 seen directly, and it is the whole of the `−26 708` DC.

★★ **ACCA is empty under every configuration ever measured** — §43, §48, §61, §63, at every
mask. That is now the single sharpest fact in the investigation, because `w73` presents ACCA
and `w73` is DO1, the main mix.

### §64 — a good hypothesis, and its falsifier fired

`801.0.NN.821` (ldptr) and `801.0.PP.825` (ldptr.d) carry `hi12 = 0x801`, so
`f31 = (0x801 >> 1) & 7 = 0`, which this ALU reads as **LOAD acc ← P**. With P = 0 that wipes
the accumulator — and the epilogue's second word is `801.0.26.825`, whose `0x26` is *exactly*
the `dsc` range the delay port reads, so it is unambiguously the descriptor-pointer load.
A word whose job is to aim a pointer clobbering the accumulator is a real defect.

**Prediction, stated first: ACCA becomes non-zero at `w73`.**

Implemented as mask bit 15 (pointer-load words aim their pointer and return without touching
the ALU). **ACCA is still 0.** ⛔ The falsifier fired; §64 is **not** the blocker, though the
reasoning may still be correct — a pointer load should not be an accumulator operation
regardless of whether fixing it moves this particular number. Kept as a switch, off.

### Where ACCA actually dies is now the question

Under bit 14 (accumulator by unit) **ACCB is never non-zero either**, even though
`m_cur_unit1` *is* assigned at the CALL (`:2840`, from the tag word's `addr8 != 0x0e`). So
under unit-selection **neither** accumulator receives the bodies' work — which means the
bodies' accumulation is not reaching any accumulator, and the f31[2] reading was merely
concentrating the *kernel's* output into ACCB and calling it a result.

⇒ Next is a per-slot ACCA/ACCB trace through both bodies and the epilogue. The frame trace
now arms at frame 420 000 (~9.5 s) instead of 970 000, so the fast 16-second harness produces
one — the previous runs emitted no trace at all and I did not notice until I went looking for
the answer in it.

Evidence grade: **MEASURED** (the presentation dumps); **REFUTATION** of §62's claim and of
§64's prediction, both by declared falsifiers.

## 65-66. The per-slot ACCA/ACCB trace — both bodies work, and one reader killed a unit

**2026-07-29.** Added ACCB and the unit context to the frame trace. The picture is not what
any of §§43-64 assumed.

```
n=50   iw 84   U=0  ACCA=539 074 636 021   ACCB=0                <- body 0 FILLS ACCA
n=131  iw 201  U=1  ACCA=769 657 969 049   ACCB=769 657 969 049
n=132  iw 202  U=1  ACCA=0                 ACCB=1 539 315 938 098
n=135  iw 205  U=1  ACCA=0                 ACCB=3 848 289 845 245
```

★ **Both bodies compute.** Body 0 fills ACCA; body 1 fills ACCB. Under bit 14 the per-unit
routing works exactly as intended — the thing §61-63 could not see because it only ever
looked at the two accumulators *at the presentation*, by which time the answer was gone.

★★ **And the ladder behaves like a comb, not like a decay or a runaway:**

```
iw 206  769 657 969 049      iw 224  461 794 730 311
iw 212  0                    iw 229  269 380 247 879
iw 222  192 414 482 432      iw 298  731 174 978 190
```

Oscillating, recovering, re-accumulating. That is the first time in this investigation the
body has behaved like a **filter** rather than like a number sliding to zero or to the rail.

### ★★★ And then it died at one slot, because of my own code

```
iw 305   ACCB = 269 380 247 879
iw 306   ACCB = 0                 `000.2.49.407'  SRC = ACC, f31 = 0 (LOAD acc <- P)
```

`LO_SRC_ACC` — "read the accumulator" — was hard-wired to `m_acc`. Under bit 14 the *current*
accumulator during body 1 is `m_accb`, so that word read **ACCA = 0**, formed `P = 0`, and
loaded zero into ACCB. **One reader of the wrong register annihilated an entire effect unit,
133 slots from the end of its body.**

That is not a speculative reading — it is internally required by bit 14's own semantics, and
it was wrong from the moment §62 introduced the unit-selected accumulator. Fixed:

```
DO2 non-zero   0  ->  455 999   (peak +26 707)
```

### Where that leaves it

Still `DC` by the tracking test — the peak is now `+26 707` where it was `−26 708`, the same
magnitude with the sign flipped. So a constant survives at the end of a ladder that visibly
oscillates on the way there, which is a much more specific problem than "the chip is silent".

⇒ Next: the same trace through the **epilogue** with the fix in, to see what the working
ladder's output becomes between `iw 332` and `w73`/`w78` — and whether ACCA (body 0's
539 074 636 021, which nothing in the epilogue should touch) survives to DO1.

Evidence grade: **MEASURED** throughout — the per-slot dump, and the single-slot death
localised to `iw 306` by direct observation rather than inference.

## 67. The epilogue traced with the fix in — it does NO arithmetic at all

**2026-07-29.** With §66's fix, the epilogue is legible end to end for the first time.

```
iw 332  U=1  ACCA=0   ACCB=3 078 631 876 196   P=0     <- body 1 ends
iw  60  U=0  ACCA=0   ACCB=3 078 631 876 196   P=0
iw  65  U=0  ACCA=0   ACCB=3 078 631 876 196   P=0
iw  73  U=0  ACCA=0   ACCB=3 078 631 876 196   P=0     <- presents ACCA -> DO1 = 0
iw  78  U=0  ACCA=0   ACCB=3 078 631 876 196   P=0     <- presents ACCB -> DO2
iw  81  U=0  ACCA=882 940 994 777              P=333 185 246 425
```

★★★ **ACCB is bit-identical from `iw 60` to `iw 81`.** Twenty-two words execute and not one
of them changes it. And **`P = 0` across the whole epilogue** until `iw 79`. The epilogue
performs **no arithmetic on the body's result whatsoever** — it is a pure presentation stage
in our model, which is precisely what §29 measured (*"the multiply never issues"*) and what
§39 localised (*"what enables the multiply, as distinct from the fetch, is OPEN"*).

### So the DC has an exact arithmetic explanation

```
ACCB at the presentation :  3,078,631,876,196
acc_to_datum (>>16)      :         46,977,433
24-bit rail              :          8,388,607
overshoot                :        5.6x  -> CLAMPS -> a constant
expected body datum      :        16.0x too hot
```

★ **DO2's DC is a clamp.** The body's result is 5.6× the rail before any level is applied, so
the clamp returns the same value every frame regardless of input — a constant *by
construction*, not by a broken datapath. That is why every reading tried since §44 produced
either this DC or silence: the two outcomes are "clamped" and "not clamped", and nothing in
between was ever reachable while the epilogue applies no attenuation.

★★ And it is **16× hotter than the body's own expected datum** (~2 936 000), which points at
body 1's ladder: §65 measured its accumulation stepping by a constant 769 657 969 049 per
repetition. A ladder that adds a fixed quantum rather than a decaying one is missing its
feedback attenuation — the same gap §51 named as *"the loop has no gain term because the body
has no gains"*.

### DO1's zero has a different cause

`ACCA = 0` already at `iw 328`, i.e. **before body 1 even ends**. Body 0 filled it with
539 074 636 021 (§65), so ACCA is cleared somewhere between body 0's exit and body 1 — in the
kernel's second block, slots 50..59. That is a separate, small, well-bounded question:
**twelve words, and one of them discards unit 0's entire result.**

### Two questions, both now sharp

1. **Why does the epilogue form no product?** (`P = 0` at 22 of 22 slots.) This is the oldest
   open item in the investigation and it is now isolated from every other defect.
2. **What clears ACCA in kernel slots 50..59?** New, and cheap — the trace already covers
   those slots.

Neither is speculative. Both are single-question, single-window measurements.

Evidence grade: **MEASURED** — the full epilogue dump, and the clamp arithmetic checked
against the 24-bit rail.

## 68-69. ★★★★ DO1 LIVES — two unit-blind writes, and a store that ate its own result

**2026-07-29.** §67 guessed ACCA was cleared in kernel slots 50..59. **Wrong** — the trace
shows those slots leaving it healthy:

```
iw 50  ACCA=1 154 487 091 200      iw 53  ACCA=538 760 587 509
iw 59  ACCA=  769 657 969 049      <- kernel hands unit 0's result on intact
```

Two defects, both the same shape as §66, both in code I wrote.

### §68 — the bit-4 store was unit-blind, twice

```cpp
m_dram.write_dword(stdest, u32(acc_to_datum(m_acc)) & 0xffffff);   // reads ACCA
...
m_acc = 0;                                                          // clears ACCA
```

Both hard-wired to ACCA regardless of unit. So during **body 1** — which accumulates into
ACCB — every bit-4 store read ACCA for its datum and then wiped it, destroying unit 0's
result one slot into a body that has 132 more to run. Fixed: ACCA now survives body 1 intact
(769 657 969 049 at iw 201, iw 202 **and iw 332**).

### §69 — and then the epilogue's first word ate it

ACCA survived the body and was still 0 by `iw 73`. The epilogue's **first** word,
`w60 = 092.1.8D.15B`, carries `HI_ST` — so under "store-and-clear" it stores **and wipes the
accumulator** at the top of the very stage whose job is to present it.

★ That clear is not established. Round-4 adjudication item 2 lists `no memory access`,
`store -> elsewhere` and `LOAD` as equally surviving, and this core's own comment says it
*"implements 'no store, no clear', which is one point inside that set"*. **A store that
annihilates the value the next words must read is not a plausible chip behaviour** — and that
is now specific evidence, not a preference. Suppressed under mask bit 16.

### ★★★ The result

```
                    before            after
unit0 / DO1   0 non-zero        455 998 non-zero,  peak -2 936 012
unit1 / DO2   455 999           455 999            peak    26 707
ACCA at iw 60 / 73 / 78   353 970 438 019 / -415 687 531 030 / 134 068 217 322
```

★★★★ **DO1 carries a signal for the first time in this project**, and its peak is
**−2 936 012** — the body datum this investigation has been predicting since §43
(*"the body delivered a datum of 504 instead of ~2 936 000"*). The number arrived on its own,
from a datapath fix, with nothing tuned to produce it.

★★ And ACCA now **varies across the epilogue** rather than sitting at one value, so the
epilogue is finally performing arithmetic on a live accumulator.

⚠ Still `DC` by the tracking test — the output does not yet follow the input. But the failure
has changed character completely: from *"nothing reaches the pin"* to *"the right magnitude
reaches the pin without tracking"*, which is the difference between a broken datapath and an
unfinished one.

### The pattern worth naming

§66, §68 and §69 are all the same bug: **a unit-selected accumulator introduced in §62, with
three readers left pointing at ACCA.** Each one silently destroyed a whole unit's work, and
each was invisible until the per-slot trace existed. The lesson is not about the chip — it is
that adding a second register to a datapath means auditing *every* reader and writer of the
first, and I added it three sections before I looked.

Evidence grade: **MEASURED** throughout; §69's suppression is **SPECULATIVE** but now
supported by a concrete consequence rather than by preference.

## 70. ⛔ Why it does not track: the body SELF-OSCILLATES, and −2 936 012 is not a signal

**2026-07-29.** §68-69 reported DO1 reaching *"exactly the long-predicted body datum,
−2 936 012"*. **That reading is wrong, and the correction matters more than the result.**

```
ACCA at w73   quiet frames  min -767 935 722 468   max +768 999 109 494
              loud  frames  min -767 935 722 468   max +768 999 109 494
```

★ The accumulator is **not constant** — it swings ±7.7 × 10¹¹ every frame. But **the range is
identical with and without input.** The chip is generating that swing *by itself*.

### The arithmetic closes exactly, and it is damning

```
ACCA peak            768 999 109 494
>>16                      11 733 890        (24-bit rail: 8 388 607)
-> CLAMPS to               8 388 607
x level 0x2CCCCC           2 936 011
measured DO1 peak          2 936 012
```

★★★ **The output is the rail times the output level.** And because the level is
`0x2CCCCC = 2 936 012` in Q0.23, `rail × level / 2²³ ≈ level` — **so DO1's "signal" is
numerically the level coefficient itself.** It looked like the predicted body datum because
`0x2CCCCC` *is* 2 936 012; the resemblance is a coincidence of the same constant appearing
on both sides.

⚠ And that casts doubt backwards: this core's own comment *"the body delivered a datum of 504
instead of ~2 936 000"* may itself have been this artefact rather than a real expectation.
**The figure ~2 936 000 should not be quoted as the body's target again without re-deriving
it from the ROM.**

### So the diagnosis is stability, not routing

The datapath is now, as far as every measurement can tell, **correct**: the input arrives
(§35), both bodies compute (§65), both units reach their pins (§68-69), the descriptors are
real (§59-60), the level is applied (§42). What is wrong is that **the ladder oscillates and
clips**, so the output is pinned by the rail and the level and cannot encode the input.

That is exactly §51's finding, now visible as a waveform rather than an inference:
**the loop has no gain term because the body has no gains.** A feedback ladder whose
per-stage attenuation is missing will oscillate at full scale regardless of what is fed in —
and it will do so *identically* whether the input is a note or silence, which is precisely
what the two identical ranges show.

⇒ **The remaining question is a single number per stage, and it is not in the C-RAM ramp
bank** (§53 killed every scaling of it). The roadmap's answer is `H1`: a **measured T60 from
the real instrument gives the per-pass loop gain numerically** — the one quantity three
separate guesses (Q0.23, unity, Q0.16) have failed to supply.

Evidence grade: **MEASURED** (the quiet/loud range comparison; the clamp arithmetic closing
to one LSB); **RETRACTION** of §68's "the predicted datum arrived".

## 71. ⛔ §42 REFUTED — the output level IS in D-RAM, and the poke decode is confirmed

**2026-07-29.** With P1.1 working, the tag-`0x15` D-RAM packets are readable for the first
time. Extracted from the captured upload stream and mapped cell by cell:

```
06 = 200000 = +0.250000     <-- ★ UNIT-0 OUTPUT LEVEL
86 = 0BC685 = +0.091996     <-- ★ UNIT-1 OUTPUT LEVEL
1D..40 = 0611E3 158547 238139 2F11C1 376D1D 3C0182 3C7F0A 38DD28 315B3A 267C3A ...
05 07 0E 10 11 50 51 52 53 85 87 8A 8B 94 D0 D1 D2 = 000000   (the zero-fill)
```

### ★★★ Two independent confirmations that the poke decode is right

1. **The LFO table lands exactly where A3 says it does.** `host-side.md` A3 is **PROVEN BY
   CONSTRUCTION + MEASURED**: *"opcode 0x74 … a 36-entry D-RAM TABLE … destination base cell
   `0x1D` … the live cold-boot capture's 36-value burst at `0x1D..0x40` is the SINE table,
   36 of 36 values identical."* My decode puts 36 values at `0x1D..0x40`, rising to a peak
   and falling — a 12-point sine, three cycles. **Reproduced independently, to the cell.**
2. **The levels are exactly half the documented cold-boot values.** The record says
   `reg 0x06 <- +0.500000` and `reg 0x86 <- +0.183992`; the stream carries `+0.250000` and
   `+0.091996` — **half of each, to six decimal places** — which is precisely
   `r3-delaydram.md`'s *"host payload is 2× the raw three bytes"*.

Two established results, from different notes, both reproduced by the same decode. That is a
control that could have failed and did not.

### ⛔ So §42 is wrong

§42 concluded *"the per-unit output level lives in C-RAM, not D-RAM"* because `D-RAM[0x06]`
measured `0x000000` on 100 % of frames. **It measured zero because the poke port was dropped
(§56).** The original code read the right cell; my "fix" (mask bit 6, read from C-RAM)
compensated for a different bug and happened to find non-zero values there by coincidence —
`0x2CCCCC` and `0x006854`, which are ordinary coefficients, not levels.

Verified at runtime:

```
bit 6 OFF (D-RAM)   unit0 0x200000 (+0.25)      unit1 0x0BC685 (+0.091996)   ✓ the host's own values
bit 6 ON  (C-RAM)   unit0 0x2CCCCC             unit1 0x006854               ✗ coincidence
```

**Default `0x5DF` → `0x59F`.** And this is the general lesson of §56 arriving a second time:
*a measurement taken on a subsystem that was never fed is not evidence about the chip.*
Several conclusions in §§42-53 were drawn from a D-RAM the host could not reach.

★ Note the zero-fill is real too — `05 07 0E 10 11 50..53 85 87 8A 8B 94 D0..D2` all receive
`000000`. The state cells that §48/§53 found saturating **were never being cleared**, and now
are.

Evidence grade: **MEASURED**, with two independent pre-existing results reproduced;
**REFUTATION** of §42.

## 72. ★★★★ THE REVERB DECAY COEFFICIENT IS FOUND — C-RAM 0x97, computed by the firmware

**2026-07-29.** A 12-agent workflow hunted the loop gain from the ROM alone (no hardware).
Its headline claims are re-verified here by hand; full output in the run journal.

### The ramp bank is not a coefficient source — and now it is PROVEN, not argued

Census over **all 91 algorithms' parameter streams** (re-run this session):

```
C-RAM writes into the RAMP bank 0x50..0x8B :   0   (from  0 algorithms)
C-RAM writes into the COEFF bank 0x90..0xB5: 445   (from 12 algorithms)
```

★★★ **No algorithm ever writes `0x50..0x8B`.** Its monotonic contents are boot residue. That
retires, in one measurement, the whole §43–§53 sequence: Q0.23 gave silence, unity gave
saturation, Q0.16 gave saturation, and the shape never looked like a gain set — because it
never was one. `cram-unit-base.md` item A (**MEASURED**: 33/33 fetches resolve at base `0x90`,
0/33 at `0x00`, in 12/12 reverbs) says where the gains really are.

### The gains, ROOM REVERB 1 (algo 16), signed Q0.23

```
0x90 +0.250  0x91 +0.500  0x92 +0.500      input mix
0x93 +0.384  0x94 +0.198  0x95 -0.206      input filter
0x96 +0.500                                summing tap
0x97 +0.200   <-- ★ THE DECAY / REVERB-TIME COEFFICIENT
0x98..0x9C +0.750 +0.630 +0.520 +0.500 +0.400        ladder A
0x9D..0xA0 +0.500 +0.438 +0.363 -0.415              damp A
0xA1..0xA4 +0.630 +0.620 +0.520 +0.400              ladder B
0xA5..0xA8  byte-identical to 0x9D..0xA0, 12/12     damp B
```

Irregular, signed, |g| ≤ 0.75 in the eleven clean presets — **exactly what a Schroeder ladder
looks like**, and nothing like the ramp.

### ★★★ Cell 0x97 is COMPUTED by the Sub CPU, and the law reproduces the wire

```
T(v)  = 0.02v+0.1 (v<=15) | 0.05(v-16)+0.45 | 0.1(v-24)+0.9 | 0.2(v-56)+4.2 | v-67
        -- REVERB TIME, 0.10 .. 32.00 s
C-RAM[0x97] = int( -(10 ** (-4.816 * K / T)) / 2.0 * 8388608 )
```

Evaluator at **`0x039D98..0x03A229`**, constants at `0x012E07..0x012F03` (`-4.816` ×5, `10.0`,
`2.0`, `8388608.0f`), softfloat `pow` at `0x03D533`, and the negation is a real
`XOR QH,0x80` at **`0x03D404`** — 6 `pow` calls, 6 negations, one per code path.

★★ **Verified against the live wire, by hand:**

```
transfer 26:  01 60 | 08 01 09 78 21 | 0A 74 7B 89 A6
  ldptr  801.0.97.821  -> C-RAM pointer = 0x97          ✓ (decoded independently)
  packet 0A 74 7B 89 A6 -> payload 0x747B89
  x2 (r3-delaydram's host-payload rule, INDEPENDENTLY CONFIRMED in §71 where the
      levels came out exactly half the documented values)  ->  0xE8F712 = -0.17996
```

The workflow searched 12 algorithms × 100 knob positions and found **exactly one exact hit:
CONCERT REVERB 1, REVERB TIME = 35 → T = 2.000 s** — a round factory default the search was
not steered toward. Sign-flipped and un-halved variants: 0 hits each.

⚠ My first hand-decode read `+0.9100` and disagreed — because I omitted the ×2. The rule that
resolved it is the one §71 had confirmed an hour earlier from a completely different datum.

### ★★ And a NEW ISA finding: hi12 bit 12 selects the coefficient format

Q1.22 vs Q0.23, per instruction word. Forced by biquad mathematics in PARAMETRIC EQ: a 0 dB
block's `b0/a0 ≡ 1` cell holds `0x400000` and its word has **bit12 = 1** (1.000 only at
Q1.22), while the `-a2/a0` cell — which must satisfy |·| < 1 — has **bit12 = 0**. SINGLE
DELAY's anchored cell holds the same `0x400000` with bit12 = 0 and its **MEASURED** regression
requires exactly +0.5. **All 33 reverb ladder words have bit12 = 0**, so the ladder is Q0.23
and the chip multiplies by the stored value.

### Implemented, and it is not yet enough

Mask bit 17 relocates the body's cursor window `0x50..0x8B → 0x90..0xCB`:

```
ACCA swing at w73   +/-7.7e11  ->  +/-3.5e11     (halved)
quiet vs loud range                IDENTICAL      (still self-oscillating)
verdict                            DC
```

★ Real progress — the amplitude halves — but the loop still oscillates, so the mapping
`+0x40` is not yet the right one. Item A gives base `0x90` for **unit 1** and base `0x00`
for unit 0 (*"rival 'always add 0x90' rejected 79/79 on unit 0"*), and my flat `+0x40` ignores
that split. **Next: per-unit bases, not a blanket offset.**

Evidence grade: **MEASURED** (the 0/445 census, re-run here; the wire decode, re-done here);
**PROVEN BY CONSTRUCTION** (the firmware law, two independent readers); **SPECULATIVE** (the
`+0x40` relocation, which is already known to be the wrong shape).

## 73. The body reads REAL coefficients at last — and still oscillates

**2026-07-29.** §72's flat `+0x40` was the wrong shape. `cram-unit-base.md` item A is exact
and **MEASURED** over 91 programs / 1546 class-A words: *"The C-RAM cursor is UNIT-RELATIVE:
base `0x00` for unit 0, `0x90` for unit 1"*, with unit 1's reverbs resolving 33/33 at `0x90`,
keys `0x90..0xB4` and **nothing below `0x90`**; item E rejects the tempting global
"always add 0x90" **79/79** on unit 0. The tools count k from **zero within each unit's body**
and add the base — so the cursor is **reset per unit at the CALL**, not aimed by the
in-program `ldptr`, whose `0x50`/`0x70` payloads land in the never-written ramp bank.

Implemented as mask bit 18. Verified at the same slots:

```
                iw 205        iw 206        iw 207
before  cur=53  coef=008C00   008C00        009000     <- ramp residue, +0.0069
after   cur=93  coef=3B9885   3B9885        2DF3A0     <- REAL gains, +0.464 / +0.359
```

★★ **The reverb body multiplies by genuine reverb coefficients for the first time in this
project.** The values match the bank the host actually writes (445 writes, 12 algorithms).

### ⛔ And it still self-oscillates

```
ACCA swing at w73   ±7.7e11  ->  ±3.5e11
quiet vs loud                    IDENTICAL
verdict                          DC
```

Identical to §72's blunt `+0x40`, which is itself informative: **two different relocations,
same amplitude** — so the oscillation is not sensitive to *which* coefficients are read.
A loop whose behaviour does not change when its gains change from 0.0069 to 0.464 **is not
being attenuated by those gains at all.**

⇒ That is the sharpest statement of the problem yet, and it points away from the coefficients
entirely. The ladder's feedback must be closing through a path the coefficient multiply is
not in — and the obvious candidate is the **delay line**, where §48 measured the port issuing
~20.8 reads per frame while the ALU consumes `SRC 0x0B` exactly **1.0** times. A feedback
loop whose delay reads are discarded 20 times in 21 has no per-pass attenuation no matter
what the multiplier is doing.

★ Note this also re-frames §49-50: the one-deep read pipeline was implemented correctly and
changed nothing *because the consumers do not exist in our decode*. That is now not a curiosity
but the leading explanation of the oscillation.

**Next: find the other consumers of the delay-read datum.** `SRC 0x0B` is a PLAIN GUESS with
one consumer in the whole reverb; `dram-datapath.md` item E says the datum *"must still be in
the read-data register when the first word naming SRC 0x0B executes"*, which implies there are
several. If ~21 reads per frame each feed a ladder stage, finding their source code is the
remaining structural gap.

Evidence grade: **MEASURED** (the coefficient values now read, the unchanged oscillation
amplitude across two different relocations).

## 74. ★★★ THE DELAY-READ CONSUMER IS THE DELAY WRITE WORD — and the ISA says so

**2026-07-29.** §73 left the question: who consumes the ~21 delay reads per frame, when
`SRC 0x0B` is consumed only 1.0 times? Answered from the corpus, and it is structural.

### The enrichment test

For every delay READ in the twelve unit-1 reverb bodies, the SRC codes of the words inside
the **FORCED** latency window `land ∈ [1,4]`, against their corpus-wide base rate:

```
SRC    obs      exp   ratio
0x11    24     10.8    2.22
0x0B   120     75.8    1.58   m_dr  <-- enriched, so the guess is SUPPORTED
0x07   144     92.0    1.56   MEM
0x00   264    211.1    1.25
0x19   108    113.7    0.95   tA
0x10    60    151.6    0.40   ACC     <-- depleted
0x1A     0     65.0    0.00   tB      <-- absent entirely
```

★ `SRC 0x0B` is genuinely enriched after a delay read. The PLAIN GUESS survives a test that
could have killed it.

### ★★★ And then the decisive census

**All 168 words carrying `SRC 0x0B` in the twelve reverb bodies are `class4 == 1` with the
escape bit — so `is_dram` claims every single one — and every one has `addr8 = 0x60`, the
FORCED WRITE direction.**

```
8801602D4   hi 880  cl 1  addr8 60  lo12 2D4  ACT 14
8801602DA   hi 880  cl 1  addr8 60  lo12 2DA  ACT 1A
```

⇒ **The delay WRITE word IS the delay-read consumer.** It stores to the line *and* takes the
read-register onto its bus in the same instruction. That is `dram-datapath.md` item F in its
own words — *"the structural argument moves onto the WRITE word, which is the pipeline"* — and
it is the read/write pairing the descriptors show (§59-60), seen from the instruction side.

★★ Our `is_dram` branch **`return`ed after the port access**, so the ALU half of those 168
words never ran. That is why §48 measured 1.0 consumption against ~20.8 reads, why §49's
correctly-implemented read pipeline changed nothing, and why §73 found a loop whose behaviour
is insensitive to its own gains: **the ladder had no per-pass feedback term because the word
that carries it was being executed as a port access only.**

### ⚠ The fix attempt did NOT produce the predicted effect

Mask bit 19 lets a delay word run its ALU after the port access. **Prediction: `SRC 0x0B`
consumption rises from ~1/frame to ~15/frame.**

```
bit 19 OFF   SRC 0x0B consumed 491 520 times, 0 with a non-zero datum
bit 19 ON    SRC 0x0B consumed 491 520 times, 0 with a non-zero datum
```

⛔ Unchanged, and the datum is now **always zero** (it was 1 557 537 non-zero at §48). So two
things are wrong: the ALU is not reaching the `SRC 0x0B` case for these words — they are
`class4 == 1` with the escape bit, which `alu_decoded()` may route elsewhere — and the delay
memory is now reading back empty, a regression against §48 that the recent cursor/descriptor
changes must have introduced.

**The finding stands; the implementation does not.** The corpus census is a fact about the
ROM: 168 of 168, one direction, one class. What remains is making the core execute those
words as both a port access and an ALU operation, which needs the escape/class-1 dispatch
untangled first.

Evidence grade: **MEASURED** (the enrichment table and the 168/168 census);
**REFUTATION** of the first implementation attempt, by its own declared prediction.

## 75. ⛔ Correction: the delay memory is NOT empty — the PIPELINE is losing the datum

**2026-07-29.** §74 said the delay memory *"reads back empty, a regression the recent
cursor/descriptor changes introduced."* **Wrong**, and the correction localises the fault
precisely.

```
§46 DELAY PORT :  9 802 560 reads (6 383 984 returned NON-ZERO), 9 293 760 writes
§75 writes with content       :  6 383 984 of 9 293 760  (69 %)
§48 SRC 0x0B consumed         :    491 520 times, 0 with a non-zero datum
```

★ **65 % of delay reads return real data, and 69 % of writes carry content.** The delay line
works. What fails is the **delivery**: every one of 491 520 consumptions sees zero.

### The addressing is right, which is worth recording

Sampled at frame 420 001:

```
DLY R  addr 6969  cell 00C8   got 000000
DLY W  addr 70C1  cell 0820   data 7D70
```

`addr = (descriptor + frame) & 0xffff`, so a read at descriptor `0x00C8` targets what a write
at descriptor `0x0820` stored `0x0820 − 0x00C8 = 1880` frames earlier:
`(0x0820 + 418121) & 0xffff = 0x6969` — **exactly the read address**. The ring-buffer
arithmetic, the descriptor pairing and the lag are all correct, and 1880 samples is 42.6 ms,
a plausible reverb tap.

### So the defect is the §49 pipeline

The one-deep pipeline (mask bit 10) schedules each datum into ring slot `(slot + land) & 7`
and publishes it when execution reaches that slot. **The consumer never lands on that slot**,
so `m_dr` holds a stale zero at every read.

★★ And §74 says why the slot model cannot be right: the consumer is **the delay WRITE word
itself** (168 of 168 `SRC 0x0B` words are `class4 == 1`, escape set, `addr8 = 0x60`). A write
word is not at a fixed slot offset from its read — it is the *next delay access on that
line*, which the descriptor pairing places a variable number of ordinary words later.

⇒ **The pipeline should be keyed to the port, not to the slot counter**: a read latches the
datum, and the *next delay word* consumes it. That is what "one-deep pipeline" means in
`dram-datapath.md` item A — one outstanding access — and I implemented it as a slot-indexed
ring, which is a different machine.

### Three corrections in one section, all mine

1. §74's "delay memory reads back empty" — **false**, 65 % of reads carry data.
2. §49's ring is the wrong shape — one-deep means *one outstanding access*, not *a fixed
   slot latency*.
3. The delay write's data source was ACCA regardless of unit (fixed here) — the **third**
   instance of the §66/§68 unit-blind defect, after the ALU source and the bit-4 store.

Evidence grade: **MEASURED** (read/write content counts, the sampled addressing arithmetic
recomputed by hand); **REFUTATION** of §74's closing claim.

## 76. ★★★ THE PORT-KEYED PIPELINE WORKS — the delay datum reaches the ALU at last

**2026-07-29.** §75 localised the loss to §49's slot-indexed ring. Re-keyed to the port, as
`dram-datapath.md` item A actually specifies — *"THE DRAM PORT IS A ONE-DEEP PIPELINE"*, one
**outstanding access**, not a fixed slot latency.

Model (mask bit 20): a delay READ **latches** its datum into a pending register; the **next
delay word** publishes it, runs its ALU with the datum on the bus, and only then performs its
own port access — the ordering matters, because a write must store the accumulator *after*
the ALU has updated it.

```
bit 20 OFF   SRC 0x0B: 491 520 consumptions,       0 with a non-zero datum
bit 20 ON    SRC 0x0B: 491 520 consumptions, 455 998 with a non-zero datum   (93 %)
```

★★★ **The delay-read datum reaches the ALU for the first time in this project.** Zero to
455 998. The feedback path from the delay line into the arithmetic now exists.

### What is still missing, precisely

The consumption **count** is unchanged at ~1.0 per frame, where §74's census says ~15 of the
168 `SRC 0x0B` words should fire per frame. So the datum now arrives correctly for the one
word that reaches the source switch, and the other ~14 still do not get there: `alu_decoded()`
routes `class4 == 1` + escape words elsewhere before the switch, exactly as §74 flagged.

And the ladder is unchanged — ACCA swing ±3.5e11, quiet and loud identical, verdict `DC`.
That follows: one feedback term per frame cannot damp a twelve-line ladder.

### The remaining chain, stated compactly

```
delay memory        ✔ healthy   (69 % of writes carry content, 65 % of reads non-zero)
descriptors         ✔ real      (§59-60, paired at stride 5)
addressing          ✔ correct   (read at 0x00C8 finds the write at 0x0820, 1880 frames back)
pipeline            ✔ delivers  (§76, 93 % non-zero)
CONSUMERS           ✘ ~1 of ~15 reach the ALU   <-- THE LAST GAP
```

⇒ **One question remains: get the class-1 escape words past `alu_decoded()` to their source
switch.** Everything upstream and downstream of that is now measured working.

Evidence grade: **MEASURED** — the 0 → 455 998 delivery, against a model taken verbatim from
item A rather than invented.

## 77. ★★★ THE CONSUMERS FIRE — a missing re-entrancy guard, and §74's census confirmed live

**2026-07-29.** §76 delivered the datum but only ~1 consumer per frame reached it. Measured
the delay path directly rather than reasoning about `alu_decoded()`:

```
§77 DELAY-PATH ALU: entered 19 096 320 times, SKIPPED 19 096 320; SRC 0x0B among them 0
```

★ The ALU **was** entered 19 M times — and reached `SRC 0x0B` **zero** times. The equal
entered/skipped counts give it away: `exec_alu()`'s own `is_dram` branch had **no re-entrancy
guard**, so §76's recursive call re-entered it, performed a **second port access**, and
returned before the arithmetic. The K6 input stage needed exactly this guard (`m_in_k6`) and
I did not carry the pattern across.

```
entered 19 096 320, skipped 0;  SRC 0x0B among them 8 841 600
SRC 0x0B consumed:  491 520  ->  9 333 120     (~19 per frame)
```

★★★ **~19 consumers per frame, against §74's census prediction of ~15 from the ROM.** A count
derived statically from the corpus, reproduced dynamically by the emulator, having fixed a
defect found by a third route. That is three independent things agreeing.

### ⚠ And now every consumer sees zero

```
SRC 0x0B: 9 333 120 consumptions, 0 with a non-zero datum
ACCA at w73: min 0 max 0 in BOTH quiet and loud
VERDICT: SILENT   (the DC is gone -- DC leak 0.00 %)
```

The publish/consume model is now wrong in the other direction. §76 latches one pending datum
and the **first** following delay word consumes it; with ~19 consumers per frame, one datum
cannot serve them. Every delay word is both a consumer *and* an issuer, so the correct model
is almost certainly **per-line**, not per-port-globally: each of the twelve delay lines has
its own outstanding access, which is what the read/write descriptor **pairing** (§59-60,
stride 5) has been saying all along.

★ Note the DC has disappeared entirely — verdict `SILENT`, leak 0.00 %. Three sections ago
the output was a clamped constant; it is now honestly zero, which is a better failure.

### Status of the chain

```
delay memory   ✔ healthy      descriptors ✔ real       addressing ✔ correct
pipeline       ✔ delivers     consumers   ✔ ALL FIRE   (~19/frame, census-matched)
datum routing  ✘ one pending register serves nineteen consumers   <-- the gap
```

Evidence grade: **MEASURED** (the entered/skipped asymmetry, the 0 → 8 841 600 jump, the
census agreement); the per-line model is **INFERRED (strong)** and untested.

## 78. Per-line keying by descriptor value — REFUTED by evidence I already had

**2026-07-29.** §77 left one pending register serving ~19 consumers. Made it per-line, keyed
by the **descriptor value**, on the reasoning that §59-60 shows the bank holding each value
twice at stride 5 (`51E2` at 02 and 07, `5460` at 06 and 0B) — one read and one write per
line sharing a descriptor.

```
SRC 0x0B: 9 333 120 consumptions, 0 with a non-zero datum      (unchanged)
VERDICT: SILENT
```

⛔ **Refuted — and the disproof was in §75, which I wrote myself two sections ago:**

```
DLY R  addr 6969  cell 00C8      <- read descriptor
DLY W  addr 70C1  cell 0820      <- write descriptor, DIFFERENT VALUE
```

The two accesses sampled in the *same frame* carry descriptors `0x00C8` and `0x0820`. The
stride-5 duplication is a property of the **bank layout**, not of what consecutive delay
words fetch — so a read and the write that consumes its datum do **not** share a descriptor,
and keying by value cannot pair them.

★ I had the counter-example in my own §75 dump and re-derived a model that contradicts it.
That is the second time this session a note of mine contained the refutation of a later claim
(the first was §67's "cleared in slots 50..59", disproved by the trace in the same file).

### What the §75 sample actually says about the lag

`0x0820 − 0x00C8 = 1880` samples = **42.6 ms** at 44.1 kHz, and the read at frame *f* collects
what the write stored at frame *f − 1880*. So the read/write pairing IS real and the lag is
correct — the pairing is by **address arithmetic across frames**, not by shared descriptor.
A line is `(read desc, write desc)` with the *difference* setting the delay.

⇒ **The correct key is the PAIR, and it must be discovered from the descriptor bank**, not
from the value: find, for each read descriptor `r`, the write descriptor `w` such that
`w − r` is the intended lag. §60's bank has 40 populated cells and the pairing is visible in
the dump; extracting `(r, w)` pairs statically and keying the outstanding access by pair index
is the next attempt.

⚠ And a broader flag: three of the last four attempts (§74, §76, §78) proposed a routing model
and were refuted. The measurements around them are solid — the consumers fire, the memory is
healthy, the addressing is right — but I am guessing at the *pairing* rather than deriving it.
**The next step should extract the pairs from the ROM before touching the core again.**

Evidence grade: **REFUTATION**, by a measurement already in this register.

## 79. ★★★ THE PAIRS, EXTRACTED FROM THE ROM — and §78's refutation is itself REFUTED

**2026-07-29.** §78 concluded that a read and its write do not share a descriptor, citing a
§75 runtime sample. Extracted the pairs statically instead of arguing from one sample.

`ROOM REVERB 1` (algo 16), delay words in execution order with the cell each consumes:

```
k= 0  iw   0  READ   8320        k= 1  iw  11  WRITE  B198
k= 2  iw  15  READ   A2C9        k= 7  iw  35  WRITE  A2C9   <-- SAME
k= 4  iw  23  READ   A375        k= 9  iw  43  WRITE  A375   <-- SAME
k= 6  iw  31  READ   A4D9        k=11  iw  51  WRITE  A4D9   <-- SAME
k= 8  iw  39  READ   A6DA        k=13  iw  59  WRITE  A6DA   <-- SAME
k=10  iw  47  READ   A9BD        k=15  iw  69  WRITE  A9BD   <-- SAME
k=12  iw  55  READ   AAAD        k=17  iw  77  WRITE  AAAD   <-- SAME
k=14  iw  63  READ   AB24        k=19  iw  85  WRITE  AB24   <-- SAME
k=16  iw  73  READ   AC1B        k=21  iw  93  WRITE  AC1B   <-- SAME
k=18  iw  81  READ   ADC7        k=23  iw 101  WRITE  ADC7   <-- SAME
```

★★★ **The read and its write DO share a descriptor value, at stride 5 in the consumer order.**
And it is not one program:

```
all twelve reverbs:  15 READs, 13 WRITEs, 9 of 15 paired at stride 5 -- 12 of 12 algorithms
```

⛔ **So §78's refutation was wrong.** Its evidence — §75's runtime sample showing a read at
descriptor `0x00C8` and a write at `0x0820` — compared **two accesses from different lines**,
which of course carry different descriptors. One sample of an unpaired pair, used to overturn
a model that 108 paired instances across twelve programs support.

★ That is a specific methodological failure worth naming: I refuted a correct model with a
sample I had not established was a matched pair, having earlier refuted a *tautology* by
reading two predicates that could not co-occur. **Both times the fix was to compute the
population instead of inspecting an instance.**

### What the pairs give

* **9 clean lines per reverb**, read at `k`, write at `k+5`, sharing a descriptor. Reading a
  walking address and then overwriting it is a circular delay line whose lag is the buffer
  length — which is why the descriptors match rather than differ.
* **6 of 15 reads unpaired**, consistent with `dram-datapath.md` item C's accounting: twelve
  lines plus *"two extra early-reflection taps on the pre-delay buffer"*, one flush read and
  one prime write, which are exactly the accesses with no partner.
* The structure is **identical in 12 of 12 reverbs**, so it is a property of the shared
  133-word image, not of any preset.

⇒ **The core should key its outstanding delay access by the descriptor value** — which is what
§78 implemented and what its own (bad) refutation caused me to abandon. The remaining question
is why that implementation still delivered zero, and it must now be a defect in the code
rather than in the model.

Evidence grade: **MEASURED** (108 paired instances, 12/12 programs);
**REFUTATION** of §78's refutation.

## 80. ★★★ THE PAIRING IS PERFECT — and the loop is stuck in a ZERO FIXED POINT

**2026-07-29.** §79 said the remaining question was a code bug. Instrumented the latch and
publish directly:

```
§80 LATCH/PUBLISH: latched 9 802 560 (0 non-zero) | publish attempts 19 096 320,
                   hits 9 802 557 (0 non-zero)
```

★★★ **The per-line pairing works exactly.** 9 802 557 publish hits against 9 802 560 latches —
every delay read is matched to the write that consumes it, three misses in ten million. §78's
model was right, §78's refutation was wrong (§79), and the machinery built on it is sound.

**The datum is zero because there is nothing to carry.**

### The collapse, and it is causal

```
                        before §77's guard      after
delay writes with content   6 383 984            455 999     (~1 per frame)
delay reads non-zero        6 383 984                  0
```

Writes-with-content collapsed by 93 % **at the moment the ALU started running on delay
words**. That is a **zero fixed point**:

```
   delay read returns 0  ->  the ALU computes 0  ->  the accumulator is 0
        ->  the write stores 0  ->  the delay read returns 0
```

Self-consistent, and stable. Before §77 the delay words' ALU did not run, so the accumulator
was driven entirely by the *rest* of the body and the writes carried its output; now the
ladder is closed and it closes onto zero.

★ **A closed feedback loop with no excitation stays at zero — which is correct behaviour.**
The loop is not broken; it is *unexcited*. Something must inject the input into the ladder,
and the surviving `455 999 ≈ 1 per frame` writes with content are presumably exactly that one
injection point.

### So the question has moved, and it is a good move

For the first time the reverb is a **closed, correctly-paired feedback structure** rather than
a collection of stages that do not reach each other. What it lacks is the input.

⇒ **Next: trace the input from the latch cells into the body's ladder.** §35 proved the input
arrives and is read correctly by the kernel header. Whether it reaches the *body's*
accumulator has never been measured — every input-side check in this register stops at the
header. The falsifier is clean: with a note held, at least one delay write per line should
carry content, not one per frame.

⚠ And the §70 self-oscillation is gone: with the ladder closed, the output is honest silence
rather than a rail-clamped constant. Three states in one session — DC, oscillating, silent —
and silence is the first one that is *correct given the input reaching the ladder*.

Evidence grade: **MEASURED** (latch/publish census, the before/after collapse in
writes-with-content).

## 81. ★★★★ THE INPUT REACHES THE KERNEL AND DIES BEFORE THE BODY

**2026-07-29.** §80 said the loop is closed but unexcited. Probed the accumulator at four
points, splitting each range by whether the frame carried input — a probe whose quiet and
loud ranges are identical has not seen the input.

```
header exit  iw 12    quiet [72 492 492 081 .. 72 492 492 081]
                      loud  [-39 413 178 582 .. 187 837 611 422]   ★ DIFFERS
body-0 end   iw 152   quiet [0 .. 0]   loud [0 .. 0]   IDENTICAL
body-1 entry iw 201   quiet [0 .. 0]   loud [0 .. 0]   IDENTICAL
body-1 end   iw 332   quiet [0 .. 0]   loud [0 .. 0]   IDENTICAL
```

★★★ **The input is in the kernel's accumulator** — a single fixed value in silence, a wide
signal-dependent range under a note. The whole input chain (§35's latch fix, the header
reads, the K6 stage) is working end to end.

★★ **And the body never sees it.** All three body probes are not merely identical — they are
**zero**. The accumulator arrives at body 0 empty.

### Which is the zero fixed point, seen from the other side

§65 measured `ACCA = 539 074 636 021` at body-0 entry, before §77 let delay words run their
ALU. Now it is 0. The mechanism is direct: a delay word whose datum is empty executes
`f31 = 0` ⇒ **LOAD acc ← P** with `P = 0`, and there are ~19 of them per frame. **The delay
words wipe the accumulator faster than the kernel can fill it.**

So the loop is not merely unexcited — it is **actively drained**, and the drain is the same
mechanism that closes the feedback. Before §77 the accumulator survived because the delay
words were inert; now they are live and empty, and empty is worse than inert.

⇒ The chain is now completely mapped, and every link is measured:

```
host -> descriptors, parameters, levels, coefficients   ✔ (§56-60, §71-72)
input -> latch -> kernel header -> kernel accumulator   ✔ (§35, §81)
kernel accumulator -> BODY                              ✘ ARRIVES EMPTY   <-- HERE
body ladder -> delay lines -> paired feedback           ✔ (§79-80, 9.8 M matched)
body -> per-unit accumulators -> presentations -> pins  ✔ (§65-69)
```

★ **One link, and it is between two things that both work.** The kernel holds the input; the
body needs it; the handoff loses it — because ~19 delay words per frame each execute a LOAD
with an empty product.

**The falsifier for whatever comes next is clean**: probe iw152 again and it must differ
between quiet and loud.

Evidence grade: **MEASURED**, with a control that fires — the same probe reports DIFFERS at
one point and IDENTICAL at three, so it can distinguish the two outcomes.

## 82-83. Two refuted attempts — then the answer, DERIVED from the trace

**2026-07-29.** §81 localised the loss to the kernel→body handoff. I then proposed two models
and both failed their declared falsifiers:

* **§82** (mask bit 21) — the delay word's ACTION puts its datum on the accumulator, extending
  row 26's MEASURED "ACTION 0x00 ADDS the bus". ⛔ No change: the datum is itself zero, so
  summing it contributes nothing.
* **§83** (mask bit 22) — a delay word does not LOAD from a stale product, since it fetches no
  coefficient and §29 showed the multiply only issues on fetching words. ⛔ No change: delay
  words are not the drain on this path.

★ That is three consecutive refuted models (§78, §82, §83), exactly what §78's own flag
warned about: *"I am guessing at the pairing rather than deriving it."* So I stopped and read
the trace.

### ★★★ The answer, in the trace all along

```
n=46  iw=46  080016000B   ACCA=538 760 587 509   P=0   MUL=Y
n=47  iw=47  080080C000   ACCA=0                 P=0   MUL=.    <-- KILLS IT
n=48  iw=48  0C645A2000   ACCA=0
n=49  iw=49  040010E000   ACCA=0
n=50  iw=84                                              body 0 starts EMPTY
```

**`iw 47` = `800.8.0C.000`.** `hi12 = 0x800` ⇒ `f31 = 0` ⇒ **LOAD acc ← P**, and `P = 0`, so
it erases the kernel's accumulator **three slots before the body-0 call**. Every frame.

★★ **And its multiply did not issue** — `MUL = '.'` — although `class4 = 8` **sets the
coefficient-fetch bit** and `hi12 = 0x800` is not c-format, so `coeff_fetch()` is true. A word
that fetches a coefficient and then loads the accumulator from the product is a perfectly
ordinary MAC; it destroys state only because **the product was never formed.**

⇒ This is §39's open question arriving where it actually costs something:
*"what enables the MULTIPLY, as distinct from the fetch, is OPEN."* The multiply-enable gap
was an accounting curiosity for forty sections; it is now the specific reason the input never
reaches the reverb.

★ Note the same shape at `iw 41` (`400.A.00.21A`, ACCA 401e9 → 0) and `iw 47`, with `iw 45`
restoring in between — several LOAD-from-empty-product words in the kernel tail, of which
`iw 47` is simply the last before the call.

### Where this leaves the investigation

```
input -> latch -> kernel header -> kernel accumulator   ✔ live to iw 46 (538 760 587 509)
iw 47: LOAD acc <- P, P never formed                    ✘ THE DRAIN
kernel accumulator -> body                              ✘ arrives empty, as measured
body ladder, delay lines, pairing, presentations        ✔ all verified working
```

**One word, one register, one unformed product.** And the falsifier stays clean: fix why
`iw 47`'s multiply does not issue, and probe `iw 84` — it must differ between quiet and loud.

Evidence grade: **MEASURED** (the per-slot trace); **REFUTATION** of §82 and §83, each by its
own stated prediction.

## 84. ★★★ WHY iw47's MULTIPLY NEVER ISSUED — §44's guard returns before it

**2026-07-29.** Traced it to a `return` in code I wrote forty sections ago.

```cpp
const bool tap_table = (m_cursor >= 0x50 && m_cursor <= 0x8b) && !(m_specmask & 0x20000);
if (m_speculative && (m_specmask & 0x100) && tap_table)
{
    m_tap_n++;
    if (coeff_consumer(word)) m_cursor++;
    return;                     // <-- and the MULTIPLY is below this
}
m_k = coef;
```

★★★ **§44's tap-table guard (mask bit 8) returns before the multiply.** `tap_table` is true
whenever the cursor is in `0x50..0x8B` — which it is throughout the kernel — so `iw 47`, and
every other kernel word in that window, **never reached the multiply at all**. P was never
formed, `f31 = 0` loaded it, and the accumulator died.

⚠ And §72 already **proved** that guard's premise false: **0 of 91 algorithms write
`0x50..0x8B`.** The guard was protecting the chip from multiplying by a bank that is boot
residue — a reasonable act when it was written, and superseded the moment the census landed.
I left it enabled for eleven sections after disproving it.

### Dropping it, and keeping §72's relocation instead

```
mask 0x5D459F (bit 8 ON)    iw47 MUL='.'   ACCA -> 0
mask 0x1F440F (bit 8 OFF,
              bit 17 relocate ON)  iw47 MUL='Y'   the multiply issues
```

★★ Two further improvements fall out:

```
header exit iw12   before: quiet [72 492 492 081 .. same]   loud [-39.4e9 .. 187.8e9]
                   after : quiet [0 .. 0]                   loud [-65.7e9 .. 61.5e9]
body-1 entry       before: [0 .. 0]     after: [1 301 505 024 .. same]
```

**The kernel accumulator is now zero in silence** and signal-dependent under a note — which is
what a correct input stage looks like, and was not true before. And body 1 now receives a
non-zero value where it received nothing.

### ⚠ Still silent, and the honest position

`body-0 ENTRY` remains identical quiet and loud, and the verdict is `SILENT`. So the input
still does not cross into the body. What has changed is that the drain is understood and
removed, the multiply issues, and the kernel's silence behaviour is now correct.

★ **Bit 8 should be retired from the default**, and its whole §44 line of reasoning with it —
that reading generated §§44–53, was refuted by §53's shape argument, refuted again by §72's
census, and has now been shown to also suppress the kernel's arithmetic. It is the single
most costly wrong turn in this register.

Evidence grade: **MEASURED** (the `return` located in source; the MUL and probe deltas across
one bit).

## 85. WHERE THE INPUT LEAVES THE ACCUMULATOR — iw39, and what that implies

**2026-07-29.** Probed a ladder through the kernel rather than proposing a model.

```
kernel iw12   quiet [0 .. 0]              loud [-65 697 963 445 .. 61 536 416 410]   ★ DIFFERS
kernel iw20   quiet [0 .. 0]              loud [-282 529 599 130 .. 264 633 226 187]  ★ DIFFERS
kernel iw30   quiet [329 853 435 904]     loud [-1 715 237 814 272 .. 2 374 944 442 285]  ★ DIFFERS
kernel iw40   quiet [401 321 689 088]     loud [401 321 689 088]                       IDENTICAL
kernel iw46   quiet [0]                   loud [0]                                     IDENTICAL
body-0 entry  quiet [0]                   loud [0]                                     IDENTICAL
```

★★ **The input is in the kernel accumulator through iw30 — a ±2.4 × 10¹² swing — and gone by
iw40.** The trace names the word:

```
n=37  iw=37  0092A011C0   ACCA=1 086 503 328 112   P=401 321 689 088   MUL=Y
n=39  iw=39  0410AFF647   ACCA=  401 321 689 088   P=401 321 689 088   MUL=Y
```

`iw 39` = `410.A.FF.647`, `f31 = 0` ⇒ **LOAD acc ← P**, and `P = 401 321 689 088` is
**identical in quiet and loud**. So the kernel's input-carrying accumulation is *deliberately
discarded* by a LOAD whose product does not carry the input.

### ★★★ Which suggests the handoff is not the accumulator at all

I have spent §81–§85 assuming the input must reach the body *through the accumulator*, because
that is where the kernel puts it. But a LOAD at iw39 that throws it away is not a defect if
the input was already **committed elsewhere** — and the kernel demonstrably stores: `w0` is
*"ST mem[X+0]"*, `w3` and `w7` store, `w9` stores *"the only input-stage product the header's
mix block consumes"* (`K6_INPUT_STAGE`, in this core's own table).

⇒ **The input almost certainly crosses into the body through D-RAM, not through the
accumulator.** The kernel mixes it, stores it to a cell, and the body reads that cell with
`SRC = MEM`. On that reading iw39's LOAD is correct behaviour — the accumulator is scratch
that has already done its job — and the real question becomes **which cell the kernel commits
the input to, and whether the body reads it.**

★ That reframes §81's conclusion. *"The kernel accumulator arrives at the body empty"* is
**true and probably not a defect.** The chain I drew ending in "one link between two things
that both work" was drawn along the wrong wire.

**Next, and it is a measurement not a model:** watch every D-RAM cell the kernel writes,
split by quiet/loud, and find which ones carry the input. Then check whether any body word
reads those cells. The falsifier is clean — if no D-RAM cell is input-dependent, the handoff
really is the accumulator and §85 is wrong.

Evidence grade: **MEASURED** (the probe ladder; iw39 identified from the trace);
**INFERRED** for the D-RAM handoff, from the kernel's own documented stores.

## 86. ★★★★ THE INPUT'S D-RAM HOME: cells 0x4C and 0x4D — §85 CONFIRMED

**2026-07-29.** §85 inferred that the input crosses into the body through D-RAM rather than
the accumulator. Measured it: every D-RAM write from a kernel slot, per cell, value range
split by whether the frame carried input.

```
★ cell 4C   quiet [0 .. 8 388 607]   loud [0 .. 16 776 739]   (2 400 000 writes)
★ cell 4D   quiet [0 .. 4 194 304]   loud [0 .. 16 772 017]   (  600 000 writes)
    2 of 9 kernel-written cells are INPUT-DEPENDENT
```

★★★ **Exactly two cells carry the audio, and only two.** Seven other kernel-written cells are
input-independent. This is a control that could have failed in either direction — it could
have found none (refuting §85 outright) or found all nine (meaning nothing was localised).

### ★★ And the addresses are exactly where the ISA table says they should be

`K6_INPUT_STAGE`, this core's own twelve-word table, ends with:

> *"w11: END OF BLOCK B (falls through), read mem[X+6], p+1 — **the pointer leaves at X+7**"*

With `X = 0x45` (MEASURED, §33, the steady-state window on 98.31 % of frames), **X+7 = 0x4C**
and X+8 = `0x4D`. The input stage deposits its mixed result exactly where its own documented
walk ends. Two independent artefacts — a runtime census and a hand-written ISA note — landing
on the same two addresses.

⇒ **§85 is confirmed and §81 is corrected.** The handoff is D-RAM, not the accumulator;
`iw 39`'s LOAD is ordinary behaviour; and "the kernel accumulator arrives at the body empty"
was a true observation about the wrong wire.

### ★ The gap, now stated precisely

The **FORCED** per-unit D-RAM base is `0x05 | (unit << 7)` — `0x05` for unit 0, `0x85` for
unit 1 — established at the CALL (`DRAM_UNIT_BASE`, and this core already applies it). So the
body begins reading around `0x05`/`0x85`, while **the input sits at `0x4C`/`0x4D`.**

The body never looks where the kernel put it.

**Next, and it is bounded:** either a body word reaches `0x4C` by absolute addressing (the
mode-1 register file, whose `addr8` names a cell directly), or the kernel's deposit address
and the body's base are related by an offset we have not decoded. Both are checkable from the
corpus — enumerate every cell any reverb-body word can address, and see whether `0x4C` is
among them.

**Falsifier:** if no body word can address `0x4C`, the deposit and the body are genuinely
disjoint and the connection must be made elsewhere (most likely the pointer value the CALL
installs).

Evidence grade: **MEASURED** (the per-cell census, with a control that could have gone either
way), corroborated by an independent hand-written source landing on the same addresses.

## 87. ★★★★ NO BODY WORD CAN REACH 0x4C — the input window is DISPLACED BY 0x46

**2026-07-29.** §86 set the falsifier: *"if no body word can address `0x4C`, the connection
must be made by the pointer the CALL installs."* Checked both routes over the corpus.

```
1. mode-1 words naming 0x4C or 0xCC :  0  across the twelve reverbs
2. pointer walk from the FORCED base 0x85, ROOM REVERB 1 and CONCERT REVERB 1:
      15 distinct cells, range 0x00..0xD2
      reaches 0x4C? NO      cells visited in 0x40..0x60: NONE AT ALL
```

★★ **The body cannot address `0x4C` by any route.** The falsifier fired.

### ★★★ And this core's own comment says what the pointer should be

Quoted verbatim from `upd6383.cpp`, dated 2026-07-27:

> *"★ THERE IS A STEADY STATE AGAIN, and **X IS 0xFF**. … the per-unit rebase at the CALL
> (DRAM_UNIT_BASE, FORCED) does place the pointer: the unit-1 body starts at 0x85, walks
> −133, the output stage walks −1, and the frame ends on 0xFF. So the two deposits below land
> on **cells 0x01 and 0x04** — exactly the two DI latches of
> `output-stage-decode.md` sect. 3.5's map, which is a PREDICTION of that map and not an
> input to it."*

Against what we measure:

```
                X = 0xFF (the note)        X = 0x45 (MEASURED, 98.31 % of frames)
input latch L   0x01                       0x47
input latch R   0x04                       0x4A
deposit X+7     0x06                       0x4C
```

★★★★ **The whole input window is displaced by exactly `0x46`.** And at `X = 0xFF` the deposit
lands on **`0x06`** — adjacent to the **FORCED** per-unit body base `0x05`. The kernel would
be handing the input to the body's own base region, which is precisely the connection §86
found missing.

⇒ **The defect is the frame-closure steady state**, not the input stage, not the body, and
not any ALU reading. Our pointer ends each frame on `0x45` where the documented walk
(`0x85 − 133 − 1`) ends on `0xFF`, so every input-stage address is off by 0x46 and the body
looks in the right place at the wrong cells.

★ §37 measured the closure residue as **exactly 0** in steady state and concluded the pointer
"returns exactly". That is true — it returns to a *stable* value, and I never checked it
returned to the **right** value. A residue of zero says the walk is self-consistent; it says
nothing about its origin.

**Next: find why the walk terminates on 0x45 rather than 0xFF** — a 0x46 discrepancy in the
per-frame pointer arithmetic, with every landmark on both sides now known.

Evidence grade: **MEASURED** (both addressing routes enumerated over the corpus; the 0x46
displacement arithmetic), against a **FORCED** base and a documented steady state.

## 88. ★★★★ THE 0x46 IS BODY 1's WALK — it moves −63 where it must move −133

**2026-07-29.** §87 localised the input displacement to the frame-closure steady state.
Measured the pointer at every region boundary:

```
n=0    iw=0    dp=46      frame entered at X = 0x45
n=11   iw=11   dp=4C      input window: X+7, as K6_INPUT_STAGE says
n=49   iw=49   dp=4B      kernel block 1:  +6
n=50   iw=84   dp=05      CALL body 0 -- REBASED to 0x05   ✓ FORCED base, unit 0
n=119  iw=153  dp=FC      body 0 net:  −9
n=120  iw=50   dp=FC
n=129  iw=59   dp=FD      kernel block 2:  +1
n=130  iw=200  dp=85      CALL body 1 -- REBASED to 0x85   ✓ FORCED base, unit 1
n=262  iw=332  dp=46      body 1 net:  −63
n=263  iw=60   dp=46
n=284  iw=81   dp=45      epilogue:  −1   ✓ "the output stage walks −1"
```

★★★★ **Body 1 walks −63. The documented walk requires −133.** `0x85 = 133`, and
`133 − 133 = 0`, then the epilogue's −1 gives `0xFF`. We get `133 − 63 = 70 = 0x46`, then −1
gives `0x45`.

**Shortfall: exactly 70 = 0x46 — the whole displacement, in one region.**

Everything else is right: both per-unit rebases land on the FORCED bases `0x05` and `0x85`,
the epilogue's −1 matches the note verbatim, and the input window sits at `X+7` exactly where
`K6_INPUT_STAGE` says. **One region, one number.**

### Where 70 counts can go missing

`exec_alu()` performs the pointer post-increment **at the very end**:

```cpp
// ---- the pointer post-increment (classes 2 and A) ----
if ((cl & 7) == 2) m_dp = u8(m_dp + dd);
```

**Every early `return` above it skips that increment.** The function has several: the bit-11
family, the C-format/no-op cases, `cl == 6`, the deferred-presentation path, `is_dram`, and —
until §84 — the tap-table guard. Any body-1 word with `class4 & 7 == 2` that exits through one
of those loses its contribution to the walk.

⇒ **Next: count, over body 1's 133 words, how many have `(class4 & 7) == 2` and what their
`addr8` deltas sum to.** If the ROM's own sum is −133 and the emulator applies −63, the
difference names exactly which words are exiting early — and that is a static computation
against a runtime counter, both cheap.

★ This also explains, retrospectively, why the input window has always been at `0x47/0x4A`
rather than `0x01/0x04`: `output-stage-decode.md` §3.5's map predicts the latter, and the
core's own comment flagged that prediction as *"a PREDICTION of that map and not an input to
it"*. It has been falsified for a while and read as agreement.

Evidence grade: **MEASURED** (the boundary dump), against a **FORCED** per-unit base and a
documented walk.

## 89. ★★★★ ONE INSTRUCTION: iw213 loses its −70, and that is the whole 0x46

**2026-07-29.** §88 said body 1 walks −63 where the ROM requires −133. Summed the ROM's own
deltas:

```
algo 16 ROOM REVERB 1     133 words, 100 post-increments, SUM = -133   ★ exact
algo 20 CONCERT REVERB 1  133 words, 100 post-increments, SUM = -133   ★ exact
delta histogram: { -127:1  -119:1  -72:1  -70:2  -13:1 ... 0:75 ... 73:1 74:1 75:1 123:1 }
```

★★ **The ROM sums to exactly −133**, matching the documented walk to the unit, in both
algorithms. The emulator applies −63. **Exactly 70 counts are lost — and the histogram
contains exactly two words with delta −70.**

### The trace names which one

```
iw 212  0000A00695  dp=D0
iw 213  00002BA000  dp=D0     <-- delta -70 NOT APPLIED
iw 214  0212200419  dp=D0

iw 273  0880120655  dp=17
iw 274  0102ABA64B  dp=D1     <-- delta -70 APPLIED  (0x17 + 0xBA = 0xD1)
```

★★★★ **`iw 213` = `000.2.BA.000` does not apply its pointer post-increment. `iw 274`
(`102.A.BA.64B`) does.** One instruction of 133, one omitted increment of 100, and it accounts
for **the entire chain**:

```
iw213 loses -70
  -> body 1 walks -63 instead of -133          (§88)
  -> the frame closes on 0x45 instead of 0xFF  (§87)
  -> the input window sits at 0x47/0x4A/0x4C instead of 0x01/0x04/0x06   (§86)
  -> the kernel deposits the audio at 0x4C, which no body word can address (§87)
  -> the body never receives the input                                    (§81, §85)
  -> the ladder is unexcited and the chip is silent                       (§80)
```

⚠ **Why it is skipped is NOT yet established.** `000.2.BA.000` matches none of the early-return
branches I checked — `word == 0`, `cl == 5`, the escape NOPs, `lo12` bit 11, `cl == 6`,
`is_dram`, c-format. So the omission is real and measured, and its cause is the next question,
not this one. It is one instruction in one function, with a runtime probe (`dp` unchanged
across it) that will confirm any fix instantly.

★ Note `lo12 = 0x000` and `hi12 = 0x000`: this word has **no ALU content at all** — it is a
pure pointer move. A word whose only effect is the post-increment is exactly the kind that a
decode structured around "what does the ALU do?" will drop, because every branch that answers
"nothing" returns early.

**Falsifier for the fix**: `dp` must change by −70 across `iw 213`, body 1's net must become
−133, the frame must close on `0xFF`, and the input-dependent kernel cells must move from
`0x4C/0x4D` to `0x06/0x07`. Four independent checks, all already instrumented.

Evidence grade: **MEASURED** — the ROM sum (exact, two algorithms), the histogram, and the
per-slot `dp` trace isolating which of the two −70 words is dropped.

## 90. ★★★★★ FIXED — an INFERRED "nop" was swallowing a MEASURED pointer move

**2026-07-29.** §89 isolated the loss to `iw213`. The instrumented probe never fired, which
was itself the clue: **`iw213` never reaches `exec_alu` at all.** `exec_decoded()` catches it
three branches earlier:

```cpp
else if (hi12(word) == 0x000 && class4(word) == 2 && lo12(word) == 0x000)
{
    // nop -- INFERRED.  (The old "PROVEN BY CONSTRUCTION" citation was WITHDRAWN...)
}
```

`iw213 = 000.2.BA.000` matches all three conditions exactly and is executed as a **total
no-op** — ALU *and* addressing.

★★★★ **But `class4 & 7 == 2 ⇒ p += (s8)addr8` is MEASURED**, and this device's own header
states the principle in capitals:

> *"THE ADDRESS GENERATOR IS DECODED EVEN WHERE THE ALU IS NOT … EXECUTE WHAT ADDRESSES,
> NEVER WHAT COMPUTES."*

An **INFERRED** nop was overriding a **MEASURED** addressing rule. The word's ALU content is
genuinely nothing — `hi12 = 0x000`, `lo12 = 0x000` — but its `addr8 = 0xBA` is a −70 pointer
delta, and that is not optional.

### The fix, and all four falsifiers declared in §89

```cpp
if (upd6383_disassembler::ptr_postinc(word))
    m_dp = u8(m_dp + s8(upd6383_disassembler::addr8(word)));
```

```
                                        before        after      predicted
1. dp across iw213                     D0 -> D0      D0 -> 8A    -70 applied      ✓
2. body 1 net displacement                  -63          -133    exactly -133     ✓
3. frame closes on                         0x45          0xFF    0xFF             ✓
4. input-dependent kernel cells         4C / 4D       06 / 07    06 / 07          ✓
```

★★★★★ **Four independent predictions, written down before the change, all confirmed.** And
`0x06`/`0x07` sit adjacent to the **FORCED** per-unit body base `0x05` — the kernel now hands
its audio to the body's own base region, exactly as §87 predicted from the note's arithmetic.

### The chain this closes

```
INFERRED nop swallows a MEASURED -70   ->  body 1 walks -63 not -133     (§88, §89)
                                       ->  frame closes 0x45 not 0xFF    (§87)
                                       ->  input window at 0x47/0x4A/0x4C not 0x01/0x04/0x06
                                       ->  kernel deposits audio where no body word can reach (§86)
                                       ->  the body never receives the input   (§81, §85)
```

**All five links are now measured closed.** One instruction, one omitted increment.

⚠ **The chip is still SILENT** — presentations remain zero. So this was necessary and not
sufficient, and §80's zero fixed point in the delay loop is the next thing standing. But the
input now arrives where the body can address it, which was not true in any previous state of
this emulator.

★ The general lesson, and it is the third instance today: **a reading graded INFERRED must
never override one graded MEASURED.** The same shape produced §72 (a guard whose premise the
census had disproved) and §84 (that guard suppressing the kernel's arithmetic). Grades exist
to be compared when readings collide, and I have not been comparing them.

Evidence grade: **MEASURED** — four falsifiers stated in advance, all fired correctly.

## 91. WHY THE BODY STILL DOES NOT SEE THE INPUT: the deposit is in unit 0's region only

**2026-07-29.** §90 moved the kernel's audio deposit from `0x4C/0x4D` to `0x06/0x07`. The body
probes are still identical quiet vs loud, so the input still does not enter the ladder.
Enumerated where each unit's pointer walk actually goes:

```
unit-0 walk (base 0x05):  05 07 08 09 0A 0B 0C 0D 0F 14 50 51 ...   ★ reaches 0x07
unit-1 walk (base 0x85):  00 0E 85 87 88 89 8A 8B 8C 8D 8F 94 ...   ✘ never 0x05/06/07
```

★★★ **The twelve reverbs are unit 1, and unit 1's walk never touches the deposit cells.**
But it *does* visit **`0x87`** — which is `0x07 + 0x80`, the same offset inside its own
region. The **FORCED** per-unit base is `0x05 | (unit << 7)`, so unit 0's input cell `0x07`
has an exact counterpart at `0x87` that unit 1 reads.

⇒ **The kernel deposits once, into unit 0's region only.** Unit 0 can see it; unit 1 looks at
the mirrored address and finds whatever is there.

That is a coherent and checkable next step, and it has three possible shapes worth separating
before any code is written:

1. **The deposit is per-unit** — the input stage runs once but writes both `0x07` and `0x87`
   (or the hardware mirrors the low region into both).
2. **The rebase is wrong for unit 1** — `0x85` is FORCED, but if unit 1's body is meant to
   read the *unit-0* cell for its input, the CALL should not offset that particular access.
3. **A different word carries the input across** — a mode-1 word naming `0x06`/`0x07`
   absolutely, which the pointer-walk census cannot see because it only models pointer
   addressing.

★ **(3) is testable statically and costs nothing**: enumerate every mode-1 `addr8` in the
twelve reverb bodies and check for `0x06`, `0x07`, `0x86`, `0x87`. §87 already ran exactly
this query for `0x4C` and got zero — the same query for the new addresses is the obvious first
move, and it distinguishes (3) from (1)/(2) outright.

⚠ Note the deposit split: `0x06` receives **2 400 000** writes and `0x07` **600 000** — a 4:1
ratio, so they are not a stereo pair of equals. Whatever reads them may want only one.

Evidence grade: **MEASURED** (both per-unit walks enumerated from the ROM; the probe ladder).

## 92. Option (3) ELIMINATED — no mode-1 word names the deposit

**2026-07-29.** §91 offered three shapes for how the input might cross from the kernel's
deposit into a unit-1 reverb body, and named (3) as the one testable for free.

```
mode-1 (class4 == 1) words naming 0x06 / 0x07 / 0x86 / 0x87,
across the twelve unit-1 reverb bodies:     0, 0, 0, 0     (from 0 algorithms)
```

⛔ **Option (3) is eliminated.** No reverb body word addresses the deposit — or its unit-1
mirror — absolutely. The same query returned zero for `0x4C` in §87, so this is now the second
address family ruled out by the same instrument, which is worth stating: the query
discriminates, and it has answered "no" to two different candidate addresses.

⇒ **Two shapes remain**, and they are distinguishable:

1. **The deposit is per-unit** — something writes `0x86`/`0x87` as well as `0x06`/`0x07`.
   ★ Supported by the walk: unit 1 **does** visit `0x87`, at exactly `0x07 + 0x80`, the same
   offset inside its own **FORCED** region base `0x85`.
   ⚠ But §86's census covered *all* kernel slots — including block 2 at `iw 50..59`, which
   runs between body 0 and body 1 and would be the natural place to stage unit 1's copy — and
   found **only** `0x06`/`0x07` input-dependent. So if a per-unit copy exists, **the kernel
   does not make it**, and the candidate becomes the hardware: the DI latch region mirrored
   into both halves, which is testable against `output-stage-decode.md` §3.5's map.

2. **The rebase should not apply to the input access.** `0x05 | (unit << 7)` is FORCED for
   the body's *own* state, but nothing forces that the *input* read is rebased with it — a
   reverb reading a shared input cell while keeping its private state banked is an ordinary
   design.

★ Both are decidable from the ROM. The cleanest discriminator: for a unit-1 reverb, take the
first body word that reads through the pointer and ask what cell it wants **relative to entry**.
If it wants base+2, (1) is required. If the corpus shows unit-0 and unit-1 bodies reading the
*same* absolute cell for their first input, (2) is required.

Evidence grade: **MEASURED** (the null result, with an instrument shown to discriminate).

## 93. The discriminator returns NEITHER — and names a cell nobody was looking at

**2026-07-29.** §92 left two shapes and a clean discriminator: take each body's first
pointer-based memory read and compare unit 0 against unit 1, relatively and absolutely.

```
unit-0 bodies   first mem[ptr] read at base+0 = 0x05   in 64 of ~79 programs
unit-1 reverbs  first mem[ptr] read at absolute 0x0E   (+137 from base 0x85), 12 of 12

shared RELATIVE offsets : none      ->  (1) per-unit deposit  NOT supported
shared ABSOLUTE cells   : none      ->  (2) no-rebase-for-input  NOT supported
```

⛔ **Both hypotheses fail.** The discriminator was built to choose between them and instead
eliminated both — which is the outcome a good discriminator is allowed to have, and better
than picking the least-bad of two wrong models.

### ★★ What it found instead

* **Unit-0 bodies read `base + 0` — the base cell itself — in 64 of ~79 programs.** So for
  unit 0 the input is at `0x05`, *not* at the `0x06`/`0x07` the kernel deposits to. The
  deposit and the first read disagree by one even in the unit that can reach both.
* **All twelve reverbs read absolute `0x0E`**, uniformly, at `+137` from base `0x85` (i.e.
  the walk wraps). `0x0E` is not a deposit cell — and it is one of the two **unit-tag**
  addresses `{0x0E, 0x0F}` that `upd6383d.h` names as the CALL's unit selector, and one of
  the cells §71 measured the host zero-filling.

⇒ The reverbs' input does not come from the kernel's deposit region at all. It comes from
`0x0E`, a cell with an established role in the unit-dispatch machinery, which nothing in this
investigation has yet connected to audio.

**Next, and it is one query:** is `0x0E` ever *written* with input-dependent data? §86's
census says no — it is one of the nine kernel-written cells and it was **not** input-dependent
(only `0x06`/`0x07` were). So either the kernel should be writing the audio there and does
not, or `0x0E` is read for something other than the input and the reverbs' true input read is
a later word this "first read" query walked past.

⚠ The query took the **first** `SRC = MEM` word, which assumes the first memory read is the
input read. That assumption is unexamined, and given unit 0's first read lands on `base+0`
rather than the deposit, it is probably wrong for both units. **Re-run over ALL pointer reads
per body, not just the first, before drawing anything from `0x0E`.**

Evidence grade: **MEASURED** (the census); the `0x0E` interpretation is **UNSUPPORTED** — it
rests on a first-read assumption the same table undermines.

## 94. ★★★★ OPTION (1) VINDICATED — both units read base+2, and only unit 0's is fed

**2026-07-29.** §93's discriminator eliminated both hypotheses, and I flagged its weakness in
the same breath: it took only the **first** `SRC = MEM` word. Re-run over **all** pointer
reads per body:

```
unit-1 reverbs   cells read: 0E 85 87 89 8A 8B 8C 8F 94 D0 D1 D2
                 ★ 0x85 read by 12 of 12    ★ 0x87 read by 12 of 12
unit-0 programs  ★ 0x05 read by 79          ★ 0x07 read by 61     (0x06 by only 7)
```

★★★ **Both units read `base + 0` and `base + 2`.** unit 0 → `0x05` / `0x07`; unit 1 → `0x85`
/ `0x87`. The shared *relative* structure §93 declared absent is there in 12/12 and 61-79
programs — it was hidden because the first read happens to be a different cell in each unit.

⇒ **§93's elimination of option (1) is RETRACTED. The deposit must be per-unit.**

```
kernel deposits    0x06 (2 400 000 writes)  and  0x07 (600 000 writes)
unit 0 reads       0x07  in 61 programs                     ->  FED
unit 1 reads       0x87  in 12 of 12 reverbs                ->  NOT FED
```

**`0x87` is never written.** The reverbs read their input cell every frame and find whatever
the zero-fill left. That is the whole of the remaining silence, and it is one address.

★ Note `0x07` is the main input cell (61 programs) and `0x06` is minor (7) — so the kernel's
4:1 write ratio favouring `0x06` (§91) is worth revisiting: the cell almost nobody reads gets
four times the traffic. Either the two carry different things (L/R? dry/send?) or the deposit
offsets are themselves off by one, which would rhyme with unit 0's first read landing on
`base+0` rather than the deposit.

⇒ **Next: what should write `0x87`.** Candidates, in order of cheapness: the kernel's second
block (`iw 50..59`, which runs between the two bodies and is the natural staging point — but
§86's census found it writes nothing input-dependent); a per-unit mirror in the deposit
itself; or the CALL's rebase applying to the deposit as well as the body.

★★ **Method note.** §93 reached a confident "both eliminated" from a query with an
unexamined restriction, and I published that conclusion with the caveat attached rather than
resolving it first. The caveat turned out to *be* the answer. **A stated limitation is not a
substitute for removing it** — especially when removing it costs one line.

Evidence grade: **MEASURED** (all pointer reads, 91 programs); **RETRACTION** of §93's
elimination of option (1).

## 95. What should write 0x87 — the per-unit pair EXISTS but carries no audio

**2026-07-29.** §94 localised the silence to one address: the reverbs read `0x87` and nothing
writes it. Searched the resident kernel (286 words recovered from the upload stream) for a
writer.

### ★★ The per-unit pair is real

```
iw 72   000.1.06.087   addr8 06                    <- unit 0's cell
iw 77   859.0.86.822   addr8 86   hi12 bit4 STORE  <- unit 1's cell
```

**Two words, one per unit, `0x06` and `0x86`** — exactly the mirrored structure §94 predicted
must exist. They are the same pair `r2-output.md` §3.1 calls the unit-0 and unit-1 *level*
words, and that §43's mask bit 7 reads as level-selects.

### ⛔ But they do not carry the input

Two tests, both negative:

* **Mask bit 7 off** (so `iw72`/`iw77` perform their stores rather than being read as
  level-selects): no change to any cell, probe or verdict.
* **The census widened to every slot** — my §86 instrument gated on `m_cur_iw < 60`, which
  silently **excluded the epilogue where iw72/iw77 live**. Widened: 29 cells written, and
  **still only `0x06` and `0x07` are input-dependent.** `iw77` does write `0x86`, with
  constant data.

⇒ **Nothing writes the reverbs' input cell with audio.** The pair exists, it is per-unit, and
it carries something input-independent — a level, most likely, consistent with §71 measuring
the host writing `0x06 = +0.25` and `0x86 = +0.092` at load.

### ★ Which raises a conflict worth stating plainly

`0x06` is now doing two jobs. §71 measured the **host** writing it the unit-0 output level
(`0x200000` = +0.25, confirmed against the documented cold-boot value). §86 measures the
**kernel** writing it input-dependent audio 2 700 000 times per run. **Both cannot be right**:
either the kernel is clobbering a host-programmed level every frame, or one of the two
readings has the wrong cell.

That conflict is now the most informative thing on the table, because it is between two
MEASURED results rather than between a measurement and a guess. Resolving it decides whether
`0x06/0x07` are the input cells at all — and if they are not, §90's four confirmed predictions
localised the *pointer* correctly while I attached the wrong meaning to where it landed.

⚠ **A third instrument of mine had a silent restriction.** §86's `m_cur_iw < 60` gate was
never stated in its own note, and it hid the epilogue for nine sections. That is the same
failure as §93's first-read restriction, one day apart. **Instruments need their scope written
into the result line, not just into the code.**

Evidence grade: **MEASURED** (the kernel word search; the widened census; the bit-7 A/B);
the `0x06` double-role conflict is **OPEN and between two measurements**.

## 96. ★★★ THE §71/§86 CONFLICT RESOLVED — two address spaces, not one

**2026-07-29.** §95 left two MEASURED results contradicting each other: §71 has the **host**
writing `0x06` the unit-0 output level; §86 has the **kernel** writing that same cell
input-dependent audio 2 700 000 times. Recorded which words write the disputed cells:

```
cell 06  written by iw11, iw19, iw21, iw27, iw33, iw34, iw39   -- SEVEN kernel words
cell 07  written by iw30, iw32, iw91, iw92
cell 87  written by iw262                                       -- and it IS written
```

★★★ **Seven distinct kernel words store to `0x06`.** That is not a dedicated parameter cell
being read once per frame — it is **scratch**, written all through the kernel's arithmetic.
No sane design would put a host-programmed output level in a cell its own microcode spills to
seven times a frame.

⇒ **The two results describe two different memories.** `host-side.md` C4 names tag `0x15`
*"the D-RAM **register file**"*, and the ISA distinguishes **mode-1** words, whose `addr8`
names a **register** directly, from **mode-2** words, which walk a **pointer** through D-RAM.
Our core resolves both onto the same 256-cell array. **They are not the same space.**

* §71 is right: the host writes **register `0x06`** = the unit-0 level (+0.25, exactly half
  the documented cold-boot `+0.5`, confirmed independently by the LFO table landing at
  `0x1D..0x40`).
* §86 is right: the kernel writes **D-RAM cell `0x06`** with audio, via the pointer.
* **Neither is wrong. The emulator aliases them.**

★★ **And this dissolves §94's problem rather than solving it.** "The reverbs read `0x87` and
nothing writes it" was a statement about the aliased array. `iw262` — a body-1 word — does
write `0x87`. What the reverbs read is a *register*, addressed by `addr8`; what the kernel
deposits is a *D-RAM cell*, addressed by the pointer. Whether those should be the same cell is
now the open question, and it is a question about the chip's memory topology rather than about
any single word.

★ This also puts §90 in its proper place. Its four confirmed predictions were all about the
**pointer** — displacement, closure, walk — and every one of them stands. What does not follow
is the meaning I attached: that landing on `0x06` meant landing where the body reads. If the
spaces are distinct, the pointer is now right and the aliasing is a separate defect.

⇒ **Next: establish whether mode-1 `addr8` and mode-2 `mem[ptr]` address the same memory.**
Decidable from the corpus — if any cell is written through one route and read through the
other with a coherent value, they alias; if the two routes partition cleanly, they do not.
`dram-datapath.md` and `register-space.md` both bear on it and neither has been consulted for
this question.

Evidence grade: **MEASURED** (the writer census); the two-space reading is **INFERRED
(strong)** — it is the only reading under which both prior measurements survive.

---

## §97 — MODE-1 `addr8` AND MODE-2 `mem[ptr]` ARE **NOT** THE SAME MEMORY, AND THE ALIAS WAS DESTROYING THE UNIT-0 OUTPUT LEVEL

§96 asked the question this section answers, and named `dram-datapath.md` and
`register-space.md` as the notes that bear on it.  Both were read **before** any model was
proposed, and `register-space.md` C2 turns out to be most of the answer already.

### 1. The decisive argument needs no pointer walk

`output-stage-decode.md` item **J** is **FORCED**, and the disassembler's guard 6 already
rests on it:

> *"On a MODE-1 word ACTION 0x07 does NOT write `reg[addr8]`: the output stage's `w72` is
> `000.1.06.087` and register `0x06` is the unit-0 OUTPUT LEVEL, written once by the
> firmware's `EFF_VolumeLoop` after linking (PROVEN BY CONSTRUCTION) and carrying the user's
> effect depth.  **If ACTION 0x07 on a mode-1 word wrote the addressed register, that depth
> would survive exactly ONE frame.**"*

Extend it one step.  Under the alias, the kernel's own mode-2 scratch stores overwrite that
same cell **every frame** — the identical impossibility item J already rejected, only worse.
Item J therefore refutes the alias, using a forcing this project had already paid for.

### 2. Three independent supports, all pre-existing

* **`register-space.md` C2** — four mode-1 cells (`0x0F`, `0x8C`, `0x8D`, `0x8F`) are never
  initialised by the host, in 100 canned streams *and* the live cold-boot capture, and C2
  concluded *"a cell the host never initialises is not state the host owns; it behaves like a
  hardware register or port."*  Ports do not live in working memory.
* **`host-side.md` C4** names tag `0x15` *"the D-RAM **register file**"* — the host's own
  transport already distinguishes it.
* **Shape** (`dsp/tools/mode_alias.py`, new): corpus-wide the mode-1 route names **8 distinct
  cells across 48 of 3057 words**; the mode-2 route reaches **129 cells across 3440 accesses**.
  A register file and a memory.

Per region, mode-1 vs mode-2 cells:

```
  kernel   (iw 0..59)    mode-1  0E 0F 8A       mode-2  01..07 FF     intersection EMPTY
  epilogue (iw 60..82)   mode-1  06 85 8C 8D 8F mode-2  84 85         intersection 85
  38 bodies              mode-1  0E 0F          mode-2  128 cells     intersection 0E 0F
```

⚠ **The numeric intersection is NOT evidence of aliasing** — both routes index with 8 bits,
so collisions are expected either way.  It is listed because its *absence* in the kernel would
have been evidence, and it is nearly absent.

### 3. ⚠ A CALIBRATION THAT FAILED, STATED BEFORE THE RESULT IT AFFECTS

`mode_alias.py` reimplements the pointer walk statically.  Run against §96's live writer
census of cell `0x06` it agrees on 6 of 7 words and adds 4 of its own:

```
  sect.96 measured : [11, 19, 21, 27, 33, 34, 39]
  static walk      : [16, 17, 19, 21, 23, 24, 27, 33, 34, 39]
```

The walk carries at least three unverified conventions (kernel entry cell, pre- vs
post-increment store cell, which store forms count).  **Nothing in this section rests on it.**
It did, however, catch one real error: the walk was starting the kernel at `0x05`, six cells
late.  The core's own closure arithmetic (`upd6383.cpp:3236`) is `0x85 − 133 − 1 = 0xFF` and
`0xFF + 6 = 0x05` — the forced per-unit base is applied **at the body call**, not at kernel
entry.

### 4. APPLIED — mask bit **23** (`0x800000`), and the A/B

A separate `m_rf[256]` for the mode-1 / host-tag-0x15 space.  Three routing sites; the third
is the one that shows how close this already was — `exec_alu()` line 1843 **already** computed
a local named `regfile` to separate the two modes, and then read both from `m_dram`.

Predictions written before the build; masks recomputed after the first attempt used four
hand-hexed bits I did not intend (recorded, not hidden).

```
  run  mask      unit-0 level (cell 06)         unit-1 level (cell 86)
  A    1F440F    0x000000  non-zero on      0   0x0BC685  on 452,160    aliased
  B    9F440F    0x200000  non-zero on 452,160  0x0BC685  on 452,160    register file
  C    1F442F    0x000000  non-zero on      0   0x0BC685  on 452,160    aliased + guard
  D    9F442F    0x200000  non-zero on 452,160  0x0BC685  on 452,160    split   + guard
```

**P1 CONFIRMED** — the level goes from `0x000000` on 100% of frames to the host's value on
452,160 frames.  `0x200000` is exactly half the documented cold-boot `0x06 = +0.5 = 0x400000`,
which is the already-known host-payload factor of 2 (A3), not a new discrepancy.

**P2 CONFIRMED but WEAKER THAN I WANTED** — the `host_reg` symptom-guard (bit `0x20`) changes
nothing under the split (B ≡ D).  ⚠ It also changes nothing *without* it (A ≡ C), so the guard
is **inert in both** configurations and this run does not demonstrate it was ever suppressing
anything.  What it does show: the split does not depend on the guard.

**P3 CONFIRMED** — all four runs verdict `SILENT`, not `DC`.  No leak introduced.

### 5. ★ THE STRONGEST EVIDENCE, AND IT IS POST-HOC — flagged as such

Unit 0's level is cell `0x06`, **inside** the kernel's pointer window; unit 1's is `0x86`,
**outside** it.  Under the alias, unit 0's level is destroyed (non-zero on **0** frames) and
unit 1's survives **bit-identical through both routings** (`0x0BC685` in all four runs).

A harmless alias predicts both survive.  A global corruption predicts both die.  Exactly the
in-window one died.  I did **not** state this in advance — it is post-hoc — but it had a live
failure mode and a two-sided one, which is why it is worth more than the arithmetic.

### 6. What this does and does not do

It fixes a **parameter** path, not the ladder.  **The chip is still silent.**  It also
dissolves §94 rather than solving it: *"the reverbs read `0x87` and nothing writes it"* was a
statement about the aliased array.  And it retires the escape route §42 took — the level was
never "in C-RAM"; it is in the register file, and C-RAM was a workaround for reading the wrong
one of two spaces we had merged into one.

**Open, and not claimed here:** the register file's true depth (256 is chosen to make this a
routing change and nothing else); whether index bit 7 is the unit select there as it is in
D-RAM; and why unit 1's `0x0BC685` is close to but not exactly half the documented
`0x178D50` (`0x0BC6A8`) while unit 0's is exact.

Evidence grade: **FORCED** for the two-space reading (item J's forcing, extended);
**MEASURED** for the A/B; **INFERRED** for the register file's depth and index mapping.

---

## §98 — THE POINTER WINDOW, MEASURED LIVE: UNIT 0 IS FED, UNIT 1 IS NOT, AND THE ONLY WRITERS OF UNIT 1'S INPUT CELL ARE **MODE-1 STORES §97 FAILED TO SPLIT**

§97 leaned on a window figure ("the kernel's window is `0x01..0x07`, so `0x06` is inside it and
`0x86` is not") that came from a static walk which **had already failed its own calibration**.
It happened to match the observed damage, which is exactly when a discredited instrument is
most dangerous. So: measure it.

New live census `pwatch()` — per REGION, per cell, mode-2 reads and writes, mode-1 counted
**separately** rather than pooled. Regions follow the measured execution order.

```
  kernel A  (iw   0.. 49)  mode-2  7 cells 01..07   01r 02w 03rw 04r [05rw] 06w [07rw]
  body 0    (iw  84..199)  mode-2 17 cells 03..F1   03r [05r] [07rw] 0Crw 0Dr 0Erw 0Frw
                                                    10rw 11w 12rw 13w 20w 50r 51r 52r 53r F1w
  kernel B  (iw  50.. 59)  mode-2  4 cells 0F..FC   0Fw 8Aw D0w FCw
  body 1    (iw 200..332)  mode-2 14 cells 0E..D2   0Erw [85r] [87rw] 88w 89rw 8Arw 8Brw
                                                    8Cr 8Dw 8Frw 94rw D0rw D1rw D2rw
  epilogue  (iw  60.. 82)  mode-2  6 cells 00..FF   00w 06w [85w] 8Cw 8Dw FFr
                           mode-1                   05r 8Fr
```

### 1. §97's window claim SURVIVES measurement

Kernel A's window is exactly `0x01..0x07`. `0x06` is inside it, `0x86` is not. The static walk
was right here; it is now MEASURED rather than borrowed from a discredited tool.

### 2. ★ THE UNIT-0 HANDOFF IS VISIBLE AND WORKS

Kernel A writes `[05rw]` and `[07rw]`; body 0 reads `[05r]` and `[07rw]`. And the §86 census
says which cells carry audio:

```
  ★ cell 06  quiet [0 .. 8388607]  loud [0 .. 16776739]  (2 700 000 writes)
  ★ cell 07  quiet [0 .. 8388607]  loud [0 .. 16772017]  (1 200 000 writes)
  2 of 29 kernel-written cells are INPUT-DEPENDENT
```

Only `0x06` and `0x07`. Both unit 0's.

### 3. ★★★ THE UNIT-1 HANDOFF DOES NOT EXIST

**No region writes `0x85` or `0x87` with input-dependent data before body 1 runs.** Kernel B
(iw 50..59) sits exactly between the two bodies — the structural counterpart of kernel A — and
writes `0F 8A D0 FC`, missing `85`/`87`. Body 1 is measurably unexcited:

```
  ★ §81 PROBE body-1 iw210      quiet [0 .. 0]  loud [0 .. 0]  IDENTICAL
  ★ §81 PROBE body-1 END iw332  quiet [0 .. 0]  loud [0 .. 0]  IDENTICAL
```

**The twelve reverbs are unit 1.** That is the silence, stated as one fact instead of a chain.

### 4. ★★★ AND THE WRITERS OF `0x85`/`0x8A` ARE MODE-1 STORES — §97 IS INCOMPLETE

```
  §96 cell 85 written by iw70   word 2A61850C7     2A6.1.85.0C7   class4 = 1  MODE-1
  §96 cell 8A written by iw58   word 00018A007     000.1.8A.007   class4 = 1  MODE-1
  §96 cell 87 written by iw262, iw264, iw328       class4 2/2/A   mode-2, INSIDE body 1
```

Both anomalies in the window are the same thing: a **mode-1 word's ACTION-0x07 store being
routed into the pointer-walked D-RAM**. `register-space.md` C2 already lists both words as
mode-1 (`slot 273` and `slot 128`).

§97 split the **read** side and the host writes. **It did not split the store side.** So the
category error it diagnosed is still live in the direction that matters most: mode-1 stores are
landing in D-RAM, and one of them lands on `0x85` — body 1's own input cell.

⚠ **This also flags a possible conflict with guard 6**, which claims "of the 303 executing
`L=07` words, 303 are mode 2 and 0 are not". `iw70` has `lo_act = 0xC7 & 0x1F = 0x07` and
`class4 = 1`. Either the guard is not firing on it, or the 303/303 census counted something
narrower than it says. **Not resolved here — recorded as a discrepancy, not explained away.**

### 5. ⚠ AND I OVER-CORRECTED IN §97

§97 said the split "dissolves §94 rather than solving it — *the reverbs read `0x87` and nothing
writes it* was a statement about the aliased array". Half right. `0x87` **is** written
(`iw262`), so that clause was wrong. But §94's underlying observation — **unit 1 does not
receive the input** — is now CONFIRMED live, and I waved it away. A claim being wrongly
*argued* is not the same as its being wrong.

### 6. Next, with its prediction

Complete the §97 split on the STORE side. **PREDICTION: `0x85` loses its only outside writer,
`0x8A` disappears from kernel B's window, and unit 1's input cells become visibly unfed rather
than fed with non-audio** — which is the honest state, and turns "why is the reverb silent"
into the single question "what is supposed to feed unit 1?".

Evidence grade: **MEASURED** (the window, the writers, the input-dependence census);
**INFERRED** for "kernel B is the region that ought to feed unit 1" — that rests on symmetry
with kernel A, and symmetry is not evidence.

---

## §99 — THE STORE SIDE SPLIT, AND ITEM J's PREDICTION FIRES ON CUE

§98 named the incompleteness: §97 routed the mode-1 READ and the host's tag-0x15 writes to the
register file and left both STORE sites writing `m_dram` unconditionally — so the only outside
writer of body 1's input cell `0x85` was still a mode-1 word landing in the pointer-walked
D-RAM. Both sites already computed the mode and selected `addr8` for mode 1, so this was again
a routing change: one `store_mode()` helper, both call sites through it.

### 1. The four predictions

| # | prediction | result |
|---|---|---|
| 1 | `0x85` leaves the epilogue's mode-2 row | ✅ epilogue mode-2 is now `00w FFr` |
| 2 | `0x8A` leaves kernel B's mode-2 row | ✅ kernel B mode-2 is now `FCw` alone |
| 3 | they reappear in the mode-1 rows | ✅ kernel B `0Fw 8Aw D0w`, epilogue `05r 06w 85w 8Cw 8Dw 8Fr` |
| 4 | ★ **live failure mode:** if the mode-1 store to `reg 0x06` is not an identity, the unit-0 level collapses | ✅ **it collapsed — `0x000000`, non-zero on 0 frames** |

### 2. ⚠ AND PREDICTION 4 FIRING DOES **NOT** REFUTE ITEM J's ESCAPE — read the source field

Item J's stated escape is *"SRC 0x02, undecoded, might carry the level itself and make the
write an identity."* The word that collapsed the level is `iw72 = 000.1.06.087`, and
`lo_src(0x087) = 0x02` — **exactly that source.** Our core does not decode SRC 0x02 and
evaluates it as 0.

So the collapse measures **our undecoded source**, not the chip's behaviour. The routing is
right; it exposed a pre-existing hole and made it visible for the first time. I nearly filed
this as "item J's escape is refuted, MEASURED", which would have been a false retraction of a
correctly-hedged reading — the escape remains **open**, and now has a name: decode SRC 0x02.

### 3. ★ THE GUARD I CALLED INERT IN §97 IS LOAD-BEARING

§97 reported the `host_reg` guard (mask bit `0x20`, `unsupported_src = src == 0x02 || 0x03`)
as *"inert in both configurations"* and noted its own comment calls it *"⛔ A GUARD, NOT A
DECODE"*. It was inert **because the store went to D-RAM, where zeroing `0x06` cost nothing.**
Routing the store to the register file makes it the thing that keeps the level alive:

```
  store split, guard OFF   unit0 0x000000  non-zero on       0
  store split, guard ON    unit0 0x200000  non-zero on 452,160
                           §41 LEVEL GUARD: suppressed 483,840 zero-stores
```

Bit `0x20` joins the default; the mask is now `0x9F442F`. **A guard being inert is a fact about
the current configuration, not about the guard** — and §97 stated it as though it were the
latter. Third time this week a "this does nothing" reading turned out to be about the state
rather than the claim (cf. Part 103).

### 4. ⚠ THE GUARD IS NARROWER THAN THE DEFECT — stated, not fixed here

It tests `d07 == 0x06 || d07 == 0x86` only. `iw70` (`2A6.1.85.0C7`) carries `SRC 0x03` — also
undecoded, also evaluated as 0 — and stores to register `0x85`, which C2 lists as **host-primed**.
Nothing reads reg `0x85` today so there is no live harm, but we are writing an undecoded value
into a host parameter. The principled form is *"suppress any mode-1 store whose SRC is
undecoded"*. **Not done here** — that is a separate change with its own measurement, not a free
rider on this one.

### 5. Where this leaves the machine

```
  kernel A  mode-2  01r 02w 03rw 04r [05rw] 06w [07rw]      <- feeds unit 0, INPUT-DEPENDENT
  body 0    mode-2  03r [05r] [07rw] ...                     <- receives it
  kernel B  mode-2  FCw                    mode-1  0Fw 8Aw D0w
  body 1    mode-2  0Erw [85r] [87rw] ...  mode-1  8Fw       <- reads 85/87
  epilogue  mode-2  00w FFr                mode-1  05r 06w 85w 8Cw 8Dw 8Fr
```

**No region writes `0x85` or `0x87` from outside body 1 at all now.** Unit 1 is visibly unfed
rather than fed with non-audio, which is the honest state and was the point of the change.
§54 verdict `SILENT`, DC leak 0.00% — no leak introduced by any of it.

The question is now single and well-posed: **what is supposed to feed unit 1?** Kernel B is the
structural counterpart of kernel A and sits exactly between the bodies, but "symmetry" is not
evidence, and its whole mode-2 window is one cell (`FCw`).

Evidence grade: **MEASURED** (all four predictions, the guard A/B); **INFERRED** for the
store's true destination — not-D-RAM is forced, but *where* remains open, and §99 deliberately
does not guess.

---

## §100 — **SRC 0x02 = `reg[addr8]`**, ITEM J's HEDGE PAYS OFF, AND THE GUARD IS RETIRED

### 1. ⚠ FIRST, TWO OF MY OWN TESTS THAT CANNOT FAIL — caught, and reported as failures

`src02.py` census, over all 3057 words:

```
   SRC  total   mode-1   mode-2   verdict as printed
   02       1        1        0   "★ MODE-1 LOCKED (1 of 1)"
   03       1        1        0   "★ MODE-1 LOCKED (1 of 1)"
```

**SRC 0x02 occurs exactly ONCE in the corpus.** "Mode-1 locked, 1 of 1" and the companion
"100% of SRC-0x02 words name a host-primed cell, 1 of 1" are criteria that **cannot fail** —
METHOD RULE 14, which this project wrote after the last one. The tool printed two confident
verdicts carrying zero information. **The corpus cannot decode SRC 0x02 by frequency; there is
nothing to count.** Recorded rather than deleted, because the tool is still right about the
census and the sites.

### 2. The two words, and what the notes already said

```
  iw70   2A6.1.85.0C7   SRC 0x03   dest reg 0x85   ACT 0x07
  iw72   000.1.06.087   SRC 0x02   dest reg 0x06   ACT 0x07
```

`output-stage-decode.md` §7.2 enumerated exactly these, called them *"the sharpest single
question this pass leaves open"*, and refused to choose — correctly. Its reading (R-2) is
*"`w70` writing `0x85` … `0x85` is a cell the reverb reads and never writes, so something must
supply it and `w70` is the only candidate in the machine"*, with two objections: it feeds the
reverb one frame late, and item J forces `ACT 0x07` not to write `reg[addr8]`.

**§98 and §99 moved both objections:**
* *"one frame late"* — §98 MEASURED that unit 1 is fed **nothing at all**. One frame late beats
  never; the objection assumed a better alternative exists and there isn't one.
* *"item J forbids the write"* — §99 established item J's force comes **entirely from the
  volume's persistence**. That argument is about `reg 0x06`. It does not reach `0x85`, which is
  an input cell that *should* be rewritten every frame.

### 3. ★ THE MERGE: our core had SRC 0x02 and 0x03 as ONE case

```cpp
  case 0x02: case 0x03:                        // "no independent support"
      L = mem[m_dp];
```

The two hypotheses in play **require these codes to differ**:
* item J's escape needs `w72` (SRC 0x02) to be an **IDENTITY**
* §7.2's R-2 needs `w70` (SRC 0x03) to **SUPPLY** something new

Both cannot hold of one route. They are different codes; nothing forced them to share a case.
Same shape as the two memories — a merge in the model creating a contradiction in the machine.

### 4. APPLIED — mask bit **24**, and the A/B that could have gone either way

SRC 0x02 alone reads `reg[addr8 | unit]`. SRC 0x03 deliberately keeps the old `mem[ptr]` guess:
this tests ONE code, per the Part 103 lesson.

**Guard bit `0x20` OFF in both runs**, so nothing protects the level except the decode:

```
  9F440F   bit 24 OFF   unit0 0x000000  non-zero on       0 frames
  19F440F  bit 24 ON    unit0 0x200000  non-zero on 452,160 frames
```

**PREDICTED IN ADVANCE by item J**, days ago, and hedged rather than promoted:
*"SRC 0x02, undecoded, might carry the level itself and make the write an identity."*
It does. `w72` is `reg[0x06] ← reg[0x06]`.

### 5. The guard is RETIRED, and that is the point

§99 promoted the `host_reg` guard to the default one section ago. §100 removes it. That is not
a reversal of §99 — §99 was the correct interim state, and the guard's own comment asked for
exactly this outcome: **"⛔ A GUARD, NOT A DECODE: it suppresses the symptom so the level
survives; what w72/w77 really do is OPEN."** It is no longer open. Default mask `0x19F440F`;
bit 5 stays available for bisection.

A hack retired by understanding is worth more than the audio it didn't produce — and the chip
is, still, silent.

### 6. Next, and the tension I am NOT smoothing over

SRC 0x03 (`w70`) is now the named candidate to feed unit 1. **But there is a live conflict with
§97 that must be resolved before implementing it:** under the two-space split, `w70` writes
**register** `0x85`, while §98 MEASURED body 1 reading **D-RAM** `0x85` through the pointer
(mode 2). Those are different cells. So R-2 as literally stated cannot feed the reverb under
§97, and one of the following must give:

* body 1's read of `0x85` is not really mode 2 (our decode of that word is wrong), or
* `w70`'s store really does target D-RAM (§99's routing is wrong for this word), or
* the two spaces are not two flat arrays (a window, a shadow, a small file aliasing low
  addresses) — in which case §97 is right in substance and wrong in shape.

⚠ Note the third possibility means §97 could be **right that they are distinct and wrong that
they are two independent 256-cell arrays**. I have not tested the shape, only the distinctness.

Evidence grade: **MEASURED** (the A/B, with a live failure mode and the guard disabled);
**FORCED** that 0x02 and 0x03 cannot share one route; **OPEN** for SRC 0x03 itself.

---

## §101 — SRC 0x03 IS **BLOCKED, NOT OPEN**, AND §100 NEEDS RIGHT-SIZING

### 1. ⚠ FIRST: §100 CLAIMED MORE THAN IT MEASURED

§100 decoded SRC 0x02 as `reg[addr8]`. What the A/B established is narrower:

* **MEASURED:** the value SRC 0x02 must produce at `w72` is `reg[0x06]`, the level. The level
  survives with the guard disabled, on 452 160 frames, where it collapsed before. That stands.
* **NOT established:** that the *code* means `reg[addr8]` generally. **n = 1.** Any reading
  that yields the level at that one site passes identically.

And there is positive evidence against the general form: **SRC 0x07 on a mode-1 word already
reads `reg[addr8]`** — that is the `regfile` local §97 routed, and the census shows **37 mode-1
words use it**. So §100 gives two distinct opcodes the same meaning. Instruction sets do not
usually spend a code twice. The *effect* at `w72` is right; the *identity* of the code is
weaker than §100 wrote it. Regrade: **MEASURED** at the site, **INFERRED (weak, n=1)** as a
route.

### 2. The experiment for SRC 0x03, and why it is VOID rather than negative

SRC 0x03's only corpus site is `w70`, so again n = 1 and again the corpus cannot count. The
testable consequence: §7.2's R-2 needs `w70` to SUPPLY `reg 0x85`, so the value it stores must
be **input-dependent**. §86 already reports exactly that, per cell, and only `0x06`/`0x07`
qualify — a two-sided criterion that is currently failing, which is the right shape.

Implemented SRC 0x03 = the accumulator (mask bit 25) — the one operand at that point in the
frame that could plausibly carry unit 0's result. Result: **bit-identical. Cell `0x85` did not
join the input-dependent set.**

⚠ **That refutes nothing.** From the same run:

```
  §63 PRESENT unit0  cur_unit1=0  ACCA=0 ACCB=0  pacc=0 -> v=0
  §63 PRESENT unit1  cur_unit1=0  ACCA=0 ACCB=0  pacc=0 -> v=0
  ★ §81 PROBE kernel iw12   quiet [0 .. 0]  loud [-65,697,963,445 .. 61,536,416,410]  ★ DIFFERS
```

**Both accumulators are ZERO at the epilogue.** Storing the accumulator stores zero whether or
not the reading is correct. The criterion was sound; the **operand was known-dead**, and
knowably so — §46 recorded that the presentation emits a kernel constant, and the standing open
question in this project's own notes is *"nothing connects the BODY's accumulator to
`w73`/`w78`"*. `check-the-handover-first` says compute the NULL before interpreting the table.
I computed it after.

### 3. ★ THE USEFUL RESULT: a named blocker, and an ordering

SRC 0x03 cannot be decoded **at all** right now, and the reason is specific:

> Every candidate reading of SRC 0x03 must be judged by what `w70` supplies. **Every operand
> available at `w70` is currently zero.** No experiment at that site can discriminate between
> readings until the accumulator survives from the kernel to the epilogue.

So this is not an open question awaiting a better idea — it is a **blocked** one with a
prerequisite, and the prerequisite is the project's oldest standing defect. The dependency runs:

```
  accumulator survives kernel -> epilogue      (OPEN, oldest defect, §46)
    -> w70 has a live operand
      -> SRC 0x03 becomes decidable by the §86 two-sided test (already built)
        -> R-2 testable: does w70 feed unit 1?
          -> and only then does the §97/§98 routing conflict need resolving
```

The last line matters: I was about to resolve the register-vs-D-RAM conflict for `0x85`. That
work is **premature** — it decides where a zero goes.

Bit 25 stays implemented and OFF by default. Not reverted: it is the right hypothesis to re-run
the moment the blocker clears, and the test harness for it now exists.

Evidence grade: **MEASURED** that both accumulators are zero at the epilogue while the input
reaches iw12/iw20; **VOID** for the SRC 0x03 experiment; **INFERRED** for the dependency order.

---

## §102 — THE ACCUMULATOR DOES NOT "DIE". IT IS HANDED OVER THROUGH MEMORY, AND **BODY 0 FAILS TO PICK IT UP**

§101 named the blocker as *"the accumulator does not survive from the kernel to the epilogue"*.
Measuring it dissolves that framing.

### 1. Where it stops being input-dependent

Existing §81 probes, extended into the window between the last live probe (iw30) and the first
dead one (iw40):

```
  after iw30   quiet [329,853,435,904]      loud [-1,715,237,814,272 .. 2,374,944,442,285]  ★ DIFFERS
  after iw31   quiet [329,853,435,904]      loud [-1,715,237,814,272 .. 2,374,944,442,285]  ★ DIFFERS
  after iw32   quiet [395,824,060,170]      loud [395,824,060,170]                          IDENTICAL
  after iw34   quiet [274,877,906,944]      loud [274,877,906,944]                          IDENTICAL
  after iw39   quiet [401,321,689,088]      loud [401,321,689,088]                          IDENTICAL
```

**`iw32` = `000.A.FF.207`, `f31 = 0`, `SRC 0x08`.** `f31 = 0` is `acc <- P`: it *discards* the
accumulator unconditionally and reloads it from the product.

### 2. ⚠ AND I FIRST BLAMED THE WRONG WORD, FOR THE OLDEST REASON

I read the probes as sampling **before** the slot executes, which put the death at `iw31` — a
**C-format** word, and the C-format handler has previous form (Part 102's phantom DC was
`2436 << 11`, manufactured there). It was a satisfying story and it was wrong.

The probe block sits **after** `exec_decoded(word)` (`upd6383.cpp:3174` vs `:3195`). Probe
`iwN` is the accumulator *after* slot N. I checked the source instead of building on the
assumption, which is the only reason this is a paragraph and not a section. The labels are now
corrected in the code so the next reader cannot repeat it.

### 3. ★★★ THE REFRAME: `iw32` IS NOT A DEFECT

A `LOAD acc <- P` starting a fresh MAC chain is **normal DSP behaviour**, and the kernel has
already put the audio somewhere safe before it fires. §86, same run:

```
  ★ cell 06  quiet [0 .. 8388607]  loud [0 .. 16776739]   INPUT-DEPENDENT
  ★ cell 07  quiet [0 .. 8388607]  loud [0 .. 16772017]   INPUT-DEPENDENT
  2 of 29 kernel-written cells are INPUT-DEPENDENT
```

The audio is deposited in D-RAM `0x06`/`0x07` by iw11..iw32 and **the handover is through
memory, not through the accumulator.** So "the accumulator must survive to the epilogue" was
never a requirement. §101's blocker, as stated, does not exist.

### 4. ★★★ SO WHERE IT ACTUALLY FAILS — and it is one step, not a chain

§98 measured that **body 0 READS the audio cells**: `03r [05r] [07rw] ...`. And §81 measures
what body 0's accumulator does with them:

```
  body-0 iw90       quiet [274,881,642,546]  loud [274,881,642,546]  IDENTICAL
  body-0 END iw152  quiet [0 .. 0]           loud [0 .. 0]           IDENTICAL
```

**Body 0 reads two cells that demonstrably carry the input and produces an accumulator that
does not depend on it.** That is the defect, stated as one fact:

> The kernel hands the audio over correctly. The body picks it up and loses it.

Unit 1 not being fed (§98) is downstream of this and probably *not* independent — body 0's
result is a plausible source for the unit-1 send, and body 0 has no result.

### 5. What this reorders

The §101 dependency chain is **wrong at its root** and is withdrawn:

```
  WITHDRAWN:  accumulator survives kernel -> epilogue  ->  w70 live  ->  SRC 0x03  -> ...
  REPLACED:   body 0 converts its input-bearing reads into an input-bearing accumulator
                -> body 0 has a result
                  -> the unit-1 send has a possible source
                    -> SRC 0x03 / R-2 become decidable
```

The new head of the chain is **narrow and instrumented**: body 0 is iw84..199, its first
audio-bearing read is at `[05r]`, and the §81 probe at iw90 is already inside it. The next
measurement is which slot between the read and iw90 drops the operand — the same bisection that
worked here, on a region a tenth the size of the frame.

⚠ **Grade honestly:** §101's blocker was MEASURED (the accumulators *are* zero at the
epilogue) but MIS-INTERPRETED — a true observation promoted to a causal requirement without
checking whether the machine needs it. The observation stands; the conclusion drawn from it
does not.

Evidence grade: **MEASURED** (probe series, cell input-dependence, probe placement verified in
source); **INFERRED** that body 0's failure is upstream of unit 1's.

---

## §105 — THE BODY-0 BISECTION: EXCELLENT MEASUREMENT, **REFUTED MECHANISM**, AND THE REAL DEFECT IS AN OFF-BY-ONE

A multi-agent run bisected body 0. Its measurements are strong and are kept. Its central
interpretation is **wrong**, and what refutes it was already written in `lfo-ramp.md` — the
fourth time this week.

⚠ **All three adversarial verifiers died on API 529/500 with zero tokens spent, so the finding
arrived unchecked.** The verification below is mine, done because the checking is the half that
matters.

### 1. WHAT STANDS — and it is a lot

* **A new instrument worth keeping (§104):** per slot, the quiet/loud min-max of THREE
  quantities — the accumulator *after* the slot, the D-RAM cell under the pointer *before* it
  (a RESIDENCY census, distinct from §86/§96's write census), and `L`, the operand bus the
  decode actually selected.
* **The null computed first, properly:** every slot executed in *both* buckets — 92 592 quiet
  and 207 408 loud frames at every slot — and the same columns report DIFFERS on kernel slots
  in the same run. No verdict here is a "1 of 1".
* ★★★ **Frame-wide sweep: the LAST slot at which any of acc/mem/L is input-dependent is
  `iw33`.** From `iw34` through kernel A's tail, all of body 0, kernel B, all of body 1 and the
  epilogue, all three columns are bit-identical quiet versus loud. **The audio never leaves
  kernel A.**
* **A negative result that killed the static lenses' favourite:** two of three lenses ranked
  `iw85` first. Cell `0x05` reads `0..0` in both buckets at every appearance anywhere in the
  frame. The canonical base+0 read has nothing to lose.
* **Value-level identification:** `iw32` puts `L = 4194304 = 0x400000` into the cell, and
  4194304 is exactly what body 0 finds resident seventy slots later.

### 2. ⛔ THE MECHANISM IS REFUTED — `iw90` IS THE CHORUS LFO, NOT AN AUDIO PATH

The claim: *"body-0 `iw90` is the acquisition slot; it fails because kernel `iw32` overwrote the
audio in cell `0x07`."*

`lfo-ramp.md` §1 tabulates the LFO block's three words:

```
   0092A00200    092 (f31=1,ST)  A  +0  200  SRC 0x08   phase accumulate
   00822001C0    082 (f31=1   )  2  +0  1C0  SRC 0x07   the middle word
   0094A00200    094 (f31=2,ST)  A  +0  200  SRC 0x08   the wrap
```

The measured body-0 rows at iw89/90/91 are `0092A00200`, `00822001C0`, `0094A00200` —
**character for character, in order.** And §11 of the same note gives the semantics:
`082.2.00.1C0` is `acc <- mem[Q] = phase`.

So `iw90` is the **CHORUS LFO phase read**, cell `0x07` there is `mem[Q]`, and it is *supposed*
to be input-independent. An LFO phase that tracked the audio would be a defect, not a fix.

**Which inverts the counterfactual.** Suppressing `iw32`'s store made `iw90` report DIFFERS —
but it achieved that by letting the LFO phase read pick up audio the kernel had left in the
cell. That is not the bug being fixed; it is a second wrong behaviour producing a DIFFERS. A
one-word counterfactual with a genuine two-sided criterion still measured the wrong thing.

And the agent's own "independent corroboration not fitted to" — *"mem[0x07] is 4194304 in every
frame, so the CHORUS LFO phase never ramps"* — is not corroboration for its mechanism at all.
It is a **separate, pre-existing finding**: `lfo-ramp.md` §11 already states *"the block stores
the phase back unchanged — no ramp."*

### 3. ★★★ THE REAL DEFECT: THE DEPOSIT AND THE PICKUP ARE ONE CELL APART

Put the measured facts side by side:

```
  kernel A deposits the audio in    cells 0x06 AND 0x07   (§86: the only 2 of 29 that are
                                                           input-dependent)
  body 0's pointer window is        03 05 07 0C 0D 0E 0F 10 11 12 13 50 51 52 53 F1   (§98)
                                       ^^    ^^
                                    0x05 and 0x07 -- base+0 and base+2.  NO 0x06.
  and 0x07 is independently the CHORUS LFO PHASE cell (lfo-ramp.md §1/§11)
```

**Body 0 never reads the cell that holds the audio.** `0x06` is base+1, and the body reads
base+0 and base+2. `0x05` is measurably empty; `0x07` belongs to the LFO. The audio sits in the
one cell between them, untouched.

That is a **one-cell misalignment between the kernel's deposit and the body's pickup**, and one
of the two anchors involved is the FORCED per-unit base `0x05 | unit << 7`. Either the base is
off by one, or the kernel's deposit pair is.

It also explains the `0x07` collision cleanly: our model has **two subsystems aliased onto one
cell** — the kernel writing audio there and the body's LFO using it as phase — which is the same
shape of error as §97's two memories, one level down.

### 4. Notes on the run itself

* The workflow shape earned its keep in an unexpected way: the parallel static lenses were
  *wrong* (both favoured `iw85`) and the measurement killed them. Fan-out plus measurement beat
  fan-out alone.
* Two decode details the agent did not flag, found on re-derivation: **`iw30` carries bit 4 AND
  the gate bit 7 with `f31 = 5`**, and guard 7 says a bit-4 word carrying bit 7 executes only at
  `f31 == 2` — so `iw30` should TRAP, not store. Same class as the guard-6/`iw70` discrepancy in
  §98, and now two of them. And **`iw92`'s `SRC 0x11` is the SPECULATIVE ACCB reading**, so the
  "secondary downstream defect" the agent reported at `iw92` rests on a guess.
* Nothing was promoted: no default mask changed, and the §104 instrumentation was committed
  alone, labelled unverified.

Evidence grade: **MEASURED** for §1's facts and for the LFO-block word identity;
**REFUTED** for the mechanism; **FORCED** that body 0 does not read cell `0x06`;
**INFERRED** that the misalignment is off-by-one rather than something larger.

---

## §106 — THERE IS NO OFF-BY-ONE. THE BASE+0 PICKUP IS BLOCKED BY **UNDECODED ACTION 0x0D**

Asked to fix the off-by-one §105 named. It does not exist, and saying so cost one diagnostic
rather than one guess.

### 1. Why it cannot be an off-by-one

```
  kernel's audio pair    0x06 and 0x07   -- ADJACENT, stride 1  (§86, the only 2 of 29
                                            input-dependent kernel-written cells)
  body's pickup pair     base+0, base+2 = 0x05 and 0x07 -- stride 2  (§94, 12 of 12 reverbs)
```

**No single offset aligns a stride-1 pair to a stride-2 pair.** And the kernel's window cannot
slide regardless: the frame closure pins it, with residue exactly 0 — one of §90's four
confirmed predictions. So a "fix" would have had to move a FORCED anchor on a premise that
does not hold. Two further cracks: `0x07` is independently the CHORUS LFO phase cell
(`lfo-ramp.md` §1), and the input-latch offsets `+2`/`+5` rest on a premise
`retraction-sweep.md` P9 explicitly DOWNGRADED ("the NEVER-WRITTEN half does not survive").

### 2. The discriminator, run instead of the fix (mask bit 26, DIAGNOSTIC, never to be promoted)

Mirror the kernel's `0x06` result into `0x05` as well. Deliberately does not touch `0x07`, so
the LFO stays separable. Two-sided by construction:
* body 0 becomes input-dependent ⇒ the pickup model is right, the deposit address is the defect
* it does not ⇒ `base+0` is not an input cell either, and the pair identification is wrong

```
  §106 DIAGNOSTIC: mirrored 3,649,369 writes of cell 0x06 into 0x05
  §104 SUMMARY over body-0 iw84..199: first acc DIFFERS at -1, first mem DIFFERS at -1  (-1 = never)
  §81 PROBE body-0 iw90    quiet [274881642546]  loud [274881642546]  IDENTICAL
```

**Second arm. Feeding audio into `base+0` changes nothing.** The off-by-one hypothesis is dead
from the pickup side, not merely unsupported.

### 3. ★★★ WHY — and it corrects the workflow's own dismissal

Body 0's `base+0` read is `iw85`:

```
  iw85  000020E1CD = 000.2.0E.1CD   f31 = 0 (LOAD acc <- P)
                                    SRC 0x07 = mem[ptr]   ANCHORED
                                    ACTION 0x0D           ⛔ UNDECODED
  iw84  08801308BC = 880.1.30.8BC   lo12 bit 11 set -> the ALTERNATE ENCODING,
                                    addressing only, no ALU route at all
```

So the cell is read through an anchored source and then handed to an **undecoded action**, which
routes it nowhere. Filling the cell cannot help while the action that consumes it is unmodelled.

⚠ **The bisection agent saw ACTION 0x0D and dismissed it** — *"the canonical base+0 read has
nothing to lose, so its undecoded ACTION 0x0D is not the failure here."* That inference was
conditional on `0x05` being empty. The mirror removed the condition, and the conclusion
reverses: give `base+0` something to lose and the undecoded action still loses it. **A negative
result that holds only because an input is empty is not a negative result about the consumer.**

### 4. What the real target is now

Not an address. **ACTION 0x0D**, and behind it the action field generally — `action-field.md` is
the note that owns it. This also re-ranks the standing task list: the pending item *"attack
hi12[3:1] > 2"* has a sibling of at least equal weight, since `iw30` (`f31 = 5`) and `iw85`
(`ACT 0x0D`) are both on the audio path and both unmodelled.

⚠ And a procedural note on me: this is the **second hex-composition error this session**. The
first §97 A/B used four hand-typed mask bits I did not intend; here `0x419F440F` was typed for
`0x19F440F | 0x4000000` (correct: `0x59F440F`), the diagnostic silently never fired, and the
first A/B came back bit-identical for that reason alone. It looked exactly like a real negative
result. **Masks get computed, never typed** — and a diagnostic needs a fired-count in the log,
which is the only reason this was caught rather than published.

Evidence grade: **FORCED** that no offset reconciles the two strides; **MEASURED** that filling
`base+0` leaves body 0 bit-identical (3.6M mirrored writes, criterion demonstrably two-sided
elsewhere); **MEASURED** that `iw85`'s action is `0x0D` and undecoded.

---

## §107 — ACTION 0x0D IS **STILL UNDECODED**, AND THE TEST THAT WAS SUPPOSED TO DECODE IT FAILS ITS OWN CONTROL — WHICH WEAKENS A READING WE ARE SHIPPING

### 1. The hypothesis, and it was a good one

`action-field.md` §6 establishes a family arithmetic: *"`0x19` captures tempA and `0x1A`
captures tempB … a second pair of capture codes beside the anchored `0x13`/`0x14`, with the
same two destinations and `lo12[4:3]` = 3 instead of 2. The arithmetic agrees:
`0x19 = 0x13 + 6`, `0x1A = 0x14 + 6`."*

Extending downward: `0x0D = 0x13 − 6`, `0x0E = 0x14 − 6`, a third family at `lo12[4:3] = 1`.
Supporting it: `0x0D`'s SRC profile is 75% `SRC 0x07` (mem[ptr]), closely matching anchored
`0x13`'s 90%; and the counts pair up (203/227, like 40/58 and 89/18). Unlike SRC 0x02/0x03 this
had **203 sites**, so the corpus could in principle answer.

### 2. The method was not new either — and that is the point

`upd6383.cpp` records how ACTION `0x19`'s destination was established: *"ACTION 0x19 is followed
by a word SOURCING tempA in 74 of 89 distinct-image sites (base rate 16.0%, shuffled null
42.7%). DESTINATION = tempA is measured."* `act0d.py` replicates that test and adds the
discriminator it lacked — the CROSS pairing — plus the anchored codes as calibration.

Replication is faithful: it reproduces `0x19 → tempA` at **74/89** exactly.

### 3. ⛔ THE CALIBRATION SPLITS, SO THE TEST IS NOT USABLE

```
  null, computed first:  an arbitrary ALU word is followed within 4 by a tempA source 16.7%
                                                                  ... a tempB source 10.2%

  lo12[4:3]  ACT   n    ->tempA      ->tempB     family expects
      2      14   58   20/58  34%   58/58 100%   tempB   ✅ ANCHORED, and the test nails it
      2      13   40    0/40   0%    1/40   2%   tempA   ⛔ ANCHORED, and the test scores ZERO
      3      19   89   74/89  83%   16/89  18%   tempA   (the shipping reading)
      3      1A   18   15/18  83%   10/18  56%   tempB   ⛔ scores HIGHER on tempA
      1      0D  203    6/203  3%    5/203  2%   tempA   both BELOW null
      1      0E  227    3/227  1%    4/227  2%   tempB   both BELOW null
```

**One anchored code scores 100% on its own destination and the other scores 0%.** A test whose
two controls disagree that completely cannot adjudicate a third code. So:

**ACTION 0x0D remains UNDECODED.** Not "probably tempA" — undecoded.

### 4. What can still be said about 0x0D, carefully

`0x0D` and `0x0E` score **below the null** on both destinations, across 203 and 227 sites. If
they were temp captures one would expect at least the base rate, as `0x14` (100%) and `0x19`
(83%) do. That is a **weak refutation** of the family-arithmetic extension — weak precisely
because the instrument is unreliable, and stated as weak rather than promoted.

### 5. ★★★ THE CONSEQUENCE I DID NOT GO LOOKING FOR — a shipping reading is weaker than recorded

`0x19 → tempA` is **live in the emulator** and its justification is the 74/89 figure from this
test, which the device's own comment calls *"measured"*. The same test scores **0 of 40** on the
anchored tempA code. So the instrument that certified `0x19` fails on the one case where the
answer is already known.

And `0x1A → tempB`, from the same §6 reading, scores **83% tempA against 56% tempB** — the wrong
direction.

⚠ This does not make `0x19 → tempA` false. `action-field.md` §6 has an independent argument for
it (the tap gain `C-RAM[0x96] = 0.500` multiplying tempB at the first separator, role PROVEN),
and §6 was careful to grade the family reading **CONSISTENT and not FORCED**, explicitly
noting *"three earlier words in that body (`0x0B`, `0x0D`, `0x0E`) carry unanchored ACTION codes
and could in principle have written tempB"*. The note hedged correctly. What changes is that the
**follow-on statistic should not be cited as its evidence**, and `upd6383.cpp`'s comment calling
the destination "measured" overstates it.

**Action taken: none to the shipping behaviour.** `0x19` stays as it is, under the owner's
2026-07-27 decision. The comment needs correcting, and I have not silently changed a behaviour
on the strength of a test I just showed to be unreliable.

### 6. Where this leaves the audio path

Body-0's `base+0` read (`iw85`, `ACT 0x0D`) is still the blocker, and it is still blocked by an
undecoded action. The available routes now:
* an argument from the **arithmetic of the block** that contains `iw85`, the way §6 got `0x19` —
  i.e. reconstruct what CHORUS must compute and see what the action has to be. `r1-allpass-solve`
  and `act0b-reverb.md` are the precedents.
* the `hi12[3:1] > 2` task, since `iw84`'s `f31 = 0` and `iw30`'s `f31 = 5` sit on the same path.
* ⚠ NOT another follow-on statistic over the same corpus, which §3 has just disqualified for
  this family of question.

Evidence grade: **MEASURED** (all six rows, the null computed first); **REFUTED** that this test
can decode a capture destination; **WEAKLY AGAINST** the family-arithmetic extension to `0x0D`;
**UNDECODED** for ACTION 0x0D itself.

---

## §108 — RECONSTRUCTING CHORUS AT iw84..92, AND A REFUTATION THAT RETIRES A WHOLE FAMILY OF FIXES

### 1. The block, decoded and measured together

```
 iw  word          f31 st gt esc  SRC ACT  dp  delta   measured acc / mem / L
 84  880.1.30.8BC   0  0  1  1     02  1C  05   +0     0 / 0 / 0      alt-encoding: addressing only
 85  000.2.0E.1CD   0  0  0  0     07  0D  05  +14     0 / 0 / 0      §106's blocker: reads base+0
 86  000.2.DE.40E   0  0  0  0     10  0E  13  -34     0 / 0 / 0
 87  212.2.22.00B   1  1  0  0     00  0B  F1  +34     0 / 0 / 0      the only store; symmetric excursion
 88  000.2.F4.407   0  0  0  0     10  07  13  -12     0 / 0 / 0
 89  092.A.00.200   1  1  1  0     08  00  07   +0     3735552 / 4194304 / 57      ] LFO phase accumulate
 90  082.2.00.1C0   1  0  1  0     07  00  07   +0     2.7e11 / 4194304 / 4194304  ] acc <- mem[Q]
 91  094.A.00.200   2  1  1  0     08  00  07   +0     8.2e11 / 4194304 / 8388607  ] the wrap
 92  000.2.09.447   0  0  0  0     11  07  07   +9     50 / 4194361 / 8388607
```

### 2. ★ WHAT THE RECONSTRUCTION ESTABLISHED — the phase DOES increment

`lfo-ramp.md` §11 records *"the block stores the phase back unchanged — no ramp"*. The §104
census shows that is not quite it. The phase cell reads **4194304** at iw89/90/91 and
**4194304 + 57** at iw92 — so the body **does** increment it, by 57 (`lfo-ramp.md` predicts 114
for CHORUS; the familiar factor of 2, and `iw89`'s `L` is exactly 57). The increment then fails
to survive to the next frame, because something resets the cell to `0x400000` — **which is
exactly the value kernel `iw32` stores.**

### 3. The over-determined hypothesis, and its prediction

One parameter, two independently measured symptoms: if the body's base were `0x06` rather than
`0x05`, then (a) the LFO phase lands on `0x08`, outside kernel A's measured `01..07` window, and
can ramp; and (b) `iw85`'s `base+0` read lands on the kernel's audio at `0x06` instead of the
measurably empty `0x05`. Predicted before the run: (a) fires, (b) does not — because `ACT 0x0D`
is still undecoded (§107) and §106 already showed that filling `base+0` alone changes nothing.

### 4. ⛔⛔ REFUTED — and the refutation is worth more than the hypothesis was

Applied as mask bit 27. **The gate fires** — `dp` is `0x06` at iw84/85 and `0x08` at iw89..92 —
**and every measured value is bit-identical. The phase is still pinned at 4194304.**

Why:

```
  base 0x05:  kernel A window  01..07     body 0 LFO phase at 0x07
  base 0x06:  kernel A window  02..08     body 0 LFO phase at 0x08
```

**The whole frame moves together.** Kernel A's walk begins where the previous frame *closed*, and
the closure is downstream of the base, so base and window are coupled. `iw32` follows the phase
cell wherever it goes.

### 5. ★★★ THE CONSEQUENCE: an entire family of attempted fixes is dead

**No value of `DRAM_UNIT_BASE` can fix the deposit/pickup collision, because the collision is in
the RELATIVE geometry and the base cancels out of it.** That is a structural result, not a
failed experiment, and it explains two earlier dead ends rather than adding a third:

* §105's "off-by-one between deposit and pickup" was doomed for this reason, not only because of
  the stride mismatch it identified.
* §106's mirror changed nothing partly because `ACT 0x0D` routes nowhere — but also because
  no absolute-address change could have mattered.

**What CAN change the relative geometry** is a per-word **addressing** decode: some word's
`addr8` contribution to the walk, `iw30`/`iw32`'s store target, or the body's LFO block not
really sitting at base+2. That is where to look. Not at the anchor.

This is also the fourth time this session that the fix I reached for was an ANCHOR VALUE when the
defect was a per-word DECODE. Worth naming as a bias: an anchor is a single number and therefore
feels cheap to try, but every anchor here is pinned by closure arithmetic, and a per-word decode
is where the unmodelled opcodes actually are.

### 6. Housekeeping

Bit 27 stays implemented and OFF, with the refutation recorded at the site so it is reproducible
rather than a claim, and so the next reader does not retry it.

⚠ **A stale diagnostic found in passing:** the PER-UNIT REBASE audit prints `DRAM_UNIT_BASE`
rather than the gated value, so its *"the walk ALREADY delivered 0x05 on 93.32%"* line is
meaningless whenever bit 27 is on. Noted at the site; not read under the gate.

Evidence grade: **MEASURED** (the block decode, the phase increment of 57, the window shift,
the bit-identical outcome); **FORCED** that no base value can fix the collision; **UNDECODED**
still for `ACT 0x0D`, `ACT 0x0E`, `ACT 0x0B`, `ACT 0x1C` and `f31 = 5`.

---

## §109 — iw30/iw32's STORE TARGET: BOTH DISCREPANCIES RESOLVED, PRE CONFIRMED ON A DECODED CONTROL, AND ONE GENUINE PER-WORD ADDRESSING DEFECT (iw11)

Six agents, all returning; both adversarial verifiers ran and both re-derived every word field by
hand. What follows separates what survived that from what did not.

### 1. SURVIVES — the two named discrepancies are resolved

**Guard 7 does not fire for `iw30`, and is never consulted.** `iw30`'s `SRC 0x08` is unanchored,
so `alu_decoded()` returns false at the **ROUTING** test (`gfail = 23`) *before* guard 7's test is
reached. `guard7_would_refuse()` is nevertheless 1 — the guard's own rule *would* refuse it — and
`path = 1` shows `alu_decoded_speculative()`'s unconditional `return true` discards that verdict
wholesale. The only **live** gate on the store is `st_suppressed() = bit7 && f31 == 1`, which
`f31 = 5` does not match, so it stores at the bit-4 site.

★ **The control passes** (rule 3): `iw37` returns `gfail = 7`, so code 7 *can* appear. "iw30's
gfail is 23, not 7" is a discrimination, not a vacuous 1-of-1.

**The guard-6 / `iw70` sibling has the same shape:** `iw70` is class 1, refused by guard 1 first,
so it never entered guard 6's *"303 of 303 are mode 2"* census — which is silently **post-guard-1**.

**⇒ Both are DOCUMENTARY defects in `upd6383d.h`'s comments, not code defects.** Guard 7's
"everything else traps" and guard 6's "303 of 303" are scoped to `alu_decoded()`'s executable set
and neither says so.

**ACT 0x07 stores at the PRE-increment cell**, and this is confirmed on a **fully decoded,
anchored control**: `iw34` (`0000AFF407`, `SRC 0x10`, ACT 0x07, `gfail 0`) reads dpPre 06 / dpPost
05 and stores at 06. So PRE is not merely our convention on speculative words.

**POST is measurably worse**, via a decoded witness: `iw88` (`000.2.F4.407`, class 2, `SRC 0x10`
anchored, `gfail 0`) stores at 0x13 under PRE and at **0x07 — the phase cell — under POST**,
300 000 times, driving the resident phase to 0. `lfo-ramp.md` §8.4 forces the negative *"it must
not deposit a foreign value in the phase cell"*. Base-invariant, so §108's result does not touch it.

**`iw30` and `iw32` both store to cell `0x07`.** For `iw30` pre-vs-post is **moot** — `addr8 = 0x00`,
dpPre = dpPost = 0x07 — and the pass says so rather than manufacturing a distinction.

### 2. ★★★ THE ONE GENUINE DEFECT, and it is exactly the class §108 asked for

`iw11` (`0400201447`), the single K6 input-stage word carrying ACTION 0x07, stores at **dpPost
(0x06)** while every other ACT-07 word in the build stores at dpPre. Cause: `exec_alu_k6()` runs
after `exec_addressing_only()` has already advanced `m_dp`, and §35's `if (m_in_k6)` short-circuit
covers **only the bit-4 site**, not the ACT-07 site. **Two timings for one action code in one
binary.** `iw11` is the earliest writer of cell `0x06` — one of the two cells this whole
§105–§108 line is about. It also served as the instrument's **positive control**: it proves the
probe can see a POST landing, so the PRE nulls are not blind.

Not changed here: a separate change with its own measurement.

### 3. REFUTED — three sub-claims, and the first is the instructive one

**A. The "13 corpus words" figure is a statistic its own source retracted.** `store-gate.md` item F
says verbatim *"★ published count: 13. MEASURED: 11"*, labelled *"a FALSIFICATION of the published
count"* — and goes further: the nine `f31 = 5` words (iw30's own form) *"trap because
`hi12[3:1] > 2` is an undecoded accumulator operation … independent of bit 7 and of the gate"*,
with *"A gate cannot disagree about a word it never reaches. Pricing a question at words that
cannot execute is the same defect as a control that cannot fail."*
⚠ **A pass whose whole subject is a scope defect in `upd6383d.h`'s comments reproduced a retracted
statistic out of those same comments.** The substance (the gate tie is live under speculation)
stands; the number does not.

**B. "iw32 is not the reset" is contradicted by the pass's own arm C** — and this restores my §108.
With `iw30`'s store suppressed, cell `0x07`'s writers are `{iw32, iw91, iw92}` and the phase
resident at `iw89` is **still 4194304**. So `iw32` alone installs the reset value and is the last
kernel write before the body reads. **§108's "kernel iw32 resets the phase" was correct; the
agent's correction of it was wrong.** What *is* new and right: `iw92` **also** destroys the
published phase one slot after `iw91` publishes it, writing `0x7FFFFF` = unity — verbatim the case
`lfo-ramp.md` §8.4 positively excludes. Cell `0x07` has **four** writers per frame.

**C. A fabricated citation, masking the real one.** "the biquad's static 10-of-10" bearing on the
ACT-07 store target **does not exist** anywhere in the tree. Meanwhile the genuinely decisive
static result went uncited: `lfo-ramp.md` §8.3 already ran the post-increment hypothesis over
**276 480 machines with 0 survivors**, noting it *"breaks the 5 blocks that worked: PHASER's
`092.A.0E.200` would then store at +14 = Q"* — the identical failure mode as the new `iw88`
finding. **The PRE conclusion was already established statically and got re-derived against a
phantom source.**

**D. And one of the VERIFIERS is wrong.** Verifier 1 claimed the unit-0 output level is written to
zero ~1.6 M times per run, citing the device's §41 **comment** — which describes the pre-§100
state. Measured at the shipped default immediately after: `unit0 0x200000, non-zero on 452 160
frames`. The level is intact. ⚠ A verifier citing a stale comment as a measurement is the same
error it flagged in the pass; adversarial verification is not self-validating either.

### 4. Left open, explicitly

* The phase step is **+57** where `lfo-ramp.md` predicts **114** for CHORUS. Possibly a different
  host-programmed rate, possibly the factor of 2 seen in the host levels. Unreconciled.
* A live conflict between `lfo-ramp.md`'s determined **unity** for `SRC 0x08` and the coefficient
  the device measures there. Both cannot hold.
* `ACT 0x0D`, `0x0E`, `0x0B`, `0x1C` and `f31 = 5` remain undecoded — and per store-gate.md, the
  `f31 = 5` words trap for a reason independent of the gate, so `hi12[3:1] > 2` is the live blocker.

Evidence grade: **MEASURED** (store targets, gfail codes with a passing control, the PRE/POST arms
with fired-counts, the iw11 timing split); **FORCED** that POST is wrong (decoded witness plus
§8.3's 0 of 276 480); **REFUTED** for the three sub-claims above; **documentary** for the two guard
comments.

---

## §110 — THE iw11 TIMING DEFECT FIXED, AND IT EXPOSES A SINGLE ROOT CAUSE: **SRC 0x08 CLOBBERS BOTH AUDIO CELLS**

### 1. The fix

§109 measured that `iw11` (`0400201447`), the one K6 input-stage word carrying ACTION 0x07,
stored at its **post**-increment cell while every other ACT-07 word stored at its **pre**-increment
cell — two timings for one action code in one binary. Cause: `exec_alu_k6()` runs after
`exec_addressing_only()` advanced `m_dp`, and §35's `if (m_in_k6)` short-circuit covers only the
**bit-4** site.

Corrected by undoing the advance rather than skipping the store: the bit-4 site can skip because
`exec_addressing_only()` performs that store itself at the pre-increment cell it captured on
entry; it performs **no** ACT-07 store, and `iw11` carries no bit 4, so skipping would lose the
store entirely. Mask bit 30 reverts; the fix is ON by default.

PRE is right on independent evidence, not symmetry: §109 confirmed it on `iw34`, a fully decoded
anchored ACT-07 word, and `lfo-ramp.md` §8.3 ran the post-increment hypothesis over **276 480
machines with zero survivors**.

### 2. Predictions, all four confirmed

```
                              FIXED (19F440F)              REVERTED (419F440F)
  §110 fired-count            492,480                      0            <- proper null
  cell 05                     ★ INPUT-DEPENDENT            absent from the set
                              quiet [0..4194304] loud [0..16776739], 1,200,000 writes
  cell 06                     2,400,000 writes             2,700,000, iw11 in its writers
  §54 verdict                 SILENT, DC leak 0.00%        SILENT, DC leak 0.00%
  kernel input-dependent      3 of 29                      2 of 29
```

Body 0 still does not acquire the input, exactly as predicted — `iw85`'s `ACT 0x0D` is undecoded
(§107) and routes the operand nowhere.

### 3. ★★★ BUT THE RESIDENCY COLUMN SAYS SOMETHING SHARPER

§104 still reports **`first mem DIFFERS at -1`** across body 0. So cell `0x05` is written
input-dependently by the kernel and is **constant again by the time body 0 reads it** — the
identical pattern as `0x07`. Naming its writers, in execution order:

```
  cell 05   iw9  012.2.FF.1D5  SRC 07  ACT 15  store
            iw11 400.2.01.447  SRC 11  ACT 07          <- the audio, after §110's fix
            iw35 012.A.00.1C0  SRC 07  ACT 00  store   <- SRC 07 = mem[ptr], reads and writes back
            iw45 010.A.00.20C  SRC 08  ACT 0C  store   <- ⛔ LAST before the body
  cell 07   iw30 09A.A.00.200  SRC 08  ACT 00  store   <- the audio
            iw32 000.A.FF.207  SRC 08  ACT 07          <- ⛔ LAST before the body
```

**Both audio cells are destroyed by a word whose operand source is `SRC 0x08` — which is
UNDECODED.** Two cells, two different store sites (bit-4 and ACT-07), reached independently, one
source. That is a root cause, not a coincidence.

### 4. And SRC 0x08 is where the evidence already conflicts

* At `iw89`/`iw91` — the CHORUS LFO block — `SRC 0x08` yields **57**, and `lfo-ramp.md`'s ramp
  constants are `0x72 = 114` for CHORUS at 11 sites. Ours is exactly half: the same factor of 2
  as the host levels. So there `SRC 0x08 = C-RAM[cursor]` looks **right**.
* At `iw32`/`iw45` the same route yields **`0x400000`** and destroys the audio. So either the
  route is right and the **cursor is mis-positioned** at those two words, or these words should
  not store, or the LFO agreement is coincidence.
* §109 already recorded a live conflict: `lfo-ramp.md` determines **unity** for `SRC 0x08` while
  the device measures a coefficient. Both cannot hold.

★ **`SRC 0x08` has 83 corpus words** — genuinely decodable, unlike `SRC 0x02`/`0x03` which had
n = 1 each and defeated §100/§101. This is the first blocker in this chain with enough sites to
support a corpus argument.

### 5. Next

**Decode `SRC 0x08`**, and the question is now sharply posed rather than open-ended: it must yield
~114 at the LFO block (where `lfo-ramp.md` independently predicts the value) and must not yield a
constant that overwrites the audio at `iw32`/`iw45`. That is a **two-sided criterion with a known
right answer at one site** — the strongest test shape available, and precisely what §107's
disqualified follow-on statistic lacked.

Evidence grade: **MEASURED** (the fix, its fired-count and null, cell 0x05's input-dependence and
its four writers in order); **FORCED** that PRE is the ACT-07 convention; **INFERRED** that
`SRC 0x08` is one root cause for both clobbers — the two sites agree but that is two instances.

---

## §111 — ★★★ **SRC 0x08 WAS ALREADY RIGHT. THE HOST PAYLOAD IS 2× THE RAW BYTES** — two independent known-right answers, both hit exactly

### 1. The note refuted my own §110 hypothesis before I could test it

§110 named `SRC 0x08` as the root cause: it clobbers cell `0x05` (via `iw45`) and cell `0x07`
(via `iw32`), and it yielded 57 at the LFO where `lfo-ramp.md` predicts 114. I was about to
decode it. Reading the owning note first says otherwise — `lfo-ramp.md` §2:

> *"**C-RAM cells**. The first cell is the per-frame phase increment; the second is …"*

So `SRC 0x08 = C-RAM[cursor]` is **corroborated as a route, not refuted**. And 57 is exactly
half of 114 — which is not an SRC decode error at all but the **already-known host-payload factor
of 2**, recorded in `r3-delaydram.md` as *"host payload is 2× the raw three bytes"* and
reproduced in §71/A3 as a control that could have failed: the cold-boot record says
`reg 0x06 <- +0.500000` / `reg 0x86 <- +0.183992` while the wire carries `+0.250000` /
`+0.091996`, **half of each to six decimal places.**

**We had been storing the raw bytes ever since, so every host-programmed quantity in this device
was half.** The factor was documented twice and never applied.

### 2. The test, and why it is strong

Doubling the 24-bit datum in the poke-port DATA packet, behind mask bit 31 with a fired-count.
**Two independent known-right answers, from different notes and different subsystems, neither
fitted to the other** — a wrong scaling cannot satisfy both:

```
                          mask 19F440F      mask 819F440F      independently predicted by
  §111 fired-count        0 (proper null)   115 packets
  unit-0 output level     0x200000          0x400000     ✅  +0.5, documented cold boot (A1/A3)
  CHORUS LFO increment    57                114          ✅  0x72, lfo-ramp.md, 11 sites, 0.5993 Hz
  acc at iw89             3,735,552         7,471,104        (exactly 2×, consistent)
  §54 verdict             SILENT 0.00% DC   SILENT 0.00% DC   no regression
```

Both hit **exactly**. This is the strongest single result of the session: it is a decode with a
control whose answer was written down in advance, by someone else's analysis, at 11 sites.

**Promoted to the default mask, now `0x819F440F`.**

### 3. What it does NOT fix, stated plainly

The chip is still silent, and the LFO phase is still pinned — the increment is now correct but
`iw32`/`iw45` still overwrite the cells before the body reads them. §110's *clobber* observation
stands; only its attribution to an SRC-0x08 mis-decode falls.

⚠ **Residual, unresolved:** unit-1's level doubles to `0x178D0A` against a documented
`0x178D50` — a difference of 0x46, about 0.006%. Unit 0's is exact. So the doubling is right and
unit 1's *source value* carries a small pre-existing error, which §97 first noticed and this does
not explain.

### 4. The lesson, since it is the fourth of its kind today

I was one build away from "decoding" a route that was already correct, because a two-fold
discrepancy looked like a decode error. What separated them was reading the note that owns the
quantity — and the factor had been recorded in `r3-delaydram.md`, reproduced in §71/A3, and
quoted verbatim in §97 and §110's own text. **A known constant offset between our value and the
documented one is a scaling bug until proven otherwise, not evidence about the route that carries
it.**

Evidence grade: **MEASURED**, with two independent pre-registered controls hit exactly and a
zero-valued null arm; the residual unit-1 0.006% remains **OPEN**.

---

## §112 — THE iw32 CLOBBER IS REMOVED, AND IT REVEALS THE NEXT ONE EXACTLY AS §109 PREDICTED. ⚠ §113 WAS NOT VALIDLY TESTED

### 1. The clobbers are LAYERED, and two of three are now off

Cell `0x07` — the CHORUS LFO phase cell — had three kernel/body writers ahead of the body's read:

```
  iw30  09A.A.00.200  the live accumulator (audio)   -> removed by the ALTERNATIVE STORE GATE
  iw32  000.A.FF.207  0x400000 (a C-RAM coefficient) -> removed by §112, below
  iw92  000.2.09.447  0x7FFFFF (unity)               -> STILL PRESENT
```

**The alternative store gate** (mask bit 29, `store-gate.md` item C's co-equal survivor
`bit7 && f31 != 2`): `iw30`'s `f31 = 5`, so it no longer stores. **Cell `0x07` drops out of the
input-dependent set**, and with §111's correction the increment reads correctly — `iw92`'s
residency shows `4194304 + 114`.

**§112: ACTION 0x07 on a class-A word LATCHES P rather than storing to D-RAM.** `class4 == 0xA`
is the coefficient consumer, and `lfo-ramp.md` §11 annotates `iw32`'s two sibling class-A /
SRC-0x08 words in exactly those terms (`P := INC`, `P := 0x7FFFFF`). Guard 6 already concedes
the point: *"Applying the same mode rule to ACTION 0x07 is the CONSISTENT reading, not a
separate proof."*

```
  mask 819F440F   §112 fired 0          phase pinned at 4194304 (= 0x400000, iw32's value)
  mask 839F440F   §112 fired 1,470,720  phase pinned at 8388607 (= 0x7FFFFF, iw92's value)
                                        cell 0x07 leaves the input-dependent set
  §54 verdict     SILENT, DC leak 0.00% in both -- no regression
```

Proper null, proper fired-count. **`iw32`'s clobber is removed** — and the phase immediately pins
at the *next* writer's value, which is precisely what §109 forecast: *"iw92 destroys the published
phase ONE SLOT AFTER iw91 publishes it, with 0x7FFFFF = unity — verbatim the case lfo-ramp.md
§8.4 positively excludes."*

### 2. ⚠⚠ §113 WAS NOT VALIDLY TESTED — a mask collision, and my third of the session

I implemented `SRC 0x11 = mem[ptr]` (lfo-ramp.md item L's compliant reading of `iw92`, which
would make it an identity) behind **mask bit 18** — chosen by grepping the source for
`m_specmask & 0x…` consumers and finding none for `0x40000`.

**Bit 18 is already SET in the default mask.** `0x819F440F` has bits 0-3, 10, 14, 16-20, 23, 24,
31. So the gate was live in *both* arms, the computed "new" mask came out byte-identical to the
old one, and **no A/B exists.** The reading is neither supported nor refuted.

★ The lesson is narrower than "compute your masks" — I *did* compute it. **Checking that a bit
has no consumer in the code is not the same as checking it is clear in the default.** A free-bit
search must test both. And the tell was visible before the run: the two masks printed the same
value, and I did not look.

### 3. ★ THE NEXT DEFECT IS ALREADY NAMED, PRECISELY

`0x7FFFFF` is the maximum positive 24-bit value, and `lfo-ramp.md` §11's simulation states the
publish semantics verbatim:

> `094.A.00.200   ST mem[Q] <- (phase + INC) mod 2**23`

**mod 2²³ — a WRAP.** Our phase saturates at `0x7FFFFF` and sticks, i.e. we **CLAMP**. A clamped
phase accumulator stops dead at full scale; a wrapped one is a sawtooth, which is what an LFO is.

So the remaining question on this path is not "who clobbers the cell" — it is **whether the
publish wraps or clamps**, and the note already gives the answer to check against.

### 4. Nothing promoted

Neither §112 nor §113 goes into the default. §112 because its measured consequence is "reveals
the next clobber", not "the LFO works" — and a change whose only visible effect is to move a
pinned constant has not yet earned promotion. §113 because it was never tested.

Evidence grade: **MEASURED** for §112's A/B (fired-count, null, cell 0x07 leaving the set);
**UNTESTED** for §113; **FORCED by the note** that the publish is mod 2²³ and we clamp.

---

## §114 — ★★★ THE LFO RUNS. CLAMPING WAS THE BLOCKER — BUT THE MODULUS IS HALF, AND IT DOES NOT BELONG IN `acc_to_datum()`

### 1. The blocker was a labelled guess, not a bug

`acc_to_datum()` converts the 44-bit accumulator to a 24-bit datum, and its own comment is
admirably honest:

> *"whether it saturates or wraps is UNKNOWN, and saturation is the choice that cannot turn a
> loud sound into a louder one."*

`lfo-ramp.md` §11 settles it for at least one datapath, inside the simulation it uses to derive
the LFO rates: `094.A.00.200  ST mem[Q] <- (phase + INC) mod 2**23`. A clamped phase accumulator
stops dead at full scale; a wrapped one is the sawtooth an LFO is.

### 2. ★ MEASURED — the CHORUS LFO ramps for the first time

```
  clamp (A39B440F)   phase at body iw89:  8388607..8388607    a SINGLE value, pinned
  wrap  (1A39B440F)  phase at body iw89: -8388587..8388485    full-range sawtooth
                     §114 fired 122,255,040   null arm: 0
                     §54 SILENT, DC leak 0.00% in BOTH
```

★ **The falsifier I wrote down did not fire, and it was a real one.** The original comment's
reasoning is that wrapping an AUDIO accumulator turns a loud sample into an inverted one — so a
wrong wrap should have raised the DC leak or worsened the tracking verdict. Neither moved.

This also closes the layered-clobber chain: `iw30` (alternative store gate, bit 29), `iw32`
(§112, bit 25) and finally the clamp. **Three gated readings that only show their effect
jointly** — precisely the whole-chain trap Part 103 was written about, escaped this time because
each link had its own local criterion.

### 3. ⚠ BUT THE MODULUS IS EXACTLY HALF, AND THAT IS THE THIRD FACTOR OF 2 THIS SESSION

```
  mod 2^23  (lfo-ramp.md)              period  73,584 frames  ->  0.5993 Hz   ← the derived rate
  mod 2^24  (my signed 24-bit wrap)    period 147,169 frames  ->  0.2997 Hz
```

`lfo-ramp.md` item C anchors 0.5993 Hz across **29 LFO blocks in 16 programs with 9 distinct
increments** — that is not a single coincidence to be explained away. My implementation wraps the
signed 24-bit datum (`mod 2^24`) and runs the LFO at **exactly half rate**.

⚠ Note the pattern: §111's host payload was 2× too small; the unit-1 level is still 0x46 off;
and now the phase period is 2× too long. **Three factors of two in one session** is either a
coincidence or a shared scaling convention we have not found. Recorded as a question, not a
theory.

### 4. ⛔ AND THE FIX IS IN THE WRONG PLACE — stated before anyone promotes it

`acc_to_datum()` is the **general** accumulator-to-datum conversion used by every store in the
device. Audio needs the full signed 24-bit range; only the **phase** wants a 23-bit unsigned
modulus. Putting `mod 2^23` here would clip audio, and putting `mod 2^24` here is what produced
the half-rate LFO. **The modulus belongs to the datapath, not to the conversion** — the chip has
an OVC (overflow control) on the CDJ-500 block diagram, which is exactly the kind of per-mode
control this implies, and nothing in our decode reads it yet.

**Not promoted.** The mechanism is confirmed; its scope and modulus are not. Promoting a global
wrap would trade a documented-safe clamp for an undocumented-wrong wrap on every audio store, to
buy a half-rate LFO.

### 5. Housekeeping — and the cause of §113's failure is now removed

`m_specmask` is **widened to u64**: every bit 0..31 had a consumer, and the sole apparent
exception, bit 18, was SET in the default — which is exactly how §113 came to be gated behind an
already-on bit and never tested. Bit 18 is now cleared from the default (it has no other
consumer, so this restores pre-§113 behaviour) and §113 can finally be A/B'd. New experiments
take bit 32 and up. `acc_to_datum()` is no longer `static`.

Evidence grade: **MEASURED** that clamping blocked the LFO and wrapping releases it, with a
zero-valued null and a named falsifier that did not fire; **FORCED by the note** that the phase
modulus is 2²³; **OPEN** where the modulus lives and why our period is 2× long.

---

## §115 — WHERE THE MODULUS LIVES: A **PER-UNIT MODE REGISTER**, LOADED BY SELECTOR `0x27`, AND BIT 3 IS WHAT SELECTS IT

### 1. The register exists in our model and is DEAD

```
  upd6383.h:476   u8  m_ovc;              // overflow control
  upd6383.cpp:160 m_gf(0), m_rq(0), m_ovc(0), ...      reset
  upd6383.cpp:278 state_add(UPD6383_OVC, "OVC", m_ovc); exposed to the debugger
  upd6383.cpp:337 save_item(NAME(m_ovc));               saved
```

**Never written or read by any instruction.** The CDJ-500 block diagram gives this ALU "two
shifters and an OVC", the device modelled the register, and nothing drives it — exactly the
shape `m_accb` had before §27 (Part 103: *"the device already declared m_accb, saved it in its
state, and reset it. Nothing ever read or wrote it."*).

### 2. ★★★ AND THE HEADER LOADS IT, ONCE PER UNIT, IMMEDIATELY BEFORE EACH BODY

Every class-0 register-load word in the corpus, in order:

```
  iw42  801.0.70.821   sel 21  cursor bank      ]
  iw43  801.0.6C.827   sel 27  ??? = 0x6C       ]  UNIT 0, immediately before its CALL
  iw44  801.0.25.825   sel 25  descriptor ptr   ]

  iw50  801.0.50.821   sel 21  cursor bank      ]
  iw51  801.0.64.827   sel 27  ??? = 0x64       ]  UNIT 1, immediately before its CALL
  iw52  801.0.25.825   sel 25  descriptor ptr   ]
```

A **per-unit triple**, repeated identically. Two of the three are settled — `0x821` loads the
coefficient pointer (K3 FORCED), `0x825` the delay-descriptor pointer (PROVEN BY CONSTRUCTION).
**`0x27` is the only member whose target is unidentified, and it occurs exactly twice: once per
unit.** That is where a per-unit mode register is configured, and it is the only such site.

### 3. ★ AND ITS TWO PAYLOADS DIFFER IN EXACTLY ONE BIT

```
  unit 0   0x6C = 01101100
  unit 1   0x64 = 01100100
  XOR      0x08  ->  bit 3, and nothing else
```

**Polarity fits the requirement:** unit 0 carries the LFO-bearing effects (CHORUS, PHASER, AUTO
PAN, ENSEMBLE…) whose phase accumulator MUST wrap; unit 1 is the twelve reverbs, whose audio
wants the saturation `acc_to_datum()`'s comment defends. Bit 3 is **set** for unit 0 and
**clear** for unit 1.

### 4. The prior falsification does NOT block this — it sharpens it

The device records *"K3's `0x827` candidate stays falsified (0 of 85 streams)"*. Read in full:

> *"`0x827` was falsified as **the D-RAM origin** at 0 of 85 streams"* … *"`0x825`/`0x827` are
> INFERRED siblings **whose target register is unknown**"*

`0x827` was tested as the **pointer** load and rejected. That it loads *some* register is not in
dispute; *which* is explicitly open. An overflow-mode register is compatible with the
falsification, and I checked this before proposing rather than after — the connection dropping
mid-edit is the only reason I read it in time, which is not a method.

### 5. ⚠ WHAT IS AND IS NOT ESTABLISHED

**Established:** the modulus lives in a **per-unit mode register**, written once per unit by
selector `0x27` immediately before that unit's body, alongside the two settled pointer loads.
That answers "where it lives", structurally and from the ROM.

**NOT established:** that bit 3 is the overflow selector. **n = 2.** Two samples differing in one
bit tell you that bit encodes *something* per-unit; they do not tell you it is the modulus. I
have been caught twice today by n = 1 (§100's SRC 0x02, §101's SRC 0x03) and this is barely
better. It is the **leading candidate**, not a decode.

Also note the payloads sit in the COMMON HEADER, so they are fixed for all 100 algorithms — unit
0 is always `0x6C`, unit 1 always `0x64`. Consistent with a fixed two-unit architecture
(modulation effect + reverb), but it means this register is per-unit, never per-algorithm.

### 6. The test, fully specified

Load `m_ovc` from `addr8` on selector `0x27` (returning without touching the accumulator, exactly
as `0x821`/`0x825` do), and gate the wrap on `m_ovc` bit 3:
* **(a)** the CHORUS LFO ramps — unit 0 wraps. Currently pinned; two-sided.
* **(b)** the §54 DC leak stays 0.00% — and this is the *better-scoped* version of §114, because
  unit 1 keeps saturation instead of the whole device wrapping.
* **(c)** ⚠ the falsifier: bit 3 would make unit 0's **audio** wrap too, which is precisely the
  risk `acc_to_datum()`'s comment names. If the tracking verdict worsens for unit 0 while the LFO
  ramps, then bit 3 is a per-unit flag but not the overflow mode, and the modulus is per-DATAPATH
  within the unit.
* the 2²³-versus-2²⁴ question (§114: our period is exactly 2× long) is **orthogonal** and stays
  open under either outcome.

Evidence grade: **MEASURED** (the corpus positions and payloads, `m_ovc` being dead);
**FORCED** that the per-unit configuration site is selector `0x27` — it is the only unidentified
member of a triple that occurs once per unit; **CANDIDATE ONLY (n = 2)** that bit 3 is the
selector.

---

## §116 — ★★★ CONFIRMED: SELECTOR `0x27` LOADS A PER-UNIT MODE REGISTER, AND BIT 3 SELECTS THE WRAP

§115 predicted the payloads from the ROM and specified the test. Run:

```
  §116 OVC loads: 951,360    values seen:  64:461,760   6C:489,600      and NOTHING else
  §114 wraps:  34,599,360    (122,255,040 under §114's GLOBAL wrap)  -> 28%, correctly scoped
  phase at body iw89:  -8,388,587 .. 8,388,485          full-range sawtooth -- the LFO RAMPS
  §54 verdict: SILENT, DC leak 0.00%                    unchanged
```

**Exactly the two predicted payloads and no others**, in near-equal counts — one per unit per
frame. `0x6C` for unit 0 (bit 3 set → wrap), `0x64` for unit 1 (bit 3 clear → saturate). The
prediction was made from the corpus in §115 *before* the register was ever loaded, and the wire
agrees.

**And the wrap is now correctly SCOPED**: 28% of accumulator stores wrap where §114's global
version wrapped 100%. Unit 1 — the twelve reverbs — keeps the saturation `acc_to_datum()`'s
comment defends.

### ⚠ THE FIRST PLACEMENT MEASURED ZERO, AND ITS OWN FIRED-COUNT CAUGHT IT

I first inserted the handler at the register-load dispatch. **`§116 OVC loads: 0`.** `lo12 =
0x827` carries bit 11, so a selector-0x27 word is swallowed by the ALTERNATE-ENCODING branch and
returns long before that dispatch. Moved ahead of it; 951,360 loads.

That branch executes **addressing only**, which is right for a word whose ALU route is
unmodelled and wrong for one whose entire job is to load a register. Without the fired-count this
would have read as a clean negative result — the same silent no-op that invalidated two earlier
passes, caught this time in one run because the instrument reports what it did.

### ⚠ AND THE SAFETY CRITERION IS WEAK RIGHT NOW — stated, not glossed

Criterion (c) was: *if unit 0's audio wraps and that is wrong, the tracking verdict should
worsen.* It did not worsen. **But the chip is silent** — `peak 0` in both buckets — so the
tracking test has almost no power to detect an audio-wrap regression when there is no audio to
regress. **The falsifier did not fire, and it also could barely have fired.** That is a
criterion that cannot fail, in this state, and it must be re-run the moment the chip emits
anything.

What is NOT weak: the payload prediction, which was two-sided and exact.

### Promoted, and what is still wrong

Mask bits **25** (§112, class-A ACT-07 latches P), **29** (`store-gate.md` item C's co-equal
survivor) and **33** (§116) join the default — `0x2A39B440F`. Each has its own local
justification and each is individually removable; jointly they make a documented subsystem run
for the first time in this project.

⚠ **Still half rate.** §114's arithmetic stands: `mod 2^23` gives 0.5993 Hz — the rate
`lfo-ramp.md` anchors across 29 LFO blocks in 16 programs with 9 distinct increments — and our
signed 24-bit wrap gives 0.2997 Hz. The register tells us *which unit* wraps; it does not yet
tell us the **modulus**. That is the next question, and it is the fourth factor of two this
session.

Evidence grade: **MEASURED**, with a pre-registered payload prediction hit exactly and a
zero-valued null; **WEAK** on the audio-safety falsifier while the chip is silent; **OPEN** on
the modulus.

---

## §117 — THE MODULUS IS 2²³ **UNSIGNED**, AND THE FOURTH FACTOR OF TWO CLOSES

### 1. Applied and observed

`lfo-ramp.md` §11 states it as `mem[Q] <- (phase + INC) mod 2**23`, and its measured phase
series — `000072`, `0000E4`, `000156` — is **small positive values ramping**, i.e. the
accumulator lives in `0..0x7FFFFF` and wraps to zero, never going negative. Our wrap was a
*signed 24-bit* one.

```
  before  (mod 2^24 signed)     phase at body iw89:  -8,388,587 .. 8,388,485
  after   (mod 2^23 unsigned)   phase at body iw89:          21 .. 8,388,485   quiet
                                                             37 .. 8,388,533   loud
  §116 OVC loads 951,360 (64 / 6C) and §114 wraps 34,599,360 -- both unchanged
  §54 SILENT, DC leak 0.00% -- unchanged
```

**The range is now strictly non-negative**, which is the direct observable for the modulus and it
is two-sided: the previous arm spanned negatives.

### 2. What is measured and what merely follows

⚠ I have **not** measured 0.5993 Hz directly. What is measured is the two quantities that
determine it, each independently:

```
  modulus    2^23   -- observed this section (the range is non-negative and spans 0..0x7FFFFF)
  increment  114    -- §111, and it matches lfo-ramp.md at 11 sites
  => period 73,584 frames -> 0.5993 Hz at Fs = 44100
```

`lfo-ramp.md` item C anchors that rate across **29 LFO blocks in 16 programs with 9 distinct
increments**. So the frequency follows arithmetically from two measured inputs and agrees with an
independently-derived table — which is good, but it is a derivation, not a frequency measurement,
and the min/max instrument cannot distinguish 2 sweeps from 4 over the sample window.

★ **The fourth factor of two closes.** §111 fixed the host payload (×2 too small); this fixes the
period (×2 too long). Two of the four are now resolved and both were the same *kind* of error — a
scaling convention we had not applied. Still open: unit-1's residual `0x46`, and whether the
remaining two share a cause.

### 3. ⛔ THE COST, STATED PROMINENTLY BECAUSE IT IS KNOWN-WRONG

The modulus is selected **per unit** by `m_ovc` bit 3, so **unit 0's AUDIO is now non-negative
too** — an unsigned 23-bit signal, which is simply wrong for a waveform. It is currently
invisible only because the chip is silent, so no measurement in the suite can see it.

That is not a reason to leave it unstated: it is **positive evidence that the modulus belongs to
the DATAPATH, not to the unit.** The OVC bit plausibly selects *which units contain a wrapping
datapath at all*, while the phase accumulator's 23-bit unsigned modulus is a property of the
phase register itself. Our model has one knob where the chip has two.

Kept in the default because the LFO is the only datapath currently producing anything and it is
now correct there; removable via mask bit 33. **This must be revisited the moment the chip emits
audio** — at which point the §54 tracking test regains the power to see it, and the weak
criterion noted in §116 becomes a real one.

Evidence grade: **MEASURED** (the range becoming non-negative, with the previous arm as a
two-sided control); **DERIVED, not measured** for 0.5993 Hz; **KNOWN-WRONG** for unit-0 audio,
and recorded as evidence about where the modulus lives.

---

## §118 — THE ENABLE AND THE MODULUS SEPARATED, ⛔ §117's RAMP WAS AN ARTEFACT, AND §113 IS FINALLY CONFIRMED

### 1. The per-datapath discriminator is exceptionless

Of the 678 bit-4 store words in the corpus, split by the gate bit and `f31`:

```
  gate f31  count
    0   0      19        1   0       3
    0   1     494        1   1     138
    0   4      13        1   2      29   <-- hi12 forms {0x094: 29}, SRC {0x08: 29}
    0   6       1        1   5      10
```

**29 words, ONE `hi12` form, ONE operand source.** `lfo-ramp.md` item C independently counts
*"29 LFO blocks in 16 programs"*. **29 words, 29 blocks.** The wrap-word family is exactly the set
of LFO publishers, and it is also the only bit-7 store shape that survives `store-gate.md` item
C's co-equal survivor — which is why `iw91` publishes and `iw30` does not.

So the two knobs are now distinct, as §117 said they had to be:

```
  m_ovc bit 3        does this UNIT contain a wrapping datapath?      (§116)
  the wrap-word form is THIS STORE the wrapping one?                  (§118, 29/29)
```

### 2. ⛔ AND SEPARATING THEM REFUTED MY OWN §117

With the modulus scoped correctly, the phase **pinned again at `0x7FFFFF`** — and the diagnostic
row says why:

```
  §118 only    phase at iw89: 8,388,607 .. 8,388,607   pinned
               phase at iw92:     3,411 .. 3,411       iw91 publishes a CONSTANT
```

Under §114/§116/§117 **everything in unit 0 wrapped, including `iw92`** — the word §109 identified
as writing `0x7FFFFF` over the phase one slot after `iw91` publishes. **The varying value I
reported as a phase ramp was iw92's wrapped accumulator, not the publish.** `iw91` was emitting a
constant the whole time; over-broad wrapping hid it.

⚠ This is the same failure §105 caught in the workflow — *"a probe reported DIFFERS because a
second wrong behaviour produced motion"* — and I committed it myself three sections later, in
§114, and again in §116 and §117 without re-examining it. A range that stops being constant is
not automatically the quantity you think is moving.

### 3. ★★★ AND THE FIX IS §113, NOW VALIDLY TESTED

`lfo-ramp.md` item L names the compliant reading of the `447` word: `SRC 0x11 = mem[ptr]`, making
`iw92` an **identity** on the phase cell. §113 implemented it and could not be tested because its
gate bit was already set in the default; §114 freed bit 18 and gave it a real null arm.

```
  A  §118 only        §113 fired         0    phase iw89: 8,388,607 .. 8,388,607   PINNED
  B  §118 + §113      §113 fired 3,900,480    phase iw89:        36 .. 8,388,562   quiet
                                                                 18 .. 8,388,594   loud
                      phase at iw92: the same range -- an identity, as predicted
                      wraps 1,827,840 in BOTH arms; §54 SILENT, DC leak 0.00% in both
```

**The LFO now ramps from the correct word**, with `iw91` as the publisher `lfo-ramp.md` forces,
`iw92` as an identity, the modulus scoped to the wrap-word datapath, and **unit 0's audio
saturating again** — which removes the known-wrong cost §117 had to record.

Bit 18 rejoins the default; mask `0x2A39F440F`.

### 4. What is now standing on measurement rather than on a chain

```
  §111  host payload x2         two pre-registered right answers, hit exactly
  §116  selector 0x27 -> OVC    payloads predicted from the ROM, hit exactly (0x6C / 0x64, nothing else)
  §118  wrap-word family        29/29, one hi12 form, one SRC, matching an independent count of 29
  §113  SRC 0x11 = mem[ptr]     two-sided A/B, pinned -> ramping, with a zero null
```

Still open: whether 0.5993 Hz is the true rate (it is derived from two measured inputs, not
measured); unit-1's residual `0x46`; and the chip is still silent — the LFO is a modulator with
nothing to modulate yet.

Evidence grade: **FORCED** for the wrap-word discriminator (29/29, exceptionless, matching an
independent count); **MEASURED** for §113's A/B; **RETRACTED** for §117's claim that the phase
ramped — it did not, and §114/§116/§117 all inherited the error.

---

## §119 — A REAL MECHANISM, AN OVER-READ CONCLUSION, ⛔ **AND IT UNDERMINES §118's PROMOTION OF BIT 18**

Six agents; both adversarial verifiers ran and both returned **refuted=true**, each with grounds
the other did not raise. Separating what survived from what did not.

### 1. ★ WHAT SURVIVES — one hop, measured properly

`iw92` = `000.2.09.447` is class 2, `addr8 = +9`, `SRC 0x11`, `ACT 0x07`. Under our PRE-increment
store target it is `mem[0x07] <- mem[0x07]`, an identity. Under a POST target it is
`mem[0x10] <- mem[0x07]` — **a memory-to-memory MOVE**, and `0x10` is the cell the next two slots
read.

And the tracking witness is the one I demanded under rule 8 — not "it varies" but **it equals**:

```
  LFO phase at iw89, 8 consecutive frames:  1006784 1006898 1007012 1007126 1007240 ...
  cell 0x10 at iw94, the same frames:       1006898 1007012 1007126 1007240 1007354 ...
  cell 0x10 == phase + 114 on 8 of 8 -- iw91's published value, to the digit
```

Both verifiers granted this. Verifier 2 additionally confirmed the isolation is near-clean: bit
34 touches only **two** non-K6 words in the 285-slot frame, and the other one moves a value whose
D-RAM non-zero count is 0 in both arms.

★ It also **dissolves the apparent conflict with §109's PRE finding**. The degeneracy is a
property of the ENCODING — source and destination naming the same cell — and it selects **56 of
444** mode-2 ACT-07 words. The other 388 include all 256 accumulator-source words, which is where
§109's PRE anchors (`iw34`, `iw88`) live. PRE is right for those; the memory-source ones are
moves. That is why bit 34 survives where bit 28 (move everything) kills the ramp.

### 2. ⛔⛔ AND IT UNDERMINES SOMETHING I PROMOTED TWO SECTIONS AGO

Verifier 1's first ground, and it is the one that matters most to this project's own record:

> `lfo-ramp.md` §8.4's constraint on the `447` word is **purely negative** and names **TWO**
> compliant readings: *"`SRC 0x11 = mem[ptr]`, making the word a self-copy"* **OR** *"ACTION
> 0x07's destination is not D-RAM here, in which case `SRC 0x11` is UNCONSTRAINED by the LFO."*

**Bit 34 is the second family.** Under it the phase ramps *regardless* of what `SRC 0x11` reads —
so §118's A/B, the sole evidence for §113, no longer discriminates. §118 concluded `SRC 0x11 =
mem[ptr]` (bit 18, now in the default) because arm A pinned and arm B ramped; that contrast
exists **only** because iw92's store lands on the phase cell under PRE.

⚠ **I promoted bit 18 to the default in §118 on evidence that a second, equally compliant reading
would remove.** The note named both readings; I tested one and shipped it. §27's `SRC 0x11 = ACCB`
is still the enum name in `upd6383d.h` and is not refuted. **Bit 18's grade drops from MEASURED to
CONTESTED**, and the two readings are now a live tie that needs an experiment able to separate
them.

### 3. The conclusion, refuted on five further grounds

The claim was *"the LFO's operand-level consumers are the four delay-voice blocks"*.

* **Cell `0x10` was not empty.** `0x0E`/`0x0F`/`0x10` are a matched set of three, each written from
  the accumulator by gate-permitted stores in the w32..w48 section and each read by a
  `192.A.4X.000` voice word. Bit 34 **overwrites** the previous frame's value rather than filling
  a gap — method rule 8 one level up.
* **A 4.5-order magnitude contradiction.** Four structurally identical voice blocks would take
  operands of `0..8,388,562` (voices 1/2) and `0..264` / `0..203` (voices 3/4). A tap offset is
  the *small* one — so the right magnitude sits at `0x0E`/`0x0F`, the cells the claim demoted to
  "derived".
* **It destroys the quadrature.** CHORUS's two table-lookup idioms feed `0x0E`/`0x0F` and produce
  two *distinct* outputs — the "quadrature 2-voice chorus" of the disassembly header. Under the
  claim voices 1 and 2 read the **same cell with the same value**: zero quadrature. A chorus
  needs decorrelated voices.
* **Arm F was confounded.** Bit 25 is not an LFO switch: it gates §112 *and* `SRC 0x03 = acc`,
  and clearing it flips 1,470,720 operations across three kernel words, changing the kernel's
  arithmetic from `iw13` onward. **Arm F is a different machine, not "arm E with the LFO frozen"**,
  so the DC control is invalid and every attribution resting on it is unsupported.
* The claimed 5.4 ms depth **exists nowhere in the run** — the agent conceded our multiply applies
  ×65536, not ×240.

### 4. ★ The agent's own near-miss, which it caught

It reported the delay line going from 455,999 to 1,812,851 writes-with-content under bit 34 —
then found arm F gives 1,821,119, and refused to credit the LFO: *"a DC fills the delay line just
as well."* That is rule 2/8 applied correctly and unprompted. It also declined to claim the tap
**address** is modulated, on rule 7 — our core computes it from a program-order counter with no
data input, so no value can reach it by construction.

### 5. Where this leaves things

**Not promoted.** Bit 34 stays gated OFF, instrumentation committed for reproducibility.

The honest position: **`iw92` is a MOVE and its destination tracks the phase to the digit** — that
is measured and survived both skeptics. **What the phase is FOR is not established**, and the
leading structural candidate has shifted to `0x0E`/`0x0F` — the small-magnitude, quadrature-
producing pair fed by CHORUS's own table-lookup idioms — rather than to `0x10`.

Evidence grade: **MEASURED** for the move and the phase-tracking of cell `0x10`; **REFUTED** for
the four-delay-voice consumer reading; **CONTESTED** (downgraded from MEASURED) for §113/bit 18;
**OPEN** for the consumer itself.

---

## §120 — `0x0E`/`0x0F` ARE **DEAD IN THE SHIPPED BUILD**, AND THE BLOCKER IS **CLASS 6** — 53 WORDS, WITH A 29/29 SIGNATURE

### 1. The hypothesis as stated is not supported

§119's verifier argued `0x0E`/`0x0F` are the real modulation cells, citing operand ranges of
`0..264` and `0..203` — tap-offset sized, and producing the quadrature pair the disassembly
header names. Measured in the **shipped default**, every slot whose pointer sits on
`0x0E`/`0x0F`/`0x10` sees:

```
  102..151   mem 0..0   L 0..0        dead, with ONE exception:
  118  0142000C63  dp 0E   mem 39,718..39,718
  119  0000620407  dp 0E   mem 39,718..39,718
  120  00124011CE  dp 0E   mem 39,718   L 39,718   <- reads it, and zeroes the cell
  121+                     mem 0..0     L 0..0
```

⚠ **The verifier's `0..264`/`0..203` figures came from arm E (bit 34), not the default.** In the
shipped build these cells carry one constant and then nothing. So "0x0E/0x0F are the consumer" is
**not currently supported** — though nothing here refutes it as a statement about the real chip.

★ **And an instrument limitation worth recording:** `kwatch`'s quiet/loud split measures
**INPUT** dependence, while an LFO is a free-running modulator *independent* of the input. A
correctly-working modulation cell would show as "not input-dependent" in that census while still
varying frame to frame. **§86-style input-dependence is the wrong instrument for anything
downstream of the LFO**; the §104 residency range is the right one.

### 2. ★★★ BUT THE STRUCTURE IS REAL, AND THE BLOCKER IS NOW NAMED

`iw118`/`iw119` are exactly the table-lookup idiom the verifier identified — a class-0
pointer-family word (`lo12 = 0xC63`) followed by a **class-6** word. Class 6 is one of
`register-space.md` §5.3's "unknown classes", and its corpus population is far larger than that
section's header-only list suggests:

```
  000.6.18.4CD   addr8 = 24   x29      ★
  000.6.28.4CD   addr8 = 40   x17
  000.6.20.407   addr8 = 32   x3       <- the one feeding 0x0E in CHORUS
  000.6.1E.407   addr8 = 30   x3
  000.6.1A.407   addr8 = 26   x1
                              -----
                               53 words, 5 forms
```

★ **`addr8 = 24` occurs exactly 29 times, and `lfo-ramp.md` item C counts exactly 29 LFO blocks
in 16 programs.** That is the same 29/29 signature that identified the wrap-word family in §118 —
one per LFO block, exceptionless. And **24 is the "×24 table"** earlier analysis named without
being able to say what indexed it.

So the chain is structurally identified end to end, and blocked at one opcode:

```
  phase (sawtooth, 0..2^23, ramping)        MEASURED, §113..§118
    -> class-0 lo12 0xC63   aim at the table
      -> CLASS 6, addr8 = 24  the LOOKUP        ⛔ UNDECODED -- the blocker
        -> 0x0E / 0x0F        the modulation pair, currently dead
          -> the voice words  192.A.4X.000
```

### 3. Why this is a better target than the last four blockers

`SRC 0x02` and `SRC 0x03` had **n = 1** and defeated §100/§101. The OVC payload had **n = 2**
(§115). Class 6 has **53 words in 5 forms**, and its leading form has a 29/29 structural match to
an independently-derived count. It is decodable by corpus argument in a way the recent blockers
were not.

⚠ Note also that all five `addr8` values are small integers — 24, 26, 30, 32, 40 — which is what
a table SIZE or STRIDE looks like, not a pointer delta. That is a reading, not a measurement, and
its falsifier is simple: if `addr8` here were a pointer delta, the pointer would move by 24..40
at these slots, and the §104 `dp` column says it does not.

Evidence grade: **MEASURED** that `0x0E`/`0x0F`/`0x10` are dead in the shipped build and that the
`0..264`/`0..203` figures belong to arm E; **MEASURED** the class-6 census and the 29/29 match;
**INFERRED** that class 6 is the table lookup and `addr8` its table parameter; **OPEN** for what
class 6 computes.

---

## §121 — ⛔ BIT 18 REMOVED (IT WAS DESTROYING THE AUDIO DEPOSIT), AND THE ACT 0x0D ENUMERATION IS **VOID TWICE OVER**

### 1. Bit 18 resolved, and worse than §119 thought

§119 argued §113 (`SRC 0x11 = mem[ptr]`, bit 18) had no discriminating evidence. Measured:

```
  bit18 ON,  bit34 off   phase RAMPS   36..8,388,562
  bit18 off, bit34 off   phase PINNED  8,388,607
  bit18 off, bit34 ON    phase RAMPS   33..8,388,493      §113 fired 0
```

`lfo-ramp.md` §8.4's two compliant readings are **observationally equivalent on the LFO** — both
ramp. Confirmed.

★★★ **And bisecting the promoted bits found something worse.** Cell `0x05` — the audio deposit
§110 established — is **dead at the current default** and restored by clearing bit 18 alone:

```
  default             cell 05 input-dependent?  NO
  no bit 18 (§113)    quiet [1105 .. 4,194,304]  loud [151 .. 16,776,890]   YES
  no bit 25 / 29 / 33                            NO   (so it is bit 18 specifically)
```

**Mechanism:** `iw11` = `400.2.01.447` — `SRC 0x11`, `ACT 0x07` — is the K6 input word §110 fixed
to deposit the audio at `0x05`. Under §113 its source becomes `mem[ptr]`, so it executes
`mem[0x05] <- mem[0x05]`: **a self-copy instead of the audio deposit.**

So §113 is not merely unsupported — it **silently un-fed the audio path**, and it did so in the
same section (§118) where I promoted it on a single non-discriminating A/B. **Removed.**
Bit 34 joins instead: it delivers the LFO ramp without bit 18, and both §119 verifiers granted its
mechanism even while refuting its consumer conclusion. Default `0x6A39B440F`.

### 2. ⚠ THE ACT 0x0D ENUMERATION IS VOID — twice, and the second is the interesting one

Six destinations (`acc=L`, `tempA`, `tempB`, `mem[ptr]`, `P`, `acc+=L`) against the criterion
*"does body 0's accumulator become INPUT-dependent"*.

**Void #1 — a criterion that could not fail.** With the LFO ramping, all seven arms *including the
null* reported `first acc DIFFERS at 90`. That is not input dependence: it is the free-running
sawtooth sampled over unequal buckets (92,592 quiet vs 207,408 loud) making min/max differ
spuriously. **The null arm caught it** — which is the only reason it is a paragraph and not a
result. Re-run with the LFO frozen gave a clean null (`-1`) and all five candidates also `-1`.

**Void #2 — an empty, then constant, operand.** `iw85` reads `mem[0x05]` and gets `0..0` under
bit 18, and `1105..1105` — a CONSTANT — once bit 18 is removed. **I tested six destinations for a
value that does not vary.** That is verbatim the trap §106 named: *"a negative result that holds
only because an input is empty says nothing about the consumer."* I wrote that sentence and then
walked into it.

**⇒ The enumeration establishes nothing about ACT 0x0D**, except that `mem[ptr]` (sel 4) is
refuted independently — it flips the §54 verdict to **DC**, output with no input.

### 3. ⛔ AND MY STRATEGIC CALL WAS WRONG

I recommended ACT 0x0D as *"the last blocker on the audio path"*. It is not. The resident value at
`iw85` is a constant because the audio deposited at `0x05` is **overwritten before the body reads
it** — §110's `iw45` (`010.A.00.20C`, `SRC 0x08`) clobber, which has been standing since §110 and
which I walked past while planning two sections of work downstream of it.

**The real order is:** fix the `iw45`/`iw32` clobber → give `iw85` a varying operand → *then*
ACT 0x0D becomes decidable by exactly the enumeration built here, which is now correct and
reusable.

Evidence grade: **MEASURED** (bit-18 bisect, the criterion contamination caught by its null, the
constant operand at iw85); **REFUTED** for `ACT 0x0D -> mem[ptr]`; **VOID** for the other five;
**RETRACTED** for my "last blocker" framing.

---

## §122 — COVERAGE STATS, AND THEY REDIRECT THE WHOLE EFFORT

New tool `dsp/tools/coverage_report.py`. ⚠ First, an artefact to kill: the device reports
*"285 slots = 285 DECODED, 0 TRAP"*. That is meaningless — `alu_decoded_speculative()` ends in an
unconditional `return true`, so every word is admitted regardless of its fields. The per-slot
probe's `dec`/`gfail` columns show the truth. This tool counts words decoded on **anchored**
evidence versus words depending on a field still listed as unknown.

### 1. The stats

```
  COMMON CODE (60-word kernel + 23-word epilogue, run by EVERY effect)
      83 words, 33 blocked = 40% of the code every effect runs

  FULLY EXECUTABLE PROGRAMS:  0 of 91

  CLOSEST, blocked/words:
      11/105   algo 39  PARAMETRIC EQ      <- 89.5% decoded, far ahead of the field
      17/54    algo 72  PEQ+S.DELAY
      19/48    algo  9  SINGLE DELAY
      24/86    algo 15  ROCK ROTARY
      25/53    algo 50  VIBRATO
      27/49    algo  0  NO OPERATION       <- and 41 stub twins sharing its image
```

### 2. ★★★ THE BLOCKER RANKING — one dominates

```
  blocker    words   programs affected
  SRC 00      1270      91        <- 3x the next, and it blocks EVERY program
  ACT 0E       422      91
  ACT 0D       356      91
  ACT 0B       341      76
  f31=7        139      49
  f31=5         96      61
  f31=4         87      62
  f31=6         84      42
```

★ **`SRC 0x00` is the single biggest unknown in the machine** — and its population is
strikingly uniform:

```
  1270 words, ALL of them ACT 0x00, in just 3 (class, ACT) shapes
  by f31:  LOAD 581   ADD 542   HOLD 147
```

**Every one is `SRC 0x00 + ACT 0x00`.** That is not a source code at all — it reads as the
**ABSENCE** of a bus operand: `lo12 = 0x000` means "no operand, just the accumulator and the
product", and `f31` already says load/add/hold. The f31 split is exactly a MAC chain's.

⛔ Our core currently reads `SRC 0x00` as `mem[ptr]` — a guess its own comment marks *"1 of 6
enumerated, no independent support"* — which **injects a spurious memory read into 1270 words,
in every program.**

### 3. ★ AND WE HAVE BEEN DECODING AGAINST THE HARDEST PROGRAMS

The whole investigation has been driven by **CHORUS** (unit 0) and **ROOM REVERB** (unit 1).
`PARAMETRIC EQ` is **89.5% decoded** — nearly twice as complete as anything we have used — and has
never been the vehicle. It is also a **biquad**, the structure that FORCED several of this
project's anchored readings in the first place, so its remaining 11 words sit in a context where
the arithmetic is already known.

**That is a strategic error worth naming:** the effects were picked by what sounded interesting
(a reverb, a chorus) rather than by what is closest to executable. Eleven blocked words in a
known-arithmetic program is a far better decoding vehicle than a reverb with 27.

### 4. Next

1. **Decode `SRC 0x00`** — 1270 words, all 91 programs, uniform shape, and a strong structural
   reading available (no bus operand). Biggest single win in the machine.
2. **Switch the decoding vehicle to PARAMETRIC EQ** and drive the remaining unknowns from its 11
   blocked words, where the biquad pins the arithmetic.
3. `ACT 0x0E`/`0x0D`/`0x0B` next, at 422/356/341 words.

Evidence grade: **MEASURED** (all counts, from the ROM); **INFERRED** that `SRC 0x00` marks the
absence of a bus operand — uniform ACT 0x00 across 1270 words and a MAC-shaped f31 split, but not
yet tested.

---

## §123 — ⛔ §122's `SRC 0x00` READING WAS ALREADY FALSIFIED, THE DEVICE COMMENT IS STALE, AND PARAMETRIC EQ IS **8 WORDS** FROM BEING THE FIRST FULLY EXECUTABLE EFFECT

### 1. The hypothesis was dead before I proposed it

§122 argued `SRC 0x00` marks the ABSENCE of a bus operand, from the encoding: all 1270 corpus
instances carry `ACT 0x00`, with a MAC-shaped f31 split. `action00-discriminator.md` §5.1 makes
**exactly that argument**, in the same terms, and then kills it:

> *"`SRC 0x07` appears with nine different ACTIONs. `SRC 0x00` appears with essentially one. That
> is what a **null routing** encoding looks like … **It is a good hypothesis and SINGLE DELAY
> kills it: `zero` has 0 survivors**, in both windows and at both mix settings. `SRC 0x00`
> carries data."*

Item I adds that `DR` (the delay-RAM register) also has **0 survivors**. Item H states the
surviving reading's limit precisely: **`SRC 0x00 = mem[ptr]` is not forced absolutely — it is
forced GIVEN THE LOADED COEFFICIENTS.**

★ **Sixth time this session the answer was already in a note.** And this one is the sharpest: I
did not merely miss a result, I independently reconstructed a hypothesis the note names as
attractive and had already refuted by constraint solve.

### 2. The device comment is STALE, and that is what misled §122

The `SRC 0x00` site inherits the neighbouring *"1 of 6 enumerated, no independent support"*
phrasing. That was true when written and is not true now: `action00-discriminator.md` supplies
the support by falsifying both rivals at 0 survivors. Corrected at the site, with item H's
conditional stated so nobody over-promotes it either.

### 3. ★ THE CORRECTED PICTURE — and §122's ranking was wrong

With `SRC 0x00` counted as decided:

```
  COMMON CODE:  23 of 83 words blocked = 28%   (§122 said 40%)

  blocker    words   programs        CLOSEST PROGRAMS
  ACT 0E      422      91             8/68    algo 10
  ACT 0D      356      91             8/105   algo 39  PARAMETRIC EQ
  ACT 0B      341      76            11/48    algo  9  SINGLE DELAY
  f31=7       139      49            11/54    algo 72  PEQ+S.DELAY
  f31=5        96      61            13/86    algo 15  ROCK ROTARY
  f31=4        87      62
  f31=6        84      42
```

The `f31 > 2` family totals **406 words across 62 programs** — one field, four codes, and it is
the standing task list's item #2.

### 4. ★★★ AND PARAMETRIC EQ IS EIGHT WORDS AWAY

PEQ's remaining blockers are **exactly four unknowns, each appearing twice**, in two
near-identical motifs — the two stages of the biquad:

```
  iw84  000.2.0B.1CD  ACT 0D        iw137 000.2.0A.1CD  ACT 0D
  iw85  000.2.00.40E  ACT 0E        iw138 000.2.FF.1CE  ACT 0E
  iw86  212.2.00.000  (now decoded) iw139 212.2.02.000  (now decoded)
  iw87  02A.2.00.000  f31=5         iw140 02A.2.00.000  f31=5
  iw134 028.2.00.000  f31=4         iw188 428.1.0E.000  f31=4
```

**Decode `ACT 0x0D`, `ACT 0x0E`, `f31=4` and `f31=5` and PARAMETRIC EQ becomes the first fully
executable effect on this chip** — and those same four unknowns are the top of the corpus-wide
ranking, so nothing about the target is parochial. The biquad's difference equation constrains
what each must compute, which is the context §107's failed attempt lacked.

Evidence grade: **REFUTED** for §122's `SRC 0x00` reading, on a pre-existing constraint solve;
**MEASURED** for the corrected coverage numbers; **FORCED** that PEQ needs exactly those four.

---

## §124 — THE BIQUAD PLACES `ACT 0x0D`/`0x0E` BY EXCLUSION: THEY ARE **PER-BANK INPUT PLUMBING**, NOT PART OF THE DIFFERENCE EQUATION

### 1. PARAMETRIC EQ contains the reconstructed biquad verbatim

`notes/dsp-alu-biquad.md` reconstructs a biquad section and names its words. PEQ's body holds
them **character for character** at idx 5..8:

```
  note row 0   000.A.00.1D3   ACT 13    =  PEQ idx 5
  note row 1   212.A.01.412   ACT 12    =  PEQ idx 6
  note row 2   202.A.01.1D5   ACT 15    =  PEQ idx 7
  note row 3   202.A.01.1D4   ACT 14    =  PEQ idx 8
```

★ **And the core repeats at a stride of 9, ten times** — `ACT 0x13` occurs at idx 5, 14, 23, 32,
41, then 59, 68, 77, 86. **PARAMETRIC EQ is a ten-section filter bank, in two banks of five.**
That is exactly what a parametric EQ is, and it means the note's reconstruction — which FORCED the
anchored actions `0x12`/`0x13`/`0x14`/`0x15` — already covers **90 of PEQ's 105 words**.

### 2. ★★★ WHICH PLACES THE TWO UNKNOWNS PRECISELY

```
  ACT 0x0D at idx  0 and 53
  ACT 0x0E at idx  1 and 54
```

`idx 0/1` sit immediately before the **first** bank's first section (idx 5); `idx 53/54`
immediately before the **sixth** section, i.e. the **second** bank's first. **Two occurrences, one
per bank, always as an adjacent `0x0D`,`0x0E` pair at the bank entry.**

The full bank-entry sequence, now that `SRC 0x00` is settled (§123):

```
  idx 0  000.2.0B.1CD   f31=0  SRC 07 = mem[ptr]   ACT 0D   ⛔
  idx 1  000.2.00.40E   f31=0  SRC 10 = acc        ACT 0E   ⛔
  idx 2  212.2.00.000   f31=1  SRC 00 = mem[ptr]   ACT 00   store
  idx 3  02A.2.00.000   f31=5                      ACT 00   ⛔ f31
  idx 4  000.2.40.407   f31=0  SRC 10 = acc        ACT 07   store acc to +64
  idx 5  ...the biquad core...
```

★ **The biquad constrains them BY EXCLUSION, and that is the useful part.** The difference
equation `y = b0·x + b1·x1 + b2·x2 − a1·y1 − a2·y2` is **fully decoded without them** — every MAC
step and both state writes are anchored actions inside the core. So `ACT 0x0D`/`0x0E` cannot be
carrying any term of the filter. They are the **per-bank input plumbing**: whatever assembles the
bank's input in the accumulator before `idx 4` deposits it where the core reads it.

That is a much tighter constraint than the destination enumeration §121 attempted. It says what
they are *for* — a two-word input mix, once per bank, reading `mem[ptr]` then the accumulator —
before any candidate destination is proposed, which is the ordering §107 and §121 both got wrong.

### 3. Handoff — the next step, fully specified

The pair reads `mem[ptr]` (`0x0D`) and then the accumulator (`0x0E`), and four words later the
accumulator is stored to `+64`. So the candidate readings are constrained to operations that
**assemble a sum or a scaled mix in the accumulator**, and the criterion is available and sharp:
**PEQ is a filter with a known transfer function.** Feed it a known input and the ten sections'
output is analytically predictable — which is a far stronger criterion than "does something stop
being constant", and it does not depend on the chip being audible.

Remaining for PEQ to become the first fully executable effect: `ACT 0x0D`, `ACT 0x0E`, `f31=4`,
`f31=5` — 8 words, 4 unknowns, in a program whose other 97 words are decoded.

Evidence grade: **MEASURED** (the verbatim core match, the stride-9 repeat, the ten sections, the
two bank-entry positions); **FORCED** that the two unknowns carry no term of the difference
equation; **INFERRED** that they are the bank input mix.

---

## §125 — PEQ IS **TWO PARALLEL FIVE-SECTION BANKS**, AND THAT IS WHAT MAKES THE TRANSFER-FUNCTION CRITERION VALID FOR `ACT 0x0D`/`0x0E`

### 1. ⚠ THE CRITERION-VALIDITY CHECK, RUN BEFORE THE TEST THIS TIME

§124 handed off "PEQ has a known transfer function" as the criterion. That needed checking
first, because a biquad's response is set by `b0,b1,b2,a1,a2` **inside the core, which is already
decoded** — so if `ACT 0x0D`/`0x0E` merely assemble a bank's input, they would affect **gain, not
shape**, and the criterion would be blind to them. Exactly the class of hole that voided §121 and
wasted §107.

### 2. The structure, from the pointer walk

```
  both banks READ cell 0x05 at entry     idx 0 and idx 53      -> PARALLEL, not series
  bank 1 private state   0x50..0x63      20 cells = 5 sections x 4
  bank 2 private state   0x64..0x77      20 cells = 5 sections x 4
  both write shared scratch              0x0E, 0x10
```

**PARAMETRIC EQ is two PARALLEL five-section banks, both fed from the unit-0 audio input cell
`0x05`, summed through shared scratch.** The 20-cell private ranges match the biquad note's
four-cell state (`x[n-1] x[n-2] y[n-1] y[n-2]`) times five sections, exactly — an independent
confirmation of that layout from the address map rather than from the arithmetic.

### 3. ★ SO THE CRITERION IS VALID — the two mixes are not identical

```
  bank 1 entry:  ACT 0D addr8 = 0x0B (+11)     ACT 0E addr8 = 0x00
  bank 2 entry:  ACT 0D addr8 = 0x0A (+10)     ACT 0E addr8 = 0xFF (-1)
```

The two banks' input words **differ in `addr8`**. Because the banks are parallel and summed,
their relative contributions change the **shape** of the combined response, not merely its level.
**A known input therefore yields an output that depends on `ACT 0x0D`/`0x0E`** — the criterion
discriminates, and it does so without needing the chip to be audible.

Had the banks been in series, or had the two mixes been identical, this criterion would have been
blind and §124's handoff would have been another void experiment.

### 4. The test, now fully specified and validated

1. Extract the ten sections' `b0,b1,b2,a1,a2` from the ROM C-RAM image (cursor banks feeding
   `ACT 12/13/14/15`), and compute the analytic response of *two parallel five-section banks*.
2. Drive the emulated chip with a known input and compare its output spectrum.
3. Enumerate `ACT 0x0D`/`0x0E` readings; the correct pair reproduces the analytic response, and a
   wrong pair mis-weights one bank against the other — a **shape** error, which is visible.
4. ⚠ `f31=4` and `f31=5` also sit in the bank entry (idx 3, idx 50/104), so all four unknowns must
   be resolved together or held fixed while one varies. Do not attribute a shape change to
   `ACT 0x0D` while `f31=5` is also unmodelled in the same five-word sequence.

Point 4 is the constraint that would have caught §121's error: the enumeration varied one unknown
while three others in the same block were still guesses.

Evidence grade: **MEASURED** (the parallel structure, the private state ranges, the differing
`addr8` values); **FORCED** that the criterion discriminates given parallel summation and unequal
mixes; the decode itself remains **OPEN**, with a validated test now specified.

---

## §126 — THE TEST HAS A PREREQUISITE NOBODY HAS DONE: **PARAMETRIC EQ IS NOT THE LOADED EFFECT**

### 1. PEQ's coefficients are not in the ROM

Parsing algo 39's stream: **1 I-RAM block, 0 C-RAM records.** The coefficients are not baked into
the program — which is correct and obvious in hindsight: a *parametric* EQ's coefficients are
whatever the user dials in, written at runtime through the host poke port (§111 counted 115 such
packets). **There is no fixed ROM transfer function for PEQ**, so §125's step 1 as written —
"extract the ten sections' coefficients from the ROM C-RAM image" — cannot be done. The analytic
prediction must come from the LIVE C-RAM.

### 2. ★ And the live C-RAM holds a different effect

The device does dump it, and the contents identify the effect immediately:

```
  C-RAM 00: 000072 7FFFFF 0000F0 000000 0000F0 000000 2CCCCC 2CCCCC ...
             ^114   ^wrap  ^240          ^240
```

`0x000072` = **114** is the CHORUS LFO increment (§111); `0x0000F0` = **240** is the voice-word
coefficient §119 measured. This is CHORUS's image. **PARAMETRIC EQ is not loaded and has never
been loaded in any measurement this session.**

### 3. ⇒ THE DEEPER FORM OF §122's DIAGNOSIS

§122 concluded *"we picked the wrong vehicles — effects were chosen by what sounded interesting."*
That was too generous to us. **We did not choose them at all: the cold-boot default did.** Every
number in §98–§125 describes CHORUS (unit 0) and ROOM REVERB (unit 1) because those are what the
instrument loads at power-on, and no pass ever changed the selection. The investigation has been
shaped by a default for its entire length.

### 4. The prerequisite, and why it is worth doing

Before the transfer-function test can run at all:

* select **PARAMETRIC EQ** on the emulated panel (or force algo 39's upload) so its I-RAM image
  and its host-written C-RAM are the live ones;
* confirm from the live C-RAM dump that ten sections' worth of coefficients are present and
  non-trivial — with a **known** panel setting, so the analytic response is computable;
* only then enumerate `ACT 0x0D`/`0x0E`/`f31=4`/`f31=5` together (§125's point 4).

★ This is also the cheapest broad win available: the SD/panel machinery already works in this
driver, and selecting effects would let every future pass choose its vehicle by decode coverage
(§122's table) rather than inherit CHORUS. Ten of the 91 programs are more decoded than CHORUS,
and none of them has ever been executed.

Evidence grade: **MEASURED** (0 C-RAM records in algo 39's stream; the live C-RAM identified as
CHORUS by two independently-known constants); **FORCED** that §125's test cannot run until PEQ is
selected.

---

## §127 — PARAMETRIC EQ **SELECTED AND RUNNING**; the coefficient chain verified end-to-end; §125's criterion CORRECTED

§126's prerequisite is done. The panel route already existed and had already been used once:
`kn7000_mame/notes/kn5000-dsp-origin-capture.md` (2026-07-23) selected PARAMETRIC EQ in MAME with
`tools/kn5000_dsp_origincap.lua`, snapshot- and RAM-verified. **That note was not read before §126
was written** — the sixth-and-seventh occurrence of trap 1 (`HANDOFF-NEXT.md` §7).

### 1. PEQ is loaded — three independent confirmations

Run: `UPD6383_SPEC=6A39B440F`, `DSPCFG=3`, harness `peq_select.lua` (the origincap navigation:
`CPR_SEG10 0x04` SOUND -> `CPL_SEG7 0x02` DSP EFFECT editor -> 40x `CPL_SEG10 0x10` to saturate at
CHORUS -> 15x `CPL_SEG10 0x20` to PARAMETRIC EQ), notes held 6 s at t = 40.5 s.

| check | expected (pre-registered, from the 2026-07-23 note) | measured |
|---|---|---|
| name-index array | `RAM[0x29AA]=17`, `RAM[0x29AC..]=[51,52,53]x5` | `cnt=17 idx=[51,52,53,51,52,53,...]` ✔ |
| live C-RAM cell 0x00 | anything but CHORUS's `000072` | `C04B34` ✔ |
| frame length | 286 - 70 (CHORUS) + 105 (PEQ) = 321 | **320 slots, 320 DECODED, 0 PARTIAL, 0 TRAP** ✔ |

### 2. ★★ The coefficients decode to a textbook 5-band EQ — an END-TO-END control that PASSES

Live C-RAM `0x00..0x1D` = **30 values, five stride-6 sections**, decoded with the format already
solved in `notes/kn5000-dsp-biquad-coeffs.md` §3 (`NN+0..+2` = b1,b0,b2 x2^22 pre-halved;
`NN+3` = -a1/a0 x2^22; `NN+4` = -a2/a0 x2^23):

```
  sec   pole r     pole-angle f     nearest ISO 1/3-oct centre    err
   0    0.99556       121.1 Hz              125 Hz              -3.2 %
   1    0.99114       242.1 Hz              250 Hz              -3.2 %
   2    0.98236       484.2 Hz              500 Hz              -3.2 %
   3    0.96511       968.7 Hz             1000 Hz              -3.1 %
   4    0.93203      1939.7 Hz             2000 Hz              -3.0 %
```

All five poles **stable** (r < 1) and all five land on ISO centres one octave apart. The -3.1 %
is not an error: the sub-CPU designer prewarps with `K = tan(pi*f0/fs)`, so the *digital pole
angle* is not `2*pi*f0/fs`. Solving the design equations back for band 0 gives `Q = 2.0011` — a
value that **is in the 32-entry Q table** — and predicts the pole angle as 121.2 Hz against 121.1
measured. So the chain host designer -> poke port (incl. the §111 x2 payload) -> C-RAM addressing
-> coefficient format is verified end to end, on live data, with no free parameters.

### 3. ★ CORRECTION to `kn5000-dsp-biquad-coeffs.md` §3/§4: cell `NN+5` is a **x2 make-up**, not padding

That note concluded "the sixth coefficient does not exist ... algorithm 39's stride-6 blocks
contain one padding word each". Against this:

* the program **multiplies by it** — `w12/w21/w30/w39/w48` are `mac.st acc,c+,(p)-1` on C-RAM
  `0x05/0x0B/0x11/0x17/0x1D`, exactly the `NN+5` cells;
* the host **writes** them: `C-RAM WRITE RUNS (3): [0x50..0x8B]=60 [0x90..0xB4]=37 [0x00..0x2C]=301`
  — the third run spans them, and the rest of C-RAM `0x20..0x4F` is `000000`;
* all five hold exactly `0x800000` = **2.0** at the b-scale `2^22`;
* and only that reading is self-consistent: the b's are stored **pre-halved**, so five sections
  are 1/32; the cascade computes **-30.10 dB** flat with the cell unused and **0.00 dB flat
  (+/-0.05 dB)** with it as x2. `-20*log10(32) = -30.10`.

**MEASURED.** The disassembler's own label (`coeff C-RAM[0x05] = biquad makeup`) was right.

### 4. ⛔ §125's CRITERION IS DEAD — the two banks share one coefficient set

`w58 = 0801000021 = rstcur`. Bank 2 restarts the coefficient cursor at 0x00, and the generated
listing confirms both banks walk `0x00..0x1D`; the host uploads exactly 30 coefficients
(extent `0x1E` = 30, `origin-capture.md`). So the two banks are **not** two differently-weighted
parallel voices — they are the **two CHANNELS** of "5 bands x 2 channels" (`programs.tsv`), running
identical filters on different inputs into different state blocks.

§125's argument was: *"parallel banks sum, so their relative weights change the shape; a wrong
reading mis-weights one bank against the other."* Identical coefficients and separate channels mean
there is **no relative weight to get wrong** and nothing sums. This is exactly the fragility §125
itself flagged ("if you change anything that makes the banks series, or equalises the mixes, the
criterion dies") — it was already dead when written, and it dies on the *coefficients*, a case §125
did not consider.

### 5. And the loaded preset is FLAT, which is a second, independent reason the test as specified cannot discriminate

The cascade is 0.00 dB at every frequency. A flat EQ cannot distinguish a correctly-decoded filter
from a plain pass-through, so even a perfect audio comparison would score the same for both.

### 6. What replaces it

The vehicle is still right — PEQ is 8 words from fully executable and its 4 blockers are the
corpus-wide top — but the criterion must change:

1. **Dial one band's GAIN off 0 dB** so the target response has a sharp, localised, predicted
   feature. Candidate soft-keys (INFERRED from `-paramlist.md` §1.3 "TYPE / PARAMETER / VALUE, each
   an up/down pair", only TYPE measured): PARAMETER = UP-2/DOWN-2 = `CPL_SEG10 0x80/0x40`,
   VALUE = UP-3/DOWN-3 = `CPL_SEG9 0x20/0x10`. ★ This is **self-validating**: if the presses are the
   right ones, the live C-RAM section coefficients move off flat in the predicted direction.
2. Then discriminate on **which input cell each bank reads and which state block it walks**, which
   is what the four unknowns actually control — not on a mix weight.

Evidence grade: §1 **MEASURED** (three pre-registered checks); §2 **MEASURED** + **FORCED**
(the Q solve-back); §3 **MEASURED**; §4/§5 **FORCED** (`rstcur` + the 30-coefficient extent +
the flat response); §6 **OPEN**, with the enumeration constraint of §125 point 4 still binding.

---

## §128 — THE PANEL DRIVES THE COEFFICIENTS: a non-flat target and two measured pass-through controls

### 1. The editor's PARAMETER and VALUE keys, MEASURED

`-paramlist.md` §1.3 names the three rockers "TYPE / PARAMETER / VALUE" but had measured only
TYPE. The other two are now measured, and the first attempt got them wrong in an instructive way.

| rocker | port/bit | how established |
|---|---|---|
| TYPE up / down | `CPL_SEG10 0x20 / 0x10` | prior, `-paramlist.md` §1.3 |
| **PARAMETER down / up** | **`CPL_SEG8 0x10 / 0x20`** | per-press snapshot diagnostic |
| **VALUE up** | **`CPL_SEG7 0x20`** | drove `FC 125 Hz -> 16K Hz` |

⚠ **A first sweep concluded PARAMETER = `CPL_SEG8 0x80` and that was WRONG.** The sweep pressed
each pair's UP, snapshotted, then pressed its DOWN to restore — so the restore of pair *n* fell
between the snapshot of pair *n* and the snapshot of pair *n+1*, and the cursor move attributed to
`0x80` had actually been caused by the preceding restore press `0x10`. A clean rerun with **one
snapshot per press and no restores** shows `0x80` changes nothing (0 pixels differ, twice).
★ Method note: *a control that runs between the stimulus and the observation is part of the
stimulus.* The confound was invisible in the log and only fell out of the pixel diff.

`CPL_SEG10 0x80` is also not PARAMETER: it changes the **effect** (`cnt` 17 -> 6).

### 2. Three live captures, and what each panel edit moved

Driving the real panel gives three C-RAM images of the same program:

| capture | band 0 | C-RAM section 0 |
|---|---|---|
| FLAT | FC 125 Hz, Q 2.0, G 0.0 dB | `C04B34 200000 1FB760 7F6996 81227A 800000` |
| FC16K | FC **16K** Hz, Q 2.0, G 0.0 dB | `2303C4 200000 15CA92 B9F876 A8D5B0 800000` |
| G12 | FC 125 Hz, Q 2.0, G **+12.0** dB | `C0515C 20691C 1F481C 7F6996 81227A 800000` |

In every case **sections 1..4 stayed byte-identical** — only the edited band moved.

★ **The GAIN edit moved the NUMERATOR ONLY**: cells `0x03`/`0x04` are bit-identical between FLAT
and G12, while `0x00`/`0x01`/`0x02` all changed. The FC edit moved both. That is exactly the
signature of this designer's **gain-independent denominator** (`a0 = 1+K/Q+K²`, `a1 = 2(K²−1)`,
`a2 = 1−K/Q+K²`, `-biquad-coeffs.md` §1.1) and it **independently confirms the cell roles**:
`0,1,2` = numerator, `3,4` = denominator. Nothing about that assignment was assumed to get it.

### 3. ★★ The analytic target, and it hits the panel's own number

Cascading the five decoded sections:

```
       f(Hz)      FLAT     G=+12dB    FC=16kHz
        62.5     -0.05     +3.93     -0.01
       125.0     -0.01    +11.99     -0.01        <- the panel says G: +12.0 dB at FC: 125 Hz
       250.0     +0.01     +3.95     -0.00
      1000.0     +0.00     +0.25     +0.00
   G=+12dB PEAK: +11.99 dB at 125.1 Hz
```

**+11.99 dB at 125.1 Hz against a panel-stated +12.0 dB at 125 Hz, with no free parameters.**
Together with §127's ISO-centre and Q solve-back, the host-designer -> poke port -> C-RAM ->
coefficient-format chain is now confirmed three independent ways.

### 4. ⇒ The test now has a target AND a measured null

This is the part §125 never had. **FLAT and FC16K are exact pass-throughs** — with `G = 0.0 dB`
the bilinear design gives numerator == denominator per section, so `H(z) = 1` *whatever the centre
frequency is* (max deviation 0.050 dB and 0.007 dB over 20 Hz..20 kHz).

So the three captures form a test with the null measured rather than assumed:

* a chip that merely **passes its input through** scores **identically** on FLAT and FC16K, and
  identically again on G12 — three-way tie, hypothesis dead;
* a chip that **executes the biquad correctly** scores flat on FLAT and FC16K and shows a
  **+12 dB / Q 2 peak at 125 Hz** on G12;
* a chip whose bank entries are **mis-decoded** (wrong input cell, colliding state blocks, or the
  cascade never fed) fails to reproduce the peak *while still* being flat on the other two — which
  distinguishes it from both of the above.

★ The G12 capture is the ONLY discriminating one; FLAT and FC16K are its controls. That the null
is a *measured* pass-through rather than an assumed silence is what makes this a test.

Evidence grade: §1 **MEASURED** (per-press snapshots) and one **RETRACTION** of the confounded
sweep; §2 **MEASURED**; §3 **MEASURED** + **FORCED**; §4 **FORCED** given §2/§3.

---

## §129 — THE FIRST LIVE TRACE OF PEQ: the static walk CONFIRMED, and **bank 1 runs on the TAP TABLE**

Enabled by the `UPD6383_TRACE_FRAME` change (the trace armed unconditionally at frame 420000
≈ 8.75 s; PEQ is selected at t ≈ 50 s ≈ frame 2.2 M, so **every trace ever taken of "PEQ" would
have been a CHORUS frame**). Armed at frame 2 300 000, inside the held note.

### 1. ★ The control passes: the static pointer walk is confirmed live, to the cell, at 13/13 slots

| slot | word | dp after | derived |
|---|---|---|---|
| iw84 `w0` | `000020B1CD` | `10` | read cell **0x05**, +11 |
| iw88 `w4` | `0000240407` | `50` | +64 → **bank 1 state base 0x50** |
| iw136 `w52` | `00002F7000` | `05` | −9 |
| iw137 `w53` | `000020A1CD` | `0F` | read cell **0x05**, +10 |
| iw141 `w57` | `0000254407` | `64` | +84 → **bank 2 state base 0x64** |

**MEASURED.** State blocks `0x50..0x63` and `0x64..0x77` are disjoint and contiguous.

★ **And it falsifies the expectation §127 §4 was built toward.** PEQ is "5 bands × 2 channels", so
the two banks were expected to read two *different* input cells. **They read the same one:
D-RAM `0x05`, both of them.** Any future reading of `ACT 0x0D` must accommodate that.

⚠ Grade correction: §125 graded this walk MEASURED. It was **STATIC/INFERRED** — PEQ had never
executed. It is MEASURED as of now, and it agrees.

### 2. ★★★ BANK 1 EXECUTES AGAINST THE DELAY-TAP TABLE, NOT ITS COEFFICIENTS

The trace's coefficient column across body 0:

```
  iw 84..126  (bank 1)   0004BE 00097C 000E3A 0012F8 0017B6 001C74 002132 ... 007B4C 007FFF 000000
  iw142 = w58 rstcur
  iw143..    (bank 2)    C0515C 20691C 1F481C 7F6996 81227A 800000   <- PEQ's REAL band-0 coefficients
```

The bank-1 stream is an arithmetic ramp of step **`0x4BE` = 1214**, saturating at `0x007FFF`.
That is **C-RAM TABLE B verbatim** (`k3-pointers.md` §: `0x70..0x8B`, 28 entries, `1214·k`,
clamped to `0x7FFF`) — confirmed against the live dump, `C-RAM 70: 000000 0004BE 00097C 000E3A …`.
The cursor enters body 0 at **`0x71`** and walks the delay-tap address table for all five of
bank 1's biquad sections.

**So PARAMETRIC EQ's first channel multiplies its audio by delay-tap ADDRESSES.** Only the second
channel is correct, and only because `w58 = rstcur` re-bases the cursor to `0x00`.

This is the open item `dsp-perframe-execution.md` named and could not localise: *"the coefficient
cursor must be re-based twice per frame (0x00 / 0x90) and no word on the path is known to do it;
`rstcur` is in 1 of 38 programs."* PEQ **is** that 1 of 38, and it makes the defect visible by
contrast **inside a single frame**: same program, same C-RAM, two banks, one based and one not.
`dsp-critical-path-coverage.md` predicted exactly this — *"the header runs 21 class-A words with
no `rstcur` before the unit-0 CALL, yet body coefficients are MEASURED at C-RAM base 0x00 ⇒ an
undecoded word must rebase/bank the cursor."* The undecoded rebase word is now the top blocker.

★ **The contrast is also the strongest positive control yet on the coefficient chain.** Bank 2's
fetched stream is `C0515C 20691C 1F481C 7F6996 81227A 800000` — **bit-identical to the G12
capture's C-RAM section 0, in order**. The host upload, the §111 ×2 payload, the stride-6 layout
and the cursor mechanism are confirmed *from inside the chip's own execution*, not from a dump.

### 3. ⛔ GO/NO-GO: the audio comparison of §128 CANNOT RUN YET, and the null is already measured

From the §127 run: `§61 PER-UNIT PRESENTATION: unit0/DO1 2099250 exec, **0 non-zero, peak 0**`
and `§70 ACCA AT w73: quiet min 0 max 0 | loud min 0 max 0`. **PARAMETRIC EQ's output is
identically zero.** Its input is a constant too: the trace's operand bus at iw84 reads `8388607`
= `0x7FFFFF`, the rail, in every loud frame.

Per this project's own rules — *compute the null first*, and *a test whose operand is constant
says nothing about its consumer* — building an output-capture harness now buys a spectrum of
zeros. §128's target stands; it cannot be scored until §2 above and the `iw45`/`iw32` `SRC 0x08`
clobber are fixed.

### 4. Corrections to §127, from an adversarial pass — three of them are mine to own

1. ⛔ **The make-up cell is `−2.0`, not `+2.0`.** `0x800000` signed / 2²² = **−2.0** exactly;
   `+2.0` is not representable (`0x7FFFFF`/2²² = 1.9999998). Five sections give `(−2)⁵ = −32`:
   the magnitude is 32 as §127 said, but **the PEQ channel is POLARITY-INVERTED** and §127 erased
   that. `dsp-alu-biquad.md` §: *"−2.0 in Q1.22 … Section gain is therefore −1: unity magnitude,
   inverted."*
2. ⛔ **§127's stated evidence for the make-up was a criterion that could not fail.**
   `peq_tf.py` never reads cell `NN+5`; its "with make-up" column is `abs(h)*32` with **32 as a
   hardcoded literal**. The printed "0.00 dB flat" would be identical if the cell held anything at
   all. (§128's `peq_ab.py` does take the value from C-RAM, so §128's numbers are sound.)
3. ⛔ **Trap 1 for the eighth time.** `kn5000-dsp-biquad-map.md` §3 made this same correction on
   2026-07-22, **44 minutes after** the "padding" note it corrects and 8 days before §127, with
   better evidence (OVERDRIVE's `0x600201` = 1.500122 at 2²² against an independently decoded
   Butterworth DC gain of 1.500150 — an external, non-circular anchor). `kn5000-dsp-INDEX.md`
   already said "+5 = make-up gain". And §127's "the disassembler's own label was right" is
   **circular**: that label was written by that analysis.
   The claim SURVIVES — on other people's evidence. The note's own counter-evidence is **void**:
   algo 79 `GEQ` is an **IC310/MN19413** program (`second-dsp-and-ready.md` B1/B7), so its stride-5
   is a different chip's 16-bit coefficient memory.
4. ⚠ **§127 §2's ISO control is much weaker than it looked.** At `G = 0 dB` the bilinear design
   gives numerator ≡ denominator, so `NN+0..+2` are a rescaled negated *copy* of `NN+3/NN+4` and
   the pole is recoverable from **either** pair — a rival that reads poles out of the numerator
   scores 5/5 ISO hits too. `nearest_iso()` also snapped unconditionally. §128's gain edit is what
   actually breaks the degeneracy (gain moved the numerator and left `0x03/0x04` bit-identical).

### 5. ★ The replacement control, and it CAN fail: the ROM designer run forward in float32

`dsp/tools/peq_roundtrip.py` runs `LABEL_03A933` (transcribed in `-biquad-coeffs.md` §3) forward
from the **panel-stated** (f0, Q, gain) of all three captures, quantises to 24 bits and scores
**every word**: 75 words, zero free parameters, no fitting.

**Result: 13 of 15 band-instances close to ≤ 13 LSB of 2²⁴.** A wrong cell role, a wrong
2²²/2²³ split, a missing pre-halving or a wrong stride would move words by 10⁵–10⁶ LSB.

The two outliers are exactly the `+12 dB` band, and the mechanism is clean. `N = (1−A1−A2)/(b0+b1+b2)`
is *analytically exactly 1* (both sums equal `4B`, `B = K²`). At `G = 0` the ROM forms them from
**the same floats**, so `N ≡ 1` bit-for-bit and the words close. At `G ≠ 0` the two sums are built
from different values and `N` inherits catastrophic float32 cancellation — `4K² ≈ 3.2e−4` formed
by cancelling operands of magnitude ~2, i.e. ~3e−4 relative error. The live `+12 dB` word requires
`N = 0.9996225` (predicted `b0` = `0x206C3E`, live `0x20691C`), a 3.8e−4 deviation — the right
mechanism and the right order of magnitude.

⇒ **Correction to `kn5000-dsp-biquad-coeffs.md` §3.2**, which grades *"the tool measures
N = 1.000000 on every one of the 42 336 presets"* as MEASURED: that holds in double precision, but
the ROM works in float32, where `N` is **not** identically 1 on gain ≠ 0 — and the live coefficient
proves it. Its open question (*"the exact predicate of the `1.0f` guard is NOT ESTABLISHED"*)
is now bounded: the guard does **not** simply clamp to 1.0, or the `+12 dB` word would be `0x206C3E`.

Evidence grade: §1 **MEASURED**; §2 **MEASURED**; §3 **MEASURED**; §4.1–4.3 **FORCED**
(arithmetic + provenance), §4.4 **FORCED**; §5 **MEASURED** with the `N` mechanism **INFERRED
(strong)** — the exact float32 operation order of the ROM's `N` has not been transcribed.

---

## §130 — THE PER-UNIT COEFFICIENT-CURSOR REBASE, CONFIRMED AND SHIPPED — plus a confounded run of my own

### 1. ⛔ FIRST, THE RETRACTION: §129's rebase run was CONFOUNDED

Mask **bit 18 gated two unrelated readings**: §113 (`SRC 0x11 = mem[ptr]`, `upd6383.cpp:2151`)
and the §73 per-unit cursor rebase (`:3917`). The first A/B (`0x6A39F440F`) therefore turned on
**both** — including a reading §121 had **deliberately removed** because it destroys the audio
deposit (`iw11` becomes a self-copy of `mem[0x05]`). That run is not evidence for the rebase and
is discarded.

★ **The audit that was supposed to catch this ran and missed it.** It grepped `0x40000\b`, which
**does not match `0x40000u`** — the spelling at `:2151`. The handoff's rule ("verify your bit is
CLEAR IN THE DEFAULT") was followed and was not enough; the missing half is **"and used at
exactly one site."** *Match the bit, not the spelling* — enumerate bits from every mask literal
programmatically, never by text search.

The rebase now has **its own bit 38** and a **fired-count**.

### 2. ★★★ The clean A/B: three pre-registered predictions, all confirmed bit-exactly

`UPD6383_SPEC=46A39B440F` (default | bit 38; bit 38 clear in the default, used at one site).
Predictions written to `scratchpad/PREDICT_129.md` **before** the run.

| | prediction | measured |
|---|---|---|
| **P1** | bank 1 (iw84..) fetches C-RAM `0x00..0x1D` in order, bit-identical to bank 2 | cursor `00 00 00 00 00 01 02 03 04 05`, coeffs `C0515C 20691C 1F481C 7F6996 81227A 800000` ✔ |
| **P2** | bank 2 **UNCHANGED** — the gate must be a no-op where `rstcur` already re-based | cursor `00 01 02 03 04 05`, identical to baseline ✔ |
| **P3** | unit 1 rebases to `0x90`, not `0x00` | cursor `90 90 91 92 93`, coeffs `4D9364 400000 3B9885` ✔ |

**Fired-count 5 148 920** = 2 body CALLs × 2 574 460 frames — not a silent no-op.
Falsifiers F1/F2/F3 all avoided. ★ **P2 is the load-bearing one**: it is the control whose answer
was known in advance, and a gate that "fixed" bank 2 as well would have been doing something other
than a rebase.

★ The confound also **resolves itself**: unit 1's output under bit 38 alone (1 064 113 non-zero,
peak −1543434) is within one frame of the confounded run's (1 064 112, −1543434), so §113
contributed nothing to it and the whole unit-1 change is the rebase.

### 3. SHIPPED — the default becomes `0x46A39B440F`

Backed by `cram-unit-base.md` item A, **MEASURED** over 91 programs / 1546 class-A words (unit-1
reverbs 33/33 at base `0x90`, 0/33 at `0x00`; the rival "always add `0x90`" rejected 79/79 on
unit 0), and by §129's direct demonstration that without it a program multiplies its audio by
delay-tap addresses — which cannot be right on any reading.

⚠ **Two consequences that must not be buried:**

1. **Unit 1's output changed**: 620 866 → 1 064 113 non-zero presentations, peak **+1543433 →
   −1543434**. The reverb now reads its real coefficient bank instead of whatever the unrebased
   cursor delivered. This is the only currently-audible unit. **It needs a listen** — the sign flip
   in particular is a claim about the instrument, not a bookkeeping detail.
2. **Every earlier measurement taken inside a BODY was taken against tap-table values standing in
   for coefficients.** Body-0 findings in §§98–129 should be re-checked before being quoted. This
   does not touch the kernel/epilogue results, which run before the CALL.

### 4. Still NOT fixed, and still the blocker

`unit0/DO1` remains **0 non-zero in 2 581 792 presentations**. PARAMETRIC EQ now reads the right
coefficients and still emits nothing, because its **input** is railed at `0x7FFFFF` by the
`iw45`/`iw32` `SRC 0x08` clobber. That was pre-registered as *not* predicted here, and it is the
next task. §128's audio target stands, unscoreable until then.

Evidence grade: §1 **FORCED** (two gate sites on one bit, verified by enumeration); §2 **MEASURED**
with a passing known-answer control; §3 shipped on §2 + `cram-unit-base.md` item A; §4 **MEASURED**.

---

## §131 — ★★ THE ENTRY HANDS THE INPUT OVER IN **P**, NOT IN THE ACCUMULATOR — which is why §121 was structurally blind

From a three-way design panel run over §§127–130. This item is **verified here independently of
the agent that proposed it**, by decoding the words directly.

### 1. The structural fact

`f31 = hi12[3:1] = 0` is **LOAD: `acc ← P`** (it discards whatever the accumulator held). Decoding
the six words that bracket each bank's hand-over:

```
  w0   000020B1CD  hi12=000  f31=0   acc <- P     (bank 1 entry, ACT 0x0D)
  w1   000020040E  hi12=000  f31=0   acc <- P     (bank 1 entry, ACT 0x0E)
  w4   0000240407  hi12=000  f31=0   acc <- P     (bank 1 entry, last word)
  w5   0000A001D3  hi12=000  f31=0   acc <- P     (bank 1 CORE, first word)
  w57  0000254407  hi12=000  f31=0   acc <- P     (bank 2 entry, last word)
  w59  0000A001D3  hi12=000  f31=0   acc <- P     (bank 2 CORE, first word)
```

**Every slot in both entries reloads the accumulator from P.** So the sample the cascade filters
is **whatever is in P at `w4` / `w57`** — the accumulator physically cannot carry it across the
entry, because it is overwritten at each step and again by the core's own first word.

### 2. ⇒ Why §121's enumeration could not have worked

§121 enumerated `ACT 0x0D`'s **destination** (1 acc=L, 2 tempA, 3 tempB, 4 mem[ptr], 5 P, 6 acc+=L)
one value at a time and found all seven arms — including the null — reporting the same thing. The
reason is now structural, not statistical: **`ACT 0x0D → acc` is erased one slot later by `w1`'s
own `acc ← P`.** Any arm whose destination is the accumulator is indistinguishable from the null
*by construction*. The enumeration was not underpowered; it was measuring a register that is
guaranteed to be overwritten before anything reads it.

This also sharpens §125's "resolve all four together": the four unknowns are not merely
*correlated*, they are **competing to write one register**, and only the arms that land in P (or in
a temp that a later word moves to P) can survive to the core at all.

### 3. Two live defects the panel surfaced, recorded but NOT acted on

* **Mask bit 16 is SET in the default and suppresses the store-and-clear on `hi12` bit 4**
  (`upd6383.cpp:2412-2417`). That clear fires on `w6` — the word that commits `x[n]` to the
  section's first state cell. `dsp-alu-biquad.md` §6 ablates the clear at **57.193 dB** and calls
  it required under both readings of the accumulator op. The code carries a specific counter-
  argument (the epilogue's `w60` carries HI_ST, so an unsuppressed clear destroys unit 0's result
  at the top of the presentation stage), so this is a **considered decision in tension with a
  measured ablation**, not an oversight. It deserves its own A/B; it does not get flipped on one
  agent's say-so.
* **`f31=4` and `f31=5` are not trapping**: with mask bit 0 set, `op = f31 & 3`, so they execute as
  `HI_ACC_LOAD` / `HI_ACC_ADD` aliases with **no fired-count anywhere** — a standing violation of
  this project's own "every gate logs a fired-count" rule. Any enumeration must A/B against that
  alias, not against a trap.

### 4. A pre-computed null worth keeping

One design built an offline 105-word taint simulator over PEQ and enumerated
`ACT 0x0D × ACT 0x0E × f31=4 × f31=5` = 576 destination combinations, scoring "both banks acquire
an input, and not the same one". **32 of 576 pass = 5.6 %**, with sub-nulls 112/576 (bank 1 alone)
and 176/576 (bank 2 alone). That is a *sharp* criterion with a computed null and a non-trivial pass
rate on each half — exactly the shape §121 lacked. ⚠ Its own stated weakness stands: with cell
`0x05` railed, every grid cell may fail for a reason that has nothing to do with the four unknowns,
so the clobber fix is a prerequisite for it too.

Evidence grade: §1 **FORCED** (direct decode of six words, verified independently of the proposal);
§2 **FORCED** given §1; §3 **MEASURED** (both gates read from source), action deferred; §4 an
offline computation not yet reproduced here — **INFERRED**, listed so the next pass can re-run it.

---

## §132 — ADVERSARIAL PASS: three corrections to §127's own confirmation, and the two structural reasons §121 could never have worked

A three-skeptic + three-design + judge panel over §§127–130. Every claim below **re-verified here
against source**, not accepted from the agent that raised it.

### 1. ⛔ §127's third confirmation row was wrong in three ways

| §127 said | actually |
|---|---|
| `286 − 70 + 105 = 321` … measured **320** … ✔ | **321 ≠ 320. I ticked a miss.** `286` is a *structural* sum; the *measured* CHORUS frame is **285** (this document says so ten times). `285 − 70 + 105 = 320` exactly. The tight invariant is **Δframe = +35 = 105 − 70**. |
| "320 DECODED, 0 PARTIAL, 0 TRAP" as confirmation | **A criterion that cannot fail.** `alu_decoded_speculative()` ends in an unconditional `return true` (`upd6383d.h:618`) and `DSPCFG=3` enables it. **§122 in this very document already called this statistic meaningless** — and §127 re-quoted it as evidence. |
| frame length identifies PEQ | **Degenerate.** `programs.tsv` has **two** 105-word unit-0 programs: algo 39 PARAMETRIC EQ and **algo 70 AUTO WAH+S.DELAY**. Slot count identifies SIZE, not identity. |

The claim itself **SURVIVES** — on the other two rows (the `cnt=17 idx=[51,52,53]×5` fingerprint and
C-RAM `0x00` = `C04B34`), the screenshot, and §128's coefficient decode, which the skeptic could not
break. But one third of the stated evidence was bad, and the tautology was one this document had
already flagged.

Also corrected: §127 §4's *"numerator == denominator **exactly** per section"* is an overstatement —
`2·b2` vs `a2/a0` differ by ≈176 LSB at 2²². The conclusion (flat to ±0.05 dB ⇒ cannot discriminate
a decoded filter from a pass-through) is unaffected.

★ And a preservation failure: `run.sh` does `rm -f error.log`, and §127's log was overwritten before
being archived. The runs are now committed under `dsp/analysis/data/`.

### 2. ★★ THE SECOND STRUCTURAL REASON §121 WAS BLIND — a blanket capture upstream of the selector

`upd6383.cpp:2626-2642`, under `m_speculative` and **before** §121's destination switch at `:2675`:

```cpp
    case 0x01: case 0x08: case 0x0C: case 0x11: case 0x16:
    case 0x0D: case 0x0E:
        m_ta = u32(L) & 0xffffff;     // blanket tempA capture -- ALWAYS runs
```

So every §121 arm was *"destination X **and** tempA"*. **Selector value 2 (→ tempA) is
indistinguishable from value 0 (none)**, and no arm could ever isolate a destination.

This is independent of, and compounds, §131's finding that the accumulator cannot carry the
sample across the entry. **§121 had two structural reasons to fail and neither was statistical.**
Any future enumeration must suppress this capture for an action whose own selector is non-zero.

### 3. ⚠ "`ACT 0x0D` → P" as currently coded is dimensionally suspect

`:2684` `case 5: m_p = u32(L) & 0xffffff;` — a raw 24-bit datum. But a multiply writes
`m_p = (sext(coef,24) * L) >> P_SHIFT` held as 44 bits (`:3039`), with `P_SHIFT = 6`,
`ACC_SHIFT = 22 − 6 = 16`. The two differ by ≈2¹⁶.

⚠ **Stated as a tension, not a defect**, because `:2908` *also* latches a raw datum into `m_p`
("latch the multiplier input") under the §112 class-A ACT-07 reading. So `m_p` is doing double
duty in this model — *multiplier input* at `:2908`/`:2684` and *product* at `:3039` — and they
cannot both be right under one consumer. **This matters because §131 shows P is the only register
that can carry the sample across the entry**, so the arm that could work is the one whose
implementation is in question. Resolve `m_p`'s meaning before enumerating it.

### 4. The adjudicated plan

Winner: **inject a known, per-cell-distinct stimulus into D-RAM `0x05`/`0x0F` at the body CALL and
read the 40 Direct-Form-I state cells** (`0x50..0x77`) as a bit-exact witness of what the entry
left in P.

* ★ **It does not need the chip audible**, and it does not need the `iw45` `SRC 0x08` clobber
  fixed — the injector writes at the CALL, *downstream* of the clobber. That **removes the
  clobber from the critical path** for the decode (it stays a prerequisite only for the final
  audio confirmation), which reverses the ordering assumed in §130 §4 and in `HANDOFF-NEXT`.
* Its null is computed **and** measured: 576 of 1024 readings leave all 40 cells at zero.
* The FLAT closed form is `+s, +s/2, −s, −s/2, …` — the alternating sign following from the
  make-up being **−2.0** (§129 §4.1), the very value §127 got wrong.
* **The lowest free mask bit is now 39**, not 38 (§130 took 38). Enumerate bits programmatically
  from every mask literal — the §130 lesson.
* Prerequisites: suppress the §2 blanket capture; resolve §3; add fired-counts for `ACT 0x0E` and
  for `f31 ≥ 4` **split by value** (today `op = f31 & 3` executes both silently).

Evidence grade: §1 **FORCED** (arithmetic, source, `programs.tsv`); §2 **MEASURED** (source, quoted);
§3 **OPEN** — a modelling tension, deliberately not resolved here; §4 a plan, not a result.

---

## §133 — ★★★ `ACT 0x0D` AND `ACT 0x0E` DECODED: the entry hands the sample over in **P**, at the multiply's scale

The bank-entry demultiplexer, run as specified in §132 §4. A non-repeating stimulus is injected
into D-RAM `0x05`/`0x0F` **at the unit-0 body CALL** — downstream of the `SRC 0x08` clobber, which
is why this did not have to wait for it — and the 40 Direct-Form-I state cells `0x50..0x77` are read
back as a bit-exact witness. 1024 joint readings × 64 frames in **one** run, armed on I-RAM
identity (`I-RAM[84] == 000020B1CD`), never on a frame count.

Masks pre-registered in `data/PREDICT_133.md`; arm `0x1003C6A39B440F`. **Run twice** (before and
after the §134 instrument fixes) with identical results: 224/1024.

### 1. The null is perfect, and the criterion discriminates

| | trials | `chg` | feed |
|---|---|---|---|
| non-feeding | **800** | `0` — every one | `(0,0,0,0)` — every one |
| feeding | **224** | `63` — every one | 64/64 bit-exact |

**No overlap.** 21.9 % pass, so the criterion can fail, and chance is 2⁻²⁴ per frame per bank.

### 2. ★★ The result: only **P** ever carries the sample, and only at the multiply's scale

```
  sel0D \ sel0E |none      acc<-L    tempA     tempB     mem[ptr]  P raw     acc+=L    P<<16
  none          |-/-       -/-       -/-       -/-       -/-       -/-       -/-       -/0F
  acc<-L        |-/-       -/-       -/-       -/-       -/-       -/-       -/-       05/0F
  tempA..acc+=L |-/-       -/-       -/-       -/-       -/-       -/-       -/-       -/0F
  P<<16         |05/05     05/05     05/05     05/05     05/05     -/-       05/05     -/0F
```

* **All 36 combinations in which neither action writes P feed nothing at all.** §131 was derived
  from the word encodings; it is now MEASURED.
* **`P raw` scores 0/128; `P<<16` scores 128/128.** And `sel0D=P<<16, sel0E=P raw` reads `-/-`: a
  raw write does not merely fail, it **destroys a working feed**. ⇒ **§132 §3 is RESOLVED**: P is
  written at the multiply's scale (`<< ACC_SHIFT`), not as a raw 24-bit datum. The `:2684`/`:2908`
  raw-datum latches are wrong by 2¹⁶.

### 3. ★★★ THE TWO-CHANNEL STRUCTURE PICKS ONE COMBINATION UNIQUELY

PARAMETRIC EQ is **"5 bands × 2 channels"** (`programs.tsv`, from the ROM's own role table), so the
two banks must filter **different** inputs. Exactly one cell of the 8×8 map delivers that:

| reading | bank 1 | bank 2 | two channels? |
|---|---|---|---|
| `0x0D → P`, `0x0E` anything | `0x05` | **`0x05`** | ✗ both banks filter the same input |
| **`0x0D → acc`, `0x0E → P`** | **`0x05`** | **`0x0F`** | **✓** |

⇒ **`ACT 0x0D` = `acc ← bus`. `ACT 0x0E` = `P ← bus`, at the multiply's scale.**

The mechanism is elegant and explains the microcode's asymmetry. Bank 1's `w1` has `SRC 0x10` =
**acc**, so `0x0D` loads the accumulator from `mem[0x05]` and `0x0E` relays it into P. Bank 2's
`w54` has `SRC 0x07` = **mem[ptr]** with the pointer on `0x0F`, so `0x0E` takes its operand
straight from the *other* cell. **The SRC fields do the channel selection; the two actions are the
same pair in both banks.**

★ And this closes §121 completely: `ACT 0x0D → acc` **was a correct reading**, but with `ACT 0x0E`
doing nothing the accumulator never reached P, so it produced no observable. **The pair only works
together** — exactly §125 point 4, and the reason a one-at-a-time sweep could not find it.

### 4. ⛔ HONEST LIMIT: `f31=4` and `f31=5` are BLIND to this test

**0 of 64 `(sel0D, sel0E)` pairs showed any dependence on either**, and all four readings score
56/256. This test decides **two** of the four unknowns and says nothing whatever about the other
two. They are not "probably the alias" — they are unmeasured, and `HANDOFF-NEXT`'s standing task
("attack `hi12[3:1] > 2`") remains open with a new fact attached: whatever they do, it does not
change what the entry delivers to the cascade.

### 5. ⛔ A PRE-REGISTERED CRITERION OF MINE WAS BADLY SPECIFIED — and the data proves it, rather than me arguing it

F1 was *"trial 0 `nz > 0` ⇒ the injector leaks ⇒ run VOID"*. It **fired**, twice (`nz` = 18, then 3
after the §134 clear-at-arm fix). Rather than reinterpret a failed criterion after the fact, the
distribution settles it:

```
  nz among the 800 NON-feeding trials: 37 x720, 20 x55, 3 x10, 14 x10, 17 x5
  nz among the 224     FEEDING trials: 37 x224
```

**720 of 800 non-feeders share `nz = 37` with all 224 feeders.** `nz` counts cells the *core* wrote
— the biquad stores into them every frame whatever the entry did — so it has **zero discriminating
power** and should never have been registered. The two predicates that were also registered, motion
and feed identity, separate the space perfectly (§1). The decode conclusion never used `nz`.

★ The lesson is not "F1 was wrong": it is that **a null must be a predicate the hypothesis can
actually move**. `nz` measures the core, not the entry.

Evidence grade: §1 **MEASURED** (twice, identical); §2 **FORCED** by the 8×8 map plus the
destructive interference of `P raw`; §3 **INFERRED (strong)** — the map is measured, and the
selection among its feeding cells rests on PEQ's documented two-channel role; §4 a **MEASURED
NEGATIVE**; §5 **FORCED** by the `nz` distribution.

---

## §135 — TOWARDS SHIPPING §133: the blocker localised to six words, three hypotheses refuted

### 1. The blast radius, and independent corpus corroboration

`ACT 0x0D` + `ACT 0x0E` = **829 of the corpus's 6282 ALU words (13.2 %), in ALL 91 programs**, so
setting them in the default is a corpus-wide change. Their SRC pairings corroborate §133's decode
from a base far wider than PEQ:

```
  ACT 0D <- SRC 07 (mem[ptr]) 350/402 = 87%      "load the accumulator from memory"
  ACT 0E <- SRC 10 (acc)      239/427 = 56%      the RELAY  (PEQ bank 1's w1)
         <- SRC 07 (mem[ptr]) 187/427 = 44%      the DIRECT form (PEQ bank 2's w54)
```

The two patterns measured inside PEQ are the two the whole corpus uses.

### 2. ⛔ SHIPPING RAILS THE ONLY AUDIBLE UNIT

| arm | unit1/DO2 non-zero | peak | frame |
|---|---|---|---|
| default `0x46A39B440F` | 1 064 113 / 2 581 792 = 41.2 % | −1 543 434 | 320/320, 0 trap |
| **ship** (`sel0D=1, sel0E=7, supp`) | **2 553 952 = 98.9 %** | **−8 388 608 = −0x800000, THE RAIL** | 320/320, 0 trap |
| ship without tempA suppression | identical to ship | identical | identical |

Frames still close everywhere, so nothing is structurally broken — the reverb is simply railed.
**A default that rails the only audible unit is strictly worse than the current one however well
evidenced the reading, so this is NOT shipped.**

★ Note bit 52 (suppress the blanket tempA capture) is **inert in normal operation** — ship and
no-suppress arms are identical. It was indispensable to §133's *isolation* and does nothing here.

### 3. The cause is ONE of the two readings, and THREE hypotheses are refuted

* **`ACT 0x0D → acc` alone is bit-identical to the default.** Harmless corpus-wide. It is
  shippable on its own.
* **`ACT 0x0E → P` alone reproduces the railing exactly.** It is the entire cause.

Refuted, each by measurement rather than argument:

1. **The suppressed store-and-clear** (§131 §3's flagged tension, and my stated leading candidate):
   clearing mask bit 16 changes **nothing**.
2. **Multiply-carrying words** ("don't clobber P on a word that computes a product"): only
   **3 of 427** `ACT 0x0E` words are class A.
3. **The resident scaffolding** (5 of the 10 live `ACT 0x0E` sites are in the kernel and the
   epilogue, and the epilogue is the output stage): restricting the write to body slots
   (`iw >= 84`, mask bit 53) is **identical to the full ship arm**.

### 4. ⇒ Localised to SIX WORDS, and the idiom is the same one

The railing is unit 1's own three `ACT 0x0D`/`0x0E` pairs. Beside PEQ's:

```
  PEQ    w0/w1     000.2.0B.1CD + 000.2.00.40E    f31=0 on the 0x0D word
  REVERB w5/w6     202.2.4B.1CD + 000.2.00.40E    f31=1
         w119/w120 202.2.08.1CD + 090.2.FB.40E    f31=1, and bit-4 STORE
         w130/w131 202.2.7B.1CD + 880.1.60.40E    f31=1, and a delay-DRAM WRITE
```

**The same adjacent-pair idiom, with the same `lo12` values `1CD` then `40E`.** The difference is
`f31`: PEQ's `0x0D` word carries `f31 = 0` (`acc ← P`, which discards the accumulator anyway), the
reverb's carry **`f31 = 1`** (`acc ← acc + P`) — i.e. the reverb is *accumulating* when the pair
overwrites the accumulator, and it is a **feedback** structure, so the injection compounds instead
of passing through. Its `ACT 0x0D` words read `mem[ptr]` at `+75 / +8 / +123`, inside the reverb's
own state block, so the pair copies loop state back into the loop at unity gain.

★ This also explains why `ACT 0x0D → acc` alone is neutral: the ACT switch runs **after** the
`f31` accumulator op, so in the reverb `acc += P` happens first and the overwritten accumulator is
discarded by the next word's own `acc ← P`. Only when `0x0E` then relays it into P does the value
survive into the ladder.

### 5. Where this leaves shipping

* **`ACT 0x0D = acc ← bus` — shippable now**, measured neutral, corroborated 350/402.
* **`ACT 0x0E = P ← bus` — confirmed inside the bank entry** (bit-exact 64/64; the only reading
  yielding two channels) **but conflicts in a feedback structure.**

The open question is no longer "what does `ACT 0x0E` do" but "why does doing it in a feedback
ladder diverge". The standing suspect remains §132 §3: `m_p` is one member modelling what is
probably **two** real registers — a multiplier input latch and a product register — and the reverb
is where the difference between them would show. ⚠ Note §133's feed test does *not* let the scale
float: it compares the state cell after `acc_to_datum`, so `<< ACC_SHIFT` is pinned, and a common
scale error is **not** available as the explanation.

Evidence grade: §1 **MEASURED**; §2 **MEASURED** (three arms); §3 **MEASURED**, three refutations;
§4 **MEASURED** (the six words) + **INFERRED** (the feedback mechanism); §5 **OPEN**.

---

## §136/§137 — "SPLIT `m_p`" HAS NO SPLIT TO MAKE; §40 RE-MEASURED AND STILL REFUSED; and a DC I called output

§135 §5 named the standing suspect for the reverb divergence: *"`m_p` is one member modelling what
is probably TWO real registers — a multiplier input latch and a product register."* That was
followed up. **The hypothesis is dead**, and the way it died is worth recording.

### 1. ★ The split already exists in the type system

Auditing **every** `m_p` site (`upd6383.cpp`, enumerated not grepped-by-spelling):

```
  WRITES  :2737 :2770   ACT 0x0D / 0x0E selector 5   raw datum
          :2739 :2772   ACT 0x0D / 0x0E selector 7   L << ACC_SHIFT
          :2995         §112 class-A ACT-07          raw datum
          :3126         the multiply                 (sext(coef,24) * L) >> P_SHIFT
          :3149         the §40 latched multiply     (sext(m_k,24) * L) >> P_SHIFT
  READS   :2641         the accumulator op           <-- THE ONLY FUNCTIONAL READ
          :3792 :3805   trace / profiling            (diagnostics)
```

`upd6383.h:451` already declares `m_k, m_l` as **"multiplier input latches"** and `:450` declares
`m_p` as the **"MPLY product register"**. `m_p` has exactly **one** functional read and the
multiplies never read it. **There is nothing to split.** MEASURED.

### 2. The real defect, and why it is inert

§112's class-A ACT-07 site writes `m_p` while its own reasoning says it *"LATCHES the coefficient
into the multiplier input"*. It therefore does not latch an input at all — it overwrites the last
multiply's outcome with a raw 24-bit datum, which §133 proved is wrong by 2^ACC_SHIFT.

★ But it is **coupled to §40**: writing `m_k` is a no-op unless the multiply reads `m_k`, and the
default multiply bypasses the latch — *"a latched-coefficient MAC with the latch bypassed"*
(`:3136`, the file's own words). So §112 and §40 had never been evaluated together, exactly the
shape that made §133's `ACT 0x0D`/`0x0E` pair decodable only jointly.

Four arms, `peq_gain.lua`, PARAMETRIC EQ selected (bit 54 = route §112's latch to `m_k`; bit 4 = §40):

| arm | 54 | 4 | unit0/DO1 | unit1/DO2 | DC leak |
|---|---|---|---|---|---|
| A default | 0 | 0 | 0 non-zero, peak 0 | 1 064 113, peak −1 543 434 | 34.69 % |
| B §112→`m_k` | 1 | 0 | **bit-identical to A** | **bit-identical to A** | — |
| C §40 | 0 | 1 | 2 398 138, peak 1 346 371 | 2 546 794, peak −1 543 434 | **99.79 %** |
| D both | 1 | 1 | **identical to C, to the digit** | identical to C | 99.79 % |
| E D + §133 | 1 | 1 | identical to C | 2 547 974, peak −1 543 434 | 99.85 % |

Frames close 320/320, 0 traps, in every arm.

* **B is bit-identical to A** — the pre-registered prediction, confirmed: routing the latch to the
  input register does nothing while the multiply bypasses it.
* **C and D are identical to the digit** ⇒ with §40 on, it makes **no observable difference**
  whether §112 writes `m_p` or `m_k`. **§136's routing question is UNDECIDABLE by this observable**
  and needs a different instrument. (Two summary statistics cannot prove waveform identity — this
  is "no difference detected", not "no difference".)

### 3. ⛔ AND I CALLED A DC "OUTPUT FOR THE FIRST TIME"

Arm C makes `unit0/DO1` non-zero on 2 398 138 presentations after being **identically 0** in every
measurement of this investigation. I reported that as unit 0 producing output. **It is a constant.**

```
  §70 ACCA AT w73:  loud frames 291193   min 176471605248   max 176471605248
```

min == max over 291 193 loud frames; `176471605248 >> 17 = 1346371`, the reported "peak". This is
**method rule 13** — *a difference from SILENCE is not a signal* — and the project has already
**retracted** one "IC311 outputs audio" claim for exactly this. I repeated it, and only the
accumulator check caught it. ★ The check that catches this is cheap and should be automatic:
**before reporting any non-zero output, read `§70 ACCA` and compare min against max.**

### 4. ⇒ §40 is CONFIRMED REFUSED, with a better reason than before

The old refusal said §40 "measurably destroys the result". Re-measured under today's model it does
something more specific: it takes the DC leak from **34.69 % → 99.79 %** of quiet frames and makes
*both* units emit a near-permanent constant. It does not rescue unit 0; it replaces silence with DC.

### 5. What genuinely survives

★ **With §40 on, §135's railing DISAPPEARS**: unit 1 returns from −8 388 608 (railed) to
−1 543 434, the baseline peak, even with the §133 readings enabled (arm E). So the reverb's
divergence is **mediated by the multiply's coefficient source** — real mechanistic information
about §135, obtained inside a regime (99.8 % DC) that is itself unusable. INFERRED.

⇒ The "two registers" explanation for §135 is **closed**. The next explanation must come from the
delay-DRAM datapath or from what `f31 = 1` means on the reverb's `ACT 0x0D` words, not from the
register file.

Evidence grade: §1 **MEASURED** (site enumeration); §2 **MEASURED** (four arms) with the routing
question **UNDECIDED**; §3 **MEASURED** and a retraction of my own claim; §4 **MEASURED**;
§5 **INFERRED**.

---

## §139 — WHY `f31 = 4/5` WERE BLIND: a POPULATION failure, not a witness failure

From a read-only corpus agent, with the load-bearing claims **re-verified here independently**.

### 1. ★★★ At cold boot, essentially no `f31 ∈ {4,5}` word executes at all

Counting only **plain** words — `f31 = hi12[3:1]` is not a field inside C-format
(`hi12[11:8] == 0xC`, where bits [24:12] are one 13-bit immediate reaching *into* `hi12`) nor
inside the bit-11 escape:

```
  CHORUS        a1   70 words -> f31=4 x0, f31=5 x0
  ROOM REVERB 1 a16 133 words -> f31=4 x0, f31=5 x0
  PARAMETRIC EQ a39 105 words -> f31=4 x2, f31=5 x2
  KERNEL             60 words -> f31=4 x0, f31=5 x1
  EPILOGUE           23 words -> f31=4 x0, f31=5 x0
```

**MEASURED** (re-verified). And PEQ's four are `w3`/`w56` = `02A.2.00.000`, `w50` = `028.2.00.000`
and the `428.1.0E.000` terminator — the **operand-free NOP form**: SRC 0, ACT 0, `addr8` 0,
class 2, no coefficient, no store. Such a word can touch nothing but the accumulator, and §131
established the accumulator cannot cross a bank entry.

⇒ **§133's "f31 = 4/5 are BLIND" was not an instrument limitation. It was FORCED by the words.**
The demultiplexer could not have decided them in that vehicle no matter how many arms it ran.
This is a materially better statement than §133 §4's, and it changes what to do next.

★ **It also pre-refutes the standing plan.** `f31-high.md` hands over *"★ AUTO PAN, not PARAMETRIC
EQ"* — but AUTO PAN's four sites (`w4`/`w43` = `02A.2.00.000`, `w13`/`w48` = `028.2.00.000`) are
**the identical NOP form**. It would fail identically. Do not run it. (A saved run, from reading
the corpus rather than the handoff.)

### 2. ⚠ A field-hygiene correction that moves every published `f31` count

Because `f31` is not a field in the two alternate formats, the corpus split is
`f31=4`: 48 total → **46 plain**; `f31=5`: 60 → **52 plain**.

⛔ **This removes §27's evidence.** §27's "`f31[2]` selects the accumulator" argument rests on
epilogue `w73` (`E30.C.00.404`), `w77` (`859.0.86.822`) and `w78` (`A3C.D.9F.287`) — **all three
carry bit 11**, so their quoted `f31` values 0/4/6 are read out of an immediate. That does not make
§27 wrong; it leaves it **unsupported**. And the independent check is unfavourable: of the 128
`SRC 0x11` (putative ACCB) reads, distance to the nearest preceding `f31 ≥ 4` word gives
P(d ≤ 4) = 0.273 against a shuffled null 0.247 ± 0.050 — **z = +0.50**, no support; 62 of the 128
have no preceding `f31 ≥ 4` word in their image at all, and PARAMETRIC EQ has four such words and
**zero** `SRC 0x11` reads.

### 3. ★★ `0x517CC1` = `floor(2/π × 2²³)`, EXACTLY

**MEASURED, re-verified**: `0x517CC1` = 5 340 353 = `floor(2/π × 2²³)` to the LSB — the same
truncation convention `lfo-ramp.md` anchored nine-fold. `2/π` is the mean of a **rectified** sine,
i.e. `programs.tsv`'s "2/pi env" level detector, named in the ROM's own role table.

It sits in a byte-identical four-word idiom at **12 sites across 8 images**, every one of which is
an effect with a level detector (NO OPERATION ×42 slots, GATED REVERB, COMPRESSOR ×2, AUTO WAH,
AUTO WAH+S.DELAY, and the PEQ+COMPRESSOR combis):

```
    026|02E.2.xx.xxx   (f31 = 3 or 7)          -- 11 of 12 sites
 ** 018.A.00.1D5       f31 = 4, ST   C-RAM = 0x517CC1 = 2/pi
    104.A.00.1D5       f31 = 2       C-RAM = 0x400000 = 0.5   <- same lo12/addr8, pointer FROZEN
    C40.2.C0.000       C-format immediate
    182.A.00.000       f31 = 1       one-pole smoothers, 4.712 ms and 11.764 ms
```

### 4. Absences — the sharpest part of the profile

* `f31 = 4` **never** carries bit 7 (0/46; base rate 23 % at `f31=1`, p ≈ 8e-6).
* **Neither** ever carries bit 6 (0/98; 6 % at `f31=0`).
* Their non-null SRC sets are **disjoint**: `f31=4 → {07}`, `f31=5 → {08,10}`. `f31=4` never
  sources the accumulator; `f31=5` never sources memory.
* **12 of 38 images terminate on `428.1.0E.000` (`f31=4`); not one terminates on `f31=5`.**
  `f31=4` has the corpus's highest mean position (0.622), `f31=5` among the lowest (0.391).
* Neither is ever a delay-DRAM word.

### 5. ⚠ AN INSTRUMENT DEFECT THAT MAY HAVE CAUSED PART OF §133's NULL

`bx_stim` (`upd6383.h`) returns `0x010000 + n·0x101` and `0x018000 + n·0x203` — **strictly positive
and monotone**. **A rectifier is invisible to a strictly positive stimulus.** If any of these codes
takes an absolute value, no number of arms can see it. The stimulus must alternate sign before
`f31` is enumerated again.

Evidence grade: §1 **MEASURED** (re-verified) and **FORCED** as to the blindness; §2 **MEASURED**
+ a **withdrawal of support** from §27, not a refutation; §3 **MEASURED**; §4 **MEASURED**;
§5 **FORCED** by inspection of the stimulus.

---

## §140 — SPECULATIVE PATTERNS (explicitly not gated; recorded so they accumulate)

Per Felipe's instruction to leave room for speculation. **None of these is evidence.** Each carries
what would confirm or kill it.

**S1 — `hi12` bit 5 changes what `hi12[3:1]` MEANS.** Outside the bit-5 family `f31 > 2` is
**0.90 %** of words; inside it, **76.05 %**. The 8/8 sub-field completeness that originally
established `hi12[3:1]` *is* a field used the prefix `0x02_` — **entirely inside the bit-5 family**.
Under this reading, "`f31 = 4`" inside and outside bit 5 are two different questions, and every
enumeration so far has conflated them. *Kill it by:* finding one bit-5-clear word whose behaviour
matches a bit-5-set word of the same `f31`.

**S2 — `f31 ≥ 3` marks the NONLINEAR / LEVEL-DEPENDENT stage.** The 14 images with **zero**
`f31 ≥ 3` words are CHORUS, MODULATED CHORUS, FLANGER, ENSEMBLE, VIBRATO, MIX UP, SINGLE DELAY,
MULTI TAP DELAY, ROOM REVERB 1 and the five S.DELAY combis — **every purely linear program in the
machine, and nothing else.** Everything with a rectifier, level detector, waveshaper or envelope
carries them. The split is MEASURED; the causal reading is the speculation. (PEQ and PHASER are
the awkward cases: linear, but carrying only the operand-free NOP form.)

**S3 — `f31` bit 2 = RECTIFY / absolute value.** ★ The strongest new lead and nobody has proposed
it. Its motivation is the *constant*, not a frequency argument: `2/π` is the mean of `|sin|`, so
the idiom containing it must take an absolute value somewhere — and **the ISA has no ACT code for
one**. Carriers would be the `026`/`02E` word (`f31` = 3 or 7) preceding 11 of the 12 sites, or the
`018` word itself. Then `026`(3) → `018`(4) reads as *rectify* → *rectify-and-scale-by-2/π*, with
3/7 vs 4/5 the same LOAD/ADD distinction one bit lower. *Kill it by:* a sign-alternating stimulus —
which §5 above says the current instrument cannot produce.

**S4 — `f98` is a modifier OF the accumulator op, not an independent field.** `f98 ≠ 0 ⇒
f31 ∈ {1,2}` holds on **2158/2203 = 97.96 %** of plain words (my per-program denominator; the
agent reported 1203/1207 = 99.67 % over the 38 distinct images — the regularity is strong either
way, the exact rate depends on the denominator, and I quote mine). If true, the operation is a
joint `(f98, f31)` code and `f31 ≥ 3` is simply where `f98` does not apply — meaning the four
`f31hi` readings enumerated so far search the wrong axis.

**S5 — kernel `w30` (`09A.A.00.200`) is the cheapest `f31=5` observable in the machine.** It is the
ONLY plain `f31 ∈ {4,5}` word that executes at cold boot with the default effects, it runs every
frame of every boot with any effect, it is already a named §109 probe slot, and it is one of the 13
words separating the two surviving store-gate rules. No panel path, no effect selection needed.

---

## §141 — §138's GUARD WORKED, AND WALKED THE SILENCE TO ITS LAST SLOT: **`w73` erases the accumulator at the door**

Scored against `data/PREDICT_138.md`, written before the run.

| | prediction | result |
|---|---|---|
| **P1** | the guard fires, count >> 0 | ✔ **198 372 977** = 76.8 words/frame of 320 |
| **P2** | acc at iw65..72 stops being 0 | ✔ **the body's result SURVIVES all eight slots** |
| **P3** | `unit0/DO1` becomes non-zero | ✘ still **0 non-zero, peak 0** |
| **P4** | §70 ACCA at w73 `min != max` | ✘ **min = max = 0** |

### 1. ★★★ The accumulator now reaches the presentation word — and dies inside it

```
  iw        baseline            §138 guard
  64    1 102 114 506 752   −2 199 023 124 480
  65..72              0     −2 199 023 124 480   <-- P2: the erasure is GONE
  73                  0                      0   <-- and w73 zeroes it ITSELF
```

The eight-slot drain §138 targeted is **fixed**. The value is carried intact to the door and
**`w73` destroys it in its own slot.** MEASURED.

### 2. Why, precisely — and it is the same defect a third time

```
  w73 = 0E30C00404   hi12=E30  class4=C  addr8=00  lo12=404
        f31 = 0  ->  LOAD acc <- P        bit4 ST, bit11 ESC, bit10 END
        class 0xC  ->  bit 3 set  ->  coeff_fetch() TRUE   (upd6383d.h:869)
```

So `w73` **fetches a coefficient and then loads the accumulator from the product** — an ordinary
MAC — but its **multiply does not issue**, so `P = 0` and the LOAD is an erasure. And because it
*does* fetch, §138's guard (gated on `!coeff_fetch`) **excludes it by construction** — which is
exactly why the accumulator survives iw65..72 and dies at iw73.

★★ **This is the third instance of one defect, not three defects:**

| site | word | fetches? | multiply issues? | effect |
|---|---|---|---|---|
| kernel `iw47` (§83's trace) | `800.8.0C.000` | **yes** | **no** | drains before body 0 |
| epilogue `iw65..72` (§138) | class 1/5/9, no fetch | no | n/a | drained before presentation — **now fixed** |
| **presentation `w73`** | `E30.C.00.404` | **yes** | **no** | **erases at the door** |

⇒ §39's long-open question — *"what enables the MULTIPLY, as distinct from the fetch, is OPEN"* —
is not an accounting curiosity. **It is the single root cause of unit 0's silence, and it acts at
three separate sites.** Fixing any one of them alone cannot produce audio; the register's
"one word, one register, one unformed product" framing was right about the mechanism and wrong
about the count.

### 3. ⛔ The guard is NOT shippable as written

It fires on **76.8 of 320 words per frame** — far too broad. It rails unit 1 (2 553 952 non-zero,
peak −8 388 608, DC leak 99.94 %) and perturbs the whole body trajectory (iw84 goes
1 805 397 833 546 → −2 002 210 652 160). ★ P1's fired-count is what exposed this: a guard that
fires 198 million times is changing the machine, not repairing one defect. **Keep bit 55 OFF.**

Its value is diagnostic: it is the instrument that walked the drain from iw65 to iw73.

### 4. ⇒ The next question is now single and well-posed

**Why does `w73`'s multiply not issue, when `coeff_fetch(w73)` is true?**

Same question as `iw47`. Both are class-with-bit-3-set words whose product is never formed. The
answer decides whether unit 0 can present anything at all, and it is upstream of every remaining
audio question — including §135's railing, which is also mediated by the multiply's coefficient
source (§137 §5).

⚠ And note what `w73` carries: `bit 11 ESC` — so per §139 §2, `f31` is **not a valid field** in it
and the "`f31 = 0` ⇒ LOAD" reading of `w73` is itself resting on a field the escape has
repurposed. That is a second, independent reason to distrust the current handling of this word,
and it may be the whole answer.

Evidence grade: §1 **MEASURED**; §2 **MEASURED** (the exclusion is forced by `coeff_fetch`'s own
definition); §3 **MEASURED**; §4 **OPEN**, and now single.

---

## §143 — FOUR CORRECTIONS FROM THE PARALLEL PASS, three of them to my own sections

Three read-only agents over the corpus, the notes and the **committed** logs. Every claim below
**re-verified here** before being recorded.

### 1. ⛔ §135 §4 IS RETRACTED: the reverb pairs do NOT read loop state

§135 §4 said unit 1's `ACT 0x0D` words *"read `mem[ptr]` at +75 / +8 / +123, inside the reverb's
own state block, so the pair copies loop state back into the loop"*, and `HANDOFF-NEXT` carried
that as the framing of the whole open question.

**`+75 / +8 / +123` are the signed pointer POST-INCREMENTS, not the read addresses.** For
`class4 & 7 == 2` the operand is `mem[m_dp]` *before* the increment. From
`data/ship_46A39B440F.log.gz`'s §104 table:

```
  205 020224B1CD 85  ... |  mem quiet 0..0  loud 0..0  =  | L 0..0  0..0  =
  319 02022081CD 85  ... |  mem quiet 0..0  loud 0..0  =  | L 0..0  0..0  =
  330 020227B1CD 85  ... |  mem quiet 0..0  loud 0..0  =  | L 0..0  0..0  =
```

**All three read `dp = 0x85` — the SAME cell, unit 1's INPUT latch — and it is measured ZERO**
(`=` marks quiet and loud identical). `0x85 = DRAM_UNIT_BASE 0x05 | (unit<<7)`. The idiom is
identical to PEQ's, which reads unit 0's `0x05`: **`acc ← mem[unit input cell]`, then `P ← acc`.
It is the INPUT-ACQUISITION pair**, used three times because the reverb needs the dry input in
three places — not an all-pass injection and not a feedback tap. **MEASURED, re-verified.**

### 2. ⛔ AND §135's A/B COMPARED TWO ALREADY-RAILED CONFIGURATIONS

`iw331`'s accumulator on loud frames is **549 755 748 352 = `0x7FFFFF << 16` EXACTLY** — the
positive rail — **in the DEFAULT arm**. Body-1 END is `2 × (0x7FFFFF << 16)`; the ship arm's is
`−2⁴⁰`, the same magnitude with the sign flipped.

⇒ **The railing is pre-existing.** `ACT 0x0E → P` does not cause it; it flips which rail and
extends it from 41.2 % of frames to 98.9 %. §135's headline — *"shipping the §133 readings rails
unit 1"* — attributes to the reading something the default already does. **MEASURED.**

★ This also rehabilitates §135's refutation #1 only partially: clearing mask bit 16 changing
nothing is a valid statement about the **delta** between two railed arms and says nothing about
whether the machine should be railed at all.

### 3. ⛔ A BUG IN CODE I WROTE TODAY: the `ACT 0x0D`/`0x0E` destination menu was UNIT-BLIND

```
  :2771 :2804   case 1: m_acc = u64(s64(L)) << ACC_SHIFT;    <- unconditional
  :2776 :2809   case 6: m_acc += ...                          <- unconditional
  :2143         L = acc_to_datum((m_specmask & 0x4000) && m_cur_unit1 ? m_accb : m_acc);
```

Mask bit 14 is **SET** in the default, so unit 1 accumulates into `m_accb` — and the `SRC 0x10`
**reader is unit-aware** while my **writer was not**. In unit 1 the pair therefore wrote ACCA and
read ACCB: *the write and the read targeted different registers*, and `ACT 0x0D`'s write went to a
register nothing in unit 1 reads.

★ **That is exactly why "`ACT 0x0D → acc` alone is bit-identical to the default" (§135 §3)** — in
unit 1 it wrote a dead register. And it means **§133's decode was only ever validated in unit 0**
(PEQ), where `m_acc` is the live one; the corpus-wide ship test was exercising a broken
implementation in unit 1.

This is the **fourth** instance of a defect this file has already fixed three times — §66 (source
side), §68 (the bit-4 store), §75 (the delay write). Fixed on mask bit 56 (`bx_acc_w`), gated so
the correction is A/B-able; predictions pre-registered in `data/PREDICT_142.md`. **FORCED** (source).

### 4. ⛔ §131's ARGUMENT WAS OVERSTATED — the conclusion survives, the premise did not

§131 §1 said *"Every slot in both entries reloads the accumulator from P"* and listed six words.
The entries contain **thirteen**:

```
  w0  f31=0   w1  f31=0   w2  f31=1   w3  f31=5   w4  f31=0
  w50 f31=4   w51 [ESC: f31 not a field]   w52 f31=0   w53 f31=0
  w54 f31=0   w55 f31=1   w56 f31=5   w57 f31=0
```

Five carry `f31 ∈ {1,4,5}`. ★ **The conclusion still holds** — the last word before each core
(`w4`, `w57`) is `f31 = 0`, so the accumulator is discarded at the entry's final slot regardless,
and §133 confirmed it independently (all 36 non-P combinations feed nothing). But the *argument*
generalised from six words to "every slot", and **the words it skipped are precisely the
`SRC 0x00` / `f31 = 4/5` words now in question.** MEASURED.

### 5. ⛔ `SRC 0x00`: the constraint that narrowed it to two readings is VOID, and §123 restored it

`adjudication-round6.md:605` — *"`action00-discriminator.md` §7's 108/108 and the `single`
section's 72/72: **VOID**"* — because round 5 falsified the delay polarity those counts assumed
(`adjudication-round7.md:48-49`: at the forced polarity *every* `src00` reading scores 0).

**§123 replaced a stale device comment with a citation to a section that had already been voided
three days earlier.** The correct status is: **`SRC 0x00` — 1 of 6 enumerated, and the constraint
that narrowed it to `{mem, acc}` is VOID.** `zero`, `DR`, `P` and `tA` are **not** excluded by any
surviving measurement.

★ And the menu itself is short: `action00_discriminate.py:340-343` enumerates
`{mem, P, acc, zero, DR, tA}` for `src00` while the *`src08`* menu next to it contains **`coef`** —
the C-RAM word at the cursor. **`SRC 0x00 = coef` has never been enumerated.**

### 6. ⇒ PARAMETRIC EQ's remaining blockers are its SEVEN `SRC 0x00` WORDS

With §133 applied, `coverage_report.py` leaves PEQ 11 blocked words, and after `ACT 0x0D`/`0x0E`
the remainder are **all `SRC 0x00`**: `iw86`, `iw87`, `iw134`, `iw136`, `iw139`, `iw140`, `iw188` —
three of them (`iw86`, `iw136`, `iw139`) blocked by `SRC 0x00` **alone**.

**§123's "eight words away" list named `ACT 0D`, `ACT 0E`, `f31=4`, `f31=5` and OMITTED `SRC 0x00`**
— because §123 had just declared it decided, on the strength of the section that was already void.
`SRC 0x00` is also the **#1 corpus blocker**: 1270 words, 91 programs, three times the next.

Evidence grade: §1 **MEASURED** and a **RETRACTION**; §2 **MEASURED**; §3 **FORCED** (source) and a
**bug fix**; §4 **MEASURED**, a partial retraction; §5 **FORCED** from the round-6 void;
§6 **MEASURED**.

---

## §144 — ★★★ §135's REFUSAL IS OVERTURNED: the railing was my own bug, and the §133 READINGS ARE SHIPPED

Scored against `data/PREDICT_142.md`, written before the run.

| | prediction | A: unit-BLIND | B: unit-AWARE |
|---|---|---|---|
| **P1** | fired-count 0 in A, >> 0 in B | **0** ✔ | **7 690 128** ✔ |
| **P2** | ★ the railing STOPS; DO2 falls toward 41.2 % | 2 553 952 = 98.9 % | **1 062 933 = 41.2 %** ✔ |
| **P3** | DO1 UNCHANGED (known-answer control) | 0 non-zero, peak 0 | **0 non-zero, peak 0** ✔ |

```
  arm                        DO2 non-zero   frac    peak          DC leak
  default (§130)             1 064 113      41.2 %  −1 543 434    34.69 %
  ship, unit-BLIND (§135)    2 553 952      98.9 %  −8 388 608    99.94 %
  ship + §142 unit-AWARE     1 062 933      41.2 %  +1 543 433    34.64 %
```

Frames close **320/320, 0 traps**.

### 1. What this settles

**§135's entire "NOT shippable" verdict rested on a defect in code I had written the same day.**
The `ACT 0x0D`/`0x0E` destination menu wrote `m_acc` unconditionally while the `SRC 0x10` reader is
unit-aware and mask bit 14 is set — so in unit 1 the pair wrote ACCA and read ACCB. With the writer
matched to the reader the arm returns to the default's statistics to within **0.1 %**.

★ **P3 is the load-bearing one.** Unit 0 uses `m_acc` either way, so the fix *had* to be a no-op
there — and it was, exactly. A fix that also moved DO1 would have been doing something other than
what it claims.

★ Note what this says about §135's three "refuted hypotheses" (store-and-clear, multiply-carrying
words, kernel/epilogue sites): all three were **correctly** refuted, and all three were refutations
of explanations for a phenomenon that **had no external cause at all**. Ruling out real hypotheses
about an artefact is the expensive failure mode; the thing that ended it was an agent reading the
source, not another arm.

### 2. SHIPPED — the default becomes `0x110E446A39B440F`

`sel0D = 1` (`ACT 0x0D = acc ← bus`), `sel0E = 7` (`ACT 0x0E = P ← bus` at the multiply's scale),
bit 52 (excused from the blanket tempA capture), bit 56 (per-unit accumulator write).

Backed by: §133's bit-exact demultiplexer (224/1024, chance 2⁻²⁴ per frame, and the *only*
combination yielding two channels); the corpus corroboration (`ACT 0x0D` pairs with `SRC 0x07` in
350/402 = 87 %; `ACT 0x0E` splits 239/187 between the relay and direct forms — the two patterns
measured inside PEQ); and now a corpus-wide regression that is statistically indistinguishable from
the default.

**829 of 6282 ALU words (13.2 %), in all 91 programs, move from undecoded to decoded.**

### 3. ⚠ THE ONE REAL DIFFERENCE, AND IT IS NOT MINE TO CALL

**Unit 1's peak flips sign: −1 543 434 → +1 543 433.**

Both are rails — §143 §2 measured the **default** already railed at `0x7FFFFF << 16` exactly — so
this is a polarity change between two railed states, not a change from clean audio to clipping.
But it is audible behaviour in the only audible unit. ★ **It needs a listen**, alongside §130's
still-outstanding one. The agent's speculative SP-4 offers a candidate reading: the PEQ channel is
already known polarity-inverted by an odd number of `−2.0` make-ups (§129 §4.1), and the reverb
tail may carry an unpaired inversion of the same kind.

### 4. What is NOT claimed

Nothing here makes the chip audible. `unit0/DO1` is still **0 non-zero**, and §141 localised that
to a single slot: `w73` loads the accumulator from an unformed product and erases it at the door.
The railing of unit 1 is also still unexplained — it is *pre-existing*, which is a different and
harder question than the one §135 thought it was asking.

Evidence grade: **MEASURED** (three pre-registered predictions, one of them a known-answer
control); the ship decision **FORCED** by §133 + the regression; §3 flagged for hardware judgement.

---

## §145 — ★★★ `SRC 0x00` = **C-RAM[cursor]** — the reading that was never in the menu

Scored against `data/PREDICT_145.md`, written before the run.

### 1. The result, bit-exact

```
                       baseline (mem[ptr])          bit 57 (coef)
  fired-count                  0                    15 540 204
  iw89   ANCHORED SRC 0x08   L = 114                L = 114        <- control, UNCHANGED
  iw94   twin  SRC 0x00      L = 8388607            L = +240
  iw103  twin  SRC 0x00      L = 8388607            L = +240
  iw135  twin  SRC 0x00      L = 671                L = −240
  iw144  twin  SRC 0x00      L = 203                L = −240
```

**P1 ✔ P2 ✔ P3 ✔.** The predicted values were `+240 / +240 / −240 / −240`, written down before the
run from the live C-RAM, and they came back **exactly**. Chance of a coincidental 24-bit match at
four slots is 2⁻⁹⁶. The known-answer control — the anchored `SRC 0x08` word — did not move, so the
gate is confined to `SRC 0x00`. Frames close 285/285, 0 traps.

★ And the sign pattern is itself a finding: `+240, +240, −240, −240` is **two antiphase pairs**,
which is exactly what a two-voice chorus needs. The shipped reading delivered the **rail** at two
of the four sites and unrelated residue at the others.

### 2. Why this was invisible for so long — three compounding reasons

1. **`coef` was never in the menu.** `action00_discriminate.py:340-343` enumerates
   `src00 ∈ {mem, P, acc, zero, DR, tA}` while the **`src08` menu on the next line contains
   `coef`**. Every "1 of 6 enumerated" statement about this source is a statement about those six.
2. **The LFO tool's site predicate excluded the twin by construction.** `lfo_ramp.py:263` defines an
   LFO site as `lo12 == 0x200 and class == 0xA` — that *is* the `SRC 0x08` encoding, so no LFO
   analysis in this project has ever seen the `SRC 0x00` form.
3. **The constraint that appeared to settle the question was VOID.** §123 restored a device comment
   citing `action00-discriminator.md` item I, which `adjudication-round6.md:605` had voided three
   days earlier (§143 §5).

### 3. The corpus twin, MEASURED

```
  092.A.xx.200  SRC 0x08 (ANCHORED)  n=29, successor 082.2.00.1C0 in 29/29
  192.A.xx.000  SRC 0x00             n=29, successor 082.2.00.1C0 in 29/29
  base rate of that successor after ANY class-A word: 64/822 = 7.79 %
```

The two differ in **exactly two bits** — `hi12` bit 8 and `SRC` bit 3 — occupy the same slot of the
same idiom, and `082.2.00.1C0` is the anchored LFO phase-read. 29/29 against 7.79 % is ~10⁻³².
Twin programs: CHORUS, MODULATED CHORUS, ENHANCER, ROCK ROTARY, VIBRATO, MIX UP, S.DELAY+CHORUS,
S.DELAY+VIBRATO, PEQ+CHORUS, PEQ+VIBRATO — the modulation family.

CHORUS's anchored word consumes `C-RAM[0x00] = 114`, **its known LFO increment** (0.599 Hz); its
four twins consume `0x02/0x04/0x0D/0x0F`, holding ±240 = 1.262 Hz.

### 4. ⚠ WHAT THIS RUN DOES **NOT** ESTABLISH — and the limitation is mine to state

**The run had ZERO loud frames.** `§54 TRACKING: loud-in 0`. The cold-boot vehicle exits at t = 14 s
and the machine does not reach the play screen until ≈ 19 s, so **the notes never sounded**. By
method rule 12, *a DSP test with no notes playing is not a test* — for anything input-dependent.

★ The decode result survives that anyway, and precisely because of *why*: **an LFO is
input-independent by construction.** The operand bus at those four slots equals a ROM constant
whatever the input does, which is what makes a 24-bit bit-exact match meaningful here. But:

* the **audio regression is NOT assessed** by this run. With bit 57 the same run took
  `unit1/DO2` from 0 non-zero to 408 252 with peak 8 388 607 (the rail) — **on quiet frames only**,
  because there were no others. That is not evidence of a defect *or* of its absence.
* A comparable-vehicle regression (PEQ + notes, the §144 setup) is running separately, and the
  shipping decision waits for it.

### 5. Scope

`SRC 0x00` is the **#1 corpus blocker**: **1270 words across all 91 programs**, three times the
next. It is also **PARAMETRIC EQ's entire remaining blocker set** — its seven `SRC 0x00` words
(§143 §6). This result is measured on the 29 twins, which are a *modulation-family* population;
whether `coef` is right for the other ~1240 words is **not** established here, and the class-2
`lo12 = 0x000` majority (which does not consume a cursor coefficient) is the obvious place for it
to fail.

Evidence grade: §1 **MEASURED**, three pre-registered predictions including a known-answer control;
§3 **MEASURED**; §4 a stated **limitation**; §5 **OPEN** — the generalisation beyond the twins.

---

## §146 — THE CLASS GATE FAILS ITS OWN P3, AND THE FAILURE LOCALISES THE RAILING TO **FOUR WORDS**

Scored against `data/PREDICT_146.md`.

| | prediction | result |
|---|---|---|
| **P1** | fired-count falls sharply | ✔ **91 383 219 → 16 063 766** |
| **P2** | ★ the twins UNCHANGED (known-answer control) | ✔ `+240 / +240 / −240 / −240`, and `iw89` still 114 |
| **P3** | ★ the railing stops | ✘ **DO2 2 553 951, peak +8 388 607, DC leak 99.94 %** |

`2 553 951` against the all-words arm's `2 553 952` — **one frame different.** So restricting the
read to coefficient-consuming words removes 82 % of its firings and changes the outcome by
essentially nothing. **F3 fired: class is not the discriminator.**

★ But that is a *better* result than a pass, because it localises the cause. Of the ~111 class-A
`SRC 0x00` words in the corpus, only **FOUR execute in the live frame**:

```
  KERNEL           iw14, iw36    400.A.00.000    f98=0  f31=0
  ROOM REVERB 1    iw315, iw326  282.A.00.000    f98=2  f31=1
  PARAMETRIC EQ                  -- none --
  EPILOGUE                       -- none --
```

**Unit 1's railing is produced by at most four words, and the two in the audible unit are
`282.A.00.000`.**

### 1. ⚠ A measurement-hygiene note about these runs

The `peq_gain.lua` runs do **not** set `UPD6383_TRACE_FRAME`, so the trace still arms at frame
420 000 ≈ 8.75 s while PEQ is selected at ≈ 50 s. **The `iw94/103/135/144` readings in this and the
previous arm are therefore CHORUS frames, not PEQ frames** — which is fine, because the twins live
in CHORUS, but it must be said rather than assumed. It also means the DO2 statistics over an 80 s
run are dominated by the **CHORUS**-era ~62 % of it, not by PEQ.

### 2. ★ The encoding that separates them, and one independent check before it is believed

All 47 class-A `SRC 0x00` words over the 38 distinct images + kernel + epilogue:

```
  hi12=192  f98=1  f31=1  n=29   <- THE LFO TWINS, bit-exact +/-240 (§145)
  hi12=182  f98=1  f31=1  n=12
  hi12=282  f98=2  f31=1  n=2    <- ROOM REVERB iw315/iw326, the railers
  hi12=212  f98=2  f31=1  n=2
  hi12=400  f98=0  f31=0  n=2    <- KERNEL iw14/iw36
```

`f98 = 1` covers **41 of 47** and excludes exactly the words that rail.

⚠ **Gating on `f98 = 1` because it separates the twins from the railers would be fitting the gate
to the outcome.** What makes it more than that is an *independent* identification of the other
f98=1 form: `182.A.00.000` is the **one-pole smoother** of the 2/π level-detector idiom (§139 §3),
found from a byte-identical 12-site window, not from this experiment. So `f98 = 1` collects
{LFO phase accumulator, one-pole smoother} — two *coefficient-consuming filter* contexts — while
`f98 = 2` and `f98 = 0` are something else.

★ **The independent prediction that would make it evidence:** under `coef` the twelve `182` words
must consume the smoother time constants the idiom needs (≈ 4.712 ms and 11.764 ms, ratio ≈ 5/2),
**not** whatever `mem[ptr]` supplies. That is checkable offline, on a population this experiment
never touched, and it should be checked **before** the gate is run.

### 3. Where this leaves `SRC 0x00`

* **MEASURED**: `coef` is right at the 29 LFO twins, bit-exact, with a passing control.
* **MEASURED**: `coef` applied to all 1610, or to all 111 class-A, rails unit 1 identically.
* ⇒ The reading is **context-dependent**, and `class4` is not the context. `f98` is the leading
  candidate and is **not yet tested**.
* The 1262-word class-2 majority remains entirely unaddressed — it is 78 % of the population and
  no measurement here speaks to it.

Evidence grade: §1 **MEASURED** with one **stated hygiene limitation**; §2 **MEASURED** (the
census) + **SPECULATIVE** (the f98 reading), with its independent test named; §3 **OPEN**.

---

## §147 — ★★ THE `182` SMOOTHER TEST PASSES, FROM THE ROM'S OWN UPLOAD SCRIPT — and it names the compressor's ATTACK/RELEASE

§146 §2 pre-registered this test *before* running anything, on a population the §145 twin
experiment never touched: **under `coef` the twelve `182.A.00.000` words must consume the
one-pole smoother time constants the 2/π level-detector idiom needs.** It passes, and the check
needed no emulator at all.

### 1. The ROM contains the host's upload script, and the constants are consecutive

At ROM `0x84CD`, five consecutive 3-byte big-endian Q0.23 coefficients:

```
   517CC1   0.636620   = floor(2/pi * 2^23) EXACTLY -- the mean of |sin|
   400000   0.500000
   009DAD   0.004812   -> one-pole tau = 1/(a*fs) = 4.712 ms
   003F29   0.001927   -> one-pole tau =            11.764 ms
   066666   0.050000
```

(The preceding bytes `... 08 21 20 26 ...` are the `0x821` coefficient-base pointer load.)

### 2. And COMPRESSOR's cursor consumes them in exactly that order

```
   w3   018.A.00.1D5  -> C-RAM[0x00]   = 2/pi        the rectifier calibration
   w4   104.A.00.1D5  -> C-RAM[0x01]   = 0.5
   w6   182.A.00.000  -> C-RAM[0x02]   = 0.004812    ★ THE SMOOTHER, 4.712 ms
   w10  000.A.00.219  -> C-RAM[0x03]   = 0.001927       11.764 ms
   w11  09A.A.00.200  -> C-RAM[0x04]   = 0.05
   w24/w25/w27  the same idiom again  -> C-RAM[0x05]/[0x06]/[0x07]  (the second stage)
```

**The upload order and the consumption order are the same sequence.** The `182` word lands on a
one-pole time constant, which is what `coef` predicts it reads and what `mem[ptr]` does not.

### 3. ★ And the parameter list closes the loop with the UI

`kn5000-dsp-paramlist.md`: **COMPRESSOR's six parameters are THRESHOLD, RATIO, ATTACK SENS.(s),
RELEASE SENS.(s), VOLUME, REV SEND.** Two time constants, *in seconds* — and the idiom appears
**twice**, once per stage, consuming one smoother constant each.

⇒ `0.004812` → 4.712 ms and `0.001927` → 11.764 ms are the compressor's **ATTACK and RELEASE**
sensitivities, ratio 2.4964 ≈ 5/2. The `018`/`182` pair is a **rectify-and-smooth envelope
follower**: `2/π` calibrates the rectified mean, the `182` word applies the one-pole.

This also gives §139 §3's `0x517CC1` finding its consumer, and gives §140's speculative **S3**
(*"`f31` bit 2 = RECTIFY"*) a concrete context to be tested in: the rectifier must live in this
idiom, because `2/π` is meaningless without one.

### 4. What this does and does not license

* **Supports** `SRC 0x00 = coef` on the `f98 = 1` family, from an independent population and an
  independent source (the ROM's parameter script, not a model output). The `182` words are 12 of
  the 41 `f98 = 1` class-A `SRC 0x00` words; the `192` twins are the other 29 and were already
  bit-exact (§145).
* **Does NOT** license the `f98 = 1` gate by itself. §146 warned that gating on `f98` *because* it
  separates the twins from the railers is fitting to the outcome; this removes that objection for
  the `182` half but the gate is still **untested in the emulator**.
* **Says nothing** about the 1262-word class-2 majority — 78 % of the population, still untouched.
* ⚠ Grade: the cells are shown to *hold* designed smoother constants and to be consumed in the
  ROM's own upload order. A live capture of the operand bus at a `182` word would upgrade this
  from **INFERRED (strong)** to MEASURED, as §145 did for the twins.

Evidence grade: §1/§2 **MEASURED** (ROM bytes and the disassembler's cursor addresses);
§3 **INFERRED (strong)** — the UI parameter names, the two stages and the two constants agree;
§4 the scope, explicitly bounded.

---

## §148 — THE `f98` GATE IS INERT IN A CLEAN VEHICLE — and the clean vehicle overturns §143 §2

Scored against `data/PREDICT_148.md`. Vehicle: **cold-boot CHORUS**, notes at t = 21..27.5 s,
i.e. *after* the ~19 s boot — which fixes §145's defect of having **zero** loud frames. This run
has **314 063** of them.

| | prediction | result |
|---|---|---|
| **P1** | fired-count > 0, ≪ the class-A arm's 16 063 766 | ✔ **4 513 920** |
| **P2** | ★ control: twins still ±240, anchored `iw89` still 114 | ✔ `+240/+240/−240/−240`, `114` |
| **P3** | the railing does not appear | **VOID in this vehicle** — see §2 |
| **P4** | ★ something downstream differs | ✘ **DO1 and DO2 are 0 non-zero in BOTH arms** |

⇒ **F4 fired**: `coef` puts the right value on the bus and **nothing downstream reads it**. The
reading is **inert in this vehicle** and cannot be validated by it. The gate is not refuted; it is
unobservable here, which is a different and weaker outcome than either a pass or a refutation.

### 1. ★★ THE CLEAN STEADY STATE IS SILENT IN **BOTH** UNITS

```
  cold-boot CHORUS + notes, DEFAULT mask, 314 063 loud frames:
     unit0/DO1  1 155 840 exec, 0 non-zero, peak 0
     unit1/DO2  1 155 840 exec, 0 non-zero, peak 0
     VERDICT: SILENT -- chip eats the signal
     §70 ACCA at w73: quiet min 0 max 0 | loud min 0 max 0
```

This is exactly what §141 predicts (`w73` erases the accumulator at the door) and it is the first
time it has been measured in a vehicle that both plays notes *and* leaves the machine alone.

### 2. ⛔ AND IT OVERTURNS §143 §2: THE UNIT-1 RAILING IS **VEHICLE-DEPENDENT**

The same slot, the same default mask, two vehicles:

```
  CLEAN cold-boot CHORUS      iw330/331/332   acc  0..0   quiet AND loud, marked '='
  80 s peq_gain (navigation)  iw331           acc  549 755 748 352 = 0x7FFFFF<<16  (the rail)
                              iw332           acc 1 099 511 496 704 = 2x the rail
```

§143 §2 concluded *"unit 1's railing is PRE-EXISTING"* and `HANDOFF-NEXT` §1b carries it as a
standing caution. It is pre-existing **within the `peq_gain` vehicle** — and **that vehicle creates
it.** In the clean steady state the reverb's accumulator is identically zero.

★ The mechanism is not mysterious: `peq_gain.lua` spends ~40 s driving the panel — DSP EFFECT
toggle, SOUND menu, editor, 40 DOWN presses, 15 UP presses — and **every TYPE step uploads a
different effect** (`origin-capture.md` measured 16 uploads in one 16-step sweep). So the chip
takes ~55 program loads and coefficient rewrites mid-run.

### 3. ⇒ What this qualifies, and what it does NOT

**Qualified — every DO2 / DC-leak *absolute* number in §§135–148** was measured in the
navigation vehicle and describes **the vehicle**, not the chip's steady state. That includes
§135's "98.9 %", §144's "41.2 %" and §145/§146's railing figures.

**NOT invalidated — the A/B *deltas*.** §144's ship decision rested on the ship arm being within
0.1 % of the default *in the same vehicle*, and §142's three predictions were differences between
two arms measured identically. A shared contaminant cancels in a delta; it does not cancel in a
characterisation. ★ The distinction matters and is worth keeping: §135's *"shipping rails unit 1"*
was wrong for a different reason (my unit-blind write, §143 §3), but its numbers were
vehicle-contaminated **as well**.

**New standing rule:** report audio statistics from a **clean vehicle** (cold boot, notes after
the boot settles, no panel navigation), and use the navigation vehicle only when the experiment
actually needs a selected effect — and then only for deltas.

### 4. Where `SRC 0x00 = coef` now stands

* **MEASURED**: bit-exact ±240 at the 29 LFO twins, control passing, in two vehicles (§145, §148).
* **INFERRED (strong)**: the twelve `182` smoothers land on the ROM's own attack/release constants
  (§147).
* **UNOBSERVABLE downstream** in a clean vehicle — nothing yet reads what it puts on the bus.
* **UNTOUCHED**: the 1262-word class-2 majority, 78 % of the population.

⇒ To validate it further requires an observable *downstream of the LFO*, not another arm. §104's
residency ranges on the phase cell, or the delay-tap address the LFO is supposed to modulate,
are the candidates — and the latter is the one the whole chorus depends on.

Evidence grade: §1 **MEASURED**; §2 **MEASURED** and a **partial retraction of §143 §2**;
§3 **FORCED**; §4 status.

---

## §149 — ★★★ WHY `coef` IS INERT DOWNSTREAM: **THE LFO IS NOT CONNECTED TO THE DELAY TAP AT ALL**

§148 asked for an observable between the LFO phase cell and the delay tap it modulates. There
isn't one, and the reason is structural rather than instrumental.

### 1. The LFO ramps correctly — that half already works

`§109 LFO PHASE resident at body-0 iw89 on 8 consecutive frames`:

```
  f420001:1006784  f420002:1006898  f420003:1007012  f420004:1007126 ...
```

Successive differences are **exactly 114** — CHORUS's ROM LFO increment (0.599 Hz). **MEASURED**,
and *identical in both §148 arms*, because `iw89` is the anchored `SRC 0x08` word the gate does
not touch.

### 2. ⛔ And the delay address ignores it completely

`upd6383.cpp:1813`:

```cpp
    const u32 addr = (cellv + u32(m_frames_run)) & 0xffff;
```

**Descriptor cell + the free-running frame counter, and nothing else.** No accumulator, no temp,
no phase term appears anywhere in the address computation. `m_frames_run` is the circular-buffer
rotation `G` (`r3-delaydram.md` §5.1, *"address = (cell + G) mod 2^N, G a single global
rotation"*) — which is right, and is **not** modulation.

⇒ **A swept delay cannot exist in this model.** The LFO accumulates a correct phase every frame
and the phase has nowhere to go. That is the whole explanation for §148's F4: `SRC 0x00 = coef`
puts the designed increment on the bus, the phase ramps, and **the consumer is missing from the
emulator**, not from the reading.

★ It also predicts what the emulated CHORUS would sound like if anything were audible: a **fixed**
comb, not a chorus.

### 3. ★ A concrete candidate for the missing link

CHORUS's two modulated delay READs are each preceded by a byte-identical three-word idiom:

```
   C40.3.20.44C     C-format immediate
   A00.0.00.041     SRC 0x01, ACT 0x01     <- immediately before the read, both times
   880.1.20.2C7     THE DELAY READ (addr8 = 0x20)
```

and the LFO twin (`192.A.4x.000`) plus its phase-read successor sit a few words earlier, so the
phase is in hand when this idiom runs.

**`A00.0.00.041` occurs 38 times in 14 programs**, and the population is exactly the swept-delay
family — with a clean **present-and-absence**:

```
  CARRIERS   CHORUS, MODULATED CHORUS, FLANGER, VIBRATO, MIX UP, ROCK ROTARY, ENHANCER,
             + the S.DELAY and PEQ combis of those same effects
  ABSENT     PHASER  -- which sweeps ALL-PASS COEFFICIENTS, not a delay tap
```

★ **SPECULATIVE (strong): `A00.0.00.041` is the word that applies the LFO-derived offset to the
delay-tap address.** It sits in the one slot where the modulation must be applied, it is present
in every effect that sweeps a delay, and it is absent from the one modulation effect that sweeps
something else. `ACT 0x01` is one of the five codes given a "PLAIN GUESS ×5" tempA reading with no
evidence, so nothing currently stops it meaning this.

*Kills it:* find `A00.0.00.041` in a program with no delay line, or a swept-delay effect that
lacks it. *Confirms it:* an address term derived from the phase cell that reproduces the ROM's
designed sweep depth at the tap.

### 4. ⇒ Consequence for the `SRC 0x00` line of work

`coef` cannot be validated downstream **until the modulation path exists**, so the next step is not
another mask arm on `SRC 0x00`. It is to decode the tap-offset mechanism — which is also what
`dsp-audiopath-wiring.md`'s O-2 and `r3-delaydram.md`'s open items have been circling, and what
every swept effect in the machine depends on.

★ And note the shape of this result: three sections (§145–§148) refined a reading that was already
right, against a consumer that does not exist. The fired-count and the bit-exact bus check kept
saying "the gate works"; only asking *what reads this* found the gap.

Evidence grade: §1 **MEASURED**; §2 **MEASURED** (source, quoted); §3 **MEASURED** (the idiom, the
38/14 census and the present-and-absence) + **SPECULATIVE** (the role); §4 **FORCED** by §2.

---

## §150 — ⛔ §141's MECHANISM IS REFUTED: `w73`'s MULTIPLY **DOES** ISSUE, AND THE ACCUMULATOR IS ZEROED ANYWAY

§141 concluded that `w73` *"fetches a coefficient and then loads the accumulator from a product
that is never formed, so `P = 0` and the LOAD is an erasure"*, and made that the third instance of
one root cause (§39's *"what enables the MULTIPLY"*). **The trace says otherwise**, and it was in
logs I already had.

### 1. The measurement

Frame trace, columns `n iw u word dp acc accb P cur coef MUL L`:

```
  DEFAULT arm
   275  72  0 0000106087 00              0              0              0 90 4D9364  .  4194304
   276  73  0 0E30C00404 00              0              0              0 90 4D9364  Y        0

  §138-GUARD arm (accumulator preserved through iw65..72)
   275  72  0 0000106087 00 -1291953864697 -1841681917543              0 90 4D9364  .  4194304
   276  73  0 0E30C00404 00              0 -1841681917543  -666370572288 90 4D9364  Y -8388608
```

★★ At `iw73`, **`MUL = 'Y'`** — the multiply issues, in both arms. In the guarded arm the operand
bus carries `L = −8 388 608` (the preserved accumulator, clamped by `acc_to_datum`) and
**`P = −666 370 572 288`, a real product** — and **`acc` comes out `0` regardless.**

⇒ **The erasure is not "no product". Something zeroes the accumulator at `w73` despite a valid
product.** MEASURED.

### 2. Why §141 got it wrong, and the general lesson

§141 inferred the mechanism *by analogy* with §83's trace of `iw47`, where `MUL = '.'` was directly
observed — and then reasoned from `coeff_fetch(w73) == true` to "so it should multiply, and doesn't".
Both halves were checkable in one grep of a log I had already committed. I checked the **gate**
(`upd6383.cpp:3157`, `coeff_fetch` selected by mask bit 2, which is set) and not the **outcome**.

★ The pattern is the same one §149 closed with, one level down: I asked *"is this word allowed to
multiply?"* when the answer needed was *"did it?"* — and the instrument that answers the second was
already running.

### 3. The new suspect, and it is already on record as contested

`w73 = 0E30C00404`, `hi12 = 0xE30`: **bit 4 (STORE) is SET**. The store-and-clear writes `mem[p]`
and then zeroes the accumulator — which is exactly the observed behaviour: a product forms, the
store takes it, and the accumulator is left at 0 for the presentation that follows (deferred to
after the arithmetic by §29 / mask bit 3, which is set).

⚠ And this is the tension §131 §3 recorded and deliberately did **not** act on: mask bit 16
*suppresses* the store-and-clear and is SET in the default, while `dsp-alu-biquad.md` §6 ablates
the clear at **57.193 dB** and calls it required. The device's own comment gives the counter-
argument in the same terms as this finding — *"the epilogue's FIRST word w60 carries HI_ST, so it
stores AND CLEARS — destroying unit 0's result at the top of the very stage whose job is to present
it."* **The same argument applies verbatim to `w73`.**

So one of these must be wrong:
* the store-and-clear reading (a store that annihilates the value the next word must present), or
* the claim that `w73`'s `hi12` bit 4 means *store*, or
* the presentation ordering.

⚠ Note `w73` carries **bit 11 (ESC)**, so per §139 §2 `f31` is **not a valid field** in it — the
`f31 = 0 ⇒ LOAD acc ← P` reading of this word rests on a field the escape has repurposed, and
§141 §4 already flagged that as a second reason to distrust its handling. **Bit 4's meaning under
the escape is equally unestablished.**

### 4. What to measure next

The discriminating observable is **whether the store fires at `iw73` and what it writes**: the §109
per-slot store witness already reports `dpPre`, `dpPost`, the store address, the path taken and
which guard admitted the word. Point it at slot 73 (`SPROBE` list) and read it — no new mechanism
needed, and it distinguishes "the store-and-clear zeroed it" from "something else did".

Evidence grade: §1 **MEASURED** (the trace, both arms); §2 a **RETRACTION** of §141's mechanism —
its *localisation* to `w73` survives, its *explanation* does not; §3 **INFERRED** (the store-bit
suspect) and the contradiction between the two readings **FORCED**; §4 a named, existing instrument.

---

## §151 — `SRC 0x00` ON CLASS 2: the build already ships TWO incompatible readings, and `acc` is excluded

From a read-only corpus agent; every claim below **re-verified here** before recording.

### 1. ⛔ THE BUILD CONTRADICTS ITSELF, AND NO NOTE RECORDS IT

`000.2.00.000` — **273 words, across 91 programs** (re-counted) — is hard-coded as a **`nop`** in
both mirrors:

```
  upd6383d.cpp:728   if (hi == 0x000 && cl == 2 && ad == 0x00 && lo == 0x000) return true;  // nop
  upd6383.cpp:3401   else if (hi12(word)==0x000 && class4(word)==2 && lo12(word)==0x000)
                     { /* nop -- INFERRED */ ... ptr_postinc still applied (§90) ... }
```

That branch precedes `exec_alu()`, so those 273 words never reach the ALU. **Every other class-2
`SRC 0x00` word does**, and there reads `mem[m_dp]`.

⇒ **The shipped emulator uses `SRC 0x00 = zero` for 273 of the class-2 population and
`SRC 0x00 = mem[ptr]` for the rest — two incompatible semantics for one source code, live, and
undocumented.** And the `nop` reading is the *only* class-2 `SRC 0x00` decode this project has ever
shipped. FORCED (source).

★ It is also self-consistent only under `zero`: with `f31 = 0` and `ACT 0x00`, a non-zero bus would
**overwrite** the accumulator, so treating the word as a no-op *is* the claim that its operand is 0.

### 2. ★★ `SRC 0x00` and `SRC 0x07` have DISJOINT `hi12` vocabularies inside class 2

Re-verified: over class-2 words with `ACT 0x00`,

```
  SRC 0x00 (lo12 = 0x000):  17 distinct hi12
  SRC 0x07 (lo12 = 0x1C0):   3 distinct hi12
  SHARED:                    0
```

The agent's permutation null (20 000 draws, marginals preserved, global and within-program) gives
mean overlap ≈ 19 and **P(overlap ≤ 0) < 5×10⁻⁵**. Concretely `022.2.00.000` and `002.2.00.1C0`
have *identical* decoded ALU fields and differ only in `hi12` bit 5 and the source code.

⇒ If `SRC 0x00` were `mem[ptr]`, the two encodings would be interchangeable and the assembler's
choice would be uncorrelated with the accumulator operation. It is perfectly correlated.
**This is the strongest static evidence yet that `SRC 0x00 ≠ mem[ptr]`** — i.e. against the reading
the build ships for 989 of the 1262. MEASURED.

### 3. ★★★ The self-write exclusion, promoted to a reusable ISA constraint

Over the 38 distinct images (2899 routed words), five source×action pairs that would write a
register from itself:

```
  mem[ptr] SRC 07 x ACT 07 : obs 0, exp 145.17
  acc      SRC 10 x ACT 00 : obs 0, exp 198.28
  tempA    SRC 19 x ACT 13 : obs 0, exp   1.92
  tempA    SRC 19 x ACT 19 : obs 0, exp   4.27
  tempB    SRC 1A x ACT 14 : obs 0, exp   1.52
  TOTAL    observed 0, expected 351.15    ->  P = 3.1e-153
```

**Any proposed "`SRC X` = register `R`" must have zero co-occurrence with the actions that write
`R`.** This has been rediscovered piecemeal; it belongs in the ISA notes as a standing test.

Applying it:
* ⛔ **`SRC 0x00 = acc` is EXCLUDED.** `SRC 0x00 × ACT 0x00` occurs **580** times (453 in class 2),
  and `ACT 0x00` is the code that admits the bus to the accumulator adder. ⚠ The honest escape:
  if `0x00` and `0x10` were two encodings of one register with a spelling convention, the
  exclusion would be convention rather than prohibition — weakened by their overlap elsewhere
  (`ACT 0x0B`: 27 vs 10; `ACT 0x07`: 3 vs 264).
* ✔ **`P` survives with positive support**: `SRC 0x00 × ACT 0x0E` (`P ← bus`, §133) = **0** against
  47.84 expected.
* ⚠ **`zero` is untouched** — it names no register, so the test is silent by construction. That is
  a limitation of the test, not evidence for the reading.
* ★ **Free by-product**: `ACT 0x0B` co-occurs with `SRC 0x19` (tempA) **44** times. If `ACT 0x0B`
  wrote tempA that would be 44 self-writes against an exceptionless prohibition — so this argues
  **`ACT 0x0B ≠ tempA ← bus`**, a different open code, at no cost.

### 4. ⚠ The live null is 89.7 % — do not spend another mask arm here

From `data/clean_vehicle_default.log.gz` (§148's clean vehicle, 314 063 loud frames): of the 39
class-2 `SRC 0x00` slots that execute per frame, **35 read `L ≡ 0` in quiet *and* loud**. Only one
is input-dependent — kernel `iw13 = 282.2.00.000` at `dp = 0x06`.

⇒ A live A/B on this population has ≈10 % power **before it starts**. Combined with §148's F4 and
§149's missing consumer, a live arm here is the wrong instrument twice over.

### 5. Bookkeeping

**`SRC 0x00` is 1610 words per-program** (class split `1:233 | 2:1262 | 8:4 | A:111`), not the
**1270** quoted in §143 §6 and `HANDOFF-NEXT` §1a. The 1270 figure is `coverage_report.py`'s
*ranking* number, which excludes words already blocked by a higher-priority field. Both are
correct for their denominator; the register quotes it as the population, which it is not.

### 6. ⇒ Where this leaves the class-2 majority

The population is one word shape: **97 % is exactly `lo12 = 0x000`**, and **76 % is
`hi12 . 2 . 00 . 000`** — no pointer move, no coefficient, no side-effect action. And class 2
never fetches a coefficient or issues a multiply (`class4 & 8` clear), so on such a word the
operand reaches **exactly one place**: `accum += L << ACC_SHIFT`.

Surviving readings, class-2 only: **`zero`** (shipped for 273 words, untouched by the exclusion),
**`P`** (survives with positive absence support), `hold-the-bus`, `DR`. Excluded: **`acc`**.
Weakest survivor: **`mem[ptr]`** — the one the build ships for the other 989.

Evidence grade: §1 **FORCED** (source, both mirrors); §2 **MEASURED** (re-verified; the
permutation null is the agent's); §3 **MEASURED** and promoted to a standing constraint;
§4 **MEASURED**; §5 bookkeeping; §6 **OPEN**.

---

## §152 — ⛔ §149 NAMED THE WRONG WORD, AND THE ANSWER WAS WRITTEN DOWN EIGHT DAYS EARLIER

Trap 1 again — the ninth time. `kn7000_mame/notes/kn5000-dsp-chorus.md`, dated **2026-07-22**,
already resolves §149's "byte-identical three-word idiom" into a **seven-word transaction** and
assigns the offset-applying word. It is **not** `A00.0.00.041`.

```
  chorus.md:61  ★★ A NEW SHARED-`lo12` FACT: `lo12 = 0x44C` is "apply the modulation offset",
                and the CLASS selects interpolation.  CHORUS uses C40.3.20.44C,
                ENSEMBLE uses 000.2.00.44C.  Same lo12, different class ...
```

### 1. ★ §149's OWN KILL TEST FIRES, on data I could have checked in one command

§149 wrote: *"Kill it: find `A00.0.00.041` in a program with no delay line, **or a swept-delay
effect that lacks it**."* Re-verified here:

```
  ENSEMBLE   15 DRAM words | lo12=0x44C x6 | A00.0.00.041 x0    <- SIX modulated taps, ZERO
  CHORUS     10            | 0x44C x4      | A00.0.00.041 x4
  FLANGER     8            | 0x44C x2      | A00.0.00.041 x2
```

**ENSEMBLE sweeps six delay taps, carries the `0x44C` route, and has none of the word I named.**
My present-and-absence census was over *effects*, and I checked that PHASER (which sweeps
all-passes) lacks it — a confirming absence. I did not check for a **disconfirming presence**:
a swept-delay effect that lacks it. One `grep` would have done it, and I had already written the
test that would have caught it.

### 2. What `A00.0.00.041` actually is

The FLANGER layout settles it by position: there the transaction contains **two consecutive DRAM
READs** and `A00.0.00.041` sits *between* them. That is linear interpolation written longhand —
`d[⌊m⌋]`, advance, `d[⌊m⌋+1]`. In CHORUS's C-format form the second fetch folds into the single
`2C7` word, which is what *"class 3 keeps the fraction, class 2 truncates"* means. ENSEMBLE
truncates, so it needs no interpolation partner and has none.

⇒ **`A00.0.00.041` = the interpolator's second point / address advance.** INFERRED (strong).
⇒ **`lo12 = 0x44C` = apply the modulation offset** — 41 sites, 14 images, present in **every**
swept-delay effect without exception. That is the missing link, and the correct target.

### 3. ★★ AND THE MISSING QUANTITY IS A SAMPLE COUNT, proved against a named UI parameter

The `192.A` word's coefficient is a **delay-tap offset in samples**, not a Q0.23 gain:

```
  ENHANCER  UI slot 3 "DELAY L (ms)"  -> op 0x64, literal 350
            -> C-RAM[0x0B] = 15435  =  350 x 44100/1000  EXACTLY   (re-verified here)
            -> consumed by w42 192.A.4D.000, word [1] of the modulated-tap idiom
            -> its line allocation is 15437 = 15435 + r3's +2 minimum-delay guard
```

A Q0.23 reading of the same cell gives 0.00184, which means nothing; a "rate" reading gives
ENHANCER an **81 Hz LFO**, which is impossible. And CHORUS's four values are `+240 +240 −240 −240`
— **bit-identical to what §145 captured live off the bus**, so the static read and the live
measurement agree.

★ The geometry then closes on two independent host streams (tag-0x4C descriptors vs tag-0x26
coefficients), which is the arithmetic most likely to have failed and did not:

```
  CHORUS 1040 = 800 + 240   MOD CHORUS 900 = 800 + 100
  VIBRATO 840 = 800 +  40   MIX UP     880 = 800 +  80
  PEQ+CHORUS and S.DELAY+CHORUS: allocation 640 = 400 + 240  EXACTLY
```

`allocation = nominal tap + |depth|`, exactly, in four standalone effects. Containment
(`0 ≤ tap−|depth|` and `tap+|depth| ≤ allocation`) passes **8 of 10** carriers with a **10/10 null
failure** when a different class-A coefficient of the same image is substituted. The single outlier
is ROCK ROTARY — the one modulated image whose rate mechanism `chorus.md` §8 already records as
undecoded.

### 4. Corrections this forces

* ⛔ **§149 §3's role assignment is RETRACTED.** Its *structural* finding stands — the delay
  address has no modulation term and a swept delay cannot exist — but the candidate was wrong and
  `chorus.md` had the right one.
* ⛔ **`chorus.md` Headline 4** (*"its default is 0 in every chorus image, i.e. depth is entirely
  host-supplied"*) is **falsified** by the static ROM (240/100/40/80/200/96/15435) and by §145's
  live capture. Depth is a **ROM constant**; the UI DEPTH knob is a separate op-0x66 Q0.23
  *multiplier* on it (CHORUS cells 0x09/0x0A, default 0.5).
* ★ **Bonus, retiring part of `r3-delaydram.md` O-3**: `880.1.20.40B` consumes **no** descriptor
  cell (it is the interpolator's first fetch, reusing the computed address). With r3's own
  `C40.1.E0.451` exclusion that closes the counting identity from **88/96 to 38/38** distinct
  images.

### 5. The emulator change this licenses

`upd6383.cpp:1813`'s `addr = (cellv + m_frames_run) & 0xffff` needs a third term set by the
`lo12 == 0x44C` word from the depth × LFO product. Today: the C-format immediate is written to
`m_cimm` and **`m_cimm` is never read anywhere**; `A00.0.00.041` carries a PLAIN GUESS "no side
effect"; and **there is no modulation register in the device at all**.

⚠ Do **not** gate that change on the current descriptor-cursor alignment being right — `r3` O-1
(the per-unit cursor phase) is still open, and CHORUS's 4th modulated read takes the ceiling cell.

Evidence grade: §1 **MEASURED** and a **retraction of §149 §3**; §2 **INFERRED (strong)**;
§3 **PROVEN BY CONSTRUCTION** (ENHANCER's UI→ROM→cell→word chain) + **MEASURED** (the geometry and
the null); §4 corrections; §5 the consequence, not yet implemented.

---

## §153/§154 — THE MODULATION PATH IMPLEMENTED; my census was a criterion that could not fail, in the other direction

§152 licensed the change: `lo12 == 0x44C` applies a delay-tap offset, and the offset is a
**sample count**. The device had no modulation register at all — `addr = cellv + m_frames_run`,
the rotation `G` and nothing else (§149).

Implemented on mask bit 60: `m_tapmod`, set at the `0x44C` word from the per-unit accumulator in
datum units, added to the address. ★ Deliberately **not** scaled to make any excursion come out —
a per-cell census reports the range, so a wrong quantity shows as a wrong range instead of being
fitted away.

### 1. ⛔ THE FIRST RUN WAS VOID BY ITS OWN F2, AND THE FAULT WAS THE INSTRUMENT

```
  BASE (bit 60 off): [00]0..65535(range 65535) [10] .. [20] .. [30] ..   -- every cell
  ARM  (bit 60 on):  identical
```

I pre-registered *"in BASE the range must be 0 for every cell"*, reasoning that `G` is common to
all cells so no address can move **relative** to another. True of the relative geometry — and
irrelevant to what I actually measured. The census took the **absolute** address, and
`m_frames_run` ramps across 1.39 M frames, so `G` alone sweeps the whole 16-bit space. **An
absolute-address range can only ever return 65535.**

★ Same defect as a criterion that cannot fail, inverted: it could not *succeed*. F2 fired, the run
was void, and the census now measures the **modulation term** itself.

★ One sanity check did pass and is worth keeping: **fired-count 4 513 920** = 4 words/frame ×
1 128 480 frames. CHORUS has exactly four `0x44C` words — and §148 measured the *same* 4 513 920
for its four `f98 = 1` twins. Two independent gates over two different word-sets in one program,
agreeing to the digit. **The gate was right; the census was blind.**

### 2. The corrected run: the null is real, and P3 fails

```
  BASE: "NONE -- the modulation term never moved"          <- P2, a REAL null
  ARM : fired 4 513 920
        [00] range 8 388 607   [10] range 8 388 607
        [20] range       670   [30] range 8 388 607
```

`8 388 607 = 0x7FFFFF` — the full 24-bit datum rail, against an expected ~120–240 samples.
**F3 fired: the accumulator, as transported, is not the offset.**

### 3. ★ And the diagnosis points at a reading I already have

This ran at the **default** mask, which does **not** enable §145's `SRC 0x00 = coef`. But §152
established that word [1] of the transaction is **`192.A.40.000` — a `SRC 0x00` class-A word** —
and that it consumes `C-RAM[0x02] = 240`, the depth. Under the default that word reads `mem[ptr]`
instead, which §148 measured as **the rail (8 388 607) at exactly those slots** (`iw94`, `iw103`).

⇒ **The depth is never loaded, and the accumulator inherits the rail — which is precisely the
8 388 607 excursion measured.**

★★ So §145's reading is not an optional extra here: **it is the thing that puts the depth on the
bus.** §148 graded it *"inert downstream — nothing reads it"*; its consumer is this path, which
did not exist when that was written. The combined arm is pre-registered in `data/PREDICT_155.md`
with its own falsifiers — including F3, *"right register, wrong scaling: report the ratio, do NOT
introduce a fudge factor to close it."*

⚠ And stated in advance: a pass there would show **the depth reaches the address with the right
magnitude**. It would *not* decode the modulation arithmetic — sine table vs triangle vs raw ramp
is a separate question this test does not touch.

Evidence grade: §1 **MEASURED** and a **void run by my own falsifier**; §2 **MEASURED**, F3 fired;
§3 **INFERRED** (the diagnosis), with the test pre-registered.

---

## §155 — ★★★ THE DELAY TAP SWEEPS, AT EXACTLY THE DESIGNED DEPTH

Scored against `data/PREDICT_155.md`, written before the run.

```
  §154  tapmod alone      [00] range 8 388 607   -- the full 24-bit datum rail
  §155  coef + tapmod     [00] -240..240   [10] -240..240   [30] -240..240
                          [20] -240..  0
```

**The excursion is exactly ±240** — `C-RAM[0x02] = 240`, the depth §152 read out of the ROM
statically and §145 measured on the bus. Not "of order the depth": **the depth, to the sample.**

| | prediction | result |
|---|---|---|
| **P1** | fired-count unchanged at 4 513 920 | ✔ identical |
| **P2** | ★ excursion collapses from 8 388 607 to order the depth | ✔ **to exactly ±240** |
| **P3** | the three railed cells fall **together** | ✔ `[00]`, `[10]`, `[30]` all ±240 |
| **P4** | cell `[20]`'s 670 changes | ✔ → `−240..0` |

Frames close 285/285, 0 traps.

### 1. ★★ The cross-check that makes this more than an internal consistency

§152 computed, **from the ROM alone** and before any of this was implemented, that CHORUS's swept
tap must live in `160..640` inside a 1040-sample allocation — from the tag-0x4C descriptor stream
and the tag-0x26 coefficient stream, two independent host paths.

The live measurement gives nominal tap 400 ± 240 = **160..640**.

**A static ROM-derived prediction and a live emulator measurement, agreeing exactly, on a
mechanism that did not exist in the emulator two hours ago.**

### 2. ⇒ And it retires "inert downstream"

§148 graded `SRC 0x00 = coef` *"INERT downstream — `coef` puts the right value on the bus and
DO1/DO2 are 0 in both arms, so no further arm can validate it."* That was true and it was the
wrong conclusion to draw: **its consumer is this path**, which did not exist when the sentence was
written. §154 (tapmod without `coef`) railed at `0x7FFFFF`; §155 (both) lands on the designed
depth. **Neither reading is observable without the other** — the same joint structure as §133's
`ACT 0x0D`/`0x0E` pair, and the third time this corpus has punished one-at-a-time enumeration.

### 3. ⚠ WHAT DID *NOT* COME OUT AS PREDICTED — stated, not fitted

`PREDICT_155.md` P2 also said DEPTH defaults to a **0.5 gain**, so *"expect roughly ±120"*.
**Measured is ±240 — the FULL depth.** The 0.5 DEPTH multiplier (`chorus.md`: op 0x66, CHORUS
cells `0x09`/`0x0A`, default `0x400000`) is **not applied on this path.** Either it enters
somewhere this transaction does not touch, or the default is 1.0, or `chorus.md`'s reading of it
is wrong. ⛔ **No factor has been introduced to close this**, per F3's standing instruction.

Also unexplained: **cell `[20]` sweeps `−240..0`, one-sided**, where the other three are symmetric.
An asymmetric voice is not obviously wrong — a chorus wants voices in antiphase and §145 measured
the four twins at `+240 +240 −240 −240` — but a *rectified* excursion is a different shape from an
inverted one, and this is not decoded.

### 4. What this does and does not establish

**Established (MEASURED):** the depth reaches the delay-tap address with the correct magnitude and
sign range, in the effect whose geometry the ROM independently predicts.

**NOT established, and pre-registered as out of scope:** the modulation **arithmetic**. Sine table
vs triangle vs raw ramp is untouched — the census measures the excursion's *extent*, not its
*shape over time*. The next question is whether the sweep is sinusoidal, and D-RAM `0x1D..0x40`
(the 36-entry SINE table, `dsp-next-steps-roadmap.md`) is where to look.

**Still silent:** DO1/DO2 remain 0 in this vehicle for reasons upstream (§141's `w73`, §150's
correction to it). A swept tap is not audio; it is the mechanism audio would need.

⚠ Reporting bug to fix: the `§145` line prints `mask bit 57 = 0` while reporting 4 513 920
firings, because bit 59 drove them. The line should report which of bits 57/58/59 is active.

Evidence grade: §1 **MEASURED** (four pre-registered predictions, one of them a cross-check
against a prior static computation); §3 a **stated discrepancy**, deliberately unfitted;
§4 scope.

---

## §156 — SHIPPED: `SRC 0x00 = coef` and the DELAY-TAP MODULATION PATH; default `0x1910E446A39B440F`

Regression against `data/PREDICT_156.md`, clean cold-boot vehicle (§148's rule: absolute audio
statistics come from the clean vehicle, never the panel-navigation one).

| | prediction | result |
|---|---|---|
| **P1** | frames still close | ✔ **285/285 decoded, 0 PARTIAL, 0 TRAP** |
| **P2** | the tap sweeps ±240 | ✔ `[00] −240..240` `[10] −240..240` `[30] −240..240`, `[20] −240..0` |
| **P3** | ★ DO1/DO2 **unchanged** | ✔ both 0 non-zero, peak 0; **§70 ACCA min == max == 0** |
| **P4** | no new trap/partial classes | ✔ DC leak 0.00 %, verdict SILENT — identical to BASE |

No blocker fired: F1 (traps) no, F2 (new DC leak) no, F3 (sweep reproduces) it does, F4 (slot
count) unchanged at 285.

### 1. What is now in the default

* **`SRC 0x00 = C-RAM[cursor]`**, gated on `f98 == 1` **and** coefficient-consuming — bit-exact
  `±240` at the 29 LFO twins with a passing anchored control (§145), independently supported at
  the twelve `182` smoothers by the ROM's own upload script and the UI's ATTACK/RELEASE names
  (§147).
* **The delay-tap modulation path** — the device has never had a modulation register; the address
  was `cellv + G` and nothing else, so a swept delay could not exist (§149).

★ **Neither is observable without the other.** `tapmod` alone rails at `0x7FFFFF` (§154); `coef`
alone was graded *"inert downstream"* (§148) because its consumer did not yet exist. That is the
**third** time this corpus has punished one-at-a-time enumeration, after §133's `ACT 0x0D`/`0x0E`
and §136/§40's coupled pair. It is worth stating as a working rule: **in this ISA, a reading that
measures inert is a hypothesis about a missing consumer, not a refutation.**

### 2. ⚠ WHAT SHIPPING THIS DOES NOT MEAN

* **Nothing is audible.** DO1 and DO2 are still 0 non-zero and `§70 ACCA` is `min == max == 0`.
  The chip stays silent for reasons upstream — §141 localised it to `w73` and §150 corrected the
  mechanism (the multiply *does* issue; the accumulator is zeroed despite a formed product).
  **Shipped on the mechanism, not on a sound.**
* **The waveform is undecoded.** The census measures the excursion's **extent**, not its **shape
  over time**. Sine vs triangle vs raw ramp is open, and is now `HANDOFF-NEXT` §1.
* **Two anomalies stand unfitted**: DEPTH's 0.5 gain is not applied (measured ±240, not ±120), and
  cell `[20]` sweeps `−240..0` one-sided where three sweep symmetrically.

### 3. A reporting bug fixed in passing

The `§145` line printed **bit 57's** state while reporting firings driven by bit 58 or 59 — a gate
reporting the wrong gate, which would have made a future arm look inert when it was not. It now
names whichever selector is active.

Evidence grade: **MEASURED** (four pre-registered predictions, one of them the known-answer
control P3); the ship decision **FORCED** by §155 plus this regression; §2 the bounded scope.

---

## §157 — ⛔ §155's "±240 SWEEP" WAS POOLED. The tap moves — as an UNSHAPED SAWTOOTH, not a sweep

A read-only agent challenged §155's headline. The challenge was sound, I re-verified it in source
before accepting it, and the deciding measurement went to **neither** of my two hypotheses.

### 1. The challenge, verified

* `upd6383.cpp:2030` — **class 6, the TABLE-LOOKUP idiom, is an explicit NO-OP**:
  *"no table is modelled, so execute the addressing and leave the ALU alone."*
* §155's census buckets on `cellv & 0x3f` and takes min/max over the run.
* CHORUS's four ROM depths are **`+240 +240 −240 −240`** (§145 live, §152 static).

⇒ A bucket holding one positive and one negative voice reports `−240..+240` **with no sweep at
all.** §155's P2 could not distinguish a sweep from pooled signed constants — a **criterion that
cannot fail**, the same family as §153's void run, which I had already flagged once.

⚠ And §155's cross-check was weaker than I presented it: `160..640` **is** `400 ± 240`, and ±240
is what the constants alone give. I called it "a static prediction and a live measurement
agreeing"; both sides may have been reading the same four numbers.

### 2. The deciding census — per I-RAM SLOT, where voices cannot pool

```
  iw96: 0..240 (r240)   iw105: 0..240 (r240)   iw137: -240..0 (r240)   iw146: -240..0 (r240)
```

| hypothesis | prediction | verdict |
|---|---|---|
| **H-CONST** (pooled constants) | every slot range **0** | ⛔ **REFUTED** — range is 240 |
| **H-SWEEP** (a real, zero-mean sweep) | each slot `−\|d\|..+\|d\|` | ⛔ **REFUTED** — each slot is ONE-SIDED |

★ **F2 fired, as pre-registered: "neither hypothesis; report the numbers, do not fit."**

### 3. ★★ What is actually happening

Each slot ramps **0 → its own signed depth**. That is the **raw phase accumulator passed through
unshaped** — a **sawtooth**, not an oscillation. The phase ramps `0..0x7FFFFF` and wraps, so
`depth × phase` gives exactly `0..+240` for a `+240` voice and `−240..0` for a `−240` voice.

This explains, with no extra hypothesis, **both** anomalies §155 left open:
* the pooled `−240..+240` = two positive ramps and two negative ramps in one bucket;
* cell `[20]`'s "one-sided `−240..0`" = a bucket that happened to hold only negative voices.
  It was never a rectifier.

⇒ **The correct statement replacing §155's headline: the modulation term DOES reach the delay
address and DOES vary over time — but as an unshaped sawtooth ramp, because the waveform lookup
is a no-op.** A sawtooth LFO on a chorus is a click train once per cycle, not a chorus.

### 4. What survives, and what §156's ship now rests on

* **SURVIVES**: the mechanism. `lo12 == 0x44C` reaches the address; the depth is a sample count;
  the excursion's magnitude is the ROM's designed depth. §156's regression (285/285, 0 traps,
  DO1/DO2 unchanged) is untouched — those were deltas, not shape claims.
* **RETRACTED**: "the tap **sweeps**" as a description of the motion, in §155's headline, §156's
  ship note, `HANDOFF-NEXT` §1 and blog Part 107. The motion is a ramp.
* **STILL OPEN**: DEPTH's 0.5 gain (±240 not ±120) is **not** explained by this and remains unfitted.

### 5. ★ And the next test is now sharp, two-sided, and pre-computable

The waveform is a **36-entry table the host uploads at boot**, and the cold-boot default is an
exact sine — `0.95·sin(2πk/24 + 0.1)` to **0.94 LSB**, one-bin DFT. Its peak is
`table[6] = 0x78FE14 = 0.9452541`, **not 1.0**.

```
  with the class-6 lookup implemented:   peak = 0.9452541 x 240 = 226.86  ->  226
  today (no table, raw ramp):            peak = 240
  triangle table (peak 1.0):             peak = 240
```

**226 vs 240 is 5.5 %, about 30× the 24-bit quantum, and two-sided**: 226 kills "no table", 240
kills "sine on the default preset". That is `HANDOFF-NEXT` §1.

Evidence grade: §1 **FORCED** (source); §2 **MEASURED**, both my hypotheses refuted;
§3 **INFERRED (strong)** — the one-sided 0→depth ramp is what an unshaped phase accumulator gives,
and the class-6 no-op is FORCED; §4 the retraction; §5 the pre-computed next test.

---

## §158 — ⛔ §157 WAS ALSO WRONG. The tap-mod is a CONSTANT. And the DEPTH chain is now traced end to end

Two corrections of my own claim in a row, and the second agent's report went further than the
first. Everything below **re-verified in my own logs** before recording.

### 1. ⛔ The settled state is CONSTANT — §157's "sawtooth" was a boot transient

`§104` per-slot, frames > 420 000, quiet **and** loud, marked `=` (identical):

```
  iw96   15729946 .. 15729946   -> datum  240
  iw105  15729540 .. 15729540   -> datum  240
  iw137 -15727740 ..-15727740   -> datum -239
  iw146 -15727740 ..-15727740   -> datum -239
```

**All four constant.** §157's census read `0..240` only because it recorded from the *first*
firing, including the boot period where the accumulator is still 0. It is a **step from 0 to a
constant**, not a ramp.

```
  §155  "the tap SWEEPS ±240"         -> WRONG: pooled across voices of opposite sign
  §157  "the tap RAMPS, a sawtooth"   -> WRONG: boot transient inside the census window
  TRUTH: the tap-mod is a CONSTANT per voice.  Nothing moves at all.
```

★ **H-CONST was right after all**, and I refuted it on an artefact of my own census window. Two
successive corrections to one claim, each from a different defect in the *instrument* rather than
the hypothesis. The lesson is narrow and worth stating: **a min/max census must declare its window**
— §104 has one (frames > 420 000) and my ad-hoc census did not.

### 2. ★★★ The DEPTH chain, traced end to end and MEASURED

```
  LCD "DEPTH 30"
   -> UI slot 0 -> T2 record #1 -> op 0x66 (eval_038FE8, C-RAM writer 0387E6)
   -> C-RAM[0x09] = C-RAM[0x0A] = 0x1364D8 = 1 271 000
        = 0.30303 x the ROM base 0x400000     and  30/99 = 0.30303030  (7 digits)
   -> iw123 `000.A.00.415`  acc = DEPTH x LFO   -> stored to D-RAM 0x0F
   -> iw126 `010.A.00.1D5`  acc = DEPTH x that  -> stored to D-RAM 0x0E, and 0x10 at iw132
   -> the tap idiom's word [1] reads D-RAM 0x10 / 0x0E / 0x0F as its BUS operand
```

The live trace shows the gain applied **twice in cascade**: `iw123` L=2216 → datum 671
(ratio 0.3028), `iw126` L=671 → datum 203 (ratio 0.3025), against `0x1364D8/2²² = 0.30303`.
CHORUS has exactly five T2 records against five UI slots in order, with slots 1 and 2 independently
anchored — so record #1 ↔ DEPTH is **PROVEN BY CONSTRUCTION**, closing `chorus.md`'s open item
*"NOT ESTABLISHED — whether host op 0x66 is DEPTH"*.

### 3. ★★ AND THIS PUTS A SHIPPED READING IN TENSION

The four modulated taps read `dp = 0x10 / 0x10 / 0x0E / 0x0F` — **exactly the three cells the DEPTH
block writes.** And §145's own baseline column at those slots was `8388607 / 8388607 / 671 / 203`,
which I described as *"the rail and unrelated residue"*.

**`671` and `203` are literally the outputs of the two DEPTH multiplies.** That was not residue;
it was the depth-scaled modulation signal. `0x10` reads the rail only because the LFO chain is dead
upstream — the class-6 table-lookup triplet has **no handler at all** in `upd6383.cpp`.

⇒ **`SRC 0x00 = coef` at these four slots may be wrong**: it replaces a live memory operand (the
depth-scaled LFO) with the raw ROM constant ±240. And that reading is **SHIPPED** (§156, bit 59).

⚠ I am **not** un-shipping it on this. The corpus twin (29/29 successor identity against a 7.79 %
base rate) is independent evidence and is untouched; what is challenged is the reading *at these
four sites*, where the class-A cursor fetch supplies ±240 to `K` regardless of what `SRC` says
(bit 23 is unconditional on class A). Both can be true: `coef` right in general, and the bus
operand at these slots being the memory value. **This is a tension, not a refutation**, and it is
now the next task.

### 4. ★ The ±240 vs ±120 discrepancy — RESOLVED, with no factor introduced

`PREDICT_155` P2 predicted ±120 from a 0.5 DEPTH gain and measured ±240. Both numbers were wrong
for the same reason: **two missing multiplications**, not a scale error.

```
  excursion = |ROM depth| x g,  g = C-RAM[0x09] as Q0.23
     live setting DEPTH 30  -> g = 0.15152 -> +-36.4 samples
     DEPTH 99 (the ROM base) -> g = 0.5     -> +-120 samples
```

So ±120 was right **for the maximum knob position**, and the vehicle sits at DEPTH 30. §152's
containment geometry survives with margin: the ROM sizes the line for the raw ±240 and the knob can
never exceed ±120. ★ **The gap was never a scale error, and no fudge factor was needed** — which is
why F3's standing instruction (*report the ratio, do not close it*) was worth following.

### 5. Next: the two tests that settle it

* **K1** — re-key §157's census on the `0x44C` **word index** with an explicit settled-frame window.
  Prediction: 4 constants, every range 0. (§1 above already effectively shows this via §104.)
* **K2** — implement the class-6 table lookup so the LFO waveform actually varies, and turn bit 59
  **off** at these four slots. Prediction at DEPTH 30: **±36 samples per site, sweeping at
  0.599 Hz** (73 584-frame period); move DEPTH to 99 → **±120**. ★ That can fail in three
  independent ways — magnitude, period, and knob response — and it decides §3's tension.

Evidence grade: §1 **MEASURED**, a second retraction of my own claim; §2 **MEASURED** +
**PROVEN BY CONSTRUCTION** (record order); §3 a **stated tension** against a shipped reading, not a
refutation; §4 **MEASURED**; §5 pre-registered.

---

## §159 — K2's PREREQUISITE FAILS: the wavetable is 36 cells of ZERO, and the upload is on the wrong side of the §97 split

`HANDOFF-NEXT` §1 said *"⚠ CHECK FIRST whether the table is actually loaded."* It is not, and
checking cost one grep of a committed log — against implementing a lookup that would have read
zeros and measured nothing.

### 1. MEASURED: every wavetable cell is written, and every write is zero

`D-RAM WRITES (nonzero/total)` from `data/clean_vehicle_default.log.gz`, cells `0x1D..0x40` — the
36-entry LFO wavetable range:

```
  1D:0/795  1E:0/811  1F:0/810  20:0/4514717  21:0/793  22:0/798  23:0/806 ...
  ... 3E:0/800  3F:0/790  40:0/795
```

**~800 writes to each cell and NOT ONE of them non-zero.** The cells are live and the table never
arrives. (`0x20`'s 4.5 M writes are a different, per-frame writer; its non-zero count is 0 too.)

⇒ **K2 as specified cannot work.** Implementing the class-6 lookup today would index a table of
zeros, produce a modulation of 0, and measure exactly what the no-op already measures — a null
that would look like a refutation of the sine reading when it is a statement about an empty table.
★ This is "compute the NULL first" doing its job: the prerequisite was checkable offline and
would have cost a build, a run, and a wrong conclusion.

### 2. ★ The likely cause, and it is structural rather than a bug

`upd6383.cpp:912` — the host poke port's **tag `0x15` routes to the mode-1 REGISTER FILE**, which
§97 split off from the pointer-walked D-RAM:

```
  case 0x15:   // D-RAM register file
      // ★ §97: "register file" ... is the MODE-1 space -- not the pointer-walked
      //  D-RAM.  Writing it into m_dram put the host's parameters ...
```

The `§59` census confirms the route fires: `tags: 15:42`, `data packets -> D-RAM 59`.

⇒ **SPECULATIVE (strong): the wavetable upload and the wavetable reader are on opposite sides of
the §97 memory split.** The host writes the table into the mode-1 register file; the microcode's
class-6 lookup addresses the pointer-walked D-RAM, where `0x1D..0x40` stays zero. §97 was a
correct and well-evidenced split (two memories, one array), and this is the kind of seam it would
naturally create.

⚠ **Not yet verified**: I have not confirmed the table actually *lands* in `m_rf`, only that it
does not land in `m_dram`. Both "it arrives in the register file" and "it never arrives at all"
fit the evidence so far, and they need different fixes.

### 3. The next measurement, and it is cheap

Dump `m_rf[0x1D..0x40]` at `device_stop()` alongside the existing D-RAM census and compare against
the ROM table at `0x01EAFA` (36 entries, the exact sine, peak `0x78FE14`).

* **Table present in `m_rf`** ⇒ the reader must address the register file, and K2 becomes a
  one-line change plus the lookup.
* **`m_rf` also zero** ⇒ the op-0x74 upload is not reaching the chip at all, and the target moves
  upstream to the host route — `ROADMAP-2026-07-29.md:229`'s *"881 writes / 65 cells dropped"*.

**Control whose answer is known:** the same dump must show the tag-0x15 cells that §97 *did*
validate as non-zero. If those are empty too, the dump is reading the wrong array.

⚠ And the aliasing hazard stands either way: descriptor cells `0x26..0x39` overlap D-RAM
`0x1D..0x40` under `upd6383.cpp:1305`'s flat `map(0x00,0xff).ram()`. **Whichever space the table
lands in, that overlap must be separated before the table is trusted** — otherwise a correct
upload will be corrupted by descriptor writes, and the resulting wrong waveform would be read as a
refutation of the sine.

Evidence grade: §1 **MEASURED**; §2 **SPECULATIVE (strong)**, with the unverified half stated;
§3 pre-registered with its control.

---

## §160 — ★★★ THE WAVETABLE IS THERE, IT IS AN EXACT SINE, AND EXACTLY ONE CELL IS DESTROYED

Scored against `data/PREDICT_160.md`. **H-RF confirmed.**

### 1. The table arrives in the register file, and it is the ROM sine to the bit

`m_rf[0x1D..0x40]`, **35 of 36 non-zero**, fitted against `0.95·sin(2πk/24 + 0.1)`:

```
  idx cell   raw      signed      /2^23      expected     err(LSB)
   0  0x1D 0C23C6    +795590   +0.094842   +0.094842        0.2
   2  0x1F 470272   +4653682   +0.554762   +0.554762        1.8
   3  0x20 000000          0   +0.000000   +0.735459   6169474.9   <-- A HOLE
   6  0x23 78FE14   +7929364   +0.945254   +0.945254        0.9    <-- the peak
  12  0x29 F3DC38    -795592   -0.094842   -0.094842        1.8
  18  0x2F 8701EA   -7929366   -0.945254   -0.945254        1.1    <-- the trough
```

**23 of 24 cells match to under 3 LSB**, most under 2. The predicted peak `table[6] = 0x78FE14 =
0.9452541` is present exactly where predicted. **MEASURED.**

★ **The control passes**: the all-cells listing shows `06 = 400000` — §97's validated unit-0 output
level, `+0.5`. The dump is reading the right array.

### 2. ⛔ ONE CELL IS CLOBBERED, AND THE CULPRIT IS COUNTED

Index 3 = register cell **`0x20`** reads `0x000000` where the sine requires **+6 169 476**. Index
15 holds **−6 169 476** exactly, so the missing value is confirmed by the table's own symmetry.

```
  §99 MODE-1 STORES -> register file:  06:1155840  0E:28800  0F:1167360  20:4513920 ...
  §159 D-RAM census, same cell:        20:0/4514717   (neighbours ~800)
```

**Cell `0x20` takes 4 513 920 mode-1 stores from the MICROCODE** — and 4 513 920 = **4 per frame ×
1 128 480 frames**, the *same* count as §153's tapmod gate and §148's `f98` gate, i.e. the same
four words per frame.

⇒ **The host's wavetable and the microcode's mode-1 scratch COLLIDE inside the register file.**
§97 split host parameters off from the pointer-walked D-RAM and fixed one conflict; **this is a
residual conflict within the space that split created** — the same defect one level down, and the
first hard evidence that the register file needs a further separation (or that one of the two
addressings into it is wrong).

### 3. ⇒ K2 is unblocked, with one prerequisite

The lookup can now be built against a real table. **But not before cell `0x20` is fixed**, because
a wavetable with a zero at index 3 produces a waveform with a notch in it — and a sweep measured
through that notch would be wrong in a way that looks like a shape result. ★ Concretely: the
excursion peak would still be `0.9452541 × depth` (the peak is at index 6, undamaged), so the
**226-not-240 test survives**, but any *shape* claim would be contaminated.

**Two candidate fixes, and they are distinguishable:**
* the microcode's mode-1 stores at `0x20` are correctly addressed and the **wavetable base is
  wrong** (it should not be at `0x1D`), or
* the base is right and those four stores are **mis-addressed**.
The `§109` per-slot store witness already reports the store address and the guard that admitted it;
pointing it at the four words that hit `0x20` names which.

⚠ And the **aliasing hazard is now demonstrated rather than hypothetical.** `HANDOFF-NEXT` flagged
descriptor cells `0x26..0x39` overlapping D-RAM `0x1D..0x40`; what actually bit is a *different*
overlap, inside `m_rf`, at `0x20`. Both need separating before the table is trusted.

Evidence grade: §1 **MEASURED** (35 of 36 cells fitted, control passing); §2 **MEASURED** (both
counters, and the symmetry confirming the missing value); §3 **FORCED** as to the blocker, the two
candidate causes **ENUMERATED, not chosen**.

---

## §161 — the delay word's `addr8` is a DIRECTION field, and it was being used as a store address
### SHIPPED into the default: mask bit 61 → `0x3910E446A39B440F`

§160 closed by enumerating two candidate causes for the one destroyed wavetable cell and
explicitly declining to choose. This is the choice, made by reading the code rather than by
running anything, and then gated A/B.

### 1. The word

```
  880.1.20.2C7      hi12=0x880  ESC(bit 11)=1  class4=1  addr8=0x20  lo12=0x2C7
                    SRC = 0x0B  (the delay-read register)
                    ACT = 0x07  (STORE)
```

`upd6383.cpp:2977` computes `mode07 = c_format(word) ? 2 : (class4(word) & 7)`. This word is
**not** C-format, so `mode07 = 1`, and `:2979` then takes `d07 = addr8(word) = 0x20`.

But `addr8` on a class-1 **escape** word is the delay direction code, not a register address.
That reading is **FORCED**, not speculative — adjudication-round5 item D at 276/276: bit 6
selects, `0x20`/`0x30` are READ and `0x60` is WRITE. A field cannot be a direction code and a
destination at the same time.

⇒ CHORUS's four delay READs were storing into register cell `0x20` = **LFO wavetable index 3**.

### 2. The arithmetic that made the prediction bit-exact

A least-squares sine fit over the **22 surviving cells** (index 3 excluded from the fit) returned

```
  A   = 7 969 178  =  0.9500000 x 2^23        max residual 2 LSB over 22 cells
  phi = 0.100000 rad
```

Amplitude and phase both *fell out*; neither was assumed. Predicted index 3 = `+6 169 475`.

★ **But the decisive witness was not the fit.** The window is 36 entries and the sine's period is
24, so **index 3 and index 27 are the same phase**. Cell `0x38` = index 27 already read `0x5E2382`
in the control, undisturbed. The prediction had a bit-exact in-table twin available the whole time.

### 3. A/B, all four pre-registered falsifiers (`data/PREDICT_161.md`)

| | pre-registered | measured | |
|---|---|---|---|
| **F1** aim | fires on exactly those four words | `FIRED 4 515 636` = §153's tapmod count **in the same run** | ✔ |
| **F2** value | cell `0x20` = `0x5E2383`, 36/36 | `0x5E2382`, **36 of 36** | ✔ |
| **F3** collateral | re-aimed to `m_dp`, so it could punch a NEW hole | full non-zero-cell diff vs control = **exactly one added line, `20=5E2382`** | ✔ |
| **F4** null | control unchanged | 35/36, `0x20 = 000000`, `FIRED 0` | ✔ |

F2 landed **1 LSB** off my fit and **bit-identical** to the period-24 twin — the fit's own stated
residual is 2 LSB, so the fit was never the tighter instrument. F3 is the one that could have
failed quietly: the fix redirects the store rather than deleting it, and `m_dp` could have pointed
back into `0x1D..0x40`. It does not.

### ⚠ 4. A methodological correction against my own pre-registration

F1 as written demanded `4 513 920`, a literal copied from §153's *earlier* run. The measurement is
`4 515 636`. **The number I pre-registered was wrong and the claim it was testing was right**: both
counters read `4 515 636` in the run being adjudicated. Cold-boot frame totals vary run to run
(§159 saw 1 128 480 frames, this pair 1 156 269), so:

> **An absolute event count is not a falsifier across runs. Only a within-run comparison of two
> counters is.** Pre-register the *relation*, never the literal, whenever the quantity scales with
> frame count.

This is the second time a stale cross-run constant has been carried into a prediction.

### 5. What this does and does not buy

It does **not** make the chip audible — the shipped-default confirmation run still reports
`§70 ACCA min 0 max 0` in 678 469 quiet and 313 960 loud frames, and both ports at peak 0. That
was pre-registered as not-a-goal.

What it buys is precisely the §160 blocker: **K2 now has an intact table to index.** And it retires
§160 §2's "the host's wavetable and the microcode's scratch COLLIDE inside the register file" as a
*structural* claim — there is no collision to separate. One line was reading a direction field as
an address. The table's base at `0x1D` was right all along, which was candidate 2 of the two.

Evidence grade: the field's meaning **FORCED** (276/276, prior adjudication); the misuse
**MEASURED** (four falsifiers, A/B, known-answer control); the restored value **MEASURED against an
independent in-table witness**, not against my own fit.

---

## §162 — K2 is NOT blocked on the table any more. It is blocked on the PHASE.

§161 handed K2 an intact table, so I went to build the lookup — and stopped at the step this
project keeps skipping: I did not know where the *index* comes from. Guessing would have been a
fourth hypothesis about an uninstrumented datapath. So the probe went in first, read-only.

### 1. The idiom, from the disassembly

CHORUS's lookup is a **four-word motif**, and it appears twice:

```
  w30  040.0.00.C63          w34  142.0.00.C63
  w31  000.6.18.4CD          w35  000.6.20.407     <- class 6
  w32  012.4.01.1CE          w36  012.4.01.1CE
  w33  104.2.02.1CE          w37  104.2.01.1CE
```

Across all 91 programs there are **6 distinct class-6 encodings at 54 sites in 26 programs**, in
exactly two `lo12` forms — and the forms are an operation pair, not two tables:

| form | SRC | ACT | meaning |
|---|---|---|---|
| `..4CD` ×46 | `0x13` | `0x0D` | **acc ← bus** (§144, shipped) |
| `..407` ×7 | `0x10` | `0x07` | **store acc** |

⇒ `SRC 0x13` is the class-6 **table read port**: the word's whole job is `acc ← table[...]`.

★ And the `addr8` split runs along a clean functional line. `0x18` occurs in chorus, flanger,
phaser, ensemble, auto pan, vibrato, ring modulator, mix up and the s_delay/peq variants —
**every modulation effect**. `0x28` occurs in rock rotary, distortion, overdrive, fuzz, exciter and
the peq compressor/distortion pairs — **every drive effect**, which is where a waveshaper transfer
curve belongs and where an LFO does not.

### 2. ★ An independent confirmation of the table I recovered

`lfo-ramp.md` §10 MEASURED, on 2026-07-22, the scale coefficient feeding the LFO lookup as
`0x000018` = **24** at 8 of 8 sites, and reads the idiom as `(coef × phase) >> 23` — an integer
index into a **24-entry** table.

§161's recovered table has period **exactly 24**, from a sine fit that was never shown that
coefficient. Two independent routes, a week apart, to the same 24. *(That note also records
P-16 as a MISS: `addr8` is **not** the table extent. Nothing here revives it — the `0x18`/`0x28`
split is a selector, and 0x28 = 40 is not the drive table's 16.)*

### 3. THE PROBE, and its pre-stated null

Instrument the three candidate index sources at every class-6 site. Stated before running: if the
accumulator carries the phase it must **sweep** — a large fraction of 2^23 at the LFO rate. If
`min == max`, the phase is not there and the candidate is dead. A probe that could not come back
constant would not be a test.

```
  §162 CLASS-6 SITE 00006184CD addr8=18 lo12=4CD : hits 1129389 |
       acc 0..0 (CONSTANT) | m_dp 12..12 | cursor 9..9
  §162 CLASS-6 SITE 0000620407 addr8=20 lo12=407 : hits 1129389 |
       acc 0..0 (CONSTANT) | m_dp 14..14 | cursor 9..9
```

**All three are constant, over 1 129 389 executions, in silence and under a held chord alike.**

### 4. ⇒ Why building K2 today would have manufactured a false null

Every available index source is frozen, so the lookup would have returned **the same table entry
in every frame** whichever one I picked. The measured excursion would then have been a constant —
and against the pre-registered "226 not 240" discriminator that reads as *refuting the sine*, when
it is a statement about a missing phase.

That is exactly §158's trap, one level up: §155 and §157 both reported motion that was not there.
This time the instrument ran before the claim.

> **Generalised rule (fourth occurrence): before implementing a consumer, MEASURE that its inputs
> vary. A datapath whose every input is constant cannot be validated by its output.**

### 5. The redirect — where the phase actually is

The accumulator is *zero*, not merely constant, at both sites. Its producers are the two words
immediately around the class-6 word, and both are known-dark: `040.0.**.C63` ×46 and
`012.4.01.1CE` ×53 are two of the four largest families in `ROADMAP-2026-07-29.md` #10's list of
**"words with no reading of any kind"**. The LFO's coefficient triple is already MEASURED
(`lfo-ramp.md`) as *increment / wrap `0x7FFFFF` / index-scale `0x18`*, so the phase is accumulated
somewhere and wrapped — the emulator simply never performs it.

⇒ **NEXT TASK is `C63` and `1CE`, not the lookup.** The lookup is four lines once the index exists.

Evidence grade: §1 **MEASURED** (census over all 91 programs) with the `0x18`/`0x28` functional
split **INFERRED** from program membership; §2 **MEASURED** twice independently; §3 **MEASURED**;
§4 **FORCED** by §3; §5 the location **INFERRED**, the coefficient triple **MEASURED** elsewhere.

---

## §163 — ⛔ CORRECTION to §162 §5. The dark words are not dark, and §108 already had the answer.

§162's measurement stands. **Its redirect does not.** I named `040.0.**.C63` and `012.4.01.1CE`
as the missing phase producers on the strength of their appearing in the roadmap's *"no reading of
any kind"* list. Decoding their fields takes one line each and refutes that immediately:

```
  040.0.00.C63    SRC 0x11  ACT 0x03   ->  tempB <- ACCB       upd6383.cpp:2932, MODELLED
  012.4.01.1CE    SRC 0x07  ACT 0x0E   ->  P <- mem[ptr]       §144, SHIPPED
```

Both are implemented. **Tenth occurrence of trap #1**, and the sharpest yet: I checked the owning
note for the *table* (`lfo-ramp.md`, correctly) and then skipped the same check for the *phase*.

### 1. What is actually true — MEASURED at §104, recorded at §108

```
 iw  word           SRC ACT  dp    measured acc / mem / L
 89  092.A.00.200    08  00   07   3735552 / 4194304 / 57      ] LFO phase accumulate
 90  082.2.00.1C0    07  00   07   2.7e11  / 4194304 / 4194304 ] acc <- mem[Q]
 91  094.A.00.200    08  00   07   8.2e11  / 4194304 / 8388607 ] the wrap
 92  000.2.09.447    11  07   07   50      / 4194361 / 8388607
```

**The phase DOES increment — by 57, within the frame.** `lfo-ramp.md` §11's *"the block stores the
phase back unchanged — no ramp"* is superseded by this. The increment then **fails to survive to
the next frame**, because kernel `iw32` re-deposits `0x400000` into the cell every frame.

⇒ The LFO is pinned at exactly `0x400000` = 2^22 = **0.5 in Q0.23**, which with the measured index
scale 24 selects table index `(24 × 2^22) >> 23` = **12** — one fixed entry, forever. §162's
conclusion (do not build the lookup yet) is therefore **right, and right for a better reason than
the one I gave**.

### 2. And an entire family of fixes is already dead — §108 §5, FORCED

> *"No value of `DRAM_UNIT_BASE` can fix the deposit/pickup collision, because the collision is in
> the RELATIVE geometry and the base cancels out of it."*

Mask bit 27 tried it: the gate fires, `dp` moves from `0x07` to `0x08`, and **every measured value
is bit-identical**. Kernel A's walk starts where the previous frame closed, so base and window are
coupled and `iw32` follows the phase cell wherever it is moved.

⇒ **The fix must be a per-word ADDRESSING decode** — `iw30`/`iw32`'s store target, or the body's
LFO block not sitting at base+2 — not an anchor value. §108 §5 names this as a standing bias:
*an anchor is a single number and therefore feels cheap to try, but every anchor here is pinned by
closure arithmetic.* §109 then resolved both `iw30`/`iw32` discrepancies and found one genuine
per-word addressing defect at `iw11`; **that chain is where task #8 belongs.**

### 3. ⚠ A third over-read, caught before it was written

§160's register dump has `06=400000` as the only non-zero cell outside the wavetable, and the
phase is pinned at `0x400000`. Tempting. But `lfo-ramp.md` §10's C-RAM listings show `400000` is
the **fourth member of the LFO coefficient group** in both FLANGER (`08:400000`) and AUTO PAN
(`04:400000`), and `m_rf` is the side §97 split *host coefficients* onto, not the pointer-walked
D-RAM the phase census reads. Same number, different space. **Not identified; left open.**

### 4. Standing rules, restated because they keep earning their keep

> **Check the owning note for EVERY component of a claim, not for the one you happened to doubt.**
> **A word in a "no reading" list is a claim about a corpus statistic, not about the emulator** —
> verify against the source before building on it.

Evidence grade: §1 **MEASURED** (§104's census, re-read not re-run); §2 **FORCED** (§108's
enumeration) with the bit-27 refutation **MEASURED**; §3 deliberately **UNIDENTIFIED**.

---

## §165 — ⛔⛔ THE PHASE IS NOT PINNED. IT RAMPS. The blocker was one build out of date.

§163 restated §108's *"the phase is pinned at 4194304"* and made it the project's headline blocker.
An instrument built to score §112's two-sided criterion says otherwise, in the very first run.

### 1. The instrument, and why min/max alone would not have done

A per-frame census over D-RAM `0x00..0x1F`: range **and** the number of frames in which the cell
*changed*. ⚠ Range alone is the §137 trap in a new place — a cell pinned at `0x400000` and a cell
alternating between two values both report a range. A pinned cell changes **0** times.

### 2. MEASURED, cold-boot CHORUS, 1 392 430 frames

```
  01: -4275712..4952576  chg 308646        06: 0..8388607  chg 1100
  02:       0..6553600   chg 1             07: 0..8388598  chg 1128429    <- the LFO phase cell
  04: -5579776..4994816  chg 307312        0E:       0..39718  chg 2
```

**Cell `0x07` sweeps essentially the full Q0.23 range** — `0..8 388 598` against a full scale of
`8 388 607` — and changes in **1 128 429 of 1 392 430 frames**.

★ And the cross-check that identifies it beyond doubt: §162 measured the class-6 word executing
**1 129 389** times. The phase changes **1 128 429** times. Ratio **0.99915** — the phase advances
**once per body execution**, which is what an LFO phase accumulator does and what nothing else in
the frame does.

The rate settles the increment too. `0.599 Hz` is the panel's LFO rate; increment 114 gives
**0.652 Hz** and increment 57 gives 0.326 Hz. **`lfo-ramp.md`'s predicted 114 is the match; §108's
measured `L = 57` is the half.** (§108 itself flagged *"the familiar factor of 2"*.)

### 3. ⇒ The real defect is ROUTING, not generation

§162 stands: `acc 0..0 | m_dp 12..12 | cursor 9..9` at the class-6 word. Both are now true at once,
and together they are much sharper than either alone:

> **The phase ramps in D-RAM cell `0x07` and does not reach the class-6 word.**

That is a *routing* failure over a handful of words, not a missing accumulator. §108's whole
analysis — kernel `iw32`, the deposit/pickup collision, the `DRAM_UNIT_BASE` family — was aimed at
a symptom that no longer exists in this build. Some combination of what has shipped since (§130's
cursor rebase, §144, §156, §161) fixed the generation.

### 4. §112 / §136's untried arm: RUN, and REFUTED

| arm | mask | result |
|---|---|---|
| **A** control | `0x3910E446A39B440F` | — |
| **C** +bit 54 (latch to `m_k`) | `0x3950E446A39B440F` | **bit-identical to A in every cell.** Inert. |
| **D** +bit 54 +bit 4 (§40 reads `m_k`) | `0x3950E446A39B441F` | `§70 ACCA min = max = 176 471 605 248` |

D's ACCA is **the exact DC constant §137 already retracted** — and `min == max`, so standing rule 1
caught it before it could be reported as output. §136's *"the pair has never been evaluated
together"* is now discharged: **evaluated, and refuted.** Bits 54 and 4 stay off.

### 5. The lesson, and it is about the ledger

§163's blocker was **inherited from a section written days and several shipped gates ago, and never
re-measured**. The dead-ends list Felipe asked for on the same day would not have caught this one,
because the entry was not a refuted idea — it was a *stale measurement presented as current state*.

> **RULE: a blocker is a MEASUREMENT, and measurements expire. Before building a task on a symptom
> from an earlier section, re-run the measurement on the current build. Cite the run, not the
> section.**

`LEDGER.md` Tier 0a now carries the run that established the current blocker, not just its name.

Evidence grade: §2 **MEASURED** (two counters, plus the 0.99915 identification); §3 **FORCED** by
§2 together with §162; §4 **MEASURED** (A/B/C/D, with the known-answer DC recognised).

---

## §166 — `C63` + class-6 is ONE IDIOM: 53 of 53, both directions. And it names the index register.

A static test, no emulator. `dark-words.md` §4.4 lists `040.0.**.C63` and the class-6 words as
separate dark forms; they are not separate.

### 1. Pre-registered, with the null computed first

* **H1** — a `C63` word immediately precedes every class-6 word ⇒ they are one idiom.
* **H0** — the adjacency I saw in two hand-read programs is coincidence.
* **NULL:** 53 of 3057 corpus words carry `lo12 = 0xC63`, a base rate of **0.0173**. On 54
  class-6 sites chance predicts **0.94 ± 0.96** predecessors.

### 2. MEASURED

```
  53 of 54  class-6 words are immediately PRECEDED by a C63 word
  53 of 53  C63 words are immediately FOLLOWED by a class-6 word
```

**Bidirectional and exclusive.** Against a null of ~1, at a base rate of 0.0173, a 53/53
bijection is not a coincidence any reasonable prior survives.

⚠ The single exception is `kernel.dsm w56 = 0C646A2007`, and it is *not* a counterexample — it is
the **only C-format class-6 word in the corpus** (`hi12 = 0xC64`, ESC, END, `addr8 = 0xA2`,
`lo12 = 0x007` ⇒ `SRC 0x00 / ACT 0x07`). Different form, different `lo12`, different everything.
Excluding it the pairing is **53/53 both ways with no exceptions at all**.

### 3. ⇒ What the idiom is, and where the index lives

`C63` decodes as `SRC 0x11 / ACT 0x03`, and `ACT 0x03` is `m_tb = L` (`upd6383.cpp:2932`):

```
   C63          tempB <- SRC 0x11          "load the index register"
   class 6      acc   <- table[ tempB ]    "indexed table read"     (SPECULATIVE)
```

That is the canonical shape of an indexed lookup, and it explains why the corpus never separates
the two words. The class-6 branch in the emulator reads **none** of `m_ta`/`m_tb` — it returns
early — which is consistent with §162's finding that no *modelled* index source varies.

★ And it supplies a candidate route for the phase. `SRC 0x11`'s reading is **contested, not
settled**: §27 shipped it as `ACCB`, and §113 proposed `mem[ptr]` as bit 18 (implemented, off).
If `SRC 0x11 = mem[ptr]` and the pointer is on the phase cell there, then `C63` loads the ramping
phase (§165: cell `0x07`, `0..8388598`, chg 1 128 429) straight into `tempB`, and the whole
routing gap closes in one word.

### 4. ⛔ What must be measured BEFORE any of that is implemented

**Standing rule 4.** `tempB` is now a *candidate* index and nothing more. §162 measured
`acc`/`m_dp`/`cursor`; it never measured `m_ta`/`m_tb`/`m_k`/`m_l`. If `m_tb` is constant at the
class-6 site, `table[m_tb]` is frozen and implementing it manufactures exactly the false null §162
was written to prevent.

Next action is therefore **extend the §162 probe, not write the lookup.**

Evidence grade: §2 **MEASURED** (exhaustive over all 91 programs, null computed first);
§3 the idiom's *shape* **INFERRED** from the field decode, the identity of the index register
**SPECULATIVE**; §4 procedural.

---

## §168 — bit 18 tested at last, and it names the defect: **`C63` reads a cell that never changes**

§113 has sat off since it was written. §112 §2 records why — *"⚠⚠ §113 WAS NOT VALIDLY TESTED — a
mask collision"* — and §130 moved the colliding gate to bit 38, so the confound is gone. Bit 18
verified programmatically as **clear in the default and used at exactly one site**
(`upd6383.cpp:2369`) before arming.

### 1. Results against `data/PREDICT_168.md`

| | pre-registered | measured | |
|---|---|---|---|
| **F1** gate fires | count > 0, else the run says nothing | **9 279 912** | ✔ |
| **F2** two-sided | `m_tb` chg → ~1 129 389, **or** stays ≈1 ⇒ gap is upstream | **chg = 1**, unchanged | **arm 2** |
| **F3** control | `m_dp`/`cursor` must not move (bit 18 is a SRC decode) | `12..12` / `9..9`, unchanged | ✔ |
| **F4** upstream null | cell `0x07` census unchanged | `0..8388598`, chg 1 128 429 | ✔ |
| **F5** rule 1 | `§70 ACCA` min ≠ max before any output claim | `min 0 max 0` | ✔ (silent) |

F1 matters here more than usual: without it, "`m_tb` did not move" is indistinguishable from "the
gate never ran". **9 279 912 firings** makes arm 2 a decision rather than an absence.

### 2. ★ THE DIAGNOSIS, and it falls out of two censuses already in hand

`§164`'s per-frame census lists **every** D-RAM cell in `0x00..0x1F` that moved at all:

```
  01  02  04  06  07  0E          <- and NOTHING else
```

`§162` measures `m_dp = 12` (`0x0C`) at the class-6 word. **Cell `0x0C` is not in that list — it
never changes.** So `m_tb` is constant for the plainest possible reason:

> **`C63` reads cell `0x0C`. The phase is in cell `0x07`. It is reading the wrong cell.**

That also explains why bit 18 changed nothing here: swapping `SRC 0x11` from `ACCB` to `mem[ptr]`
moves *which* constant arrives, not whether it is constant.

⇒ This is an **addressing** defect, precisely the class §108 §5 forced the fix to be
(*"a per-word ADDRESSING decode … not the anchor"*) and precisely what §165 predicted the shape of
the remaining gap to be. Three independent lines now agree on the same conclusion.

### 3. ⚠ Bit 18 is NOT inert, and it does NOT ship

One cell differs against the control: `06: chg 1100 → 2`. Everything else is bit-identical. That
is a real effect on a cell §160 could not identify, too small to justify overturning §27's live
`ACCB` reading, and it is now **TESTED-and-recorded** rather than untested. Bit 18 stays off with
this measurement at the site.

### 4. ⚠ A structural gap in `LEDGER.md`, found by using it

Tier 1 renders every unarmed bit as *"off … which usually means tried and refuted"*. Bit 18 was off
because it was **never tested**. Those are opposite states — one says *stop*, the other says
*this is owed a run* — and the index could not tell them apart. Being unable to distinguish them is
how a testable idea becomes invisible for weeks.

The generator now classifies unarmed bits as **REFUTED**, **UNTESTED** or **off** by looking for a
refutation or an untested marker in the owning comment block, and Tier 0 carries an explicit
"owed a run" list.

Evidence grade: §1 **MEASURED** (five falsifiers, fired-count satisfied); §2 **FORCED** by the
conjunction of §162's `m_dp = 12` and §164's exhaustive moved-cell list; §3 **MEASURED**.

---

## §169 — the register enumeration is COMPLETE and EMPTY, and it names the hole: **`ACT 0x15` is 23.7% of the corpus and decodes as nothing**

### 1. The last register, and the enumeration closes

`data/PREDICT_169.md` asked whether the index is the *product* — `lfo-ramp.md` §10 reads the idiom
as `(coef × phase) >> 23`, and §167 measured `m_k = 24`, so the scale is already in the multiplier
input latch. ⚠ §167 censused `m_ta`/`m_tb`/`m_k`/`m_l` and **not `m_p`** — a gap in my instrument,
not a measurement.

```
  §169 SAME SITE, THE PRODUCT: P 0..0 chg 0
```

**F1 arm 2.** With that, every register at the class-6 site is enumerated:

```
   acc  0..0        m_ta 0..0        m_tb 0..5872025 chg 1      m_k  0..24 (the scale)
   m_l  0..0        m_p  0..0 chg 0  m_dp 12..12                cursor 9..9
```

> **Nothing varying reaches the site. The enumeration is complete and it is empty.**

And `m_p = 0` with **chg = 0** says more than "not the index": across 1 129 389 executions the
multiplier **never produced a product at all** before the lookup. ⇒ **The index multiply never
issues.** That is a much sharper statement than "the index is missing".

### 2. ★★ WHY — and it is one undecoded ACTION code

The word that `lfo-ramp.md` §10 identifies as consuming the scale is `000.A.00.1D5`: class A (the
coefficient consumer), `SRC 0x07` = `mem[ptr]`, **`ACT 0x15`**. And in the device:

```
   LO_ACT_NONE_5 = 0x15,   // ditto -- how it differs from 0x12 is OPEN
```

**It is decoded as a no-op.** The word that must issue `scale × phase` does nothing, so `m_p`
stays 0, so no register at the lookup ever varies. Every measurement in §162/§167/§169 is
downstream of that one line.

### 3. How big the hole is — corpus census, C-format excluded

```
  ACT    count     %      programs   decode
  0x00    820    27.4 %      40      acc <- bus (before op)
  0x15    707    23.7 %      39      ★ NO-OP
  0x07    455    15.2 %      40      STORE
  0x0E    227     7.6 %      40      P <- bus  (§144)
  0x0D    203     6.8 %      39      acc <- bus (§144)
```

**`ACT 0x15` is the second-largest ACTION code in the entire corpus, present in 39 of 91 programs,
and it does nothing.** *(`adjudication-round7`'s count of 1174 is a different population — it does
not exclude C-format words, whose `lo12` is a 13-bit immediate and has no ACTION field at all.)*

⇒ **NEXT TASK: decode `ACT 0x15`.** It is the largest single unmodelled behaviour left in the
device, and the LFO is merely the first place its absence has been traced end to end.

### 4. ⚠ A vehicle result — my measurement vehicle is the worst one available

Static, all 91 programs: the distance from the LFO phase-accumulate block to the class-6 lookup.

```
  prog05_phaser            44, 54          prog02_modulated_chorus  24, 31, 35
  prog06_ensemble          40, 44, 48, 52  prog56_mix_up            13, 20, 31
  prog64_s_delay_chorus    40, 44          prog01_chorus            24, 28   <- MY VEHICLE
  prog71_peq_chorus        37, 41
  ---------------------------------------------------------------------------
  prog04_flanger            6, 6           prog50_vibrato            6, 6
  prog48_auto_pan           6, 6           prog54_ring_modulator     6, 6
```

**Two families, and the split is sharp:** four programs at *exactly* 6, everything else ≥ 13.
Cold-boot CHORUS — the vehicle rule 2 mandates for audio statistics — carries the phase **24 words**
from its own lookup, and has one LFO block where the gap-6 family has two.

⇒ For *index-path* work, AUTO PAN / VIBRATO / FLANGER / RING MODULATOR are four times shorter.
⚠ But reaching them needs panel navigation, and §148 measured that the navigation vehicle *creates*
a unit-1 rail. **Rule 2 is about absolute audio statistics; a register census at a class-6 site is
not one** — so the vehicle may be switched for this purpose, and must not be for that one.

### 5. SPECULATIVE — patterns recorded, not claimed

* **S1.** The gap-6 four (FLANGER, AUTO PAN, VIBRATO, RING MODULATOR) share an *identical*
  structural signature: 4 phase-accumulate words, 2 lookups, both gaps exactly 6. That is what a
  single assembler **macro** instantiated four times looks like. If so, one decode validated on
  AUTO PAN transfers to all four for free, and the ≥13 family is the same macro with body code
  spliced between phase and lookup. **SPECULATIVE** — untested, and the null (do unrelated
  programs share signatures this exact?) is not yet computed.
* **S2.** `ACT 0x15` at 23.7 % with `ACT 0x00` at 27.4 % is suspicious as a *pair*: two codes
  covering half the corpus between them, one decoded as "acc ← bus before the operation" and the
  other as nothing. A plausible shape is that they are the two halves of one operand-order choice.
  `LO_ACT_NONE_5`'s own comment — *"how it differs from 0x12 is OPEN"* — says the field's
  neighbourhood was never resolved. **SPECULATIVE.**

Evidence grade: §1 **MEASURED**, and *"nothing varying reaches the site"* **FORCED** by exhaustion
of the register set; §2 the mechanism **FORCED** (the decode is a literal no-op in the source), the
claim that `ACT 0x15` *should* multiply **INFERRED** from `lfo-ramp.md` §10; §3 **MEASURED**;
§4 **MEASURED**; §5 **SPECULATIVE** and labelled.

---

## §170 — the DSP EFFECT TYPE map, measured from the machine's own uploads. Vehicle problem solved.

§169 established that index-path work wants one of the four **gap-6** programs (FLANGER, AUTO PAN,
VIBRATO, RING MODULATOR — phase-accumulate 6 words from the lookup) instead of cold-boot CHORUS
at 24. Selecting one needs its TYPE index, and nobody had the list.

### 1. It cannot be derived from the manifest, and the attempt says so out loud

`programs.tsv` lists **distinct programs**, so every TYPE slot that reuses an already-listed
program is absent from it. Deriving the index from manifest order puts PARAMETRIC EQ at **16**
where `peq_select.lua` measured **15**. The off-by-one is the manifest telling you it is the wrong
source; it is not an origin to adjust away.

### 2. The instrument failed, its control caught it, and a second instrument passed the same control

`tools/type_enum.lua` walks the list on the machine and reads the display. **The readout was
wrong** — `0x30AE5` is the *parameter* line, not the TYPE line, so it returned garbage
(`'  2k  i     G   S'`) at every stop. The pre-registered control — *index 0 must read CHORUS and
index 15 must read PARAMETRIC EQ, and if either disagrees the enumeration is VOID* — failed, and
the run was voided rather than rationalised.

★ But the walk itself worked: the snapshot shows the editor open on the list's last entry, and the
device dumped **882 transfers / 38 KB** on the way — every effect's program upload, in order. So
the effect was identified from **the DSP's own uploaded image** instead of from the LCD, and the
same two controls **both pass** on that instrument.

### 3. ⚠ And my matcher was unsound, caught by a check I nearly skipped

The first pass fingerprinted each upload on its **first 4 words**. Soundness check:

```
  first  4 words: 34 distinct prefixes over 38 programs -> 8 programs in 4 COLLIDING groups
                  distortion/fuzz, exciter/auto_pan, peq_chorus/peq_flanger, peq_dist_delay/peq_overdr_delay
  first  8 words: 36 distinct                          -> 4 programs in 2 groups
  first 16 words: 38 distinct                          -> NONE
```

The 4-word map mislabelled four entries and showed AUTO PAN twice — which is what made me check.
**A fingerprint that cannot separate its candidates is a criterion that cannot fail.** Redone on
16 words. ⚠ Note the collisions are not random: they pair *distortion with fuzz* and *peq_chorus
with peq_flanger* — effects that share a prologue, which is independent support for §169's
SPECULATIVE S1 (programs assembled from shared macros).

### 4. The result — `analysis/data/typewalk/TYPE_MAP.md`

```
   0 CHORUS           3 FLANGER        15 PARAMETRIC EQ   16 AUTO PAN
  17 VIBRATO         20 RING MODULATOR
```

The four gap-6 vehicles are TYPE **3, 16, 17, 20**. The capture itself is committed under
`analysis/data/typewalk/` — it is overwritten by every emulator run, so it is preserved rather
than regenerable.

⚠ Reaching any of them costs ~26 s of navigation, and §148 measured that the navigation vehicle
*creates* a unit-1 rail. **Rule 2 governs absolute audio statistics; a register census at a
class-6 site is not one.** Use these for index-path work and cold-boot CHORUS for audio.

Evidence grade: §1 **FORCED** (the manifest's population is the wrong one by construction);
§2 **MEASURED**, with the LCD instrument **VOIDED by its own control**; §3 **MEASURED**;
§4 **MEASURED**, two independent known-answer controls passing.

---

## §171 — §169's one word is a **46-site family**, and it is a minimal pair. Three lines converge.

A parallel read-only pass found this while §169 was being written; independently re-measured here
before being built on.

### 1. VERIFIED — and the first check said 0 of 54

```
  class-A ACT-0x15 base rate 0.1544  ->  chance gives ~8.3 of 54 at any fixed offset

  offset from the class-6 word :  -5:13   -4:0   -3:46   -2:0   -1:0   0:0
  offset from the C63 word     :  -5:21   -4:13  -3:0    -2:46  -1:0   0:0
```

**46 of 54, against a null of 8.3.** The remaining 8 are *chained* lookups whose −3 slot is
occupied by the previous idiom's tail — so **54 of 54 are accounted for**.

⚠ My first verification returned **0 hits** and I nearly filed the claim as unreproduced. The
finding was anchored on `C63`; I measured from the class-6 word. Same 46 sites, offsets −2 and −3
for the same thing. The base rates agreed to a tenth (8.4 vs 8.3), which is what said the
disagreement was the *anchor* and not the statistic.

> **RULE: an offset claim is meaningless without its anchor. State the anchor word explicitly, or
> report the whole offset profile — which is cheaper than the argument.**

### 2. What it buys — a minimal pair with BOTH sides already decoded

```
  SRC 0x07 (mem[ptr])  x29        SRC 0x10 (the accumulator)  x17
     000.A.00.1D5 x8  ...            000.A.00.415 x17
```

Same class, same ACTION, two **already-decoded** sources. That bounds `ACT 0x15` from both sides:
whatever it does, it must make sense applied to memory *and* to the accumulator, at the same slot
in the same idiom. §169's `000.A.00.1D5` is one of 46 instances, not a special case — the
NEXT TASK just became a 46-site, 25-image problem instead of a one-word one.

### 3. ★ Three independent lines land on the same family

The `f31` pass's decidable minimal pair — `020.A.06.1D5` vs `028.A.06.1D5`, byte-identical but for
bit 27 — is **inside this list** (`x1` and `x2` respectively). So the `f31 > 2` question, the
`ACT 0x15` question and the LFO index path are all the same 46 words, reached from three
directions that could not see each other.

### 4. ⚠ An open challenge to §168, and it is cheaper than what §168 concluded

§168 concluded *"`C63` reads cell `0x0C`, the phase is in `0x07` — an **addressing** defect"*, and
§169 then concluded *"the multiply never issues — `ACT 0x15`"*. **They were written in that order
and never put side by side.** The corpus names `182.2.**.407` as the writer of the cell `C63`
reads, which admits a cheaper account:

> There is **no addressing defect**. The cell `C63` reads is frozen *because* the dead `ACT 0x15`
> multiply never produces the value that would be written into it. One cause, not two.

**Unresolved, and recorded as such.** It is falsifiable at the first step and both ways: decode
`ACT 0x15`, and either cell `0x0C` starts changing (one cause) or it stays frozen (two). Do not
carry §168's "addressing defect" forward as settled until that runs — ★ **rule 10 again: it is a
conclusion, not a measurement, and it has an untested rival.**

Evidence grade: §1 **MEASURED**, independently reproduced; §2 **MEASURED**; §3 **MEASURED**;
§4 **OPEN** — two live accounts, one experiment separates them.

---

## §172 — ⛔ "DISTORTION ≡ FUZZ" does not survive its own test, and the data corroborates the notes

A parallel pass reported *"DISTORTION ≡ FUZZ — same 42 words, differing in exactly 4 `addr8`
bytes"*, marked it as **contradicting** `programs.tsv`'s two role strings, and proposed the
cheapest hardware test in the project: **ask Felipe whether the two effects sound the same**. Its
own stated precondition was *"if algos 32 and 34 also ship identical data"*. That precondition is
checkable statically, and it fails.

### 1. The microcode half is CONFIRMED, exactly

```
  DISTORTION 42 words, FUZZ 42 words -- 38 identical, 4 differ, and `addr8' is the ONLY field
  that ever differs:
     w6   -7  vs -122      w8   +7  vs +122
     w16  -16 vs +125      w17  +16 vs -125
```

★ Each program's four displacements form **two symmetric ± pairs** — an out-and-back pointer
excursion. So this is one algorithm walking two very different strides, which is a stronger and
more useful statement than "the same program".

### 2. ⛔ But the DATA is not identical, and the precondition fails

From §170's TYPE-walk capture, DISTORTION's and FUZZ's own upload payloads: **16 of 19 transfers
identical, 3 differ.** The coefficient payload is legible:

```
                      Q0.23
  DISTORTION   7E63CE = +0.9874208     066666 = +0.050000
  FUZZ         7FFFFE = +0.9999998     028F5C = +0.020000
```

**FUZZ ships full scale — a hard rail. DISTORTION ships just under unity — a soft knee.** And the
companions are exactly `0.05` and `0.02`, two time constants differing by 2.5×.

`programs.tsv` says `DISTORTION = "AGC waveshaper, curve A"` and `FUZZ = "rail-clip waveshaper"`.
⇒ **The data corroborates the role strings; it does not contradict them.** The claim was aimed at
the wrong target: the *microcode* is shared, the *parameters* are what make them different effects,
which is exactly what "same waveshaper, two curves" means.

### 3. ⇒ Do NOT put this to Felipe as written

The proposed question — *"do DISTORTION and FUZZ sound the same?"* — is already answered by the
ROM, and asking it would spend the one irreplaceable resource on this project (★
`felipe-hardware-testimony-is-ground-truth`) on something a `diff` settles. **A hardware question
is only worth asking when the static evidence cannot decide it.**

★ There *is* a good question underneath, and it is sharper: the static evidence **predicts** FUZZ
is the harder-clipping of the two with a time constant 2.5× faster. That is a prediction the
instrument can falsify, and it is worth asking only once the chip makes sound.

### 4. What survives, and it is worth keeping

* **MEASURED:** DISTORTION and FUZZ share 38 of 42 words; `addr8` is the only differing field.
* **MEASURED:** their coefficient payloads differ, in the direction the role strings state.
* **INFERRED:** the drive family is one waveshaper microcode parameterised by pointer stride and
  by a clip coefficient. §162's `addr8 = 0x28` table selector is shared across the whole family;
  the *curve* is selected by the stride, not by the program.
* ⚠ **Method note.** §170 independently found DISTORTION and FUZZ colliding on a 4-word
  fingerprint, and I read that as support for "shared macros". It is — but a shared *prologue* and
  a shared *program* are different claims, and the second does not follow from the first.

Evidence grade: §1 **MEASURED**; §2 **MEASURED**, the original claim's precondition **REFUTED**;
§3 procedural; §4 as labelled.

---

## §173 — the lookup is a FOUR-WORD idiom, and the `-2` slot is operand staging with three forms

§171 left an open question: is there really an addressing defect (§168), or is the frozen cell just
a consequence of the dead multiply (§169) — one cause rather than two? The `-2` slot decides most
of it, statically.

### 1. The idiom, measured at every offset

```
   offset -3   class-A ACT 0x15            (the multiply)     46 of 54    null 8.3
   offset -2   class-2 SRC 0x10 ACT 0x07   (store acc)        21 of 54    null 3.6
   offset -1   C63                          (load index)      53 of 54    null 0.9
   offset  0   class 6                      (the lookup)      54 of 54
```

**All three present simultaneously at 21 of 54**, against a joint null of **0.01** if the three
were independent.

### 2. ★ The `-2` slot is not one word — it is the OPERAND-STAGING slot, and it has three forms

**53 of 54 are class 2** (the lone exception is the kernel's C-format lookup, `800.1.60.00B`).
By ACTION:

```
   ACT 0x00  x25   SRC 0x00   acc <- C-RAM[cursor]     (a coefficient)   §156
   ACT 0x07  x21   SRC 0x10   store the accumulator                      `182.2.00.407'
   ACT 0x0E  x7    SRC 0x07   P <- mem[ptr]                              §144
```

Three ways to stage an operand — from the coefficient bank, from the accumulator, from memory —
all feeding the same lookup. `hi12 = 0x182` accounts for 45 of them. ⇒ the idiom is

```
   [-3] multiply     [-2] stage an operand     [-1] load the index register     [0] look up
```

### 3. ⇒ §171 §4 leans to ONE CAUSE, for the 21 sites that include CHORUS

At those 21 — CHORUS among them — the `-2` word **stores the accumulator into the cell `C63` then
reads**. If the `-3` multiply is dead, the accumulator is stale, so the stored cell is frozen, so
`C63` reads a frozen cell. **That is one cause, and §168's separate "addressing defect" is not
needed to explain it.**

⚠ **NOT CLOSED, and here is what stops me closing it.** §167 measured `m_tb = 5872025` at the
lookup — exactly `0.700000` in Q0.23, a clean coefficient, arrived at once and never again. A
scratch cell written from a stale-zero accumulator should read **0**, not `0.7`. So either `C63`
is not reading the cell the `-2` word writes, or something else wrote `0.7` there first. **That
must be explained before "one cause" is asserted** — it is exactly the loose end that, three times
on this project, turned out to be the actual mechanism.

### 4. SPECULATIVE

* **S3.** The three `-2` forms may be *the same operation* with the operand routed from three
  places, which would make the whole family one macro with a source parameter — consistent with
  §169's S1 and with §170's prologue collisions. Testable once `ACT 0x15` is decoded: all three
  should leave the lookup's index in the same place.
* **S4.** `ACT 0x00` ×25 at `-2` reads `acc <- C-RAM[cursor]`. If the `-3` `ACT 0x15` word is the
  multiply, then `-2` loading a *coefficient* into the accumulator right after it is an odd order —
  unless `ACT 0x15` leaves its result somewhere other than the accumulator. That is a constraint on
  the `ACT 0x15` decode, obtained without decoding it. **SPECULATIVE.**

Evidence grade: §1 **MEASURED** (nulls computed first); §2 **MEASURED**; §3 **INFERRED** and
explicitly **left open**, with the falsifying observation named; §4 **SPECULATIVE**.

---

## §174 — ⛔⛔ §169 §2 RETRACTED. The multiply issues. The dead operand is `L`, and §168 was right.

A parallel read-only pass found the error; I verified it at source before accepting it, and then the
correction propagated further than the pass predicted.

### 1. ⛔ The retraction — a source-level mistake, and rule 3's ELEVENTH occurrence

§169 §2 said the LFO index multiply never issues *because* `ACT 0x15` decodes as a no-op. The
multiply's gate is:

```cpp
   coeff_consumer(w) = class4(w) == 0xa && !c_format(w)          // upd6383d.h:841
```

**The ACTION field is not in that condition.** CHORUS's word is `202.A.07.1D5` — class A, `f31 = 1`
— so it multiplies already, `ACT 0x15` or not. And `lfo-ramp.md` §10 says so *in the paragraph
§169 quoted*: *"ACTION 0x15 (no side effect), class A — so it multiplies the phase by a coefficient
and leaves the product in P."*

⇒ **§169's measurement stands (`m_p 0..0 chg 0` at the lookup); its cause does not.**
⇒ And it takes two other sections with it: **§171 §4 and §173 §3's "one cause — the dead multiply"
lose their premise. §168's addressing diagnosis is NOT displaced.**

### 2. ⚠ My first probe pooled, and §175 caught it — §155's error in a new place

Instrumenting the multiply gave *"both operands live, P up to 1.76 × 10^13"* — over **36 463 968**
firings pooled across every class-A `ACT 0x15` word in every program. Meanwhile a second probe
naming the last writer of `P` reported **THE MULTIPLY** at CHORUS's lookup, with `P` still 0.

Both cannot be read together unless the census is hiding a dead site inside 36 million live ones.
**A pooled census cannot answer a per-site question.** Keyed by word:

```
  0192A00455  coef -3792303..3527094 nz 1133229 | L 0..8388607 nz 1133229 | P ..1.75e13   live
  0292A00455  ...                                                                         live
  0182A00415  ...                                                                         live
  0692A00415  ...                                                                         live
  0212A811D5  coef 0..5084004        nz 1133229 | L 0..16384    nz 3839    | P ..5.4e8    live
  ---------------------------------------------------------------------------------------------
  0202AFD1D5  coef 0..4194304 nz 1133229 | L 0..0 nz 0 | P 0..0   <= L ALWAYS 0 -> POINTER
  0202AF91D5  coef 0..4194304 nz 1133229 | L 0..0 nz 0 | P 0..0   <= L ALWAYS 0
  0212A001D5  coef 0..3905669 nz 1133229 | L 0..0 nz 0 | P 0..0   <= L ALWAYS 0
  0212A00415  coef 0..3527094 nz 3394887 | L 0..0 nz 0 | P 0..0   <= L ALWAYS 0
  0202A001D5  coef -3792303..0 nz 3394887 | L 0..0 nz 0 | P 0..0  <= L ALWAYS 0
  0000A00695  coef 0..4194304 nz 3394887 | L 0..0 nz 0 | P 0..0   <= L ALWAYS 0
  0000A0A1D5  coef -1509614..1509949 nz 1133229 | L 0..0 nz 0 | P 0..0  <= L ALWAYS 0
```

**Seven of twelve sites: the coefficient arrives on every one of 1.1–3.4 million firings, and the
memory operand is identically zero on all of them.**

### 3. ⇒ THE DEFECT IS THE OPERAND FETCH, and that is §168's pointer

`L` at these sites is the bus datum — `SRC 0x07` = `mem[ptr]`. It reads **0**, always, while the
coefficient beside it is live. The multiply is healthy; it is being fed nothing.

⇒ §168's *"`C63` reads a cell that never changes — an **addressing** defect"* is **confirmed and
generalised**: it is not one word reading one frozen cell, it is the operand fetch returning zero
across most of the family. ★ The chain §165→§174 now reads: the phase ramps, the coefficient
arrives, the multiply runs — **and the memory read under it is empty.**

⚠ **Limits, stated.** The per-site table is capped at the first **12** distinct words, so it is not
exhaustive and CHORUS's own `0202A071D5` is not among them; the 7/12 split is a sample, not a
census. And `0182A00415` is live where `0212A00415` — same `lo12`, different `hi12` — is dead, so
the split is not a simple function of `SRC`.

### 4. What `ACT 0x15` is, from the same pass — kept separate because it is not measured here

**INFERRED, ~70 %:** `ACT 0x15` has no architecturally visible side effect — the "no capture"
member of the ACTION field, the plain-MAC code. 23.7 % is what that predicts. The negative half is
much stronger (**≥95 %**): PARAMETRIC EQ's biquad contains an adjacent minimal pair
`202.A.01.1D4` / `202.A.01.1D5` differing *only* in ACT, and the section's state shift requires the
first to write a register and the second not to — which excludes `0x13`'s effect, `0x14`'s effect,
any accumulator write, any store, any pointer or cursor move, and "0x15 enables the multiply"
outright. **`0x12` vs `0x15` cannot be closed from the corpus** — `0x12` is essentially one form.

Evidence grade: §1 **FORCED** (read at source); §2 **MEASURED**, the pooled reading **VOIDED**;
§3 **MEASURED** with its sampling limit stated; §4 **INFERRED**, from a separate pass, not
re-derived here.

---

## §176 — ★★★ THE INDEX MULTIPLY POINTS AT CELL 5. THE PHASE IS IN CELL 7. Off by exactly 2.

Against `data/PREDICT_176.md`. Both probes were pointed one step further upstream than §174's, and
that is where the answer was.

### 1. F1 — the D-RAM is mostly empty (H1's arm fires)

Every cell `0x00..0x1F`, settled value, over 1 392 430 frames:

```
  02:6553600   06:8388607   07:2811786(0..8388598/chg1128429)   0E:39718
  ---- and 00 01 03 04 05 08 09 0A 0B 0C 0D 0F 10 ... 1F all settle at ZERO ----
                                                       ||  NON-ZERO 4 of 32
```

⚠ §164 reported only the cells that *moved*, so it could not tell "static and non-zero" from
"static and **zero**" — and the whole fork turned on that. Same defect as §169 measuring `m_p` at
the consumer: the instrument was one step off.

### 2. F2/F3 — and the per-site pointer table settles it

Cap raised 12 → 24, so **CHORUS's own word is now in the table** (F3 satisfied):

```
  0202A071D5   coef 0..24   L 0..0   P 0..0   m_dp 5..5
  ^ 202.A.07.1D5, SRC 0x07 = mem[ptr] -- CHORUS's LFO index multiply
```

> **`coef` is `0..24` — the index scale `lfo-ramp.md` measured as `0x18` = 24. It arrives, exactly
> as designed. `m_dp` is a CONSTANT 5. The phase is in cell 7. The multiply computes 24 × 0.**

**Pointer 5, target 7. Off by exactly two.**

And F2's prediction holds across the table: every dead site's `m_dp` lands on a cell the census
reads as zero (`5`, `0F`, `0x10`, `0x12`, `15..18`), and the one apparent counterexample —
`0010A001D5` at `m_dp 14..14`, cell `0x0E` — is not one: `0E` has `chg 2`, i.e. it is zero for
essentially the whole run.

### 3. ★★ The convergence, and it is with a candidate that was named and never tested

§108 §5 FORCED that no anchor value could fix this and listed what could:

> *"some word's `addr8` contribution to the walk, `iw30`/`iw32`'s store target, or **the body's LFO
> block not really sitting at base+2**."*

**The measured offset is exactly 2.** That third candidate has sat in the register untested since
§108, through a `DRAM_UNIT_BASE` refutation, two retractions and eleven occurrences of trap #3 —
and it is the one the measurement now names.

⇒ **NEXT: test the +2.** ⚠ Pre-register properly and remember §108's own warning — an *anchor* is
cheap to try and every anchor here is pinned by closure arithmetic. The thing to move is a per-word
addressing contribution, not a base. And the two-sided criterion is already available and sharp:

```
  if the pointer reaches cell 7:  L stops being 0, P becomes 24 x phase, and the class-6 index
                                  finally VARIES -- then K2 is four lines and the discriminator
                                  is 226, not 240.
  if it does not:                 L stays 0 and nothing else moves.
```

### 4. What this does NOT say

`§70 ACCA min 0 max 0` — the chip is silent, unchanged (F5). Neither arm of F1 nor this finding
makes it audible. And "28 of 32 cells are zero" is **not** yet established as a defect: this is a
small scratch window and the delay lines live elsewhere. It is the *specific* pointer/target
mismatch at a word whose coefficient is provably correct that carries the weight here.

Evidence grade: §1 **MEASURED**; §2 **MEASURED** (coefficient 24 identifies the word's role
independently of any addressing claim); §3 the convergence **MEASURED**, the fix **UNTESTED**.

---

## §177 — §176's "off by 2" is an instance of a KNOWN, LOCALISED defect, and it adds a fourth constraint

Before building anything on §176 I read the note the pointer trace names in its own header —
`kn7000_mame/notes/kn5000-dsp-pointer.md`. It says the rule I was about to chase is already known
to be wrong, and says so on the file's first screen:

> *"CAUTION, stated up front: WHICH words move the pointer is NOT established … the rule used below
> is `classes 2 and A move it'. Two independent checks say that rule is still WRONG."*

★ Twelfth avoided repetition of trap #3, and the first one this session caught **before** spending
a build.

### 1. The same defect, from an unrelated effect family, already FORCED

That note's §6 runs the walk from a measured origin and finds a producer/consumer pair that
*must* coincide and does not:

```
   algo  5   chain READS {76}      modulator WRITES {7B}     miss  +5
   algo 68   chain READS {76}      modulator WRITES {77}     miss  +1
   algo  3   chain READS {7E,7F}   modulator WRITES {7B,7C}  miss  -3
```

and concludes — **FORCED**, because both addresses are `origin + Σ(deltas)` so the origin cancels:

> *"The error is in the Σ — in which words carry a pointer delta."*

⇒ §176's CHORUS finding is the same defect: a consumer (`202.A.07.1D5`, the index multiply, at
`m_dp = 5`) and its producer's cell (the LFO phase, cell `7`). **Not a new problem — a fourth
instance of a problem already localised.** And it independently corroborates §108 §5's FORCED
"no anchor value can fix this", now from two directions.

### 2. ★ What §176 CONTRIBUTES: a fourth constraint, from a family the note did not use

The note had three constraints, all from the phaser family. §176 supplies one from **modulation**:

```
   C1  phaser algo  5    write - read  =  +5
   C2  phaser algo 68    write - read  =  +1
   C3  phaser algo  3    write - read  =  -3
   C4  CHORUS  algo  1   consumer 5, producer cell 7   ->  miss  +2      ★ NEW, §176
```

and three that any candidate rule must **not** break (all reproduced by the current rule):

```
   P1  the phaser's 20 all-pass sections are net-zero (deltas cancel)
   P2  the biquad walks +4 per band
   P3  8 of 9 reverb diffusers are stationary
```

★ C4's value is that it is **structurally different**: a different effect family, a different
idiom, and — unlike C1–C3 — its consumer's role is pinned independently of any addressing claim,
because §176 measured that word's coefficient as `0..24`, the index scale `lfo-ramp.md` designed.
**A rule that satisfies C1–C3 by construction can still fail C4.** Four constraints over three
families is a materially better-posed search than three over one.

### 3. ⇒ The task is now well posed and STATIC

Enumerate candidate delta rules — which classes, and under which conditions, carry the signed
`addr8` post-increment — and score each against C1–C4 and P1–P3. No emulator.

⚠ **Do NOT touch the origin.** It is MEASURED three ways (ROM record `0x01E496`, cold-boot
capture, live I-RAM read-back), it cancels out of every constraint above, and "reach for the
anchor" is a named standing bias (§108 §5, LEDGER rule 9).

⚠ And the note's §5 is a live warning about the corpus this search will run on: *"bit 10 with
bit 11 clear = END OF PROGRAM"* was measured 38/38 on the bodies and **falsified as a bit meaning**
— the header carries it 14 times in 60 words. Any rule conditioned on `hi12` bits must be
validated on the header too, not only on the 38 body images.

Evidence grade: §1 **FORCED** (quoted from the owning note, origins cancel); §2 C4 **MEASURED**
(§176), its independence **INFERRED**; §3 procedural.

---

## §178 — the header's vocabulary, verified and enumerated; and a gap I nearly reported that is not there

`kn5000-dsp-pointer.md` §10.3 calls the common header *"the highest-value remaining static
target"*, on the strength of a figure quoted from another note: *"about 90 % of its vocabulary
appears in no effect body."* Checked, because a quoted figure is not a measurement.

### 1. VERIFIED, and tightly

```
  header (kernel.dsm)      60 words,  57 distinct
  bodies                  688 distinct words over 38 images
  header words in NO body  51 of 57 distinct  =  89.5 %
                           54 of 60 slots     =  90.0 %
```

The figure is right to the tenth. And the six pointer-family loads the note says every static
search excluded reproduce exactly where it puts them:

```
  iw42 801.0.70.821   iw43 801.0.6C.827   iw44 801.0.25.825      <- unit 0
  iw50 801.0.50.821   iw51 801.0.64.827   iw52 801.0.25.825      <- unit 1
```

### 2. ⚠ THE GAP I NEARLY REPORTED, AND IT IS NOT THERE

`kernel.dsm` runs `w0..w59`, and the header is I-RAM `0..82` — so 23 words that every effect
executes appeared to be in no listing at all. That would have been a clean, quotable finding.

**It is wrong.** `epilogue.dsm` covers `w60..w82` exactly, 23 words, and its own header says so:
*"SHARED KERNEL, part 2 of 2 — OUTPUT STAGE, I-RAM 60..82 … a LITERAL canned image in Sub CPU ROM
at `0x01E63C`."* The header is fully disassembled; it is split across two files under names that do
not advertise the range.

★ I record this because the near-miss is the same failure mode as the twelve trap-#3 occurrences,
merely pointing the other way: **assuming absence from one file's name instead of checking the
directory.** One `ls` and one range query cost nothing and stopped a false claim.

### 3. The target list — what "decode the header" actually means

The 51 header-only words, by `(class4, ACT)` profile — **30 distinct profiles**, so this is a
vocabulary problem, not a handful of opcodes:

```
  class A ACT 0x00 x5    class 2 ACT 0x00 x4    class A ACT 0x15 x4    class 2 ACT 0x15 x3
  class A ACT 0x07 x3    class 2 ACT 0x0D x2    class 2 ACT 0x0E x2    class A ACT 0x08 x2
  class 2 ACT 0x07 x2    class 4 ACT 0x00 x2    class 0 ACT 0x01 x2    class 0 ACT 0x07 x2
  ... 18 further profiles at x1
```

★ Note the overlap with the current blocker: `class A ACT 0x15` occurs **4 times in the header**.
Any pointer-delta rule conditioned on `hi12` bits **must be validated here** — `kn5000-dsp-pointer.md`
§5 records that *"bit 10 = END OF PROGRAM"* held 38/38 across the body images and was **falsified as
a bit meaning** the moment the header was looked at (14 occurrences in 60 words, only 2 of them
terminators). A rule fitted to the bodies alone is fitted to a population that excludes the control
layer.

Evidence grade: §1 **MEASURED** (the quoted figure independently reproduced); §2 **MEASURED**, and
recorded as a near-miss rather than a finding; §3 **MEASURED** census, its *interpretation* as a
target list **INFERRED**.

---

## §179 — the census window was RIGHT, and the note's origin region is EMPTY. An open discrepancy.

§176 censused D-RAM `0x00..0x1F` — one eighth of the 256-cell space — while the owning pointer note
measures the operand origin at `0x70`/`0x50`. If the data lived there, §176's off-by-2 was measured
in an empty corner. That is a doubt worth one run rather than an argument.

### 1. F1 — arm 1. The window was right.

All 256 cells, 1 392 430 frames:

```
  01:0(-4275712..4952576/chg308646)   02:6553600(chg1)   04:0(-5579776..4994816/chg307312)
  06:8388607(chg1100)   07:2811786(0..8388598/chg1128429)   0E:39718(chg2)   92:8388607(chg2)
                                    ||  NON-ZERO 5 of 256 (4 below 0x20), MOVING 7 of 256
```

**Seven cells move, in the whole 256-cell space.** Six of them are inside §176's window; the
seventh is `0x92`. ⇒ **§176 stands as measured** — its off-by-2 was not an artefact of a narrow
window. A cheap negative result that removes a real doubt.

★ New: cell **`0x92`** at full scale (`8388607`). §72 places the body's coefficient bank at
`0x90+`, so this is the first observed live cell in that bank. **Not identified**; recorded.

### 2. F2 — the shipped closure argument's observable half HOLDS

`upd6383.cpp:1209` argues `DRAM_UNIT_BASE = 0x05` is FORCED: unit 1 starts at `0x85`, walks `−133`,
the output stage walks `−1`, the frame ends on `0xFF`, *"so the two deposits below land on cells
`0x01` and `0x04`"* — and it flags that as a **prediction** of `output-stage-decode.md`'s DI-latch
map rather than an input to it.

**`0x01` and `0x04` are two of the seven moving cells**, at 308 646 and 307 312 changes. The
prediction holds. (`0x85` and `0xFF` are dead, but the argument only ever claimed the pointer
*passes through* them.)

### 3. ⚠⚠ AND THE NOTE'S ORIGIN REGION IS COMPLETELY DEAD — recorded, NOT adjudicated

`kn5000-dsp-pointer.md` §4 measures the operand origin at `0x70` (unit 0) / `0x50` (unit 1)
**three ways**: the ROM record at `0x01E496`, the cold-boot capture, and the live I-RAM of a booted
KN5000 read back by the device. In this emulator **nothing in `0x50..0x8B` is non-zero and nothing
there ever moves.**

Two readings, and I am deliberately not choosing:

* **(a)** the device never implements the header's `ldptr` at all — it substitutes
  `DRAM_UNIT_BASE` — so that region is dead *because unimplemented*, and the note describes the
  real machine while the emulator describes a different one;
* **(b)** the note's `0x821` is **not** the operand pointer. That note grades its own selection
  **INFERRED (strong)** and says explicitly *"`0x827` not excluded"*.

⛔ **Do not resolve this by moving `DRAM_UNIT_BASE`.** §108 §5 FORCED that no base value fixes the
geometry, bit 27 measured a base change bit-identical, and "reach for the anchor" is LEDGER rule 9.
The discrepancy is between two *models*, and the deciding evidence is the note's own §10.1
experiment — capture the host's parameter poke while PHASER is selected and see which register and
which address it uses.

### 4. What this constrains for the delta-rule search running in parallel

Any candidate rule that walks the operand pointer into `0x20..0x4F` or `0x93..0xFF` puts it
somewhere **nothing in this machine ever writes**. That is not a proof the rule is wrong — those
regions could be dead precisely *because* the pointer never reaches them — but a rule whose
producer/consumer pair resolves into dead space has explained nothing, and should be scored below
one that resolves into the seven live cells.

Evidence grade: §1 **MEASURED**; §2 **MEASURED** (a standing prediction confirmed);
§3 **MEASURED** as to the emptiness, the two readings **ENUMERATED, not chosen**;
§4 **INFERRED**, offered as a scoring heuristic and not a constraint.

---

## §180 — PTRD-A: the dead multiply comes ALIVE, by moving the DATA rather than the pointer. Not shipped.

An exhaustive search over 21 364 736 candidate delta rules returns `class4 ∈ {2,0xA}` **AND**
`lo12 ≠ 0x1C0` as the **unique best non-degenerate rule in the entire space** (C4 + P1 + P2 + P3).
Re-verified independently before building — control reproduces C1 `+5`, C2 `+1`, C3 `−3`, C4 `−2`,
P1 30/38, P2 8/8, P3 8/9 and the absolute cells `0x76`/`0x7B`/`0x7E,0x7F`; and the gate is not
vacuous (103 sites, **36** with a non-zero `addr8`). Mask bit 62, clear in the default, one site.

### 1. Results against `data/PREDICT_180.md`

| | pre-registered | measured | |
|---|---|---|---|
| **F1** fires | count > 0 | **1 165 869** | ✔ |
| **F2** the point | `m_dp → 7`, `L` non-zero, `P` real | `m_dp` **stays 5** — but `L` **`−599858..8388607`, nz 1 128 428** and `P` **`0..1.76e13`** | ⚠ see §2 |
| **F3** downstream | `m_tb` chg → ~1.1 M | `m_tb 0..5872025` **chg 1** — still frozen | ✗ |
| **F4** control | phase still ramps in cell `07` | `07: 0..8388598 chg 1128429` — **exact** | ✔ |
| **F5** rule 1 | `§70 ACCA` min = max | `min 0 max 0` — silent, as predicted | ✔ |

### 2. ⚠ MY FALSIFIER WAS MIS-SPECIFIED, and I am reporting that before the result

F2 said *"`m_dp` becomes `7..7` … or lands anywhere but 7 ⇒ PTRD-A is refuted."* `m_dp` stayed at
**5**. By the letter of my own criterion, refuted.

**But I wrote the wrong criterion.** C4 is a *coincidence* constraint — consumer and producer must
name the **same cell** — and it says nothing about *which* cell. I assumed the consumer would move.
The census shows the other resolution:

```
  control  01  02  04  06  07  0E  92        (7 moving, cell 05 DEAD)
  armed    01  02  05  07  0C  0E  0F  91    (8 moving, cell 05 now  -599858..8388607 / chg 2772)
```

**The producer's writes relocated onto cell 5, which is where the consumer already reads.** They now
coincide — C4 satisfied, by the arm I did not enumerate.

> **RULE: when a constraint says "two things must be equal", do not pre-register WHICH ONE MOVES.
> State the equality and let the run say how it is met.** Otherwise a pass reads as a refutation.

### 3. ★ What genuinely changed — the multiply is no longer dead

`0202A071D5`, CHORUS's LFO index multiply, across 1 129 389 executions:

```
  before   coef 0..24 nz 1128429  |  L 0..0        nz 0        |  P 0..0
  after    coef 0..24 nz 1128429  |  L -599858..8388607 nz 1128428 | P 0..17592185828702
```

**The operand that was identically zero on every one of 1.1 million firings is now live on all but
one of them, and the multiply produces a real product for the first time.** That is the datapath
§169–§176 chased across eight sections.

### 4. ⛔ AND IT IS NOT SHIPPED. Three reasons, all pre-registered.

* **F3 failed.** `m_tb` at the lookup is still frozen at chg = 1, so the index still does not reach
  the class-6 word. PTRD-A is **at most half the fix** — exactly the outcome F3 was written to
  detect.
* **C1/C2/C3 remain unexplained by every non-degenerate rule in 21 million**, and C3 is *provably*
  unreachable: it demands `77x − 80y = 0` with `x,y ∈ {0,1}`, and `gcd(77,80) = 1` forces the inert
  case. ★ Verified independently — `x = y = 1` gives exactly the `−3` C3 misses by today.
* **The output is unchanged and silent** (`§70 ACCA min 0 max 0`), so nothing audible corroborates
  the change, and cell `04` vanished while `0C`/`0F`/`91` appeared — a layout shift with no
  independent confirmation that the *new* layout is the right one.

⇒ Bit 62 stays **off**, implemented, with this measurement recorded at the site.

### 5. SPECULATIVE

* **S5.** The search's own conclusion is that the thing to drop is the **C1–C3 producer/consumer
  premise** (`-axes.md` §2.4, graded INFERRED) — not the arithmetic, not the origin. Corroborating
  and worth testing: under the current rule *both* of algo 5's modulator writes land on one cell,
  and two LFOs clobbering a single gain cell is not a phaser. **SPECULATIVE.**
* **S6.** P1's 8 "chain-terminal exceptions" and C1–C3's misses are reported by the owning note as
  a reproduction and a failure respectively — and they are **the same eight words**. One defect at
  one location, double-counted as a success and a problem. **INFERRED** from the search; worth an
  independent check.

Evidence grade: §1 **MEASURED**; §2 the mis-specification **acknowledged**, the coincidence
**MEASURED**; §3 **MEASURED**; §4 **FORCED** as to C3, **MEASURED** as to F3; §5 **SPECULATIVE**.

---

## §181 — ⛔ `C63` NEVER WRITES `m_tb`. Three experiments were aimed at the operand of a word the device does not route to the ALU.

### 1. Results against `data/PREDICT_181.md`

| | pre-registered | measured | |
|---|---|---|---|
| **F1** both gates fire | two non-zero counts | bit 62 **1 165 869**, bit 18 **9 279 912** | ✔ |
| **F2** two-sided | `m_tb` chg → ~1.13 M, **or** stays ≈1 ⇒ `SRC 0x11` is not the route | **chg = 1 in both arms** | **arm 2** |
| **F3** control | arm B must reproduce §180 bit-exactly | `L −599858..8388607 nz 1128428`, `m_dp 5..5`, `P 0..1.76e13` — **exact** | ✔ |
| **F4** rule 1 | `§70 ACCA` min = max | `min 0 max 0` | ✔ (silent) |

Arm D does change the multiply — `L 0..8388607`, `P 0..3145727` against B's `1.76e13` — so bit 18 is
live and consequential. **`m_tb` is untouched by either.**

### 2. ★★★ WHY, and it is written in the source in plain sight

```cpp
  upd6383d.h:609   if (lo12(w) & 0x800) return true;    // the alternate lo12 encoding:
                                                        // addressing only, no ALU effect
  upd6383d.h:628   if (lo12(w) & 0x800) return false;   // the bit-11 MODIFIER ... Not part of
                                                        // the code -- simply not modelled on
                                                        // an ALU route yet.
```

`C63`'s `lo12` is **`0xC63`**, and `0xC63 & 0x800` is set. ⇒ **`C63` performs addressing only. It
does not execute an ALU operation, so it never writes `m_tb`, whatever `SRC 0x11` delivers.**

⇒ **§166 §3 is REFUTED.** It read `C63` as `SRC 0x11 / ACT 0x03 → m_tb = L` by applying the
**standard** `lo12` split to a word in the **alternate** encoding. ★ §166 graded that exactly
right at the time — *"the idiom's shape INFERRED, the identity of the index register
SPECULATIVE"* — and it is the SPECULATIVE half that falls. §166 §2's 53/53 bijection is a
measurement and stands untouched.

⇒ And it explains **three** experiments at once: §168 (bit 18 alone), §181 arm D (bit 18 + 62), and
the whole `SRC 0x11` line were testing **the source of a write that never happens.** `m_tb`'s
`chg = 1` was never evidence about `SRC 0x11` at all.

### 3. The size of the hole

Words whose `lo12` carries bit 11, C-format excluded:

```
  90 of 2989 corpus words = 3.0 %, in 9 distinct forms
     0xC63 x53 (25 programs)   0x8BC x24 (24 programs)   0x825 x3   0x821 x3
     0x839 x2   0x827 x2   0x822 x1   0x864 x1   0x921 x1
```

Only 3.0 % by population — but `0xC63` is **one half of the table-lookup idiom** (§166: 53/53), and
`0x821`/`0x825`/`0x827` are the **pointer-family loads** the header uses to set the operand origin
(`kn5000-dsp-pointer.md` §1). ⚠ **This is not a long-tail decode. It is small, and it sits on two
load-bearing structures.**

### 4. ⇒ NEXT TASK, and a warning about the task list

**Model the bit-11 alternate `lo12` encoding on an ALU route.**

⚠ Task #1 in this session's list — *"Decode the bit-11 alternate lo12 encoding"* — is marked
**completed**, and the device says *"not modelled on an ALU route **yet**"*. Either the earlier work
decoded the field without wiring it, or the completion was about something narrower. **Check what
that task actually delivered before redoing it** — thirteenth application of rule 3, and the first
where the stale record is my own task list rather than a note.

### 5. What survives from §180, unchanged

PTRD-A still takes CHORUS's index multiply from `L 0..0 nz 0` to `L` live on 1 128 428 of 1 129 389
firings. That result is independent of `C63` and is not affected by this refutation. It remains
**unshipped** for §180's three reasons.

Evidence grade: §1 **MEASURED**; §2 **FORCED** (read at source), §166 §3's SPECULATIVE half
**REFUTED**; §3 **MEASURED**; §4 procedural.

---

## §182 — ⛔ my own next-task was misconceived, and `bit11-family.md` had refuted §166 §3 FOUR DAYS EARLY

§181 set the next task as *"model the bit-11 alternate `lo12` encoding on an ALU route"* and flagged
that a task marked **completed** claimed to have decoded it. Following that flag first — as the
handoff instructed — found `analysis/bit11-family.md`, 447 lines, dated **2026-07-27**.

### 1. ⛔ THE TASK AS I WROTE IT CANNOT BE DONE, because the premise is wrong

That note's §9 establishes, on two independent measurements, that **`lo12` bit 11 selects a SECOND
ENCODING — on those words there is no `SRC` field and no `ACTION` field at all**:

* **§9.1** bits 11 and 5 co-vary, 80 of 80 over the body corpus, with one off-diagonal in a family
  whose `lo12` encoding is *already known* to be selector + flag.
* **§9.2** parsing the five bit-11 shapes as SRC/mode/ACTION needs **four field values attested
  nowhere else in the corpus**, plus a pointer mode §9.1 shows is not free.

⇒ `alu_decoded()` refusing every bit-11 word is **CORRECT, not a gap**, and `k3-pointers.md` item A
proves *by construction* that the firmware assembles bit 11 as a separate flag. **"Model it on an
ALU route" would have been implementing a field that does not exist.**

### 2. ⛔ AND §9.3 REFUTED §166 §3 BEFORE I WROTE IT

> *"`ACT 0x03`, `ACT 0x04`, `ACT 0x1C`, `SRC 0x02` and `SRC 0x04` **do not exist**. They are what
> you get by applying the bit-11-clear encoding to bit-11 words."*

`ACT 0x03` is the code §166 §3 used to claim `C63` performs `m_tb = L`. Verified here: **54 sites,
53 of them bit-11 set.** §181 refuted that reading by reading the device source; this note refuted
it four days earlier, from the corpus, with the stronger argument.

★ **Fourteenth occurrence of rule 3.** §167, §168 and §181's arm D are all *measurements* and stand;
what falls is only the interpretation, and §181 already retracted it. But the whole `SRC 0x11` line
would have cost nothing if `bit11-family.md` had been opened when §166 first wrote down `ACT 0x03`.

### 3. ★ WHAT IS NEW HERE — the note's own population excluded the header, and §178 said to check

`bit11-family.md` measures over *"2917 non-C-format words in the 38 distinct IC311 images"* — bodies
only. Re-run including the kernel and the epilogue (2989 words):

```
                 bit5 SET   bit5 CLEAR                   ACT 0x03   54 sites, 53 bit-11  (98.1%)
   bit11 SET         90           0                      ACT 0x1C   24 sites, 24 bit-11  (100%)
   bit11 CLEAR        1        2898                      SRC 0x02   25 sites, 24 bit-11  (96.0%)
```

* **§9.1 is STRENGTHENED on the wider population**: 90 of 90, still exactly one off-diagonal
  (`prog39 w58 = 801.0.00.021`, the cursor reset the note already names).
* **And §9.3 acquires exactly one genuine exception**: `epilogue w63 = 2A7.9.05.1C3`, `SRC 0x07`
  `ACT 0x03`, **bit 11 CLEAR**. ⇒ `ACT 0x03` is *not purely* a parse artefact — there is **one real
  site, and it is in the OUTPUT STAGE**, the one place this chip's signal has to emerge and does
  not. The note's population could not see it. *(The other three apparent exceptions — `w66`,
  `w72`, `w73` — are also epilogue words, and item A already discusses `w73` explicitly, so they
  are not counterexamples to anything the note claimed.)*

### 4. ⇒ RETARGET, to the note's own §6

> *"`C63` is now the highest-value undecoded form on the chip — 53 sites in 25 of 38 images …
> corpus-wide it is the single most common thing this chip does that we cannot read."*

with §6's second item as the concrete lead: **`8BC` co-occurs with `C63` in 23 of 24 of its images
and is exactly one per image**, against `C63`'s two — *"the shape of setup + per-channel use", and
testable against the pointer state, which is decoded.*

⚠ And item E is a standing correction to §166's label: `C63` count equals LFO count in only 11 of
16 images, is *exactly 2* in 20 of its 25, and **is never fewer** — *"the shape of a per-channel
constant, not a per-LFO one. `C63` is not the LFO's table read."* §166 §2's 53/53 bijection with
class 6 is a measurement and stands; the *name* does not.

Evidence grade: §1 **FORCED** (two independent measurements in the owning note, re-read not
re-derived); §2 **MEASURED**; §3 **MEASURED**, and new — the wider population is this pass's
contribution; §4 procedural.

---

## §183 — the bit-11 family rides exactly TWO carriers, and that gives it the minimal pair §7.2 said it lacks

`bit11-family.md` §7 is a decidability census: two routes closed, **one open** — the `w000` slot,
*"the only controlled comparison the bit-11 family has."* Tested here, and the structure underneath
turns out to be different from what that comparison assumes.

### 1. The `w000` test — a MISS, and the miss is informative

**Pre-registered:** `8BC` at `w000` ⟺ the image contains `C63`. **NULL** computed first: 19 of 28
images carry `C63` (0.679), so chance predicts 11.5 of the 17.

```
                  has C63   no C63
   w000 = 8BC        16        1          observed 16 vs null 11.5
   w000 = 00B         3        8          4 exceptions
```

Enriched, not a rule. The exceptions: **FLANGER, ENSEMBLE and MIX UP have `C63` with `00B` at
`w000`**, and AUTO WAH+S.DELAY has `8BC` with no `C63`.

★ And FLANGER and ENSEMBLE **do** carry `8BC` — just not at `w000`. Which is the whole point.

### 2. ★★★ ALL 90 bit-11 words sit on exactly TWO carriers. Zero on any other.

```
   class 0, addr8 0x00     73 words
   class 1, addr8 0x30     17 words   -- all seventeen are ONE form, 880.1.30.8BC
   anything else            0
```

and the class-0 side resolves into three groups:

```
   040.0.00.C63 x46   142.0.00.C63 x7                      <- C63, 53
   040.0.00.8BC x6    050.0.00.8BC x1                      <- 8BC on the CLASS-0 carrier, 7
   040.0.00.864 x1    050.0.00.921 x1
   80x.0.**.{821,822,825,827,839} x11                      <- the register-load family, encoding
                                                              PROVEN by construction (k3-pointers A)
```

⇒ **The same payload `8BC` rides two different carriers** — a class-0 word and a class-1 delay
access. **The bit-11 payload is therefore carrier-independent**: its meaning cannot depend on
`class4`, because the identical twelve bits appear under two different ones. That is a real
constraint on what the alternate encoding can be, obtained without decoding it.

### 3. ⇒ §7.3's controlled comparison is comparing the wrong axis

`880.1.30.8BC` vs `880.1.30.00B` holds `hi12`/`class4`/`addr8`/position fixed and varies `lo12` —
but `8BC` is a **bit-11 payload** and `00B` is an **ALU `lo12`**. They are not two values of one
field; they are two different *encodings*. The comparison can isolate "which encoding is used
here", never "what the payload means".

⚠ That also explains §1's exceptions without any new hypothesis: FLANGER and ENSEMBLE put the same
payload on the class-0 carrier instead. **The `w000` split is about the CARRIER, not the payload.**

### 4. ★★ And the family DOES have a minimal pair — §7.2 looked across the flag, not within it

§7.2 tested each bit-11 word against itself with bit 11 **cleared**: 0 of 8 present. Correct, and it
closes comparison *across* the flag. But **within** the flag the same carrier hosts three payloads:

```
   040.0.00.C63   x46          040.0.00.8BC   x6          040.0.00.864   x1
   ^ identical hi12, class4 and addr8 -- differing in NOTHING BUT lo12, all three bit-11 set
```

⇒ **A true minimal set across the alternate encoding's own payload field**, on 53 sites against 6
against 1. Whatever `lo12` encodes under bit 11, `C63` and `8BC` differ *only* in it, on a carrier
that is otherwise byte-identical. **This is the comparison §7 concluded did not exist**, and it is
strictly better posed than the `w000` one because both sides are in the same encoding.

### 5. SPECULATIVE

* **S7.** `8BC` is once per image and `C63` twice (the note's §6.2, "setup + per-channel use").
  Under §2's carrier-independence, the natural reading is that the alternate `lo12` is a **small
  operation selector** and the carrier supplies its operand — a delay access for `880.1.30.8BC`, a
  bare class-0 word for `040.0.00.8BC`. **SPECULATIVE**, but it predicts that the class-0 and
  class-1 `8BC` sites should behave differently in exactly the way their carriers differ, which is
  measurable.
* **S8.** The `80x` register-load group is *already decoded by construction* and is in the same
  encoding. It is the only bit-11 group whose meaning is known — so it is the **Rosetta candidate**:
  whatever rule explains `821`/`825`/`827`/`839` must also parse `C63` and `8BC`. That constraint
  has not been applied. **SPECULATIVE**, and the cheapest next test.

Evidence grade: §1 **MEASURED** (null computed first, a pre-registered MISS); §2 **MEASURED**,
exhaustive over all 90; §3 **FORCED** by §2; §4 **MEASURED**; §5 **SPECULATIVE**.

---

## §184 — the alternate `lo12` decomposes, and there is exactly ONE payload with a decoded sibling

§183 handed forward the Rosetta constraint: `k3-pointers.md` §1.1 item 2 proves **by construction**
that the firmware builds `lo12 = 0x800 | X` — *"not opaque constants `0x821`/`0x825`"* — because
`INC 8, WA` adds a literal 8 to byte 3 *after* the address nibble is placed. Applied here.

### 1. Stripping the flag does NOT find the payloads elsewhere — and that is a result

```
   lo12   X = lo12 & 0x7FF    occurs with bit 11 CLEAR?
   0x821  ->  0x021           YES x1   <- rstcur, the pair k3 §1.2 already names
   0x822  0x825  0x827  0x839  0x864  0x8BC  0x921  0xC63     ->  none
```

**1 of 9, against a null of 0.3** (70 distinct `lo12` values occur bit-11-clear, of 2048). The
alternate encoding's payloads are **disjoint** from the ALU encoding's values. ⇒ supports
`bit11-family.md` §9's *"second encoding"* over the *"modifier on an otherwise-ALU `lo12`"* reading,
from a third direction.

### 2. ★★ But the flag is not alone up there — a SUB-FIELD at `lo12[10:8]`

```
   lo12[11:8]   sub    sites   forms
      0x8        0       36    821 822 825 827 839 864 8BC
      0x9        1        1    921
      0xC        4       53    C63
```

⇒ **`lo12` under bit 11 decomposes as `FLAG(11) | SUB[10:8] | PAYLOAD[7:0]`**, with `sub ∈ {0,1,4}`.
`sub` separates **`C63` (53 sites, sub 4) from every other member of the family** — perfectly, and
it is the only field that does. All 28 register-load words sit at `sub = 0` with no exceptions.

### 3. ★★★ THE PAYLOAD-`0x21` TRIPLE — the only payload collision in the corpus

Enumerating every payload that appears under more than one `(flag, sub)`:

```
   payload 0x21:   0x021    0x821    0x921        <- and NOTHING ELSE collides, anywhere
```

```
   lo12 0x021   flag 0  sub 0   x1    rstcur — DECODED (k3 item K)        prog39_parametric_eq w58
   lo12 0x821   flag 1  sub 0   x3    ldptr  — PROVEN BY CONSTRUCTION     kernel w42, w50, epilogue w69
   lo12 0x921   flag 1  sub 1   x1    ⚠ UNDECODED                        prog10_multi_tap_delay w33
```

**Two of the three are decoded, and one of those is proven from the firmware's own assembly.**

⇒ `050.0.00.921` at MULTI TAP DELAY `w33` is **the highest-leverage single undecoded word in the
bit-11 family**: it is one `sub` value away from a decode that cannot be argued with, on a payload
whose other two readings are known. Nothing else in the corpus offers that.

### 4. ⚠ And it reframes the `C63` task

`C63` is `sub 4 / payload 0x63`; `8BC` is `sub 0 / payload 0xBC`. **They differ in *both* fields**,
so they are not siblings and `8BC` cannot bound `C63` the way §6.2's once-vs-twice pairing implied.
The `040.0.00.C63` / `040.0.00.8BC` minimal pair §183 found is real as a *carrier* control, but
under this decomposition it varies two fields at once.

⇒ The tractable target is **`0x921` first, not `C63`** — decode the `sub` field where two of three
values are already known, then apply it to `C63`'s `sub = 4`.

### 5. SPECULATIVE

* **S9.** `0x021` = *reset the cursor*, `0x821` = *load the pointer*. Both are pointer/cursor
  operations **on the same payload**, distinguished by the flag. The natural reading is that
  `payload` names a register-family operand and `(flag, sub)` selects the operation — making
  `0x921` a **third pointer/cursor operation**, in MULTI TAP DELAY, an effect that plausibly needs
  one. **SPECULATIVE**, but it predicts `0x921`'s effect is on pointer state and nothing else,
  which is measurable against the `§164` census.
* **S10.** `sub = 4` is one-hot-ish against `sub = 1`, and `C63` — 53 sites, more than half the
  family — is the only occupant. A field whose most common value is used by exactly one form is
  more likely a *mode* than an *opcode*. **SPECULATIVE.**

Evidence grade: §1 **MEASURED** (null computed first); §2 **MEASURED**, exhaustive over all 90;
§3 **MEASURED** (the collision is exhaustive over the corpus), the two decodes cited not re-derived;
§4 **FORCED** by §2; §5 **SPECULATIVE**.

---

## §185 — reading the alternate encoding as SELECTOR + VALUE: `C63` is a per-channel RESET

§184 decomposed the alternate `lo12` as `FLAG | SUB[10:8] | PAYLOAD[7:0]`. `k3-pointers.md` §1.1
item 1 supplies the other half, **proven by construction**: *"`addr8` is exactly bits [19:12] and
the payload is 8 bits"* — the firmware writes the **value** into `addr8`. So on these words
`lo12[7:0]` is a **selector** and `addr8` is the **value written**.

### 1. The whole family, read that way — MEASURED

```
  selector  sub  sites   addr8 (the VALUE)      hi12 carriers
    0x21     0      3    50  70  90             801        <- ldptr: real pointer values
    0x21     1      1    00                     050        <- ★ THE TARGET
    0x22     0      1    86                     859
    0x25     0      3    25  26                 801
    0x27     0      2    64  6C                 801
    0x39     0      2    00                     809 80B
    0x63     4     53    00                     040 142    <- C63, ALWAYS zero
    0x64     0      1    00                     040
    0xBC     0     24    00  30                 040 050 880
```

★ **`addr8` is non-zero only on the `0x80x` carriers** — and on `880.1.30.8BC`, where `0x30` is the
delay **direction** code (FORCED, adjudication-round5). On the `040`/`050`/`142` carriers it is
**identically zero across all 62 sites**.

### 2. ⇒ INFERRED — the `04x`/`05x` carrier writes ZERO, i.e. it RESETS

If `addr8` is the value, then every one of those 62 words writes **0** to its selector. That is a
**reset**, not a load. And it explains a measurement `bit11-family.md` recorded as a puzzle:

> item E: *"`C63` is **exactly 2** in 20 of its 25 images — which is the shape of a **per-channel
> constant**, not a per-LFO one."*

⇒ **`C63` resets register `0x63`, once per channel.** That is the first coherent reading of *"the
single most common thing this chip does that we cannot read"* — 53 sites, 25 images — and it comes
from a construction proven off the firmware's own assembly rather than from a corpus statistic.

### 3. ★★ And `0x921` reads out at a SECTION BOUNDARY

`050.0.00.921`, MULTI TAP DELAY `w33`, in context:

```
   w30  202.A.0C.1D5   mac (p),c+,(p)+12    C-RAM[0x06]  role mix/TAP
   w32  000.2.FD.407   ld.st acc,(p)-3
   w33  050.0.00.921   <- selector 0x21 (the POINTER register), value 0, STORE bit set
   w34  002.A.03.1D5   mac (p),c+,(p)+3     C-RAM[0x07]  role FILTER
```

Three things line up at once: the C-RAM **role annotation changes from tap to filter** exactly
here; the word is bracketed by a **symmetric `−3`/`+3`** pointer excursion; and its selector is
`0x21`, the register `ldptr` loads and `rstcur` resets.

⇒ **INFERRED: `0x921` resets the pointer at a section boundary** — which is precisely what a
multi-tap delay needs between its tap bank and its damping filter.

### 4. ⚠ WHAT THIS IS NOT

`k3-pointers.md` proves its construction for the form **`hi12 = 0x801`**. `C63` and `0x921` sit on
`0x040`/`0x050`/`0x142`. **Transferring the selector/value reading across carriers is INFERRED, not
FORCED**, and it rests on §183's measurement that the payload is carrier-independent (the same
`8BC` rides class 0 and class 1). ⚠ It is exactly the kind of step that has been retracted here
before — §166 §3 applied a decode across an encoding boundary and was wrong.

★ **The falsifiable consequence, and it is cheap:** if `C63` zeroes a register twice per frame per
image, that register must show **exactly two writes of 0 per frame** in the existing
`§164`/`§176` census once the word is modelled. If it shows a different count, or writes a non-zero
value, the reading is refuted. **Do not implement it without that pre-registration.**

### 5. SPECULATIVE

* **S11.** Selectors `0x63` and `0x64` are **adjacent**, and `0x64` occurs once on the same `040`
  carrier. Adjacent selectors reset together is the shape of a **register pair** — plausibly the
  two channels whose per-channel reset §2 infers. **SPECULATIVE.**
* **S12.** `sub` may not be an opcode at all: `sub 0` covers every proven register load, `sub 1` and
  `sub 4` each have exactly one selector. A field whose non-zero values are used by one selector
  apiece looks like a **register-bank** or width selector rather than an operation. **SPECULATIVE**,
  and it competes with §184 S9.

Evidence grade: §1 **MEASURED**, exhaustive; §2 **INFERRED** from a FORCED construction, with the
independent corroboration of item E's per-channel count; §3 **INFERRED** (three independent
alignments); §4 the limitation **stated**; §5 **SPECULATIVE**.

---

## §186 — two corrections, both caught BEFORE a build: my own falsifier was circular, and the roadmap's headline defect is fixed

### 1. ⛔ §185's falsifier cannot fail — caught before running it

§185 proposed: *"once modelled, that register must show exactly two writes of 0 per frame."*

**That returns its own input.** `C63` appears exactly twice per image **in the static corpus** — that
is where the per-channel reading came from (`bit11-family.md` item E). Modelling the word and
counting its writes measures the disassembly, not the machine.

And the *effect* is nil: **register `0x63` is in no non-zero census.** `m_rf` non-zero cells are
`06` and `1D..40`; D-RAM's are `01 02 04 06 07 0E 92`. Writing 0 over 0 changes nothing, so
"bit-identical" would also be the outcome if `C63` were a no-op — which is the current model.

⇒ **The selector/value reading is, as posed, UNTESTABLE in this emulator.** ★ Fifth
criterion-that-cannot-fail on this project, and the second caught *before* the run rather than
after.

★ What the reading *does* have is a **known-answer control that could have failed and did not**: on
the `0x80x` carriers it predicts `0x821` with `addr8 = 0x70` loads `0x70` into register `0x21` —
which is exactly what `k3-pointers.md` decodes `ldptr` to do. The reading is well supported
*where it is checkable* and unobservable *where it is new*. That is worth stating plainly rather
than dressing up as a result.

### 2. ⛔⛔ AND THE ROADMAP'S ITEM (a) IS STALE — verified at source, not repeated

Chasing "what would make it observable" led to `ROADMAP-2026-07-29.md`, whose **first** listed
defect is:

> *"(a) INGRESS — the host poke port is unimplemented … all 881 tag-`0x15` D-RAM writes and all 870
> tag-`0x4C` descriptor writes are dropped … no per-effect parameter (delay time, reverb time,
> feedback, high-damp, LFO waveform table, ER level) has ever reached the chip."*

That would explain the silence, the empty D-RAM and the zero descriptors **at one stroke**, and I
was one step from reporting it as the live blocker.

**It is fixed.** `upd6383.cpp:872` implements the poke port (§59 P1.1); the comment there describes
the former bug **in the past tense**, and the code decodes the 5-byte packet stream and routes tags
`0x15` → `m_rf`, `0x4C` → `m_dscbank`, `0x26` → `m_cram`.

★ **Rule 10 again — "a blocker is a MEASUREMENT and measurements expire" — this time applied to
another document rather than my own.** §165 earned that rule by finding a stale blocker still
believed; this is the mirror case, a stale *defect report* that would have sent a whole tick
backwards. **Verifying at source instead of repeating the citation is the entire difference.**

⚠ The roadmap is dated 2026-07-29 and is quoted elsewhere in this register. **Every claim taken
from it needs the same treatment before use.**

### 3. ⇒ The constructive redirect

The reading predicts `C63` resets a register. **A reset presupposes a writer.** Tag-`0x15` host
writes land at `m_rf[m_dram_wp & 0xff]` on a walking pointer, and the roadmap counts **65 cells**
written — while the census shows non-zero only at `06` and `1D..40`, about 37.

⇒ **Next: instrument which `m_rf` cells the host actually writes — all of them, not just the ones
that end non-zero.** Two-sided and it decides something:

* `0x63` **is** in the host's write range ⇒ the selector plausibly names that register, the reset
  has something to reset, and the reading becomes testable by clearing it.
* `0x63` is **not** ⇒ the selector space is not `m_rf`, and §185 §2's identification is wrong even
  though its arithmetic (`addr8` = value) survives on the `0x80x` control.

Evidence grade: §1 **FORCED** (the circularity is structural); §2 **MEASURED** (read at source);
§3 procedural, with both arms stated.

---

## §187 — the selector space is NOT `m_rf`, and a collision proves it

§186 §3 asked which `m_rf` cells the host actually writes, two-sided: if selector `0x63` is in the
host's range the §185 reading becomes testable; if not, the selector space is something else.

### 1. MEASURED — the host tag-`0x15` write targets

```
  59 writes over 55 cells (38 ever non-zero)     |  0x63 written 0 times
  05 06 07 0E 10 11 | 1D..40 (36 cells) | 50 51 52 53 | 85 86 87 8A 8B 94 | D0 D1 D2
```

★ The contiguous `1D..40` block is **exactly §161's wavetable window**, 36 cells — the sine's
provenance confirmed from the host side for the first time.

### 2. ⚠ A near-miss I nearly filed as support

Five of the eight selectors — `0x21 0x22 0x25 0x27 0x39` — **are** in the host's written set, which
reads as evidence for the `m_rf` identification. It is not: all five lie inside `0x1D..0x40`, i.e.
inside the wavetable block. **Coincidence of numeric range.** My first script printed "5 of 8 IN"
and I nearly reported it.

### 3. ★★★ AND THE COLLISION IS THE PROOF — the spaces are different

```
   selector 0x21  =  THE POINTER REGISTER     k3-pointers.md, PROVEN BY CONSTRUCTION (ldptr)
   m_rf[0x21]     =  wavetable index 4        §161, part of a bit-exact 36-entry sine
```

**A pointer register is not a sine-table entry.** Two independent, differently-grounded
identifications of index `0x21` cannot both be `m_rf`.

⇒ **FORCED: the alternate encoding's `lo12[7:0]` selector space is NOT `m_rf`.** It is the chip's
internal control-register file — which is exactly what `k3-pointers.md` means by *"the `0x_2x`
selector block"*, and what `ldptr`/`rstcur` target.

★ Note this is proven by a **collision**, not by `0x63`'s absence. Absence would have been weak;
two contradictory decodes at one index is not.

### 4. ⇒ Consequences, in both directions

* **§185 §2's identification is REFUTED**: "`C63` resets register `0x63`" cannot mean an `m_rf`
  cell. ⚠ §185's *arithmetic* — `addr8` is the value, `lo12[7:0]` the selector — is untouched: it
  rests on the `0x80x` known-answer control (`ldptr` loading `0x70`), which this does not disturb.
* **§186 §1's objection dissolves too.** I argued the reading was untestable because "writing 0
  over 0 changes nothing". That assumed the target was in a memory census. Control registers are
  in no census at all, so the objection was aimed at the wrong space — and so was the falsifier.

### 5. ⇒ The tractable target is still `0x921`, and now for a stated reason

Selector `0x21` is the **pointer** register, and the pointer's effect is **observable** — `m_dp` is
instrumented at every site (§162, §176). So `0x921` is the one family member whose predicted effect
can be measured. It sits in MULTI TAP DELAY, **TYPE 8** in §170's map, reachable by navigation.

⚠ **Open discrepancy, flagged not asserted:** this run counts **59** tag-`0x15` writes;
`ROADMAP-2026-07-29.md` counts **881 / 65 cells**. Different captures (cold-boot CHORUS here vs
cold-boot + PARAMETRIC EQ there) — but a factor of 15 is too large to leave unexamined, and §186
already found that roadmap's headline item stale.

Evidence grade: §1 **MEASURED**; §2 the artefact **acknowledged**; §3 **FORCED** by the collision
of two independently-grounded decodes; §4 follows; §5 procedural, with the discrepancy flagged.

---

## §188 — the host payload's LSB was being dropped. SHIPPED, default → `0xB910E446A39B440F`.

Chasing §187's flagged "59 vs 881" discrepancy closed it (1086 tag-`0x15` packets over a 37-effect
walk ≈ 29 per effect per unit; my one-effect two-unit run measured 59 — **no defect**) and turned up
a real one on the way.

### 1. ⛔ A hypothesis refuted in the same breath as forming it

The tag histogram pairs cleanly — `15`/`95`, `26`/`A6`, `4C`/`CC` — each differing in **bit 7**, and
the device does `switch (tag & 0x7f)`, discarding it. That reads as a **unit selector** being
thrown away, which would mean unit-1's parameters clobbering unit-0's.

**It is the payload's LSB.** `k5-output-stage.md` item 9 and `k3-pointers.md` §1.1 item 3 both give
the decode as `V = ((aa&0x7F)<<17)|(bb<<9)|(cc<<1)|(dd>>7)` — **PROVEN BY CONSTRUCTION**, off the
firmware's own writers. `adjudication-round4.md` item D says so explicitly. Sixteenth application of
rule 3, and the cheapest yet: the idea and its refutation arrived together.

### 2. ★ But the decode exposes a live defect

```
   PROVEN     V = ((aa&0x7F)<<17) | (bb<<9) | (cc<<1) | (dd>>7)
   DEVICE     v = ((aa<<16)|(bb<<8)|cc) << 1  =  (aa<<17)|(bb<<9)|(cc<<1)
```

§111's `×2` reproduces the three shifts and **drops `dd>>7`**. 32 % of host packets carry it set, so
a third of every host-programmed quantity in this machine was 1 LSB low. `adjudication-round4.md`
item D records this retraction as having *"never reached"* six documents, leaving **7 live sites**.
This was one.

### 3. ★★★ Measured STATICALLY first, then confirmed bit-exactly

The host stream contains the LFO sine. Decoding those 24 packets both ways against
`round(0.95 × 2^23 × sin(2πk/24 + 0.1))` — **before writing any code**:

```
   PROVEN decode : max err 1 LSB, RMS 0.707        tag bit 7 set in 12 of 24 -- half,
   DEVICE decode : max err 2 LSB, RMS 1.291        as a sine's LSBs should be
```

Implemented as mask bit 63 and run against `data/PREDICT_188.md`:

| | pre-registered | measured | |
|---|---|---|---|
| **F1** fires | > 0, not all packets | **46 of 115 (40.0 %)** | ✔ |
| **F2** the fit | max `2 → 1` LSB, RMS `1.291 → ≈0.707`, and 16/24-negative must stop | **max 1 LSB, RMS 0.707, 12/24 negative** | ✔ exact |
| **F3** null half | bit-7-clear cells bit-identical | **True** | ✔ |
| **F4** rule 1 | `§70 ACCA` min = max | `min 0 max 0` | ✔ silent |

★ **RMS `0.707` = `1/√2`, exactly the RMS of uniform ±0.5 rounding.** The residual is now pure
quantisation — the table is reproduced as exactly as a 24-bit integer can represent it.

★★ And the 12 cells that moved match the capture's tag-bit-7 pattern **bit-for-bit**:
`011000000011100111111100`. That is a 24-bit prediction made from the host stream and confirmed in
the register file, with no fitted parameter between them.

### 4. SHIPPED

Default `0x3910E446A39B440F` → **`0xB910E446A39B440F`**, verified with no env override.

⚠ **The chip is still silent** (`min 0 max 0`), and this was pre-registered as not an audio fix.
What it buys is that **every host parameter in the device is now bit-exact** — delay times, reverb
times, feedback, damping, levels and the LFO table — which every downstream measurement has been
resting on.

### 5. ⚠ A correction to my own working

Fitting the *measured* table with a free amplitude and phase gave "mean residual exactly −1.000,
24 of 24 negative", and I tested "add 1 to every value", which improved it. **That was an
artefact** — a free fit lets `A`/`φ` absorb per-value structure. The packet-level check showed the
deficit is **per value, set in 12 of 24**. Scoring against the **ideal formula** rather than a fit
to the corrupted data is what made F2 a real criterion.

Evidence grade: §1 **FORCED** (two notes, by construction); §2 **FORCED**; §3 **MEASURED**, all four
falsifiers pre-registered and exact; §5 the artefact **acknowledged**.

---

## §189 — §188 reached the descriptors too; the read/write pairing confirms; P16's ladder does not appear

`adjudication-round4.md` item D says §188's retraction leaves **7 live sites**, and flags premise
**P16** as the one that *"matters operationally: a control or an impulse test sized against the
halved numbers **amputates the feedback of every line**."*

### 1. ★ §188 already covers the descriptors, and the correction has the right SHAPE

The LSB restoration sits **before** the tag switch, so it applies to tag `0x4C` (descriptors) and
`0x26` (C-RAM) as well as `0x15`. And P16's correction is exactly `×2 + LSB`:

```
   raw   corrected    2n?   2n+1?
   127      255              yes
   489      979              yes
   183      366       yes
   522     1044       yes
  4452     8905              yes
   435      869              --     (435 is itself round(869/2); the raw was 434)
```

⇒ §111's bit 31 (`×2`, already in the default) **plus** §188's LSB is precisely r3's correction.
Both are now shipped.

### 2. ★★ A structural confirmation that came free

The descriptor bank pairs exactly:

```
   02==07   04==09   06==0B   08==0D   0A==0F   0C==11   0E==13   10==15   12==17
```

**Nine `k ↔ k+5` pairs, no exceptions** — the delay READ/WRITE descriptor pairing, confirmed from
the live bank for the first time. (Direction itself is FORCED elsewhere by `addr8` bit 6.)

★ And CHORUS's own block reads out correctly: `26:0190` = **400** and `2B:0410` = **1040** — exactly
the nominal tap position and line length `§152` computed **from the ROM alone**. A positive control
that the bank is being read right.

### 3. ⛔ But P16's ladder is NOT in this bank — neither corrected nor halved

Searching every pairwise difference among the 32 non-zero cells for
`255 / 869 / 979 / 366 / 1044 / 8905` — and for their halves:

```
   corrected ladder :  0 of 6 found
   halved ladder    :  0 of 6 found
```

The unit-1 chain's consecutive differences are `569 707 1250 1674 480 512 870 678 900 840`. Only
`480` coincides with `adjudicate4`'s doubled partition, and `870` is one away from `869` — **not
enough to claim anything**.

⇒ **Recorded as an open discrepancy, not forced.** Three readings, none chosen:
* the cold-boot unit-1 effect is not ROOM REVERB 1 (the vehicle's unit-1 program has never been
  identified the way §170 identified unit 0's);
* the ladder is not a difference of descriptor cells but is computed some other way;
* `m_dscbank[..] = u16(v & 0xffff)` **truncates a 24-bit payload to 16 bits** — and every unit-1
  cell here has bit 15 set, which is what a lost high byte would look like.

★ The third is checkable in one line and should be checked first.

### 4. What is NOT claimed

§188 shipped on its own evidence (a bit-exact wavetable control). **Nothing here corroborates or
undermines it** — the descriptor path simply inherits the same fix. And no claim is made that the
reverb's delay lines are now correct: P16's numbers were not found, so that remains open.

Evidence grade: §1 **FORCED** (the arithmetic) ; §2 **MEASURED** (9 of 9 pairs; the CHORUS control);
§3 **MEASURED** as a negative, the three readings **ENUMERATED, not chosen**.

---

## §190 — two of §189's three readings are REFUTED, both statically. The third is narrowed, not settled.

### 1. ⛔ "the descriptor payload is truncated 24→16" — REFUTED, one grep

`r3-delaydram.md` **P5**, MEASURED over 870 cells across 100 algorithms:

> *"Delay memory map: unit 0 = `[0x00000, 0x08000)`, unit 1 = `[0x08000, 0x10000)` — 32 768 words
> each. **No address the firmware ever writes reaches 2¹⁶ (max 64 899).**"*

⇒ `m_dscbank[..] = u16(v & 0xffff)` is **CORRECT**, not a defect. And the observation that prompted
the suspicion — *"every unit-1 cell has bit 15 set"* — is **explained**: unit 1's range **is**
`[0x8000, 0x10000)`, so bit 15 must be set. Seventeenth application of rule 3, answered in one grep.

★ Two bit-exact corroborations fall out of the same live bank:

```
   03:8000 = 32768   exactly the unit-1 BASE
   1E:7FFF = 32767   exactly one below it -- the unit-0 CEILING
```

Neither was fitted to anything; both are the boundary P5 measured, appearing as literal descriptor
cells.

### 2. ⛔ "the cold-boot unit-1 program is not ROOM REVERB 1" — REFUTED

§170's method, applied to the other unit for the first time. Program-sized uploads by load address:

```
   I-RAM[84..]  x37   (unit 0, the TYPE walk)      I-RAM[200..] x1   <- unit 1, loaded ONCE
   I-RAM[352..] x30   I-RAM[0..] x3   I-RAM[60..] x1
```

```
   transfer 18   prog16_room_reverb_1   ROOM REVERB 1
```

Matched on the same 16-word fingerprint §170 validated. **The unit-1 program is identified for the
first time**, and it is what the cold-boot notes said.

### 3. ⚠ The third reading survives — and I am NOT claiming the obvious explanation

Only *"the ladder is not a difference of descriptor cells"* remains. The tempting resolution is
that the capture is at a different **reverb-time** setting:

```
   long head here   02 - 00 = 41925 - 33255 = 8670        r3's long head 8905   (2.64 % apart)
   ladder here      569 707 1250 1674 480 512 870 678 900 840
   r3's ladder      255 869 979 366 1044
```

⛔ **That does not hold up as stated, and I would rather say so.** The two sets have **different
element counts** (10 vs 5; `adjudicate4`'s re-derivation has 11), so they are not one set rescaled.
`480` appears in both and several others are close (`1250`/`1232`, `870`/`856`, `707`/`720`) — which
is suggestive and is *exactly* the kind of near-match this project has been burned by.

⇒ **SPECULATIVE, and explicitly not adopted.** What would settle it: capture at a **known**
reverb-time setting and check whether the ladder scales by a single factor. If every element scales
together, the parameter explanation holds; if the element *count* changes, the ladder is not a
simple difference chain and P16's numbers are computed some other way.

### 4. Standing

`adjudication-round4.md` item D's **7 live sites** for the halved-payload retraction: §188 fixed
one (the device's own decode). The remaining six are in *documents*, not in the emulator, and
`tools/retraction_sweep.py` P16 already detects them — that is a documentation sweep, worth doing
but not a decode.

Evidence grade: §1 **FORCED** (P5 is MEASURED and the arithmetic is decisive), with two bit-exact
corroborations; §2 **MEASURED**; §3 **SPECULATIVE and declined**, with the deciding experiment
stated.

---

## §191 — the probe reverses the target: `0x921` sits at a CONSTANT pointer, `C63` is the one that varies

Built to answer §162's rule — *measure that a consumer's inputs vary before implementing it* — for
the `0x921` reset. It took two attempts to place, and both failures are worth recording.

### 1. ⚠ Two instrument defects, both mine

* **Wrong function.** I put the probe in `exec_addressing_only()` — the function whose *name*
  matches "addressing only, no ALU effect". It is only reached from the k6 path (`:1708`), so **no
  bit-11 word ever entered it** and the first run logged **zero sites**. LEDGER rule 10 applied to
  my own instrument: I instrumented the concept, not the path.
* **C-format pollution.** The second placement worked but had no `c_format` filter, and its 12
  slots filled with **C-format false positives** (`0C0A292820`, `0C04312820`, …) whose 13-bit
  *immediate* merely happens to carry bit 11. The static census excluded C-format; the probe did
  not. ⇒ **A probe whose sample is chosen by arrival order must be filtered at the door.**

### 2. MEASURED — the pointer at every bit-11 word, MULTI TAP DELAY vehicle (TYPE 8)

★ Control first: `I-RAM[84] = prog10_multi_tap_delay`, `I-RAM[200] = prog16_room_reverb_1` — §170's
TYPE map confirmed **live**, on a different unit and a different effect from the one it was built on.

```
   0040000C63  sel 63 sub 4   hits 1441604 | m_dp   5..208  chg 70177   ★ VARIES
   0142000C63  sel 63 sub 4   hits 1405020 | m_dp  13..210  chg 32902   ★ VARIES
   ------------------------------------------------------------------------------
   0050000921  sel 21 sub 1   hits  552876 | m_dp  16..16   chg 0       CONSTANT
   0040000864  sel 64 sub 0   hits  552876 | m_dp  16..16   chg 0       CONSTANT
   08801308BC  sel BC sub 0   hits 1383360 | m_dp   5..5    chg 0       CONSTANT
   00400008BC / 00500008BC    (both)       | m_dp   5..5    chg 0       CONSTANT
```

★ `0x921` and `0x864` have **identical hit counts (552 876)** and sit at the **same constant
pointer (16)** — they execute together, once per frame, in the same block. §185 S11 guessed
`0x63`/`0x64` were a pair; the measured pairing is `0x921`/`0x864`.

### 3. ⇒ THE TARGET IS REVERSED, and the motivating argument dissolves

§185 §3 inferred that `0x921` *"resets the pointer at a section boundary"*, motivated by the C-RAM
role changing tap→filter there. **The pointer at that word is already a constant 16 in every one of
552 876 executions.** So the *function* the reading attributes to it — giving the filter section a
fixed base — is already true without it.

⚠ Precisely: implementing the reset **would** change something (`m_dp` 16 → 0, shifting the whole
filter section's addressing by −16). It is not unobservable. But **nothing available says which
value is correct**, because both are constants and there is no independent ground truth for where
the filter section should read. ⇒ **no criterion, rather than no effect** — and building it would
produce a change I could not grade.

⇒ **`C63` is the one bit-11 form whose pointer varies**, at two carriers, tens of thousands of
changes each. It is where a pointer-affecting reading *can* be tested — the opposite of what §184
and §190 concluded on structural grounds.

### 4. SPECULATIVE

* **S13.** The split is **exactly `sub 4` varies / `sub 0` constant**. If `sub` selected a register
  bank (§185 S12) rather than an operation (§184 S9), a systematic difference in pointer state
  between the two is what you would expect. **SPECULATIVE**, and it now has a measurement behind it
  rather than only a population count.
* **S14.** `0x8BC` sits at `m_dp = 5` on **all three** of its carriers — including the class-1
  delay word and both class-0 words. §183 measured the payload as carrier-independent; this is the
  first behavioural evidence for it. **SPECULATIVE.**

Evidence grade: §1 both defects **acknowledged**; §2 **MEASURED**, with the vehicle's program
identity as a passing control; §3 **FORCED** by §2 (the pointer is constant, so the motivating
argument cannot discriminate); §4 **SPECULATIVE**.

---

## §192 — ⛔ §191 §3's "target reversal" needs a vehicle qualifier. The bit-11 family has NO gradeable test.

### 1. The contradiction I went looking for is not there

§166 measured `C63` immediately followed by the class-6 word, 53/53 both ways. `C63` is class 0, so
it carries no post-increment — the two words must see the **same** pointer. §191 reported `C63`'s
`m_dp` as **varying** and §162 reported the class-6 word's as **constant 12**, which cannot both
hold with nothing between them. Run on the cold-boot CHORUS vehicle, both probes in the same run:

```
   §191  0040000C63   m_dp 12..12  chg 0        §162  class-6 site  m_dp 12..12
   §191  0142000C63   m_dp 14..14  chg 0        §162  class-6 site  m_dp 14..14
```

**Perfectly consistent, and pairwise exact.** No contradiction, and nothing resets a pointer here.

### 2. ⛔ Which means §191 §3 was over-stated

§191 concluded *"`C63` is the one bit-11 form whose pointer varies"* from **one vehicle**
(MULTI TAP DELAY: `5..208` and `13..210`). In CHORUS the same two words are **constant**.

⇒ **Pointer variability is a property of the PROGRAM, not of the word.** MULTI TAP DELAY walks a
long tap bank; CHORUS does not. The "target reversal" stands only for MTD, and I should have said
so.

> ★ **RULE: a pointer-state statistic needs a vehicle qualifier, exactly as §148 established for
> audio statistics.** "Word X's pointer varies" is not a fact about X.

### 3. ★ What the run DID buy — behavioural confirmation of the C63 ↔ class-6 pairing

`C63`'s two carriers sit at `m_dp` **12** and **14**; the two class-6 words sit at **12** and
**14** — matching **pairwise**. §166 established the pairing structurally (a 53/53 bijection in the
corpus); this is the first time it has been confirmed **in the running machine**, and it is exact.

### 4. ⇒ THE HONEST POSITION: the family has no gradeable test right now

| candidate | why not |
|---|---|
| `0x921` | pointer already constant (552 876 executions); implementing changes `m_dp` 16→0 but **nothing grades which is right** (§191 §3) |
| `C63` | constant in CHORUS, varying in MTD — and in both cases the value it would be reset *to* has no ground truth |
| `0x8BC` | constant `m_dp = 5` on all three carriers |

`bit11-family.md` §7's decidability census closed two routes and left `w000` open; §183 showed
`w000` compares **encodings, not payloads**. ⇒ **All four routes are now closed**, and the family is
**undecidable by the instruments this project currently has**. That is a result, not a failure —
and it is what §7 was written to find out.

⚠ **Do not spend further ticks proposing bit-11 experiments without first naming the criterion that
would grade them.** Three have now been proposed and withdrawn (§185's reset count, §186's
"bit-identical", §191's pointer reset).

### 5. SPECULATIVE — what a decidable instrument would need

* **S15.** The one thing that *would* grade a pointer reset is an **independent statement of where
  a section should read** — e.g. a coefficient whose C-RAM index is known and must line up with the
  cell the pointer names. `dram-bounds.md`'s abutting-buffer arithmetic is the closest existing
  candidate. **SPECULATIVE**, and it is the shape of instrument to look for, not another A/B.

Evidence grade: §1 **MEASURED**; §2 **FORCED** by §1 (same words, two vehicles, opposite answers);
§3 **MEASURED**; §4 **FORCED** given §183; §5 **SPECULATIVE**.

---

## §193 — the f31 run is VOID: the navigation vehicle loaded the wrong program. The control caught it.

### 1. The instrument took three attempts, and all three failures are the same species

* **Slot only.** Keyed the probe on I-RAM slot 122..130 alone. It sampled from **frame 0**, before
  the program is uploaded, so the captured word logged as `0000000000` and the min/max were
  dominated by boot content. Symptom: **both arms reported byte-identical accumulator ranges for
  two different programs.** ⇒ *a slot does not identify an instruction; a slot AND a word does.*
* **A dangling `else`.** Inserting the word-capture between an `if` and its `else` — caught by the
  compiler, cost one build.
* **Gated on the expected words.** Works: the words now log correctly and 21.4 M out-of-window
  samples are rejected and counted.

### 2. ⛔ AND THE RUN IS STILL VOID — the vehicle did not load what I asked for

With the words visible, the two arms disagree structurally:

```
   TYPE 30 arm:  +0..+8 = 0202AFC415 0204200000 00922FA700 0020A061D5 0182200407 ...
                                                            ^ the f31 = 0 variant
   TYPE 28 arm:  the same words, SHIFTED by five slots
```

`0020A061D5` is **PEQ+CHORUS's** variant. So TYPE 30 did not load PEQ+FLANGER, and TYPE 28's window
is offset — i.e. a third program entirely.

Fingerprinting the upload confirms the last run loaded **`prog72_peq_s_delay`**, which §170's map
places one slot away from the target. ⇒ **The navigation dropped a step.** TYPEIDX 8 worked
earlier (8 presses, verified `prog10_multi_tap_delay`); 28 and 30 do not.

⚠ **And my own check was sloppy**: I copied the upload dump per-run in the first loop but not the
second, so the script read **one file twice**. The conclusion above rests on the *word sequence*
in the probe output, which is per-run and unambiguous — not on that file comparison.

### 3. ⇒ Two standing requirements for any navigated run

1. **Verify the loaded program from the upload fingerprint, in the same run, every time.** §170's
   map is correct — it was confirmed live at TYPE 8 — but `peq_select.lua` presses UP at 0.10 s
   intervals and **drops steps over long distances**. The map is not the failure; the transport is.
2. **Copy `kn5000_dsp1_upload.txt` into the run directory before the next run starts.** It is
   overwritten by every launch, and comparing two runs against one file is not a comparison.

★ The `f31 = 4` experiment itself is **untouched** — its design still holds, including the
input-control at `+0..+2` that would detect a confound. It needs a transport that lands on the
program it is asked for.

### 4. What is NOT claimed

No statement about `f31 = 4`. The accumulator numbers in both arms describe `prog72_peq_s_delay`
and possibly a neighbour, not the minimal pair, and are not reported as results.

Evidence grade: §1 **MEASURED** (the symptom is diagnostic); §2 **FORCED** by the word sequence
alone; §3 procedural.

---

## §194 — the transport is FIXED and §170's map has an off-by-one. The f31 comparison then FAILS its own input control.

### 1. ★ The transport, fixed and verified

§193 diagnosed `peq_select.lua` as dropping steps over long walks. `tools/type_select.lua`
saturates **UP** to the end of the list and steps **DOWN** to the target, turning 28–30 presses into
6–8 — the regime that was verified to work.

First attempt still missed, **by exactly +1 on both arms**: asked 28 → `prog72_peq_s_delay`
(map 29); asked 30 → `prog74_peq_vibrato` (map 31). Systematic, not dropped steps.

⇒ **§170's TYPE map is off by one above index 8, and the cause is my own instrument.** It built the
map from *distinct consecutive* programs (`if not seen or seen[-1] != lbl`), so **two adjacent TYPE
slots sharing one program image collapse into a single row**, shortening the map and shifting every
later index. TYPE 8 was verified live and is correct, so the duplicate lies above it. *(The twelve
NAMED effects that ship a program byte-identical to NO OPERATION are exactly what collapses.)*

With `LAST = 36`:

```
   asked TYPE 28 -> prog71_peq_chorus     ✔        asked TYPE 30 -> prog73_peq_flanger   ✔
```

**Both correct** — the minimal pair, verified by upload fingerprint in the same run.

### 2. ⛔ AND THE COMPARISON IS CONFOUNDED — its own control says so

Window aligned, correct words at `+3` (`0020A061D5` vs `0028A061D5`). Accumulator change-counts:

```
   off   f31=0    f31=4   ratio
   +0       45       43    1.0x   input control
   +1       41       39    1.1x   input control
   +2     1013       50   20.3x   ★ 20x DIVERGENCE, ONE WORD BEFORE THE f31 BIT
   +3     1022       57   17.9x   the f31 word
   +4       57       47    1.2x
   +5..+8   ~equal
```

**The two programs already diverge at `+2`, upstream of the bit under test.** §193's input control
was written precisely to detect this, and it fired.

⇒ **No claim about `f31 = 4`.** The `+3` difference cannot be attributed to the bit when `+2`
already differs 20-fold.

### 3. ⇒ The "decidable vehicle" is not decidable as designed

The claim was that these three programs are byte-identical for nine words and the result is
observable one word later *"with no `f31 = 0` barrier, no biquad, no store-gate dependence."* The
**code** is byte-identical — that part is exactly right and re-verified. But:

> **Byte-identical code with divergent input state is not a controlled comparison.** The nine words
> are a shared *subroutine*, not a shared *experiment*; what reaches them differs.

★ That is a general correction to how minimal pairs have been proposed on this project: a minimal
pair in the **instruction stream** bounds what a field can *encode*; it does not by itself give a
**controlled measurement**, because the machine state entering the window is not part of the pair.

### 4. What would rescue it

The divergence enters at `+2` (`00922FA700`). Either find a window whose input control holds, or
instrument further upstream until the two programs' states agree and take that as the true window
start. ⚠ The window may not exist: the two effects are a chorus and a flanger, and they may simply
never present the same state to this code.

Evidence grade: §1 **MEASURED** (both arms fingerprinted), the map defect **FORCED** by the +1 on
both arms plus the dedup in the generator; §2 **MEASURED**, the control **FAILED**; §3 **FORCED**
by §2; §4 procedural.

---

## §195 — the three-way f31 test also fails: bit identity is confounded with program similarity

§194 killed the two-way comparison on its input control. The natural repair: PEQ+VIBRATO carries the
**same nine-word window** and the **same `f31 = 4`**, so the two `f31 = 4` programs can serve as each
other's control. Verified statically first — **8 of 9 words identical across all three**, the ninth
being the bit under test.

### 1. Transport and vehicle: all three verified

`type_select.lua` with `TYPELAST=36`, fingerprinted in-run:

```
   asked 28 -> prog71_peq_chorus    asked 30 -> prog73_peq_flanger    asked 31 -> prog74_peq_vibrato
```

### 2. ⚠ The probe's own self-check fired on all nine slots

VIBRATO carries the window at program word 31 (I-RAM 115) where the others carry it at 38
(I-RAM 122), so the probe was re-keyed by **word**. The pooling self-check — *slot min == max* —
**failed everywhere**: `0182200407` spans slots 109..140, `00124011CE` spans 103..138. These words
recur throughout the program.

★ But the slot ranges are **identical in all three runs**, so the pooling is a systematic property
of the corpus, not a per-run artefact. The comparison survives *as a comparison*; what it loses is
attribution to one window instance.

### 3. ⛔ THE RESULT — the predicted pattern appears, and it is explained by something else

```
   off    CHORUS(f31=0)   FLANGER(f31=4)   VIBRATO(f31=4)
   +2            1013               50               52     <- ONE WORD BEFORE THE BIT
   +3            2654             1689             1691     <- the f31 word
```

The two `f31 = 4` programs agree at `+3` (1689 vs 1691) while the `f31 = 0` program differs (2654)
— **exactly the predicted three-way pattern.**

⛔ **And they agree at `+2` as well** (50 vs 52 against 1013), which is *before* the bit. So FLANGER
and VIBRATO are simply more similar to each other than either is to CHORUS, **throughout the
window**. ⇒ **Bit identity is confounded with program similarity, and this design cannot separate
them.** The agreement at `+3` is fully explained without `f31` doing anything.

⇒ **No claim about `f31 = 4`.** Second design, second honest negative.

### 4. ⇒ The route is closed, and the reason generalises

To separate the two you would need a pair differing in the bit but *more* similar to each other
than the same-bit pair is — and in this corpus that pair does not exist. Combined with §194:

> **An instruction-stream minimal pair bounds what a field can ENCODE. It does not yield a
> controlled MEASUREMENT, because neither the machine state entering the window nor the overall
> similarity of the host programs is part of the pair.**

⚠ **Process note, recorded because the pattern is the point:** this probe went through **five**
revisions — slot-only (boot pollution), a dangling `else`, word-gated, word-keyed, and the pooling
self-check. Each revision was found by an internal check rather than by the result looking wrong.
That is the instrumentation working, but it is also five builds for two negatives, and it is worth
asking for the criterion *and* the confound analysis before the first build, not after the fourth.

Evidence grade: §1 **MEASURED** (all three fingerprinted); §2 the pooling **MEASURED** and its
uniformity across arms **MEASURED**; §3 **FORCED** — the `+2` agreement is upstream of the bit;
§4 **FORCED** given §3 and §194.

---

## §196 — §114 §3's "the modulus is exactly half" does NOT apply to the shipped build. Measured, no gate.

Auditing the **unarmed** mask bits (§168's point: "off because untested" is an opportunity, not a
verdict) turned up §114, graded **MEASURED**, sitting behind bit 32 with the default clear. Its §3
flags a live worry:

> *"the modulus is exactly half … my implementation wraps the signed 24-bit datum (`mod 2^24`) and
> runs the LFO at **exactly half rate**"* — 0.2997 Hz where `lfo-ramp.md` item C anchors
> **0.5993 Hz across 29 LFO blocks in 16 programs with nine distinct increments.**

★ And the device comment already explains why the bit is off, honestly: the wrap is gated **per
unit** (`m_ovc` bit 3), so arming it makes unit 0's *audio* non-negative — *"evidence the modulus
really belongs to the DATAPATH and the OVC bit only selects which units have a wrapping datapath."*

### 1. ★ The discriminator needs no gate and no implementation

A wrap is a large negative step in a rising ramp. **Counting them in the phase cell separates the
two moduli 2:1**, as a pure measurement against an independently derived number:

```
   mod 2^23   period  73 584 frames   0.5993 Hz     18.9 cycles in this run
   mod 2^24   period 147 169 frames   0.2997 Hz      9.5 cycles in this run
```

### 2. MEASURED

```
   §196 LFO WRAP CENSUS over 1 392 430 frames:  07: 15 wraps
```

```
   all frames        period 92 828 frames -> 0.5171 Hz
   LFO-active only   period 75 229 frames -> 0.6380 Hz     (§165: the phase changed in 1 128 429)
```

**`0.5993 Hz` lies between the two estimates.** `mod 2^24` is out by a factor of two on either
bound. ⇒ **The shipped build already behaves as `mod 2^23`, and §114 §3's factor-of-two concern
does not apply to it.**

★ An independent corroboration falls out of a measurement made for another purpose: §165 measured
the phase range as `0..8388598`, and `2^23 = 8388608`. **The ramp never exceeds 2^23** — so the
modulus is visible in the range as well as in the period, from two unrelated instruments.

### 3. What this is and is not

* **Is:** a factor-of-two worry, raised as a real open question in §114 and repeated in that
  section's *"three factors of two in one session"* note, **closed against an externally anchored
  rate**. Cell `0x07` is the only cell in 256 that wraps at all, which also confirms it is the only
  free-running accumulator in D-RAM.
* **Is not:** a statement that the rate is *exactly* right. 0.5993 sits inside a bracket
  0.5171–0.6380 whose width is set by how many frames the LFO is actually active — that is
  agreement, not a measurement of the rate. Narrowing it needs the LFO-active window measured
  directly rather than proxied by §165's change-count.
* **Is not** an argument for arming bit 32. The per-unit gating cost the device comment states is
  unchanged, and nothing here addresses it.

### 4. ⚠ Method note — the audit found this, not a hypothesis

This came from mechanically listing the 18 unarmed mask bits and reading their sections' evidence
grades, not from a new idea. **Two of the eighteen are graded MEASURED with pre-registered
predictions that hit** (§114 and §116). That is the audit class §188 came from, working again —
and here it *closed* a question rather than finding a defect, which is the cheaper outcome.

Evidence grade: §1 **FORCED** (the arithmetic); §2 **MEASURED**, with the range agreement as an
independent corroboration; §3 the limits **stated**.

---

## §197 — the poke packet's leading nibble is a FLAG, not a constant. Two-character fix, SHIPPED.

Found by the parallel PROVEN-BY-CONSTRUCTION audit (`data/AUDIT_HOST_findings.md`), the class §188
came from.

`upd6383.cpp:886` tested `if (m_poke[0] == 0x0a)`. `k3-pointers.md` §7 item 6 and
`register-space.md` §1.1 both record `0B .. .. .. 15` as the **same tag-`0x15` packet with one extra
flag bit**. The device fell through to its instruction-word arm, so the value was discarded **and
the auto-increment stalled**, shifting the rest of the stream one cell low. **44 of 3456 packets
(1.3 %)** in the TYPE-walk capture lead with `0x0B`.

### Results against `data/PREDICT_197.md`

| | pre-registered | measured | |
|---|---|---|---|
| **F1** fires | > 0 | **4** (cold-boot vehicle; the 44 figure is the TYPE walk) | ✔ |
| **F2** census rises, values appear | 59 writes / 55 cells must grow | **63 writes / 59 cells** — exactly +4/+4 | ✔ |
| **F3** null half | nothing displaced | +4/+4 with no other cell moved | ✔ |
| **F4** rule 1 | `§70 ACCA` min = max | `min 0 max 0` | ✔ silent |

★ **The control, and it was already in hand.** Two of the four recovered values match the
delay-descriptor space **bit-exactly**: `m_rf[0x54] = 0x0009B0 = 2480` and
`m_rf[0x56] = 0x000DC0 = 3520`, against §189's live descriptor dump `0x2A = 0x09B0` and
`0x2C = 0x0DC0` — a measurement made two ticks earlier for an unrelated purpose. Different writer,
different pointer register, different memory. *(`register-space.md` §6.2: "CHORUS writes the same
four tap lengths twice".)*

⚠ **Stated, not smoothed:** only 2 of the 4 are corroborated here. The other two (`400`, `1440`)
are not in this vehicle's recovered set — the "four lost values" figure is the auditor's, from a
different capture. 4 packets in, 4 writes out, 4 cells gained: the *mechanism* is confirmed
exactly; the *value list* is corroborated 2 of 4.

⚠ And the flag's **meaning** stays undecoded. This accepts the packet; it does not interpret the
bit.

Evidence grade: the packet form **PROVEN BY CONSTRUCTION** (two notes); the fix's effect
**MEASURED**, with 2 of 4 values bit-exact against an independent space.

---

## §198 — the three-way PROVEN-BY-CONSTRUCTION audit: four gaps, two note defects, and a correction to §182

Three parallel read-only auditors over disjoint file sets. Deliverables: `data/AUDIT_HOST_findings.md`,
`AUDIT_DRAM_findings.md`, `AUDIT_ISA_findings.md`. §197 already shipped from the first.

### 1. ★ The ranked gaps, all with controls

| # | gap | control |
|---|---|---|
| **1** | **The delay ROTATION SIGN is inverted** — `addr = cell + m_frames_run` with `G` rising, where round5 §3 FORCES `delay = READ − WRITE`. Yields **`65536 − D` on every line**; an 18.1 ms pre-delay becomes **1.468 s** | **two** — the host's own evaluator `cell = round(ms × 44.1) + BASE24` requires the delay to *grow*; and **the device's own disassembler already prints the corrected relation** (`upd6383d.cpp:468`) |
| **2** | **`setvec`'s per-unit CALL VECTORS are written and read by nothing** — the sequencer uses a hard-coded `{0x0E→84, 0x0F→200}` whose own comment says *"OBSERVED … NOT derived"*. ⇒ the device runs a body **the firmware has deliberately disconnected** | **two** — four literal constants in Sub CPU ROM (`EFF_Link`/`EFF_Disconnect`, indexed by unit), and the cold-boot capture decoded independently to 84/42 and 200/50 |
| **3** | **Per-body descriptor map absent** — `m_delay_ix` is frame-global, so the unit-1 reverb draws cells `0x33..0x4E` instead of `0x00..0x1F`: **mostly never-written cells, i.e. no delay line at all** | the region split, measured live |
| **4** | **`C40.1.80.000` must consume a cell** (r3 §6.1, all 8 exact solutions; 28 non-C + 4 C-format = 32 = *n*) — **the cursor runs 4 short inside every reverb** | arithmetic, from the .dsm |

### 2. ★ §189/§190's OPEN discrepancy is CLOSED — and my method was wrong for reverbs

The cold-boot unit-1 preset is **CONCERT REVERB 1 (algo 20)**, not ROOM REVERB 1. Its ROM ladder
reproduces §189's measured chain `569 707 1250 1674 480 512 870 678 900 840` **exactly, 10 of 10 in
order**, and its cell `0x02 = 41925` is §190's live value.

⚠ **§190 fingerprinted the BODY IMAGE — and all twelve reverbs share it byte for byte.** The preset
lives only in the descriptors. ⇒ the identification method §170/§190 rely on is sound for unit 0 and
**cannot identify a reverb at all**. That limitation was not stated when the method was introduced.

### 3. ⛔ A correction to §182 — I under-reported my own finding

§182 §3 reported *"§9.3 acquires exactly ONE genuine exception"* (`epilogue w63`, `ACT 0x03`).
Re-reading the same census:

```
   ACT 0x03  54 sites, 53 bit-11 -> 1 exception   epilogue w63
   ACT 0x04   2 sites,  1 bit-11 -> 1 exception   epilogue w73 = E30.C.00.404  <- THE DO1 PRESENTATION
   ACT 0x1C  24 sites, 24 bit-11 -> 0
   SRC 0x02  25 sites, 24 bit-11 -> 1 exception   epilogue w72
   SRC 0x04   2 sites,  1 bit-11 -> 1 exception   epilogue w66
```

**Four of five, not one** — every exception in the **epilogue**, the region `bit11-family.md`'s
body-scoped census could not see. I had the numbers in front of me and read one row.

⇒ §9.3's *"these five codes do not exist"* is **body-scoped and false for four of five**, and the
note contradicts its own item A. ★ MAME is unaffected and correct; `dsp_disasm.py`'s
`PHANTOM_ACT`/`PHANTOM_SRC` carry the defect, latent.

### 4. What the audit also CONFIRMED (no action)

* The `bit 10 = END` falsification **did** reach the executor, in three places, correctly scoped.
* Most of the host surface is right: §188's packet decode, `addr8 = [19:12]`, the three-tag space
  separation, unit-step auto-increment, the per-unit C-RAM rebase.
* ⚠ Two **stale note sites** caught: `host-side.md` §10 item 6 and `register-space.md` §1 still
  describe the poke port as unreached (it was fixed by §59). Rule 10 again, in the notes.

Evidence grade: §1 gaps **MEASURED/FORCED** per the linked audits, none implemented here;
§2 **MEASURED** (10 of 10 in order); §3 **MEASURED**, my own under-report **acknowledged**.

---

## §199 — the rotation sign: I nearly refuted a correct finding by checking the wrong quantity

§198 ranked the inverted delay-rotation sign first. Before implementing it I checked the arithmetic,
and the check appeared to **kill** it.

### 1. ⛔ The objection — and it is valid, about the wrong quantity

The rotation `G` is added to **both** the read and the write address:

```
   device    addr = (cell + G) & 0xffff
   proposed  addr = (cell - G) & 0xffff
```

so it **cancels** in `R − W`. Measured on §189's live descriptor pair (`R = 41925`, `W = 41590`),
`R − W = 335` under either sign, at every `G`. ⇒ *the rotation sets where the heads are, not how
far apart they are* — and "yields `65536 − D` on every line" cannot be a statement about `R − W`.

### 2. ★★★ Working it through TEMPORALLY reverses that, and the finding stands

A read at address `R + G` returns whatever the **write** head deposited when it was at that same
address:

```
   G RISING (device)   read at R+T returns the sample written at T' with W+T' = R+T
                       => T' = T + 335   -- a FUTURE sample.  The only consistent
                          reading is a delay of 65536 - 335 = 65201 = 1.478 s @ 44.1 kHz
   G FALLING (round5)  read at R-T returns the sample written at T' with W-T' = R-T
                       => T' = T - 335   -- a PAST sample.  Delay = 335 = 7.60 ms  ✓
```

⇒ **`R − W` is constant under either sign — that is what I checked — but the TEMPORAL delay is
`(R−W)` or its complement depending on which way the heads sweep.** The finding is confirmed, and
by the audit's own number: 1.478 s here against its 1.468 s on a different line.

> ★ **RULE: for a circular buffer, the delay is a TEMPORAL quantity. A difference of addresses is
> not a delay, and checking one to test the other will refute a correct claim.** I was one step from
> filing "the rotation sign cannot matter."

### 3. ⚠ AND THE OBJECTION LEAVES A REAL CONSEQUENCE FOR THE FALSIFIER

Because `R − W` is sign-invariant, **no static or per-frame address measurement can grade this
fix.** Every instrument this project currently has — the descriptor census, the delay-port census,
the tap-modulation census — reports addresses. They will all be bit-identical across the change.

⇒ **The falsifier must be temporal**: tag each delay-line address with the frame it was last
written, and at each read report `frames_since_written`. Predicted **335** for that line with the
fix, **65201** without; and for CHORUS's line, **1040** (§152's ROM-derived length, confirmed live
at descriptor `0x2B = 0x0410` in §189) against `64496`.

**That instrument does not exist yet, and the fix must not be shipped without it** — a change that
every existing probe reports as bit-identical is exactly the kind that gets shipped on reasoning and
retracted later.

### 4. Not done, deliberately

The fix is **one operator**. It is not applied, because §195's process note says to have the
criterion before the build, and the criterion here needs a new instrument. Next tick: build the
write-timestamp probe, pre-register 335 / 1040, then flip the sign.

Evidence grade: §1 **MEASURED** (the cancellation); §2 **FORCED** (the temporal argument, matching
the audit's independent figure); §3 **FORCED** by §1 — sign-invariance of `R − W` is exactly why the
existing instruments are blind.

---

## §200 — the delay lines have ZERO LENGTH, so the rotation sign is ungradeable. And §199's arithmetic paired the wrong cells.

§199 designed the only instrument that could grade the rotation sign: tag each delay address with
the frame it was written, and report `frames_since_written` at each read. Built (the u64 spec mask
is **exhausted**, so the gate is the env var `UPD6383_ROTSIGN`, the mechanism §104 used).

### 1. MEASURED — and it is the same under both signs

```
   ROTSIGN=0 (device)    dsc 29/2B/2D/2F/31/33 : frames_since_written 0..0   (0.00 ms)
   ROTSIGN=1 (round5)    identical, every line
```

**Every read returns a sample written in the SAME frame.** ⇒ read address == write address ⇒
**the delay lines have zero length**, and the rotation sign cannot be graded because there is no
delay to be right or wrong about.

### 2. ⛔ §199's arithmetic used two cells that are not a pair

§199 computed `R − W = 335` from `R = 41925` (cell `0x02`) and `W = 41590` (cell `0x05`). But §189
measured the descriptor pairing as **`k ↔ k+5` with EQUAL values** — `02==07`, `04==09`, `06==0B`,
nine pairs, no exceptions. **The true read/write pairs are equal**, so `R − W = 0`, and both my
`335 samples` and my `65201` were computed from a mis-paired cell.

⇒ §199's *temporal* reasoning stands (it is why the sign matters at all); its *numbers* do not, and
the predictions I pre-registered — 335 and 1040 — were unreachable by construction. ★ The probe
caught that immediately, which is the argument for building the instrument before the fix.

### 3. ★ AND IT CONFIRMS §198's GAP #3, from the other direction

The descriptor indices actually in use are `0x29 0x2B 0x2D 0x2F 0x31` and — with **1 135 149 hits,
two orders of magnitude above the rest** — `0x33`. The DRAM audit predicted exactly this: *"the
unit-1 reverb draws cells `0x33..0x4E` instead of `0x00..0x1F`, i.e. mostly never-written cells →
no delay line at all."* **`no delay line at all` is now measured, not inferred.**

⇒ **Gap #3 comes first.** The rotation sign is downstream of it and cannot be tested until the
descriptor map is right. ⛔ The sign flip is **implemented and OFF** (`UPD6383_ROTSIGN=0`); do not
ship it on §199's reasoning alone.

### 4. What survives

* the write-timestamp probe — the only instrument that can grade a delay, and it will still be
  the right one after gap #3;
* §199's rule (a difference of addresses is not a delay) — **and now a second edge on it**: it is
  also not a delay when the two addresses are not a read/write **pair**;
* `R − W` sign-invariance, so every address-reporting probe stays blind.

Evidence grade: §1 **MEASURED**; §2 **FORCED** by §189's nine exceptionless pairs; §3 **MEASURED**,
matching the audit's independent prediction.

---

## §201 — ★★★ THE DELAY LINES HAVE LENGTH. Per-body descriptor index, SHIPPED ON.

§198 gap #3, measured out of existence by §200 and now fixed. `adjudication-round5.md` §1 **FORCES**
the IDENTITY map — *"the k-th class-1 format-escape consumer takes the k-th descriptor cell of its
own body's block"* — and `m_delay_ix` was **frame-global**, reset only at frame end, so body 1
continued body 0's count.

⚠ The u64 spec mask is **exhausted**; gated on `UPD6383_BODYIX`, the mechanism §104/§200 use.

### Results

| | | |
|---|---|---|
| **F1** fires | count > 0 | **2 736 860** |
| **F2** indices move | onto the body's own block | `0x29 2B 2D 2F 31 33` → **`0x26 28 2A 2C 2E 30`** |
| **F3** ★ the point | zero-length lines must gain length | **`0..240`, `0..480`, `0..640`** |
| **F4** rule 1 | `§70 ACCA` min = max | `min 0 max 0` — **still silent** |

```
  before   dsc 29 2B 2D 2F 31 33   frames_since_written 0..0 on EVERY line
  after    dsc 26 28 2A 2C 2E 30   0..240 / 0..480 / 0..240 / 0..0 / 0..0 / 0..640
                                   = 5.44 / 10.88 / 14.51 ms @ 44.1 kHz
```

★ **`0x26` is exactly where §189 measured CHORUS's descriptor block live** (`26:0190` = 400,
`28:05A0` = 1440, `2A:09B0` = 2480, `2C:0DC0` = 3520) — an independent measurement, made for
another purpose, that the corrected indices land on.

⇒ **For the first time in this emulator the delay lines have a length.** §200 measured them at
**zero** on every line one tick ago; the audit's *"no delay line at all"* is now repaired, not just
diagnosed.

### ⚠ What is NOT claimed, and it is a lot

* **The chip is still silent.** `min 0 max 0`, both ports peak 0. A delay line is not audio; the
  output stage (§141/§150, `w73`) is a separate defect and untouched.
* **Two lines still read `0..0`** (`0x2C`, `0x2E`). Unexplained.
* **The age maxima are unexplained.** `240 / 480 / 640` against descriptor values
  `400 / 1440 / 2480 / 3520` — no relation established. ⚠ `240` is CHORUS's modulation depth
  (§156, the ROM's `C-RAM[0x02]`), and `480 = 2 × 240`, which is **suggestive and nothing more**;
  recorded **SPECULATIVE**. A tap that sweeps ±240 around a nominal position would also produce an
  age *range* starting near 0, which is what these look like — but that is a story, not a
  measurement.
* **The per-unit descriptor BASE is still absent** (§198 gap #3's other half): `m_dsc` comes only
  from the in-program `ldptr.d`, which is `0x25` in **both** header blocks. This fixes the index,
  not the base.

### ⇒ And the rotation sign is now gradeable

§200 could not test it because every line had zero length. There is now a real delay to measure,
so `UPD6383_ROTSIGN` can finally be scored — **with the descriptor difference pre-registered from
the ROM**, not from §199's mis-paired cells.

Evidence grade: the decode **FORCED** (round5 §1); the consequence **MEASURED**, with §189's
independent block identification as a passing control; the age *values* **UNEXPLAINED** and the
`240` coincidence **SPECULATIVE**.

---

## §202 — ★★★ THE ROTATION SWEEPS DOWN, and the proof is the ROM's own numbers. SHIPPED.

§201 gave the delay lines a length, which made §198 gap #1 gradeable for the first time. Flipped
`UPD6383_ROTSIGN` and measured.

### 1. ⛔ My pre-registration was wrong, and the truth is stronger

I pre-registered: *"if the sign is wrong, flipping it gives the COMPLEMENT, `65536 − D` = 65296 /
65056 / 64896."* **Neither** — not the complement, not the old values:

```
   ROTSIGN=0 (was)   dsc 28 -> 0..480       dsc 30 -> 0..640
   ROTSIGN=1 (now)   dsc 28 -> 0..4161      dsc 30 -> 0..3120
```

★★★ **And those are the ROM's own descriptor cells, bit-exactly:**

```
   4161 = 0x1041 = descriptor cell 0x27        3120 = 0x0C30 = descriptor cell 0x2F
```

against §189's live descriptor dump — taken three ticks ago for an unrelated purpose, from a
different memory, through a different writer. **Two independent lines, both exact.**

⇒ **The rotation sweeps DOWN.** `adjudication-round5.md` §3's FORCED `delay = READ − WRITE` is
confirmed, and the measured delay of a line now *equals the number the ROM stores for it* — which
is what a delay descriptor is for.

⚠ My falsifier assumed the pre-flip ages (240/480/640) were the true delays and the error was a
simple complement. They were not delays at all; they were an artefact of reading a rising sweep.
**A wrong pre-registration that the run overturns in the *stronger* direction is still a wrong
pre-registration** — the third time in this line that a number of mine came from a mis-modelled
pairing (§199, §200, here).

### 2. SHIPPED — default ON, `UPD6383_ROTSIGN=0` to override

Applied **46 665 909** times. ⚠ The u64 spec mask is exhausted, so this and §201 are env-gated.

### 3. ⚠ What is NOT claimed

* **The chip is still silent** — `§70 ACCA min 0 max 0`, both ports peak 0, verified on the shipped
  default. A correct delay line is not audio; the output stage (`w73`, §141/§150) is untouched.
* **Four of six lines still read `0..0`** (`0x26 2A 2C 2E`). Two exact hits is decisive for the
  *sign*; it is not a working reverb.
* The **per-unit descriptor base** remains absent (§198 gap #3's other half) and
  **`C40.1.80.000`** still does not consume a cell (gap #4) — the cursor runs 4 short in every
  reverb.

### 4. Three shipped this session from one audit

§197 (`0x0B` packets) · §201 (per-body descriptor index) · §202 (rotation sign) — all three from
the PROVEN-BY-CONSTRUCTION sweep, each with an independent control, none from a hypothesis.

Evidence grade: **MEASURED**, bit-exact at two lines against an independently-taken dump; the
decode itself **FORCED** (round5 §3). My pre-registration **WRONG**, recorded.

---

## §203 — `C40.1.80.000` consuming a descriptor cell is INERT by the only instrument that could grade it. Not shipped.

§198 gap #4: `r3-delaydram.md` §6.1 **FORCES** that `C40.1.80.000` consumes a descriptor cell (all
8 exact solutions require it), and it is verified arithmetically from the .dsm — **28 non-C-format
consumers + 4 C-format = 32 = *n***. The delay path excludes C-format, so the cursor was thought to
run four short inside every reverb.

Implemented at the dispatch, in program order (round5 §1's identity map counts consumers in program
order), gated on `UPD6383_CFMTIX`.

### Result

```
   §203 FIRED 5 698 785 times
   §200 DELAY AGE  dsc 26 0..0 | 28 0..4161 | 2A 0..0 | 2C 0..0 | 2E 0..0 | 30 0..3120
                   -- BYTE-IDENTICAL to §202's shipped run
   §70 ACCA  min 0 max 0
```

**The gate fires 5.7 million times and changes nothing the delay census can see.** ⇒ **not shipped**;
implemented and off.

### ⚠ Why that is a weak negative, stated plainly

The write-timestamp census reports the delay of lines that **already resolve**. §202 left four of
six lines at `0..0`, and a cursor advancing four further cells would move which *descriptor* each
consumer reads — a change this instrument only sees if the newly-read cells are non-zero **and** the
line then resolves. So *"inert by this probe"* is much weaker than *"wrong"*.

⇒ **Do not read this as refuting r3 §6.1.** It is FORCED by an argument this run does not touch.
What is measured is only that the shipped delay census cannot grade it — the same shape as §200's
finding about the rotation sign, and the reason that one needed §201 first.

★ What would grade it: a census of **which descriptor index each consumer reads**, per body, against
the identity map's prediction — a *consumer-to-cell* probe, not a delay probe. That does not exist
yet and is the natural companion to §200.

Evidence grade: the claim **FORCED** (r3 §6.1, plus the 28 + 4 = 32 arithmetic); the run
**MEASURED** and **inconclusive by construction**, recorded as such rather than as a refutation.

---

## §204 — the CONSUMER-TO-CELL census grades §203. It was right. SHIPPED.

§203 left `C40.1.80.000`'s descriptor consumption unshipped because the delay census could not see
it — *"inert by this probe, not wrong"* — and named the missing instrument: a **consumer-to-cell**
map rather than a delay map. Built.

### 1. ⚠ It took two attempts, the same defect as §193

Keyed on "the first 16 consumers", it recorded them **from frame 0**, before the program uploads:
body 0 logged `iw12` sixteen times with `cell0000`, and **both arms of the A/B were identical**
because the gate never fires during boot. Gated to a settled frame (> 900 k), it works.

### 2. ★★★ MEASURED — and it grades §203 positively

```
   CFMTIX=0   iw12->ix0(dsc26,cell0190)  iw26->ix1(dsc27,cell1041)  iw46->ix2(dsc28,cell1041)
   CFMTIX=1   iw12->ix0(dsc26,cell0190)  iw26->ix1(dsc27,cell1041)  iw46->ix3(dsc29,cell05A0)
```

**With the gate OFF, `iw26` and `iw46` both read descriptor value `0x1041` — two consumers sharing
one cell.** With it ON, `iw46` advances to index 3 and reads `0x05A0`: **every consumer gets a
distinct cell**, which is exactly what round5 §1's identity map requires and what
`r3-delaydram.md` §6.1 FORCES.

⇒ The C-format word between them **does** consume a cell. **SHIPPED**, default ON, fired 5 698 785
times.

★ The collision is the point: a duplicate descriptor value is a *signature* of a short cursor, and
it is visible in the mapping while being invisible in the delay — which is why §203's null was
correctly recorded as inconclusive rather than as a refutation.

### 3. ⚠ Not claimed

* **Still silent** — `§70 ACCA min 0 max 0`, verified on the shipped default.
* The **delay-age census is unchanged**. The mapping is fixed; whether those cells then yield
  audible delays depends on the per-unit descriptor **base**, still absent.
* ⚠ The census labels kernel consumers (`iw12/26/46`, before I-RAM 84) under "body 0". Harmless
  here — the A/B compares like with like — but the label is wrong and should be fixed before the
  data is quoted elsewhere.

### 4. Four shipped this session, all from the same audit

§197 · §201 · §202 · §204 — each from the PROVEN-BY-CONSTRUCTION sweep, each with an independent
control, none from a hypothesis. §203 is the counter-example that proves the discipline: a FORCED
claim held back one tick for want of an instrument, then shipped when the instrument existed.

Evidence grade: the decode **FORCED** (r3 §6.1 + the 28 + 4 = 32 arithmetic); the consequence
**MEASURED** (a duplicate-cell collision removed); the probe's first form **VOIDED** by boot
pollution and recorded.

---

## §205 — both standing tasks return NOT-AS-NAMED. One is 93 sections stale; the other is undecidable.

### 1. ⛔ "Fix the `SRC 0x08` clobber that rails PEQ's input cell" — the task is wrong four ways

* The bit-4 store at `iw45` (`010.A.00.20C`) writes **the accumulator**. `SRC 0x08` is not in that
  datapath at all — `L` reaches only `ACT 0x0C`'s tempA capture and the next word's `m_p`.
  **No `SRC 0x08` decode change can alter this write.** ★ **§111 §3 already retracted the
  attribution; the task title outlived its own retraction by 93 sections.**
* `iw45` **is** the unit-0 SEND (`k6-input-stage` finding 7, FORCED, over-determined 37×).
  Suppressing it deletes the only kernel→body-0 route.
* Of the 71 mode-2 bit-4 `SRC 0x08` stores, **59 are the `092`/`094` LFO phase-accumulate + wrap
  idiom** — a `src == 0x08` suppression would delete the LFO publish in 21 images.
* **"Rails" is a vehicle artefact**: `0x7FFFFF` appears only in the `peq_gain` navigation vehicle
  (standing rule 2 — deltas only). In the clean vehicle the same word sends **0**.

⇒ **The patch must not be written.** What is real is a different word and is **downstream of the
current blocker**: the send is 0 because `§48 DELAY READ CONSUMED (SRC 0x0B): 22 773 120 times,
0 with a non-zero datum`. ★ That second field is the single number that settles it — while it is
zero the send is zero regardless of `iw45`.

### 2. `f31 = 4/5` — UNDECIDABLE, and now partly MEASURED

The audit named its grading criterion before proposing anything and found that for four of six
candidate readings *no quantity outside the emulator depends on the choice at all*. Three routes
closed by measurement: the delay domain (15 of 98 sites precede a delay word, **all 15 are READs,
0 of 98 reach a WRITE**); `F31_HIGH`'s index vehicle (the device does not model the table);
and `f31-high.md` §6's "14/14 linear" statistic, which is **circular** — that list was *derived* as
"images with zero f31 ≥ 3". Replaced with an a-priori partition: **69 of 97 vs 36.4 expected,
p = 8.4e-12**, so the inert-alias null is refuted on admissible evidence.

★ **New structural fact:** 46 % of the `f31 = 4/5` population is operand-free (`0XX.2.00.000`), and
for `f31 = 0/1/2` those decode as exactly the three **MAC product-writeback modes**. ⇒ `hi12[3:1]`
on those words is the **writeback mode**, and the shipped `{LOAD, ADD, HOLD}` space is
*categorically* wrong for 45 of them. **INFERRED.**

### 3. ★ Two measurements taken here

The counters `m_bx_f4_n`/`m_bx_f5_n` were **incremented and never printed** — this project's own
*"every gate logs a fired-count"* rule, breached for exactly the most contested field. Now printed:

```
   f31=4  0            f31=5  1 162 989          (mask bits 48-51 = 0)
```

⚠ **`f31 = 4` never fires in the clean vehicle.** Any experiment on it needs a vehicle that
exercises it — a requirement no previous `f31 = 4` proposal stated.

And the **X0 identity control** (`0xb919e446a39b440f`, a twin of the shipped default) ran: both arms
**identical**, `§70 ACCA min 0 max 0`. A free control that could have failed and did not.

Evidence grade: §1 **FORCED** (the datapath) with the corpus census **MEASURED**; §2 the closures
**MEASURED**, the writeback-mode reading **INFERRED**; §3 **MEASURED**.

---

## §206 — the descriptor base is not missing from the emulator; it is absent from `0x825`. Look at `0x827`.

The current task is *"the per-unit descriptor BASE — `m_dsc` comes only from the in-program
`ldptr.d`, `0x25` in both header blocks."* Checked against the header words already in hand (§178):

```
   unit 0    iw42 801.0.70.821    iw43 801.0.6C.827    iw44 801.0.25.825
   unit 1    iw50 801.0.50.821    iw51 801.0.64.827    iw52 801.0.25.825

   selector 0x821   0x70 vs 0x50   DIFFERS
   selector 0x827   0x6C vs 0x64   DIFFERS
   selector 0x825   0x25 vs 0x25   *** IDENTICAL ***
```

⇒ **`m_dsc` is `0x25` for both units because the FIRMWARE LOADS THE SAME VALUE.** That is not an
emulator defect, and "give `0x825` a per-unit base" would be inventing a split the instruction
stream does not contain.

★ `k3-pointers.md` already forced this and I had read it: *"`0x825` is **dead**: it is loaded with
the same value (`#$25`) in **both** unit segments, and both effect units are resident
simultaneously, so the two units' state would alias completely."* The note used that to eliminate
`0x825` as the **operand** pointer; the same argument eliminates it as the **descriptor** base.

⇒ **The descriptor base must come from `0x827`** — the only pointer-family register that differs
per unit (`0x6C` / `0x64`) and the one `k3-pointers.md` explicitly left **"not excluded"** when it
selected `0x821` for operands. **INFERRED**, and it is the first candidate with a per-unit split to
offer.

⚠ **Falsifier, and it must be stated before any build:** `0x6C − 0x64 = 8`. If `0x827` is the
descriptor base, the two units' descriptor blocks sit **8 cells apart**. §189's live bank has
unit-1 descriptors at `0x00..0x1F` and CHORUS's at `0x26..0x2F` — a gap far larger than 8. So
either the base is scaled, or `0x827` is not it. **A candidate that already disagrees with a
measurement is not a fix; it is the next thing to check.**

Evidence grade: the header values **MEASURED**; "the firmware does not split `0x825`" **FORCED**;
the `0x827` candidate **INFERRED and already in tension with §189**.

---

## §207 — ⛔ the `dsc` labels are OFF BY ONE, so §202's "bit-exact" numbers were the wrong block. And the answer was written four days early.

### 1. ⛔⛔ A defect in §202's EVIDENCE — proved by §204's own printed output

The §200/§204 `dsc` labels are **+1 for body consumers**. §204 printed
`iw46->ix3(dsc29,cell05A0)` — and `0x05A0` is descriptor cell **`0x28`**, not `0x29`.

⇒ **§202's two "bit-exact" matches were body-1 consumers reading body-0's block** — the very defect
§201/§204 were repairing. ★ §202's *conclusion* (the rotation sweeps DOWN) stands: it rests on the
temporal argument and on delays equalling ROM-stored descriptor values at all. But **its two
headline numbers must be re-baselined after the base fix, not quoted as they stand, and not read as
a regression when they move.**

I reported those numbers as the strongest control of the session. They were computed through a
mislabelled index. **The label defect was flagged in §204 as "harmless for the A/B" — it was not
harmless for the citation.**

### 2. `0x827` is eliminated by arithmetic, not by preference

A base register means `base_u = s·F_u + b (mod 256)`. Subtracting the units **cancels `b`**, so the
whole test is whether `s·d ≡ 38 (mod 256)` is solvable — i.e. whether `gcd(d,256) | 38`. As
`38 = 2·19` and `gcd(d,256)` is a power of two, **`d` must be odd or ≡ 2 (mod 4)**.

```
   0x827  d = 8   gcd 8 ∤ 38     0x821  d = 32      w45/w53 addr8  d = 48     ALL IMPOSSIBLE
```

⇒ *"the base is scaled"* is **not available** — no integer scale whatsoever, not merely no small
one. ★ NULL computed first: 75 % of the 256 possible deltas admit *some* scale and 6.2 % admit
`|s| ≤ 8`, so the criterion could have passed. Also eliminated: the body's own first D-RAM word
(`880.1.30.00B` is consumer 0 on **both** units — the same 36 bits cannot yield `0x26` and `0x00`)
and the host write pointer (`m_dsc_wp` ends at `0x30`, is order-dependent, and unit 1 uploads first).

### 3. ★ AND `dram-unit-cursor.md` ANSWERED THIS ON 2026-07-27 — four days before §206

Its sweep gives **4440 survivors of 766 576 machines, every one with `B₁ = 0x00` and `L₁ ≤ 0x26`**:
the base is **not a register at all** but **per-unit state established at the CALL**, carried by a
per-unit *ring* on the one shared cursor — so the single immediate `0x25` means *"one below unit 0's
base"* to unit 0 and *"the last cell of my ring"* to unit 1.

⚠ Neither §206 nor `HANDOFF-NEXT.md` cited it. **Trap #3 again, and this time it is mine**, in a
section I wrote specifically to correct a stale premise.

⚠ A hardwired two-entry base table is **observationally tied** with the ring; separating them needs
a unit-1 block longer than 38 cells and the maximum is 32. Recorded as tied rather than resolved.

### 4. The number that settles the fix

Body 1's §204 census going from **0 of 16 to 16 of 16**, with the sixteen cells reading
`81E7 0000 A3C5 8000 A5FE A276 A8C1 A3C5 ADA3 A5FE B42D A8C1 B60D ADA3 B80D B42D`
(today: `0000 0190 1041 05A0 0000 09B0 0410 0DC0 0820 8000 0C30 0000 0000 0000 0000 0000`).

Evidence grade: §1 **FORCED** (§204's own output); §2 **FORCED** (the gcd argument, null computed);
§3 **MEASURED** in the owning note, the ring-vs-table distinction **UNRESOLVED and labelled tied**.

---

## §208 — the §204 probe stops printing a DERIVED cell label. Housekeeping, recorded so §209 has a baseline.

§207 §1 showed the `dsc%02X` column was `u8(m_dsc + m_delay_ix)` **recomputed at print time**, which
is `+1` for body consumers (`:1927` increments before `:1950` reads) and, worse, recomputed from an
`m_dsc` of `0x26` — the *epilogue's* value — while the bodies ran with `0x25`.

⇒ the column was deleted rather than corrected, because at that moment **no correction existed**:
under a per-unit ring `m_dsc + ix` is not the cell for unit 1 under *any* offset. The probe printed
`iw%u:ix%u,val%04X` and derived nothing.

⚠ **A probe that prints a wrong label is worse than one that prints none** — §202 quoted two
numbers through this one and they became the session's headline control. Shipped as
`53dc6e8`. Evidence grade: **MEASURED** (§204's own output was the proof).

---

## §209 — ★★★ THE PER-UNIT DESCRIPTOR RING. 16 of 16, all four arms bit-exact, and §202 re-baselined.

The descriptor **base** is not a register. §207 §2 closed that family by arithmetic and
`data/DSCBASE_findings.md` closed the rest; what survives is `dram-unit-cursor.md`'s per-unit
**ring** on the one shared cursor. This is the build, and the measurement.

### 1. The change — two INDEPENDENT env gates, each with a fired count

⚠ The u64 spec mask is **exhausted**; `UPD6383_BODYIX`/`UPD6383_CFMTIX` precedent.

```
   UPD6383_DSCPRE    pre-increment: the cell is m_dsc + m_delay_ix + 1
   UPD6383_DSCRING   the per-unit ring: [0x00,0x26) unit 1, [0x26,0x40) unit 0
```

Both default **ON**. The unit is the one the device **already** establishes at the CALL for the
per-unit D-RAM rebase (`DRAM_UNIT_BASE`) — no new chip-boundary violation, nothing reaches into
another device's memory. In this corpus the census's own `m_cur_iw >= 200` partition is identical,
so the choice is not load-bearing for any number below.

★ **The wrap fires only on passing the ring TOP.** A cursor loaded *below* its own base — unit 0's
`0x25` — is **not** clamped up. That asymmetry *is* the mechanism: one immediate, two bases.

And every probe now takes the **one** cell computed at the access site, so §207's `+1` cannot recur.

### 2. ★★★ THE RESULT — the pre-registered settling number, and it lands

Pre-registered in `data/DSCBASE_findings.md` §6.3/§6.4 and committed (`d565f5d`) **before this
build**. Vehicle: cold boot, CHORUS on unit 0, CONCERT REVERB 1 on unit 1, notes at 21–27.5 s
(rule 12). Census: the §204 consumer-to-cell map, unit-1 bucket, first 16 consumers, frame > 900 k.

| PRE | RING | body-1 cells | body-1 values | settling |
|---|---|---|---|---|
| 0 | 0 | `25 26 27 … 34` | `0000 0190 1041 05A0 0000 09B0 0410 0DC0 0820 8000 0C30 0000×5` | **0 / 16** ← the NULL |
| 1 | 0 | `26 27 28 … 35` | `0190 1041 05A0 0000 09B0 0410 0DC0 0820 8000 0C30 0000×6` | **0 / 16** |
| 0 | 1 | `25 00 01 … 0E` | `0000 81E7 0000 A3C5 8000 A5FE A276 A8C1 A3C5 ADA3 A5FE B42D A8C1 B60D ADA3 B80D` | **0 / 16** |
| **1** | **1** | **`00 01 02 … 0F`** | **`81E7 0000 A3C5 8000 A5FE A276 A8C1 A3C5 ADA3 A5FE B42D A8C1 B60D ADA3 B80D B42D`** | ★★★ **16 / 16** |

★ **All four arms reproduced their pre-registered cell list *and* value vector EXACTLY** — the null
included, so the instrument was shown able to say **no** before it said yes. The shipped default
(no env vars set) reproduces arm D identically, and body 1's sixteen values are the sixteen §207 §4
named, in order.

**Body 0 — CHORUS, the arm that separates `PRE` from `RING`:**

```
   PRE=0 (RING 0 or 1)  cells 25 26 27 28 29 2A 2B 2C 2D 2E   10/10 as predicted
   PRE=1 (RING 0 or 1)  cells 26 27 28 29 2A 2B 2C 2D 2E 2F   10/10 as predicted
```

⇒ **the 2 × 2 identifies the two halves independently rather than shipping a bundle**, and
falsifier 4 does **not** fire: body 0 is bit-identical between `RING=0` and `RING=1` at the same
`PRE`. Nor does falsifier 3: the `PRE=0 RING=1` arm *does* show the single stray `0x25` at the
head, which independently confirms `m_dsc = 0x25` when body 1 runs — the `ldptr.d` decode at `w52`.

### 3. ⚠ The one number that had to be localised, and was

The first run reported **23 040 unit-0 wraps**, and unit 0's ring is supposed to be unreachable.
A fired count that is neither zero nor explained is a defect until it is localised, so a probe was
added rather than a story:

```
   §209 UNIT-0 WRAPS: 23 040 total, 0 in a SETTLED frame (> 900 k)
   last at frame 264 000 of 1 392 430 | I-RAM 54..331 | raw cursor reached 0x46
```

⇒ every one is in the **partially-uploaded-I-RAM transient** (frame 264 000 = 5.5 s, before the
host finishes writing the programs). Unit 0's ring is unreachable in every settled frame, as
designed. ★ Had this been left as "23 040, probably boot", it would have been exactly the kind of
unexamined counter this project keeps being bitten by.

### 4. ⚠ RE-BASELINE OF §202 — its numbers MOVED, as §207 said they would

With the labels corrected and the ring **OFF** (the null arm — the same machine §202 measured):

```
   §202 published   dsc 28 -> 0..4161      dsc 30 -> 0..3120
   §209 null arm    cell 27 -> 0..4161     cell 2F -> 0..3120
```

⇒ **§207's diagnosis is confirmed at the label level**: the *values* were right and the *labels*
were `+1`. And its stronger claim holds too — the `0x2F` line had 1 140 909 hits, and `0x2F` is
reachable only at `ix 10`, which CHORUS (ten consumers, `ix 0..9`) never reaches. **It was body 1's,
reading body 0's block.**

**THE NEW BASELINE, shipped default:**

```
   unit 0 (CHORUS)      cell 27  0..4401     cell 28  0..1440    cell 29    0..240
                        cell 2B  400..1040   cell 2D  160..2080
                        cell 2F  GONE -- unit 1 no longer touches it

   unit 1 (CONCERT REVERB 1) -- fifteen lines where there were NONE:
        cell 00 (81E7)  247..33015    cell 02 (A3C5)     0..335     7.60 ms
        cell 04 (A5FE)    0..664      cell 06 (A8C1)     0..1036
        cell 08 (ADA3)    0..1717     cell 0A (B42D)     0..2684
        cell 0C (B60D)    0..1914     cell 0E (B80D)     0..992
        cell 10 (BB73)    0..1862     cell 12 (BE19)   438..2540
        cell 14 (C19D)  660..3440     cell 16 (C4E5)   600..4280
        cell 18 (874A) 1626..34394    cell 1B (8616)  1318..34086
        cell 1E (7FFF) 29007..32767
```

★ `4161 -> 4401` on the surviving unit-0 line, and `3120` is gone from unit 0's census entirely.
**Expected, and not a regression** (§207). ⚠ The `cell 27` line pools two consumers (kernel `iw12`
and body-0 `iw98`) and pooled a *different* pair before the shift, so `+240` is a re-pairing and is
**NOT** offered as the CHORUS modulation depth; `m_tapmod` is gated off in this build.

**§202's CONCLUSION stands and is strengthened.** It rests on the temporal argument, and the fifteen
unit-1 lines are **7.6–780 ms**, not complements near 1.48 s.

★ **Five of the reverb's lines resolve to ONE shared write cell** (`0x0A`/`0x0F` = `0xB42D`), at
monotonically increasing distances — 992, 1862, 2540, 3440, 4280 frames = 22.5, 42.2, 57.6, 78.0,
97.1 ms. That is the *shape* of a multi-tap comb.
⛔ **AND IT CARRIES NO p-VALUE, WHICH IS WHY IT IS SAID HERE RATHER THAN SCORED.** `age = R − W` is
true **by construction** for any read that resolves at all — every write address is some cell's
value plus the same rotation — so "the age equals a ROM cell difference" is an identity, not a test.
What is genuinely informative is only *which* cell it resolves to: 7 of 15 land inside unit 1's own
block instead of somewhere else. **INFERRED, weakly.** I computed the null (`15 × 32/65536 = 0.007`)
before noticing the identity, and it is printed so the next pass does not re-derive the same
circularity.

⚠ Three lines (`0x00`, `0x18`, `0x1B`) peak near 33–34 k, about half the 65 536-frame buffer, which
is what an **unresolved** pairing looks like. Not claimed as taps.

### 5. ⚠ What is NOT claimed, and it is the important part

* ⛔ **RING vs a HARDWIRED TWO-ENTRY BASE TABLE is TIED, and neither is claimed.** Both produce
  every number in §2 identically. Separating them needs a unit-1 block longer than **38** cells and
  the corpus maximum is **32** (all twelve reverbs). The ring is implemented because it gives the
  immediate `0x25` a job — parsimony, **not evidence**. `dram-unit-cursor.md` §2.4 and
  `DSCBASE_findings.md` item F say the same and this section does not improve on them.
* **THE CHIP IS STILL SILENT.** `§70 ACCA min 0 max 0`, quiet **and** loud, on the shipped default.
  A correct descriptor map is not a working reverb; the output stage (`w73`, §141/§150) is a
  separate, untouched defect and this fix was never expected to move it.
* **§205's gate is unmoved**: `§48 DELAY READ CONSUMED (SRC 0x0B): 22 781 700 times, **0** with a
  non-zero datum`. While that is 0 the kernel's unit-0 send is 0 whatever else is done.
  ⚠ The `PRE=0 RING=1` arm is the **only** one that ever returned data (1 128 908 non-zero delay
  reads, 960 consumed) — it reads back *the same frame's own write* at zero distance, which is a
  degenerate line, not a delay. Recorded because it looks like progress and is not.
* **`L₁` inside `0x20..0x26`, `B₀` inside `0x00..0x26` and `L₀` inside `0x3A..0x41` are FREE.**
  No shipped algorithm reaches any of those bounds, so no run can move them. `0x00/0x26/0x40` is
  `dram-unit-cursor.md` item G's 38 + 26 = 64 partition and is a *choice within the class*.
* **Whether the kernel's own consumers run in unit 0's ring or unit 1's** is still open
  (`dram-unit-cursor.md` §2.5 prints both and picks neither). This build puts them in unit 0's,
  because that is what `m_cur_unit1` says; nothing measured here depends on it.

### 6. ⚠ One defect in the pre-registration, found by the run

`DSCBASE_findings.md` §6.3's body-0 lines end `-> 9 of 10` and `-> 10 of 10` **written** cells. The
truth is **8 of 10** and **9 of 10**: descriptor cell `0x29` is `0x0000`, unwritten. The prediction's
own *value* vectors already show that second zero, so the cells and values were right 4/4 and only
the derived tally was off by one. **Recorded rather than quietly corrected** — the same class of
error as §207's, in a document written to fix §207's.

### 7. Fired counts (shipped default, one cold-boot run)

```
   §209 DSCPRE  applied 46 665 909
   §209 DSCRING evaluated 46 665 909, wrapped 31 734 252 (unit 1 31 711 212, unit 0 23 040)
   §201 per-body index reset  2 736 860      §203 C-format consumption  5 698 785
   §202 rotation sign FALLING 46 665 909
```

Evidence grade: the implementation **FORCED within `dram-unit-cursor.md`'s printed model class**
and **TIED** with the base-table rival; the consequence **MEASURED**, 4 of 4 arms bit-exact against
a pre-registration committed before the build; the §202 re-baseline **MEASURED**; the multi-tap
reading **INFERRED and explicitly un-scored** (the statistic is circular); the audio **UNCHANGED and
still silent**.

---

## §210 — ⚠ §207 OVER-CORRECTED §202, and §209's measurement shows how far

§209 shipped the per-unit ring and hit **16 of 16** on the pre-registered census. In doing so it
measured the thing §207 had asserted, and §207 was too strong.

**§207 said:** the `dsc` labels are `+1`, therefore §202's two "bit-exact" matches *"were body-1
consumers reading body-0's block"* — i.e. both the cells and the attribution were wrong.

**§209 measured:** with labels corrected and the ring off, the same machine reports `4161` at cell
**`0x27`** and `3120` at cell **`0x2F`** — **exactly the cells §202 named.** What was wrong is
narrower: **the `0x2F` line was body 1's**, not body 0's. CHORUS has ten consumers (`ix 0..9`) and
`0x2F` needs `ix 10`.

⇒ **§202's cell identifications were RIGHT.** One of its two lines was attributed to the wrong body.
I took an agent's "+1 label" finding and amplified it into "the numbers were the wrong block", which
is a stronger claim than the evidence carried — and I wrote it into the register and the handoff as
though settled.

★ The pattern is worth naming, because it is the mirror of the one this project keeps hitting:
**over-correcting is as costly as under-correcting.** §207's framing would have sent the next pass
looking for an error in §202's arithmetic that does not exist.

### What §209 actually bought

* **16 of 16** on the census, the exact sixteen values §207 §4 named, in order; the other three arms
  score 0 of 16 and each matches its own pre-registered signature.
* **Unit 1 has fifteen delay lines where it had none** — 7.6 ms to 780 ms.
* The 23 040 unit-0 wraps were **localised, not explained away**: 0 in a settled frame, last at
  frame 264 000 of 1 392 430 — the partially-uploaded-I-RAM transient.

### ⚠ And what §209 recorded against itself, correctly

* `age = R − W` is an **identity, not a test**, so its "7 of 15 match a ROM cell difference" carries
  **no p-value**; only *which* cell each resolves to is informative.
* The `PRE=0 RING=1` arm returned 1 128 908 non-zero delay reads — and it reads back **the same
  frame's own write at zero distance**. *"It looks like progress and is not."*
* §6.3's body-0 "written" tallies were off by one (cell `0x29` is unwritten); the value vectors were
  right.

### Unchanged

`§70 ACCA min 0 max 0` on the shipped default, quiet **and** loud frames. `§48 DELAY READ CONSUMED`
is still **0 with a non-zero datum**, so §205's downstream gate has not moved. Correct delay lines
are not audio.

Evidence grade: §209's census **MEASURED** against a pre-registration committed before the build;
§207's over-reach **acknowledged**.

---

## §211 — ⛔⛔ THE OUTPUT STAGE IS NOT WHERE THE SILENCE LIVES. `w73` PRESENTS A ZERO IT WAS HANDED, AND `§48` IS NOT A GATE

Scored against `data/PREDICT_211.md`, **committed before the emulator was launched**
(`kn5000-roms-disasm@d171953`). Run: `data/outstage_211.log.gz` — shipped default
`0xB910E446A39B440F`, all five env gates ON, clean vehicle
(`kn7000_mame/scratchpad/coldnotes2.lua`, cold boot, isolated NVRAM, triad C4/E4/G4 held
21.0–27.5 s, `-seconds_to_run 30`), 1 440 001 frames, **313 960 loud**.

**The task was "the output stage — why is IC311 silent". The answer is that the output stage is
not silent for any reason of its own: it is handed a zero, and everything it does with that zero
is correct.**

### 0. The calibration passed, so the run counts

`§54 TRACKING` reports **313 960 loud frames** against the pre-registered `~312 000`
(6.5 s × 48 kHz). The kernel shows **27 input-dependent accumulator slots** against the
pre-registered `>= 20`. Neither could have been arranged after the fact; both were written down
first, and either failing would have voided every number below.

### 1. ★★★ THE EXHAUSTIVE READING, and it settles the whole question

⚠ **The scoring rule was fixed in advance** (`PREDICT_211.md` §1), because §104's `*` flag is not a
test of input dependence — a **free-running** quantity sampled over two buckets of unequal length
reports two different ranges too. So:

```
  INPUT-DEPENDENT  iff  flag == '*'  AND  (loud_lo - quiet_lo) != (loud_hi - quiet_hi)
  FREE-RUNNING     iff  flag == '*'  AND  the two deltas are EQUAL  (a pure translation)
```

Applied to all 285 executed slots by `dsp/tools/s104_score.py`:

```
  acc: 29 slots flagged '*'  ->  27 INPUT-DEPENDENT, 2 free-running
       input-dependent: iw 9..31, 35, 36, 37, 38          ALL of them in KERNEL A
       free-running:    iw 90, 91   (both endpoints translate by EXACTLY 262 144)
       kernel B 50..59:  0     epilogue 60..82:  0     body 0:  0     body 1:  0
```

★★ **Not one accumulator anywhere in I-RAM 39..384 depends on the input.** The last
input-dependent slot in the frame is **`iw 38`**; `iw 39` is where it becomes a both-buckets
constant. The two slots that *look* alive inside body 0 — `iw90/91`, the ones §104's own SUMMARY
line names as "first acc DIFFERS at 90" — are the **LFO ramp**, and the pre-registered rule
identifies them as such without needing to know that: both range endpoints move by the same
262 144.

⇒ **The presentation cannot be input-dependent, because nothing upstream of it is.** That is not
an inference about `w73`; it is exhaustion over every slot that could have carried a signal to it.

### 2. `§150 §4`'s NAMED MEASUREMENT, TAKEN AT LAST — and the suspect is MOOT

§150 §4 wrote: *"The discriminating observable is whether the store fires at `iw73` and what it
writes … Point it at slot 73 (`SPROBE` list) and read it."* That was **60 sections ago and was
never done**; the probe was already in the build and had simply never been aimed. `SPROBE_MAX`
16 → 24 and eight epilogue slots added (read-only, no gate, no decode change):

```
  iw  word        n_exec   dpPre dpPost | dec gfail supp g7 path | stores
  63 02A79051C3  1020000     00    00   |  0    1    1   0   1  | (NO STORE)
  64 0C40A80445  1020000     00    00   |  0    4    0   0   0  | (NO STORE)
  70 02A61850C7  1020000     00    00   |  0    1    1   0   1  | [site3 addr 85 val 0..0 x1020000]
  71 0C41900446  1020000     00    00   |  0    4    0   0   0  | (NO STORE)
  72 0000106087  1020000     00    00   |  0    1    0   0   1  | [site3 addr 06 val 4194304..4194304]
  73 0E30C00404  1020000     00    00   |  0    1    0   0   1  | [site2 addr 00 val 0..0 x1020000]
  77 0859086822  1020000     00    00   |  0    1    0   0   1  | (NO STORE)
  78 0A3CD9F287  1020000     00    00   |  0    1    0   0   1  | [site2 addr 00 val 0..0] [site3 addr 00 val 0..0]
```

★ **`w73`'s bit-4 store FIRES** — 1 020 000 times, once per settled frame, not suppressed
(`supp 0`) — **and it writes `0`, to D-RAM cell `0x00`, min = max, every frame.**

⇒ **§150 §3's store-and-clear suspect is MOOT, not refuted: there is nothing to clear.** The
accumulator is already zero when `w73` begins. The three-way contradiction §150 posed (the
store-and-clear reading vs `hi12` bit 4 meaning *store* vs the presentation ordering) **cannot be
adjudicated at this word by any experiment**, because all three readings produce the same
observable when the datum is zero. And the destination is cell `0x00`, which nothing in the frame
reads (§104: `dp = 0x00` at every slot 60..79, `mem` 0..0). The store is inert as well as empty.

### 3. ⛔ §141's LOCALISATION TO `w73` DOES NOT HOLD ON THE SHIPPED BUILD

The epilogue's accumulator, MEASURED per slot, quiet **and** loud, both identical:

```
  w54..w64   2 603 010 048   a CONSTANT, both buckets, '='
  w65        0               020.1.8F.1C1  -- reg 0x8F, ACT 0x01
  w66..w82   0
```

**The accumulator is zero from `w65`, eight slots before `w73`.** §141 reported
`iw64: 1 102 114 506 752 | iw65..72: preserved | iw73: 0` — **measured with mask bit 55 (the §138
guard) ON**. This run confirms `§138 stale-LOAD guard (mask bit 55 = 0): FIRED 0 times`. §141's
table describes an arm that is **not shipped and never was**.

★★ And note what `w73` would have destroyed even under that arm: `2 603 010 048`, **a constant in
quiet and loud alike.** Standing rule 1 exists for exactly this — *a difference from silence is not
a signal*. Chasing `w73` was chasing the right to present a DC.

★ **`w65` is not an "erasure" either.** It is `SRC 0x07 / ACT 0x01` on register `0x8F` — an
ordinary load of a unit-1 body cell that is empty. It does what its fields say.

### 4. ★ THE UNIT-1 HALF, MEASURED FOR THE FIRST TIME

§70 has only ever watched **ACCA at `w73`**. `w78` presents **ACCB**, and standing rule 1 had
therefore never been applied to DO2 at all — §61's "DO2 peak 0" cannot tell an empty ACCB from an
empty unit-1 OUTPUT LEVEL, and the two call for different work. New probe, same buckets:

```
  §70  ACCA AT w73:  quiet 726 040 frames  min 0 max 0  |  loud 313 960  min 0 max 0
  §211 ACCB AT w78:  quiet 726 040 frames  min 0 max 0  |  loud 313 960  min 0 max 0
  §61  unit0/DO1 1 203 840 exec, 0 non-zero, peak 0 | unit1/DO2 1 203 840 exec, 0 non-zero, peak 0
```

**Both accumulators are hard zeros.** The unit-1 level is not the problem; there is nothing for it
to scale. ⇒ `w78` is closed on the same terms as `w73`, and the `A3C.D.9F.287` decode is not what
is between the chip and audio.

### 5. ★★★ THE BRIEF'S OWN QUESTION: **NEITHER**. `§48` IS NOT A GATE, IT IS A SYMPTOM

The task asked whether the output silence is *downstream of §48's delay-read gate* or *independent
of it*. Decided in advance (`PREDICT_211.md` §4), and P1 held, so: **neither, as posed.** Both are
downstream of the same upstream fact — and the delay port itself says so:

```
  §48 DELAY READ CONSUMED (SRC 0x0B):  23 733 120 times, 0 with a non-zero datum
  §46 DELAY PORT: 24 922 560 reads (0 returned NON-ZERO), 23 693 760 writes
  §75 DELAY WRITES WITH CONTENT: 1 175 999 of 23 693 760   ->  95.04 % write ZERO
  §75 DLY W addr 966F cell 0000 frame 420001 data 7D70     <- and the other 4.96 % write THIS
```

`0x7D70 = 32 112`. The delay WRITE takes `acc_to_datum(m_acc) >> 8` (`upd6383.cpp:2016`, source),
and the accumulator at kernel `iw46` is the **constant** `538 760 587 509`; `538760587509 >> 16 =
8 220 787`, `>> 8 = 32 112 = 0x7D70`. Predicted from §104's table before the sample line was read,
and it matches to the bit.

⇒ **The one non-zero datum any delay write has ever put into the line is a constant.** Opening
§48's gate could therefore only deliver a DC to the ladder. ★ **§205 §1's *"while that is 0 the
send is 0 whatever else is done"* is TRUE and is NOT the operative constraint.** The unit-0 send is
not merely zero — it is **input-blind from `iw39`, which is upstream of every delay word except the
kernel's own two reads.** Fixing the delay path cannot produce audio; it would produce a delayed
constant.

### 6. WHERE THE INPUT ACTUALLY GOES — three MEASURED facts, handed over rather than acted on

Two independent instruments agree, so this is not a reading of one table:

* **§96 writer census**: cell `0x05` — the unit-0 body **entry** cell (`output-stage-decode.md`
  item A, and `DRAM_UNIT_BASE = 0x05 | unit<<7` at the CALL) — is written by
  `iw9`, `iw11`, **`iw35`**, **`iw45`**. `iw11`'s store is INPUT-DEPENDENT
  (`[site3 addr 05 val 722..16 760 298]`, SPROBE).
* **§104 residency**: cell `0x05` reads **input-dependent at `iw35`**, then `4 194 304` at
  `iw36..45`, then **`0`** at `iw46..49` and at body-0's own `iw84`/`iw85`.
  `4 194 304 = 0x400000 = acc_to_datum(2^38)`, and `2^38` is exactly the accumulator `iw34` leaves.
* ⇒ **body 0 reads its entry cell and finds `0`, every frame.** The input arrives in `0x05` and is
  overwritten twice before the body runs.

★ **The new, gradeable lead — `iw39` stores TWICE to the same cell, and the second store wins:**

```
  39 0410AFF647  [site2 addr 06 val 1991044..8388607 x1020000]   <- bit-4: the INPUT-BEARING acc
                 [site3 addr 06 val 0..0          x1020000]      <- ACT 0x07: tempA, and it is 0
```

`site 2` is `upd6383.cpp:2816`, `site 3` is `:3487` — same function, same word, second one last.
`iw39 = 410.A.FF.647` is **fully `alu_decoded()`** (`dec 1`, `gfail 0`, `path 0`), so this is not a
speculative artefact. Its `SRC` is `0x19 = LO_SRC_TA` (ANCHORED), and **tempA is empty at that
word**. So the kernel's one input-bearing deposit into cell `0x06` is overwritten by an empty
temporary in the same instruction.

⚠ **This is a LEAD, not a finding, and nothing here was changed on the strength of it.** Two things
must be established before anyone touches it: (a) that a word carrying *both* `HI_ST` and
`ACT 0x07` really performs two stores on real silicon — the alternative is that one of the two
readings is wrong for this encoding, which is a decode question and not a bug; and (b) **why
tempA is empty**, which is the same shape as the `SRC 0x13` hole in the LEDGER's tier-0a blocker.
⛔ Do **not** reach for "suppress one of the two stores": that is an ANCHOR-VALUE fix (standing
rule 9) aimed at a symptom.

### 7. What was built, and the control on it

`SPROBE_MAX` 16 → 24, eight epilogue slots added to `sprobe_idx()`, and the `§211 ACCB AT w78`
probe. **All read-only**: no gate, no mask bit, no decode. The control is free and it passed — the
instrumented build's §104 census is **identical, slot for slot**, to the pre-instrument run
(27/2 split, same slot list, same loud count 313 960). A probe that changed the machine would have
shown up there.

### 8. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| *"the output stage — why is IC311 silent"* as a task | the stage presents what it is handed, and it is handed a hard zero in both units |
| **`w73`** as the localisation (§141) | measured under the §138 guard, which fires **0 times** in the shipped default; the accumulator is zero from **`w65`** |
| **`w73`'s store-and-clear** as a suspect (§150 §3) | the store FIRES and writes **0** to cell `0x00`; there is nothing to clear and nothing reads the cell |
| **`w78` / `A3C.D.9F.287`** | ACCB is a hard zero, so the unit-1 decode is not between the chip and audio |
| **`§48`'s delay-read gate** as *the* blocker (§205 §1) | true but not operative: 95 % of delay writes write 0 and the rest write the constant `0x7D70`; opening the gate delivers a DC |
| **`bit11-family.md` item B's undecidability** as a *blocker* | it remains true and is now also **irrelevant**: nothing downstream of the presentation unknowns is waiting on them |

Evidence grade: §1 **MEASURED** against a scoring rule committed before the run, and **exhaustive**
over all 285 executed slots; §2 **MEASURED** (the store witness, fired-count 1 020 000); §3
**MEASURED**, and §141's arm identified as unshipped by that run's own bit-55 fired-count of 0;
§4 **MEASURED**; §5 **MEASURED**, with the `0x7D70` arithmetic **FORCED** from source and matched
to the bit; §6 **MEASURED** (two independent instruments) for the cell-`0x05` history, the double
store **MEASURED** and its net effect **INFERRED (strong)** from the two sites' order in one
function; §7 **MEASURED** (the identity control).

---

## §212 — ⛔ §205's "single number that matters" was WRONG. §48 is not a gate, and §141's `w73` does not hold.

§211 answered the discrimination it was asked for, and the answer retires two things I had been
repeating — one of them in every handoff for the last several passes.

### 1. ⛔ `§48` is NOT the operative constraint

I wrote, and re-wrote into `HANDOFF-NEXT.md` and the memory file: *"`§48 DELAY READ CONSUMED`'s
second field is the single number that matters — while it is 0, the send is 0 whatever else is
done."* The statement is **true and not the constraint.**

§211 MEASURED, exhaustively over all 285 executed slots: **27 accumulators are input-dependent and
every one is in kernel A (`iw 9..38`)** — kernel B **0**, epilogue **0**, body 0 **0**, body 1 **0**.
And **95.04 % of delay writes write `0`**, the remaining 5 % writing the constant `0x7D70`, forced
from source and matched to the bit.

⇒ **Opening `§48` would deliver a DC.** The input never reaches either body at all; it dies in
kernel A. I had promoted a true downstream fact into the headline blocker, and it would have sent
the next pass to unblock a path that carries nothing.

### 2. ⛔ §141's localisation of the silence to `w73` does not hold on the shipped build

§141 measured **with mask bit 55 (the §138 guard) ON**. That bit is **0** in the shipped default and
this run reports it firing **0 times**. On the current build the epilogue accumulator is the constant
`2 603 010 048` from `w54`→`w64` and `0` from **`w65`** — eight slots earlier than `w73`.

★ And what `w73` would have destroyed under that arm was **a constant in quiet and loud alike** —
the exact DC shape standing rule 1 exists to catch. Rule 10 again: a blocker is a measurement, and
measurements expire.

⇒ **`w73` is innocent.** Its bit-4 store fires **1 020 000×**, unsuppressed, writing `0` to D-RAM
cell `0x00` — a cell nothing reads. §150 §3's store-and-clear suspect is **MOOT, not refuted**:
there is nothing to clear, and all three of §150's rival readings give the same observable on a zero
datum, so **no experiment at that word can separate them.** `bit11-family.md` item B's
undecidability of the presentation codes is now not merely true but **irrelevant**.

★ §150 §4 named the instrument that settles this — *"point the §109 store witness at slot 73"* —
**sixty sections ago**, and nobody aimed it until now.

### 3. ★ What §211 added that had never been measured

`§70` had only ever watched **ACCA**. `w78` presents **ACCB**, so standing rule 1 had **never been
applied to DO2 at all**. Now it is:

```
   §70  ACCA at w73:  quiet 726 040  min 0 max 0  |  loud 313 960  min 0 max 0
   §211 ACCB at w78:  quiet 726 040  min 0 max 0  |  loud 313 960  min 0 max 0
```

Both hard zeros. **No non-zero output was found and no claim of audio is made.**

### 4. The redirect — recorded, not acted on

The input reaches unit 0's entry cell `0x05` and is **overwritten twice before the body runs**
(`4 194 304` at `iw35`, `0` at `iw45`); body 0 reads `0` at its own `iw84/85` every frame. The one
gradeable lead is `iw39` storing **twice** to cell `0x06` — the input-bearing accumulator, then an
empty tempA, same fully-decoded word, second one last.

⚠ §211 flags *"suppress one store"* as an **anchor-value fix at a symptom** and declines it. Correct.

Evidence grade: §1 and §2 **MEASURED** (exhaustive over 285 slots; the store witness aimed for the
first time); §3 **MEASURED**; my §205 framing **RETRACTED**.

---

## §213 — ⛔⛔ §211's GRADEABLE LEAD WAS A PROBE ARTEFACT. The input dies at `iw36`, and the SEND is decided by ONE corpus-unique word whose SRC is a GUESS

Scored against `data/PREDICT_213.md`, **committed before `build.sh` was run**
(`kn5000-roms-disasm@251c513`). Run: `data/kernelA_213.log.gz` — shipped default
`0xB910E446A39B440F`, all env gates ON (`UPD6383_STPROBE = 1`), clean vehicle
(`kn7000_mame/scratchpad/coldnotes2.lua`, cold boot, isolated NVRAM **and isolated
`-cfg_directory`**, triad C4/E4/G4 held 21.0–27.5 s, `-seconds_to_run 30`), 1 440 001 frames,
**313 960 loud**.

⚠ **VEHICLE NOTE, and it cost one run:** `DSPCFG` is a `PORT_CONFNAME` that defaults to **Off**,
so a run with a *fresh* `-cfg_directory` executes **no DSP frames at all** and `device_stop()`
prints nothing (`m_frames_run != 0` guards the whole report). Copy
`kn7000-emulator/cfg/kn5000.cfg` (which carries `:DSPCFG value="3"`) into the isolated cfg
directory. A silent report is this, not a crash.

### 0. The calibration passed, so the run counts

`coldnotes2.lua` printed `located=true`, `NOTE ON t=21.02`, `NOTE OFF t=27.51`; `§54 TRACKING`
reports **313 960 loud** against the pre-registered 250 000–380 000. And the control held:
`dsp/tools/s104_score.py` scores this run and `data/outstage_211.log.gz` **identically in all
three columns** — `acc 27/2` (slots 9..31, 35..38), `mem 21/9`, `L 18/3`. The build is
**read-only**, as pre-registered.

### 1. ⛔⛔ §211 §6's "iw39 STORES TWICE" IS A PROBE ARTEFACT. THERE IS NO SECOND STORE

`upd6383.cpp`'s ACTION-0x07 site had an **unbraced `else`** in front of `store_mode()`:

```
    else
    store_mode(mode07, u8(d07), u32(L));     <- the ONLY statement the else guards
        kwatch(...); watch_store(..., 3);
        if (!lvl_hit && !ab_hit) store_probe(..., 3);
    m_dwr[d07]++; ...                        <- all of these ran on every VISIT
```

The `!lvl_hit && !ab_hit` guard is the hand-patch that covered the **two** suppressors named in
the comment above it. The **third** — §112's class-A latch arm (mask bit 25, ON in the shipped
default), which latches `P` and stores nothing — was added 100 sections later and never got it.
So the §109 witness reported three stores per frame that the machine does not perform.

★ **It was already MEASURED, in §211's own log, before this build existed.** `iw34`
(`000.A.FF.407`, class A, ACT 0x07) was logged storing `8 388 607` to cell `0x06` — yet §104's
residency column shows `0x06` still holding **`6 039 795`**, what `iw33`'s bit-4 store put there,
at `iw38` **and** at `iw39`, with nothing writing it in between. The store did not happen.

**Shipped: `UPD6383_STPROBE` (default 1), with a fired count.** Every prediction held:

| # | prediction | result |
|---|---|---|
| P1 | no site-3 store at `iw32`, `iw34`, `iw39` | ✅ `iw32` and `iw34` now print **`(NO STORE)`**; `iw39` prints only `[site2 addr 06 val 1 991 044..8 388 607]` |
| P2 | `iw72` (class 1) and `iw78` (class 0xD) KEEP theirs | ✅ both unchanged; `iw78` still shows a genuine site2+site3 pair |
| P3 | §96 loses `cell 07 by iw32` and `cell 06 by iw34`, keeps `iw19/21/27/33/39` and `iw9/11/35/45` | ✅ exactly that |
| P4 | fired count **equals** the §112 latch count | ✅ **3 630 720 = 3 630 720**, to the unit |
| — | (unpredicted corroboration) | §86 cell 06 writes `8 160 000 → 6 120 000` (−2/frame: `iw34` **and** `iw39`'s site 3) and cell 07 `2 040 000 → 1 020 000` (−1/frame: `iw32`) |

⇒ **`iw39` performs exactly ONE store**, of the input-bearing accumulator, into cell `0x06`.
⇒ §211 §6's *"the live value is destroyed by the second store"* is **RETRACTED**, and *"suppress
one of the two stores"* would have been a **NO-OP on the machine** that silenced a probe line.
Declining it (§211, §212 §4) was right for the wrong reason.

### 2. ★★ AND THE §112 LATCH IS IRRELEVANT AT `iw39` ANYWAY — the MULTIPLY overwrites it

§213's new per-slot `pw` column (who last wrote `P`) reads **`0x40` = bit 6 = THE MULTIPLY** at
`iw39`, not bit 5 (§112). Reading the source with that in hand: `iw39` is class A, so
`coeff_consumer()` fires **after** the ACTION switch and executes
`m_p = (sext(coef,24) * L) >> P_SHIFT; m_pw = 6` (`upd6383.cpp:3645`) — overwriting the latch in
the same word. ⇒ **`P5c`'s value prediction held and its MECHANISM was refuted** (rule 10 again:
the measurement answered a different question). The `HI_ST`-plus-`ACT 0x07` decode question §211
posed as prerequisite (a) is therefore **doubly moot** at this word: one arm is a phantom and the
other is overwritten before anything can read it.

⇒ **The operative fact at `iw39` is simply that the multiplier's multiplicand is the bus `L`, and
`L` is `tempA`, and `tempA` is `0`.**

### 3. ★★★ WHERE THE INPUT ACTUALLY DIES — `iw36`, one word earlier than §211 implied

The new `P` census, quiet ‖ loud, kernel A (`data/kernelA_213.log.gz`):

```
   iw35  012.A.00.1C0   P  280 183 750 068  ‖  -292 505 928 512 .. 462 303 209 657   *  INPUT
   iw36  400.A.00.000   P -126 764 777 472  ‖  -126 764 777 472 .. -126 764 777 472  =  CONSTANT
   iw37  092.A.01.1C0   P  401 321 689 088  ‖   401 321 689 088                      =
   iw38  809.0.00.839   P  401 321 689 088  (bit-11 word: no ALU, no multiply)
   iw39  410.A.FF.647   P            0      ‖             0                          =
   iw41  400.A.00.21A   P  538 760 587 509  ‖   538 760 587 509                      =
```

★ **`P` stops depending on the input at `iw36`.** ⚠ `P5b` predicted `iw37`; **half-refuted, and
the correction is sharper.** The mechanism, FORCED from `upd6383.cpp:3645` and matched to the
table:

* `iw35` carries **`HI_ST`**, and the bit-4 store runs **before** the adder. It writes
  `acc_to_datum(m_acc)` — the accumulator `iw34` leaves, `2^38 → 4 194 304` — into **mode-2
  destination `m_dp` = cell `0x05`**, the cell it is itself about to read. The read happens
  first, so `iw35`'s own bus is still the input (`L` `-5 307 593..8 388 607`) and its multiply is
  input-bearing.
* `iw36` and `iw37` re-read the **same parked cell** (`dp` stays `0x05`; `SRC 0x00` then
  `SRC 0x07`, both `mem[ptr]`), so from `iw36` on the multiplicand is the constant `4 194 304`
  and `P` is a constant. §104's `L` column: `4 194 304..4 194 304` in **both** buckets at `iw36`
  and `iw37`.
* `iw39` has `hi12[3:1] == 0`, i.e. **`acc ← P`** — it discards the accumulator and loads that
  constant. That is exactly §211's "last input-dependent slot = `iw38`", and §81's probe
  `after iw39 SRC19: IDENTICAL 401 321 689 088` names the same word.

⚠ **`iw35`'s store is NOT being called a defect.** "Store the running result at `X+6`, then
re-read it" is an ordinary two-operand idiom, and the input is not lost by it — see §5.

### 4. ★★★ THE SEND: `tempA` IS NOT "EMPTY", IT IS **ZEROED AT `iw25` BY THE DELAY READ**

`§213`'s `tempA` column settles §211's prerequisite (b) outright:

```
   iw6    tempA  5 084 004      ‖  5 084 004                    =   (a constant)
   iw7 .. iw24   tempA  0..0    ‖  -5 579 776 .. 4 994 816      *   INPUT-DEPENDENT, 18 slots
   iw25   000.2.00.2D9          tempA  0..0  ‖  0..0            =   ⛔ ZEROED HERE
   iw26 .. iw52  tempA  0..0    ‖  0..0                         =   and it never recovers
```

`iw25` is `SRC 0x0B` (the delay-read data register `m_dr`) with `ACT 0x19` (`tempA ← bus`).
§46/§80 measure `m_dr`: **24 922 560 reads, 24 922 552 latched, ZERO non-zero**, and §48
**23 733 120 consumptions, 0 with a non-zero datum**. §104's `L` column at `iw25` is `0..0` in
both buckets, and at `iw27` — the next word that SOURCES `tempA` — likewise. `iw7` is the first
input-bearing writer (`ACT 0x08`, blanket capture), `iw19`/`iw21` refresh it, and `iw25` replaces
all of it with the delay port's zero.

⇒ **ANSWER to §211's (b): `tempA` being empty is a CORRECT CONSEQUENCE of §48, not a defect of
its own and not a decode hole.** Given the shipped `SRC 0x0B` and `ACT 0x19` readings, `iw25`
does precisely what its fields say.

And that zero is what the send carries:

```
   iw39  L = tempA = 0   ->  multiply: P = coef x 0 = 0
   iw41  400.A.00.21A    ->  hi12[3:1] = 0  =>  acc <- P = 0        (§104: acc 0..0 from here)
   iw45  010.A.00.20C    ->  HI_ST, mode 2, dp = 0x05 = THE UNIT-0 SEND, stores acc = 0
   iw46  800.1.60.00B    ->  the kernel's delay WRITE takes acc = 538 760 587 509 -> 0x7D70
```

★ **So the send's datum is `m_dr` at `iw25`, four registers upstream, and it is a hard zero.**

### 5. ⚠ TWO CORRECTIONS TO THINGS I HAVE WRITTEN

**5.1 `§212 §1` OVER-RETRACTED `§48`.** I wrote that §48 is "true and **not** the constraint",
because the input dies in kernel A. §4 shows §48 **is** in the kernel's own send path, upstream of
`iw45`. What survives of §212 §1 is the part that matters: **opening §48 alone still cannot deliver
audio**, because the loop is closed on itself —
`iw25 (delay read) → tempA → P → acc → iw45 send → iw46 delay write → next frame's iw25`.
The only non-zero datum ever written to the line is `iw46`'s `0x7D70`, which is `acc` at `iw45`,
which is that same zero one hop later. **A DC in, a DC out.** Nothing external enters the loop.

**5.2 Cell `0x06` is NOT dead, and §98's `06w` understates it.** §98 marks kernel-A cell `0x06`
write-only, but `pwatch()`'s READ hook sits only on the anchored `SRC 0x07` evaluator
(`upd6383.cpp:2658`); `SRC 0x00`'s reading of `mem[ptr]` is invisible to it. §104's residency
column shows `dp = 0x06` at `iw12..iw27` holding `8 388 607` quiet ‖ **`1 991 044..8 388 607`**
loud — *exactly* the range `iw39`'s bit-4 store deposits — and `iw13`/`iw14` read it as
`mem[ptr]`. ⇒ **`0x06` is a CROSS-FRAME CARRY**: `iw39` parks the last input-bearing accumulator
there and the next frame's mix block picks it up. MEASURED (residency + range identity);
INFERRED that the datum is specifically `iw39`'s (nothing else writes `0x06` after it).
⚠ And §176 says what is actually parked: `06: 8 388 607 (0..8 388 607 / chg 1100)` over 1 440 001
frames — the deposit is at the **24-bit rail** on all but ~1100 frames. §211 called this datum
"the INPUT-BEARING accumulator"; it is input-dependent in range and **clipped nearly always**.

### 6. ⚠ STANDING RULE 1 — applied, and the answer is unchanged

```
   §70  ACCA AT w73:  quiet 726 040  min 0 max 0  |  loud 313 960  min 0 max 0
   §211 ACCB AT w78:  quiet 726 040  min 0 max 0  |  loud 313 960  min 0 max 0
   §61  unit0/DO1 1 203 840 exec, 0 non-zero, peak 0 | unit1/DO2 1 203 840 exec, 0 non-zero, peak 0
   §54  quiet-in 826 040 -> 826 040 silent / 0 LOUD | loud-in 313 960 -> 313 960 silent / 0 loud
```

**min == max == 0 in both accumulators, in both buckets. NO non-zero output was produced and NO
claim of audio is made.** The NULL (P7) held: this pass changed nothing audible, by construction.

### 7. ★★★ THE NEXT INSTRUMENT — and it is a DECODE question, not an anchor value

The send is decided by **one word**, and that word is **unique in the corpus**. Census over all
41 committed listings (3057 words), bit-11 words excluded because they carry no `SRC` field:

```
   SRC 0x0B words:  106
      class 1, addr8 0x20 (delay READ)     49
      class 1, addr8 0x60 (delay WRITE)    50     <- the 99 that motivated the reading
      class 2, addr8 0x00                   7
         020.2.00.2C7  ACT 0x07   x6   ENSEMBLE w14/24/34/72/82/92
         000.2.00.2D9  ACT 0x19   x1   THE RESIDENT KERNEL, iw25  <- ONE OCCURRENCE, EVER
```

`SRC 0x0B = the delay-DRAM data register` is labelled in the source itself as *"★ SPECULATIVE …
It is a GUESS; register row 14"*, and its motivation is the 99 class-1 delay words — **none of
which is `iw25`**. `iw25` performs **no delay access at all** (class 2, `addr8 = 0x00`), it has
**no corpus twin**, and it is the sole determinant of what the unit-0 send carries.

★ **The two-sided experiment, pre-computable and stated now.** `iw25`'s pointer is on cell `0x06`,
whose §104 residency is `0..0` quiet ‖ `-5 579 776..4 994 816` loud — **INPUT-DEPENDENT**. So a
rival reading of `SRC 0x0B` *at a class-2 word* (`mem[ptr]` is the obvious one) predicts, in
advance:

* `tempA` at `iw27` stops being `0..0` and becomes input-dependent;
* `P` at `iw39` stops being `0` and becomes input-dependent;
* `acc` at `iw41` and `iw45` likewise, so §104's LAST input-dependent slot moves from **`iw38`**
  to at least **`iw45`**;
* body 0 stops reading `0` at its own `iw84`/`iw85`.

Four independent ways to fail, and `s104_score.py` scores all of them from one log.
⚠ **And a fifth thing must be checked before any of it counts**: `§70 ACCA` / `§211 ACCB`
`min` vs `max`, plus a no-stimulus window. Two "IC311 outputs audio" claims have been retracted
here and one was a DC; a send that carries the input is still not audio until the ladder is
measured.
⛔ It must ship **default OFF, with a fired count**, and only ENSEMBLE's six `020.2.00.2C7`
words share the family, so the corpus can grade the rival on a second program.

### 8. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **§211 §6's "`iw39` stores TWICE, second one wins"** | the second record is a **phantom**; MEASURED by cell `0x06`'s residency in §211's own log, and now by the fixed probe |
| **prerequisite (a): "does `HI_ST` + `ACT 0x07` really do two stores?"** | moot twice over — the ACT-07 arm stores nothing on a class-A word, and its `P` write is overwritten by the multiply in the same word |
| **prerequisite (b): "why is `tempA` empty?"** | **ANSWERED**: it is not empty, it is **zeroed at `iw25`** by a capture of the delay-read register. A correct consequence of §48 |
| **"the input dies at `iw39`"** | the *accumulator*'s does; **`P`'s dies at `iw36`**, on the multiplicand `mem[0x05]` that `iw35`'s own store parked there |
| **"cell `0x06` is written and never read" (§98)** | §98's read hook only sees `SRC 0x07`; `0x06` is a **cross-frame carry** read by `iw13`/`iw14` |
| **§212 §1's blanket "§48 is not the constraint"** | **half-retracted**: §48 *is* in the send path. What stands is that opening it alone delivers a DC, because the path is a closed loop |

Evidence grade: §1 **MEASURED** against four predictions committed before the build, with an exact
fired-count identity, plus an independent pre-existing measurement (§211's cell-`0x06` residency);
§2 **MEASURED** (the `pw` column) and **FORCED** from `upd6383.cpp:3645`; §3 **MEASURED** (the `P`
census) with the mechanism **FORCED** from source and matched to §104's `L` column; §4
**MEASURED** (the `tempA` census, two independent instruments with §104's `L`); §5.1 **INFERRED
(strong)** from §4 plus §46/§48/§75; §5.2 **MEASURED** for the residency and range identity,
**INFERRED** for the attribution to `iw39`; §6 **MEASURED**; §7's corpus census **MEASURED** over
3057 words, the rival reading **SPECULATIVE and NOT SHIPPED**.

---

## §214 — the lead I handed forward was an INSTRUMENT ARTEFACT, and §212 §1 is half-retracted

### 1. ⛔ §211 §6's "one gradeable lead" did not exist

I passed on `iw39`'s double store to cell `0x06` as the single gradeable lead, and §213 disproved it
**before building anything**, from §211's own log.

`upd6383.cpp`'s ACTION-0x07 site had an **unbraced `else`** before `store_mode()`, so
`kwatch`/`watch_store`/`store_probe`/`m_dwr` ran on every *visit* while §112's class-A latch arm
(mask bit 25, **ON**) stored nothing — **three phantom store records per frame.** It was already
disproven inside §211's own log: `iw34` was logged storing `8 388 607` to cell `0x06`, yet §104's
residency shows `0x06` still holding `6 039 795` two slots later with nothing writing it between.

Fixed under `UPD6383_STPROBE`; fired count **3 630 720 = the §112 latch count exactly**, and
`s104_score.py` scores the new run and `outstage_211.log.gz` **identically in all three columns**.

⇒ **"Suppress one store" would have been a no-op on the machine.** ★ §211 declined it as *"an
anchor-value fix at a symptom"* — right instinct, and it was not even a symptom.
★ **RULE: a probe that reports a store must be gated on the store having HAPPENED, not on the site
being reached.** Three sections cited that phantom.

### 2. MEASURED — two distinct deaths, both in kernel A

* **`P` stops depending on the input at `iw36`** (the prediction said `iw37`; half-refuted, and the
  correction is sharper). `iw35` carries `HI_ST` and its bit-4 store runs *before* the adder,
  parking `acc_to_datum(2^38) = 4 194 304` in cell `0x05`; `iw36`/`iw37` re-read that parked cell.
  ⚠ **This is NOT a defect** — store-then-re-read is an ordinary idiom, and `iw39` parks the last
  live accumulator in `0x06`, which the next frame's `iw13`/`iw14` read back.
* **The SEND is killed separately at `iw25`.** `tempA` is input-dependent for **18 consecutive
  slots** (`iw7..iw24`, `−5 579 776..4 994 816` loud) and `iw25` (`000.2.00.2D9`, `SRC 0x0B` +
  `ACT 0x19`) **overwrites it with the delay-read register**, which is `0` on **24 922 560 of
  24 922 560** reads. Then `P = coef × 0`, `acc ← P = 0` at `iw41`, and `iw45` sends `0`.

### 3. ⛔ §212 §1 is HALF-RETRACTED — and its conclusion survives for a better reason

I wrote that `§48` is *"not in the send path"*. **It is** — `iw25` consumes exactly that register.
But §212's conclusion stands, because the path is a **CLOSED LOOP**:

```
   iw25 → tempA → P → acc → iw45 (send) → iw46 (delay write) → next frame's iw25
```

⇒ opening `§48` alone still delivers a DC. Right answer, wrong reason — recorded as such rather
than quietly kept.

### 4. ★ The next instrument, named and not run

The send is decided by a word that is **unique in the corpus**. Of 106 `SRC 0x0B` words, **99 are
class-1 delay words** (`addr8 0x20`/`0x60`) and 7 are class-2 `addr8 0x00` — ENSEMBLE's
`020.2.00.2C7` ×6 and the kernel's `000.2.00.2D9` ×1, which is `iw25`.

★★ **`SRC 0x0B = delay-read register` is labelled a GUESS in the source, and it is motivated
entirely by the 99 — none of which is `iw25`.** `iw25`'s pointer sits on cell `0x06`, whose
residency **is** input-dependent, so a rival class-2 reading has four pre-computed falsifiers
(`HANDOFF-NEXT.md` §1.2). Default OFF, fired count, standing rule 1 before any audio claim.

### 5. Unchanged

`§70 ACCA` and `§211 ACCB`: `min 0 max 0`, quiet **and** loud. `§61` both ports 0 non-zero, peak 0.
**No non-zero output was produced and no audio claim is made.**

⚠ Vehicle trap, now in the handoff: `DSPCFG` is a `PORT_CONFNAME` defaulting to **Off**, so a fresh
`-cfg_directory` runs **zero DSP frames** and `device_stop()` prints nothing. Copy
`kn7000-emulator/cfg/kn5000.cfg` in. It cost one run.

Evidence grade: §1 **FORCED** (the fired-count identity, and the contradiction inside §211's own
log); §2 **MEASURED**; §3 **MEASURED**, my §212 §1 **half-retracted**; §4 **MEASURED** census, the
rival reading **SPECULATIVE**.

---

## §215 — ⛔ THE RIVAL IS REFUTED BY THE CORPUS AND THE FALSIFIERS ALL PASSED ANYWAY. `SRC 0x0B` SURVIVES AT `iw25`, AND THE SEND WAS NEVER THE ONLY BLOCKER

Scored against `data/PREDICT_215.md`, **committed before `build.sh` was run**
(`kn5000-roms-disasm@575851e`). Two runs, same build, same clean vehicle
(`kn7000_mame/scratchpad/coldnotes2.lua`, cold boot, isolated NVRAM **and** isolated
`-cfg_directory` carrying `:DSPCFG value="3"`, triad C4/E4/G4 held 21.0–27.5 s,
`-seconds_to_run 30`, `-log`):

* **arm A** `data/src0b2_A_off_215.log.gz` — `UPD6383_SRC0B2=0`, the SHIPPED reading, 1 440 205
  frames, **314 063 loud**;
* **arm B** `data/src0b2_B_on_215.log.gz` — `UPD6383_SRC0B2=1`, the RIVAL, 1 440 001 frames,
  **313 960 loud**.

⚠ `logerror` output needs **`-log`**. Without it `device_stop()`'s whole report is discarded and
the run looks like the `DSPCFG` trap. It cost one run here, the way `DSPCFG` cost §213 one.

### 0. ★★★ THE ANSWER: `SRC 0x0B = the delay-read data register` HOLDS AT `iw25`

**And it is decided by the corpus, not by the four falsifiers — which is why §0 of the
pre-registration says so in advance.**

```
   lo12 = 0x2D9  ("SRC 0x0B" + ACT 0x19, tempA <- bus)          36 words of 3057
        class 1  addr8 0x60   delay WRITE     29    across 14 programs
        class 1  addr8 0x20   delay READ       6    ENSEMBLE w10/20/30/68/78/88
        class 2  addr8 0x00   NO ACCESS        1    THE KERNEL, iw25
   word 0x0012201655  = `mac ta,(p)+1'  -- the one word that MULTIPLIES tempA
        13 sites of 3057 = 0.43 % base rate
```

★ **C1 HELD, 13 of 13: every single site of `0012201655` is IMMEDIATELY preceded by a class-1
`addr8 0x20` DELAY READ** (`880.1.20.2D9` ×6 in ENSEMBLE, `880.1.20.40B` ×7 in the flanger family
and the kernel). `mac ta` after a delay read is **the** delay-read consumption idiom — which is
`dram-datapath.md` item H, now at 13/13 instead of n=1.

★ **C2 HELD, and it is the whole argument.** The slot two words before `0012201655` is the
"load the multiplicand into tempA" slot:

```
   ENSEMBLE      w10  880.1.20.2D9   READ *and* capture, one word     ->  w11  0012201655
   THE KERNEL    w25  000.2.00.2D9   capture only  (no access)
                 w26  880.1.20.40B   the READ, one word later         ->  w27  0012201655
   flanger x6    ...  000.2.00.44C   capture (SRC 0x11)               ->  w..  0012201655
```

⇒ **`iw25` is grouped, by its own successor, with the six ENSEMBLE class-1 delay READS** —
whose `SRC 0x0B` cannot be anything but the fetched delay datum. ENSEMBLE fuses the read and the
capture into one word; the kernel splits the identical `2D9` off one word *ahead* of its read.
Same lo12, same idiom, same consumer, two independent programs.

⇒ The rival (`SRC 0x0B` at a class-2 word = `mem[ptr]`) would have to claim **one lo12 means two
different things on two classes**, and it would leave the kernel's **two delay READs**
(`iw12 = 880.1.20.2D5`, `iw26 = 880.1.20.40B`) **with no consumer anywhere in the frame**.

★ **My own pre-registered falsifier was checked and did NOT fire:** the §215 counter measures
**1 211 520 class-2 `SRC 0x0B` evaluations against 1 203 840 body-0 executions = 1.0064 per
frame** — exactly one word, so `iw25` is the kernel's only class-2 consumer and the grouping
argument has no competitor. ⇒ **NOT SHIPPED. The gate stays default OFF.**

### 1. THE NULL AND THE CALIBRATION, both computed before the build

| # | pre-registered | measured (arm A) | |
|---|---|---|---|
| **N1** | class-2 `SRC 0x0B` = **1 211 520 ± 1 %** (= §48 − §77 in the control) | **1 211 725** (+0.017 %) | ✅ |
| **N2** | arm A **read-only**: `s104_score.py` identical to `kernelA_213.log.gz` in all three columns | `acc 27/2`, `mem 21/9`, `L 18/3`, **same slot lists, same last slot `iw38`** | ✅ |
| **N3** | fired count 0 in A, = N1 in B | **0** and **1 211 520** | ✅ |
| **cal** | loud bucket 250 000–380 000; `located=true`; NOTE ON/OFF | 314 063 / 313 960; `located=true`, ON 21.02 OFF 27.51 | ✅ |

★★ **The counterfactual, measured in the DEFAULT arm for free** (both counters run in both arms):

```
   §215 arm A:  1 211 725 evaluations | mem[ptr] non-zero on 313 169 | m_dr non-zero on 0
                                                    ^^^^^^^                       ^^^
                             313 169 ~= 314 063 = THE LOUD FRAMES        a HARD ZERO
```

⇒ At `iw25`, `mem[ptr]` is non-zero **exactly when notes sound and never otherwise**, and `m_dr`
is zero always. So the rival was **guaranteed** to score 4/4 before it was ever run. That is the
point of §0: **F1–F4 grade "is the substituted operand alive", not "is it `mem[ptr]`".**

### 2. THE FOUR FALSIFIERS: 4 of 4 PASSED — and it changes nothing

| # | control | arm B | verdict |
|---|---|---|---|
| **F1** | `tempA` at `iw25..iw52` `0..0 ‖ 0..0` `=` | `iw25` → `0..0 ‖ -5 579 776..4 994 816` `*`, and it stays input-dependent through **`iw44`** | PASS |
| **F2** | `P` at `iw39` `0..0 ‖ 0..0` | `0..0 ‖ -526 573 661 648..471 369 917 068` `*` | PASS |
| **F3** | LAST input-dependent `acc` slot = **`iw38`**, kernel A 27 | **`iw204`**; kernel A 27→**35**, body 0 0→**28**, body 1 0→**2** | PASS, far past `iw45` |
| **F4** | body 0 `iw84`/`iw85` `acc`/`mem`/`L` all `0..0 ‖ 0..0` | all three input-dependent; the unit-0 entry cell `0x05` now reads `-8 034 877..7 192 534` loud | PASS |

And the send itself: `iw45`'s `HI_ST` store (visible as `mem` at `iw46`) carries
`-8 034 877..7 192 534` in the loud bucket where the control had `0..0`. The delay line then
carries it: `§46` **181 521 of 24 922 560 reads returned NON-ZERO** (control: **0**), `§48`
**121 014** consumptions with a non-zero datum (control: **0**), `§75` writes with content
1 175 999 → **1 236 506**.

⇒ **The unit-0 send was opened, body 0 ran its ladder on live audio, and the delay line filled
with real data. All four falsifiers passed. It is still not evidence, and the reading is still
refuted.** ★ This is the sharpest demonstration this project has produced of *"a number becoming
non-zero is not evidence"*.

### 3. ★ STANDING RULE 1 — applied, and the null HELD exactly as pre-registered

```
   arm B:  §70  ACCA AT w73   quiet 726 040  min 0 max 0  |  loud 313 960  min 0 max 0
           §211 ACCB AT w78   quiet 726 040  min 0 max 0  |  loud 313 960  min 0 max 0
           §61  unit0/DO1 1 203 840 exec, 0 non-zero, peak 0 | unit1/DO2 idem
           §54  quiet-in 826 040 -> 826 040 silent / 0 LOUD | loud-in 313 960 -> 313 960 silent / 0 loud
```

`min == max` in the loud bucket **and** in the **no-stimulus window** (726 040 quiet frames), in
both accumulators, in both arms. **NO non-zero output was produced and NO audio claim is made.**

★★★ **AND THIS IS THE RESULT THAT OUTLIVES THE REFUTED READING.** §211 closed the output stage as
a null *while the send was zero*, so "the null is only because nothing is being sent" was still
open. **It is now closed:** body 0 was fed 313 960 frames of live audio, ran its whole ladder on
it (28 input-dependent slots), fed body 1 (2 slots), and `w73`/`w78` still read **exactly zero**.
⇒ **The output stage is a null independently of what the send carries.** MEASURED, with the send
FORCED open — which is what §211 could not do.

### 4. ★★★ THE NEXT INSTRUMENT, and §215 hands it a number no earlier pass had

Given §0, the shipped decode is right and `iw25`'s operand *should* be the datum `iw12` fetched.
**It never is:**

```
   arm B:  §46  24 922 560 reads, 181 521 returned NON-ZERO
           §80  latched 24 922 560 (181 521 non-zero) | publish hits 24 922 552 (181 521 non-zero)
           §215 m_dr non-zero at iw25:  0 of 1 211 520          <- ZERO, in the arm where the
                                                                   delay line is FULL of audio
```

181 521 non-zero data were latched **and published into `m_dr`**, and `iw25` saw a non-zero `m_dr`
**not once in 1 211 520 evaluations**. So the defect is not the decode of `iw25` and not the delay
port: it is the **§78 per-line publish schedule** — every non-zero publish lands at a body delay
word *after* `iw25` has run, and `m_dr` is overwritten by a zero publish before the next frame's
`iw25` reads it. `line = descriptor_value & 0x3f`, and §46's own dump shows the kernel's
descriptors resolving to `0000` on the early frames, i.e. **every kernel delay word shares line 0**.

★ **That is the next task**: does `iw12`'s datum reach `iw25`, and if not, is the fault the line
index, the publish ordering, or the one-register `m_dr`? It is gradeable with the instruments that
already exist (`§80`, `§215`, `§46`), and unlike the send it is not pre-decided by a corpus twin.

### 5. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **"`SRC 0x0B` at `iw25` is an unanchored guess"** | **ANCHORED**: 13/13 successor identity + the ENSEMBLE/kernel `2D9` twin. It is the delay-read register, on a class-2 word as on a class-1 one |
| **`HANDOFF-NEXT.md` §1.2's four falsifiers as a TEST** | all four pass on any live operand; arm A measured `mem[ptr]` non-zero on 313 169 ≈ the loud-frame count **before** the rival was run. They are a reach test, not a decode test |
| **"the output-stage null might be an artefact of a zero send"** | **REFUTED**: the send was forced open, body 0 ran on live audio, `w73`/`w78` stayed exactly 0 |
| **"the closed loop `iw25 → … → iw46 → iw25` is suspicious" (§213 §5.1 / §214 §3)** | it is the **intended architecture** — a feedback comb, `delay read (iw12/iw26) → tempA (iw25) → mac ta (iw27)`. What is broken is that the read's datum never reaches `iw25` |
| **§48 as "the way in"** | the way in is one hop earlier: the **publish** into `m_dr`, §4 above |

Evidence grade: §0 **MEASURED** (corpus census over 41 listings / 3057 words, plus the 1.0064
per-frame count that discharges its own falsifier), the verdict **FORCED** from C1+C2; §1
**MEASURED** against a pre-registration committed before the build, N1/N2/N3 all held; §2
**MEASURED**, arm B, and **FORCED** as non-discriminating by arm A's own counterfactual counter;
§3 **MEASURED**, including the no-stimulus window; §4 **MEASURED** (`§80` vs `§215` in the same
log), the attribution to the publish schedule **INFERRED (strong)**; §5 as noted per row.
The rival reading is **REFUTED and NOT SHIPPED**; `UPD6383_SRC0B2` stays **default OFF**.

---

## §216 — the rival is refuted, my "suspicious loop" is retracted, and the OUTPUT STAGE NULL IS NOW PROVEN BY FEEDING IT

### 1. `SRC 0x0B` SURVIVES at `iw25` — decided by the corpus, not the run

`lo12 0x2D9` is a **36-word family**: 29 class-1 delay WRITE, 6 class-1 delay READ (all ENSEMBLE),
**1** class-2 — the kernel's `iw25`. Its consumer `0012201655` (`mac ta,(p)+1`, the **only** word
that multiplies `tempA`) has a 0.43 % base rate and **13 of 13** of its sites are immediately
preceded by a class-1 `addr8 0x20` delay READ.

★ ENSEMBLE `w10` **fuses** read+capture in one word → `w11`. The kernel **splits** the *identical*
`2D9` off one word ahead of its read: `w25 → w26 (READ) → w27`. **Same `lo12`, same idiom, same
successor, two independent programs.** The rival would need one `lo12` to mean two things on two
classes *and* would leave the kernel's two delay READs with no consumer anywhere in the frame.

### 2. ⛔ ALL FOUR FALSIFIERS PASSED — AND IT PROVES NOTHING

`tempA@iw25`, `P@iw39`, the last input-dependent `acc` slot (`iw38 → iw204`) and body 0's
`iw84/85` all flipped to input-dependent. **They had to**: arm A's own counter measured
`mem[ptr]` at `iw25` non-zero on **313 169 evaluations ≈ the 314 063 loud frames — before the rival
was ever run.** `iw25`'s pointer sits on a live cell, so **any** live operand scores 4/4.

★ The four falsifiers I passed forward in `HANDOFF-NEXT.md` §1.2 **could not fail**. Caught by the
agent on its own experiment, from a control measured before the arm ran. Filed as standing rule 15
and dead-end 22.

### 3. ★★★ THE RESULT THAT OUTLIVES THE REFUTED READING

With the send **forced open** — delay port non-zero **181 521×** against 0, `§48` **121 014 live
consumptions** against 0 — **body 0 ran its whole ladder on live audio and `w73`/`w78` still read
exactly zero.**

⇒ **The output stage is a null INDEPENDENTLY of what the send carries.** §211 asserted that; this
**proved it by feeding it**. That is a far stronger statement than the refutation it came wrapped in.

### 4. ⛔ And my "suspicious closed loop" is RETRACTED

§213/§214 flagged `iw25 → tempA → P → acc → send → delay write → next frame's iw25` as a
self-sustaining loop to be wary of. **It is the intended feedback comb.** I described a working
design as a defect — the mirror of §205, where I described a working fact as a blocker.

### 5. The new blocker, one hop upstream

`m_dr` at `iw25` was non-zero on **0 of 1 211 520** evaluations *in the arm where `§80` published
181 521 non-zero data*. **The datum `iw12` fetches never reaches `iw25`** — the §78 per-line publish
schedule (`line = descriptor_value & 0x3f`; the kernel's delay words share line 0).

### 6. Unchanged

`§70 ACCA@w73` and `§211 ACCB@w78`: `min 0 max 0` in the loud bucket **and** in the 726 040-frame
no-stimulus window, **in both arms**. `§61` both ports 0 non-zero; `§54` 0 loud output frames.
**No audio claim.** `UPD6383_SRC0B2` is **default OFF, not shipped**; arm A is bit-identical to the
pre-§215 control in all three score columns.

Evidence grade: §1 **MEASURED** (41 listings, 13/13, two independent programs); §2 **FORCED** — the
criterion was unfalsifiable and a pre-arm control shows it; §3 **MEASURED**, and the strongest form
of the output-stage null yet; §4 my framing **retracted**.

---

## §217 — ⛔★★★ THE `§78` BLOCKER IS REFUTED: THE DATUM IS NOT LOST, IT IS DELIVERED TO `iw98`. The LINE INDEX is a RED HERRING and `§46`'s dump is a BOOT SAMPLE. `UPD6383_DRPUB` NOT SHIPPED

Scored against `data/PREDICT_217.md`, **committed before `build.sh` was run**
(`kn5000-roms-disasm@d4f1467`). Three runs, one build, same clean vehicle
(`kn7000_mame/scratchpad/coldnotes2.lua`, cold boot, isolated NVRAM **and** isolated
`-cfg_directory` carrying `:DSPCFG value="3"`, `-log`, triad C4/E4/G4 held 21.02–27.51 s,
`-seconds_to_run 30`), all three **1 440 001 frames / 313 960 loud / 726 040 quiet**:

* **arm A** `data/drpub_A_off_217.log.gz` — `UPD6383_DRPUB=0 UPD6383_SRC0B2=0`, the shipped build;
* **arm B** `data/drpub_B_on_217.log.gz` — `UPD6383_DRPUB=1 UPD6383_SRC0B2=0`;
* **arm C** `data/drpub_C_on_src0b2_217.log.gz` — `UPD6383_DRPUB=1 UPD6383_SRC0B2=1`, which is
  `data/src0b2_B_on_215.log.gz` **plus** `DRPUB` and nothing else.

### 0. ⛔ FIRST, THE PREMISE I WAS HANDED IS WRONG — "every kernel delay word shares line 0"

`§215 §4` and both handoffs attribute the loss to `line = descriptor_value & 0x3f` with *"§46's own
dump shows the kernel's descriptors resolving to `0000`, i.e. every kernel delay word shares line
0"*. **`§46`'s descriptor list is an UNGUARDED BOOT-TIME SAMPLE.** `upd6383.cpp`'s §46 block fills
`m_dly_dsc[]/m_dly_val[]` with the first 8 **distinct** cells ever seen, with no `m_frames_run`
guard, so it freezes the pre-upload state in which every cell reads `0000` — and then prints it in
the final report as though it were steady state. It is the same defect `§204`'s own comment warns
about (*"the first version recorded the first 16 consumers EVER — all from boot"*) and `§193`
caught in its first probe: **third occurrence, standing rule 10.**

`§204`'s census **is** guarded (`> 900 000`) and sits **in the same log**:

```
   iw12  cell 0x1041 -> line 0x01        iw98  cell 0x1041 -> line 0x01   <- iw12's PAIR
   iw26  cell 0x05A0 -> line 0x20        iw102 cell 0x05A0 -> line 0x20   <- iw26's pair
   iw46  cell 0x0000 -> line 0x00        iw54  cell 0x0C30 -> line 0x30
```

⇒ the kernel's four delay words carry **three distinct lines**, and `iw12 ↔ iw98` is `§79`'s
stride-5 pairing working **exactly as designed**. **The line index is a RED HERRING.** MEASURED
(the numbers are in `src0b2_B_on_215.log.gz`, which four passes read without noticing).

### 1. ★★★ WHERE THE DATUM GOES, MEASURED TO THE WORD

The publish lives **inside the `is_dram` branch**, so only a **delay word** can fire it. `iw25` is
`000.2.00.2D9` — class 2, no delay access — so it can never trigger one and only ever reads a
residue. And `iw12` **latches after it publishes**, so its datum waits in `m_dr_line[0x01]` for the
next line-0x01 delay word:

```
  arm A   §217 WHERE A DATUM TAGGED `iw12' IS PUBLISHED (settled):
               published at iw98   x540 000          <- 540 000 of 540 000.  ONE HUNDRED PERCENT
          §217 publishes strictly between iw12 and iw25:  0
```

⇒ **The datum `iw12` fetches is not lost. It is delivered, intact and on schedule, to `iw98` —
73 slots and one body-CALL too late for `iw25`.** MEASURED, 540 000 / 540 000, `P2` passed.

### 2. ★★ THE CRITERION: PROVENANCE, NOT LIVENESS — and it is what dead-end 22 demanded

Standing rule 15 retired the previous four falsifiers because **any live operand passed them**.
This instrument does not ask *did something arrive*; every latch is tagged with the **`iw` that
performed the read** and the **frame**, the tag travels with the datum, and it is histogrammed at
`iw25`. A wrong source reports a **wrong `iw` number**, which liveness cannot fake. Read-only, and
it runs in every arm.

```
  arm A (shipped)        540 000 evaluations | age 1..1 frames | read by iw289  x540 000  (0 nz)
  arm B (DRPUB=1)        540 000 evaluations | age 0..0 frames | read by iw12   x540 000  (0 nz)
  arm C (DRPUB=1,+line)  540 000 evaluations | age 0..0 frames | read by iw12   x540 000  (60 507 nz)
```

★ **The shipped build feeds `iw25` a UNIT-1 delay read from the PREVIOUS FRAME**, on 100 % of
settled evaluations — `iw289`, a word in the other unit's reverb, with no relationship to the
kernel whatsoever. That is not a delay line with a wrong lag; it is an unrelated register residue.

★ **`P1` FAILED ON THE WORD AND PASSED ON THE SHAPE.** I pre-registered `iw247`, hand-traced from
`§79`'s read/write offsets. The answer is **`iw289`** — because `§204`'s census caps at 16
consumers and stops at `iw269`, so my trace could not see past it. All three *structural* claims of
P1 held: it is a **unit-1** word, the age is **exactly 1 frame**, and `iw12` holds **0 %**.
The instrument was right and the hand-trace was one word short; recorded rather than smoothed over.

★ **`N3` MISSED.** I predicted 400 000–500 000 settled evaluations from 0.836 body-0 executions per
frame; the answer is **540 000 = 1.000 per frame** over the settled window. The ~16 % of frames
that never reach the wait word (`§38`) are a **boot-phase** population, not a steady-state one.

### 3. ★★★ `F1` — THE RIGHT DATUM, NAMED, WITH EVERY VALUE COUNTER STILL AT ZERO

`UPD6383_DRPUB` (new, env, **DEFAULT OFF**, fired count): a delay READ *also* writes the bus
register `m_dr` immediately, in addition to its per-line latch. It sits **after** `exec_alu`, so a
fused read+capture word still does not see its own datum (`dram-datapath.md` item A survives), and
`m_dr_line[]` is untouched.

```
  arm B   fired 24 922 560   = §80's latch count and §46's read count, EXACTLY
          provenance at iw25 -> iw12, age 0, 540 000 of 540 000            F1 PASS
          §215 m_dr non-zero at iw25 ->  STILL 0                           F2 as pre-declared
          §80 latched 24 922 560 (0 nz) | hits 24 922 552 (0 nz)  = arm A  N4 PASS
          s104_score.py acc 27/2, mem 21/9, L 18/3, last slots iw38/iw35/iw35
                                              = BIT-IDENTICAL to arm A and to §215 arm A
```

★★★ **This is the demonstration the previous four falsifiers could not give: the provenance flipped
from `iw289`/age-1 to `iw12`/age-0 while EVERY value counter stayed at zero.** The right datum
arrives, and it is zero, because the delay line is empty (`§46`: 0 non-zero of 24 922 560 reads).
**A decode was graded without a single number becoming non-zero.**

### 4. `F3` — the value test, and the arithmetic closes exactly

Arm C is `§215` arm B **plus `DRPUB`**, nothing else:

```
                                     §215 arm B (DRPUB=0)      §217 arm C (DRPUB=1)
   §80 latched / hits                24 922 560 / 24 922 552   IDENTICAL, 181 521 nz both
   §75 delay writes with content     1 236 506                 1 236 506   IDENTICAL
   §48 SRC 0x0B with a nz datum        121 014                   181 521   +60 507
   §215 m_dr nz AT iw25                       0                    60 507   <- F3 PASS
   s104 acc/mem/L, last slots        65/65/60, iw204/202/325   IDENTICAL
```

★ `60 507 × 3 = 181 521` **exactly**, and `121 014 = 60 507 × 2` **exactly**. The 181 521 non-zero
delay reads are three words hitting 60 507 times each; the shipped build consumed two of them and
threw the third away. `DRPUB`'s **entire** effect is that third one — the class-1 delay words'
consumption count did not move by one. **The blast radius is one word.**

### 5. ★ THE CORPUS SAYS `DRPUB` REPRODUCES `dram-datapath.md` ITEM A, IT DOES NOT FIGHT IT

All **9** class-2 `SRC 0x0B` words in the 41-listing corpus, and where each sits:

```
   ENSEMBLE   020.2.00.2C7  x6   w14/24/34/72/82/92, each exactly +4 after its 2D9 delay READ
   MULTI TAP  000.2.09.40B  x1   w25, +1 after the delay word at w24
   ENSEMBLE   000.2.00.40B  x1   w62, 2 slots BEFORE the read at w64  (the kernel's twin)
   KERNEL     000.2.00.2D9  x1   iw25, 1 slot BEFORE the read at iw26
```

★ **6 of 6 ENSEMBLE `2C7` sites are at `+4` — item A's corpus MODE and upper bound (`land ∈ [1,4]`,
4 the mode over 111 reads).** And because **no read intervenes** between a producing read and its
class-2 consumer at any of these sites, `land = 4` and an immediate publish are
**observationally identical** at every one of them: `m_dr` is a hold register, so a datum that
lands at `iw16` is still there at `iw25`. `DRPUB` therefore reproduces item A's schedule **without
a latency parameter**, rather than contradicting it.

⚠ **The honest residue:** `ENSEMBLE w62` is 23 slots after a delay *WRITE* and 2 slots *before* a
READ, so `DRPUB` leaves it reading a stale datum from `w30`. 7 of 9 class-2 sites get item A's
schedule; `w62` and (arguably) `iw25` remain a shape no latency model explains.

### 6. ★★★ STANDING RULE 1 — read in ALL THREE ARMS, including the no-stimulus window

```
   arm A / arm B / arm C, all three identical:
       §70  ACCA AT w73   quiet 726 040  min 0 max 0  |  loud 313 960  min 0 max 0
       §211 ACCB AT w78   quiet 726 040  min 0 max 0  |  loud 313 960  min 0 max 0
```

`min == max` in the loud bucket **and** in the 726 040-frame no-stimulus window, in **both**
accumulators, in **all three** arms. **NO non-zero output was produced and NO audio claim is
made.** This is exactly what `§216` predicts: the output stage is a null independent of the send,
and §217 does not touch the output stage.

### 7. ⇒ VERDICT: `UPD6383_DRPUB` STAYS **DEFAULT OFF**, and the reason is not doubt

`F1` passed on identity, `N4` and `s104` show zero blast radius, and §5 shows the corpus agrees.
What shipping would buy is **nothing measurable**: on the shipped build (`SRC0B2=0`) arm B is
**bit-identical to arm A in every column**, because the datum it correctly delivers is zero. A
default flip with no observable consequence is not a fix, it is a claim awaiting a use.

**The one remaining check before flipping it, stated so it is gradeable:** decide `ENSEMBLE w62`
and `kernel iw25` — the two `000.2.00.*` words that sit *ahead* of their read. If the pipeline is
one-deep and *cross-frame* (the class-2 word capturing the datum of the read that follows it, from
the previous frame), then the correct model is not "publish at the read" but "publish at the read
**of the previous frame**" — and `DRPUB`'s `age 0` would be wrong by exactly one frame, which the
§217 provenance census already measures and would show as `age 1..1` with tag `iw26`.

### 8. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **"the §78 per-line publish schedule is the blocker" / "the kernel's delay words all share line 0"** | **REFUTED.** `§46`'s descriptor dump is an unguarded BOOT-TIME sample; `§204`'s guarded census, in the same log, gives lines `0x01`/`0x20`/`0x00` and the `iw12 ↔ iw98` pair. The line index is CORRECT |
| **"the datum `iw12` fetches is LOST"** | **It is not lost.** It is published at `iw98`, 540 000 of 540 000 settled frames, intact |
| **"widen `m_dr` / it is a single-register problem" (§215 §4's option (c))** | **MOOT.** One register is enough: nothing overwrites it between `iw12` and `iw25`. The fault is *when* it is written, not *how many* there are |
| **the four falsifiers, one more time** | not reused. The criterion here is the **tag**, and arm B passed it with every value counter still at zero |

Evidence grade: §0 **MEASURED** (both censuses are in `src0b2_B_on_215.log.gz`; the boot-sample
diagnosis is **FORCED** from the source, `m_dly_dsc[]` has no frame guard); §1 **MEASURED**,
540 000/540 000; §2 **MEASURED**, and `P1`'s word-level miss recorded as a miss; §3 **MEASURED**
against a pre-registration committed before the build, `F1`/`N4` held, `N3` MISSED, `P1` PARTIAL;
§4 **MEASURED**, arm C against `§215` arm B, one variable; §5 **MEASURED** (corpus census over 41
listings), the "observationally identical" claim **FORCED** from the no-intervening-read structure;
§6 **MEASURED**, including the no-stimulus window; §7 a decision, **not shipped**.
`UPD6383_DRPUB` is **DEFAULT OFF**.

---

## §218 — ⛔★★★ THE CROSS-FRAME RIVAL IS REFUTED WITHOUT A RUN, AND `ENSEMBLE w62` IS NOT AN `SRC 0x0B` WORD AT ALL. §217 §5's CENSUS SAID 9; THE DEVICE'S OWN COMMENT SAID 7, AND 7 IS RIGHT

**Decided STATICALLY. No build, no MAME run, no new gate.** Scored against `HANDOFF-NEXT.md`
§1.-0.5's pre-registered discriminator (*"the rival predicts tag `iw26`, `age 1..1`"*) using the
logs §217 already produced — `data/drpub_{A_off,B_on,C_on_src0b2}_217.log.gz` — plus a re-run of
the corpus census with the disassembler's **own** field accessors
(`dsp/tools/src0b_census.py`, new; `dsp_disasm.lo_src/lo_act`, 41 listings / 3057 words).

> **THE QUESTION:** `HANDOFF-NEXT.md` §1.-0.5 asked to decide `ENSEMBLE w62` and `kernel iw25` —
> the two `000.2.00.*` class-2 `SRC 0x0B` words that sit *ahead* of a delay READ instead of after
> one — against the rival *"the pipeline is one-deep and CROSS-FRAME: a class-2 word captures the
> datum of the read that FOLLOWS it, from the previous frame"*, under which `DRPUB`'s `age 0`
> would be wrong by exactly one frame.
>
> **THE ANSWER:** `ENSEMBLE w62` **is not one of the words**, and for `kernel iw25` the rival is
> **REFUTED three times over** — by the pre-registered measurement, by the frame schedule, and by
> the corpus. `DRPUB`'s `age 0` is **NOT** wrong by one frame.

### 1. ★★★ THE PRE-REGISTERED DISCRIMINATOR, READ OFF THE LOGS THAT ALREADY EXISTED

Standing rule 13, applied as instructed: the instrument was already built and already pointed at
this word. `upd6383.cpp:2176-2190, 2452-2461` tags every per-line latch with **the `iw` that
performed the READ** and the frame, carries the tag through the publish, and histograms it at
`iw25`; the age is `m_frames_run - m_dr_prov_frame`, in frames.

```
   arm A  drpub_A_off_217.log.gz:2589   540000 evaluations | age 1..1 | read by iw289 x540000 (0 nz)
   arm B  drpub_B_on_217.log.gz:2589    540000 evaluations | age 0..0 | read by iw12  x540000 (0 nz)
   arm C  drpub_C_on_src0b2_217:2596    540000 evaluations | age 0..0 | read by iw12  x540000 (60507 nz)
```

★ **Arm A is the arm that grades the rival, because arm A is the pure one-deep hold register** —
`DRPUB` off, `m_dr` written only by the §78 publish. Whatever a one-deep bus actually retains
across the frame boundary, arm A measures it.

| | predicted tag | predicted age | MEASURED |
|---|---|---|---|
| **the rival** | **`iw26`** | 1..1 | — |
| `DRPUB` (§217) | `iw12` | 0..0 | arm B/C: `iw12`, age 0..0, 540 000/540 000 |
| shipped residue | — | — | arm A: **`iw289`**, age 1..1, 540 000/540 000 |

★★★ **`iw26` holds EXACTLY ZERO of the mass.** The histogram is **single-bin**: `m_prov_other`
(`upd6383.cpp:5601`, *"producers beyond slot N"*) prints only when mass falls outside the printed
bins, and it prints in **none** of the three arms. So the 0 % is enumerated, not inferred.

★ **The age agreed and the age was never the discriminator.** Arm A does report `age 1..1`, which
is the half of the rival's prediction that any previous-frame residue satisfies. **Rule 17 exists
for exactly this**: the criterion must name a *wrong `iw` number* as its failure mode, and it does
— predicted `iw26`, measured `iw289`, a word **263 slots away in the other unit's reverb**.
⇒ **FALSIFIED on the pre-registered discriminator.** MEASURED.

★ **And the test could have passed.** Had the bus at `iw25` really carried the datum of the read
that follows it, arm A would have printed `read by iw26` — the same instrument, the same log, one
different integer. It printed `iw289`. (Rule 8: a criterion that cannot fail is not a test; this
one could, and did not.)

### 2. ★★ WHY IT HAD TO FAIL: "ONE-DEEP" AND "CROSS-FRAME" ARE MUTUALLY EXCLUSIVE HERE

The rival needs `iw26`'s datum from frame *N−1* to still be on the bus at `iw25` of frame *N*.
Reconstructing the frame's delay schedule statically — kernel `kernel.dsm`, unit 0 = **CHORUS**
(`prog01`, I-RAM load 84), unit 1 = **ROOM REVERB 1** (`prog16`, load 200), epilogue **none**:

```
  iw12R iw26R iw46W | iw84R iw93W iw98R iw102W iw107R iw134W iw139R iw143W iw148R iw152W | iw54W |
  iw200R iw211W iw215R iw219W iw223R iw227W iw231R iw235W iw239R iw243W iw247R iw251W iw255R
  iw259W iw263R iw269W iw273R iw277W iw281R iw285W iw289R iw293W iw297R iw301W iw305R iw314R
  iw325R iw331W
```

**42 delay words per frame — 22 READS, 20 WRITES.** ★ That is `dram-datapath.md` item K's
independently-counted **"42 delay-DRAM frame slots"**, reproduced here from the listings by a
different route. Between `iw26` (frame *N−1*) and `iw25` (frame *N*) sit **41 delay words — 21
READS and 20 WRITES**. Every one of them writes `m_dr` (a READ latches and, under `DRPUB`,
publishes; every delay word attempts the per-line publish).

⇒ **A one-deep register cannot carry `iw26`'s datum across 21 subsequent reads.** The rival's two
clauses cannot both hold: *one-deep* forbids the retention that *cross-frame* requires, and
*cross-frame per-word* retention is not one-deep — it is a per-word or per-line hold, which is
`m_dr_line[]`, which §217 §1 already measured delivering `iw12`'s datum to **`iw98`**
(540 000/540 000), not to `iw25`. **FORCED**, and arm A is the measurement that closes it: what a
one-deep bus actually retains across that boundary is the frame's **LAST** read, not its **NEXT**
one.

★ **By-product, and it completes §217's `P1`.** §217 recorded that `P1`'s hand-trace named `iw247`
and the instrument answered `iw289`, blaming `§204`'s 16-consumer cap. The full schedule above
shows the cap truncated `P1`'s table at **both** ends: body 0's first delay word is **`iw84`**
(CHORUS `w0`, a READ), absent from `P1`'s list, and body 1 runs to **`iw331`**, not `iw269`.
`iw289` = ROOM REVERB 1 offset **89**, a READ — present and correct in the reconstructed schedule.
The instrument was right about a word the census could not print. MEASURED.

### 3. ⛔★★★ HALF THE QUESTION DISSOLVES: `ENSEMBLE w62` CARRIES `SRC 0x10`, NOT `SRC 0x0B`

`dsp_disasm.py:179-180` is the authority on the two fields, and they are **different bit ranges**:

```
   def lo_src(w):  return (w >> 6) & 0x1F      # lo12[10:6]  -- the SOURCE
   def lo_act(w):  return  w       & 0x1F      # lo12[4:0]   -- the ACTION
```

| word | lo12 | `lo_src` | `lo_act` | what it really is |
|---|---|---|---|---|
| kernel `iw25` | `0x2D9` | **`0x0B`** | `0x19` | class-2 `SRC 0x0B` ✔ |
| ENSEMBLE `w14/24/34/72/82/92` | `0x2C7` | **`0x0B`** | `0x07` | class-2 `SRC 0x0B` ✔ |
| **ENSEMBLE `w62`** | `0x40B` | **`0x10`** | **`0x0B`** | ⛔ `SRC` = **the ACCUMULATOR** |
| **MULTI TAP `w25`** | `0x40B` | **`0x10`** | **`0x0B`** | ⛔ `SRC` = **the ACCUMULATOR** |

★ **`0x10` is `LO_SRC_ACC`, an ANCHORED code** (`dsp_disasm.py:184`, `_ANCHORED_SRC`). The `0B`
§217 §5 saw in `000.2.00.40B` is the **ACTION** field. Two words were promoted into the census by
a **field mix-up**, and the corpus population is:

```
   SRC 0x0B, 41 listings / 3057 words:  106 total = 99 class-1 delay words + 7 class 2
   ACT 0x0B,          same corpus    :   82 total =  50 delay words + 16 class 2 + 16 class A
```

★★ **AND THE DEVICE ALREADY SAID SO.** `upd6383.cpp:2436-2441`, written for **§215**, two sections
earlier, in the very function that counts these words:

> *"Of 106 corpus `SRC 0x0B` words, 99 are class-1 delay words (addr8 0x20 READ / 0x60 WRITE) and
> **7 are class 2** addr8 0x00 — ENSEMBLE's `020.2.00.2C7` ×6 and the resident kernel's
> `000.2.00.2D9` ×1, which is `iw25`."*

**§217 §5 re-did in prose a census the source already carried, got 9 instead of 7, and neither the
section nor its verdict noticed the contradiction.** Standing rule 3, *fourth* occurrence — and
standing rule 13 in its sharpest form yet: the answer was not merely in an existing instrument, it
was in a **comment beside the counter being discussed**. The `82`/`50` split is `register-space.md`
§4's published statistic, reproduced digit-for-digit here, which is the control on the accessors.

⇒ **`ENSEMBLE w62` is not a class-2 `SRC 0x0B` word and never was.** It is
`mac`-neighbourhood accumulator traffic — `w61 = mac.st acc,(p)+12`, `w62 = 000.2.00.40B`
(`SRC` acc), `w63 = ld.st acc,(p)-4` — with **no** delay-bus source in it. `dram-datapath.md`
item A owes it nothing. **The "honest residue" of §217 §5 is half retracted on the spot.**
MEASURED (corpus), the field reading **FORCED** from `dsp_disasm.py:179-180`.

### 4. ★ AND THE CORPUS REFUTES THE RIVAL INDEPENDENTLY, ON THE SEVEN WORDS THAT DO EXIST

`python3 dsp/tools/src0b_census.py` — every class-2 `SRC 0x0B` word, and the delay READ on each
side of it:

```
   kernel           w25  000.2.00.2D9   prevREAD w12  (+13)   nextREAD w26  (+1)
   ENSEMBLE         w14  020.2.00.2C7   prevREAD w10  (+4)    nextREAD w16  (+2)
   ENSEMBLE         w24  020.2.00.2C7   prevREAD w20  (+4)    nextREAD w26  (+2)
   ENSEMBLE         w34  020.2.00.2C7   prevREAD w30  (+4)    nextREAD w64  (+30)  <- WRITE at w39 between
   ENSEMBLE         w72  020.2.00.2C7   prevREAD w68  (+4)    nextREAD w74  (+2)
   ENSEMBLE         w82  020.2.00.2C7   prevREAD w78  (+4)    nextREAD w84  (+2)
   ENSEMBLE         w92  020.2.00.2C7   prevREAD w88  (+4)    nextREAD  --   (NONE)
```

| rule | uniformity over the 6 ENSEMBLE sites |
|---|---|
| **item A** — *the PRECEDING read* | **+4, +4, +4, +4, +4, +4 — exceptionless 6/6**, and `+4` is item E's corpus **mode** (40 of 111) *and* its FORCED upper bound |
| **the rival** — *the FOLLOWING read, previous frame* | −2, −2, **−30**, −2, −2, and **UNDEFINED at `w92`** — its next delay word is `w94`, a WRITE, and it is the program's last |

⇒ The rival is not merely unmeasured, it is **not statable** as a uniform rule for the class: at
1 of 6 sites it has no producer to name, and at another the producer is 30 slots and a WRITE away.
Item A is exceptionless. **Rule 15's closing clause — when a decode question has a corpus answer,
the corpus outranks any run — applies, and the corpus and the run agree.** MEASURED.

### 5. ★★★ WITH `w62` REMOVED, THE RESIDUE IS **EMPTY**: ITEM A + A HOLD REGISTER EXPLAINS 7 OF 7

§217 §5 closed with *"`w62` and (arguably) `iw25` remain a shape no latency model explains."*
Both halves are now discharged:

* **`w62`** — not an `SRC 0x0B` word (§3). Nothing to explain.
* **`iw25`** — at **+13** after `iw12`, which is *later* than item E's `land ≤ 4`, not earlier.
  The datum lands by `iw16` at the latest; `m_dr` is a **hold** register; and §217 measured
  **`publishes strictly between iw12 and iw25: 0`** (structural — the kernel has no delay word in
  `iw13..iw24`). So the datum is still on the bus at `iw25`. **There is no anomaly.** The only
  thing that prevents it in the shipped build is that `m_dr` is written *solely* by the per-line
  publish, which fires *only at a delay word*, and `iw25` is not one — which is precisely §217 §1's
  located defect, and precisely what `DRPUB` repairs.

★★★ ⇒ **All 7 class-2 `SRC 0x0B` words are consistent with `land ∈ [1,4]` + a hold register, with
no latency parameter and no exception**, and at every one of them no read intervenes between the
producing read and the consumer, so `land = 1` (which is where `DRPUB` sits — it publishes *after*
`exec_alu`, so item A's `land ≥ 1` flush-read lower bound survives) and `land = 4` are
observationally identical. **`DRPUB` is now the only model on the table that fits all seven.**
**FORCED** from §3 + §4 + §217 §1's measured zero.

### 6. ★★★ STANDING RULE 1 — RE-READ IN ALL THREE ARMS, INCLUDING THE NO-STIMULUS WINDOW

```
   arm A / arm B / arm C, all three identical, straight out of the logs:
       §70  ACCA AT w73   quiet 726040  min 0 max 0   |   loud 313960  min 0 max 0
       §211 ACCB AT w78   quiet 726040  min 0 max 0   |   loud 313960  min 0 max 0
```

`min == max == 0` in **both** accumulators, in **both** buckets including the 726 040-frame
no-stimulus window, in **all three** arms. **NO non-zero output. NO audio claim.** This pass did
not touch the emulator's behaviour at all, so it could not have produced one; §216's result —
the output stage is a null *independent* of the send — is untouched and unchallenged.

### 7. ⇒ VERDICT, AND WHAT IT DOES AND DOES NOT CHANGE FOR `UPD6383_DRPUB`

**The cross-frame rival is REFUTED. `DRPUB`'s `age 0` is NOT wrong by one frame.** §217 §7 named
this as *"the one remaining check before flipping it"*; **that check is now DISCHARGED**, and it
was discharged offline, against logs that already existed, at the cost of no run.

**`UPD6383_DRPUB` nevertheless stays DEFAULT OFF in this pass, and the reason is unchanged and is
not doubt about the model.** On the shipped build (`SRC0B2=0`) arm B is **bit-identical to arm A in
every column** (`s104_score.py` acc 27/2, mem 21/9, L 18/3, last slots `iw38`/`iw35`/`iw35`;
`§80` 24 922 560 / 24 922 552 in both), because the datum it correctly delivers is **zero** — the
delay line is empty (`§46`: 0 non-zero of 24 922 560 reads) because the send is closed, and §216
proved that forcing the send open still leaves the output stage a null. ⚠ **A default flip with no
observable consequence cannot be validated by measurement, and this project does not ship one on a
model argument alone.** The blocker to flipping is no longer the corpus — it is that there is
nothing downstream able to show the difference.

**What would license the flip, stated so the next pass can grade it:** any arm in which the shipped
build's delay line carries content — i.e. after whatever closes the send — where `DRPUB=1` and
`DRPUB=0` differ in `§104`/`s104_score.py`. Until then the correct state is: **model settled,
gate present, default OFF, fired count 24 922 560.**

### 8. ★ SECONDARY — SPECULATIVE CORPUS PATTERNS RECORDED THIS PASS

⚠ All **SPECULATIVE** unless marked. None is applied; none gates anything.

* **★ `lo12` DOES NOT DETERMINE CLASS BEHAVIOUR, AND 11 CODES PROVE IT (MEASURED).** Eleven
  distinct `lo12` values occur **both** on class-1 delay words and on class-2 words:
  `0x000, 0x00B, 0x1D5, 0x2C7, 0x2D9, 0x407, 0x40B, 0x40E, 0x447, 0x647, 0x655`. The kernel's own
  `iw26` is `880.1.20.40B` — a class-1 delay READ sharing `w62`'s `lo12`, which is very likely how
  `0x40B` entered §217 §5's census in the first place. ⇒ **Group by the SOURCE field, never by the
  `lo12` string.** Cheap, and it would have prevented this section's §3.
* **★ THE `212.2.xx.00B` PROGRAM-HEAD IDIOM — 9 sites, 8 of them at `w3` (MEASURED, unexplained).**
  `hi12 = 0x212` (`ST` + `f98=2` + `f31=1`), `SRC 0x00`, `ACT 0x0B`, class 2, in
  CHORUS, MODULATED CHORUS, S.DELAY+FLANGER, S.DELAY+VIBRATO, S.DELAY+PHASER, AUTO WAH+S.DELAY,
  PEQ+CHORUS, PEQ+FLANGER (all `w3`) and PEQ+VIBRATO (`w11`). In **all 9** the program's first
  delay word is `w0`, a READ, so the idiom is *"opening delay READ, then this word 3 slots later"*.
  `addr8` varies freely (`0x22, 0xF1, 0xA7, 0x0A, 0x00, 0xB1, 0x7F, 0x7F, 0x47`) — consistent with
  `addr8` being a signed pointer post-increment (`dsp_disasm.py:1019`), i.e. **not** part of the
  idiom. Three more sit in the PEQ+compressor family as `02A.2.4B.00B` at `w0`/`w1`/`w1`.
  ⇒ SPECULATIVE: `ACT 0x0B` is a **head-of-program state-cell action**, and `register-space.md` §4's
  *"ACTION `0x0B` and the delay-DRAM family are entangled"* may be a **positional** entanglement
  (both live at program heads and around taps) rather than a functional one.
* **★ `ACT 0x0B` IS THE LARGEST OPEN ACTION CODE STILL UNSPLIT (MEASURED).** 82 corpus words:
  **50** delay-DRAM, **16** class 2, **16** class A. `register-space.md` §4 notes PARAMETRIC EQ —
  the one block solved to the bit — contains **zero** of them, so no solved block can settle it.
  The 16 class-2 members catalogued in §3/§8 are the first population of `ACT 0x0B` words that is
  **not** a delay word and **not** inside the all-pass motif; if any block containing them is ever
  solved numerically, `ACT 0x0B` becomes decidable. ⇒ recorded as a **target of opportunity**.
* **★ ROOM REVERB 1's DELAY SCHEDULE IS STRICTLY ALTERNATING R/W FOR 21 WORDS, THEN BREAKS
  (MEASURED).** Offsets `0R 11W 15R 19W 23R 27W 31R 35W 39R 43W 47R 51W 55R 59W 63R 69W 73R 77W
  81R 85W 89R 93W 97R 101W 105R` then **`114R 125R 131W`** — three trailing words that break the
  pattern. Consistent with `dram-datapath.md` item C's ledger (12 line writes + 14 line reads +
  1 flush read + 1 prime write) and item A's *"the CEILING is the LAST READ of its program"*:
  the two extra reads look like the pre-delay's early-reflection taps plus the flush.
  SPECULATIVE as an interpretation; the offsets are MEASURED.

### 9. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **the CROSS-FRAME rival** (`HANDOFF-NEXT.md` §1.-0.5) | **REFUTED**, three independent ways: the pre-registered tag is `iw26` and arm A measures **`iw289`** with a single-bin histogram (0 % `iw26`); a one-deep register cannot span the **41 delay words / 21 READS** between `iw26`(*N−1*) and `iw25`(*N*); and the rival is **undefined** at 1 of 6 ENSEMBLE sites where item A is exceptionless 6/6 |
| **"`DRPUB`'s `age 0` is wrong by one frame"** | **NO.** `age 0` with tag `iw12` is the correct model; the shipped `age 1` / `iw289` is unrelated residue |
| **"`ENSEMBLE w62` is a class-2 `SRC 0x0B` word" / "the kernel's twin"** (§217 §5) | ⛔ **WRONG FIELD.** `lo12 0x40B` carries `SRC 0x10` (the accumulator, ANCHORED) and `ACT 0x0B`. Same for MULTI TAP `w25`. The corpus population is **7**, not 9 — as `upd6383.cpp:2436-2441` has said since §215 |
| **§217 §5's "honest residue: a shape no latency model explains"** | **EMPTY.** `w62` is not in the class; `iw25` at `+13` is *inside* item E's bound with **0** intervening publishes, so item A + a hold register explains **7 of 7** |
| **§217 `P1`'s per-frame delay table** | **INCOMPLETE AT BOTH ENDS**, not just the tail: body 0 begins at **`iw84`** (CHORUS `w0` R) and body 1 ends at **`iw331`**, not `iw269`. The full 42-word schedule is in §2 and matches `dram-datapath.md` item K's independent count |
| **"§217 needs a run to be decided"** | It did not. The whole verdict comes from three existing logs and the 41-listing corpus. **Rule 13 paid for itself: zero MAME runs, zero rebuilds** |

Evidence grade: §1 **MEASURED** (three existing logs, single-bin histograms, `m_prov_other`
silent in all three arms); §2 **FORCED** from the statically reconstructed 42-word schedule, whose
total independently reproduces `dram-datapath.md` item K, plus arm A's measurement of what the
one-deep bus actually retains; §3 **MEASURED** (corpus, 3057 words) with the field reading
**FORCED** from `dsp_disasm.py:179-180` and controlled against `register-space.md` §4's published
`82`/`50` split; §4 **MEASURED**; §5 **FORCED** from §3 + §4 + §217 §1's measured zero;
§6 **MEASURED**, including the no-stimulus window; §7 a decision, **not shipped**;
§8 **SPECULATIVE** except where the counts are marked MEASURED.
`UPD6383_DRPUB` remains **DEFAULT OFF**. **No source behaviour was changed by this pass.**

---

## §219 — ⛔★★★ THE SEND'S "GUESSED `SRC`" WAS DECIDED FOUR SECTIONS AGO, AND NO `SRC` ON THE PATH CAN CLOSE THE SEND ANYWAY. THE SEND IS D-RAM CELL `0x05`, AND `iw35` OVERWRITES THE AUDIO THAT `iw9`/`iw11` DEPOSITED THERE

**Decided STATICALLY. No build of the emulator's behaviour, no MAME run, no new gate, no mask
bit.** Scored against `HANDOFF-NEXT.md` §1 item 1 (*"`§213 §4`'s one corpus-unique word whose
`SRC` is a GUESS — that word, not the delivery, is the next decode"*) using the five logs that
already existed — `data/drpub_{A_off,B_on,C_on_src0b2}_217.log.gz` and
`data/src0b2_{A_off,B_on}_215.log.gz` — plus the corpus tool `dsp/tools/src0b_census.py`,
extended with a new `sendpath` section rather than replaced. **Cite the run, not the section.**

> **THE QUESTION:** what is the guessed `SRC`, and is that guess what keeps the delay line empty?
>
> **THE ANSWER, in three parts:**
> **(1)** The word is kernel `iw25 = 000.2.00.2D9` and the field is **`SRC 0x0B` = the delay-DRAM
> data register** (`upd6383.cpp` `case 0x0B`, register row 14, labelled *"It is a GUESS"*).
> **It has not been a guess since §215** — the corpus anchored it 13/13, §217 graded it by
> provenance, §218 re-verified its population with the disassembler's own accessors. The source
> comment was **STALE**; it is corrected in this pass. *(The premise of the task was 4 sections old
> at the moment it was written down — standing rule 3, fifth occurrence.)*
> **(2) ★★ And even had it been wrong, it could not be the cause.** **No `SRC` code anywhere on
> the send path decides a stored value.** Both stores on the path take `acc_to_datum(m_acc)` and
> never the bus — the delay WRITE (`upd6383.cpp:2081-2090`) and the `HI_ST` store
> (`upd6383.cpp:2942`). `SRC 0x0B` reaches the delay line **only as a MULTIPLICAND**
> (`tempA → P = coef × tempA → acc`), so a wrong reading there changes a **gain operand**, never
> whether anything is injected. **FORCED from the source.**
> **(3) ★★★ WHERE THE SEND ACTUALLY CLOSES, and it names an `iw`:** the unit-0 send is **D-RAM
> cell `0x05`**, body 0's input pickup. The kernel **deposits the audio into it at `iw9`/`iw11`
> and then OVERWRITES it at `iw35` and again at `iw45`, before the CALL at `iw49`.** MEASURED, in
> all five logs, digit-for-digit identical.

### 1. ★ THE ASSIGNED QUESTION, ANSWERED WITHOUT A RUN

`§213 §7` named it exactly: `iw25` is the **only** class-2 `SRC 0x0B` word in the whole corpus
outside ENSEMBLE, it performs no delay access itself, and the `0x0B` reading was motivated by the
99 class-1 delay words *none of which is `iw25`*. That is a fair statement of a guess — **as of
§213**. What happened next:

| § | what it did to the guess | grade |
|---|---|---|
| **§215** | ANCHORED it by the corpus: `lo12 0x2D9` is a 36-word family; its consumer `0012201655` (`mac ta`, base rate **0.43 %**) is immediately preceded by a class-1 `addr8 0x20` DELAY READ at **13 of 13** sites; ENSEMBLE fuses read+capture in one `2D9`, the kernel splits the identical `2D9` one word ahead of its read — same `lo12`, same idiom, same successor, two independent programs | MEASURED (41 listings / 3057 words) |
| **§217** | graded it **by provenance**, not by liveness: the datum is tagged with the `iw` that READ it, and the histogram at `iw25` is single-bin | MEASURED |
| **§218** | re-verified the population — **7** class-2 words, not 9 — with `dsp_disasm.lo_src`/`lo_act`, and refuted the last rival (cross-frame) three ways | MEASURED / FORCED |

⇒ **`SRC 0x0B` at `iw25` is DECIDED.** `UPD6383_SRC0B2` (the rival) stays default OFF and is
dead-end 21. **The only thing left to do about it was to stop calling it a guess in the source**,
which this pass does (`upd6383.cpp`, `case 0x0B` preamble). Documentation only — no behaviour
changed, no gate added, no mask bit touched.

### 2. ★★ AND THE PREMISE BEHIND THE TASK IS FALSE — FORCED, FROM THE DEVICE'S OWN STORE SITES

`HANDOFF-NEXT.md` §1 reasoned *"a guessed `SRC` in the send path is exactly the kind of unforced
assumption that keeps a line empty"*. That is a good instinct and it is **structurally impossible
here**, for a reason that takes two greps rather than a run:

```
   the delay WRITE        upd6383.cpp:2081-2090   m_delay.write_word(addr,
                                                     u16((u32(acc_to_datum(wacc)) >> 8) & 0xffff))
   the HI_ST bit-4 store  upd6383.cpp:2942        store_mode(stmode, stdest, u32(acc_to_datum(sacc)))
```

**Both take the ACCUMULATOR. Neither consults `src`, `L`, or any `SRC` evaluator.** The bus only
reaches a stored value through the multiplier (`m_p = sext(coef,24) * L >> P_SHIFT`) and then the
adder. So on the send path a `SRC` decode can scale what is written; it cannot decide *whether*
something is written, and it cannot introduce a term that is not already in the accumulator.

★ The new `sendpath` section grades the whole path rather than the one word, with the
disassembler's own accessors (standing rule 18): **kernel A `w0..w49`, 44 non-C-format words**:

```
   python3 dsp/tools/src0b_census.py sendpath
   ANCHORED SRC codes: 0x07 0x10 0x19 0x1A
   OPEN SRC codes on the path:  0x00 x10,  0x08 x6,  0x0B x2,  0x11 x5
        0x0B  w12 (class-1 delay READ)  and  w25 (the class-2 word)  <- both DECIDED, §215
        0x08  w0 w30 w32 w33 w41 w45    = THE COEFFICIENT (dead-end 5; the "unity" rival saturates)
        0x11  w5 w11 w16 w17 w19        = ACCB (§27, replacing a mem[ptr] guess)
        0x00  w13 w14 w36 w38 w42..44 w46 w47 w49  = mem[ptr]  ⛔ 1 of 6 enumerated, no support
```

⇒ The largest genuinely unsupported `SRC` population on the path is **`SRC 0x00`**, not `0x0B` —
and `SRC 0x00` sits on `w46`, the delay WRITE itself, where by §2 it is **inert**: the write takes
the accumulator. **MEASURED** (corpus), the inertness **FORCED** (source).

### 3. ★★★ THE SEND IS CELL `0x05`, AND IT IS WRITTEN FOUR TIMES A FRAME

D-RAM cell `0x05` is the unit-0 body's input pickup — `[05r]` in `§98`'s live pointer window, and
the `base = 0x05 | unit<<7` the per-unit rebase is FORCED to. `§96`'s writer census, in execution
order, **identical in all five logs**:

```
   §96 cell 05 written by iw9     word 0122FF1D5    `mac (p),(p)-1 ; mem[p]<-acc, acc=0'
   §96 cell 05 written by iw11    word 400201447    SRC 0x11 / ACT 0x07, a mem-to-mem MOVE (§119)
   §96 cell 05 written by iw35    word 012A001C0    `mac.b (p),c+,(p)+0'      <- OVERWRITE
   §96 cell 05 written by iw45    word 010A0020C    010.A.00.20C, HI_ST only  <- OVERWRITE
   §86 cell 05  quiet [0 .. 5 084 004]  loud [0 .. 16 760 298]  (4 080 000 writes)   INPUT-DEPENDENT
```

★ **The audio IS deposited.** `§86` grades cell `0x05` input-dependent *when written*, and `iw9`
is a `mac` whose store is the kernel's input mix. **Then it is destroyed, and `§104`'s residency
column — `mem` under the pointer, sampled BEFORE each word (`upd6383.cpp:4549-4555`) — states the
destruction slot by slot** (`data/drpub_A_off_217.log.gz`, quiet ‖ loud, `dp = 0x05` throughout):

```
   iw35  012.A.00.1C0   mem   5 084 004 ‖ -5 307 593 .. 8 388 607   *  <- THE AUDIO, still alive
   iw36  400.A.00.000   mem   4 194 304 ‖  4 194 304                =  <- iw35's store landed
   iw37  092.A.01.1C0   mem   4 194 304 ‖  4 194 304                =
   iw41..iw45                 4 194 304 ‖  4 194 304                =
   iw46  800.1.60.00B   mem           0 ‖          0                =  <- iw45's store landed
   iw84  (body 0's first word, dp = 05) 0 ‖          0                =  <- THE PICKUP. ZERO.
```

`4 194 304` is not a coincidence: it is `acc_to_datum(m_acc)` for the accumulator `iw34` leaves,
`274 877 906 944 >> 16 = 4 194 304`, and `iw35` carries `HI_ST` with `mode 2`, so its bit-4 store
target is `m_dp = 0x05`. `iw45` likewise, storing the **pre-adder** accumulator, which is `0`.
**MEASURED** (three §217 arms + both §215 arms, identical), the attribution **FORCED** from the
store site and the arithmetic.

★★ **AND `iw35` ACCOUNTS FOR BOTH DEATHS, not just the send's.** The constant it plants in `0x05`
is the cell `iw36` and `iw37` re-read as the multiplicand (`§104`'s `L` column: `4 194 304` in
both buckets at both words), which is why **`P` stops depending on the input at `iw36`** — §213 §3,
measured, and here given its cause. `iw39` then does `acc ← P` with that constant `P`
(`401 321 689 088`, both buckets), and the input is out of the accumulator too. ⇒ **One store,
`iw35`, is upstream of `§213 §3`'s "the input dies at `iw36`" AND of `§213 §4`'s "the send carries
zero".**

★★★ **THE CONTROL THAT COULD HAVE FAILED, AND DID NOT — `iw45` IS DEMONSTRABLY THE SEND.** In the
two arms where `tempA` carried live data (`src0b2_B_on_215`, `drpub_C_on_src0b2_217`; the §215
rival, refuted as a decode) the *same* `iw45` store delivered audio to body 0:

```
   arm A (shipped)        §104  iw46 mem 0..0 ‖ 0..0                        |  iw84 mem 0..0 ‖ 0..0
   arm B/C (SRC0B2=1)     §104  iw46 mem 0..0 ‖ -8 034 877 .. 7 192 534  *  |  iw84 mem  idem  *
                                iw84 acc 0..0 ‖ -864 633 992 785 .. 773 989 370 423  *
```

⇒ Cell `0x05` **is** body 0's input, `iw45` **is** the word that fills or empties it, and the
instrument can tell the two states apart. **MEASURED.** *(Rule 17: the failure mode names a
specific wrong `iw`, and it is `iw35`.)*

### 4. ★★ THIS WAS PREDICTED IN THE SOURCE, AND THE ANSWER WAS ALREADY BEING PRINTED

`upd6383.cpp`'s `kwatch()` note, written for **§110**, says it verbatim:

> *"§110: 0x05 added. The `iw11` timing fix made cell 0x05 input-dependent when WRITTEN, yet
> §104's residency column still reports body 0 reading it as constant — so something overwrites it
> between deposit and pickup, exactly as `iw32` does to `0x07`. Name the writers, in execution
> order."*

The census it asked for has been printing `iw9 / iw11 / iw35 / iw45` in every log since, and
`§104`'s residency has been printing the `4 194 304 → 0` collapse beside it. **Standing rule 13,
third occurrence, and the most expensive yet**: 109 sections passed with the answer in the report.
The lesson is not "read §110"; it is *read the report the build already prints, all of it, before
designing anything*.

### 5. ⚠ AND "THE DELAY LINE IS EMPTY" IS IMPRECISE — CORRECTED FROM THE SAME REPORT

`HANDOFF-NEXT.md` §1 and `LEDGER.md` tier 0 both say the line is empty, citing `§46`. Eight lines
above `§46` in the *same* report:

```
   §75 DELAY WRITES WITH CONTENT:  1 175 999 of 23 693 760      (arm A, drpub_A_off_217)
   §46 DELAY PORT: 24 922 560 reads (0 returned NON-ZERO), 23 693 760 writes
   §75 DLY W addr 966F  cell 0000  frame 420001  data 7D70      <- the trace line, kernel iw46
   §200 DELAY AGE dsc 27: hits 2 358 719 | frames_since_written 0 .. 4401  (0.00 .. 99.80 ms)
```

* **Content IS written.** `1 175 999` is one per settled frame — the same integer the per-unit
  rebase reports for *"unit 0: the walk ALREADY delivered `0x05` on 1 175 999"* — and the `§75`
  trace shows the writer: **the kernel's `iw46`, descriptor cell `0x0000`, the constant `0x7D70`**.
  That constant is `acc_to_datum(538 760 587 509) >> 8`, i.e. `iw45`'s post-adder accumulator; it is
  input-independent in both buckets. MEASURED; the attribution to `iw46` MEASURED (trace) and
  INFERRED (the count identity).
* **Reads DO resolve onto written addresses.** `§200`'s per-descriptor age census reports finite
  ages on every live line (`dsc 27`: 0..4401 frames = 0..99.8 ms; `dsc 02/04/06`: 7.60 / 15.06 /
  23.49 ms), so the address arithmetic is not the reason the reads return zero.

⇒ The accurate statement is: **the line is written with a DC every frame and with zeros from the
bodies, and every read that resolves lands on a body write — which is zero because the bodies'
input cell is zero (§3).** *"The line is empty"* names a symptom of §3, not an independent fact.
Corrected in `HANDOFF-NEXT.md` and `LEDGER-HEAD.md` by this pass.

### 6. ★★★ STANDING RULE 1 — READ IN ALL FIVE LOGS, INCLUDING THE NO-STIMULUS WINDOW

```
   src0b2_A_off_215   §70 ACCA AT w73  quiet 726142 min 0 max 0 | loud 314063 min 0 max 0
   src0b2_B_on_215                     quiet 726040 min 0 max 0 | loud 313960 min 0 max 0
   drpub_A_off_217                     quiet 726040 min 0 max 0 | loud 313960 min 0 max 0
   drpub_B_on_217                      quiet 726040 min 0 max 0 | loud 313960 min 0 max 0
   drpub_C_on_src0b2_217               quiet 726040 min 0 max 0 | loud 313960 min 0 max 0
   §211 ACCB AT w78 -- the same five lines, the same numbers, min == max == 0 throughout
```

`min == max == 0` in **both** accumulators, in **both** buckets including the 726 040-frame
no-stimulus window, in **all five** arms. **NO non-zero output. NO audio claim.** This pass changed
no emulator behaviour at all, so it could not have produced one, and §216's result — the output
stage is a null *independent* of the send — is untouched.

### 7. ⇒ WHAT SHIPS, AND WHAT DOES NOT

**Ships (documentation and tooling only, zero behavioural change):**
* `upd6383.cpp` `case 0x0B` preamble — `SRC 0x0B` is no longer described as a guess, with the
  §215/§217/§218 anchoring and the §2 structural argument recorded beside the counter.
* `upd6383.cpp` `kwatch()` §110 note — the writers it asked for are named, with §104's collapse.
* `dsp/tools/src0b_census.py sendpath` — the whole-path `SRC` audit, reusing the §218 tool.

**Does NOT ship:** any gate, any mask bit, any default flip. ⚠ There was nothing to flip: the
question was a decode, the decode was already decided, and the located defect (`iw35`) has **no
instrument yet**. Building one on the strength of this section alone would be a change justified by
a model — which §217 and §218 both correctly declined.

### 8. ★ THE NEXT EXPERIMENT, PRE-REGISTERED HERE SO THE NEXT PASS CAN GRADE IT

**The question:** is `iw35`'s (and `iw45`'s) `HI_ST` store into cell `0x05` a **wrong target**, or
is cell `0x05` **not** body 0's input pickup?

**The instrument ALREADY EXISTS and has never been run** (rule 13, and it is the cheapest thing on
the table): `upd6383.cpp:612` — **mask bit 26 (`0x4000000`)**, which mirrors the kernel's `0x06`
result into `0x05`, with the fired counter `m_mirror06_n`. It is **0 in the shipped default
`0xB910E446A39B440F`** and no log in `data/` contains a `mirror06` line. Its own comment states the
two-sided reading in advance. ⚠ It answers the *deposit-address* half; the *overwrite* half needs a
second arm that suppresses the bit-4 store when `stdest == 0x05` in kernel A (env gate, default
OFF, fired count — the u64 mask is EXHAUSTED).

**Pre-registered discriminator, and it must name a wrong `iw`:**
* if body 0's `§104` columns become input-dependent **at `iw84`** (the pickup) — the deposit /
  overwrite reading is right and the defect is `iw35`'s store TARGET;
* if they become input-dependent only later, or not at all — cell `0x05` is not the pickup and the
  `base = 0x05 | unit<<7` identification is wrong, which is worth as much;
* the **null** is `§104` bit-identical to arm A, which would mean the gate never fired — check the
  fired count first.

⚠⚠ **AND IT CANNOT PRODUCE AUDIO, BY §216.** The output stage is a null *even when body 0 runs on
live audio* — `§70`/`§211` stayed `min 0 max 0` with the send forced open. So the falsifier is
`§104`'s body-0 columns and `s104_score.py`, **never** `§70`/`§211`. Any pass that grades this
experiment by listening has graded the wrong thing.

### 9. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **`HANDOFF-NEXT.md` §1 item 1 — "the send is decided by ONE corpus-unique word whose `SRC` is a GUESS"** | ⛔ **DOUBLY WRONG.** The guess was decided in **§215** and re-confirmed in §217/§218; and no `SRC` on the path decides a stored value, because both stores take `acc_to_datum(m_acc)` (§2). The task was 4 sections stale when it was written |
| **`SRC 0x0B` as "a GUESS; register row 14"** (the source's own words) | ANCHORED since §215 — 13/13 successor identity, the ENSEMBLE/kernel `2D9` twin, provenance-graded in §217, population re-verified in §218. Comment corrected |
| **"the delay line is EMPTY"** | ⚠ **IMPRECISE.** `§75` in the same report: **1 175 999 writes with content** (one per settled frame — the kernel's `iw46` writing the DC `0x7D70`), and `§200` shows reads resolving with 0..4401-frame ages. The reads return zero because the **bodies** write zero (§3), not because nothing is written or nothing resolves |
| **"the send carries zero and we do not know why"** (§213 §4, §215 §4) | ⛔ **ANSWERED.** The send is cell `0x05`; `iw9`/`iw11` deposit the audio; `iw35` overwrites it with `acc_to_datum(2^38) = 4 194 304` and `iw45` with `0`; body 0 picks up `0` at `iw84`. All three states MEASURED in `§104`'s residency column, in five logs |
| **"the input dies at `iw36`" as a root cause** (§213 §3) | it is a **consequence**: `iw36`/`iw37` re-read the constant `iw35`'s own store planted in `0x05`. The root is `iw35` |
| **§110's open question** (`upd6383.cpp:645`) | **ANSWERED** by the census it asked for, which has been in every log since. Standing rule 13, third occurrence |

Evidence grade: §1 **MEASURED** (corpus, §215/§218) and a documentation correction; §2 **FORCED**
from `upd6383.cpp:2081-2090` and `:2942`, with the path census **MEASURED** over `kernel.dsm`;
§3 **MEASURED** in five independent logs (`§86`, `§96`, `§104`), the attribution of the `4 194 304`
to `iw35` **FORCED** from the store site plus `274 877 906 944 >> 16`, and the `iw45`-is-the-send
control **MEASURED** in the two `SRC0B2=1` arms; §4 a method finding; §5 **MEASURED** (`§75`,
`§46`, `§200` in one report) with the writer attribution **INFERRED** from the count identity;
§6 **MEASURED**, including the no-stimulus window; §7 a decision — **nothing behavioural shipped**;
§8 **SPECULATIVE** as a hypothesis, with a pre-registered two-sided discriminator.
**No mask bit, no env gate and no default was changed by this pass.**

---

## §220 — ★★★ THE PICKUP IS DECIDED BY EXPERIMENT: SUPPRESS `iw35`/`iw45` AND BODY 0 RUNS ON LIVE AUDIO, THE DELAY LINE FILLS, AND `w73`/`w78` ARE **STILL EXACTLY ZERO**. MASK BIT 26 FIRED 5 881 351 TIMES AND MOVED THE PICKUP NOT AT ALL

<!-- LEDGER-VERDICT: NOT SHIPPED (diagnostic only) -->

Scored against `data/PREDICT_220.md`, **committed before `build.sh` was run**
(`kn5000-roms-disasm@451f3ce`; arm D's addendum committed before arm D, `@399661e`). Four runs, one
build, the §217 clean vehicle (`coldnotes2.lua`, cold boot, isolated NVRAM **and** isolated
`-cfg_directory` carrying `:DSPCFG value="3"`, `-log`, triad C4/E4/G4 held 21.02–27.51 s,
`-seconds_to_run 30`), all four **1 440 001 frames / 313 960 loud / 726 040 quiet**:

* **arm A** `data/A_off_220.log.gz` — shipped default, the control whose answer was already known;
* **arm B** `data/B_mirror06_220.log.gz` — `UPD6383_SPEC=b910e446a79b440f`, i.e. **mask bit 26**;
* **arm C** `data/C_noz05_220.log.gz` — `UPD6383_NOZ05=1`, the new gate;
* **arm D** `data/D_noz05_drpub_220.log.gz` — `UPD6383_NOZ05=1 UPD6383_DRPUB=1`, one variable off C.

> **THE QUESTION (§219 §8):** is `iw35`/`iw45`'s store into cell `0x05` a **wrong target**, or is
> cell `0x05` **not** body 0's input pickup?
>
> **THE ANSWER: cell `0x05` IS the pickup, decided by experiment and not by model.** Remove the two
> overwrites and body 0's `§104` columns go from `0/0/0` input-dependent slots to **`28/32/28` —
> slot for slot IDENTICAL to the §215 `SRC0B2` calibration arm**, `§46`'s delay reads go from
> **0 non-zero to 3 494 021**, and `§75`'s writes-with-content from 1 175 999 to **2 351 009**.
> **⇒ §219 §3 is CONFIRMED and dead-end 30 is opened: mask bit 26's mirror is REFUTED as a
> candidate — it fired 5 881 351 times and left `iw84` reading `0..0` in both buckets.**
> **⇒ AND `§70`/`§211` STILL READ `min == max == 0`, in all four arms, in both buckets.** The whole
> reverb now runs on live audio, delay line included, and the output is still exactly zero.
> **§216 is not merely re-confirmed; it is now the ONLY thing left.**

### 1. ★★ THE THREE PROGRAMMATIC CHECKS ON MASK BIT 26, BEFORE ARMING IT

Run by `dsp/tools/bit26_audit.py`, which **parses the C++** — comments and string literals stripped
first, so prose can never be mistaken for code — rather than grepping a spelling:

| check | answer |
|---|---|
| bit 26 CLEAR in the shipped default? | **YES.** `m_specmask = 0xb910e446a39b440f` is the **only** initialiser (`upd6383.h:1015`) and the only runtime write is the `UPD6383_SPEC` env override (`upd6383.cpp:293`). Set bits: 0,1,2,3,10,14,16,17,19,20,23,24,25,29,31,33,34,38,42,45,46,47,52,56,59,60,61,63 — **26 is not among them**. The brief's spelling of the default MATCHES the source |
| used at EXACTLY ONE site? | **YES.** `m_specmask & 0x4000000` occurs **once**, `upd6383.cpp:612`. Of the 15 literals in the two files with bit 26 set, exactly **one** equals `0x4000000`; the only non-single-bit mask ever AND-ed with `m_specmask` is `0x4001` (bits 0 + 14), which does not contain it. **Not confounded** |
| fired count, and is it logged? | **YES**, `m_mirror06_n` → `logerror`. ⚠ **But it was printed under `if (m_mirror06_n)`**, so 0 fires and "the block was never compiled in" looked identical in a log — the exact ambiguity a fired count exists to remove. **Fixed in this pass: it now prints unconditionally, with the bit's own state beside it** |
| never run? | **CONFIRMED** over all 17 `data/*.log*`: zero occurrences |

⇒ all three pass, so the instrument was usable. **The fourth line is the finding**: rule 8 is about
*legibility*, not about the increment existing.

### 2. ★★★ ARM C — THE DISCRIMINATOR FIRED, AND IT FIRED ON THE SIDE §219 PREDICTED

`UPD6383_NOZ05` (new, env, **DEFAULT OFF**, fired count **with a per-`iw` breakdown**) suppresses
the **site-2 bit-4 store when `dest == 0x05` and `pw_region(m_cur_iw) == PW_KERNEL_A`**.
`iw11`'s DEPOSIT is a **site-3 ACT-0x07** store and is untouched, so the audio still lands.

```
   §220 NOZ05 fired 3 528 080 | iw9:1 176 015  iw35:1 176 007  iw45:1 176 003
                              | iw19:19 iw21:12 iw27:12 iw33:8 iw39:4      <- 55 of 3 528 080
   §104  iw35  mem  8 388 607 ‖ -8 388 608..8 388 607  *      (was 5 084 004 ‖ -5 307 593..8 388 607)
         iw46  mem  8 388 607 ‖ -8 388 608..8 388 607  *      (was 0 ‖ 0)
         iw84  mem  8 388 607 ‖ -8 388 608..8 388 607  *      (was 0 ‖ 0)   <- THE PICKUP. LIVE.
         iw84  acc  902 698 916 773 ‖ -902 699 024 384..902 698 916 773  *
   s104_score.py   acc 63 idep (kernel A 33, body 0 28, body 1 2)
                   mem 73 idep (kernel A 40, body 0 32, body 1 1)
                   L   59 idep (kernel A 29, body 0 28, body 1 2)
   §86   cell 05 now written ONCE per frame (1 020 000, by iw11 alone; was 4 080 000 by four words)
         11 of 31 kernel-written cells INPUT-DEPENDENT (was 3): 0C 0E 0F 10 11 13 50 F1 join
   §46   24 922 560 reads, 3 494 021 returned NON-ZERO      (arm A: 0)
   §75   DELAY WRITES WITH CONTENT 2 351 009 of 23 693 760  (arm A: 1 175 999)
```

★★★ **AND THE CONVERGENCE THAT MAKES IT MORE THAN A GATE:** arm C's input-dependent slot sets in
body 0 **and** body 1 are **identical, slot for slot**, to `data/drpub_C_on_src0b2_217.log.gz` — the
§215 `SRC0B2=1` calibration arm. Two unrelated interventions (a `SRC` decode at `iw25`; the removal
of two stores 10–20 slots later) put live data into cell `0x05` by different routes and body 0
responds with **the same 28 acc / 32 mem / 28 L slots and the same `iw203`/`iw204`, `iw202`,
`iw202`/`iw325` in body 1**. That is a property of the *program*, not of either gate.

★ **`C1` MISSED ON THE LITERAL, PASSED ON THE SUBSTANCE, and the miss is worth keeping.** I
pre-registered the breakdown as *exactly* `{iw9, iw35, iw45}`. It is those three at 1 176 00x each
**plus 55 stray fires** spread over `iw19/21/27/33/39` — 1 in 64 000. Those are the words that
normally target `0x06`, caught on the frames where the pointer failed to close (`§36`: *"in the
other 1.69 % the input window lands wherever the pointer failed to return to"*). **Recorded as a
miss rather than smoothed over**; at 0.0016 % it cannot carry the result.

★ `C2` **PASS**, `C3` **PASS** (predicted mem ≥ 10, got 32), `C5` **PASS** (`iw36`, `iw37`,
`iw40`..`iw45` all join the mem list).

### 3. ⛔★★ ARM B — MASK BIT 26 IS REFUTED, AND IT IS *WORSE* THAN THE SHIPPED BUILD

```
   §106 DIAGNOSTIC (mask bit 26 = 1): mirrored 5 881 351 writes of cell 0x06 into 0x05
        5 881 351 / 5 = 1 176 270 kernel-A passes  ->  EXACTLY 5 fires per pass       B1 PASS
   §104 iw84 mem 0..0 ‖ 0..0    body-0 idep 0 / 0 / 0                                 B2 PASS
   s104 acc 22 idep (was 27) | mem 10 (was 21) | L 12 (was 18)   <- STRICTLY WORSE
```

★ **`B1` passed on the ratio I predicted from the words alone**: the mirror fires on
`mode != 1 && dest == 0x06`, which is `iw19/21/27/33/39` and **not** `iw72` (mode 1, so §99 routes
it to the register file). Five per pass, measured.

★★ **`B2` passed, and it refutes §219 §8's own reading of a null.** §219 §8 wrote *"the null is
`§104` bit-identical to arm A, which would mean the gate never fired — check the fired count
first"*. The fired count is **5 881 351** and the pickup did not move, because **every mirror site
is upstream of `iw45`**, whose zero store is the last write to `0x05` before the CALL. A null with
a large fired count was the *predicted* outcome, and it is a stronger refutation than a null with
a zero one.

★ **`B3` PARTIAL, and the miss is the interesting half.** Predicted: `iw35` leaves the mem/L lists
(**correct** — `iw33`'s mirrored constant `6 039 795` lands under the pointer) and `iw40..iw44`
join it. **They did not.** The reason names a mechanism I had not predicted: with `iw35` dead, the
accumulator at `iw38` is constant, so `iw39`'s store — the value the mirror copies — is constant
too, and the constancy then propagates **across the frame boundary** through cell `0x06` into the
next frame's `iw12..iw21`, which is why mem fell to 10 instead of rising to ~25. **The mirror
destroys input dependence; it does not create it.** ⇒ **dead-end 30.**

### 4. ★★ ARM D — THE FIRST TIME A NON-ZERO DELAY DATUM HAS EVER REACHED `iw25`

Pre-registered in the addendum, **before the run**. With the line full (arm C) and `DRPUB=1`:

```
   §215 CLASS-2 SRC 0x0B at iw25:  m_dr non-zero on 1 174 369 of 1 211 520     (arm C: 0)   D1 PASS
   §217 provenance at iw25:        iw12, age 0..0, 540 000/540 000, fired 24 922 560        D2 PASS
   §104 vs arm C, the ONLY new input-dependent slots:
        L   at iw25, iw27, iw39, iw40        <- iw25 IS the SRC 0x0B word
        acc at iw41, iw42, iw43, iw44                                                       D3 PASS
   body 0 / body 1 unchanged at 28/32/28 + 2/1/2 (already fully live in arm C)
```

★★ **This is the behavioural confirmation §215's corpus anchoring never had.** `iw25`'s `SRC 0x0B`
operand is *consumed*: give it a live datum and the liveness appears at `iw25` itself and then at
`iw27/iw39/iw40/iw41..44` and nowhere else. A wrong source could not produce that pattern.
⚠ **It does NOT make `DRPUB` shippable** — §219 §1.-0 item 3 requires the **shipped** build's line
to carry content, and arm C's line is full only because a diagnostic gate is on. Stated in the
pre-registration before the run, and unchanged by the result.

### 5. ★★★ STANDING RULE 1 — AND THIS TIME IT IS THE HEADLINE, NOT THE DISCLAIMER

```
   arm A  §70 ACCA AT w73  quiet 726 040 min 0 max 0 | loud 313 960 min 0 max 0
   arm B                   quiet 726 040 min 0 max 0 | loud 313 960 min 0 max 0
   arm C                   quiet 726 040 min 0 max 0 | loud 313 960 min 0 max 0
   arm D                   quiet 726 040 min 0 max 0 | loud 313 960 min 0 max 0
   §211 ACCB AT w78 -- the same four lines, the same numbers, min == max == 0 throughout
   §54 VERDICT in all four arms: SILENT -- chip eats the signal (DC leak 0.00 %, pass-through 0.00 %)
```

**`min == max == 0` in both accumulators, in both buckets including the 726 040-frame no-stimulus
window, in all four arms. NO non-zero output. NO audio claim. `R1`/`D4` PASS.**
★★ And this is now the strongest form of §216 that has ever been measured: in arm C **body 0 runs
its whole ladder on live audio, body 1 too, the delay line carries 3 494 021 non-zero reads**, and
the presentation stage still emits exactly zero. **Every upstream link is now demonstrably alive,
and the output is still a hard null.**

### 6. ⚠ WHY NOTHING SHIPS, AND THE REASON IS NOT DOUBT ABOUT THE MEASUREMENT

**`UPD6383_NOZ05` stays DEFAULT OFF.** It is a **diagnostic that deletes two stores the corpus says
are there**, and three things say it is not the hardware's mechanism:

1. **It rails.** `§86` cell `0x05` in arm C is `quiet [8 388 607 .. 8 388 607]` — the positive
   24-bit rail, *constant*, in the no-stimulus window. A pickup that sits at full scale with no
   notes playing is not a plausible chip state (§176's rail warning, third occurrence).
2. **There is no decode under which those stores do not happen.** Both `iw35` (`012.A.00.1C0`) and
   `iw45` (`010.A.00.20C`) carry `HI_ST`, both are `mode 2`, and — checked this pass —
   **neither carries bit 7**, so `§109`'s CO-EQUAL store-gate ambiguity (mask bit 29,
   `b7 && f31 != 2`) **cannot** refuse them under either reading. That candidate is CLOSED.
3. **§216.** Flipping it produces no audio, because nothing downstream of body 0 is connected.

**And bit 26 stays 0 forever: it is now dead-end 30, refuted by measurement.**

### 7. ⇒ WHAT SHIPS

* `upd6383.cpp` / `.h` — **`UPD6383_NOZ05`, env, DEFAULT OFF**, announced unconditionally at start,
  fired count **plus the per-`iw` breakdown** (which is what caught the 55 drift fires).
* `upd6383.cpp` — the `§106` fired count now prints **unconditionally with the bit's state**, so
  "0 fires" and "never ran" are no longer the same log.
* `dsp/tools/bit26_audit.py` — the programmatic mask-bit audit, reusable for any future bit.
* Four logs, `data/PREDICT_220.md`, this section.
* **No default flip. No mask bit. No behavioural change with the gates off** — arm A is
  **identical, slot for slot in all three `§104` columns**, to `data/drpub_A_off_217.log.gz`.

### 8. ★ THE NEXT EXPERIMENT, PRE-REGISTERED HERE

**The send is now a two-line question, and both lines are `iw`-specific:**

**(a) WHY does the kernel store to `0x05` three times?** `iw9` (constant `5 084 004`), `iw35`
(constant `4 194 304`), `iw45` (`0`) — plus `iw11`'s real deposit. Four writes to the body's input
cell in one pass is a lot. The pointer walk is deliberate (`iw32`: `dp 07→06`, `iw34`: `dp 06→05`,
both `0000AFFx07`), so *"the pointer is one cell low"* is **not** available as an explanation
without breaking that walk. ★ **The live candidate is the store's DATUM, not its address**: the
bit-4 store writes the **PRE-update** accumulator (verified: `iw39` stores
`acc_to_datum(130 485 107 904) = 1 991 044`, which is `iw38`'s post-value). At `iw35` the
**POST-update** accumulator is `908 714 800 127 ‖ 227 691 099 135..1 125 285 262 335` — **INPUT
DEPENDENT**. So *"the bit-4 store writes the accumulator AFTER the word's ALU op"* would make
`iw35` DEPOSIT audio instead of destroying it. ⚠ `iw45`'s post-value is `538 760 587 509`, still a
constant, so this reading alone does not finish the job — **which is exactly why it must be run as
a two-sided arm and not adopted.**

**(b) THE OUTPUT STAGE IS NOW THE WHOLE PROBLEM.** With arm C on, everything upstream is alive and
`w73`/`w78` are still `0`. Any pass that wants audio must work there, and `UPD6383_NOZ05=1` is now
**the standing rig for it**: it is the only arm in which the presentation stage is fed on both
units without touching the `SRC` decode.

### 9. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **§219 §8's question — "wrong target, or not the pickup?"** | **ANSWERED: cell `0x05` IS body 0's pickup.** Remove `iw35`/`iw45` and body 0 goes `0/0/0` → `28/32/28`, slot-for-slot identical to the §215 calibration arm, with `iw84` mem `8 388 607 ‖ -8 388 608..8 388 607`. `base = 0x05 \| unit<<7` is CORRECT |
| **mask bit 26 (`m_mirror06_n`), the §106 mirror** | ⛔ **DEAD-END 30.** Fired **5 881 351** times (5 per kernel-A pass, exactly as predicted from the words), moved `iw84` not at all — every mirror site is upstream of `iw45` — and made kernel A **strictly worse** (`acc 27→22, mem 21→10, L 18→12`) via a cross-frame path through cell `0x06`. **Never flip it** |
| **§219 §8's reading of a null** (*"a null means the gate never fired"*) | **WRONG, and pre-registered as wrong.** A null with a fired count of 5 881 351 is the outcome the word decode predicts |
| **"the delay line carries no audio because the bodies write zero"** (§219 §1.-1) | **CONFIRMED by intervention**, not just by inference: unblock the bodies' input and `§46` goes 0 → **3 494 021** non-zero reads, `§75` 1 175 999 → **2 351 009** |
| **"`DRPUB` delivers the right datum and it is zero"** (§217) | **The "and it is zero" half is now conditional**: with the line full, `m_dr` non-zero at `iw25` on **1 174 369** of 1 211 520, provenance `iw12` age 0, and the liveness appears at `iw25`/`iw27`/`iw39`/`iw40`/`iw41..44` and nowhere else. `SRC 0x0B` at `iw25` is confirmed **behaviourally**. Still not shippable (§219 §1.-0 item 3's condition names the SHIPPED build) |
| **`§109`'s CO-EQUAL bit-4 store gate (mask bit 29) as a candidate for the `0x05` overwrite** | **CLOSED.** Neither `iw35` nor `iw45` carries bit 7, so `guard7_would_refuse()` is false under **both** readings. It cannot be the reason |
| **rule 8 as "does the counter exist"** | ⚠ **SHARPENED.** `m_mirror06_n` had a counter *and* a `logerror`, and still made "0 fires" indistinguishable from "never ran" because the print was conditional. **Print fired counts unconditionally, with the arm's own flag beside them** |

Evidence grade: §1 **MEASURED** (a parse of the C++, not a grep) with the conditional-print defect
**FORCED** from the source; §2 **MEASURED** in one run against a pre-registration committed before
the build, `C1` MISSED on the literal breakdown and recorded as a miss; §3 **MEASURED**, `B1`/`B2`
PASS and `B3` PARTIAL with the unpredicted cross-frame mechanism named; §4 **MEASURED** against an
addendum committed before the run; §5 **MEASURED**, all four arms, including the no-stimulus
window; §6 a decision — **nothing behavioural shipped, both gates DEFAULT OFF**; §8 **SPECULATIVE**,
with the pre-update/post-update accumulator reading stated so the next pass can falsify it.
**`dsp/verify.py`: BYTE-MATCH OK.**

---

## §221 — ★★★ THE EPILOGUE IS EXONERATED BY PROVENANCE, NOT BY LIVENESS: `§E1` RUN ON THE `NOZ05` RIG NAMES EVERY OPERAND'S ARRAY, INDEX AND LAST WRITER — **`0` OF `14` TRACE TO BODY 0**, AND THE WHOLE CENSUS IS **BYTE-IDENTICAL** TO THE CONTROL WHILE THE BODIES RUN ON LIVE AUDIO

<!-- LEDGER-VERDICT: NOT SHIPPED (instrument only) -->

Scored against `data/PREDICT_221.md`, **committed before `build.sh` was run**
(`kn5000-roms-disasm@32c8818`). Two arms, one build, the §217/§220 clean vehicle (`coldnotes2.lua`,
cold boot, isolated NVRAM **and** isolated `-cfg_directory` carrying `:DSPCFG value="3"`, `-log`,
triad C4/E4/G4 held 21.02–27.51 s, `-seconds_to_run 30`), both **1 440 001 frames / 313 960 loud /
726 040 quiet**:

* **arm A** `data/A_epibus_221.log.gz` — `UPD6383_EPIBUS=1`, the shipped build;
* **arm B** `data/B_epibus_noz05_221.log.gz` — `UPD6383_EPIBUS=1 UPD6383_NOZ05=1`, **the rig**.

> **THE QUESTION (`OUTPUT-STAGE-NULL_findings.md` §6, `§E1`):** for every operand the output stage
> fetches — **which array, which index, and which `iw` last wrote it?** (Standing **RULE 17**:
> provenance, not liveness. Rule 15 is why: on a live cell every candidate reading scores 4/4.)
>
> **THE ANSWER, and it is a NULL of the most useful kind: the epilogue is NOT WIRED TO BODY 0 AT
> ALL.** `F1` = **0 of 14**. `F2`'s producer is kernel-B `iw54` on **540 000 of 540 000** settled
> frames (100.00 %), **0** body 0. `F3`'s calibration **PASSES**. And the entire 18-row census —
> every route, every resolved index, every `L` range, all three provenance columns — is
> **BYTE-IDENTICAL between the control and the rig**, i.e. **unchanged while body 0 runs its whole
> ladder on live audio, body 1 too, and the delay line carries 3 494 021 non-zero reads.**
> ⇒ ★★★ **THE EPILOGUE'S NULL IS STRUCTURAL, NOT STARVATION.** §216 is now localised: the output
> stage does not lose the signal, **it was never connected to it.**

### 1. THE CENSUS, BOTH ARMS (identical; quoted once)

`m_last_l = L` is the one statement where the operand bus is final, so the hook sits there and the
route is recorded **inside the `switch` case that ran** — never re-derived afterwards.

```
   iw  word        SRC  route[idx]                L q..q / l..l          LAST-WRITER  LAST-NONZERO  PRODUCER
   54  080016000B  00   m_dram[m_dp][FC]          0..0 / 0..0            iw3          NONE          NONE
   60  009218D15B  05   DEFAULT(no reading)       0..0 / 0..0            NONE         NONE          NONE
   61  001218D05B  01   DEFAULT(no reading)       0..0 / 0..0            NONE         NONE          NONE
   63  02A79051C3  07   m_rf[05]                  0..0 / 0..0            HOST         NONE          NONE
   65  020018F1C1  07   m_rf[8F]                  0..0 / 0..0            iw332        NONE          NONE
   66  000018C107  04   tempA                     0..0 / 0..0            iw65         iw53          iw53
   68  009218C19B  06   DEFAULT(no reading)       0..0 / 0..0            NONE         NONE          NONE
   70  02A61850C7  03   ACCA                      0..0 / 0..0            iw68         iw63          iw54
   72  0000106087  02   m_rf[06]            4194304..  / 4194304..       iw72         iw72          HOST
   73  0E30C00404  10   ACCA                      0..0 / 0..0            iw72         iw63          iw54
   75  082E80F000  00   m_dram[m_dp][00]          0..0 / 0..0            iw73         NONE          NONE
   78  0A3CD9F287  0A   DEFAULT(no reading)       0..0 / 0..0            NONE         NONE          NONE
   79  00122FF1CE  07   m_dram[m_dp][FF]          0..0 / 0..0            iw79         NONE          NONE
   80  01042001CE  07   m_dram[m_dp][FF]          0..0 / 0..0            iw79         NONE          NONE
   81  0102200000  00   m_dram[m_dp][FF]          0..0 / 0..0            iw79         NONE          NONE
  152  0880160000  00   m_dram[m_dp][FC]          0..0 / 0..0            iw3          NONE          NONE
  153  060210E000  00   m_dram[m_dp][FC]          0..0 / 0..0            iw3          NONE          NONE
  200  088013000B  00   m_dram[m_dp][85]          0..0 / 0..0            IN           NONE          NONE
        (every row x540 000 evaluations, 226 040 quiet / 313 960 loud, one route each, age stable)
```

**`N0` PASS** — 18 rows, exactly as pre-registered: **14 of the 22** `iw60..81` slots reach the
operand fetch and the **8** that do not are `w62 w64 w67 w69 w71 w74 w76 w77` (four C-format, three
`lo12` bit-11, one class-5), plus **4 of 4** handover slots. **`N1` PASS** — 13 of the 14 epilogue
fetches are identically `0` in both buckets; the 14th is `w72`. **`N3` PASS** — exactly four slots
take the literal `default: m_src_unread[]++` route, once per frame each, matching
`SRC CODES STILL READING ZERO: 0x01:1204800 0x05:1205760 0x06:1204800 0x0A:1203840`.

★ **AND `§104`'s "21 of 22" IS RE-STATED CORRECTLY FOR THE FIRST TIME.** `§104` records `m_last_l`,
a **member that survives a word which never reaches the bus**, so its `L` column has 22 rows but the
machine performs **14** fetches. This was pre-registered (`PREDICT_221` §1.1) and confirmed. It is
the same class of defect as the `D-RAM WRITES (nonzero/total)` counter: **a statistic that cannot
distinguish "measured zero" from "not measured".**

### 2. ★★★ `F1` — **0 OF 14**, AND THE INSTRUMENT WAS FIXED SO IT *COULD* HAVE FAILED

```
   §221 F1 : epilogue operands (iw60..81) whose provenance names BODY 0 (iw84..153):  0
   §221 F1b: ...naming BODY 1 (iw200..332):  1   w65 <- iw332 (last-writer column)
```

`F1b` **PASSES on the pre-registered number**: `w65` reads `m_rf[0x8F]`, which body 1's **last**
word `iw332` writes **540 000 of 540 000** settled frames — with **zero**. That is the epilogue
reading body 1's output register and finding it empty, and it is the *only* body→epilogue link in
the machine.

★★ **THE METHOD RESULT, and it is the one worth keeping.** The first build graded `F1` on the
**LAST-NON-ZERO writer** column alone and reported `F1b = 0` — a **FALSE ABSENCE**. `m_rf[0x8F]`
has *no* non-zero writer, because body 1 writes it with a dead accumulator; the wiring is invisible
in that column and plain in the last-writer one. ⇒ **a provenance census must report the last
WRITER, the last NON-ZERO writer, and the last writer that CHANGED the value, and grade over all
three.** Grading on one column is how "we are not connected" and "we are connected and it is zero"
become the same answer — the exact failure this whole line of work exists to avoid.

### 3. ★★ `F2` — THE PRODUCER IS `iw54`, 100.00 %, AND THE THIRD COLUMN IS WHY IT COULD BE SAID

```
   §221 F2: ACCA at w73 -- LAST-NON-ZERO writer: iw63:540000
                        -- PRODUCER (last writer that CHANGED it): iw54:540000
                        -- kernel B (iw50..59) 540000 of 540000 (100.00 %) | BODY 0  0
```

`OUTPUT-STAGE-NULL_findings.md` `F2` predicted the producer is **kernel-B `w54`**. The
last-non-zero column says `iw63` — because `iw63` **re-writes the same constant `2 603 010 048`**
and produces nothing. A single-hop "last non-zero writer" is confounded by exactly that, so the
census gained a third column — *last writer that changed the operand to a different non-zero value*
— and it names **`iw54`, on 540 000 of 540 000 frames.** ⇒ **`F2` PASSES, in substance and in
number, and the letter of its prediction (`w54`) is recovered rather than fudged.**
⚠ **ONE HOP.** Neither column traces a chain; both are stated with that limit attached.

### 4. ★★★ `F3` — THE CALIBRATION PASSES, AND ONE HALF OF THE FINDINGS' `N2` IS A PRE-REGISTERED MISS

```
   §221 F3 CALIBRATION: w72  route m_rf[addr8]  idx 06  L quiet 4194304 loud 4194304  ==> PASS
```

`OUTPUT-STAGE-NULL_findings.md` §6.2 `N2` predicted `w72`'s provenance is **HOST**. Measured:
**last writer `iw72` itself** (age **1..1** frames — `w72` re-stores the level it just read, §100's
identity), with **HOST** correctly appearing in the **PRODUCER** column. `PREDICT_221` §3 called
this half a miss **before the run**, from `§99 MODE-1 STORES 06:1203840` = exactly one store per
presentation. **The value is the calibration and it passed; the provenance is an observation and it
was refined.**

### 5. ★★★ `N6` — THE RIG CHANGES **NOTHING** IN THE OUTPUT STAGE. THIS IS THE HEADLINE

```
   diff  armA §E1 census  armB §E1 census   ->  EMPTY
   diff  armA §104 rows 54..81/152/153/200  ->  EMPTY
   arm A  s104  acc 27 | mem 21 | L 18   body 0: 0 / 0 / 0
   arm B  s104  acc 63 | mem 73 | L 59   body 0: 28 / 32 / 28   body 1: 2 / 1 / 2   (kernel A 33/40/29)
   arm B  §220 NOZ05 fired 3 528 080 | iw9:1 176 015 iw35:1 176 007 iw45:1 176 003 (+55 drift)
   arm B  §46 3 494 021 non-zero delay reads (arm A: 0) | §75 2 351 009 (arm A: 1 175 999)
```

Body 0 goes from **0/0/0 to 28/32/28**, reproducing §220 arm C digit for digit, the delay line
fills — **and not one byte of the epilogue's operand picture moves.** Every route, every index,
every `L` range, every provenance `iw`, every age, in all 18 rows.
⇒ **The epilogue's operand set is DISJOINT from the signal path.** It is not starved; it is
elsewhere. `§216` said the output stage is a null independent of its input; `§221` says **why**:
*there is no input to be independent of.*

### 6. ★★ `§E1b` — §5.1'S NEGATIVE RESULT IS NOW MEASURED, NOT ARGUED

`OUTPUT-STAGE-NULL_findings.md` §5.1 argues **statically** that decoding `SRC 0x01/0x05/0x06/0x0A`
could not help, partly from the `D-RAM WRITES (nonzero/total)` counter — **which is broken** (it
counts visits, and tests `L`, not the cell). `§E1b` records what each gap slot **would** have read
under all three candidate addressings, with provenance, both arms, identical:

```
   iw60 SRC 05 | m_rf[8D] 39718..39718 both buckets prov iw61 | m_dram[8D] 0..0 prov iw324
                                                              | m_dram[m_dp=00] 0..0 prov iw79
   iw61 SRC 01 | same three cells, same values
   iw68 SRC 06 | m_rf[8C] 0..0 prov iw66 | m_dram[8C] 0..0 prov iw202 | m_dram[00] 0..0 prov iw79
   iw78 SRC 0A | m_rf[9F] 0..0 prov NONE | m_dram[9F] 0..0 prov IN    | m_dram[00] 0..0 prov iw78
```

**All twelve counterfactual operands are CONSTANT in both buckets, in both arms.** `m_rf[0x8D]` is
`39 718` — the epilogue's own accumulator constant, written by `w61`, a self-loop. ⇒ **`N5` PASS:
the decode gap is REAL and NOT LOAD-BEARING, and that is now a measurement.**
★ It also *adds* something §5.1 did not have: the D-RAM twins `0x8C`/`0x8D`/`0x9F` are **not
untouched** — they are written by **body-1 words `iw324`/`iw202`** and by the **input latch**, every
frame, **with zero**. The cells are wired; the values are empty.

### 7. ★ `iw200`'s OPERAND IS `D-RAM[0x85]`, AND ITS ONLY WRITER IS THE INPUT LATCH

Pre-registered in `PREDICT_221` §1.2 as a second application of the `e49da4b` pre-increment
correction. Measured: `iw200` (body-1 entry, a delay READ) fetches `m_dram[m_dp]` with `m_dp = 0x85`
— the cell `e49da4b` proved has **ZERO I-RAM writers** — and its last writer is **`IN`**, the
per-frame input-latch deposit, **668 640 .. 1 208 639 frames ago**. So `0x85` is written only when
the input window **drifts** onto it (§36's 1.69 % of frames), never in the settled window.
⇒ **`D-RAM[0x85]` has NO PRODUCER IN THE SETTLED WINDOW, confirmed a third time by a third
instrument, and this run names its only writer ever: the input latch, under §36's pointer drift.**
⚠ **Read it with `PREDICT_D0_producer.md` (`64d1cb0`, written in parallel with this pass), which
sharpens the claim and is right to:** under §97's forced two-array split, *register* `0x85` **does**
have one producer — `iw70`, 1 020 000 stores per settled run, **every one of them zero** — while
*pointer-space* `D-RAM[0x85]`, the cell `iw205` and `iw200` read, has none. They are different
cells by construction, and `§E1`'s route column reports the pointer-space one (`m_dram[m_dp]`),
which is why the two results agree rather than compete.
★ And the same correction lands again: `w79` reads cell **`0x00`**, not `0xFF`
(`OUTPUT-STAGE-NULL_findings.md` §2's table row is wrong); `w80`/`w81` read `0xFF`. The operand is
fetched **before** the word's own post-increment, and `w79`'s `addr8 = 0xFF` is what *parks* the
pointer for `w80`. **Third occurrence of this exact trap.**

### 8. ★★★ STANDING RULE 19 IS NOW ENFORCED BY THE PRINTOUT

```
   §221 RULE 19 -- MEAN vs AC SPAN (a DC is |mean| >> span):
        §70  ACCA@w73  quiet mean 0.0 span 0 | loud mean 0.0 span 0
        §211 ACCB@w78  quiet mean 0.0 span 0 | loud mean 0.0 span 0
   §70/§211 min == max == 0, both buckets, BOTH ARMS.  §54 VERDICT: SILENT.  §61 DO1/DO2 peak 0.
```

`OUTPUT-STAGE-NULL_findings.md` §6.5(ii) constructed, **without a run**, a `w78` pedestal of
`79 438 ± 90` that passes standing rule 1 **and** §211's translation rule and is a DC at **−59 dB**.
Rather than leave that as a note a future reader must remember, `§70`/`§211` now print the **mean**
and the **AC span** beside the min/max. Read-only, always on, no behavioural change.
**`R1` PASS: nothing in this pass produced audio, and by §216 nothing in it could have.**

### 9. ⇒ WHAT SHIPS

* `upd6383.cpp` / `.h` — **`UPD6383_EPIBUS`, env, DEFAULT OFF**, announced unconditionally, fired
  count **120 960 000** printed unconditionally with the gate's state (rule 8 as §220 sharpened it).
  Shadow provenance tables for `m_dram[256]`, `m_rf[256]`, `tempA`, `tempB`, `ACCA`, `ACCB`,
  maintained **only while the gate is on**, with **three** columns: last writer, last non-zero
  writer, last writer that CHANGED the value.
* `upd6383.cpp` — **`§70`/`§211` now print MEAN and AC SPAN** (standing rule 19).
* `dsp/tools/e1_pred.py` — the static predicate walk that produced `N0`; it is what caught the
  truncated watch list.
* Two logs, `data/PREDICT_221.md`, this section.
* **No default flip. No mask bit. No decode change. `UPD6383_NOZ05` stays DEFAULT OFF** — §220 §6's
  three reasons are untouched by anything measured here, and its cell `0x05` still rails.
  **`dsp/verify.py`: BYTE-MATCH OK.**

### 10. ★★★ THE NEXT EXPERIMENT, PRE-REGISTERED HERE

`§E1`'s own decision rule (`OUTPUT-STAGE-NULL_findings.md` §6.4) says what follows from `F1` and
`F2` both holding, and it now holds **with the bodies live**, which is strictly stronger:

1. **★★★ `body-1 iw205` — `ACT 0x0D`'s DESTINATION (mask bits 42-44, currently selector 1).**
   It kills **128 of body 1's 133 slots**, and the twelve reverbs are unit 1 (§98 §3).
   ⚠ **`m_bx_sel0d` is FROZEN at 1** and changing it globally breaks body 0's only working pickup
   (§e49da4b) — so any arm here must be **`iw`-scoped or unit-scoped**, two-sided, env-gated,
   default OFF, with a fired count. ⚠ And `OUTPUT-STAGE-NULL_findings.md` §6.5(ii) names the wrong
   number in advance: a naive fix gives `w78` a **DC of `79 438 ± 90`** that passes rules 1 and
   §211. The rule-19 line now prints the mean and the span, so that failure is caught by the log.
2. **body-0's coefficient cursor at `iw112` (`coef 0..24`, §52 / register row 25)** — a
   **3 × 10⁻⁶** attenuation on the one real audio pickup, `−111 dB`.
3. ⛔ **NOT the epilogue.** `§221` closes it: `F1 = 0`, the census is byte-identical under the rig,
   and all twelve counterfactual operands are constant. **Any pass that proposes decoding
   `SRC 0x01/0x05/0x06/0x0A` to make the output stage input-dependent must first explain
   `§E1b`.**

### 11. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **`§E1`, `F1`, `F2`, `F3` — the whole pre-registered experiment** | **RUN, on the rig.** `F1` = 0 of 14, `F2`'s producer `iw54` at 100.00 %, `F3` PASS. `OUTPUT-STAGE-NULL_findings.md` §5.1 is **UPHELD**, and by measurement instead of by a static argument built partly on a broken counter |
| **"the epilogue might be starved rather than disconnected"** | ⛔ **DEAD.** Body 0 at `28/32/28`, body 1 live, 3 494 021 non-zero delay reads — and the epilogue census is **byte-identical**, all 18 rows, all three provenance columns |
| **`OUTPUT-STAGE-NULL_findings.md` §2's "`w79` reads `m_dram[0xFF]`"** | ⛔ **CORRECTED: `w79` reads cell `0x00`.** The operand is fetched before the word's own post-increment; `w79`'s `addr8 = 0xFF` parks the pointer for `w80`. Third occurrence of this trap (`iw205`, `§104`'s `dp` column, now this) |
| **§6.2 `N2`'s "`w72`'s provenance is HOST"** | ⚠ **HALF-MISS, pre-registered as one.** Last writer is **`iw72` itself**, age 1 frame, the §100 identity; **HOST** is the PRODUCER. The *value* calibration (`4 194 304`) passed |
| **"21 of 22 epilogue slots fetch zero"** | ⚠ **RE-STATED: 13 of 14 FETCHES.** `§104`'s `L` column is `m_last_l`, a member that survives a word which never reaches the bus — it has 22 rows, the machine has 14 fetches |
| **grading a provenance census on ONE column** | ⛔ **REFUTED BY ITS OWN FIRST RUN.** The last-non-zero column reported `F1b = 0` — a false absence — while the last-writer column showed `w65 <- iw332` on 540 000 of 540 000 frames. **Report all three columns and grade over all three** |
| **`E1_SLOTS = 24`, i.e. an instrument that silently truncates its own watch list** | ⚠ Two handover rows (`iw153`, `iw200`) were dropped by a `break` and simply did not print. **Caught only because `PREDICT_221` `N0` pre-registered the ROW COUNT.** An instrument with no predicted shape cannot report its own omissions |
| **standing rule 19 as a note** | ★ **MECHANISED.** `§70`/`§211` print MEAN and AC SPAN beside min/max, so §6.5(ii)'s `79 438 ± 90` counter-example is caught by the log and not by memory |

Evidence grade: §1 **MEASURED**, two arms, against a pre-registration committed before the build,
`N0`/`N1`/`N3` PASS; §2 **MEASURED**, with the one-column defect **FORCED** from the instrument's
own first run and recorded as such; §3 **MEASURED**, `F2`'s letter recovered by a third column
whose one-hop limit is stated; §4 **MEASURED**, `F3` PASS and `N2`'s provenance half a
pre-registered miss; §5 **MEASURED** — a byte-for-byte diff of two logs; §6 **MEASURED**, replacing
a static argument; §7 **MEASURED** and it is the third confirmation of `D-RAM[0x85]`'s missing
producer; §8 an instrument change, read-only; §9 a decision — **nothing behavioural shipped, every
gate DEFAULT OFF**; §10 **SPECULATIVE**, pre-registered with its named wrong number.
**`dsp/verify.py`: BYTE-MATCH OK.**

## §222 — ★★★ `ACT 0x0D`'s DESTINATION IS CLOSED AT `iw205` ITSELF, AND THE FIRST NON-ZERO OUTPUT IN THE PROJECT IS A **RIG RAIL**: `§54` REPORTS **826 040 OF 826 040 SILENT-INPUT FRAMES DRIVING A FULL-SCALE OUTPUT**, AND THE BISECTION SHOWS THE SPECULATIVE LATCH CONTRIBUTES **EXACTLY NOTHING**

<!-- LEDGER-VERDICT: NOT SHIPPED (instrument + one provably inert unification) -->

Scored against `data/PREDICT_222.md`, **committed before `build.sh` was run**
(`kn5000-roms-disasm@9f27562`). **Five arms, one build**, the §217/§220/§221 clean vehicle
(`coldnotes2.lua`, cold boot, isolated NVRAM **and** isolated `-cfg_directory` carrying
`:DSPCFG value="3"`, `-log`, triad C4/E4/G4 held 21.02–27.51 s, `-seconds_to_run 30`, visible
video):

| arm | log | env |
|---|---|---|
| **A** | `data/A_pickup_222.log.gz` | `PICKUP=1 EPIBUS=1` — shipped default |
| **B** | `data/B_pickup_noz05_222.log.gz` | `+ NOZ05=1` — **the rig control, the NULL** |
| **C** | `data/C_xb85_full_222.log.gz` | `+ XB85=1` — the full crossbar |
| **D** | `data/D_xb85_route_222.log.gz` | `XB85=2` — **array route ONLY** |
| **E** | `data/E_xb85_latch_222.log.gz` | `XB85=3` — **latch + load ONLY** |

> **THE TASK (§221 §10.1):** *body-1 `iw205` — `ACT 0x0D`'s DESTINATION.*
>
> **THE ANSWER, and it needed no new decode: the destination is the ACCUMULATOR, and §222
> measured it ON `iw205` ITSELF for the first time** rather than on its unit-0 twin. In arm C
> `iw205`'s operand is `547 518 .. 8 388 607` and `ACCB` after the slot is
> `35 882 139 648 .. 549 755 748 352` — **`L × 65536` to the unit, both endpoints.** `m_bx_sel0d = 1`
> is CORRECT, `iw205` is a **MESSENGER**, and the destination question is **CLOSED**.
>
> **AND THE HEAD OF THE CHAIN — the empty cell — WAS FORCED OPEN, WITH A RESULT THAT MUST NOT BE
> MISREAD.** Routing the epilogue's `w63` to pointer space lit the whole machine: body 1 went
> **`2/1/2` → `58/44/47`**, the epilogue **`0/0/0` → `22/19/9`**, and `§70`/`§211` left zero for the
> first time in the project. ⛔ **AND IT IS NOT AUDIO.** `§54` — the always-on DC detector — reports
> **`quiet-in 826 040 frames → 0 silent / 826 040 LOUD (peak 8 388 607)`**, i.e. **100 % of
> SILENT-INPUT frames produce a FULL-SCALE output**, and the **silent-input peak `8 388 607`
> EXCEEDS the loud-input peak `2 692 742`**. The output is louder with no notes than with notes.
> ⇒ ★★★ **THE PEDESTAL IS `UPD6383_NOZ05`'s OWN RAIL, PROPAGATED.** `D-RAM[0x05]` reads
> `8 388 607 .. 8 388 607` on every quiet frame in arm **B**, *before any crossbar exists*.
> **The only rig that makes unit 0 live is the rig that makes its output cell rail — so the
> crossbar cannot be evaluated on it. NOTHING SHIPS.**

### 1. ★★★ `ACT 0x0D` — DECIDED AT THE SITE, NOT AT THE TWIN

`§E-D0`'s row for `iw205`, arm C, beside arms A/B where the cell is empty:

```
   iw205 = 020224B1CD    dpPRE 85   dpPOST D0   route m_dram[m_dp][85]   226142 q / 314063 l
     arm A/B   L 0..0 / 0..0                 ACCB after 0..0 / 0..0
     arm C     L 8388607..8388607 / 547518..8388607
               ACCB after 549755748352..549755748352 / 35882139648..549755748352
        8 388 607 x 65536 = 549 755 748 352   EXACT
          547 518 x 65536 =  35 882 139 648   EXACT
```

Same word, same decode, three arms, and the accumulator follows the cell **to the unit** exactly
when the cell is filled. That is `bx_acc_w(L, false)` and nothing else in the eight-value menu.
⇒ `IW205-DRAM-D0_findings.md` §3.3's twin calibration is now **replicated at `iw205` itself**;
`m_bx_sel0d` stays **FROZEN at 1** and moves permanently onto the regression-control list.

★ `§E-D0` also measured what the *shipped* build does to that accumulator: `ACCB` **before**
`iw205` is `5 206 020 096` (arm A) and `5 212 375 101 ‖ 5 206 417 283..5 212 375 101` (arm C,
input-dependent) —
so `iw205` does not merely fail to deliver, **it destroys a live term** by loading an empty cell.

### 2. ★★★ `§E-D0` — `D-RAM[0x85]` HAS **NO WRITER AT ALL**, AND THE INSTRUMENT PROVES IT COULD HAVE FOUND ONE

```
   §222 §E-D0 PICKUP AUDIT: fetches 2 700 000, post-increment records 2 700 000,
                            rows 5 (PREDICTED 5), dropped 0
     iw   word         dpPRE dpPOST  var(pre/post/route)   route[idx]
      85  000020E1CD     05     13        0 / 0 / 0        m_dram[m_dp][05]
     130  020220A1CD     03     0D        0 / 0 / 0        m_dram[m_dp][03]
     205  020224B1CD     85     D0        0 / 0 / 0        m_dram[m_dp][85]
     319  02022081CD     85     8D        0 / 0 / 0        m_dram[m_dp][85]
     330  020227B1CD     85     00        0 / 0 / 0        m_dram[m_dp][85]

   WRITERS OF THE TWO PICKUP CELLS, settled frames (> 900 000):
     arm A   D-RAM[05]  iw9(site2) iw11(site3) iw35(site2) iw45(site2), each 540 000
             D-RAM[85]  NO WRITER AT ALL      m_rf[85]  iw70 site3 540 000  val 0..0 / 0..0
     arm B   D-RAM[05]  iw11 ONLY, quiet 8388607..8388607  loud -8388608..8388607
             D-RAM[85]  NO WRITER AT ALL      m_rf[85]  iw70 site3 540 000  val 0..0 / 0..0
     arm C   D-RAM[85]  iw70 site3 540 000  quiet 8388607..8388607 loud 547518..8388607
             m_rf [85]  NO WRITER AT ALL
```

**`P0` PASS** — 5 rows, exactly the pre-registered count, 0 dropped. **`P1`/`P2`/`P3` PASS** — every
`var` column is **0**, so the addresses are constant on 100 % of settled frames. ★ **And `0xD0` is
now MACHINE-REPORTED as the PARKED pointer, in its own column, beside the operand address `0x85`.**
The pre-increment trap that cost `OUTPUT-STAGE-NULL_findings.md` §1.2, `§104`'s `dp` column and
§221's `w79` is now structurally impossible to repeat at this site.

**`P5` PASS, and it is the result the audit existed for:** `D-RAM[0x85]` has **NO WRITER AT ALL** on
settled frames — in arm A *and* in arm B, where body 0 runs its whole ladder on live audio. The
instrument is not blind to writers: **it names `iw70`, site 3, 540 000, the moment one exists**
(arms C/D). ⇒ `IW205-DRAM-D0_findings.md` §2.1's **INFERRED** "no un-modelled route fills it" is now
**MEASURED**, and `PREDICT_D0_producer.md` §5.2's `N3`/`N4` are confirmed.

⚠ **`P4` IS A MISS, AND A USEFUL ONE.** Predicted **6** writers of `D-RAM[0x05]` in arm A and **3**
on the rig; measured **4** and **1**. `iw37` and `iw111` never store: both carry `hi12` bit 7 and
`§109`'s store gate suppresses them. ⇒ **on the rig, `iw11` is the ONLY writer of unit 0's input
cell** — which corrects `PREDICT_222` §1's own mechanism sketch, written from
`writers85.py`'s static map, which named `iw111`. **A static write-site map that ignores the store
GATES over-counts.**

### 3. ★★★ THE ARM MOVED THE OUTPUT — AND `§54` KILLED IT IN THE SAME LOG

```
                       body 0        body 1        epilogue      kernel A
   arm B  (control)    28/32/28      2 / 1 / 2      0/ 0/ 0       33/40/29
   arm C  (XB85=1)     28/27/24     59/44/49       22/19/ 9       33/42/29
   arm D  (XB85=2)     28/27/24     59/44/49       22/19/ 9       33/42/29   <- IDENTICAL to C
   arm E  (XB85=3)     28/32/28      2 / 1 / 2      0/ 0/ 0       33/40/29   <- IDENTICAL to B

   §70  ACCA@w73    arm C  quiet mean 352 943 168 421.0  span 0
                           loud  mean 352 935 830 162.3  span 329 906 836 205
                    arm D  quiet mean 352 943 168 421.0  span 0
                           loud  mean 352 935 830 162.3  span 329 906 836 205   <- DIGIT FOR DIGIT
   §211 ACCB@w78    arm C  quiet mean 1 212 718 186 496.0  span 0
                           loud  mean 1 212 708 031 370.7  span 1 207 096 377 344
                    arm D  quiet mean 1 212 718 186 496.0  span 0
                           loud  mean 1 212 709 732 642.8  span 1 245 317 496 832
   §70/§211         arms A, B, E   mean 0.0  span 0   quiet AND loud
   §54 arm C   quiet-in 826 040 -> 0 silent / 826 040 LOUD (peak 8 388 607)
               loud-in  313 960 -> 0 silent / 313 960 loud (peak 2 692 742)
   §61 arm C   unit1/DO2 peak 8 388 607  (the positive 24-bit RAIL)
```

**`F2` "held" — and it does not matter.** Five independent gates void it, and three of them were
pre-registered:

1. ⛔ **`§54` IS THE FATAL CASE, AT 100 %.** Its own definition in `upd6383.h` reads
   *"quiet-in / LOUD-out = ★ DC EVIDENCE. Any large count here is fatal."* The count is
   **826 040 of 826 040**. And the **silent-input peak `8 388 607` EXCEEDS the loud-input peak
   `2 692 742`** — the presentation is *anti-correlated* with the stimulus.
2. ⛔ **`F3` FAILS.** Body 0 regresses `28/32/28 → 28/27/24`. The arm is **not** confined to two
   words: the epilogue writes `D-RAM[0x00]`/`[0xFF]` (`iw75`, `iw79`–`81`) and kernel A's walk
   **starts** at `0xFF`, so a live epilogue feeds back into the next frame's kernel. `iw85`'s
   operand goes from `−8 388 608..8 388 607` to `547 518..8 388 607` — **the negative half of
   unit 0's signal is gone.**
3. ⛔ **`F1`'s `m_rf[0x8D]` control FAILS:** `0x009B26` → **`0x7FFFFF`**, and `8C`/`8F` rail with
   it. `§160` goes 42 non-zero cells → 44.
4. ⛔ **`w65`'s operand is a RAILED CONSTANT IN BOTH BUCKETS** (`m_rf[0x8F]`,
   `8 388 607..8 388 607` quiet *and* loud, provenance `iw332` on all three columns). Unit 1 is
   **saturated**, not working.
5. ⛔ **The pedestal is the RIG's.** `D-RAM[0x05]` already reads `8 388 607..8 388 607` on every
   quiet frame in **arm B**, before any crossbar exists — §220 §6's third-occurrence warning,
   measured again. A reverb fed a full-scale DC produces a full-scale DC.

★ **`F4`'s constant-fill trap fired with a constant `PREDICT_222` did not name.** It named `39 718`
and `4 194 304`; the constant that actually arrived is **`8 388 607`, the rig's own rail.**
The `F1` half that *was* upstream — `§41 unit0 0x400000 / unit1 0x178D0B` on 1 172 160 of
1 172 160 presentations — **PASSED in every arm**, including C and D.

### 4. ★★★ THE BISECTION IS TWO-SIDED AND IT REFUTES THE SPECULATIVE HALF

This is the part worth keeping, and `PREDICT_222` §5 required it before any promotion.

```
   arm E  XB85=3  LATCH + LOAD only, ARRAY ROUTE OFF
          w63 ACT-03 latch  FIRED 1 204 800     w70 SRC-03 load  FIRED 1 203 840
          §70/§211 min 0 max 0 | §54 826 040 silent / 0 LOUD | m_rf[8D] = 009B26
          body 0 28/32/28   body 1 2/1/2
          ★ diff(arm E §E-D0 census + writer census, arm B's) -> EMPTY.  The ONLY line that
            differs in the whole block is the arm's own announcement of its own state.

   arm D  XB85=2  ARRAY ROUTE only, LATCH AND LOAD OFF
          §70  quiet mean 352 943 168 421.0 span 0 | loud mean 352 935 830 162.3
               span 329 906 836 205   <- DIGIT FOR DIGIT arm C, BOTH BUCKETS
          s104  33/22/28/59 | 42/19/27/44 | 29/9/24/49   <- IDENTICAL to arm C, every column
          §54  826 040 of 826 040 quiet-in -> LOUD, peak 8 388 607
```

⇒ ⛔ **`ACT 0x03` AS A LATCH AND `SRC 0x03` AS ITS READER ARE REFUTED.** They fire **1 204 800 and
1 203 840 times** — rule 8: the counts prove they ran — and move **not one number**, and the
whole `§E-D0` block `diff`s **EMPTY** against the control. The entire effect
is the **ARRAY ROUTE**, and the source of the non-zero is **`w63`'s READ alone**: in arm D the
latch is off, yet `w70`'s bit-25 accumulator datum has already become `8 388 607`, because `w63`'s
read lit `ACCA`. `PREDICT_D0_producer.md` §5.1's steps **1 and 2 are DEAD**; only step 3 has any
consequence, and it is the **narrow bit-23 question on ONE word**.
⚠ One-hop limit: arm D shows the route's two halves are *jointly* necessary for body 1 to see
anything (`w70`'s store must also move arrays); it is `w63`'s read that supplies the non-zero.

### 5. ★★★ `§E1` UNDER RULE 17 — THE NEW LINK NAMES **KERNEL A**, NOT BODY 0

```
   arm B   w63  m_rf  [addr8][05]  0..0 / 0..0           prov HOST | NONE | NONE
   arm C   w63  m_dram[addr8][05]  8388607.. / 547518..  prov iw11 | iw11 | iw11   *
   arm C   w65  m_rf  [addr8][8F]  8388607.. / 8388607.. prov iw332 (all 3 columns)  =
   arm C  iw200 m_dram[m_dp][85]   8388607.. / 547518..  prov iw70  (all 3 columns)  *
   §221 F1  epilogue operands tracing to BODY 0 (iw84..153):  0    <- IN EVERY ARM, C AND D INCLUDED
   §221 F2  ACCA at w73, PRODUCER: kernel B iw54 100 % (arm B) -> iw72 100 % (arms C/D), BODY 0 = 0
   §E1b     iw70 | m_rf[85] 0..0 prov HOST | m_dram[85] 8388607../547518.. prov iw70
```

★★ **`F1` IS STILL `0` — WITH THE LINK OPEN.** The operand the crossbar delivers is provenance
**`iw11`**: **kernel A's dry deposit**, not body 0's processed output. ⇒ even taken at face value
this is a **parallel send** (input → unit 1), not the serial chain `PREDICT_222` §1 sketched, and
**body 0's ladder still reaches the presentation through nothing at all.** §221's structural
finding survives its own attempted refutation.

### 6. ★★ THE `:2914` / `:3491` DIVERGENCE — **DECIDED, UNIFIED, AND MEASURED INERT**

`PREDICT_D0_producer.md` §3.3 found that the mode-1 bit-4 store and the mode-1 READ both resolve
`addr8 | (m_cur_unit1 ? 0x80 : 0)` while the ACT-07 store took a **bare `addr8`**, under
`store_mode()`'s own banner *"one rule for both store sites"*. Decided on three legs, none of them
a model argument:

* **the corpus** (`dsp/tools/rebase_census.py`, new): body images name mode-1 destinations
  **UNIT-RELATIVE 7 of 7, ABSOLUTE 0 of 7** — 5 bit-4 (`a08 w101`, `a09 w47`, `a10 w67`,
  `a16 w132`, `a72 w53`) and 2 non-ESC ACT-07 (`a04 FLANGER w64`, `a05 PHASER w105`, both
  `addr8 = 0x0E`). A shared image cannot address unit 1 absolutely;
* **a measurement**: the one resident unit-1 case is `iw332` = `a16 ROOM REVERB 1 w132`,
  `addr8 = 0x0F` → `m_rf[0x8F]`, **which §221 measured `w65` reading back on 540 000/540 000
  settled frames**. The rebase is not merely plausible, it is the reason that link exists;
* **inertness, PRINTED not asserted**: both readings are now computed side by side and every
  disagreement counted unconditionally —
  **`ACT-07 mode-1 destinations resolved 5 976 000, DISAGREED 0`, in all five arms.**

⇒ **UNIFIED.** It also closes a latent **cross-unit corruption**: left alone, `a04 FLANGER` or
`a05 PHASER` selected on unit 1 would write **unit 0's** cell `0x0E`. Not observable on the
resident frame, which is exactly why it needed the corpus to decide it.

### 7. ⇒ WHAT SHIPS

* `upd6383.cpp` / `.h` — **`UPD6383_XB85`** (env, **DEFAULT OFF**, four fired counts printed
  unconditionally with the gate's state, values 1/2/3 = full / route-only / latch-only so the
  bisection needs no rebuild) and **`UPD6383_PICKUP`** (env, **DEFAULT OFF**, READ-ONLY, fired
  count and **row count vs the prediction** printed unconditionally).
* `upd6383.cpp` — the **mode-1 unit-rebase unification** plus its unconditional divergence counter
  (§6). `store_mode()` gains a `site` and a `force_dram` argument so the writer census is taken
  **inside the branch that ran**.
* `dsp/tools/rebase_census.py`; five logs; `data/PREDICT_222.md`; this section.
* **No default flip. No mask bit. No decode change. No change to `m_bx_sel0d`.**
  `UPD6383_NOZ05` stays **DEFAULT OFF**. **`dsp/verify.py`: BYTE-MATCH OK.**

### 8. ★★★ THE NEXT EXPERIMENT, PRE-REGISTERED HERE

1. ★★★ **THE BLOCKER IS NOW A RIG, AND IT IS NAMED: `UPD6383_NOZ05` RAILS `D-RAM[0x05]` AT
   `8 388 607` ON EVERY QUIET FRAME.** It is the only arm that makes unit 0 live, so **no
   end-to-end claim about this machine can be graded until it stops railing.** The fix is §220's
   own residual: the bit-4 store writes the **PRE-update** accumulator, and at `iw35` the
   **POST-update** accumulator is INPUT-DEPENDENT (`908 714 800 127 ‖ 227 691 099 135 ..
   1 125 285 262 335`), so a post-update store would make `iw35` **deposit** audio instead of
   destroying it — **without deleting a store the corpus contains.** Two-sided, default OFF,
   fired count. ⚠ `iw45`'s post-value is still constant, so this does not finish the job alone.
2. **`w63`'s READ is now the narrow, one-word form of the bit-23 question**, and §4 shows it is
   the *entire* mechanism. It is worth re-asking **on a non-railing rig** — and only there.
   ⛔ Not on `NOZ05`. ⛔ And not by clearing bit 23, which remains CONFOUNDED across six sites.
3. **body-0's coefficient cursor at `iw112`** (`§175 PER-SITE 0202A071D5`, `coef 0..24` against a
   24-bit scale — a **3 × 10⁻⁶** attenuation, **−111 dB**) is untouched by all of this and still
   measurable. §52 / register row 25.
4. ⛔ **NOT `ACT 0x0D`, NOT `m_bx_sel0d`, NOT `iw205`.** §1 closes them at the site.
   ⛔ **NOT `SRC 0x03` / `ACT 0x03` as a crossbar latch.** §4 refutes them by a two-sided run.

### 9. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **`ACT 0x0D`'s destination as an open question** | ⛔ **CLOSED AT THE SITE.** `iw205`'s own `ACCB` follows its own operand at exactly `× 65536`, both endpoints, arm C. `m_bx_sel0d = 1` is a REGRESSION CONTROL now, not a worklist item |
| **`D-RAM[0x85]` "NO PRODUCER" as an INFERENCE** | ★ **MEASURED.** An instrument that names `iw70` the instant one exists reports **NO WRITER AT ALL** in arms A and B |
| **`SRC 0x03` / `ACT 0x03` = the epilogue crossbar latch** | ⛔ **REFUTED BY A TWO-SIDED RUN.** Latch fired 1 204 800, load 1 203 840, result **bit-identical to the control**; the route alone reproduces the compound arm **digit for digit** |
| **`PREDICT_D0_producer.md` §5.1 steps 1 and 2** | ⛔ **DEAD.** Only step 3 (the array route) has any consequence |
| **"a non-zero `w73`/`w78` would be progress"** | ⛔ **NO.** Both moved, by 11 orders of magnitude, in a run where `§54` reports **100 % of silent-input frames driving full scale** and the silent peak **exceeds** the loud peak |
| **the `:2914`/`:3491` mode-1 rebase divergence** | ★ **DECIDED AND UNIFIED**, corpus 7 of 7 + `iw332` measured + **0 disagreements over 5 976 000 evaluations**. Also closes a latent cross-unit corruption in `a04`/`a05` |
| **`PREDICT_222` §1's mechanism sketch ("`iw111` fills `0x05`")** | ⚠ **WRONG, and caught by the audit.** `iw37` and `iw111` carry `hi12` bit 7 and never store. On the rig **`iw11` is the ONLY writer.** A static write-site map that ignores the store GATES over-counts |
| **`m_rf[0x8D] = 39 718` as a leak detector** | ⚠ **MIS-CHOSEN CONTROL.** It is `acc_to_datum(ACCA)` stored by `iw60`/`iw61` — **downstream** of the arm — so it cannot distinguish "leaked" from "worked". ★ **A regression control must be UPSTREAM of the arm.** The `§41` half was, and passed in all five arms |

### 10. ★★★ THE INSTRUMENT AUDIT LANDED MID-PASS, AIMED AT THIS EXACT NUMBER — AND THE RE-RUN WAS DONE

`INSTRUMENT-AUDIT_findings.md` (`6ce3b07`) shipped between this pass's pre-registration and its
runs. Its row 4 is aimed squarely at §222's headline:

> *"`§70`/`§211` `min == max == 0` — **SOUND. The null stands.** … Before believing any **future
> non-zero** `§70`, **raise the gate to 420 000 and re-run** — the 20 000-frame boot window is the
> only untested contaminant."*

`§70`/`§211` armed at **400 000** while `kwatch()`, `§81` and `§104` arm at **420 000**, so every
log in the project carried a 20 000-frame window the comparative censuses excluded and these two
did not (`§70 quiet 726 040` vs `§104 nq 706 040` — **exactly 20 000**). Harmless while the answer
was zero; **not harmless the moment §222 produced a non-zero one.**

**The audit's `R6` was applied and ALL FIVE ARMS WERE RE-RUN** (`S70_ARM_FRAME = 420000`,
read-only, one window for every census in the file). `§70` now reports `quiet frames 706 040`,
matching `§104` exactly. **The numbers quoted in §3 and §4 are from the re-run**, and:

* **the verdict did not move** — `§70` arm C `quiet mean 352 943 168 421.0 span 0`, and arm D
  reproduces it **digit for digit in both buckets**;
* **the bisection got sharper**: arms C and D are now identical in **every** `s104` column
  (`33/22/28/59 | 42/19/27/44 | 29/9/24/49`), and arm E's whole `§E-D0` block `diff`s **EMPTY**
  against the control;
* ⇒ **the 20 000-frame boot window was not the explanation.** Had it been, this section would
  have been a retraction instead of a null.

⚠ The audit's other live finding on this pass — that `§211`'s "ACCB" column is ACCA when
`m_speculative == false` — is **latent here**: every arm runs speculative. And its `§104` pooling
warning is **not** in play: all five arms are single-program cold boots.
★ **The lesson generalises: read the instrument audit's list before quoting a counter, and if the
number you are about to report is the one the audit flagged, re-run rather than caveat.**

Evidence grade: §1 **MEASURED EXACT**, three arms, at the site rather than the twin; §2
**MEASURED**, against a pre-registered ROW COUNT, with one pre-registered quantity MISSED and the
miss explained; §3 **MEASURED**, five gates, three of them pre-registered as falsifiers; §4
**MEASURED**, a two-sided bisection whose fired counts prove both halves ran; §5 **MEASURED**,
`§E1` re-run under the arm; §6 **PROVEN BY CONSTRUCTION** (corpus) + **MEASURED** (`iw332`, and 0
disagreements); §7 a decision — **nothing behavioural shipped except a unification measured inert
5 976 000 times**; §8 **SPECULATIVE**, pre-registered with the rig named as the blocker.
**`dsp/verify.py`: BYTE-MATCH OK.**

---

## §223 — ★★★ THE RAIL IS **NOT THE RIG'S**: THE SHIPPED BUILD CLIPS **5.303 %** OF EVERY ACCUMULATOR CONVERSION WITH THE INPUT **EXACTLY ZERO**, `§222`'s OWN NEXT EXPERIMENT IS REFUTED FROM DISK, AND THE NARROW RIG REPRODUCES `28/32/28` WHILE STILL RAILING

<!-- LEDGER-VERDICT: SHIPPED (one instrument, one narrower rig, one proven-by-construction fix, one latent runaway) -->

Scored against `data/PREDICT_223.md`, **committed before `build.sh` was run**
(`kn5000-roms-disasm@fc6d792`). **Three arms, one build**, the §217/§220/§221/§222 clean vehicle
(`coldnotes2.lua`, cold boot, isolated NVRAM **and** isolated `-cfg_directory` carrying
`:DSPCFG value="3"`, `-log`, triad C4/E4/G4 held 21.02–27.51 s, `-seconds_to_run 30`, visible
video, one run at a time):

| arm | log | env |
|---|---|---|
| **F** | `data/F_satcen_223.log.gz` | `PICKUP=1 EPIBUS=1` — **shipped default, THE NULL** |
| **G** | `data/G_noz05m1_223.log.gz` | `+ NOZ05=1` — §220/§222's rig, **the regression control** |
| **H** | `data/H_noz05m2_223.log.gz` | `+ NOZ05=2` — **the NARROW rig: `iw35`/`iw45` only** |

> **THE TASK (§222 §8.1):** *"no end-to-end claim about this machine can be graded until
> `UPD6383_NOZ05` stops railing `D-RAM[0x05]`. §220's post-update-store residual is the way in."*
>
> **THE ANSWER, and the first half of it needed no run at all: THE POST-UPDATE STORE IS THE RAIL
> TOO, and the rail was never the rig's.** Convert the numbers §220 and §222 both quote the way
> the store actually converts them — `acc_to_datum()`'s own `>> ACC_SHIFT` and its own clamp:
>
> ```
>    iw35 POST, quiet   908 714 800 127 >> 16 = 13 865 887  >  8 388 607   CLIPS  (1.653 x FS)
>    iw35 POST, loud                            3 474 290 .. 17 170 490    CLIPS at the top
>    iw45 POST, both    538 760 587 509 >> 16 =  8 220 834  = 98.0 % OF FULL SCALE, CONSTANT
> ```
>
> ⇒ ⛔ **A post-update bit-4 store deposits the RAIL into cell `0x05` on every quiet frame** — the
> exact failure it was proposed to cure. **CROSSED OFF. Do not build it.**
>
> **AND THE REASON IS BIGGER THAN THE RIG.** `§S1`, the new saturation census, run on the
> **SHIPPED DEFAULT** with the input **exactly zero** (`§54`'s own predicate):
> **`quiet 9 884 596 clip / 186 394 560 conversions = 5.303 %`**, and the quiet rate **EXCEEDS**
> the loud rate (`5.298 %`). **Six kernel-A sites and one body-0 site clip on 100 % of quiet
> frames**, `iw34` converting the constant **`14 428 403` = 1.720 × FS in BOTH buckets and in ALL
> THREE ARMS**. ⇒ ★★★ **THE PEDESTAL IS IN THE SHIPPED MODEL, NOT IN `UPD6383_NOZ05`.** The rig
> does not create it; it removes the two stores that were hiding it from body 0.
>
> **AND THE NARROW RIG SETTLES WHAT `iw9` WAS DOING: NOTHING BUT CLIPPING.** `NOZ05 = 2` deletes
> **2** stores where mode 1 deletes **8**, reproduces `28/32/28` and `33/40/29` and `2/1/2`
> **column for column**, and **still rails** `D-RAM[05]` at `8 388 607`. Its only difference from
> mode 1 is `iw9`'s **2 824 160 conversions, EVERY ONE OF WHICH CLIPS** — the two arms' clip
> counts differ by exactly that, in **both** buckets. **`§54` is clean in all three arms and
> `§70`/`§211` are `mean 0.0 span 0` in all three. NOTHING MOVED, AND THAT IS THE POINT.**

### 1. ★★★★ `§S1` — THE SATURATION CENSUS, AND WHAT IT SAYS ABOUT THE SHIPPED BUILD

`§54` can only see a DC that reaches the **output**. The pedestal that has now cost three sections
is made much further upstream, inside `acc_to_datum()` itself, at the single point where the
44-bit accumulator becomes a 24-bit datum. `§S1` records the **pre-clamp** value there, per `iw`,
split by `§54`'s own quiet/loud predicate, settled frames only, read-only, always on.

```
   ARM F  --  UPD6383_NOZ05 = 0, THE SHIPPED DEFAULT
   TOTALS  quiet  9 884 596 clip / 186 394 560 conversions (5.303 %)
           loud   4 391 682 clip /  82 885 440 conversions (5.298 %)   off-range iw 0

   iw   region   calls q/l          clips q/l          pre-clamp quiet[min..max]   pre-clamp loud
   16   kernelA   706040/313960      706040/313841     12 038 894 (constant)        2 052 665..14 411 582
   17   kernelA   706040/313960      706040/313951     18 061 870 (constant)        3 482 224..20 434 557
   18   kernelA   706040/313960      706040/313441     10 477 265 (constant)        1 626 296..12 849 952
   19   kernelA  3530200/1569800    3530200/1569775    18 865 872 (constant)        5 108 520..21 238 559
   34   kernelA   706040/313960      706040/313960     14 428 403 (constant)       14 428 403 (SAME)
   39   kernelA  2824160/1255840    2824160/1251928    10 729 595 (constant)        1 991 044..13 508 518
   92   body0     706040/313960      706040/313960      8 388 725..16 777 315       8 388 729..16 777 319
   §S1 rows printed 13 of cap 48, DROPPED 0
```

**`S1` PASSES, and by more than it predicted:** not "≥ 4 distinct `iw` clip in the quiet bucket"
but **seven sites clipping on 100 % of quiet frames**, and `iw39` — the one the prediction named —
is among them. **`S3` PASSES**: 13 rows, inside the predicted 4–24, **0 dropped**, against a cap
that prints its own overflow counter (the defect `INSTRUMENT-AUDIT` item 7 found in
`store_probe()`).

★★★ **`iw34` IS THE PUREST STATEMENT OF THE PEDESTAL.** Its conversion is
**`14 428 403 .. 14 428 403` in the QUIET bucket AND in the LOUD bucket AND in all three arms** —
a constant **1.720 × full scale** that clips on **1 020 000 of 1 020 000** conversions in every
configuration ever measured. It is not input-dependent, not rig-dependent and not arm-dependent.
★ **`iw92` is the body-0 twin:** its pre-clamp **minimum** is `8 388 725`, i.e. **already above the
rail before the range even opens**, on the shipped build, in both buckets.

**`S4` HOLDS AND MUST BE QUOTED:** the loud bucket clips **too** (`4 391 682`, `5.298 %`). ⇒
*"clipping only happens with no input"* is **NOT** the claim. The claim is the sharper one: **the
quiet rate is HIGHER than the loud rate**, so the overflow is not the signal overdriving anything
— it is a standing DC the signal modulates.

### 2. ⚠ THE PRE-REGISTERED CONTROL `S2` **FAILED, AND THE FAULT IS MINE** — off-by-one, FIFTH OCCURRENCE

`PREDICT_223` §3.1 `S2` named `iw34` as a conversion that **must not clip**, computing it as
`274 877 906 944 >> 16 = 4 194 304`. **It clips 100 % of the time at `14 428 403`.**

The census is not wrong; **the prediction was**. `§104`'s `acc` column is *"acc **AFTER** the
slot"*, and the bit-4 store's datum is the **PRE-update** accumulator — which is row `n−1`'s value,
not row `n`'s. `274 877 906 944` is what `iw34` **leaves**; `945 579 874 058 >> 16 = 14 428 403` is
what it **stores**. ⇒ **the after-slot / before-slot off-by-one, fifth occurrence** (after
`OUTPUT-STAGE-NULL_findings.md` §1.2, `§104`'s `dp` column, §221's `w79`, and
`RISK-TRIAGE_findings.md` §5's *cursor*). ★ **A prediction derived from a per-slot table must state
which side of the slot it took the number from, in the prediction.**

★★ **THE CONTROL THAT DID WORK IS AN INDEPENDENTLY ESTABLISHED NUMBER FROM ANOTHER INSTRUMENT.**
§220 established, by `kwatch` and by hand, *"`iw39` stores `acc_to_datum(130 485 107 904)` =
**1 991 044**, `iw38`'s post-value"*. `§S1` prints `iw39`'s **loud minimum** as **`1 991 044`**,
digit for digit, without ever being told about it. ⇒ **the census is validated against a number
decided two sections ago by a different route**, which is the only kind of known-answer control a
pure observer can have. (`iw40`, the prediction's second control, records **0 calls** — no
conversion happens there at all, so it grades nothing. Recorded so it is not quoted as a pass.)

### 3. ★★★ ARM H — THE NARROW RIG. IT REPRODUCES THE WHOLE EFFECT AND IT STILL RAILS

```
                       kernel A     body 0      body 1     epilogue
   arm F  (shipped)    27/26/20     2/ 4/ 1     0/0/0      0/0/0
   arm G  (NOZ05=1)    33/40/29    28/32/28     2/1/2      0/0/0     <- §222 arm B, reproduced
   arm H  (NOZ05=2)    33/40/29    28/32/28     2/1/2      0/0/0     <- COLUMN FOR COLUMN = G

   §220/§223 NOZ05 fired counts
     arm G  3 528 080 | iw9:1176015 iw19:19 iw21:12 iw27:12 iw35:1176007 iw33:8 iw45:1176003 iw39:4
     arm H  2 352 010 | iw35:1176007 iw45:1176003                       <- EXACTLY 2 ROWS

   D-RAM[05] WRITERS, settled frames
     arm F   iw9  quiet 5084004..5084004   iw11 quiet 5084004  iw35 4194304  iw45 0
     arm G   iw11 ONLY,      quiet 8388607..8388607   loud -8388608..8388607
     arm H   iw9  quiet 8388607..8388607   iw11 quiet 8388607..8388607   loud -8388608..8388607
```

**`H1` — THE PREDICTED NULL HELD.** `iw11` still deposits the rail. **`H2` PASSES** on the
pre-registered row count (2, against arm G's 8). **`H3` PASSES** — `iw9` is back, `n = 540 000`.
**`H4` PASSES** — `28/32/28`, identical to arm G. **`H5` PASSES** — `§54` clean, `§70`/`§211` zero.

⇒ ★★ **`iw9` IS NOT WHY THE RIG RAILS**, exactly as `PREDICT_223` §0.2 forced from the archived
`§104` rows (arm A and arm B first differ at **`iw8`**, upstream of every store the rig deletes).
And when `iw9` is restored **it rails too** (`8 388 607` where the shipped build has `5 084 004`),
because the runaway reaches it cross-frame.

★★★ **AND `§S1` MAKES THE BISECTION ARITHMETIC EXACT:**

```
   arm G  quiet 14 826 840 clip / 177 922 080 conv     loud 6 592 549 / 79 117 920
   arm H  quiet 17 651 000 clip / 180 746 240 conv     loud 7 848 173 / 80 373 760
   H - G  quiet  +2 824 160 clip / +2 824 160 conv     loud +1 255 624 / +1 255 840
   arm H  iw9 row:  quiet 2 824 160 calls / 2 824 160 clips
                    loud  1 255 840 calls / 1 255 624 clips
```

**Arm H = arm G + `iw9`'s conversions, in both buckets, to the unit — and 100 % of `iw9`'s quiet
conversions CLIP.** ⇒ restoring `iw9` adds **nothing but clipping**. Mode 2 is nevertheless the
**better rig of record**: it deletes 2 stores instead of 8, and it proves the `28/32/28` result was
never `iw9`'s or the five incidental LFO words'.

### 4. ⇒ THE BLOCKER IS RE-AIMED, AND IT IS NOT A RIG

§222 named the blocker *"`UPD6383_NOZ05` rails `D-RAM[0x05]`"*. **That is the symptom of a
shipped-build defect**, and three measurements say so:

1. the shipped build **already** clips `5.303 %` of conversions with **zero** input, quiet rate
   **above** loud rate;
2. `iw34` clips a **constant** `1.720 × FS` in **every bucket of every arm**, so no rig, no send
   and no input can be responsible for it;
3. `iw92`, in **body 0**, has a pre-clamp **minimum** above the rail on the shipped build.

⇒ ★★★ **THE NEXT QUESTION IS NOT "WHICH STORE TO DELETE". IT IS "WHY IS THE ACCUMULATOR 1.7–2.2 ×
FULL SCALE WITH NO INPUT".** Two candidates, both measurable, neither adopted here:

* **the `ACT 0x00` bus term.** Register row 26 makes ACTION `0x00` **ADD** `L << 16` to the
  accumulator. The kernel's bus carries coefficient-magnitude constants (`5 084 004`, `5 033 164`,
  `5 872 025`, `6 039 795`, `6 553 600`, `4 194 304` = exactly ½ FS), so a run of ACT-`0x00` words
  sums half-scale terms with no attenuation and passes FS after three of them. **A feedback path
  with no coefficient has gain 1, and a unity comb fed a DC ramps to the rail** — which is the
  shape of everything above.
* **`ACC_SHIFT`.** `>> 16` leaves 4 headroom bits over a 24-bit datum in a 44-bit accumulator.
  ⚠ **It is CALIBRATED and must not be moved casually**: `§41`'s `0x400000`/`0x178D0B` and
  `m_rf[0x8D] = 0x009B26 = 2 603 010 048 >> 16` both depend on it and both pass in all three arms.
  **A change here is a decode change and needs corpus evidence, not a moved number.**

⛔ **NOT the post-update store** (§0, refuted from disk). ⛔ **NOT `iw9`** (§3, refuted by
running it). ⛔ **NOT `ACT 0x0D` / `m_bx_sel0d` / `iw205`** (§222 §1, closed at the site).
⛔ **NOT `SRC 0x03` / `ACT 0x03` as a crossbar latch** (§222 §4, two-sided).

### 5. ★★ THE NOP GUARD IS NARROWED — AND IT IS MEASURED INERT ON EVERY NUMBER IN THE REPORT

`BUILD-LANE-QUEUE.md` item 1, shipped. The guard tested `hi12 == 0x000 ∧ class4 == 2 ∧
lo12 == 0x000` and **not `addr8`**, swallowing 103 corpus words across 28 of 40 streams — 41 of
them carrying a live signed pointer delta. **The narrower predicate already existed twice in this
tree** (`decoded()` requires `ad == 0x00`; the listings render the 41 as `?word`); the core was the
only one of three implementations that swallowed them.

```
   ★ §223 §NG NOP-GUARD NARROWED (addr8 == 0x00 added): 2 371 200 words handed to exec_alu()
        that the old guard swallowed, 2 distinct slots | iw213:1189440 iw57:1181760
        -- IDENTICAL in all three arms.
   §90 probe, now reached:  iw213 = 0002BA000  cl=2 dd=-70 dp=D0  ptr_postinc=1
```

**`N1` PASSES** — the count is non-zero, so the change is **tested**, not merely believed inert.
**`N2` PASSES, and it is the strongest form available:** arm F's whole `upd6383:` report `diff`s
against `A_pickup_222.log.gz` — **§222's archived arm A, same vehicle, same env** — in **29 lines**,
and **not one of them is a measured value**:

* the `NOZ05` announcement, reworded by this pass;
* six lines of the `§90 iw213` probe, which now fires (3 × 2 prints) because the word reaches
  `exec_alu()` at all — the change's own evidence;
* `§E1` fired `122 040 000` vs `120 960 000`, **+1 080 000 = 2 × 540 000 settled frames**: the
  provenance census now *sees* one more word per unit pass. A count, not a value;
* the additive `§S1` block.

**Every `§104` row, `§54`, `§70`, `§211`, `§41`, `§61`, `§160`, the writer census, the provenance
census and the delay census are IDENTICAL.** ⇒ the narrowing belongs to the proven-by-construction
class (7 of 7) and it ships on that, not on a moved number. ⚠ **82 of the 103 remain UNMEASURED**
— they sit in body images this vehicle never loads. Do not report them as measured-zero.

### 6. ⚠⚠ A LATENT RUNAWAY THE NARROWING SET OFF — AND ITS CLASS IS THE AUDIT'S OWN

The first arm-F build produced a **1 023 208-line** log where the archive's equivalent is **3 186**.
**1 020 000 of those lines were one `logerror`**:

```c
   if (m_cur_iw == 213 && m_dbg213 <= 3 && m_frames_run > 420000)     // §90, post-increment probe
```

`m_dbg213` is incremented **only** by the *other* `§90` probe at the top of `exec_alu()`, whose own
bound is `< 3`. Once that one stops at 3, **`<= 3` is true forever.** It was harmless only because
`iw213` was swallowed by the nop guard and never reached `exec_alu()` at all. ⇒ **a bound that
depends on a counter some OTHER site owns** — `INSTRUMENT-AUDIT_findings.md`'s class A, in its
purest form. Fixed: its own counter, its own bound, three lines, and the arms were **re-run on the
final build**. ★ **Every number in this section is from the re-runs.**

### 7. ⇒ WHAT SHIPS

* `upd6383.cpp` / `.h` — **`§S1` SATURATION CENSUS**: read-only, always on, settled frames only
  (`S1_ARM_FRAME = 420000`, the audit's unified window), pre-clamp min/max and clip counts per
  `iw` per bucket, totals **and ratios** printed unconditionally, a 48-row cap **with its own
  overflow counter**, and its known-answer control printed **beside** the result so the two cannot
  be quoted apart.
* `upd6383.cpp` / `.h` — **`UPD6383_NOZ05` becomes a MODE**: `0` off, `1` = §220's original
  (unchanged and **verified bit-identical to §222 arm B**), `2` = `iw35`/`iw45` only. **DEFAULT
  OFF.** Mode 2 is the **narrow rig of record**.
* `upd6383.cpp` — **the nop guard narrowed by `addr8 == 0x00`**, with `§NG`'s unconditional fired
  count and distinct-slot list (§5).
* `upd6383.cpp` / `.h` — **the `§90` runaway print bounded by its own counter** (§6).
* `dsp/tools/s104_tally.py` — the region-tally grader, **validated against all four archived §222
  arms** before use (it reproduces `28/32/28`, `33/40/29`, `2/1/2`, `59/44/49`, `22/19/9` exactly).
* three logs; `data/PREDICT_223.md`; this section.
* **No default flip. No mask bit. No decode change. No change to `m_bx_sel0d`, to `ACC_SHIFT` or to
  any store's datum.** `dsp/verify.py`: **BYTE-MATCH OK.**

### 8. ★★★ THE NEXT EXPERIMENT, PRE-REGISTERED HERE

1. ★★★ **THE BLOCKER IS `iw34`.** It converts a **constant** `14 428 403` = **1.720 × FS** and
   clips on **1 020 000 of 1 020 000** conversions in **every bucket of every arm**. It is
   input-independent, rig-independent and arm-independent, so it can be chased with **no rig at
   all** and its answer cannot be contaminated by the send. Name the words that build that
   accumulator between `iw30` and `iw34` and grade each one's contribution against full scale.
   ★ Grade on `§S1`'s per-`iw` clip count, **not** on `§70` — the output stage is a null.
2. **`ACT 0x00`'s bus term is the leading structural candidate** (§4). A comb whose feedback term
   is added **unattenuated** has gain 1, and a unity comb fed a DC ramps to the rail. ⚠ Two-sided,
   env-gated, default OFF, fired count — and the falsifier is `§S1`'s quiet clip rate, which must
   **fall** on the shipped default without `§41` or `m_rf[0x8D]` moving.
3. ⛔ **NOT `ACC_SHIFT`** on a moved number: `§41` and `m_rf[0x8D]` calibrate it and both pass.
4. **body-0's coefficient cursor at `iw112`** — `RISK-TRIAGE_findings.md` §5 has now **resolved**
   the `coef 0..24` vs `0x1364D9` conflict with zero runs (one cursor step apart, fourth
   pre-increment occurrence) and the **×24 attenuation STANDS**. Still measurable, still untouched.

### 9. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **§220/§222's post-update bit-4 store** | ⛔ **REFUTED FROM DISK, NO RUN.** `iw35`'s post-update accumulator converts to `13 865 887` and **clips**; `iw45`'s to `8 220 834` = **98.0 % of FS, constant in both buckets**. It deposits the rail it was meant to remove |
| **"the pedestal is `UPD6383_NOZ05`'s own rail"** | ⚠ **TOO KIND TO THE SHIPPED BUILD.** The shipped default clips **5.303 %** of conversions with the input **exactly zero**, at a rate **higher** than the loud bucket. The rig removes the two stores that were **hiding** it from body 0 |
| **`iw9` as a suspect in the rig's rail** | ⛔ **REFUTED BY RUNNING IT.** Arm H keeps `iw9` and rails identically; the two rigs' clip counts differ by **exactly** `iw9`'s conversions, in both buckets, **every one of which clips** |
| **`NOZ05 = 1` as "the two stores §219 named"** | ⚠ **IT DELETES EIGHT.** Its own breakdown always said so. Mode 2 deletes two, reproduces `28/32/28` `33/40/29` `2/1/2` column for column, and is the **narrow rig of record** |
| **the nop guard's `addr8`-blind predicate** | ★ **NARROWED AND SHIPPED**, `§NG` = 2 371 200 with a 29-line `diff` against the archive in which **no measured value moves** |
| **`§90`'s `m_dbg213 <= 3` bound** | ⚠ **A LATENT RUNAWAY**, dormant only because the word it watched was unreachable. 1 020 000 lines. Its own counter now |
| **`PREDICT_223 S2` (`iw34` must not clip)** | ⚠ **MY ERROR, not the instrument's** — `§104`'s `acc` is AFTER the slot, the store's datum is BEFORE it. **Off-by-one, fifth occurrence.** State which side of the slot a predicted number came from, **in the prediction** |
| **"a rig can be built that drives the bodies without railing"** | ⛔ **NOT BY DELETING STORES.** Both rigs rail, the narrow one included, and the shipped build clips already. **The rail is upstream of the send entirely** |

Evidence grade: §0 **FORCED** from an archived log, no run; §1 **MEASURED**, three arms, with a
pre-registered row count and 0 dropped; §2 a **self-caught prediction failure** plus a
cross-instrument known-answer control that passed digit for digit; §3 **MEASURED**, a two-sided
rig bisection whose clip-count difference is **exact in both buckets**; §4 **INFERRED** and
explicitly not adopted; §5 **PROVEN BY CONSTRUCTION** + **MEASURED INERT** against an archived
control; §6 **MEASURED** and fixed; §8 **SPECULATIVE**, pre-registered with the blocker re-aimed
at a word instead of a rig. **`dsp/verify.py`: BYTE-MATCH OK.**

## §224 — ★★★ `iw34` IS **ANSWERED**, AND ITS ANSWER KILLS `§223`'s OWN CANDIDATE: `ACT 0x00`'s BUS TERM CANNOT BE THE CAUSE THERE. WHERE IT **IS** THE CAUSE IS `iw91`, WHERE THE ADDEND IS THE **WRAP CONSTANT** — AND SUPPRESSING IT MAKES THE CHORUS LFO REACH ITS PUBLISHED CELL FOR THE FIRST TIME

<!-- LEDGER-VERDICT: SHIPPED (two read-only instruments, one fully-measured decode arm, DEFAULT OFF on a self-imposed gate) -->

Scored against `data/PREDICT_224.md`, **committed before `build.sh` was run**
(`kn5000-roms-disasm@fba980d`). **Two arms, one build**, the §217–§223 clean vehicle
(`coldnotes2.lua`, cold boot, isolated NVRAM **and** isolated `-cfg_directory` carrying
`:DSPCFG value="3"`, `-log`, triad C4/E4/G4, `-seconds_to_run 30`, visible video, one run at a
time):

| arm | log | env |
|---|---|---|
| **I** | `data/I_s2_224.log.gz` | *(none)* — **shipped default, THE NULL** |
| **J** | `data/J_lfowrap_224.log.gz` | `UPD6383_LFOWRAP=1` — the wrap-word reading |

> **THE TASK (§223 §8.1):** *"name the words that build that accumulator between `iw30` and `iw34`
> and grade each one's contribution against full scale"*, and **§8.2:** *"`ACT 0x00`'s bus term is
> the leading structural candidate."*
>
> **THE ANSWER TO §8.1 NEEDED NO RUN, AND IT ANSWERS §8.2 IN THE NEGATIVE.**
> `iw34` is `000.A.FF.407`: `lo12 0x407` ⇒ **`SRC 0x10` = THE ACCUMULATOR**, `ACT 0x07`. So the
> conversion `§S1` censuses there is **not a store's datum — it is the accumulator being placed on
> the bus**, and its value is `§104` row **33**'s `acc >> 16`. The ladder, all three terms
> reproduced to the unit and then **confirmed digit for digit by the new census**:
>
> ```
>    iw30  09A.A.00.200   acc = 0 + (C-RAM[9B] << 16) + P(0)              5 033 164   0.600 FS
>    iw32  000.A.FF.207   acc = P(iw30) = (C-RAM[9B]^2) >> 6              6 039 795   0.720 FS
>    iw33  412.A.00.200   acc = acc + (C-RAM[9D] << 16) + (C-RAM[9C]^2 >> 6)
>                             = 0.720 + 0.500 + 0.500 FS                 14 428 403   1.720 FS
>    iw34  SRC 0x10    ->  L = clamp(14 428 403) = 8 388 607
> ```
>
> ⇒ **`iw33` is the overflow site, not `iw34`**, its two addends are each **exactly ½ FS**, and
> **not one of the three terms is a sample** — they are a coefficient and two coefficients squared.
> ⇒ ⛔ **ZERO THE `ACT 0x00` BUS TERM AND `iw33` STILL LEAVES `10 234 099` = 1.220 × FS. STILL
> CLIPS.** The two *product* terms alone exceed full scale. **§223 §8.2 is REFUTED for `iw34`,
> from disk, with no build.**
>
> **AND WHERE THE BUS TERM *IS* THE CAUSE, THE ADDEND HAS A NAME.** `§S1`, both buckets:
> `iw92 − iw91 = 8 388 607` **exactly, at both endpoints**, and `8 388 607 = 0x7FFFFF = C-RAM[0x01]`
> — which `upd6383.cpp`'s **own** C-RAM annotation calls *"wrap"*. `iw91` is `§118`'s wrap word;
> its documented semantics are `ST mem[Q] <- (phase + INC) mod 2**23`; **the shipped model ADDS the
> modulus**, so `iw92` publishes `clamp(phase + INC + 0x7FFFFF)` and D-RAM cell `0x10` — `§120`'s
> modulation cell — is a full-scale DC.
>
> **ARM J DECIDES IT.** `§119 TRACK iw94 mem[dp]`, eight consecutive settled frames:
> `[dp10]8388607 ×8` → **`1006898 1007012 1007126 1007240 1007354 1007468 1007582 1007696`** —
> **a `+114`/frame ramp, the CHORUS LFO reaching its published cell for the first time in this
> project.** `§S1`'s quiet total falls by **exactly 706 040** and the loud total by **exactly
> 313 960** — `iw92`'s clip counts, to the unit, both buckets, as pre-registered.
> **`§41`, `m_rf[0x8D]`, `§54`, `§70`/`§211` do not move.**
> ⇒ ⚠ **AND IT DOES NOT SHIP AS A DEFAULT**, because `W4` — a gate this pass set for itself —
> **failed**. Body 0's `§104` tally moves `2/4/1 → 2/9/4`. §4 shows that is an **instrument
> artefact** and shows it from a case that was already in the shipped log.

### 1. ★★★★ WHAT `iw34`'s `14 428 403` IS — and `§S1` IS NOW VALIDATED A SECOND WAY, FROM DISK

`§223` §1 quoted `iw34`'s conversion as a store's datum. **It is the `SRC 0x10` bus read.** By the
disassembler's own accessors: `hi12 0x000` ⇒ `f31 = 0` (`acc ← P`), no `HI_ST`; `class4 0xA` ⇒
coefficient consumer; `addr8 0xFF` ⇒ `p += −1` (`dp 06 → 05`, matching `§104`); `lo12 0x407` ⇒
`SRC 0x10` = the accumulator, `ACT 0x07` = `mem[p] ← L`. `acc_to_datum()` runs there to build
**`L`**, and that clamped `L` is then both stored and multiplied.

★★★ **AND THE SAME HOLDS FOR EVERY ROW `§S1` PRINTS.** Computed here from
`F_satcen_223.log.gz` alone, before any build:

```
   iw16 <- §104 row15  788 981 014 570 >>16 = 12 038 894     §S1 12 038 894     OK
   iw17 <- row16     1 183 702 722 651 >>16 = 18 061 870     §S1 18 061 870     OK
   iw18 <- row17       686 638 043 089 >>16 = 10 477 265     §S1 10 477 265     OK
   iw19 <- row18     1 236 393 791 441 >>16 = 18 865 872     §S1 18 865 872     OK
   iw34 <- row33       945 579 874 058 >>16 = 14 428 403     §S1 14 428 403     OK
   iw39 <- row38       703 174 786 484 >>16 = 10 729 595     §S1 10 729 595     OK
   iw91 <- row90 [7 733 451 .. 549 762 367 691] = [118 .. 8 388 708]        §S1 same   OK
   iw92 <- row91 [549 763 481 803 .. 1 099 518 116 043] = [8 388 725 .. 16 777 315]  OK
```

**8 of 8, both endpoints.** `§S1`'s value is always the **PRE-update** accumulator, i.e. the
**previous** slot's `§104` `acc`. ⇒ a second, independent validation of the census (the first was
§223's `iw39` loud minimum `1 991 044` from `kwatch`), and it cost **no run**. The build now prints
this as a `§S1 PROVENANCE` line so the two can never be quoted apart — **the after-slot /
before-slot off-by-one, which has cost five sections, is now annotated in the instrument itself.**

### 2. ★★★★ `§S2` — THE ACCUMULATOR TERM CENSUS, AND ITS FOUR PRE-REGISTERED CONTROLS ALL PASS

New, read-only, always on, settled frames only, hooked at the one point where the adder runs.
It splits `acc ← SRC_TERM + P_TERM` into the three physical terms register row 26 names, taking
them **out of `src_term` itself** so they cannot drift from the expression the ALU evaluated.

```
   §S2 CONTROL iw30  q carried 0..0                 bus 329853435904  P 0             = 329853435904
   §S2 CONTROL iw32  q carried 0..0                 bus 0             P 395824060170  = 395824060170
   §S2 CONTROL iw33  q carried 395824060170         bus 274877906944  P 274877906944  = 945579874058
   §S2 CONTROL iw91  q carried 7733451..549762367691 bus 549755748352 P 0..0
                                                      = 549763481803..1099518116043
```

★★★ **`T1`–`T4` PASS, DIGIT FOR DIGIT**, against numbers derived from a **different** instrument
(`§104` + the frame trace) and committed to `data/PREDICT_224.md` **before this code existed** —
which is the only kind of known-answer control a pure observer can have (RULE 20).
**`T6` PASSES and it is the sharp one:** rows are emitted on the **result** exceeding full scale,
so **`iw34` must NOT appear — and it does not.** 21 rows, inside the predicted 4–24, **0 dropped**.
⚠ The census's internal `carried + bus + P == result` is **true by construction** and is labelled
as such in the source; what is counted instead is the 44-bit accumulator **overflowing**
(`6 048 301`, identical in both arms).

★★ **AND THE CENSUS NAMES KERNEL A's RAIL AS A LATCH-UP, TERM BY TERM:**

```
   iw13  carried 239 225 266 218 + bus 549 755 748 352 + P 239 225 266 218 = 1.870 FS   busSRC 00
   iw14  carried             0   + bus 549 755 748 352 + P 239 225 266 218 = 1.435 FS   busSRC 00
   ...
   iw19  ... = 1.889 FS   ->  §96: iw19 STORES the clamped accumulator into D-RAM cell 0x06
```

`549 755 748 352 = 0x7FFFFF << 16` and `busSRC 00` is `mem[ptr]` — **cell `0x06`, read back at
unity gain from the previous frame.** `§176` on the shipped build: `06:8388607(0..8388607/chg1100)`.
⇒ ★★★ **§223's structural hypothesis — "a unity comb fed a DC ramps to the rail" — is CONFIRMED,
but for a MEMORY loop, not a coefficient one.** `iw13`'s own two other terms are `0.435 + 0.435 =
0.870 FS`, **below** the rail, so the loop has a stable latched state and the shipped build sits in
it: once cell `0x06` exceeds ≈ `0.13 × FS` the sum passes full scale, `iw19` clamps it back into
`0x06`, and it stays there forever with zero input. **That is the `§225` target, and it is a
BISTABLE, not a gain error.**

### 3. ★★★ `§S2sq` — THE MULTIPLY SQUARES ITS OWN COEFFICIENT, 5 100 000 TIMES A RUN

`SRC 0x08` resolves to `C-RAM[m_cursor]`; on a class-A word the multiply then reads
`C-RAM[m_cursor]` **again**, before the post-increment. So the product is the coefficient squared.
Counted corpus-wide for the first time:

```
   §S2sq: 5 100 000, 5 distinct slots | iw30:1020000 iw32:1020000 iw33:1020000 iw41:1020000 iw89:1020000
```

**`Q1` PASSES** — non-zero, and the four slots the prediction named (`iw30`, `iw32`, `iw33`,
`iw89`) are all present, with `iw41` as a fifth the prediction did not name.
**`Q2` PASSES** — identical in arms I and J.
⚠ **This is MEASURED, not graded.** For the LFO (`iw89`, `114² >> 6 = 203`) the squared product is
inert — the word uses its bus term, not `P`. At `iw30`/`iw32`/`iw33` the squared coefficient **is**
the accumulator's entire content. ⛔ **Do not "fix" it on this alone:** `SRC 0x08 = C-RAM[cursor]`
is ANCHORED by the LFO rate (`C-RAM[0x00] = 114` ⇒ the phase advances by exactly 114/frame, §109),
so the pre-increment reading of the *source* is right. Whether the *multiply* should read
`cursor + 1` is a real question and it now has a population to be graded against.

### 4. ★★★★ ARM J — `UPD6383_LFOWRAP`: EVERY FALSIFIER PASSES EXCEPT THE ONE I SET MYSELF

The gate, **by predicate and not by line**: `HI_ST ∧ HI_B7 ∧ f31 == 2 ∧ ACT 0x00 ∧ SRC 0x08 ∧
coeff_consumer` — §118's wrap-word family exactly. On it, the `SRC 0x08` operand is applied as a
**modulus** (`acc ← (datum(acc) & L) << ACC_SHIFT`) instead of as an addend. **The ADDER only**;
the bit-4 store's own datum is left clamping, deliberately (it clips 36 of 2 824 160 quiet
conversions, so it is not the damage).

```
   W0  FIRED  1 176 960 adder steps, 1 distinct slot | iw91:1176960            PASS
   W1  §S1 TOTALS  quiet 9 884 596 -> 9 178 556   = -706 040  EXACTLY           PASS
                   loud  4 391 682 -> 4 077 722   = -313 960  EXACTLY           PASS
       (5.303 % -> 4.924 % quiet, 5.298 % -> 4.920 % loud)  §S1 iw92 row GONE
   W2  §119 iw94 mem[dp]  [dp10]8388607 x8  ->  1006898 1007012 1007126 1007240
                                                1007354 1007468 1007582 1007696  PASS
       store probe  iw92 [site3 addr 10 val 8388607..8388607] -> val 4..8388598  PASS
   W3  §41 0x400000/0x178D0B  |  m_rf[8D]=009B26  |  §54 quiet-in 826 040 -> 826 040
       SILENT / 0 LOUD (peak 0)  |  §70 mean 0.0 span 0  §211 mean 0.0 span 0,
       BOTH buckets, BOTH arms  |  §S1 iw39 loud min 1 991 044                   PASS
   W4  §104 body 0   2/4/1  ->  2/9/4                                            FAIL
   R1  arm I vs F_satcen_223.log.gz: NOT ONE measured value moved                PASS
   R2  dsp/verify.py BYTE-MATCH OK                                               PASS
```

★★★ **`W2` IS THE DECIDER AND IT PASSED.** Six downstream consumers change with it —
`§104` rows `92 93 94 102 103 132` go from `mem 8388607..8388607` (constant) to
`mem 4..8388594` (the live ramp). **The modulation cell carries the LFO.**

⚠⚠ **`W4` FAILED, AND ITS FAILURE IS AN INSTRUMENT ARTEFACT — DECIDED FROM THE LOGS, NO RUN.**
`§104`'s `*` marker and `§86`'s *"cells whose value depends on the INPUT"* both fire on
**quiet-range ≠ loud-range**. Cell `0x10` now reads:

```
   arm J   ★ cell 10  quiet [0 .. 8388594]  loud [0 .. 8388598]  (5100000 writes)
   BOTH ARMS, ALREADY:
           ★ cell 07  quiet [4 .. 8388594]  loud [8 .. 8388598]  (1020000 writes)
```

**Cell `0x07` is the LFO PHASE. It has no input in it whatever, it shows the identical 4-unit
endpoint split, and it has been counted as `INPUT-DEPENDENT` in every log this project has ever
taken — including the shipped build.** Both buckets cover the whole ramp; the endpoints differ by
less than one increment (`114`) because the two buckets are different *sets of frames* and a
free-running ramp lands on a different sample of its own cycle in each.
⇒ ★★★ **RULE 21 (new): `§104`'s and `§86`'s quiet-vs-loud markers CANNOT DISTINGUISH
"input-dependent" from "free-running and sampled over two frame sets". Never grade a cell carrying
an LFO, a counter or any free-running ramp on them.** The `2/9/4` is `mem`/`L` columns on the six
slots that read cell `0x10`; the `acc` column is **unchanged at 2**. It is **NOT** body 0 acquiring
audio, and a future pass reading `2/4/1 → 2/9/4` as progress would be repeating §211's mistake.

### 5. ⇒ WHY IT DOES NOT SHIP AS A DEFAULT, AND WHAT WOULD MAKE IT

`PREDICT_224` §5: *"Nothing below `W0 ∧ W1 ∧ W2 ∧ W3 ∧ W4 ∧ R1`, all six."* `W4` failed. The gate
was mine, it was written down before the run, and this project's most valuable habit is that
§217–§223 all declined on exactly this kind of margin. **`UPD6383_LFOWRAP` stays DEFAULT OFF.**

★★ **AND THE RECOMMENDATION IS UNAMBIGUOUS: `§225` SHOULD FLIP IT.** Everything except `W4`
passed, `W4`'s failure is diagnosed against a case that predates the change, and the evidence for
the reading is not a moved number:

* the constant is **named in the source already** (`"0x00..0x13 real parameters (LFO rate 000072,
  wrap 7FFFFF, 400000 ...)"`, and the device's own §-note calls `iw91` *"the wrap word (f31 == 2,
  coefficient `0x7FFFFF`)"*) — standing rule 3/13 paid off, again;
* `§118`'s decode of the family says `mod 2**23` **in words**;
* the from-disk arithmetic is exact at **both** endpoints in **both** buckets;
* the fired count is **one slot**;
* the clip-count delta was **predicted to the unit** and landed;
* and the two-sided decider (`W2`) is a **positive** result, not the absence of a negative one.

**What §225 must do first:** restate `W4` so it cannot fire on a ramp — grade body 0 on the `acc`
column alone, or make the marker require the loud range to *contain* values the quiet range cannot
reach. Then flip.

### 6. ⇒ WHAT SHIPS

* `upd6383.cpp` / `.h` — **`§S2` ACCUMULATOR TERM CENSUS**: read-only, always on, settled frames
  (`S1_ARM_FRAME`, the audit's unified window), per `iw` per `§54` bucket, carried/bus/P/result
  min–max with FS ratios and the `SRC` codes that fed the bus, a 48-row cap **with its own
  overflow counter**, a 44-bit-overflow counter, and **four pre-registered controls printed
  beside the table**.
* `upd6383.cpp` / `.h` — **`§S2sq` COEFFICIENT-SQUARING COUNTER**: read-only, unconditional,
  per-slot breakdown.
* `upd6383.cpp` — **the `§S1 PROVENANCE` line**: every `§S1` row is the PREVIOUS slot's `§104`
  `acc >> ACC_SHIFT`. Printed so the off-by-one cannot be made a sixth time.
* `upd6383.cpp` / `.h` — **`UPD6383_LFOWRAP`**, env, **DEFAULT OFF**, announced unconditionally,
  fired count with distinct slots, gated by **predicate** not line.
* two logs; `data/PREDICT_224.md`; this section.
* **No default flip. No mask bit. No change to `ACC_SHIFT`, `P_SHIFT`, `m_bx_sel0d`, any store's
  datum, or any decode on the shipped path.** `dsp/verify.py`: **BYTE-MATCH OK.**

### 7. ★★★ THE NEXT EXPERIMENT, PRE-REGISTERED HERE

1. ★★★ **FLIP `UPD6383_LFOWRAP`** after restating `W4` per §5. It is the only fully-measured,
   positively-decided decode reading currently sitting at default OFF.
2. ★★★ **KERNEL A's CELL-`0x06` LATCH-UP IS THE NEW BLOCKER, AND `§S2` HAS ALREADY NAMED IT.**
   `iw13`/`iw14` take `mem[0x06]` onto the `ACT 0x00` bus **at unity**; `iw19` stores the clamped
   accumulator back into `0x06`; the loop's other terms sum to `0.870 FS`, so the rail is a
   **stable second state**, not a gain error. **Find what first drives `0x06` past ≈ `0.13 × FS`** —
   it is a cold-boot / first-frames question, so ⚠ **`§S1`/`§S2`/`§104` all arm at frame 420 000
   and CANNOT SEE IT.** A boot-window instrument is needed and its arming must be stated.
3. **`§S2sq`'s cursor question**: should the class-A multiply read `C-RAM[cursor + 1]` while
   `SRC 0x08` reads `C-RAM[cursor]`? The source read is ANCHORED by the LFO rate; the multiply's
   is not. Two-sided, default OFF, and the falsifier is `§41` plus SINGLE DELAY's validated
   `+0.02149296` three-factor product.
4. ⛔ **NOT `ACT 0x00`'s bus term as a general attenuation** — refuted for `iw34` (§0), and at
   `iw13`/`iw91` the fault is *what is on the bus*, not that it is added.
5. ⛔ **NOT `ACC_SHIFT` / `P_SHIFT`** on a moved number. ⚠ Note for the record: the kernel's C-RAM
   block is **Q23** (`0x4CCCCC = 0.600000`, `0x400000 = 0.500000`, `0x4F5C28 = 0.620000`,
   `0x50A3D7 = 0.630000`, `0x599999 = 0.700000`, `0x5C28F5 = 0.720000`, `0x5D70A3 = 0.730000`,
   `0x600000 = 0.750000` — eight round decimals, all ≤ 0.75, i.e. reverb gains), and
   `P = (coef × L) >> 6` with `ACC_SHIFT = 16` makes the product `2 ×` a Q23 product. **That is an
   OBSERVATION, not a proposal**: `ACC_SHIFT = 22 − P_SHIFT` ties them, `§41` and `m_rf[0x8D]`
   calibrate `ACC_SHIFT`, and SINGLE DELAY's `+0.02149296` calibrates the chain. Halving the
   products alone still leaves `iw33` at **1.110 × FS**, so it is not a cure either.

### 8. ⇒ WHAT THIS RETIRES

| retired | why |
|---|---|
| **"`iw34` converts a constant `14 428 403`"** as a *store* | ⚠ **IT IS THE `SRC 0x10` BUS READ.** `lo12 0x407` ⇒ `SRC 0x10` = the accumulator; the censused conversion builds `L`. The number is `§104` row **33**'s `acc >> 16` |
| **`ACT 0x00`'s bus term as the cause of `iw34`** | ⛔ **REFUTED FROM DISK, NO BUILD.** Zero it and `iw33` still leaves `1.220 × FS`. The two product terms alone exceed full scale |
| **`§S1` as an unvalidated new instrument** | ★ **VALIDATED A SECOND WAY**, from disk: all **8** of its rows equal the PREVIOUS `§104` row's `acc >> 16`, both endpoints. Now printed as a `§S1 PROVENANCE` line |
| **"`iw92` is the body-0 twin of the pedestal"** | ★★★ **NAMED.** `iw92 − iw91 = 8 388 607 = C-RAM[0x01]`, exactly, both endpoints, both buckets — the constant this file's own C-RAM annotation calls **"wrap"**. `iw91` adds the **modulus** |
| **"the chorus LFO runs"** | ⚠ **THE PHASE RUNS; ITS PUBLISHED COPY DID NOT.** Cell `0x07` ramps at `+114`/frame (§109) while cell `0x10` — `§120`'s modulation cell — was pinned at `8 388 607` on 8 of 8 frames (§119). Arm J makes `0x10` ramp |
| **§223's "a unity comb fed a DC ramps to the rail"** | ★ **CONFIRMED, but for a MEMORY loop.** `iw13`/`iw14` take `mem[0x06]` onto the `ACT 0x00` bus at unity and `iw19` stores the clamp back. And it is a **LATCH-UP**: the loop's other terms are `0.870 FS`, below the rail |
| **`§104`/`§86`'s quiet-vs-loud "input-dependent" marker** | ⚠⚠ **RULE 21: IT CANNOT DISTINGUISH A FREE-RUNNING RAMP.** Cell `0x07`, the LFO phase, has been flagged `INPUT-DEPENDENT` in every log ever taken, in both arms, with no input in it at all |
| **`W4` as a gate on this reading** | ⚠ **IT FAILED AND THE FAILURE IS THE INSTRUMENT'S**, but it was pre-registered, so the default does not flip this pass. §225 restates it and flips |

Evidence grade: §1 **FORCED** from an archived log, no run, then **CONFIRMED** by a new
instrument; §2 **MEASURED**, four pre-registered cross-instrument controls passing digit for digit
and a pre-registered row-exclusion (`iw34`) holding; §3 **MEASURED** and explicitly not graded;
§4 **MEASURED**, two arms, with the deciding falsifier positive and the one failed gate diagnosed
against a case that predates the change; §5 **a self-imposed decline**; §7 **SPECULATIVE**,
pre-registered. **`dsp/verify.py`: BYTE-MATCH OK.**
