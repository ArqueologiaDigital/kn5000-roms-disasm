# DSP effect topology vs. the textbook algorithms

**Date 2026-09-07.** The effect NAMES are ground truth — a program called PARAMETRIC EQ
*is* a biquad chain, one called SINGLE DELAY *is* a delay line. This note checks the
reverse-engineered microcode against the canonical DSP topology each name implies, for
every KN5000 and WSA1R effect, and cross-checks the two products against each other.

Instrument: `dsp/tools/dsp_topology_fingerprint.py` (reads the committed `.dsm` listings;
counts idioms through the shared ISA model). Regenerate the tables below with it.

## The idioms counted, and what algorithm each implies

| idiom | uPD6383 form | appears in |
|---|---|---|
| **DRw / DRr** | class-1 ESCAPE word; addr8 bit 6 = direction | delay-line taps (write in / read tap) — delay, reverb, chorus, flanger |
| **cMAC** | class-A multiply | filter/gain coefficients — biquads (EQ), diffuser/feedback gains |
| **tbl** | class-6 table-lookup | a nonlinearity LUT — distortion, exciter, ring-mod |
| **bqp** | ACT 0x0D/0x0E | the two z⁻¹ biquad delay-stage updates — all-pass chains, EQ state |
| **accB** | SRC 0x11 (2nd accumulator) | a parallel path / crossfade |

## What the fingerprint confirms (each name matches its canonical topology)

- **PARAMETRIC EQ** — cMAC-dominated (KN5000 70, WSA1R 84 multiplies), **zero** delay-line
  DRAM. That is exactly a bank of Direct-Form-I biquads: coefficients everywhere, no delay
  line. It is the highest-decode program on both chips and the ISA reference.
- **SINGLE DELAY** — 3 writes / 3 reads, no table. A delay line with feedback, as named.
- **MULTI TAP DELAY** — **2 writes / 5 reads**: one input write, several read taps. The
  "multi-tap" is literally visible in the read/write asymmetry.
- **ROOM REVERB / GATED REVERB** — the most DRAM-heavy programs (ROOM REVERB KN5000
  13w/19r), i.e. a large all-pass/comb network — the reverb tank, as decoded.
- **PHASER** — ~0 delay DRAM but **30 biquad-stage words**: an all-pass *chain* built from
  the z⁻¹ pair, not a delay line. Textbook phaser.
- **CHORUS / FLANGER / ENSEMBLE** — LFO-swept delay taps (3–5 writes, 5–16 reads);
  ENSEMBLE's one-write / many-read shape is the multi-voice detune.
- **DISTORTION / FUZZ / OVERDRIVE** — a table-lookup nonlinearity (tbl 2) with little/no
  delay; the waveshaper.
- **combination effects** (S.DELAY+CHORUS, PEQ+COMPR+DIST, …) — the union of their stages'
  idioms, in name order.

## Cross-product: the two chips run the SAME algorithms

For the 31 effects present on both, the fingerprints line up (`--compare`):

```
  SINGLE DELAY     KN5000 3w/3r   WSA1R 3w/3r
  MULTI TAP DELAY         2w/5r          2w/5r
  PARAMETRIC EQ        70 cMAC        84 cMAC   (both 0 delay-line)
  PHASER               0-1w/2r        0-1w/2r
  S.DELAY+CHORUS          7w/8r          7w/8r
  S.DELAY+S.DELAY         5w/6r          5w/6r
```

This is independent structural confirmation of the ISA cross-validation: the same effect,
built the same way, on two products with the same chip.

## Where they differ (real findings, not noise)

- **The reverbs differ in tap structure — and the follow-up is now answered.** The DRAM
  access *order* (`dsp_idiom_sequence.py`, DRAM-only trace) tells the network apart:
  - **KN5000 ROOM REVERB** = `RWRWRWRW…RRRRRRRW` — read/write *alternation*, i.e. a chain
    of **all-pass diffuser stages** (each reads the old sample and writes the new), then a
    run of output-tap reads. Matches its decoded role exactly.
  - **WSA1R ROOM REVERB** = `RW WWWWWWWWWWWWW R WWWWWWWWWWWW RRRRRRRRR W` — long *runs of
    writes* into a delay line at many tap points (with `DCDC…` = delay + C-format immediate
    tap offsets), i.e. a **write-heavy multi-tap / comb (feedback-delay-network)** structure,
    not an all-pass ladder.
  So the two products implement the *same effect name with different reverb architectures*:
  KN5000 an all-pass diffuser tank, WSA1R a comb/FDN. A genuine cross-product design
  difference, pinned to the DRAM access pattern.
- **NO OPERATION is minimal on the WSA1R** — 10 words / 0 multiplies, versus the KN5000's
  49-word pass-through that still runs a level detector. The WSA1R bypass is a true
  near-nop.

## Caveat (honest)

Every program shows a baseline **~2 DRr** even when its algorithm needs none (e.g.
PARAMETRIC EQ). Those two reads are the shared prologue's delay access, not the effect
body's — treat DRr counts as "2 + the body's own taps". The idiom counts are structural
signatures, not a proof of the exact signal-flow; they confirm the *family* topology and
flag mismatches worth a closer read, which is their purpose.
