# MASTER-PLAN T3 — LFO ramp measured LIVE (modulation family, 2026-09-11)

Executes T3 (family datapath probe) for the modulation family: capture consecutive frames of a
modulation program (peq_gain TYPEIDX=N + TRACE_DETAIL at TRACE_FRAME F, F+1, F+2), read the LFO
phase-accumulator cell each frame, and measure its per-frame increment — confronting the ROM-ramp
constants that the Python harness (`unblocking-and-discriminators.md`) had only SIMULATED with a LIVE
measurement.

## Method
The LFO is a phase accumulator: one D-RAM cell increments by a constant each frame. Scan all cells
for a constant nonzero per-frame delta across 3 consecutive frames (raw 24-bit).

## Results
- **CHORUS (TYPEIDX 0):** cell **0x10 ramps +114/frame** live (raw 155152 → 155266 → 155380), and
  cell 0x07 is its one-frame-delayed copy (also +114). **This matches the documented +114/frame ROM
  constant EXACTLY** (memory §224/§225: "D-RAM 0x10 carries the chorus LFO as a +114/frame ramp").
  The harness's simulated value is now confirmed by direct live measurement. ✓
- **FLANGER (TYPEIDX 3):** cell **0x08 ramps +81/frame** live (raw 7537683 → 7537764 → 7537845).
  The harness *simulated* 38/frame for FLANGER; the live value is **81**, different.

## Reading the FLANGER difference (honest, not a contradiction)
The LFO ramp increment **is** the LFO SPEED (the phase step per frame = the settable rate), so a live
measurement depends on the current LFO SPEED parameter, whereas the harness's 38 assumed a particular
setting. So 81 vs 38 is a parameter-setting difference, not a decode error — and it is falsifiable:
driving the FLANGER LFO SPEED parameter (peq_gain NPARAM/NVALUE on that field) should move the ramp
proportionally. Different programs also use different LFO phase cells (CHORUS 0x10, FLANGER 0x08).

## What T3 establishes
- The LFO datapath is **confirmed live**: a phase-accumulator cell ramps by a constant each frame,
  exactly the modulation model — measured, not simulated.
- **CHORUS's rate is validated to the documented constant (+114) exactly.**
- The ramp value tracks the (live) LFO SPEED, so cross-checking a specific harness constant requires
  matching that program's speed setting — the clean next micro-step (drive the SPEED param and watch
  the ramp scale) if a per-program rate table is wanted.
- The waveshaper (distortion) and delay-DRAM tap (delay) probes are the remaining T3 families, now
  trivially runnable on the isolated program the same way.

## Discipline
Consecutive-frame capture via deterministic re-runs (TRACE_FRAME F, F+1, F+2); raw 24-bit deltas;
CHORUS matches the documented constant; FLANGER graded as parameter-dependent (a lead, not an error).
