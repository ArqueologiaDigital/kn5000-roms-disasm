# uPD6383GF effect algorithms — an implementation spec

**Date 2026-09-08.** The actionable summary layer over the decode work: for each effect
family, the block diagram, the kernel primitive(s) it is built from, and where its
coefficients live. Evidence for every reading is in `DECODE-by-correlation-2026-09-08.md`
(§ refs below), `TOPOLOGY-vs-ALGORITHMS.md`, and the per-program `disasm/*.dsm`. This file is
the "what an emulator needs to build" view; the grade column says how far to trust each row.

Grades: **PROVEN** (by construction / measured), **STRONG** (composition of proven parts, or
a cross-catalog correlation), **GRADED** (a single correlation or structural inference).

## The four kernel primitives (everything is assembled from these)

| kernel | ISA signature | role | grade | ref |
|---|---|---|---|---|
| **Direct-Form-I biquad** | 9-word section: `ld.ta`(0x13) `mac`(0x12) `mac` `mac.tb`(0x14) `mac` `mac.st tb` `post`(class-8) `mac.st`(makeup) `ld.st ta` | 2nd-order section, coeffs `b1,b0,b2,−a1,−a2,makeup`, two state latches `ta`/`tb` | PROVEN (prog39) | §7b |
| **two-state update** | ACT `0x0D`→`0x0E` adjacent pair (82%) | one/two-pole filter in I/O amble + feedback damping; general | STRONG | §3, §7c |
| **LFO generator** | phase-accum (`phase+=inc`, `phase wrap` @0x7FFFFF) → class-6 lookup `addr8=0x18/1A/1E/20`, `lo12=0x4CD` | shaped periodic modulation; one lookup per voice | STRONG | §6, §7a |
| **delay line** | class-1 escape DRAM `R`/`W` (addr8 bit6 = direction; 0x30 = first access); length via C-format `lo12=0x000` | external delay-DRAM; address in the descriptor block, not the word | PROVEN (R3) | §1, §4 |
| **waveshaper** | class-6 lookup `addr8=0x28`, `lo12=0x4CD` | static nonlinear curve (distortion) | STRONG | §6, §7d |

Two shared gains ride on the C-format immediate load: `lo12=0x44C` ≈ near-unity makeup /
crossfade gain (0.78–0.97 of 1024); `lo12=0x451` a filter-count parameter; `lo12=0x000` the
delay length (§1). All effects are stereo unless noted (two byte-identical datapath halves).

## Per-family assembly

### Parametric EQ  (prog39 / eff04) — PROVEN
```
x ──▶ [DF-I biquad] ─▶ [DF-I biquad] ─▶ … ─▶ y      (N sections in series, per channel)
```
- KN5000: **5 bands × 2 ch**; WSA1R: **6 bands × 2 ch**. Same kernel — EQ is **convergent**
  across products.
- Coefficients: C-RAM, 6 per section, in order `b1,b0,b2,−a1,−a2,makeup` (roles PROVEN).
- The PEQ+* combos prepend this EQ to a modulation/delay/distortion stage.

### Modulation: chorus / flanger / phaser / vibrato / ensemble / auto-pan  (prog01…) — STRONG
```
        ┌─ LFO gen (voice 0, table 0x18) ─┐
phase ──┤                                  ├─▶ sweep the delay read tap
        └─ LFO gen (voice 1, table 0x20) ─┘
x ──▶ [write delay] … [read swept tap] ──▶ ×makeup(0x44C) ──▶ mix ──▶ y
```
- **Voice count = the number of distinct LFO-table selectors** (each is one detuned phase):
  **ENSEMBLE = 4** (`0x18/1A/1E/20`), **CHORUS / MOD-CHORUS / PEQ+CHORUS / S.DELAY+CHORUS = 2**
  (quadrature, `0x18`+`0x20`/`0x1E`), **FLANGER / PHASER / VIBRATO / AUTO-PAN / RING-MOD = 1**.
  Convergent across both products. This is *why* a chorus sounds richer than a vibrato and an
  ensemble richer than a chorus — literally more detuned LFO voices. (`dsp_datapath_fingerprint.py`)
- Flanger/phaser: single LFO, shorter delay / all-pass chain (phaser sweeps all-pass notches).
- Wet mix from the `op0x66` coefficient pair; delay length from `lo12=0x000`.

