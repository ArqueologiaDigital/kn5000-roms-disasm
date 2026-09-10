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

**Acoustic modelling — HLE.** The MAME device `l7a1429_device` (`src/mame/matsushita/
acoustic_modeling.cpp`) decodes the 1217-register file into engineering units (`decoded_channel`)
and produces **no audio** — correctly, because it is not yet a `device_sound_interface` and the
internal path is unmeasured. The audio-producing model already exists and is validated *outside*
MAME: `wsa1/hle/l7a1429_hle.py` (coupled digital-waveguide resonators; rings at pitch; sustains
and decays with no key-off; MUTING = loop damping; INTERACTION GAIN coupling). **The HLE task** is
to make the device a sound interface and port that model in, consuming the parameters
`decoded_channel()` already exposes, with the two honest stand-ins behind switches (DRIVER
excitation = undumped IC4 wave ROMs; POSITION absolute scale = a hardware unknown).

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

Run: `python3 dsp/hle/lle_oracle.py` and `python3 dsp/hle/test_lle_oracle.py` (all pass).

## Next steps (each its own reviewable change)

1. **LLE side of the oracle.** Add a per-word trace dump to `upd6383_device` (accumulator +
   operand address after each executed word) so a live EQ frame can be diffed against
   `lle_oracle.py`. This touches the core — do it as an instrumentation-only change first.
2. **Crack the "+=" code and `m_dp` origin** from that diff, on the PARAMETRIC EQ body (the
   best-instrumented program: cursor map proven to the bit, 6 cells/band).
3. **Extend the oracle to the other kernels** (one-pole damping, LFO phase-accum→table, delay
   line) — the HLE already has each (`dsp/hle/kernels.py`), so each becomes a decode target too.
4. **Acoustic HLE in MAME.** Make `l7a1429_device` a `device_sound_interface` and port
   `wsa1/hle/l7a1429_hle.py`, stand-ins behind switches. Independent of the DSP LLE work.

Builds on: `dsp/hle/` (effects HLE), `wsa1/hle/` (acoustic HLE), `dsp/analysis/biquad-eq.md`,
`dsp/analysis/HOST-to-DSP-coefficient-chain-2026-09-09.md`, and the LLE core's own decode notes
under `kn7000_mame/src/devices/cpu/upd6383/`.
