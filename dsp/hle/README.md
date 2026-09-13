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
| `kernels.py` | the decoded kernels + waveshaper: Direct-Form-I biquad, one-pole damping, LFO (phase-accum→table), delay line (ring buffer, fractional read), waveshaper LUT, and ★ **`LevelDetector`** — the 2/π rectify-and-smooth envelope follower, **every constant read from ROM 0x84CD** |
| `designer.py` | the **host-side** coefficient designers (Sub-CPU `DSP_PerParameterTranslator`): bilinear peaking biquad (`K=tan(πf₀/fs)`), ms→samples delay (`×44100/1000`), LFO rate (`f/fs`), damping |
| `effects.py` | per-family wiring: `parametric_eq`, `chorus`, `flanger`, `delay`, `reverb`, `distortion`, and ★ the **dynamics family** — `level_envelope`, `compressor`, `auto_wah` |
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
- ★ **Level detector** (the dynamics family): the 2/π constant is the ROM's `0x517CC1` **to the
  LSB**; the smoother time constants come out at **4.712 ms** and **11.764 ms**, the two values
  the host's own upload script at ROM `0x84CD` supplies as COMPRESSOR's ATTACK and RELEASE; the
  detector is **linear in amplitude** (ratio 2.0000 for a 2× input) and **attacks faster than it
  releases**. **Compressor**: 19.1 dB in → 8.4 dB out, transparent below threshold.
  **Auto wah**: the resonance lands within 1.5 % of the frequency the envelope predicts, at two
  input levels a factor of 12 apart.

## ⚠ What in the dynamics family is DECODED and what is not

The **detector** is decoded — constant for constant, from the ROM, cross-checked against the
instrument's own parameter list (COMPRESSOR's `ATTACK SENS.(s)` / `RELEASE SENS.(s)` are exactly
the two smoother constants). The **gain law** is **not**: what the corpus establishes is negative
and strong — there is **no comparator opcode**, the bodies are branchless, so THRESHOLD and RATIO
must enter as coefficients — and the linear `g = clip(1 − k·env, 1/ratio, 1)` implemented here is
the simplest law meeting that constraint, **not a decode**. Rivals not excluded: a reciprocal-style
AGC, or a gain curve delivered by the same table-lookup idiom the distortion family uses. Likewise
`auto_wah`'s multiplicative sweep. See `dsp/analysis/N-INPUT-GATE-OPENED-2026-09-12.md` §67.

## Grade

Reference model of the **decoded algorithm**, graded per the source sections: the parametric
EQ is PROVEN bit-exact on the chip (`biquad-eq.md`) and here reproduces its designed response
exactly; the reverb/chorus/delay/distortion are the decoded *topologies* (§5/§7/§12/§16) with
textbook coefficient designers, so they are faithful in structure and behaviour, not
bit-identical to a specific ROM preset's coefficient values. FS = 44100 Hz (proven three ways).
