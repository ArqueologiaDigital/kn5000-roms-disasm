# ENSEMBLE + VIBRATO: located by intervention, and made audible in MAME (2026-09-11)

Sixth and seventh effects — both chorus-family (LFO-swept delay), pinned by the same
intervention method and reusing the chorus machinery.

## ENSEMBLE (TYPEIDX 5, algo 6, DSPHLE == 6) — a multi-voice chorus
Panel params: `0 DEPTH, 1 LFO SPEED, 2 LFO WAVEFORM, 3 VOLUME, 4 REV SEND`.
- **RATE / LFO SPEED = C-RAM cell 0x00**: drove 76 → 456; f = inc × 44100/2²³, so **0.40 Hz**
  at rest.
- **Panel DEPTH moves SIX small-integer cells** — 0x02/0x04/0x06 (L) and 0x09/0x0B/0x0D (R),
  raw 60/70/100 and 50/100/80 — the **per-voice tap delays** (44.1k samples). A genuine
  multi-voice ensemble: three detuned voices per channel, their spread widening with DEPTH.
- HLE: one delay line per channel read at the three tap delays, each swept by the LFO at a
  staggered phase (0, ⅓, ⅔), summed, mixed 50/50 with the dry.
- A/B (`chorus_ab.lua` TYPEIDX=5, LFO SPEED +4 → 0.8 Hz): modulates the note at **0.77 Hz**,
  **101× over dry**. PASS.

## VIBRATO (TYPEIDX 17, algo 50, DSPHLE == 7) — pitch modulation
Panel params: `0 DEPTH, 1 LFO SPEED, 2 PHASE, 3 LFO WAVEFORM, 4 VOLUME, 5 REV SEND`.
- **RATE / LFO SPEED = C-RAM cell 0x02** (twin 0x06): drove 760 → 1331; **~4.0 Hz** at rest —
  faster than the chorus/flanger/phaser, as a vibrato should be.
- **Panel DEPTH = C-RAM cell 0x05** (twin 0x09): 0.202 → 0.404 — the pitch-sweep depth.
  Cells 0x0C/0x0D = 0.5 (the mix).
- HLE: a single LFO-swept read tap per channel, mostly wet (so the ear hears the pitch
  wobble, not chorus beating).
- A/B (`chorus_ab.lua` TYPEIDX=17, rest rate, band 3.2-5.5 Hz to skip the voice's ~2.6 Hz
  tremolo): modulates the note at **4.02 Hz** (= the decoded rate), **289× over dry**, and a
  frequency scan shows the modulation is specifically at 4.0 Hz. PASS.

## Reproducibility
Interventions and A/Bs reuse `dsp/tools/chorus_ab.lua` (TYPEIDX 5 / 17) + `chorus_ab.py`
(now taking an optional band `lo hi` for a faster LFO). Seven effects now validated in the
emulator: EQ, delay, chorus, flanger, phaser, ensemble, vibrato.

## Open
- ENSEMBLE: the exact per-voice sweep amplitude (a modest fixed sweep is used; the six cells
  are the base tap delays) and the voice count if > 3.
- VIBRATO: the exact wet/mix (cells 0x0C/0x0D = 0.5; a mostly-wet mix is used for a clear
  vibrato character), PHASE (stereo L/R offset), waveform.
