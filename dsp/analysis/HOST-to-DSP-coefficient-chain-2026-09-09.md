# Closing the loop: host coefficient opcodes ↔ DSP-side decoded roles

**Date 2026-09-09.** Another "other way" — decode the DSP's coefficients from the *host* code
that computes them, then join that to the DSP-side structure decoded by correlation. The two
ends were analysed separately:

- **Host side** (Sub CPU, TLCS-900): `DSP_PerParameterTranslator` (`v142/subcpu/…s:56844`)
  interprets a per-effect record of *parameter opcodes* `0x21..0x79`; each opcode runs a
  coefficient-computation routine and streams the 24-bit result to the DSP with a **space
  TAG** (0x26 C-RAM / 0x15 D-RAM / 0x4C delay-descriptor). Catalogued in `host-side.md` and
  `dsp/algorithms/biquad-eq.md`.
- **DSP side** (uPD6383GF): what the microcode *does* with those coefficients, decoded by
  cross-program correlation in `DECODE-by-correlation-2026-09-08.md` (§1–§16).

Neither doc joined the two. This one does — and where they meet, the decode is confirmed from
**both ends of the host↔DSP boundary at once**, the strongest validation available without
hardware.

## The closed loop, per effect primitive

| host opcode → what it computes (host-side.md) | space TAG | DSP-side role (DECODE-by-correlation) | loop |
|---|---|---|---|
| **0x70 / 0x72 / 0x76** — biquad/SOS designer: `K=tan(πf₀/44100)`, `a0=1+K/Q+K²`, …, emits **6** coeffs `b1,b0,b2,−a1,−a2,makeup` | 0x26 C-RAM | **DF-I biquad section** consuming a **run of 5(+makeup)** coeffs — §7, and §15's **80 run-5 blocks = 80 `ld.ta` entries** | ✅ both ends say 6-coeff DF-I sections, same order |
| **0x74** — LFO **waveform** table upload (sine/triangle/square ROM tables @0x01EAFA…) | 0x15 D-RAM | **class-6 table lookup, addr8=0x18/1A/1E/20** = the LFO waveform read — §6 | ✅ host writes the table, DSP reads it |
| **0x6A / 0x64** — LFO/mod **rate**, integer `f/44100` curve | 0x15 D-RAM | **LFO phase accumulator** (`phase += increment`, wrap @0x7FFFFF) — §7a | ✅ host computes the increment, DSP accumulates it |
| **0x67** — **delay time** `ms×0xAC44/0x3E8` (= ms×44100/1000 → samples) | 0x4C descriptor | **delay-line length / geometry** — C-format `lo12=0x000` (§1); delay stages (§12); the descriptor-borne tap addresses (§4) | ✅ host sizes the delay, DSP runs it |
| **0x6D** — reverb curve (FP) | 0x26 C-RAM | **reverb tank** gains — the all-pass/comb+damp stages of §5 | ✅ host sets tank gains, DSP is the tank |
| **0x65 / 0x78** volume, **0x40** pan, **0x66/0x21** 2-point mix | 0x26 C-RAM | **mix / output-level** coeffs — `op0x66` mix (§7a chorus), `op0x62` output-level (§7d distortion) | ✅ host computes wet/level, DSP multiplies it |
| **0x62** exp LUT, **0x75** EQ curve, **0x71** detune, **0x69** vol-curve | 0x26 C-RAM | per-effect scalar coeffs consumed as **run-1** single fetches (§15) | ✅ single scalars both ends |

## What the join adds

1. **Coefficient VALUES now have a documented provenance.** The correlation work could only
   say "these C-RAM cells are the biquad coefficients / the LFO table / the delay length"; the
   host side says *what number goes there and by what formula* (a bilinear-transform biquad, a
   `ms×44100/1000` delay, an `f/44100` LFO rate). An emulator can now compute the coefficients
   from the user parameters, not just replay captured C-RAM.
2. **The space TAGs are the same three DSP memory regions.** Host TAG 0x26→C-RAM, 0x15→D-RAM,
   0x4C→delay-descriptor is exactly the three-space routing the DSP-side work found (the C-RAM
   coefficient cursor, the D-RAM register/table space, and the descriptor-borne delay taps) —
   the boundary is consistent from both sides.
3. **Two-ended confirmation of the biquad.** The host emits 6 coefficients in order
   `b1,b0,b2,−a1,−a2,makeup` (biquad-eq.md, proven bit-exact) and the DSP consumes a 5-run +
   makeup per DF-I section (§15). Host-writes-6 = DSP-reads-6, same order — the parametric EQ
   is now closed end to end, host formula through DSP execution.

## Runtime validation: reading the real coefficients out of the chip

The static work could only say coefficients are *runtime data*; the rebuilt DSP emulator
(`WSA1R_ENABLE_DSP=1`) lets us read them. Sweeping effect selection on unit 2 and dumping the
coefficient DSPs' C-RAM (`kn7000_mame/tools/rigs/wsa1_dsp_cram_values.lua`, 40 resolved
records) gives real numbers that check the decode:

- **Every coefficient is a Q0.23 fraction in `[-0.972, +0.996]`.** They live in `[-1, 1)`, as
  fixed-point filter/gain coefficients must — and *nothing* is in the ±2 range, independently
  re-confirming §9's correction that the large `±3931`-type words are **addresses, not
  coefficients**. The captured C-RAM even shows the biquad layout directly: 6-cell groups of
  `b1, b0, b2, −a1, −a2, makeup` with `±` value pairs and a recurring make-up term.
- **IC6 is constant across all 40 effects; IC5 is the per-effect set.** IC6's C-RAM has a
  single value-signature over every record, while IC5's cell count changes per effect —
  refining the coefficient-DSP role split (IC6 = fixed/common coefficients, IC5 = per-effect).
- **The IC5 coefficient count tracks effect complexity, matching the static budget (§14) — from
  runtime data.** PEQ and the PEQ-combos load **112–115** cells (richest, the 6-band biquad),
  the reverbs load a uniform **75** (consistent with §2's "few reverb programs + presets" and
  §5's shared tank), simple delays/modulations **58–68**, and NO-OP the baseline **54**. The
  static coefficient-fetch ranking (§14: eq richest → dyn leanest) is thus confirmed by the
  live coefficient counts.

⚠ Scope: the rig dumped IC6 *values* and IC5 *counts*; checking the reverb all-pass gains for
the *descending* ladder of §5 needs the IC5 *values* — a one-line rig change and a re-run,
deferred. What is validated here is the format ([-1,1) Q0.23), the biquad cell layout, the
IC6/IC5 role split, and the per-effect budget.

## Grade and pointers

The host-side facts are established in `host-side.md` / `biquad-eq.md` (not re-derived here);
the DSP-side roles are the graded correlation results of `DECODE-by-correlation-2026-09-08.md`.
This document is the **join** — each row is as strong as its weaker end, but the *agreement*
across the boundary raises confidence on both. Full host catalog (opcodes 0x21–0x79, evaluator
labels, constants): `host-side.md`; DSP-side sections: `DECODE-by-correlation-2026-09-08.md`.
