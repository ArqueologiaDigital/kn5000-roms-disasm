# SINGLE DELAY: parameters located by intervention, and made audible in MAME (2026-09-11)

The second effect after the parametric EQ to be reconstructed from the decode and validated
by an in-emulator A/B. SINGLE DELAY is **TYPEIDX 7 on the DSP EFFECT page** (image algo 9,
unit 0, native exec), reached with the same navigation as the EQ (`eq_hle_ab.lua` /
`delay_ab.lua`, saturate TYPE DOWN then UP 7). Panel params (0-based):
`0 DELAY L, 1 DELAY R, 2 FEEDBACK L, 3 FEEDBACK R, 4 HIGH DAMP GAIN, 5 VOLUME, 6 REV SEND`.

## Pinned by intervention (MEASURED)
Driving **FEEDBACK L** (`delay_ab.lua`/`eq_hle_ab.lua` NPARAM=2) +24 and diffing the C-RAM
dumps (the EQ `eq_gain_diff_probe` method) moved **exactly one cell**:
- **FEEDBACK L = C-RAM cell 0x00** (−0.5818 → −0.3491, cell scale). Its stereo twin
  **FEEDBACK R = cell 0x09** stayed put (only L was driven). At the operand scale the
  multiplier reads (half the cell), the default feedback is ≈ **−0.29**, matching the
  documented "0.3 feedback" (programs.tsv algo 9).
- **DELAY L length = descriptor cell 0x26** = 0x3C4D = **15437 samples = 350 ms** at the ROM
  default — exactly the decode's prediction (r3-delaydram.md: 350 ms × 44100/1000 = 15435).
  Confirms the effect identity (an EQ has no delay descriptor).

## Two scale rules (both keyed on DSPCFG bit 1 = m_speculative)
Like the EQ, the banks are read at either the CELL scale or the OPERAND scale (half):
- **Descriptor:** the true-address ×2 decode (R3) is gated on m_speculative. With DSPCFG
  bit 1 ON the bank holds the true 44.1k sample count (15437); with it OFF it holds a raw
  value that is NOT a clean half (≈7296, giving ~331 ms) — so an exact delay time REQUIRES
  bit 1. (New MAME port option DSPCFG=0x02 = speculative descriptor with the LLE return
  discarded, so the HLE delay gets the right time with no LLE audio.)
- **C-RAM feedback:** cell scale (2×) when bit 1 is ON, operand (the actual gain) when OFF.
- **Sample rate:** the descriptor counts 44.1 kHz samples; the tonegen renders at 48 kHz, so
  the delay length must be converted (×48000/44100) or the echo lands ~8 % early.

## Validated audible in MAME (kn7000_mame)
`kn5000_tonegen.cpp` HLE SINGLE-DELAY insert (DSPHLE port bit 1, default OFF): a feedback
delay line per channel, length from descriptor 0x26, feedback from C-RAM 0x00/0x09, internal
mix ≈ 0.5 (the designed constant). In-emulator TEMPORAL A/B (`delay_ab.lua` +
`delay_ab_echo.py`, DSPCFG=2): cross-correlating the delay-on output against the dry shows a
delayed copy of the dry at **350.6 ms** (strength 0.818) — the decoded delay time — absent
from the dry control. PASS.

## Open (not yet pinned; SPECULATIVE / future intervention)
- **HIGH DAMP GAIN** (in-loop one-pole damping): cell not yet pinned → no damping yet (repeats
  keep their tone). Drive NPARAM=4 and diff to locate it.
- **DELAY R time / FEEDBACK R exact pairing:** the R descriptor cell (0x28) needs a base to
  subtract (cursor phase OPEN, r3-delaydram §6.3); the insert currently uses the L length for
  both channels with per-channel feedback (0x00 L / 0x09 R).
- **MIX/VOLUME cell:** standalone SINGLE DELAY exposes VOLUME (an insert); mix ≈ 0.5 is used
  as the designed constant. The combi S.DELAY+X variants expose DRY/WET and would drive it.
