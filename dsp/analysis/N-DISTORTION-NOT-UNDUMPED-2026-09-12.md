# Distortion's clipping curve is NOT genuinely undumped (2026-09-12)

Re-evaluating a claim at Felipe's challenge. Several documents had called the distortion
waveshaper a "genuinely-undumped class-6 clipping LUT" and grouped it with the (real) data walls.
That framing is **wrong**. This note states the evidence, and is careful not to overcorrect into a
second wrong claim ("it's TABLE B").

## The claim under test
> "distortion's genuinely-undumped clipping LUT" — that the memoryless waveshaper at the heart of
> OVERDRIVE / FUZZ / DISTORTION reads a transfer curve that lives only in the physical chip and is
> therefore unrecoverable.

## Why it is refuted
The waveshaper is the **class-6 table-lookup idiom** `040.0.00.C63 | 000.6.TT.4CD | 012.4.01.1CE`
(distortion/fuzz: `TT = 0x28`, the table *selector*). Three facts place its data firmly in dumped
memory:

1. **class-6 reads a table FROM C-RAM, not from silicon.** `instruction-set.md`: class-6 + `C63`
   are measured as ONE idiom — 53 of 53 sites in both directions, against a 0.94 base-rate null —
   and `C63` is `SRC 0x11 / ACT 0x03` = "load the index register `m_tb`", so the shape is *load an
   index, then read `table[index]`* where the table is addressed in C-RAM. There is no evidence of
   an internal hardware LUT ROM on this path.

2. **PROVEN for the identical idiom's LFO-WAVEFORM role — the table is host-uploaded.** The class-6
   idiom serves three roles (LFO waveform 7/7, waveshaper 3/3, ring-mod carrier); the LFO role is
   the one we can see end to end. The LFO table is a **24-entry sine UPLOADED BY THE HOST**:
   decoding the 24 host packets and comparing with `round(0.95·2²³·sin(2πk/24 + 0.1))` matches to
   **max 1 LSB** (`upd6383.cpp` §188 static measurement; tag bit 7 set in 12 of 24 — exactly a
   sine's LSB parity). The scale coefficient is `0x18 = 24` at **8/8** sites and the idiom computes
   `(coef·phase) >> 23` → an integer index 0..23 (`lfo-ramp.md §10`). So the class-6 table is
   **firmware data the host uploads**, i.e. dumped — not in silicon.

3. **C-RAM's entire contents come from dumped ROM.** Every C-RAM cell is written either by a
   per-preset parameter stream (themselves dumped program ROM) or by the resident boot blob at
   **Sub CPU ROM 0x01E6BE** (`k4-cursor.md §1.1`, PROVEN BY CONSTRUCTION, matches cold-boot capture
   byte for byte). A runtime C-RAM capture that shows **zeros** at a table region is a **capture
   artifact** — it replays only parameter streams from a zeroed C-RAM and, for resident tables,
   never replays the boot blob. That zero is what the old "undumped" reading mistook for missing
   data.

**Conclusion: the clipping curve is recoverable from dumped data.** It is not a data wall. Contrast
the genuinely-undumped items: the acoustic-modeling L7A1429 wave mask ROMs (a separate chip, no
dump, hardware unreachable). Distortion is not one of them.

## What is still open — a DECODE refinement, not missing data
- **Which exact C-RAM cells hold the distortion waveshaper table** (selector `TT = 0x28`) and the
  **index arithmetic**. `0x28` is in the unit-0 coefficient bank range (0x00..0x4F), not the
  resident-table region — so the table is most likely assembled per-preset, but the base has not
  been pinned. The §162/§167 device probes exist to do this: first confirm `m_tb` VARIES at the
  class-6 site (else the lookup is frozen), then read the table.
- ⚠ **Do NOT claim the resident ramp/clamp tables A/B are the clip curve.** `C-RAM[0x50+k] =
  (32+k)·0x400` and `C-RAM[0x70+k] = min(1214k, 0x7FFF)` sit at 0x50..0x8B and are read by K3
  headline 1 as the per-unit **delay-DRAM allocation**, not as a transfer curve; `0x28` is not in
  that region. The "min(1214k,0x7FFF) rail-clip" shape is suggestive but unproven for this role.

## Bottom line for an HLE distortion
The **DRIVE pre-gain, VOLUME, and the OVERDRIVE tone biquad** (cells in the dumped preset stream,
same route as the 14 validated effects) are MEASURABLE. The **clip transfer curve** is until the
table base is pinned a **labelled SPECULATIVE stand-in** (hard-clip / tanh), default-off — honestly
graded, not presented as the decoded curve. That is the same discipline used for every other block:
ship what is measured, label what is a stand-in, and keep it drop-in-replaceable once the table is
decoded.
