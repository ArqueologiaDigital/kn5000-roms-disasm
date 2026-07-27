# The output stage owns the I/O register file — and `ACT 0x1B` exists nowhere else

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis and the ROM corpus only.

**Why this note exists.** The output stage (I-RAM 60..82, 23 words) is the
worst-decoded region on the chip — **8.7% tier-1** — and it is what presents
audio to the pins. This is a first characterisation of what makes it different
from everything else.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **CONSISTENT** / **OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★★ **`ACT 0x1B` EXISTS ONLY IN THE OUTPUT STAGE.** Three occurrences in the 23 words, and **zero** in the 60-word kernel and **zero** in all 3154 words of the 38 distinct body images. It is the only ACTION code on the chip with that property. | **MEASURED** |
| **B** | ★★★ **ALL FIVE mode-1 words in the entire machine that touch registers `0x8C`/`0x8D`/`0x8F` are in the output stage.** `w60`→`0x8D`, `w61`→`0x8D`, `w68`→`0x8C` (all three `ACT 0x1B`, all three carrying the store bit); plus `w65`→`0x8F` and `w66`→`0x8C` without it. **Zero such words in the kernel; zero in any body image.** | **MEASURED** |
| **C** | ★★ **Those three registers are R2's "three unexplained registers"**, and [`host-side.md`](host-side.md) measured them **unreachable from the host by any path** — the host never initialises them in 100 canned streams nor in the live cold-boot capture. | **MEASURED** (published) |
| **D** | ★★★ **AND THE MODE-1 REGISTER FILE IS THE D-RAM SPACE.** [`k3-pointers.md`](k3-pointers.md) item I: *"The tag-`0x15` space — R2's mode-1 register file, **same space, independently confirmed**."* So the output stage's `0x8C` and the reverb's `mem[0x8C]` **are the same cell**. | **MEASURED** (published) |
| **E** | ★★★ **WHICH CLOSES A LOOP NOBODY HAD DRAWN.** The reverb's input mix reads `mem[0x8C]` (`w004`, ×0.5) and `mem[0x8F]` (`w003`, ×0.5) — [`blocka-forced-defect.md`](blocka-forced-defect.md) §11. The **output stage writes `0x8C`** at `w68` with the store bit set. The epilogue runs *after* the body, so **what the output stage writes at `0x8C` is what the next frame's reverb reads as input.** | **CONSISTENT** — see §2 |

---

## 1. What makes the region distinctive

Over the 23 words, the ACTION codes are `00 01 02 03 04 05 06 07 0E 1B` and the
SRC codes `00 01 02 03 04 05 06 07 0A 10 11`. The low-numbered SRC codes
`0x01`–`0x06` appear once each here and do occur in bodies (42, 48, 9, 14, 17 and
2 times respectively), so they are not exclusive — but the *density* is: a
23-word region using six of them once each looks like a region that reads six
different things exactly once.

**`ACT 0x1B` is the only genuinely exclusive code**, and its three sites are the
only stores into the I/O register file anywhere on the chip.

## ★ 2. The loop, and what it would explain

```
   epilogue  w68   ACT 0x1B, store  ->  register 0x8C
                      |
                      |  (same space, k3-pointers item I)
                      v
   reverb    w004   x 0.5  <-  mem[0x8C]        next frame
   reverb    w003   x 0.5  <-  mem[0x8F]
```

**Every reverb simulation in this project has run the body alone** — no kernel
(which is where the input latches are read) and **no epilogue** (which is where
this write happens). So this path has never been present in any run.

[`blocka-forced-defect.md`](blocka-forced-defect.md) §16 established that the
reverb's loop gain sits at either ≈1 or ≈0 at every fixed-point setting, and
concluded the missing element must be **structural — a feedback path with a
coefficient — not a scaling constant.** A one-frame return from the output stage
into the input mix, at a gain of 0.5, is exactly that shape.

**This is not a claim that it works.** It is a structural path that exists in the
ROM, has never been simulated, and matches the shape of the thing §16 said was
missing. Testing it needs the epilogue to execute, and the epilogue currently
traps on `ACT 0x01–0x06`, `0x1B`, `f31` values 3/4/6/7 and three C-format words —
i.e. almost all of it.

## 3. Predict-then-check

- **P1 HIT.** I predicted the output stage would use a distinct code space,
  because it is the only region that talks to the pins. `ACT 0x1B` is exclusive.
- **P2 MISS, caught before publishing.** I first wrote that the reverb's input
  mix and the output stage's registers converge — while the former is a *D-RAM
  pointer* and the latter a *mode-1 register index*. I checked rather than
  asserted, and `k3-pointers.md` says they are the same space. **The claim
  survives, but it needed the check**, and on today's record it might not have.
- **P3 unforeseen.** That the I/O register file would turn out to be touched by
  **exactly five words in the whole machine**, all of them here.

## 4. What the next pass needs

1. ★ **Run body + epilogue together.** The loop in §2 has never been present in a
   simulation. It needs `ACT 0x1B` at minimum, and that code appears in exactly
   three words — a small target with a large potential payoff.
2. **`ACT 0x1B` is decidable in principle**: it is the only code whose every
   occurrence is in one 23-word region with a known job (present audio to the
   pins), and its three sites all carry the store bit and all target the I/O
   register file. That is far more constrained than `ACT 0x0D`, which
   [`three-codes.md`](three-codes.md) showed has no anchored pairing anywhere.
3. **The output stage is the right place to be working.** It is 8.7% decoded, it
   owns the only exclusive opcode on the chip, and it holds the one structural
   path that matches what the reverb is missing.

---

## 5. The loop, probed structurally — negative, and weakly so

