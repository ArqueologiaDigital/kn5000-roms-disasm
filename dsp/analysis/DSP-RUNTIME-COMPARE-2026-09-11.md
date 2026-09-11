# KN5000 DSP — runtime observed vs decode expected, and next steps (2026-09-11)

Follows the run-all survey (`DSP-PROGRAM-RUN-SURVEY-2026-09-11.md`). It compares what the LIVE
per-word frame trace shows against what the static decode (programs.tsv / prog*.dsm headers)
predicts, and plans the next steps from the discrepancies. Per-word traces captured via
`peq_gain.lua TYPEIDX=N NPARAM=0 NVALUE=0 UPD6383_TRACE_DETAIL=1 UPD6383_TRACE_FRAME=2100000`.

## Two corrections to the survey's first pass (contradict-and-correct)
- **"Per-word trace gated live" — RETRACTED.** It was a rig artifact: `kn5000_dsp_frame_trace.lua`
  did not fill the `m_trace` buffer. `peq_gain.lua` does — per-word traces are available for the
  whole corpus.
- **"Upload words" — RETRACTED as a size measure.** It was cumulative navigation transfers
  (monotonic with TYPEIDX). The real per-program measure is the C-RAM nonzero count / the isolated
  image word count below.

## Observed (live frame) vs expected (static image)

| program | expected image words | LIVE frame words | frame − image | isolated unit-0 program (iw≥84) | expected class-A | isolated class-A |
|---|---:|---:|---:|---:|---:|---:|
| SINGLE DELAY (algo 9) | 48 | 263 | 215 | **48** ✓ | 18 | **18** ✓ |
| COMPRESSOR (algo 36) | 40 | 255 | 215 | **40** ✓ | 10 | 8 |
| OVERDRIVE (algo 33) | 63 | 278 | 215 | **63** ✓ | 18 | **18** ✓ |
| FLANGER (algo 4) | 65 | 280 | 215 | **65** ✓ | 18 | 16 |

## What the comparison establishes (VALIDATED)
1. **The live frame decomposes EXACTLY as kernel(82) + selected unit-0 program image + unit-1
   reverb(133).** 82+48+133=263, 82+40+133=255, 82+63+133=278, 82+65+133=280 — all four exact. The
   constant `frame − image = 215` is the kernel(82)+reverb(133) that always runs.
2. **The isolated unit-0 program word count MATCHES the static disasm image word count EXACTLY** for
   all four programs (48/40/63/65). This is a direct, live cross-validation of the decode's program
   sizes — the disassembly's word counts are correct against what the chip runs.
3. **Class-A multiply counts match closely**: exact for SINGLE DELAY and OVERDRIVE (18/18); FLANGER
   16 vs 18 and COMPRESSOR 8 vs 10 run FEWER class-A words live than the static image lists. That gap
   (2 words each) is the interesting signal: those class-A words are **input/state-gated** and did not
   fire in the sampled steady frame — candidates for the LFO/dynamics conditional paths.
4. **Per-program operand cells are visible**: all use the stereo-twin band cells 0x50–0x57 + 0x05,
   0x0E, 0x10; program-specific cells appear (FLANGER 0x07–0x0B, SINGLE DELAY 0x07/0x08/0x0F,
   COMPRESSOR 0x14). This is the live datapath, per program.

## Expected-vs-observed: no surprises, one lead
Everything matches the decode (sizes exact, class-A within 2, decomposition exact) — a strong
confidence check that the static disassembly reflects live execution. The ONE lead is finding 3:
the 2 class-A words per program that DON'T fire live are the input/state-conditional ops, which is
exactly the family of behaviour (LFO gating, dynamics threshold) the decode marks lower-confidence.

## Next-steps plan (from the comparison)
1. **Per-program datapath validation, corpus-wide** [now unblocked]: for each program, isolate its
   iw≥84 unit-0 words from a live `peq_gain` per-word trace and diff its class-A ops / operands /
   coefficients against `prog*.dsm`. Word-count and class-A cross-checks are cheap and catch decode
   drift; run them as a regression over all 38 images.
2. **Chase the non-firing class-A words** [the lead]: for FLANGER/COMPRESSOR (and any program whose
   live class-A < static), identify WHICH image words didn't fire and why (LFO phase / threshold
   gating) — capture across several frames to see if they fire on other phases. This decodes the
   conditional paths the static analysis marks uncertain.
3. **Family datapath probes on the isolated program** [the deep inspection]: with the program's
   words isolated, run the family-specific checks — modulation LFO ramp per frame (compare to the
   ROM-ramp constants the harness only simulated), distortion waveshaper LUT, delay-DRAM taps — each
   now confrontable with a LIVE trace, not just the Python sim.
4. **Feed the EQ/reverb open questions**: the isolated unit-1 reverb words (133) are the same across
   programs — a per-program reverb-coefficient diff; and the unit-0 EQ/combi images (algos 71–99)
   let the biquad realization work (N2) run on live per-word traces now that they are capturable.

## Discipline
Live per-word traces via `peq_gain.lua` (fills `m_trace`); isolate by I-RAM slot (iw<84 kernel,
iw≥84 unit-0 program, u1 = reverb); cross-check word/class-A counts against `prog*.dsm`; grade
live-vs-static gaps as leads, not errors, until decoded. Timeout-wrap, visible video, `-log`.
