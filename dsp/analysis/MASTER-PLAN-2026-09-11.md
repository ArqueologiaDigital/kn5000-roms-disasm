# KN5000/WSA1R DSP — MASTER PLAN (merged + runtime-updated, 2026-09-11)

**This single plan supersedes and merges:** `PLAN-the-rest-2026-09-10.md` (Phases 1–6),
`PLAN-speculative-strategies-2026-09-11.md` (S1–S8), `NEXT-ACTIONS-2026-09-11.md` (N1–N4),
`PLAN-complementary-approaches-2026-09-11.md` (M1–M6), `PLAN-next-actions-2026-09-11b.md` (P1–P5).
Those remain as history; this is the source of truth. Cross-refs kept so the old IDs resolve.

## A. Where we are (consolidated status)

**DONE / VALIDATED:**
- Biquad datapath decoded bit-exact (P=(coef×L)>>6, one-slot acc, load, store). *(Phase 1)*
- **N1** role-split premise refuted; **N1′** EQ coefficient memory located (C-RAM 0x00+), **13.5 kHz
  red flag resolved** (bands spread 673–3219 Hz); reconciliation: operand = C-RAM ÷ 2 exact.
- EQ subtractive-feedback sign; shared-delay (DF-II-family) corroborated from a seeded trajectory.
- **P1** the biquad +2/+3 y-history writer decoded = iw=150 (band-1 cross-band entry store).
- Reverb: delay-advance decoded (READ_CELL−WRITE_CELL, adjudication-round5); tail structure
  (ER taps, pipe-comb family) on record; seed-once decay harness works (**N4** premise corrected).
- **Run-all survey**: 20 of 38 distinct images triggered live (every family); trigger catalog's
  panel prerequisites validated across the page.
- **Runtime observed-vs-expected (NEW, the big update)**: the live per-word frame decomposes EXACTLY
  as **kernel(82) + unit-0 program image + unit-1 reverb(133)**; the isolated program word count
  MATCHES the disasm image count exactly (48/40/63/65); class-A counts match (18/18 exact for SINGLE
  DELAY/OVERDRIVE). **The static decode is cross-validated against live execution.**
- HLE reference models for both DSPs render + self-validate (EQ +12 dB→+12 dB, part228).

**WALLED (not executable this session without crossing a line):**
- **N2** biquad canonical-vs-transposed realization — needs a clean known input + live recursion; the
  seeded capture degenerates (constant input) and audio-driven recursion doesn't engage → gated on
  the undecoded **input→biquad→state-rotation mechanism**. (M1/P2 attempts; no topology call =
  fabrication-avoidance.)
- Input-route ALU decode (ACT 0x0D/0x0E located as delay-mixing by M2; SRC 0x08/0x11 = C-RAM/accb)
  — deciding the readings needs ground truth: **hardware (unreachable) or ISA bit-encoding**.
- **N3** in-core audible EQ — audible output exists+validated in the HLE; wiring into the parked LLE
  core is deliberately deferred by Felipe's architecture (port later, gated on hardware).
- Reverb tail gain-mapping (M5) — needs seeding the external delay-DRAM, and the tail is already
  decoded structurally; low marginal value.
- L7A1429 acoustic fidelity (Phase 3), WSA1R hardware cross-checks — hardware/wave-ROM-gated.

**ACHIEVABLE NOW (unblocked by the runtime analysis — this is where execution goes):**
- **T1. Per-program datapath regression** — per-word traces are capturable for the WHOLE corpus via
  `peq_gain.lua TYPEIDX=N + TRACE_DETAIL` (the "gated" survey finding was a rig artifact). Isolate
  each program's iw≥84 unit-0 words, cross-check word/class-A/cells against `prog*.dsm`. Cheap
  decode-drift regression over all 38 images.
- **T2. Chase the input-gated class-A words** *(the runtime-comparison lead)* — FLANGER (16 live vs 18
  static), COMPRESSOR (8 vs 10): identify WHICH image words don't fire live and why (LFO phase /
  dynamics threshold). Capture across frame phases; this decodes the conditional paths the static
  analysis marks low-confidence.
- **T3. Family datapath probes on the isolated program** — modulation LFO ramp per frame vs the ROM
  constants the harness only *simulated*; distortion waveshaper; delay-DRAM taps — now confrontable
  with a LIVE trace, not just the Python sim.
- **T4. Speculative tier (S8)** — feed confirmed live findings into the disassembler's speculative
  tier with provenance; keep two tiers separate.

## B. The plan, ordered (execute A→D of the achievable set; the walled/boundary items are parked)

1. **T1 regression** [do now]: capture per-word traces for the remaining distinct non-stub images
   via `peq_gain TYPEIDX=N`, isolate iw≥84, and build a table of live-vs-static (words, class-A,
   cells) per program. Accept a program as "runtime-validated" iff live image word count == static
   and class-A matches within the gated-word tolerance. Commit the regression tool + results.
2. **T2 chase gated words** [do now, the lead]: for each program with live class-A < static, list the
   non-firing image words (iw, opcode) and classify the gate (LFO/threshold/input). Multi-frame
   capture to see if they fire on other phases.
3. **T3 family probes** [next]: on FLANGER/CHORUS isolate the LFO cell and read its per-frame ramp;
   compare to the ROM-ramp constants (unblocking-and-discriminators simulated: FLANGER 38/frame,
   etc.). On OVERDRIVE isolate the waveshaper. On SINGLE DELAY the delay-DRAM taps (lag 1001).
4. **T4 speculative tier** [ongoing]: record confirmed live datapath facts into the disassembler.
5. **Parked (boundary)**: N2/input-route (hardware/ISA), N3 in-core (architecture), reverb gain
   (low value), L7A1429/WSA1R hardware — documented, not forced, no fabrication.

## C. Discipline (unchanged)
Per-word traces via `peq_gain.lua` (fills `m_trace`); isolate by I-RAM slot (iw<84 kernel, iw≥84
unit-0 program, u1=reverb); cross-check against `prog*.dsm`; grade live-vs-static gaps as leads not
errors; timeout-wrap, visible video, `-log`; commit each number's producing script same session; no
fabricated determinations; two tiers (measured/speculative) never merged.
