# DECODE QUEUE — HANDOVER, 2026-09-14

**Read this before touching the decode queue.** Standing project rule: *check the handover first*.
Ten attacks were run on this queue in one session; two decoded, eight are nulls. The nulls are the
valuable part of this file — each closes a line and says why, so nobody walks it again.

## Where coverage stands

| region | start of session | now |
|---|---:|---:|
| KN5000 resident kernel (I-RAM 0…82) | 47.0 % | **61.4 %** |
| …header 0…59 | 56.7 % | **71.7 %** |
| …output stage 60…82 | 21.7 % | **34.8 %** |
| FRAME FLOOR (kernel + reverb) | 74.5 % | **80.1 %** |
| all 38 KN5000 body images | 80.4 % | 80.4 % |
| SX-WSA1R corpus (undecoded words 3091 → 851) | 37.5 % | **79.9 %** |

Mirrors **8003/8003** (pooled, `tools/upd6383d_diff.sh -p`); `dsp/verify.py` BYTE-MATCH OK.

## What decoded, and why it worked

* **§122** — the C-format payload is an I-RAM address. Two routes: the region test (11 of 11 inside
  their own image, p = 6.6e-9) and the **relocation test** against the WSA1R's byte-homologous copy
  of the kernel header (§121). +11 words, kernel 47.0 → 60.2 %.
* **§128** — **mode 1 is the register file.** `class4 & 7` is the addressing mode, so class 1 and
  class 9 were one question. Four measurements anchored the read half. +143 words.

**The method that paid, both times: a second copy of the same code at a different offset.** A field
that is an address shifts with a relocation; one that is data does not. No semantics, no null.

## The three blocks — 619 of the ~1358 remaining pooled words

### `ACT 0x0B` — 191 sole (62 KN + 129 WSA). THREE criteria measured blind.
* Anchored **only** on class A (fourth multiplicand route, FORCED under a 2-input ALU). §133
  checked whether that restriction is really the **cursor-fetch bit** rather than class A: it is
  not separable — every fetch-bit ACT-0x0B word *is* class A.
* §129 **withdrew the reason it was closed**: *"every ACT-0x0B delay word carries `addr8`
  0x20/0x30"* drops the population of a scoped measurement (`dram-matching.md` item J: "203 slots
  over the 83 algorithms where `#cells == #consumers`"). Six carry `0x60`, the FORCED write — two
  inside the KN5000's own algorithm images.
* **Criteria that failed, with their reasons:**
  1. SINGLE DELAY's lag-1001 ROM product — all six readings accepted (LEDGER §291, re-run).
  2. §130, the tempA hazard — beat its permutation null (0 of 48, null min 4) and **died to the
     per-action control**: 5 of 14 actions equally excluded.
  3. §133, the symmetric code (`ACT 0x0B` deposits what `SRC 0x0B` collects) — **0 of 488 at lag 1**,
     median lag 14, rank 8 of 16.
* **What would break it:** a program whose arithmetic the ROM pins *and* that an ACT-0x0B word
  visibly affects. 165 of 213 occurrences are delay escapes, 48 plain; the six WRITE-side words sit
  in ENSEMBLE and the resident kernel in **both** products, byte-identical — a small cross-product
  population any candidate reading must explain.

### `SRC 0x11` — 171 sole (54 KN + 117 WSA). A DEPENDENCY CYCLE, not a capture problem.
`DSP-DATAPATH-DECODE-HANDOFF-2026-09-11.md` states it: splitting `accb←acc` from `accb←P` needs a
program whose accb input **varies**, and every reachable program feeds it the frame-invariant
kernel-B constant — which is the very input route that is blocked. *"Capture campaigns cannot
settle accb… the break is the store/source-code decode from the bit-encoding (or hardware), NOT
another capture."* Confirmed there from three independent angles including the speculative ISA.
**Do not run another capture campaign at this.**

### `f31` 3…7 — 257 undecoded occurrences.
Downstream of the LFO rate defect §120 localised to **one word, `iw40`**. §132 measured the
documented-sibling route at exactly this field and it does **not** transfer: uPD6383 `ADD = 1`,
`HOLD = 2` against NEC uPD7725 `ADD = 5`, `NOP = 0`. The source-code match that made the rosetta
analogy credible is real and is **not** evidence about the ALU field.

## Lines closed this session — do not re-walk

| line | result |
|---|---|
| more class minimal pairs from the homolog pairs (§132) | **zero** aligned class substitutions; classes-4/6 stays at n = 2 |
| the class guard's missing 2×2 corner, class 0 (§132) | real asymmetry, **inert** — 221 words, 0 would decode |
| SRC/ACT codes exclusive to the WSA1R (§132) | **none**; one shared vocabulary, so its 851 words are blocked by the same codes |
| the documented sibling at the ALU field (§132) | codes **do not transfer** |
| `ACT 0x0B` = the write side of `SRC 0x0B` (§133) | **refuted**, 0 of 488 at lag 1 |
| `ACT 0x01` as the delay-data producer (§133) | **one word** in 27 images, not a field property (rule 9) |
| mode 3 / `class 3` (§131) | **exists** — the published class space is KN5000-local — but its addressing is undocumented and there is **no class twin** |
| the `0x820` targets as a strict NEXT-BLOCK pointer | **refuted**: 3 of 5 (KN) and 4 of 5 (WSA), weaker than §122's ζ (4/5, 5/5). `w31`/`w36` point **two** blocks ahead, consistently in both products. ζ is the right generality and `w40` stays the sole exception |

## Two method rules this session earned the hard way

1. **A null that moves is not a null that discriminates.** §128's first test was invariant under
   its own shuffle (mean 95.0, sd 0.0); §130's beat its permutation null and died to the
   per-category control. **Run the per-category control with the test, not after it.**
2. **De-duplicate before quoting a rate** (rule 9, `adjudication-round8` item E). §133's 70-of-91
   was one distinct word in 27 images.

## What would actually move this

* **Hardware.** Parked — `kn7000_mame/notes/HARDWARE-QUESTIONS-PENDING-FELIPE.md`.
* **A new anchored oracle** for one of the three codes. The HLE reference models
  (`lle-via-hle-oracle`) are the standing candidate and have corrected the bytecode twice.
* **`iw40`'s driver** (§120). It is now decoded as `ldreg r20,#iw14` — a register load whose I-RAM
  address points **at** a block terminator where all nine siblings point **past** one. What supplies
  `P` there is the best-posed question left, and it has a known answer at each end: the hand-off
  live at ±2.9 M and the ramp at the ROM's 114.
