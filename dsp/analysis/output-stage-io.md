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
