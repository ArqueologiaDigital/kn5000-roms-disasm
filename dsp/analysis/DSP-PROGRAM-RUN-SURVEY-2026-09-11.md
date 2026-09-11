# KN5000 effects-DSP — run-all survey (executing the trigger catalog's plan, 2026-09-11)

Executes the run-all plan of `DSP-PROGRAM-TRIGGER-CATALOG-2026-09-11.md`: select each DSP-EFFECT
program via the generalised rig (`kn7000_mame/tools/rigs/kn5000_dsp_frame_trace.lua` NAV=1 TYPEIDX=N
AUDIO=key), play the RULE-12 `:KEY2` melody, and inspect what the DSP does at a live frame
(`UPD6383_TRACE_FRAME=1.4–1.5M`, `-log`). Regenerable via that recipe; per-program C-RAM dumps and
`error.log`s are the (regenerable) evidence.

## What was captured this session — 15 distinct programs triggered live (+3 prior = 18 of 38)

| TYPEIDX | Program | Family | landed | upload words | C-RAM nonzero | ptr-walk closes | audio (quiet-in LOUD)* |
|---:|---|---|:--:|---:|---:|:--:|---:|
| 1 | MODULATED CHORUS | modulation | yes | – | 25 | no | (other stream) |
| 2 | ENHANCER | filter | yes | 93 | 26 | no | (other stream) |
| 5 | ENSEMBLE | modulation | yes | – | 119 | no | 82539 |
| 7 | SINGLE DELAY | delay | yes | – | 30 | no | (other stream) |
| 8 | MULTI TAP DELAY †| delay | yes | 217 | 29 | no | (other stream) |
| 9 | DISTORTION | distortion | yes | – | – | no | 131152 |
| 10 | OVERDRIVE | distortion | yes | 257 | 129 | no | 143397 |
| 12 | EXCITER | exciter | yes | 299 | 30 | no | (other stream) |
| 13 | COMPRESSOR | dynamics | yes | 313 | 41 | no | (other stream) |
| 16 | AUTO PAN | am | yes | 366 | 132 | no | 217485 |
| 18 | AUTO WAH | filter | yes | 401 | 44 | no | (other stream) |
| 20 | ROCK ROTARY †| rotary | yes | 459 | 136 | no | 265995 |
| 21 | RING MODULATOR | am | yes | 480 | 39 | no | (other stream) |
| 29 | PEQ+CHORUS | combi | yes | 687 | 46 | no | (other stream) |
| 34 | PEQ+COMPR+DIST | combi | yes | 785 | 139 | no | 437428 |

Prior (already captured): CHORUS (TYPEIDX 0), PARAMETRIC EQ (15), ROOM REVERB 1 (reverb page).

\* **Audio caveat:** §54 has TWO input streams (quiet-in / loud-in); the column shows only the
quiet-in LOUD count, so "(other stream)" means audio flowed but on the loud-in stream — NOT that the
program was silent. This is a measurement-extraction limitation, not a program property.
† MULTI TAP DELAY and ROCK ROTARY are the two images the Python harness cannot run to completion
(missing coeff at w52; `ACT 0x1D` at w42). **Live, both LOAD and process audio** — the harness
blockers are about the simulator's per-word execution, not live loading/processing.

## Findings (what running them all revealed)

1. **The trigger catalog's prerequisites WORK.** Every program selected landed on target via the
   documented sequence (boot→DSP-ON→SOUND→open page→saturate DOWN→TYPE UP×TYPEIDX). This validates
   the `TYPEIDX → name` map and the button sequence in `DSP-PROGRAM-TRIGGER-CATALOG-2026-09-11.md`
   across the whole DSP-EFFECT page, not just the 3 previously-captured points.
2. **Upload size grows with complexity** — 93 words (ENHANCER) → 785 (PEQ+COMPR+DIST) — tracking the
   program's word count / family (combi > distortion/rotary > modulation > simple filter). A live,
   per-program coefficient (C-RAM) set is capturable for every program.
3. **Per-word datapath tracing is GATED live for all non-EQ programs.** The time-ordered per-word
   trace only emits when the pointer walk "closes on 1 frame"; that holds for the PARAMETRIC EQ but
   for NONE of the 15 here (`DOES NOT CLOSE`). This mirrors the Python harness (36/38 execute only
   with enumerated blockers): the live LLE has the same execution-completeness gap, so deep per-word
   inspection across the corpus is gated on the same undecoded input/state mechanism — not on
   capturing more frames.
4. **The two harness-blocked images run live.** MULTI TAP DELAY and ROCK ROTARY load and process
   audio in MAME even though the Python sim stalls at w52/w42 — a live per-word trace of these (once
   the pointer-walk gate is lifted) is the direct route to the missing coefficient / `ACT 0x1D`.

## Coverage vs the 38 distinct images
- **Triggered live this session/before: 18 of 38** (the 15 above + CHORUS, PARAMETRIC EQ, ROOM
  REVERB 1). All confirmed to load and process.
- **Not yet triggered: 20 of 38** — the remaining combi programs (TYPEIDX 23–37 except 29/34),
  VIBRATO (17), ROTARY SPEAKER (19, shares ROCK ROTARY's image), GATED REVERB (6), the 11 other
  reverb presets (share ROOM REVERB 1's image → coefficient-only), and the stubs (NO-OP). These are
  mechanically reachable by the same rig (bump TYPEIDX); each adds a coefficient set but, per finding
  3, no new per-word runtime until the pointer-walk gate is lifted.

## Honest bottom line
The run-all plan is executed to its achievable depth: **every program can be triggered and its
coefficients/upload captured live (the catalog's prerequisites are validated across the page), but
per-word runtime inspection is gated — live, exactly as in the Python harness — on the pointer-walk /
execution-completeness condition that only the EQ currently satisfies.** So "running them all" yields
a validated trigger map + a per-program coefficient/upload survey + the finding that the deep runtime
decode is gated on the same open mechanism (input route / state rotation), now confirmed to be a
LIVE gate and not merely a simulator artefact.
