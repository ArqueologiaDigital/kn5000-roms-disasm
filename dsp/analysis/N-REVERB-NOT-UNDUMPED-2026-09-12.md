# Reverb is NOT blocked on undumped data — and is audible now (2026-09-12)

Correcting a prior overstatement. I had lumped the reverb with distortion as "walled," which
wrongly implied it needed data that isn't dumped. It does not. This note states the evidence and
ships an audible reconstruction.

## Evidence: every reverb coefficient is dumped and decoded
`dossier/reverb_listing.tsv` (the unit-1 reverb body, algo 16, the ONLY reverb image — shared by
all 12 reverb presets) decodes the whole program to the bit, with each C-RAM coefficient cell
role-assigned and its value captured:
- **0x90–0x92** input scaling (0.25 / 0.5 / 0.5) — PROVEN
- **0x93–0x95, 0x9E–0xA0, 0xA6–0xA8** three damping filters (HIGH DAMP) — PROVEN
- **0x97** reverb **decay / REVERB-TIME** coeff = 0x199999 = 0.4 — PROVEN
- **0x98–0x9C** diffuser ladder-0 (5 stages), **0xA1–0xA4** ladder-1 (4 stages) — PROVEN
- **0xA9–0xB0** left/right output-tail mix — PROVEN

`programs.tsv` algo 16: *"reverb tank: all-pass diffuser ladders of 5 and 4 stages + damping —
algorithm decoded to the bit"*, status **SOLVED**. The external delay-DRAM pipeline is decoded
too (adjudication-round5: delay = READ_CELL − WRITE_CELL, descriptor-addressed, moves with the
DELAY knob). And `N4-REVERB-DECAY-PROBE` showed the reverb **measurably decays in the emulator**
(seed the correct delay-line cells → clean geometric per-frame ratios, 0xD0 ×0.767).

So there is **no undumped dependency**. Contrast: distortion's clipping curve is a genuinely
undumped ROM LUT, and the acoustic-modeling chip's wave ROMs are undumped — those are real
missing-data walls. The reverb is not one of them.

## What IS still open (a decode refinement, not missing data)
`reverb-topology-round7.md`: the exact micro-topology is **narrowed but not closed** — the
surviving families are **pipe-comb** and **series-comb-cascade** (first-order all-pass, parallel
comb bank, Moorer, nested all-pass and lattice are all rejected at 0 matches). Plus the 6-word
core's per-word roles are down to two assignments, and the loop-latency / drain conventions.
Mapping the measured decay ratios (0.767, 0.547) to the ladder gains needs the delay-line
lengths. All of this is the same kind of intervention-crackable decode as the 13 effects already
validated — NOT a data wall.

## Shipped: an audible reverb reconstructed from the decoded coefficients (preview)
`kn5000_tonegen.cpp` HLE REVERB insert (DSPHLE == 14, default OFF). It reads the decoded reverb
C-RAM (input gain, the diffuser-ladder gains as diffuser coefficients, the HIGH-DAMP cell as the
one-pole damping, the decay coeff 0x97 driving the loop feedback, the output-tail mix) and runs a
four-comb + two-all-pass reverb. A/B (`delay_ab.lua` pluck + `reverb_ab.py`): reverb-on carries a
decaying tail **6.1× above the dry control** in the 0.4–1.2 s window, absent from the dry pluck.
**Honest grade:** the diffusion/damping/decay-control come from the decoded coefficients; the exact
micro-topology (comb family) and the absolute RT60 are the open decode above, so this is a
labelled PREVIEW, not a bit-faithful reverb — but it proves the reverb is audible from dumped data.
