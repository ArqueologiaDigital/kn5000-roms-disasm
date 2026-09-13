# AUTHORITATIVE DSP EFFECT TYPE map — MEASURED PER INDEX, 2026-09-13

★★★ **REBUILT FROM THE MACHINE'S OWN UPLOADS.** Every row below was produced by selecting that
index with the calibrated transport and then identifying the program that actually loaded, from
the uC-IF upload capture — `dsp/tools/type_map_rebuild.sh` + `type_fingerprint.py`, which replays
the capture into a 384-word I-RAM image and matches **16 words** against the 38 committed
listings. No row comes from the panel text, and no row comes from deduplicating consecutive
images. Log: `rebuild_log_2026-09-13.txt`.

★ **Why 16 words and why it cannot be ambiguous:** all 38 body images are unique on their first 16
words (verified by construction); a 4-word prefix collides for 8 of them in 4 groups. Several TYPE
slots resolving to the *same* program is a **result**, not a collision — twelve named effects ship
an image byte-identical to NO OPERATION — and this method reports the program per index instead of
collapsing the repeats, which is exactly what went wrong before.

## What the rebuild corrected, precisely
| | old map | measured |
|---|---|---|
| entries | 36 (0..35) | **38 (0..37)** |
| indices 0..19 | ✅ already correct | ✅ identical |
| index 20 | `prog54_ring_modulator` | ⛔ **`prog15_rock_rotary`** — **TYPE 19 AND 20 BOTH LOAD THE ROTARY** |
| indices 21..35 | shifted **down by one** | corrected |
| indices 36, 37 | **absent** | `prog98_peq_dist_delay`, `prog99_peq_overdr_delay` |

⇒ **The collapse is at index 20, not "above index 8".** The old header's rule — *"add 1 to any
index above 8"* — was wrong about where, and wrong for indices 9..19, which needed no adjustment.
The duplicate slot is the **rock rotary**, occupying TYPE 19 and TYPE 20.

⚠ **And the selector was wrong too, independently**: `type_select.lua` defaulted to `TYPELAST=35`
for a list of 38, landing every request **two slots high** (`37 − (35 − N) = N + 2`). Corrected to
37, at which **both** known-answer controls pass: `TYPEIDX 0 → prog01_chorus`,
`TYPEIDX 15 → prog39_parametric_eq`. Anything measured through that selector before 2026-09-13 was
addressing a program two slots from the one intended.

⚠ **THE OBLIGATION TO FINGERPRINT EVERY RUN STANDS** (§193). A calibrated transport is still a
transport; `type_fingerprint.py` on the run's own `kn5000_dsp1_upload.txt` is what makes a run's
identity a measurement. ⚠ These lua scripts print to **stdout/stderr, not `error.log`**, and the
panel title read at `0x30AE5` returns garbage in this build.

| TYPE | program | effect |
|-----:|---|---|
| 0 | `prog01_chorus` | CHORUS |
| 1 | `prog02_modulated_chorus` | MODULATED CHORUS |
| 2 | `prog03_enhancer` | ENHANCER |
| 3 | `prog04_flanger` | FLANGER |
| 4 | `prog05_phaser` | PHASER |
| 5 | `prog06_ensemble` | ENSEMBLE |
| 6 | `prog08_gated_reverb` | GATED REVERB |
| 7 | `prog09_single_delay` | SINGLE DELAY |
| 8 | `prog10_multi_tap_delay` | MULTI TAP DELAY |
| 9 | `prog32_distortion` | DISTORTION |
| 10 | `prog33_overdrive` | OVERDRIVE |
| 11 | `prog34_fuzz` | FUZZ |
| 12 | `prog35_exciter` | EXCITER |
| 13 | `prog36_compressor` | COMPRESSOR |
| 14 | `prog00_no_operation` | NO OPERATION |
| 15 | `prog39_parametric_eq` | PARAMETRIC EQ |
| 16 | `prog48_auto_pan` | AUTO PAN |
| 17 | `prog50_vibrato` | VIBRATO |
| 18 | `prog52_auto_wah` | AUTO WAH |
| 19 | `prog15_rock_rotary` | ROCK ROTARY |
| 20 | `prog15_rock_rotary` | ROCK ROTARY |
| 21 | `prog54_ring_modulator` | RING MODULATOR |
| 22 | `prog56_mix_up` | MIX UP |
| 23 | `prog64_s_delay_chorus` | S.DELAY+CHORUS |
| 24 | `prog65_s_delay_s_delay` | S.DELAY+S.DELAY |
| 25 | `prog66_s_delay_flanger` | S.DELAY+FLANGER |
| 26 | `prog67_s_delay_vibrato` | S.DELAY+VIBRATO |
| 27 | `prog68_s_delay_phaser` | S.DELAY+PHASER |
| 28 | `prog70_auto_wah_s_delay` | AUTO WAH+S.DELAY |
| 29 | `prog71_peq_chorus` | PEQ+CHORUS |
| 30 | `prog72_peq_s_delay` | PEQ+S.DELAY |
| 31 | `prog73_peq_flanger` | PEQ+FLANGER |
| 32 | `prog74_peq_vibrato` | PEQ+VIBRATO |
| 33 | `prog75_peq_compressor` | PEQ+COMPRESSOR |
| 34 | `prog96_peq_compr_dist` | PEQ+COMPR+DIST |
| 35 | `prog97_peq_compr_overdr` | PEQ+COMPR+OVERDR |
| 36 | `prog98_peq_dist_delay` | PEQ+DIST+DELAY |
| 37 | `prog99_peq_overdr_delay` | PEQ+OVERDR+DELAY |

38 indices, each MEASURED from the machine's own upload capture.
