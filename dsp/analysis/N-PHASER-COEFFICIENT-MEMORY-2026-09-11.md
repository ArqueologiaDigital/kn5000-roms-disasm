# PHASER: parameters located by intervention, and made audible in MAME (2026-09-11)

Fifth effect (after EQ, single delay, chorus, flanger). PHASER is **TYPEIDX 4 on the DSP
EFFECT page** (image algo 8's sibling). Topology: a **cascade of swept all-pass sections with
feedback** (the phaser/flanger family = cascaded all-pass, per the topology census). Panel
params (0-based) are the flanger set: `0 DEPTH, 1 LFO SPEED, 2 RESONANCE, 3 MANUAL, 4 PHASE,
5 LFO WAVEFORM, 6 VOLUME, 7 REV SEND`.

## Pinned by intervention (MEASURED) — each param moved an L+R cell pair
- **RATE / LFO SPEED = C-RAM cell 0x00** (twin R = 0x0C). Phase increment: driving LFO SPEED
  moved it **76 → 456** (raw). f = inc × 44100 / 2²³, so 76 → **0.40 Hz** at rest.
- **MANUAL = C-RAM cell 0x06** (twin 0x09), **0.736 → 0.791**: the all-pass CENTRE coefficient
  (the notch centre frequency). ONE shared MANUAL cell ⇒ a cascade of identical all-pass
  stages.
- **DEPTH = C-RAM cell 0x05** (twin 0x08), **0.081 → 0.100**: the all-pass coefficient SWEEP
  amplitude (how far the notches move).
- **RESONANCE / FEEDBACK = C-RAM cell 0x02** (twin 0x0A), **0.594 → 0.792**: feedback ≈ **0.3**
  at the operand scale — deepens the notches. Cell 0x01 = wrap 0x7FFFFF.

## Made audible + validated in MAME (kn7000_mame)
`kn5000_tonegen.cpp` HLE PHASER insert (DSPHLE selector == 5, default OFF; new `AllPass1`
first-order all-pass kernel in `kn5000_dsp_hle.h`): PH_STAGES = 6 all-pass sections per
channel sharing one coefficient `a = MANUAL + DEPTH·sin(LFO)`, the cascade output fed back
into its input (feedback = RESONANCE) and mixed 50/50 with the dry. RATE from cell 0x00 (cell
scale = the applied increment); the MANUAL/DEPTH/RESONANCE coefficients read at the operand
scale (cell/2); same DSPCFG-bit-1 rule as the other modulation effects.

A/B (`chorus_ab.lua` TYPEIDX=4 single note + `chorus_ab.py`, DSPCFG=2): the rest rate (0.40 Hz)
is slow, so LFO SPEED was driven +4 → the phaser modulates the held note at **0.77 Hz**
(matching the predicted 0.80 Hz for the driven cell 0x00), **55.3× above the dry control**.
PASS.

## Open (SPECULATIVE / future)
- **Stage count / order**: the census suggested many sections; the HLE uses 6 first-order
  stages (3 notches). The chip's exact all-pass count/order (and whether 1st- or 2nd-order)
  is not pinned — it changes the notch pattern, not the LFO-rate sweep the A/B validates.
- **PHASE** (NPARAM 4): L/R LFO phase offset (stereo width); not modelled.
- **LFO WAVEFORM** (NPARAM 5): the HLE uses a sine.
- Operand-vs-cell scale of the all-pass coefficient (a) is assumed operand (cell/2) like the
  biquad/feedback; it sets the notch centre, not the validated sweep rate.
