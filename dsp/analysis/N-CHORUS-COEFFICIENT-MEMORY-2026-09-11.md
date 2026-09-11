# CHORUS: parameters located by intervention, and made audible in MAME (2026-09-11)

Third effect after the parametric EQ and the single delay. CHORUS is **TYPEIDX 0 on the DSP
EFFECT page** (image algo 1, unit 0) — the saturate-DOWN target. Panel params (0-based):
`0 DEPTH, 1 LFO SPEED, 2 LFO WAVEFORM, 3 VOLUME, 4 REV SEND`. Topology: a quadrature
LFO-swept delay (two table reads — sin/cos — of one phase accumulator).

## Pinned by intervention (MEASURED)
Driving one panel param and diffing the C-RAM dumps (the EQ/delay method):
- **RATE / LFO SPEED = C-RAM cell 0x00** (the phase increment). Driving LFO SPEED (NPARAM=1)
  +20 moved it **0x72 (114) → 0x1EE (494)** — tracking the live D-RAM phase ramp exactly
  (+114→+494, T3). LFO frequency f = inc × 44100 / 2²³, so 114 → **0.599 Hz** at rest. Cell
  0x01 = the wrap constant 0x7FFFFF (phase modulus 2²³).
- **DEPTH (panel) = C-RAM cells 0x09/0x0A** (the wet gain). Driving DEPTH (NPARAM=0) +20 moved
  them **0.303 → 0.505** — so the KN5000 CHORUS "DEPTH" knob is the WET amount, not the
  modulation depth.
- **Modulation SWEEP amplitude = C-RAM cell 0x02/0x04 = 0xF0 = 240** (44.1k samples, ~5.4 ms).
  A fixed constant (moved by neither DEPTH nor RATE) — consistent with the settled finding
  that the modulation value is constant (BOOKKEEPING-REPAIR item 9).

## Made audible + validated in MAME (kn7000_mame)
`kn5000_tonegen.cpp` HLE CHORUS insert (DSPHLE selector == 3, default OFF): per channel, a
short delay line read at two quadrature taps (base + sweep·(0.5±0.5·sin/cos)), the two wet
voices summed and crossfaded with the dry by the wet gain. LFO rate from cell 0x00, sweep
from cell 0x02, wet from cell 0x09; DSPCFG-bit-1 cell/operand scale handled; 44.1k→48k
converted. Base delay not separately pinned → uses the sweep amplitude as the base (short
chorus); HIGH DAMP / feedback (FLANGER) not implemented.

A/B (`chorus_ab.lua` single sustained note + `chorus_ab.py` modulation spectrum, DSPCFG=2):
the chorus amplitude-modulates the held note's harmonics at **0.62 Hz (= the decoded rate),
18.8× above the dry control**, and — the capstone — driving **LFO SPEED +8 moves that
modulation to 1.40 Hz** (20.9× dry), i.e. the rate tracks cell 0x00 (114→266). The dry has
nothing at either rate. PASS. (The instrument voice's own tremolo sits at ~2.6 Hz and is
present in the dry too, so the chorus test is restricted to the LFO band.)

## Open (SPECULATIVE / future)
- **BASE delay** (chorus pre-delay): in the descriptor bank, not separately pinned; a fixed
  base is used. Read via dsc_read once the chorus descriptor cell is identified.
- **FLANGER** (TYPEIDX 3): a swept all-pass chain with feedback; its LFO phase cell is 0x08
  (not 0x10), so its C-RAM layout differs and must be probed separately.
- **LFO WAVEFORM** (NPARAM 2): selects the class-6 table; the HLE uses sin/cos always.
