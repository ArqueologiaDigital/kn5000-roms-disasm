# FLANGER: parameters located by intervention, and made audible in MAME (2026-09-11)

Fourth effect (after EQ, single delay, chorus). FLANGER is **TYPEIDX 3 on the DSP EFFECT
page** (image algo 8, unit 0). Topology: a **swept all-pass chain / LFO-swept delay WITH
feedback** — the chorus topology plus a feedback (resonance) path. Its C-RAM layout DIFFERS
from the chorus (probed separately, as the chorus note warned: its LFO phase is a different
cell). Panel params (0-based): `0 DEPTH, 1 LFO SPEED, 2 RESONANCE, 3 MANUAL, 4 PHASE,
5 LFO WAVEFORM, 6 VOLUME, 7 REV SEND`.

## Pinned by intervention (MEASURED) — each param moved an L+R cell pair
- **RATE / LFO SPEED = C-RAM cell 0x05** (twin R = 0x09). The phase increment: driving LFO
  SPEED (NPARAM=1) +20 moved it **38 → 418** (raw). f = inc × 44100 / 2²³, so 38 → **0.20 Hz**
  at rest (a slow flange; the chorus's cell 0x00 sits at 114 = 0.6 Hz — a genuinely different
  default AND a different cell).
- **RESONANCE / FEEDBACK = C-RAM cell 0x00** (twin R = 0x0D). Driving RESONANCE (NPARAM=2)
  moved it **0.594 → 0.792** (cell scale). At the operand scale the multiplier reads (half),
  the default feedback ≈ **0.30** — exactly the documented flanger feedback (programs.tsv
  prog04 "0.3 feedback"). This feedback is what turns the moving comb into the deep resonant
  flange.
- **DEPTH (panel) = C-RAM cell 0x08** (twin R = 0x0C). Driving DEPTH (NPARAM=0) moved it
  **0.808 → 1.000**; used to scale the LFO sweep amplitude. Cell 0x06 = wrap 0x7FFFFF (2²³).

## Made audible + validated in MAME (kn7000_mame)
`kn5000_tonegen.cpp` HLE FLANGER insert (DSPHLE selector == 4, default OFF): per channel a
single LFO-swept delay tap fed back into the line — `line[n] = x + fb·tap`, `tap =
line[n − (base + depth·(0.5+0.5·sin))]`, 50/50 dry/wet. RATE from cell 0x05, feedback from
cell 0x00, sweep scaled by the DEPTH cell 0x08; same DSPCFG-bit-1 cell/operand scale rule and
44.1k→48k conversion as the chorus.

A/B (`chorus_ab.lua` TYPEIDX=3 single sustained note + `chorus_ab.py`, DSPCFG=2): the rest rate
(0.20 Hz) is too slow to resolve in one note, so LFO SPEED was driven +6 → the flanger
modulates the held note at **0.77 Hz** (matching the predicted 0.80 Hz for the driven cell
0x05), **44.7× above the dry control**. PASS. (The instrument voice's own tremolo at ~2.6 Hz is
in the dry too and is excluded by the LFO-band test.)

## Open (SPECULATIVE / future)
- **MANUAL** (NPARAM 3): the static delay offset (flanger centre); not pinned — a fixed short
  base is used. **PHASE** (NPARAM 4): L/R LFO phase offset (stereo width); not modelled.
- **Base/sweep in absolute samples**: the DEPTH cell (0..1) scales a fixed max sweep (~5 ms);
  the exact sweep/base in samples is not separately pinned.
- **LFO WAVEFORM** (NPARAM 5): selects the class-6 table; the HLE uses a sine.
- The chip's faithful structure is a swept ALL-PASS chain; the HLE uses a feedback delay (comb)
  as a drop-in that produces the same swept resonant-notch signature.