§2's path cannot be run directly: the epilogue traps on `ACT 0x01`–`0x06`,
`0x1B`, `f31` values 3/4/6/7 and three C-format words — nearly all of itself. So
the loop was probed *structurally* instead: take a fraction **g** of the frame's
output and place it in `mem[0x8C]` for the next frame, which is what `w68`'s
store would do whatever value it computes.

Decay measured properly this time — `E@2000 > E@5000 > E@8000`, not a range check:

```
  regime    g     E@2000  E@5000  E@8000   decaying?
  DATUM  0.00      -75.5   -75.5   -75.5      no
  DATUM  0.25      -73.5   -73.5   -73.5      no
  DATUM  1.00      -73.5   -73.5   -73.5      no
  ACC    0.00       -2.8    -2.8    -1.1      no
  ACC    0.50        0.0    -1.4    -1.4      no
  ACC    1.00       -1.2    -0.8    -0.8      no
```

**No decaying tail at any gain, in either regime.** And in DATUM the feedback
barely couples at all — 2 dB of change across the whole range from `g = 0` to
`g = 1`, meaning `mem[0x8C]` contributes almost nothing to the output despite
being multiplied by 0.5 in the input mix.

### ⚠ 5.1 How weak this negative is

**It cannot refute §2.** What the epilogue actually writes at `w68` is computed by
23 words that cannot be executed — that is the whole reason for probing
structurally. This test substitutes *a scalar multiple of one chosen output
probe* (`w123`) for that computation. A negative therefore shows only that

> **simple proportional feedback from `w123` does not produce a tail** —

not that the epilogue's real write fails to. The two differ in value, in timing,
and in which quantity is fed back.

Stated plainly so nobody quotes it as a refutation: **§2's loop remains
CONSISTENT and untested.** What §5 rules out is one particular caricature of it.

### 5.2 And what it does add

The 2 dB coupling figure is a real measurement and it is informative on its own:
whatever reaches `mem[0x8C]`, the reverb's output at `w123` is **almost
insensitive to it** in the regime that produces the echo. Either the input mix's
`0x8C` term is not the dominant path to the output, or `w123` is the wrong probe.
Both are checkable, and both are cheaper than executing the epilogue.

**The honest ranking is unchanged:** decoding `ACT 0x1B` — three words, one
region, a known job — is still the shortest route to testing §2 properly, and it
is far more constrained than anything left in
[`three-codes.md`](three-codes.md).

---

## 6. The store gate does NOT suppress `w68` — and the reason is a FORCED result the model never implemented

§5 accepted `output_stage.py`'s annotation that the adopted gate suppresses
`w60` and `w68` (both `(b7, f31) = (1,1)`), which would mean the §2 loop does not
exist. Taking the gate seriously turns that around.

### ★★★ 6.1 A priority-1 behavioural requirement is missing from the ALU model

[`isa-adjudication.md`](isa-adjudication.md), *Behavioural notes for the core, in
priority order*, item **1**:

> **`hi12` bit 4's target is mode-dependent — `mem[ptr]` only in mode 2. Eight
> kernel words mis-execute otherwise.**

`action00_discriminate.step`'s `do_store()` is:

```python
    st.mem[st.p] = v & MASK24        # unconditional -- no mode check
```

**The model stores to `mem[ptr]` for every mode.** A FORCED result, filed as the
*first* item on the core's handover list, with its own warning that eight kernel
words mis-execute without it, was never implemented. Every ALU search this
project has run carries it.

### ★★★ 6.2 Which invalidates the gate constraint at exactly the words that matter

`store-gate.md` FORCED its class-`(1,1)` result from the LFO: *"the memory access
does not deliver the accumulator to `mem[ptr]`"*, 0 of 17 928 survivors writing
it. Measured now:

```
  the LFO's bit-4 store words, by mode:
      class4 = 2  -> mode 2 :  8
      class4 = A  -> mode 2 : 80
      mode-2 stores: 88 of 88
```

**Every one is mode 2** — words whose bit-4 target *is* `mem[ptr]`. The constraint
is therefore a statement about **mode-2 stores**, and it is silent about mode-1
words, whose target the forced result places elsewhere.

And `w60`, `w61`, `w68` — the three `ACT 0x1B` words, the only stores into the I/O
register file on the chip — are **all mode 1**.

> ★ **So the gate does not suppress `w68`.** Its apparent suppression came from
> applying a mode-2-derived constraint to a mode-1 word, inside a model that
> ignores the mode-dependence entirely.

### 6.3 Status

- **§2's loop is NOT excluded.** `w68`'s store into register `0x8C` is not gated
  off; §5's caricature-negative was already weak, and §6 removes the structural
  objection as well. The loop is **OPEN and untested**, one step better than it
  stood an hour ago.
- **What `w68` stores, and to which register, is OPEN** — R2 forced only that
  mode-1's bit-4 target is *not* `mem[ptr]`; `isa-adjudication.md` item 13's
  register-file annotation (mode-1 without escape, `addr8` as the index) is the
  obvious candidate and is not established for stores.
- ⚠ **The model gap is the actionable item.** Implementing the mode-dependent
  target is a change to `do_store()` that affects **every** ALU result this
  project has published, and `isa-adjudication.md` says eight kernel words
  currently mis-execute. It should be done deliberately, with the published
  numbers re-run, not folded into another pass.

### 6.4 Predict-then-check

- **P1 HIT, and it is the pass.** I predicted that giving the store gate a
  *consequence* would make it tractable where the abstract 17-word framing had
  not. It immediately exposed a model gap instead — better than the answer I was
  looking for.
- **P2 unforeseen.** I did not expect the blocker to be a forced result **already
  written down and simply not implemented**. That is the third time today the
  answer was in the project's own notes.
