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

## 5. The "multiplier runs on class-2 words" reading was RUN — disfavoured (MEASURED)
`UPD6383_MULALL` (kn7000_mame `upd6383.cpp`, default off) forms the product on every BODY class-2
word (never C-format, never the kernel) with the cursor's coefficient and no cursor advance.
Recipe: `dsp/tools/dlyseed_run.sh 7 … UPD6383_MULALL=1` (delay; FIRED 123 042 050) and
`dlyseed_run.sh 15 … UPD6383_MULALL=1 UPD6383_BIQSEED=8` / without the arm (EQ).
* **Delay:** the fixed point RAILS — cells 0x08, 0x50, 0x51 all read 0x7FFFFF (+2.0) entering the
  frame, the accumulator sits above the clamp, and `dlyseed_confront.py` reports 5 unexplained
  accumulator rows (0 without the arm). At unity input a damping loop must not rail; under this
  reading the extra products (w7's `1.0·L`, w13/w14's `c6·(…)`, the fold's `c0·(…)`) drive it to
  the rail. DISFAVOURED, in the form implemented (product on every class-2 word).
* **EQ:** INCONCLUSIVE — in the `fx_ab.lua`/`DSPCFG=3` rig used here the EQ trace is railed
  (state cells at 0x800000/0x7FFFFF) with and without the arm, so the biquad running-sum test
  cannot discriminate (2 broken rows with the arm, 0 without, both at saturation). The proper
  falsifier is the handoff's original biquad rig (`NAV=0 AUDIO=key BOOTGATE=10 DWELL=25
  DSPVAL=1 …`, DSP-DATAPATH-DECODE-HANDOFF §1), not re-run here. `lle_trace_diff.py`'s row regex
  now accepts the `[:dsp1]` log prefix (it parsed 0 rows before); its `--eq-trace` geometry
  report is identical across the two arms, as it must be (the arm touches no addressing).
So of §4's two candidates the **`w14` move** (`y_A` → cell 0x51) is the one still standing; the
class-2-multiply reading needs a narrower form (e.g. only on `ld`/`mac`-family class-2 words with
a tempA/acc source) before it is worth another run.

## 6. The coefficient SCALE, argued from the damping cascade's DC gain (HLE-informed, INFERRED)
The biquad's bit-exactness is scale-free (it compares the device's columns with themselves), so
the absolute multiply scale — §227's three-way `P_SHIFT`/`ACC_SHIFT` question, shipped total 22
(unity `0x400000`) vs the "UNTIED" total 23 (unity `0x7FFFFF`) — was never pinned by the LLE.
The recurrence of §2 pins what a damping section must NOT do: a damping filter's DC gain is at
most 1. `dlyseed_recurrence.py` evaluates the cascade's closed-form gain under the measured
routing at both scales:

```
total shift 22 (unity 0x400000): c3..c8 = +0.547 +0.774 -0.415 | +0.547 +0.774 -0.415  -> y_B/x = -1.452  |gain| > 1
total shift 23 (unity 0x7FFFFF): c3..c8 = +0.273 +0.387 -0.207 | +0.273 +0.387 -0.207  -> y_B/x = -0.353  |gain| <= 1
```
At the shipped scale the "damping" cascade AMPLIFIES the tap by 1.45 (and the fold's feedback
cell reads −0.58); at total shift 23 it damps to 0.35 and C-RAM[0x00] reads **−0.29 ≈ the "0.3
feedback" the program header and the HLE both carry**. Two independent cells agreeing with the
physical expectation only at 23 is an argument, not a measurement: it stands on the device's
class-2 store readings (which the fixed point does reproduce) and on "a damping filter does not
amplify". The same argument applies to §5: the MULALL rail at unity input is partly the scale
(a 1.45× cascade rails a 1.0 seed) — so §5's verdict is "disfavoured at the shipped scale", and
the reading deserves a re-run once the scale is settled. **Falsifier:** the §227 `UPD6383_PSHIFT=2`
build, seeded the same way, must give a self-consistent fixed point with a damped gain, and the
EQ's design-parameter match (docs §12) must survive — both already-built instruments.

**RUN (same day), delay half — MEASURED.** `dlyseed_run.sh 7 … UPD6383_PSHIFT=2` (no rebuild:
§227 is env-selected; the trace's header confirms `P_SHIFT = 7 ACC_SHIFT = 16 TOTAL = 23`). With
the tools told the shift (`--pshift 7`): multiplier **16/16** exact at `>> 7`, accumulator 21 + 17
+ 2 bus-add + 7 boundary, **0 unexplained, 0 saturated**; the recurrence check passes **8/8** (+1
LSB) once section A's load is written as `v = c2·x` (`c2 = 0x400000` is unity at 22 and one half
at 23 — the corrected tool reproduces BOTH traces). Entering state `m08 = −0.176`, `s51 = −0.198`
— the closed form's `−0.176 / −0.198` exactly — against `−1.452 / −1.624` at the shipped scale,
likewise exactly the closed form. So the two scales are two self-consistent executions of the
same routing, and the question is which is the chip's; at 23 the cascade DAMPS (0.18) and the
feedback cell reads −0.29, at 22 it amplifies (1.45) and the cell reads −0.58. The EQ half of the
falsifier (does the biquad stop railing at 23, as `a2 = 0.9911` vs `1.98` predicts?) is §7.

## 7. The EQ half of the falsifier — the biquad stops railing at total shift 23 (MEASURED)
The parametric EQ's coefficient cells read `−a2 = 0x81227B` etc.; as Q23 that is `a2 = +0.9911`
(poles at |z| ≈ 0.996, a stable resonant band), as Q22 it is `a2 = +1.98` — an UNSTABLE recursion
that must rail. `dlyseed_run.sh 15 … UPD6383_BIQSEED=8` at both scales, counting the body rows
whose cell under the pointer sits at a rail (`0x7FFFFF`/`0x800000`) and whose accumulator sits at
or beyond the ±2³⁹ clamp, and the biquad state block 0x64..0x77 in particular:

| | rows | mem at a rail | \|acc\| ≥ 2³⁹ | state cells 0x64..0x77 seen / railed |
|---|---|---|---|---|
| shipped, total 22 | 105 | **59** | **85** | 48 / **19** (`6A=800000`, `6C..6E=7FFFFF`) |
| `UPD6383_PSHIFT=2`, total 23 | 105 | 5 | 11 | 48 / **0** (`68=FFC4E0`, `6C=007623`, …) |

At the shipped scale the EQ's own state block is pinned to the rails; at total 23 it holds small,
finite values. Two programs, two independent physical constraints (a damping filter's gain ≤ 1;
a biquad's `|a2| < 1`), one answer: **the chip's coefficient field is Q23 — unity `0x7FFFFF`,
total multiply-to-datum shift 23 — i.e. §227's UNTIED variant (`P_SHIFT 7 / ACC_SHIFT 16`), not
the shipped 22.** This is the first time the absolute scale has been pinned by anything other than
the device's own columns (the biquad 27/27 is scale-free and holds at both: 16/16 at `>> 7`).
The disassembly's own static header annotations already read the cells this way (`prog09`: "0.5
mix, 0.15/0.3 feedback" = `0x400000`, `0xDAC37C` at Q23; `prog01`: "wet 0.25/0.15" =
`0x1364D9` at Q23) — the LLE's shipped 22 and the HLE's `q22 × cs` convention are the outliers.

**Consequence for the HLE (audited against the source, not assumed).** The HLE reads raw cells
with two conventions. The single delay's `fscale = bit1 ? 0.5 : 1.0` ("cell → operand, actual
gain") on top of `q22d` **already yields Q23 of the chip cell** — its feedback comes out `−0.29`
in both DSPCFG modes, exactly the chip's; so the delay is RIGHT and this note's first draft, which
called it 2× hot, was wrong and is corrected here. The chorus, by contrast, scales its wet gain
as `q22c(cell) × cs` with `cs = bit1 ? 1.0 : 2.0` — a convention that restores the chip's INTEGER
cells (the LFO increment 114, the 240-sample sweep) but leaves a GAIN at Q22 of the chip cell:
`cho_wet = 0.303` where Q23 says `0.152` (the disassembly header's "wet 0.15"). The distortion's
DRIVE/VOLUME (`q22d × cs`) are the same shape. So the audit's verdict is **per block**: gains
scaled via `fscale` are Q23 and correct; gains scaled via `q22 × cs` are 2× hot and should become
`q22 × cs / 2` (= Q23) — chorus wet first, then every block that copies the `cs` idiom for a
gain rather than an integer. The EQ is exempt (design parameters, calibrated to the panel's dB).
**Chorus wet corrected and A/B'd (kn7000_mame, `cho_wet … * 0.5`):** `dsp/tools/chorus_wet_ab.py`
on the previous vs the rebuilt binary (same `chorus_ab.lua` rig, one held note): LFO-band
modulation strength **0.0751 → 0.0449 (0.60×)**, rate unchanged at 0.62 Hz, mix rms 0.0149 →
0.0180 (the larger dry share, `(1−0.152)/(1−0.303) = 1.22`). The halving landed; the impl page
regenerated. Distortion DRIVE/VOLUME (`q22d × cs`, behind an AGC normaliser) are next in the audit.

## Honest grade
§7 MEASURED (two EQ runs, two delay runs; the rail/no-rail of the device's own state block), the
scale conclusion STRONG (two independent constraints + the corpus annotations; the shipped 22 was
never independently pinned). §6 INFERRED (closed-form from measured coefficients + a physical constraint; a named falsifier).
§5 MEASURED (two runs each program; the delay's rail is the device's own fixed point). §2 MEASURED: the recurrence reproduces every checked column from the entering state and the
coefficients (9/9, one LSB of rounding), i.e. this is exactly what the device executes. §3: the
feedback-cell identity is MEASURED (coefficient on the bus, operand = the damped output); the
"two sections" is MEASURED as structure, its filter form is OPEN pending §4. §4 is a STRONG
HLE-guided lead naming two candidate readings on already-open codes, not a decode. Nothing here
changes the shipped device; the tool and the archived trace reproduce every number.
