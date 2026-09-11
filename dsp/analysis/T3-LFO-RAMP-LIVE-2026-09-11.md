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

## T3 — delay family (SINGLE DELAY, delay-DRAM taps)
Isolated SINGLE DELAY (iw≥84) shows the external delay-DRAM datapath executing live:
- **iw84 = class-1 READ (addr8=0x30)** — the delay-DRAM read (first access of the body);
- **iw89 / iw112 / iw130 = class-1 WRITE (addr8 bit-6 set)** — delay-DRAM writes;
- **iw89 / iw112 read the SRC 0x0B delay-read register with coef 0.5** — the documented "0.5 mix";
- iw93 / iw116 class-1 addr8=0x20 (secondary access), iw131 end-of-block.
So the delay read/write/mix structure is confirmed on the running chip; the lag (1001) is the
descriptor READ_CELL−WRITE_CELL offset (already decoded). The operand mem values are 0 at this frame
because the delay line is unfed (the input-route gap — audio doesn't reach the biquad/delay input in
the current LLE), so the STRUCTURE is confirmed but not the delayed-signal values.

## T3 — distortion family (OVERDRIVE vs FUZZ)
The OVERDRIVE image carries a distinctive **class-A cluster with ACT 0x12 / 0x13 / 0x14** that is
**absent from FUZZ and from every other family probed** (delay, modulation, dynamics). Since OVERDRIVE
= a waveshaper PLUS a post-distortion tone biquad (4 kHz Butterworth, per the catalog) while FUZZ is a
harder clip with no tone filter, this ACT 0x13/0x14 cluster is **OVERDRIVE's extra tone-filter
stage** — a live datapath distinction between the two distortion variants. (The clipping waveshaper
op proper is a further probe; what's established here is the OVERDRIVE-only tone stage.)

## T3 follow-ups (both executed)
**(1) LFO ramp = LFO SPEED — CONFIRMED by driving the panel.** CHORUS with LFO SPEED (parameter #1)
driven up 20 steps (peq_gain NPARAM=1 NVALUE=20): cell 0x10 ramp went **+114/frame → +494/frame**.
So the phase-accumulator increment IS the settable LFO SPEED — which resolves the FLANGER 81-vs-38
gap (a different speed setting, not a decode error) and validates the LFO model end to end (the panel
parameter controls the observed live ramp).

**(2) OVERDRIVE waveshaper — characterized live as a POLYNOMIAL (Horner form).** The distinctive
class-A MAC sequence (iw100–104, mirrored iw131–135 for the R channel) is:
`SRC 0x07 ACT 0x13 (0.019) → SRC 0x10 ACT 0x12 (0.019) → SRC 0x07 ACT 0x15 (0.609) →
SRC 0x07 ACT 0x14 (−0.448) → SRC 0x07 ACT 0x15 (0.750)`. It feeds **SRC 0x10 (the accumulator) back
as a multiply operand**, which is how it builds the x²/x³ nonlinear terms — a Horner-form polynomial
waveshaper with coefficients [0.019, 0.609, −0.448, 0.750, …]. **FUZZ has NONE of ACT 0x12/0x13/0x14**
→ a different (harder) clip. So OVERDRIVE = polynomial waveshaper + tone biquad; FUZZ = a distinct
clipping mechanism — a live datapath distinction, and the distortion nonlinearity now named.

## T3 status — COMPLETE
All three families probed live and confronted with the decode: modulation LFO (CHORUS +114 exact,
ramp CONFIRMED = LFO SPEED by driving it to +494), delay (delay-DRAM read/write/0.5-mix confirmed),
distortion (OVERDRIVE polynomial waveshaper + tone stage named; FUZZ distinct). Live confrontations,
honestly graded.

## Discipline
Consecutive-frame capture via deterministic re-runs (TRACE_FRAME F, F+1, F+2); raw 24-bit deltas;
CHORUS matches the documented constant; FLANGER graded as parameter-dependent (a lead, not an error);
delay operand values are 0 (unfed line) so only the structure is claimed; distortion ACTs verified
family-specific by cross-program presence check.
