# MAME synthesis architecture: HLE the modelling LSI, LLE the DSPs — and use the HLE to aid the LLE

**Direction (Felipe, 2026-09-10):** in the MAME driver, *HLE of acoustic modelling* and *LLE of
the DSPs*; and *use insights from the HLE of the DSPs to aid the development of the LLE for them.*

This note records why that split is the right one, where each half stands, and the concrete
mechanism by which the DSP HLE becomes the oracle that drives the LLE decode forward.

## Why HLE one chip and LLE the other

The two devices are not the same kind of thing, so faithfulness means opposite techniques.

| | uPD6383GF effects DSP (IC311; WSA1R IC6/IC5/IC30) | L7A1429 acoustic-modelling LSI (WSA1R IC3) |
|---|---|---|
| what its behaviour is | a **host-uploaded microprogram** in I-RAM (384×36) | **fixed-function silicon** + undumped wave ROMs |
| is there a program to execute | yes — the microcode IS the algorithm | no — no code crosses its port (register file only, proven) |
| faithful route | **LLE**: execute the 36-bit microcode | **HLE**: realize the documented model; there is nothing to execute |
| ceiling | the real algorithm, once the ISA is decoded | the *documented* model — never the exact chip audio (wave ROMs `NO_DUMP`, POSITION scale needs a hardware trace, internal path unmeasured) |

