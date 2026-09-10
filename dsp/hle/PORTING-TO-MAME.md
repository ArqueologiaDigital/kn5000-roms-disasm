# Porting the HLE reference into MAME (the bridge to emulator audio)

The Python reference in this directory is validated and stable. This note is the concrete,
low-risk plan to turn it into **audio inside MAME** without disturbing the delicate, parked
low-level-emulation (LLE) cores. It is written to the project's standing rules: *fake with the
real mechanism, labelled and drop-in-replaceable; gate with a spectral A/B; never edit a device
core autonomously without hardware to validate against* — so the steps below are a plan for a
human-reviewed change, not an autonomous one.

## What already exists on the MAME side

- **Effects DSP** (`kn7000_mame/src/mame/matsushita/upd6383.cpp`): the LLE core, behind
  `KN5000_ENABLE_DSP1` / `WSA1R_ENABLE_DSP` (default off). It already loads I-RAM and C-RAM and
  executes C-format immediate loads; it is the thing NOT to disturb.
- **Acoustic-modeling LSI** (`.../acoustic_modeling.cpp`, `l7a1429_device`): the register-file +
  `decoded_channel()` state model — the parameters in engineering units, no audio (correctly).

## The integration, effect by effect

The HLE consumes **decoded coefficients**, which both devices already produce. So the port is a
*consumer* of existing decode, added beside the LLE path, never replacing it.

1. **Add an HLE output path as a compile-time + runtime option**, e.g. `KN5000_DSP_HLE`
   (compile) and a `DSPHLE` config port (runtime), both default off — mirroring the existing
   `ENABLE_DSP` gating. When on, the device produces audio via the HLE kernels; when off,
   behaviour is byte-for-byte unchanged. One switch, drop-in.
2. **Port the four kernels + waveshaper** (`kernels.py`) to C++ — they are ~150 lines and use no
   numpy feature beyond arrays. The DF-I biquad is the anchor and is bit-provable against
   `biquad-eq.md`.
3. **Feed them the decoded coefficients the device already has**: the effects device streams
   C-RAM per effect; map C-RAM sections to biquad/comb/allpass coefficients using the decoded
   layout (`b1,b0,b2,-a1,-a2,makeup` per §7b/§15; `validate_against_capture.py` shows the real
   captured cells are stable in that order). Do **not** re-derive coefficients host-side in the
   device — read the ones the firmware already computed and streamed.
4. **Pick the per-effect wiring from the effect number**, using the family map
   (`EFFECT-ALGORITHMS-implementation-spec.md`): EQ→biquad chain, chorus/flanger→LFO+delay,
   delay→feedback delay, reverb→`reverb_kn5000` (KN5000) / comb+damp (WSA1R), distortion→
   waveshaper(+tone). The combination effects are the component blocks chained (§16).
5. **Gate acceptance on a spectral A/B**, not on "it sounds plausible": render the same note
   through the HLE path and (when it exists) the LLE path, and compare spectra. Until the LLE
   path produces audio, the A/B is HLE-vs-reference (this repo's `test_golden.py` hashes are the
   fixed reference).

## The acoustic-modeling LSI

`l7a1429_hle.py` is the "eventual synthesis" the device's `decoded_channel()` was built to feed.
The port is the same shape: an optional audio path that reads `decoded_channel()` and runs the
coupled-waveguide model. **But two inputs are missing and no port can invent them** (HLE-GUIDE
§8): the DRIVER excitation (IC4's six wave mask ROMs are undumped) and the POSITION absolute
scale (needs a hardware trace). So an acoustic-model audio path is a *research preview* with a
labelled synthetic excitation, not a faithful voice, until those two are supplied. Keep it behind
its own switch and label it as such.

## What NOT to do

- Do not modify the LLE execution path or its state to make the HLE work.
- Do not implement resonator families or effect-name special-cases — implement the coefficients
  (§3.4 of the guide; §16 here).
- Do not ship acoustic-model audio as faithful; it is a preview with two stated stand-ins.
- Do not claim hardware fidelity for anything not spectrally A/B'd against a measured reference.
