# KN5000 effects-DSP — next actions (synthesized, post-verification 2026-09-11)

Synthesized from an adversarial-verification + strategy-design workflow (7 agents). It
corrects two overclaims first, then orders the reachable work by value-per-effort and by
the ONE discipline the verification hammered: **the biquad's remaining unknown is decidable
only by the internal STATE trajectory with a differential null — response, the HLE oracle
and the designer's (f0,gain,Q) are all topology-invariant and cannot decide it.**

## Corrections already applied this session (contradict-and-correct)
- **DF-II "transposed" → SHARED-DELAY (DF-II-family), realization UNDECIDED.** `biquad_topology_probe.py`
  proves DF-I ≡ DF-II ≡ DF-II-transposed in response (max diff 0.0). Earlier "transposed" numbers were
  the DF-I probe's (reproducibility gap, now closed).
- **"reverb uses no class-A MACs" → RETRACTED** (class4 read as `>>32` not `>>20`; n=142 is class-A).
  The reverb multiplies its feedback with the same class-A MAC as the biquad.
- Both fixed in the plan, the handoff, docs §9/§10, and memory.

## Ordered next actions

**N1 — Fix the b/a coefficient role split (cheapest, unblocks everything). [1–2 sessions]**
The red flag: under the current slot→role guess, all 5 EQ bands' poles cluster at ~13.5 kHz — a real
parametric EQ spreads across the spectrum, so the assignment (which captured slots are b0/b1/b2/a1/a2,
with b0=0.125 a fixed input scale) is probably wrong. Pin it with the firmware EQ **designer as a
COEFFICIENT oracle** (not a topology one): grid `biquad_peaking(f0,Q,gain)` over plausible (f0,Q,gain),
find the (params, role-permutation) that reproduces the captured band coefficients, and require the
recovered f0 to spread sensibly across the 5 bands. Accept only if the fit is tight AND the band
frequencies are musically plausible. *Falsifier:* if no permutation both fits the coefficients and
spreads the bands, the EQ form isn't the assumed peaking biquad — a finding, not something to tune.

**N2 — Decide the biquad TOPOLOGY by cross-frame state matching (the only valid decode). [multi-session]**
Build `biquad_topology_probe.py` out into a differential oracle over {DF-I, DF-II canonical, DF-II
transposed, scaled/coupled} under 24-bit **saturating** fixed point. Capture the chip's per-frame
state cells (0x65/0x66 + the 0x50 stereo twin) across CONSECUTIVE frames (held steady note, RULE-12
`:KEY2`; script N runs at `UPD6383_TRACE_FRAME=F,F+1,…`; read the operand address BEFORE the
post-increment; watch the twin). Accept a form ONLY if it reproduces the cell trajectory bit-exactly
AND a rival form FAILS the same test (a null). *Pre-register* the alignment check: steady-state cells
must be frame-invariant before rotation is trusted. Never validate topology on response/FFT/HLE/designer.

**N3 — Realize the confirmed form in-core → audible EQ. [after N1+N2]**
Add `UPD6383_SPEC_DF2` (default off): the decoded shared-state update on the captured coefficients,
full internal precision, clamp only at the measured `acc_to_datum`; drive with `SPEC_INJECT` audio;
route to the mix behind `SPEC_AUDIO` (default off, beside the HLE render). Accept ONLY on an
**independent** spectral test: FFT the rendered PCM and confirm it TRACKS panel edits (G12 → +12 dB
bump at band f0; FC16k → peak migrates) vs `peq_ab.py`'s analytic H(z). "Makes sound" / "differs from
silence" is NOT a pass (RULE 12/13). Circular check forbidden (never compare against a replay of the
same coefficients the core just used).

**N4 — Consolidate + broaden in parallel (highest value-per-effort, needs no input route). [ongoing]**
Route AROUND the proven input-route/accb dependency cycle via controlled seeding + the HLE oracle:
- reverb: add `DLYSEED` (AS_DELAY seed) and impulse-test for a decaying echo train whose per-loop
  decay tracks the gains, gated by the §73 gain-sensitivity falsifier (the delay-line ADVANCE, not the
  arithmetic, is the open part now that the class-A retraction stands);
- extend the seed-probe method to the one-pole and LFO/delay families (existing tools);
- WSA1R twin as a cross-check oracle for **shared biquad/core primitives only** (NOT the reverb — its
  is comb/FDN vs the KN5000 all-pass ladder);
- regenerate LEDGER (`gen_ledger.py`) + shipped fixlist (`gen_fixlist.py`); keep speculative fits in
  the disassembler's speculative tier with one-line provenance.

## Standing guardrails (verification-reinforced)
1. Topology: differential null, saturating state, identical input across frames — never response.
2. Never sweep (shift × sign × role) for a stable-LOOKING result (criterion that cannot fail).
3. Speculative audio: default-off, labelled, beside the HLE reference; never called faithful.
4. The input-route / accb-op cycle is hardware/bit-encoding gated — do not re-attempt via capture.
5. Commit the producing script for every quoted number, same session (the DF-II gap was a lapse).
6. 100% decode is unreachable (~93.3% ceiling); scope wins as coverage + named forms, not completion.

**Recommended sequencing:** N1 (fix roles) and N4 (consolidate + reverb DLYSEED) first — cheap, high
value, no input route. N2 (topology cross-frame) is the rigorous flagship but multi-session. N3
(audible) only after N1+N2. Front-load N1: the 13.5 kHz clustering says a wrong role split may be
masquerading as the whole "topology" mystery, so fixing roles could sharply narrow N2.