LLE of the L7A1429 is not merely hard, it is **undefined**: a modelling engine with fixed on-die
code that exposes only coefficients has no uploadable program to run (`acoustic_modeling.h`, "IT IS
A REGISTER FILE, NOT A PROGRAM LOADER"). HLE of the DSPs, conversely, would throw away the one
thing we *do* have — the exact microcode — and bake in guesses. So: HLE the LSI, LLE the DSPs.

## Where each half stands today (2026-09-10)

**Acoustic modelling — HLE. ✅ DONE (2026-09-10).** `l7a1429_device` (`src/mame/matsushita/
acoustic_modeling.cpp`) now becomes a `device_sound_interface` under `WSA1R_ENABLE_ACOUSTIC_HLE`
(default 0 — the shipped machine is unchanged), running the documented coupled digital-waveguide
resonator model ported from `wsa1/hle/l7a1429_hle.py` (per channel MAIN+SUB waveguide: delay =
pitch period → MUTING one-pole loss → feedback, POSITION pickup tap; mixed by SUB GAIN; no
key-off). A MAIN TUNE write is the per-channel note event. **Validated in `wsa1r`**
(`tools/rigs/wsa1_acoustic_hle_probe.lua` pokes MAIN TUNE over CPU 2's bus): exciting all 64
voices at A4 rings at **436 Hz ≈ 440** (pitch tracks the written tune) and **decays autonomously**
(RMS 164→94→87, highs damping first via MUTING). Two honest stand-ins behind the flag: the
excitation is a synthetic burst for IC4's undumped wave ROMs, and POSITION's absolute scale is
unknown. It is the DOCUMENTED model, not the chip's real audio (its output leaves on RQWFI into
IC4). Commit: kn7000_mame `4944c81`.

**Effects DSP — LLE.** The core `upd6383_device` (`src/devices/cpu/upd6383/upd6383.cpp`, 8345 lines)
is a real executable CPU core with `execute_run()`, C-RAM/D-RAM/descriptor banks, a biquad path
(with the MEASURED factor-of-two), LFO and delay, a disassembler, and heavy instrumentation — but
it is instantiated **disabled** and `run_frame()` discards every frame because most words still
trap (silence by construction). The ISA is a *horizontal microword* (hi12 = enable bits, not an
opcode), and the open frontier on the biquad path is small and specific (`upd6383d.cpp`):

  * **hi12 bits 3:1 — the accumulator operation.** 3 of 8 codes are read (0 = `acc<-P`,
    1 = `acc+=P`, 2 = unchanged); the other five are unknown.
  * **the D-RAM operand pointer origin (`m_dp`)** — OPEN: nothing in the decoded set loads it,
    so the core does not know which state cells hold `x0,x1,x2,y1,y2`.

## The mechanism: the HLE biquad as a per-word ORACLE for the LLE

The effects-DSP HLE (`dsp/hle/`) is proven bit-exact on the biquad (biquad-eq.md: +12.00 dB peak,
impulse response == analytic to 0.000 dB) and runs the **real captured coefficients** (12/12
sections stable, `validate_against_capture.py`). That makes it a *ground-truth generator*: for a
section's coefficients and an input sample it fixes, for each recursive multiply-accumulate, the
coefficient consumed, the operand, the running accumulator, and the required accumulator op.

`dsp/hle/lle_oracle.py` emits exactly that table. On real capture section 0 (C-RAM 0x60..0x65 =
`[b1,b0,b2,-a1,-a2,makeup]`), one biquad sample is **five class-A MACs then a post-sum makeup**:

```
  k  C-RAM  coeff(role)   operand(role)  op    acc_after
  0  0x60   b1            x1             load   <- b1*x1
  1  0x61   b0            x0             mac    += b0*x0
  2  0x62   b2            x2             mac    += b2*x2
  3  0x63   -a1           y1             mac    += (-a1)*y1     (coeff pre-negated on the chip)
  4  0x64   -a2           y2             mac    += (-a2)*y2
     0x65   makeup        (post-sum)     ×      y_out = acc * makeup
```

Confronting a **live per-word LLE trace** (accumulator + operand address after each word) with
this table decides the open unknowns numerically instead of by guesswork:

  * the five `acc_after` values (order-invariant) **confirm the hi12 "+=" op code** — the LLE
    word that turns `acc` from `b1*x1` into `b1*x1 + b0*x0` is carrying that code;
  * the operand of each MAC (`x0/x1/x2/y1/y2`) **pins the D-RAM operand-pointer origin `m_dp`** —
    the consecutive cells the LLE reads must be the x/y history in this order;
  * the cursor 0x60..0x64 consumed one-per-class-A **confirms the coefficient cursor** (MEASURED);
  * the makeup as a post-sum step at 0x65 **is the class-8 post-sum word**, not a sixth cursor MAC.

Because the pair is stored pre-negated, every recursive term is a plain `+=` MAC (no subtract),
which is why a load-then-four-accumulates schedule is the natural one. **Graded honestly:** the SET
of five products and the FINAL sum are hard, order-invariant targets and the coefficient at cursor
k is MEASURED; the step *order* printed is the canonical DF-I schedule — the hypothesis the live
trace tests, not itself a measurement.

## Artifacts (this session)

| file | what it is |
|---|---|
| `dsp/hle/lle_oracle.py` | the per-word oracle: `BiquadOracle`, `sections_from_capture`, demo |
| `dsp/hle/test_lle_oracle.py` | proves the oracle == validated `BiquadDF1` on all 12 real sections (max \|Δ\| = 0), and asserts the load/mac schedule, cursor and post-sum makeup |
| `dsp/hle/lle_trace_diff.py` | confronts a live core trace with the oracle: running-sum → the "+=" op; coef sequence; operand = P/coef → m_dp. `--ops` classifies ops oracle-free; `--selftest` proves it recovers the map from a synthetic trace and rejects a corrupted one |
| `dsp/analysis/data/kn5000-dsp-live-frame-trace-2026-09-10.txt` | the first live per-word trace (285 words) captured from the running DSP |
| (kn7000_mame) `tools/rigs/kn5000_dsp_frame_trace.lua` | drives the KN5000 to run the DSP and dumps the trace |
| (kn7000_mame) `src/devices/cpu/upd6383/upd6383.cpp` | the frame-trace dump made machine-parseable |

Run: `python3 dsp/hle/lle_oracle.py`, `test_lle_oracle.py`, `lle_trace_diff.py --selftest` (all pass).

## Live capture — DONE; the "+=" op is CONFIRMED on hardware-emulation (2026-09-10)

The whole pipeline was built and run end to end, and it produced a real decode result:

1. **The LLE trace dump is parseable** (upd6383.cpp) and the core was **built with
   `KN5000_ENABLE_DSP1=1` and run**; a **full 285-word per-word frame trace was captured** from
   the executing DSP (the committed data file) **with audio flowing into it**.
2. **★ The accumulator op is CONFIRMED on live execution** (`lle_trace_diff.py --ops`):
   - **`f31` (hi12 bits[3:1]) `= 0 → acc ← P` (LOAD)** — 8 clean, 0 contradicting.
   - **`f31 = 1 → acc += P` (ACCUMULATE)** — 5 clean, e.g. iw95 `prev 15729046 + P 900 = 15729946`.
   - and the **biquad's MEASURED factor-of-two is reproduced live**: iw33 `prev + (P<<1) == acc`.
   This turns the hi12[3:1] "+=" reading from established-elsewhere into **measured on the running
   chip model**, through the HLE-oracle toolchain — exactly "use the DSP HLE to aid the LLE".
3. **The audio fix (RULE 12):** signal reaches the DSP only when a note sounds in the **right-hand
   melody zone** (`KEY2` = C4..B4, the R1 voice); the split's left/accompaniment zone (`KEY1`) is
   silent unless ACMP is on — an early C3/E3/G3 chord there gave `peak |mix| = 0`. C4 gives
   `peak |mix| ≈ 16000` (WAV RMS 550). On a silent frame LOAD and ACC are indistinguishable, which
   the comparator states honestly (0 informative words); with audio it decides.

## Session addendum (plan execution) — audio SOLVED; EQ capture is an operational blocker

- **★ AUDIO INTO THE DSP IS SOLVED.** Play the **right-hand melody zone** (`:KEY2`, C4..B4 → R1
  voice): `DSP INPUT AUDIT peak |mix| ≈ 16000`. The split's left/accompaniment zone (`:KEY1`) is
  silent unless ACMP is on. This unblocks RULE 12 for every future capture.
- **`m_program_id` is never set by the driver — it is stuck at 0.** Do NOT use `program=` in the
  trace to tell which effect is running; identify the effect by the **cursor base** instead
  (EQ / unit-0 body starts at cursor `0x00`; the boot-default program's unit body starts at `0x90`).
- **Multiplier structure (from live data):** `P` is the `coef × operand` product at a fixed-point
  scale (iw5: coef 0.5 → `P` ≈ `coef_raw × operand`); the exact scale (P_SHIFT/ACC_SHIFT and the
  biquad `P<<1`) is what the "other" accumulate cases still need. Not yet a clean closed form.
- **⚠ The remaining blocker for `m_dp` and the EQ flagship is OPERATIONAL, not analytic:** reliably
  capturing a *full* EQ frame trace *with audio*. Three finicky couplings: (a) the frame trace
  arms by a DSP-ON frame count while the effective rate is diluted, so `UPD6383_TRACE_FRAME` must
  be tuned to land in the note+effect window; (b) arming mid-frame yields a partial capture; (c) in
  some runs `error.log` ends at boot with no `device_stop` dump. The pieces all work individually
  (nav selects effects by UP presses — user-confirmed; audio flows; the trace dumps) — they need to
  co-occur in one run. Next attempt: hold the melody note, select EQ, arm ~1 frame after EQ lands,
  give generous dwell + timeout, and confirm via cursor base 0x00 before diffing with the oracle.

## Next steps (each its own reviewable change)

1. **`m_dp` origin (the biquad-specific unknown).** UPDATE 2026-09-10 (verified): the kn5000
   machine's DEFAULT BIOS (v10) loads **kn5000_subprogram_v142** — the exact version the origincap
   nav + extractor target — so `kn5000_dsp_origincap.lua TYPEIDX=15` DOES select PARAMETRIC EQ, and
   `kn5000_dsp_frame_trace.lua NAV=1` (aligned to origincap's timing/gate, DSP-on-late) captures an
   EQ frame with audio (peak|mix|≈16000). The origin is NOT a visible pointer-load poke
   ✅ **RESOLVED 2026-09-10.** Running EQ with the SPECULATIVE ISA (DSPCFG bit1) — which enables the
   per-unit cursor rebase and, with `rstcur` in the EQ body, seats the coefficient cursor at 0x00 —
   the live frame trace shows all five EQ bands: coefficients at C-RAM cursor 0x00..0x1D (6 cells/
   band = `[b1,b0,b2,-a1,-a2,makeup]`, b0=0.125 across bands) and their D-RAM operand cells at
   **band k → 0x64+4k** (0x64/0x68/0x6C/0x70/0x74 = the host-written state block {64,68,6C,70,74}).
   So **`m_dp` = the host state block, 0x64 stride 4/band**, read directly from live execution — the
   static replay's "REQUIRED 0x19" was a cursor-model artifact. Evidence:
   `dsp/analysis/data/kn5000-dsp-eq-biquad-trace-2026-09-10.txt`.
2. **Faithful EQ audio (task 5) — now narrowed to the OUTPUT STAGE, not `m_dp`.** In that trace the
   biquad reads coef × **0**: the state cells 0x64+ are zero because neither the input signal nor the
   y-writeback reaches them. Two gaps remain: (a) route the audio input into the biquad's x cell
   (the input latch lands at `m_in_base+2`, which must coincide with the band-0 block), and (b)
   perform the **bit-4 store** (acc → y1/y2), which the core deliberately does NOT do outside the
   K6 twelve ("performing half a word writes invented data"; the known "output stage DISCONNECTED,
   NOZ05 is a RIG not a fix"). That store/output-stage is the real task-5 frontier now.
3. **Feed the confirmed ops back into the core decode** — the hi12[3:1] table (0=load, 1=+=) is now
   measured; the "other" f31=1 cases are the accumulator/datum scale (P_SHIFT/ACC_SHIFT) still to model.
4. **Extend the oracle to the other kernels** (one-pole, LFO, delay). ✅ DONE — `lle_oracle.py` now
   has `OnePoleOracle` and `LFOOracle`, each proven == its kernel (`test_lle_oracle.py`).
5. **Acoustic HLE in MAME** (independent track). ✅ DONE — see the acoustic status above
   (kn7000_mame `4944c81`, behind `WSA1R_ENABLE_ACOUSTIC_HLE`, validated in `wsa1r`). Remaining
   acoustic work is hardware-gated (POSITION absolute scale; IC4 wave ROMs) — task 7, opportunistic.

Builds on: `dsp/hle/` (effects HLE), `wsa1/hle/` (acoustic HLE), `dsp/analysis/biquad-eq.md`,
`dsp/analysis/HOST-to-DSP-coefficient-chain-2026-09-09.md`, and the LLE core's own decode notes
under `kn7000_mame/src/devices/cpu/upd6383/`.
