# DLYSEED2: the single-delay datapath confronted with the HLE oracle — POSITIVE (2026-09-12)

Follow-up to `N-DLYSEED-SINGLE-DELAY-TRACE-2026-09-12.md`, which localized that the single
delay's signal is the **external delay-DRAM tap**, not the D-RAM state block. `UPD6383_DLYSEED2`
(`upd6383.cpp`, default-off, observation-only) now seeds the external delay DRAM **at the tap
address the chip itself computes**, immediately before the fetch — no address is re-derived — so
the genuine read → per-line latch → publish → ALU pipeline carries a known impulse
(16-bit 0x4000 → 0x400000 = 0.5 FS on the bus after the `<<8` widening).

## Recipe (reproducible)
```
DISPLAY=:0 DHLE=0 DSPCFG=3 TYPEIDX=7 NOTEMODE=0 TGM=0 UPD6383_DLYSEED2=1 \
  UPD6383_TRACE_FRAME=1820000 ./kn7000 kn5000 -rompath ./roms -skip_gameinfo -log -window \
  -autoboot_script dsp/tools/fx_ab.lua          # then:
python3 dsp/tools/dlyseed_confront.py error.log
```
(DSPCFG=3 = LLE + speculative ISA so prog09 runs end to end; TYPEIDX 7 = SINGLE DELAY; the
frame rate is 44100 Hz; the trace captures frame TRACE_FRAME+1.)

## 1. The seeded tap datum REACHES THE ALU — MEASURED
Eight body rows carry `L = 0x400000` on the operand latch (iw89/90/95/96 for the L channel,
iw112/113/118/119 for R) with **non-zero products**. The v1 D-RAM seed never reached L; the
external-tap seed does. The localization in the v1 note is confirmed.

## 2. The chip's multiplier holds EXACTLY on the delay program — MEASURED
`P[N] = (coef[N−1] × L[N]) >> 6` — the biquad's MEASURED multiplier *with its depth-1 coefficient
pipeline* (`DSP-DATAPATH-DECODE-HANDOFF §1`) — matches **16 of 16** non-zero multiply rows bit-exactly
(`dlyseed_confront.py` Q1b); the naive same-word form matches 0. E.g. iw95: 0x318B12 (iw94's coef)
× 0x400000 >> 6 = 212 786 610 176 = the traced P. A second program, a second datapath, the same
primitive — the multiplier rule GENERALIZES from the biquad to prog09.

## 3. The one-slot accumulator holds on EVERY multiply row — MEASURED
Classifying all consecutive body pairs against `acc[N] = acc[N−1] + P[N−1]` (`Q2b`): 20 accumulate,
17 load (`acc[N] == P[N−1]`, the f31=0 section-start form and the DRAM-read words), 2 saturated at
±2³⁹, 7 class-2/DRAM/mixing boundary words, **0 unexplained multiply rows**. The accumulator rule
generalizes too; the only residue sits on (a) the ±2³⁹ saturation clamp and (b) the class-2 /
0x0D-0x0E mixing / SRC-0x00 boundary words — i.e. exactly the codes still OPEN. The signal now
lives through iw130 (v1 died at iw111).

## 4. Why the audio-echo test cannot be used — MEASURED, a negative result
A `DLYSEED2_ONCE` capture with NO note playing (NOTE=NONE) shows the mix at **0.184 FS rms with
peak == rms** before the seed — a constant, not silence: the LLE wet under the speculative ISA is a
DC/rail (consistent with the trace's ±2³⁹ clamps), so a 0.5-FS impulse in the delay line is invisible
in the audio. The loop delay therefore has to be measured in the TRACE domain (§5), not by listening.

## 5. The realized loop delay (hardware question Q4) — measured in the trace domain
Seed once at frame F = 1 820 000, then trace frame F+k and inspect the tap-read words (iw93/iw116):
the line is otherwise empty (no audio ever enters it — the input route is blocked), so **any non-zero
L at the tap read at F+k is the recirculated seed, and that k is the LLE's realized loop delay**.
Candidates: k = 500 (the §234 shipped-pair lag) and k = 15437 (descriptor 0x26, the HLE delay).
**RESULT — SUGGESTIVE, not conclusive.** At the tap-read words iw93/iw116:
- **F+500**: `L = 0xFFFFFE = −2` — a non-zero residue, and several body rows that frame carry it
  (e.g. iw87 P=76260). Something recirculated.
- **F+15437**: `L = 0` — nothing at the descriptor lag.
So the realized recirculation sits nearer **500 frames** than the descriptor's 15437 — consistent
with the documented Q4 (the LLE returns its product at ~500, not the descriptor's lag). ⚠ But the
recirculated amplitude is **near noise** (−2, not a clean fraction of the 0.5-FS seed), because a
single `_ONCE` seed plus the per-frame address rotation (addr = cellv + m_frames_run) does not
deposit the impulse at the exact cell the F+k read lands on. So this is **SUGGESTIVE of k≈500, not a
measurement of it.**

A clean realized-lag number is available from the device's OWN instrumentation but is currently
**boot-gated**: the §75 `DLY R/W` debug and the §200 write-timestamp "age" census both fire at
frame ~420001 (the cold-boot default program), long before the panel-navigated SINGLE DELAY at
~1.82 M. (They do confirm the port mechanism: in the every-frame seed run the boot program's tap
reads `got 400000` — the 0.5-FS seed round-trips the external line.) **Re-gating §200's age census
to `m_trace_frame` (so it reports the realized lag of the navigated effect) is the clean next
build-lane step for Q4** — it measures "how many frames ago this address was written" directly,
which is exactly the loop delay, and it is not amplitude-limited like the seed-residue method.

## Honest grade
§1–§3 are MEASURED from the live seeded trace and are the first POSITIVE oracle confrontation of
a non-biquad program: the decoded arithmetic primitives are the chip's, and the open codes are
confined to the boundary words. §4 is a MEASURED negative result about the test method. §5 is
SUGGESTIVE of the Q4 ~500-frame lag but near-noise — a clean number awaits re-gating the §200 age
census. No decode was changed; DLYSEED2 is a pure observation diagnostic.
