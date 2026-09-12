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

## The other S.DELAY+X combos (same pattern)
Each is the delay stage chained with a different second block, pinned the same way (drive the
second effect's LFO SPEED / feedback, find its cell; delay feedback and descriptor as above):
- S.DELAY+FLANGER (25), S.DELAY+VIBRATO (26), S.DELAY+PHASER (27), S.DELAY+S.DELAY (24).
- AUTO WAH+S.DELAY (28) and PEQ+S.DELAY (30) need their non-delay stage (auto-wah = envelope
  filter; PEQ = the biquad) first.
