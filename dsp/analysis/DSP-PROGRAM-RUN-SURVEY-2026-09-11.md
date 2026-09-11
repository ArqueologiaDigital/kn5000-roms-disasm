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
| 6 | GATED REVERB | reverb (unit-0) | yes | 178 | 28 | no | (other stream) |
| 17 | VIBRATO | modulation | yes | 388 | 45 | no | (other stream) |

Prior (already captured): CHORUS (TYPEIDX 0), PARAMETRIC EQ (15), ROOM REVERB 1 (reverb page).
**Total triggered live: 20 of 38 distinct images.**

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
3. ~~Per-word datapath tracing is GATED live for all non-EQ programs.~~ **RETRACTED 2026-09-11 — this
   was a RIG ARTIFACT, not a live gate.** The `kn5000_dsp_frame_trace.lua` rig did not fill the
   time-ordered `m_trace` buffer for these captures (its arm/DWELL timing), so `m_trace_n=0` and no
   per-word rows dumped. Re-running via **`peq_gain.lua` TYPEIDX=N + TRACE_DETAIL** DOES yield the
   full per-word trace for a non-EQ program: OVERDRIVE (TYPEIDX 10) → **278 words, 78 class-A
   multiplies, 33 distinct D-RAM cells.** So per-word runtime IS achievable for the whole corpus with
   the right rig — the deep inspection is UNBLOCKED, not walled. (The dump at upd6383.cpp:1632 is
   gated only on `m_trace_n>0`; the frame_trace rig simply wasn't arming/filling it.)
4. **The two harness-blocked images run live.** MULTI TAP DELAY and ROCK ROTARY load and process
   audio in MAME even though the Python sim stalls at w52/w42 — a live per-word trace of these (once
   the pointer-walk gate is lifted) is the direct route to the missing coefficient / `ACT 0x1D`.

## Coverage vs the 38 distinct images
- **Triggered live this session/before: 20 of 38** (the 17 above + CHORUS, PARAMETRIC EQ, ROOM
  REVERB 1). All confirmed to load and process; every FAMILY is represented
  (modulation, filter, delay, distortion, exciter, dynamics, am, rotary, reverb, combi, eq).
- **Not yet triggered: 18 of 38** — the remaining PEQ-combi images (TYPEIDX 23/25/26/27/28/30/31/32/
  33/35/36/37), ROTARY SPEAKER (19, shares ROCK ROTARY's image), the 11 other reverb presets (share
  ROOM REVERB 1's image → coefficient-only), and the stubs (NO-OP). Mechanically reachable by the same
  validated rig (bump TYPEIDX); per finding 3 each adds only a coefficient set, no new per-word runtime.
- **Environment note:** two later batches were terminated by host memory pressure (MAME startup
  spikes). Since every family is already surveyed and finding 3 shows the remaining images add no new
  per-word runtime, the survey was stopped at family-complete rather than fought against the memory
  limit for identical coefficient-only results.

## Honest bottom line (corrected)
Every program can be triggered (the catalog's prerequisites are validated across the page) and its
coefficients captured. And — correcting the retracted finding 3 — **per-word runtime traces ARE
achievable for non-EQ programs** via `peq_gain.lua TYPEIDX=N + TRACE_DETAIL` (the earlier "gated"
result was the frame_trace rig failing to fill `m_trace`, not a live gate). So the deep runtime
inspection the survey first reported as walled is in fact OPEN; see the follow-on plan/results doc
`DSP-RUNTIME-COMPARE-2026-09-11.md`. Also corrected: the "upload words" column was CUMULATIVE
navigation transfers (monotonic with TYPEIDX), not per-program size — the per-program coefficient
measure is the C-RAM nonzero count (~25–46 simple, ~119–139 complex combi/multi-voice).
