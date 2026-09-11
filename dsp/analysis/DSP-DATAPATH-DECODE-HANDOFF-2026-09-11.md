# uPD6383GF datapath decode — session handoff (2026-09-11)

State of the effects-DSP LLE decode after this session's work on
`PLAN-the-rest-2026-09-10.md`. Every claim below is graded by provenance and
backed by a committed, reproducible tool (named per item). Read this first, then
the inline notes in the plan doc.

## 1. MEASURED this session (bit-exact against live hardware traces)

- **Biquad multiplier:** `P[N] = (coef[N-1] × L[N]) >> 6`. Coefficient latched one
  word early (coef pipeline depth 1); operand = current-row latch; shift 6 =
  `P_SHIFT`. Bit-exact 27/27 on the seeded EQ trace INCLUDING band boundaries.
  Tool: `dsp/tools/biquad_pipeline_probe.py` (truth = the chip's P register).
- **Biquad accumulator:** one-slot pipeline `acc[N] = acc[N-1] + P[N-1]`;
  `f31=0 → acc←P` (verified 8/8), `f31=1 → acc+=P`; store/makeup writes the
  band's y. Same probe, sections 1 & 4.
- **Operand source (interior):** `L[N] = mem[N-1]` — the D-RAM cell at `dp`, one
  slot late (38/43; the 5 exceptions are band boundaries where L is a stored,
  saturating y). Same probe, section 5.
- **Multiplier GENERALISES:** the same `(coef[N-1]×L[N])>>6` holds on a SECOND
  program (boot-default program 0, real audio RMS 550), 18/21 (the 3 misses are
  frame-startup rows whose P carries the prior frame's acc). So it is the chip's
  general multiplier, the primitive every downstream stage uses.
  Tool: `biquad_pipeline_probe.py <program-0 trace> --all-rows`.

## 2. LOCALISED / ENUMERATED — the precise open targets (the 4.2 audio gate)

The external audio DOES reach the DSP (deposited to D-RAM 0x01/0x04, confirmed in
the AUDIO=key trace) and DOES reach the input-stage MULTIPLY (w5/w10 read L =
DI-latch value; their multiply is the standard `(coef×L)>>6`). What is open is the
ACCUMULATOR/STORE side of the input-stage words. Reduced to a checklist:

- **Unanchored codes gating the route:** SRC {0x08, 0x11(=accb)}, ACT {0x08,
  0x0D, 0x0E(=P←bus), 0x17}, plus admitting `f31=2` (acc-unchanged latch-read)
  off class 8. Tool: `dsp/tools/input_route_guards.py`.
- **Route tail already works:** w9 (`ST mem[X+6]`, the product the mix block
  consumes) and w6 decode strict.
- **Causal chain:** w5/w10 read the audio but are unexecuted (open codes) → the
  audio never enters the accumulator that the decoded w9 stores → the mix block
  gets an audio-free value. Anchor the ~6 codes and the route goes live.
- **accb writer LOCATED** (root of the chain — SRC 0x11 can't be anchored until
  accb has a known non-zero value to match): a class-1 / hi12=0x400 / ACT=0x07
  word does `accb←acc`; other transitions show `accb+=P` and `accb←0`. accb is a
  SEPARATE register (NOT a delayed acc — refuted), live only in a narrow window.
  Tool: `dsp/tools/accb_writer_probe.py`.

## 3. REFUTED / CORRECTED this session (would-be wrong decodes, caught)

- **5.1 "reverb needs no route":** FALSE. On the real-audio frame the reverb unit
  (unit-1) is STARVED — 1/133 live operand, acc frozen — because the unit-0→unit-1
  handoff doesn't carry signal. 5.1 is gated on the same route class as 4.2.
- **"w5 = input injection L<<16":** a coef=0.5 (=2²²) DEGENERACY of `(coef×L)>>6`,
  not a special op. Retracted; the probe now flags coef=0.5 rows.
- **"accb = pipeline-delayed acc":** refuted (best `accb[N]==acc[N-k]` 29%, just
  shared zeros). accb has its own writer.

## 4. NEXT-SESSION RECIPE (in dependency order)

1. **Multi-frame accb campaign.** Sweep `UPD6383_TRACE_FRAME` over many DSP-ON
   frames (build-lane, `kn5000_dsp_frame_trace.lua`); run `accb_writer_probe.py`
   on each; collect accb transitions where **acc ≠ P** to split `accb←acc` from
   `accb←P`, and confirm `accb+=P` / `accb←0` at N-clean/0-contradicting. This
   anchors the accb writer → then SRC 0x11 (=accb) via the source-operand
   classifier (match live L against acc/accb/coef/mem).
   > ✅ **OPERATIONAL BLOCKER SOLVED (2026-09-11) — the harness needs `-log`.** The
   > frame trace is emitted via `logerror` (upd6383.cpp:1627), which reaches a file
   > ONLY with MAME's `-log` (writes `error.log`) — the upload messages I saw use
   > `osd_printf` (always visible), which masked the difference. Adding `-log` and
   > reading `error.log` (strip the `[:dsp1] ` line prefix before parsing) dumps the
   > full trace (verified: 285-slot frame, DSP clock 44100 Hz, DSPCFG read 0x3).
   > ⚠ **RETRACTED same-day**: the earlier "build-staleness / stale `kn5000_tonegen.o`"
   > diagnosis was WRONG — a clean rebuild did NOT change the symptom; the missing
   > `-log` did. (The rebuild was harmless.) **WORKING CAPTURE RECIPE:**
   > `DISPLAY=:0 NAV=0 AUDIO=key BOOTGATE=10 DWELL=25 DSPVAL=1 UPD6383_TRACE_FRAME=<F>
   > timeout 110 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log
   > -autoboot_script tools/rigs/kn5000_dsp_frame_trace.lua` then
   > `sed 's/^\[:dsp1\] //' error.log | accb_writer_probe.py /dev/stdin`.
   > ⚠ **REMAINING for the accb-op split**: sustained-tone frames all converge to a
   > FIXED POINT (accb load has acc==P=2603010048, so accb←acc vs accb←P is not
   > split); short arm frames land mid-frame (107 slots) and miss the accb region
   > (unit-1 rows ~130-134). Need a FULL (285-slot) frame during the note ATTACK
   > TRANSIENT (acc≠P) — a precise arm-frame at a frame boundary shortly after
   > note-on. That arm-timing precision is the residual sub-task (plan line 186's
   > "no mid-frame arming"). The harness itself is no longer the blocker.
2. **Store-target codes ACT {0x08,0x0D,0x0E,0x17}.** These need an observable
   store, which strict decode refuses (the words don't execute). Resolve from the
   bit-encoding cross-reference (their addressing IS decoded; the store TARGET is
   mode-dependent — analysis/output-stage-decode.md) or a hardware reference.
   NOT capturable passively — do not guess.
3. **With 1+2, the input route (4.2) goes executable** → re-capture and validate
   `mem[0x64]≠0` and the biquad computing on real x0 (4.3), then the one-pole
   reverb (5.1) with a live y1, then LFO/delay (5.3/5.5).
4. **Phase 6** (speaker-audible LLE) follows once the whole frame runs trap-free.

## 5. HARDWARE BOUNDARY (not tasks — unreachable)

- Store-scaling constant of the biquad cascade (the saturating acc→datum makeup),
  best decoded with a re-seed of smaller values (avoid saturation) — build-lane,
  optional; the biquad transfer function is already reproduced by the HLE oracle.
- Phase 2 KN5000 EQ coefficient order (the WSA1R order is Jury-unstable on KN5000
  coeffs); needs the real tap→coef assignment, which needs live signal (gated on
  4.2) or hardware.
- POSITION absolute scale and IC4 wave ROMs: PROVEN absent from the dumps /
  undumped — not derivable. Do not re-attempt.

## Tools committed this session (all reproducible, no build needed)
`dsp/tools/biquad_pipeline_probe.py`, `input_route_probe.py`,
`input_stage_alu_probe.py`, `input_route_guards.py`, `accb_writer_probe.py`;
evidence trace `dsp/analysis/data/kn5000-dsp-eq-biquad-trace-SEEDED-2026-09-11.txt`.
