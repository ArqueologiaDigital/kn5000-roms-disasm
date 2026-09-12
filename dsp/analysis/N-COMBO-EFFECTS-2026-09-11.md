# S.DELAY+X combo effects: chaining validated blocks (2026-09-11)

The combi effects are the union of two sub-effect topologies — a SINGLE DELAY chained with a
second effect — packed into one C-RAM layout that differs from the standalones, so each is
pinned separately. They reuse the standalone delay/chorus/flanger/phaser/vibrato blocks (only
one effect is ever selected, so the delay lines are shared).

## S.DELAY+CHORUS (TYPEIDX 23, algo 64, DSPHLE == 8) — VALIDATED
Panel params: `0 DELAY DRY/WET, 1 DELAY L, 2 DELAY R, 3 FEEDBACK L, 4 FEEDBACK R,
5 CHORUS DRY/WET, 6 DEPTH, 7 LFO SPEED, 8 LFO WAVEFORM, 9 VOLUME, 10 REV SEND`.
Pinned by intervention:
- **Delay FEEDBACK L = C-RAM cell 0x02** (moved when FEEDBACK L driven; −0.36 cell → operand
  ~−0.18). Delay length = descriptor cell 0x26 (13232 ≈ **300 ms**).
- **Chorus RATE = C-RAM cell 0x00** (114 → 494 with LFO SPEED, = 0.6 Hz), the same cell the
  standalone chorus uses.
HLE: stage 1 = a feedback delay (reusing m_dly), stage 2 = a 2-voice quadrature LFO-swept
chorus on the delayed signal (reusing m_cho). Chorus sweep/wet are not separately pinned in the
combo layout → a modest fixed sweep + fixed wet (the validated quantities are the echo time and
the modulation rate).

Validated by TWO in-emulator A/Bs (DSPCFG=2):
- **Delay stage** (`delay_ab.lua` TYPEIDX=23, `delay_ab_echo.py`): a delayed copy of the dry at
  **299 ms** (= the combo's decoded 300 ms delay), absent from the dry control. PASS.
- **Chorus stage** (`chorus_ab.lua` TYPEIDX=23, `chorus_ab.py`): the note modulates at
  **0.62 Hz** (the decoded rate), 32× over dry. PASS.
So both chained stages are present and correct — the combi chaining works end to end.

## The other S.DELAY+X combos — ALL VALIDATED (DSPHLE == 9..12)
Each is the delay stage chained with a different second block; each has its OWN C-RAM layout,
pinned by intervention (drive the second effect's LFO SPEED, find its rate cell; the delay
feedback cell and descriptor 0x26 as the delay stage). Second-stage feedback/sweep where the
combo layout does not expose them are fixed; the validated per-combo quantity is the mod RATE
(and, for the delays, the echo). All reuse the standalone mod-block delay lines / all-pass
stages; S.DELAY+S.DELAY uses a second long delay line (m_dly2).

| combo | TYPEIDX | mod RATE cell | delay feedback cell | A/B result |
|---|---|---|---|---|
| S.DELAY+FLANGER | 25 | 0x00 (0.2 Hz) | 0x04 | mod 0.77 Hz driven, 36× over dry |
| S.DELAY+VIBRATO | 26 | 0x00 (0.6 Hz) | 0x04 | mod 0.62 Hz, 22× over dry |
| S.DELAY+PHASER  | 27 | 0x03 (0.4 Hz), MANUAL=0x0A, DEPTH=0x09 | 0x00 | mod 0.77 Hz driven, 32× over dry |
| S.DELAY+S.DELAY | 24 | (no LFO) delay2 feedback=0x05 | 0x00 | echo at 178 ms, strength 0.92 |

So all five S.DELAY+X combos are audible and validated in the emulator: the delay stage
produces its echo, and the modulation stage modulates at its decoded rate.

## Still needing their non-delay stage
- AUTO WAH+S.DELAY (28): auto-wah = an envelope-swept filter (envelope follower, not an LFO) —
  a different block, not yet built.
- PEQ+S.DELAY (30): the PEQ biquad stage + the delay — the EQ block exists; would chain it.
