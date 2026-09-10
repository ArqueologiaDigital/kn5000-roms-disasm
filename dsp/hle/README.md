# HLE reference for the uPD6383GF effects DSP

A **high-level-emulation reference implementation** of the Technics KN5000 / SX-WSA1R effects
DSP, built from the reverse-engineered block diagrams and coefficient designers. It is the
audio-producing counterpart to the static decode: where `dsp/analysis/DECODE-by-correlation-2026-09-08.md`
and `dsp/algorithms/biquad-eq.md` say *what each effect is*, this **runs it and makes sound**.

**HLE, not LLE.** It reproduces each effect's transfer function / behaviour from the decoded
algorithm; it does **not** execute the chip's 36-bit microcode (that is the LLE core in MAME,
`KN5000_ENABLE_DSP1`, still hardware-gated). This reference is (a) a proof that the decode is
*implementation-complete* for the effect families, and (b) a validated model to port into a
MAME HLE path later, drop-in and A/B-testable — without touching the delicate parked LLE core.

## Files

| file | what |
|---|---|
| `kernels.py` | the four decoded kernels + waveshaper: Direct-Form-I biquad, one-pole damping, LFO (phase-accum→table), delay line (ring buffer, fractional read), waveshaper LUT |
| `designer.py` | the **host-side** coefficient designers (Sub-CPU `DSP_PerParameterTranslator`): bilinear peaking biquad (`K=tan(πf₀/fs)`), ms→samples delay (`×44100/1000`), LFO rate (`f/fs`), damping |
| `effects.py` | per-family wiring: `parametric_eq`, `chorus`, `flanger`, `delay`, `reverb`, `distortion` |
| `test_hle.py` | self-validation — each block checked by its defining property |
| `render_demo.py` | render each effect on a test signal to a WAV for listening |

## Run

```
python3 dsp/hle/test_hle.py          # validate (all checks pass)
python3 dsp/hle/render_demo.py       # write demo WAVs
```

## Validation (from `test_hle.py`, all PASS)

- **Parametric-EQ biquad**: peak = **+12.00 dB at f₀**; the impulse-response FFT equals the
  analytic response to **0.000 dB**; cut = −12.00 dB — the bilinear peaking designer is exact.
- **LFO**: dominant bin = requested rate. **Delay**: 100 ms echo returns at exactly N samples.
- **All-pass diffuser**: magnitude **flat** (ripple 0.0000) and **unity energy** — a true
  all-pass (the KN5000 reverb primitive, §5).
- **Distortion**: waveshaper odd + monotonic, and it adds a 3rd harmonic to a pure tone.
- **Reverb**: audible decaying tail at 0.5 s. **5-band EQ**: boosts/cuts the right bands.

## Grade

Reference model of the **decoded algorithm**, graded per the source sections: the parametric
EQ is PROVEN bit-exact on the chip (`biquad-eq.md`) and here reproduces its designed response
exactly; the reverb/chorus/delay/distortion are the decoded *topologies* (§5/§7/§12/§16) with
textbook coefficient designers, so they are faithful in structure and behaviour, not
bit-identical to a specific ROM preset's coefficient values. FS = 44100 Hz (proven three ways).
