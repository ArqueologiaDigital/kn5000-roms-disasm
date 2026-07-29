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
