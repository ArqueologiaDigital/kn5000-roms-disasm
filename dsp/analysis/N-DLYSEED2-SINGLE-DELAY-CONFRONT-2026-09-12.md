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
**RESULT — the realized delay matches the DESCRIPTOR (~350–400 ms), measured by the device's own
§200 age census.** The census is printed in the SAME trace dump (not boot-gated as I first thought —
it accumulates every delay read and prints at the frame-trace). For the single delay's read
descriptor **0x26** it reports `frames_since_written 0 .. 17711 (0.00 .. 401.61 ms @ 44100 Hz)` —
the maximum age ≈ **402 ms**, right by the descriptor's nominal **350 ms** (15437 samples); the
other descriptors span similar depths (0x28 up to 1112 ms, etc.). So the LLE's external delay LINE
DEPTH tracks the descriptor, as the HLE delay assumes.

⚠ **This RETRACTS a weaker reading.** My first pass seed-once-and-read-at-F+k test found `L = −2` at
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
MEASURED from the device's §200 age census (realized delay-line depth ≈ the descriptor, ~350–400 ms),
and RETRACTS the near-noise seed-residue reading. No decode was changed; DLYSEED2 is a pure
observation diagnostic.

## 6. Net result toward full LLE
The single delay's **arithmetic core is confirmed decoded** (multiplier + one-slot accumulator,
bit-exact, generalizing the biquad) and its **external delay-line depth matches the descriptor**.
What stays open is unchanged and unchanged in kind: the class-2 / 0x0D-0x0E mixing / SRC-0x00
boundary words (the feedback/mix fold), and the `SRC 0x11`/accb input route — both hardware/
bit-encoding items, not HLE-answerable (`N-HLE-AS-LLE-ORACLE-2026-09-12 §4`). The HLE oracle has now
validated the delay datapath as far as the open codes allow.
