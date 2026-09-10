# HLE reference for the SX-WSA1R acoustic-modeling LSI (L7A1429, IC3)

A **high-level-emulation reference** of the WSA1R's physical-modeling chip, built strictly from
`wsa1/notes/HLE-GUIDE-l7a1429.md`. It is the audio-producing counterpart to the register-level
decode already shipped in MAME (`acoustic_modeling.cpp` / `l7a1429_device`, which models the
port pair, the 1217-register file, and `decoded_channel()` — the parameters in engineering
units, but **no audio**, correctly, because the internal path and excitation are unmeasured).

This reference takes the decoded per-channel parameters and **runs the resonator model**, so the
documented physics can be heard and shown implementation-complete for the settled parameters.

## The model (HLE-GUIDE §0/§3, graded STRONG)

Per channel, a pair of coupled linear **digital-waveguide resonators** — the media the firmware
names itself (`STRING, CYLINDER, CONE, FLARE, PLATE, MEMB`):

```
 excitation ──▶ delay(period = pitch)  ──▶ one-pole loss (MUTING)  ──▶ ×feedback ──┐
        ▲                          └────────── POSITION pickup tap ──▶ out          │
        └──────────────────────────────────────────────────────────────────────────┘
 MAIN and SUB run in parallel, coupled through a tuning DETUNE, mixed by SUB GAIN.
```

- **tuning** (regs 0x0040/0x0080) → the delay length (pitch period);
- **MUTING** (regs 0x0400/0x0440) → the loop loss one-pole — its cutoff has a **PROVEN** bilinear
  closed form (`cutoff_hz()`, ported from the guide's C, index = MIDI note − 36);
- **POSITION** (reg 0x00C0) → a delay-tap along the medium (log-period); its absolute scale is
  the one genuinely unknown number (§8.1), exposed as `position_scale`;
- **FITTING** (regs 0x0140+0x01C0 …) → the excitation shaping (rise/decay);
- **SUB GAIN** (reg 0x0280) → the MAIN/SUB mix; coupling is a **tuning detune** (the firmware's
  `sub_FC4269` solver), not a register (§ correction 2026-09-04). `coupled_detune()` implements
  this as coupled-oscillator **normal-mode splitting** driven by INTERACTION GAIN (faithful to
  the model; the exact 1087-byte fixed-point solver is `notes/w24_e093_coupling_solver.py`).

`position_sensitivity.py` is a speculative characterization of the one number the decode cannot
supply — the POSITION absolute scale (HLE-GUIDE §8.1): it shows, via the HLE, that the constant
sets the pickup-comb *timbre* (nulls move with pickup fraction) not the pitch, and brackets it
physically — without inventing a value (needs a hardware trace).
- **No key-off** (§7.5): the model sustains and decays *autonomously* from initial conditions.

## Honest stand-ins (each behind a switch, drop-in replaceable)

- **Excitation** — the DRIVER waveform is a prom_d wave-ROM **sample that is not dumped**; here
  it is a synthetic shaped noise burst (`driver_excitation`), clearly marked.
- **POSITION absolute scale** — unknown (§8.1); exposed as `position_scale` (default 1.0).
- **Internal signal path** — series/parallel, where the driver enters, one biquad vs two poles:
  **inference** (§8.2). The waveguide topology is the manufacturer's-vocabulary reading, STRONG.

⇒ a physically-plausible realization of the **documented** resonator model — not a faithful
reproduction of the chip's audio (impossible without the wave ROMs and an internal-path trace).

## Run

```
python3 wsa1/hle/test_l7a1429_hle.py     # validate (all PASS)
python3 wsa1/hle/render_l7a1429_demo.py  # render notes to WAV
```

## Validation (all PASS)

MUTING cutoff round-trips and obeys the octave law; the waveguide rings at the note's
fundamental (220/440/880 Hz); the voice **sustains past 1 s and decays gradually with no input**
(the no-key-off requirement); brighter MUTING → more HF energy; SUB GAIN adds the detuned
coupling (audible beating). FS = 44100 Hz.