### Distortion family: distortion / overdrive / fuzz / exciter  (prog32…) — STRONG
```
x ──▶ ×drive(op0x61) ──▶ [waveshaper 0x28] ──▶ ×level(op0x62) ──▶ y   (+ optional tone biquad)
```
- **FUZZ, DISTORTION**: bare waveshaper (hardest).
- **OVERDRIVE, EXCITER**: waveshaper **→ post DF-I tone biquad** (smooths clip harmonics).
- **PEQ+DIST / PEQ+OVERDR**: **pre-EQ biquad(s) → waveshaper** (parametric tone into the drive).
- One shared kernel `gain·waveshaper·gain` + a placeable biquad; the curve is a C-RAM table
  (`op0x61`=drive, `op0x62`=output-level, decoded by position, §7d).

### Reverb  (prog08/16, eff18/26–37) — STRONG, and product-divergent
```
KN5000 room:  … ─▶ [all-pass diffuser ladder: RMaaW, 1 coeff/stage] ─▶ …
WSA1R room/plate/concert: … ─▶ [comb + biquad damping: RMMzzW, 2+ coeff/stage] ─▶ …
```
- **Different algorithm, same name**: KN5000 = single-coefficient all-pass diffuser; WSA1R =
  lossy comb with a damping filter in the feedback (§5).
- WSA1R's 13 named reverbs are **4 distinct programs + coefficient presets** (§2): an emulator
  needs ~4 reverb kernels, not 13.
- Delay length constant (`lo12=0x000`=480) reloaded before each comb write (`WC` motif, §4);
  damping via the 0x0D/0x0E pair inside the loop.

### Delay: single / multi-tap / manual  (prog09/10, eff23–25) — STRONG
```
x ──▶ [write delay] ──▶ [read tap]×g ──▶ (+feedback) ──▶ y      (taps from descriptor cells)
```
- Tap **count** = the DRAM-read count; tap **offsets** live in the descriptor block, not the
  program words. Multi-tap shares a single write with several reads.

### Pitch shifter  (eff54) — GRADED (this session)
```
x ──▶ [write delay] ──▶ ┌ read tap A (ramping) ×window ┐
                        ├                               ├─(crossfade)─▶ y
                        └ read tap B (ramping) ×window ┘
```
- **Delay-line crossfading pitch shifter, not a phase vocoder**: 8 DRAM reads / 7 writes,
  **no LFO table, no waveshaper**, near-unity crossfade gain `992≈0.97` at `lo12=0x44C`.
- The `0x0D/0x0E`-family ops appear in **runs** (not clean pairs) around each tap — consistent
  with fractional-delay interpolation of the ramping read pointer. Internal crossfade window
  structure is GRADED (the ramp is in the descriptor, invisible statically).

### Ring modulator / auto-wah / rotary  — STRONG/GRADED
- **Ring modulator**: LFO gen (`0x18`) as the carrier, multiplied with the input (no delay).
- **Auto-wah**: a **state-variable / DF-I biquad** whose cutoff is LFO- or envelope-swept
  (`ld.ta` present, 1 section) — §7c lists it among the DF-I users.
- **Rotary / rock-rotary**: LFO-swept delay + a tone biquad (Doppler + horn coloration).

## What an emulator author should take from this

1. Implement **four kernels** (DF-I biquad, two-state filter, LFO gen, delay line) + a
   **waveshaper LUT**. Every effect is a wiring of these.
2. Filters are **two mechanisms**: DF-I for tone-shaping EQ; the 0x0D/0x0E pair for
   reverb/mod feedback damping. Do not conflate them.
3. Coefficients and tap offsets are **C-RAM / descriptor data**, streamed per effect — the
   program words give the *topology*, the presets give the *character*. This is why runtime
   effect changes upload only coefficients, never new I-RAM (the Goal-2 runtime finding).
   Confirmed a third way by the immediate-value census (`DECODE-by-correlation` §9): **no
   C-format value-load anywhere carries a biquad-range coefficient** — every value is a size,
   a gain or a filter-count (`|imm| ≤ 1440`); the numeric coefficients arrive only via C-RAM.
4. **Division of labour, by C-format opcode.** Effect bodies contain *only* value-loads
   (opcode `0x620`) and no control words; the resident kernel contains *only* control words —
   WAIT/SYNC (`0x600`, segmenting the per-frame loop into event-synchronised phases) and
   pointer-loads (`0x60B–D`) — and no value-loads. Model the kernel as the control/sync engine
   and the body as straight-line signal code parameterised by streamed C-RAM.
5. Reverb needs **~4 programs + presets**, and the reverb kernel **differs by product**
   (KN5000 all-pass vs WSA1R comb+damp); EQ and the modulation LFO are **shared**.

Every row here is reproducible from the committed `dsp/tools/dsp_*_analysis.py` +
`dsp_biquad_mechanisms.py` against the `disasm/*.dsm`; grades are honest — GRADED rows are
single-correlation or structural, not proven.
