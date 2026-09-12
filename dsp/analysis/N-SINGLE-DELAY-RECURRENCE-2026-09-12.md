# The single delay's per-frame recurrence, read off the seeded LLE trace at its fixed point (2026-09-12)

Companion to `N-DLYSEED2-SINGLE-DELAY-CONFRONT-2026-09-12.md` (which validated the arithmetic
PRIMITIVES). This note reads the program's SIGNAL FLOW off the same trace, word by word, and checks
it numerically. Tool: `dsp/tools/dlyseed_recurrence.py` on
`dsp/analysis/data/dlyseed2_single_delay_2026-09-12.log.gz` (the every-frame DLYSEED2 capture).

## 1. The instrument: a constant seed makes one frame a closed set of equations
With `UPD6383_DLYSEED2` seeding every frame the tap datum is a constant `x = 0x400000` — which is
**1.0 at the chip's Q22** (`P = coef × L >> 6`, datum = `acc >> 16`, so `0x400000` is unity in the
coefficient field) — and thousands of frames in, every state cell sits at its **fixed point**: the
value a cell holds when the frame starts equals what the frame's last writer leaves in it. The
trace's `mem` column (the cell under the pointer, sampled before each word) therefore gives the
entering state, the `coef` column gives each coefficient in force, and the recurrence predicted
from those must reproduce the `acc` column exactly. It does — **9 of 9 checks, the one "DIFF −1"
being the `>> 16` of a negative number** (device `acc_to_datum` vs Python floor, one LSB).

## 2. The L channel as the device executes it (MEASURED — every line reproduces the trace)
Words are `iw = 84 + w` of prog09; `x` = tap, `m08` = cell 0x08 entering the frame, `s51` = cell
0x51 entering section B; coefficients at Q22 from the bus:
`c0 = C-RAM[0x00] = 0xDAC37C (−0.582)`, `c2 = 0x400000 (1.0)`, `c3 = c6 = 0x23001E (+0.547)`,
`c4 = c7 = 0x318B12 (+0.774)`, `c5 = c8 = 0xE5762D (−0.415)`, `c1 = 0`.

```
w5   880.1.60.2D9  WRITE  line ← acc>>16 ; tempA ← published tap x      (ACT 0x19)
w6   mac ta        P = c2·x = 1.0·x                                        (SRC 0x19 = tempA)
w7   000.2.48.000  acc = (x + m08) << 16 ; cell 0x50 ← x + m08 =: u      (bus-add, dp = 0x50)
w8   mac.ta2 acc   acc += P (stale) ; tempA ← u
w9   880.1.20.64B  READ   acc = P (load) ; the next frame's tap latched
w10  ld  (p)       acc = x            ; P = c3·u                            (cell 0x50 ← x)
w11  mac acc       acc += c3·u        ; P = c4·x                            (operand = acc>>16 = x)
w12  mac (p)       acc += c4·x        ; P = c5·x           → cell 0x50 ← acc>>16 =: s50'
w13  mac.st acc    acc += c5·x  =: y_A ; the bit-4 store keeps the PRE-ALU acc (s50')
w14  000.2.01.000  acc = trunc(acc)  ; dp → 0x51
w15  ld  (p)       acc = P (= c5·x, the product held since w12) ; P = c6·s51
w16  mac acc       acc += c6·s51      ; P = c7·(c5·x)                       (cell 0x51 ← c5·x)
w17  mac (p)       acc += c7·c5·x     ; P = c8·(c5·x)      → cell 0x51 ← acc>>16 =: s51'
w18  mac.st acc    acc += c8·c5·x =: y_B                   → cells 0x07/0x08 for the next frame
w1..w4             acc = P[w0] (stale kernel product) + L[w2]<<16 (P←bus of cell 0x05, the
                   pickup — a saturated rail in the starved LLE) + c0·m08 + c1·m08
```
Fixed-point identities that hold in the trace: `y_B = m08` (±1 LSB) and `s51' = s51`. The R
channel (w24–w41, cells 0x52/0x53, C-RAM 0x09–0x11) is the same program with the same numbers.

## 3. What this says against the HLE (bytecode ↔ HLE, both ways)
**HLE feedback cell confirmed at word level.** `w3` multiplies **C-RAM[0x00]** — the cell the HLE
reads as the delay's feedback gain — by `m08 = y_B`, the damped output: `fb · damped`, exactly the
HLE's `line ← dry + g · damp(tap)`. The two other terms of the fold (`w1`/`w2`, the 0x0D/0x0E pair)
are the OPEN mixing readings and, in this starved run, carry a stale kernel product and the rail.

**The damping is not the HLE's one-pole.** The HLE damps with a single one-pole whose coefficient
comes from cell 0x03. The bytecode spends **two three-coefficient sections per channel** (cells
0x03–0x05 and 0x06–0x08, identical values in this setting), each of the shape
`load · mem ; += c_a · (acc) ; += c_b · mem ; += c_c · (…)`. That is an HLE-refinement lead with
bytecode provenance; the exact filter it realizes depends on §4.

## 4. Where the device's reading is suspect — the HLE as the tie-breaker
Under the device's current decodes, **section A's output `y_A` is discarded**: `w14` truncates the
accumulator and `w15` reloads it from the product register (the stale `c5·x` formed at `w12`), so
the four words `w10–w13` compute a value nothing consumes (cell 0x50 is scratch within the frame:
the next frame's `w7` overwrites it before anything reads it). Section B then recurs only on itself
(`s51' = c5·x + c6·s51 + c7·c5·x`). A program does not spend four words on a dead value; the HLE's
topology (tap → damping → feedback) wants section A to FEED section B — a cascade. Two device
readings would give that, and both sit on codes already flagged OPEN:
* `w14` (`000.2.01.000`, SRC 0x00 / ACT 0x00, pointer 0x50 → 0x51) **moves `y_A` into cell 0x51**
  (the memory-to-memory-move family of §119) instead of truncating in place — then
  `s51 = y_A` and `y_B = c5·x + c6·y_A + c7·c5·x + c8·c5·x`;
* or the **multiplier runs on class-2 words too** (only the cursor advance is class-A-specific), so
  `w15`'s load takes `c6 · s50'` rather than a product held for three words. The biquad's 27/27 was
  measured on multiply words only and does not decide this.
Either way the trace's fixed-point method is the falsifier: each reading predicts different `acc`
columns at `w15–w18`, and a run with the device switched to it either reproduces the same
self-consistent frame or does not. (In the current device the trace is self-consistent — that is
the point of §2 — so this is a decode question, not a device bug.)

## Honest grade
§2 MEASURED: the recurrence reproduces every checked column from the entering state and the
coefficients (9/9, one LSB of rounding), i.e. this is exactly what the device executes. §3: the
feedback-cell identity is MEASURED (coefficient on the bus, operand = the damped output); the
"two sections" is MEASURED as structure, its filter form is OPEN pending §4. §4 is a STRONG
HLE-guided lead naming two candidate readings on already-open codes, not a decode. Nothing here
changes the shipped device; the tool and the archived trace reproduce every number.
