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

## 5. The realized loop delay (hardware question Q4) — NOT measured; the census claim RETRACTED
Seed once at frame F = 1 820 000, then trace frame F+k and inspect the tap-read words (iw93/iw116):
the line is otherwise empty (no audio ever enters it — the input route is blocked), so **any non-zero
L at the tap read at F+k is the recirculated seed, and that k is the LLE's realized loop delay**.

⚠⚠ **RETRACTED (same day, by the chorus confrontation's census cross-check —
`N-DLYSEED2-CHORUS-CONFRONT-2026-09-12 §5`).** This section first claimed "the realized delay matches
the DESCRIPTOR (~350–400 ms), measured by the device's own §200 age census", quoting dsc 0x26
`frames_since_written 0 .. 17711 (401.61 ms)` ≈ the descriptor's 350 ms. That number is **not a
line-depth measurement**: (a) the §200 census is CUMULATIVE SINCE BOOT and spans every program that
ran before the navigation (the boot default's reads on the same descriptor index are pooled in);
(b) the read ADDRESS in this build carries the SPECULATIVE tap-modulation term `m_tapmod` (mask bit
60) — prog09 has NO `44C` word, so during the single delay `m_tapmod` is whatever STALE value the
previous program's `44C` word left, a garbage constant offset that the seed itself perturbs. Five
runs of the same recipe give dsc 0x26 max = 27748 / 27750 / 27748 / 27748 / **17711** with
IDENTICAL hit counts (311 892) — the one 17711 is the every-frame DLYSEED2 run, the others are v1
DLYSEED and `_ONCE` runs — i.e. the max moves with the stale offset, not with the line. The
coincidence 17711 ≈ 402 ms ≈ 350 ms was luck. **The LLE's realized single-delay depth is therefore
UNMEASURED.** Under the device's address model `addr = cell + rot` it equals `(R_cell − W_cell)`
by construction (the descriptor difference, ~350 ms) — a property of the model, not a measurement
of the chip. The instrument that would measure it: a per-program census reset (env-gated) with
mask bit 60 OFF, or the `_ONCE` recirculation read at F+k with the address rotation accounted for.

⚠ **This ALSO retracts the earlier weaker reading.** My first pass seed-once-and-read-at-F+k test found `L = −2` at
F+500 and `L = 0` at F+15437 and I called it "suggestive of the Q4 ~500-frame lag". That was
**near-noise and wrong**: −2 is not a recirculation of a 0.5-FS seed — a single `_ONCE` seed plus
the per-frame address rotation (addr = cellv + m_frames_run) simply does not land the impulse on the
exact cell the F+k read hits. The §200 age census is the device's own, reliable instrument and it
says ~descriptor, not ~500. (§234's "500" is a *separate* quantity — the output-stage lag `sd_rerun`
measured under the shipped 0x0D/0x0E pair — not the external-line depth this census reports; the two
are not in conflict once distinguished.)

## Honest grade
§1–§3 are MEASURED from the live seeded trace and are the first POSITIVE oracle confrontation of
a non-biquad program: the decoded arithmetic primitives are the chip's, and the open codes are
confined to the boundary words. §4 is a MEASURED negative result about the audio test method. §5 is
RETRACTED in full (two readings, both wrong: the census max is a stale speculative offset, the
seed-residue was noise) — the realized line depth is UNMEASURED. No decode was changed; DLYSEED2 is
a pure observation diagnostic. (`dlyseed_confront.py` now also names 2 of §3's 7 boundary rows as
the device's "bus-add" form — corrected here to the form the tool actually tests and
`N-DEVICE-ALGEBRA-EXTRACTED` §3 confirms on 442 rows: **`acc ← acc[N−1] + P[N−1] + (L[N] << 16)`**,
not `acc += L<<16`; the product term is part of it — leaving 5 boundary words, same residue, finer label.)

## 6. Net result toward full LLE
The single delay's **arithmetic core is confirmed decoded** (multiplier + one-slot accumulator,
bit-exact, generalizing the biquad). Its external delay-line depth is NOT yet measured (§5).
What stays open is unchanged and unchanged in kind: the class-2 / 0x0D-0x0E mixing / SRC-0x00
boundary words (the feedback/mix fold), and the `SRC 0x11`/accb input route — both hardware/
bit-encoding items, not HLE-answerable (`N-HLE-AS-LLE-ORACLE-2026-09-12 §4`). The HLE oracle has now
validated the delay ARITHMETIC as far as the open codes allow. The trace this note is built on is
the every-frame DLYSEED2 capture (the `_ONCE`/v1 captures show 0 impulse rows — the tool's Q1
distinguishes them).
