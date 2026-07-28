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
