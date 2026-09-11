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

**N1 — Fix the b/a coefficient role split. PREMISE REFUTED 2026-09-11; redirected. [done → re-capture]**
Original premise: under the current slot→role guess all 5 EQ bands' poles cluster at ~13.5 kHz, so the
b/a assignment is probably wrong. `eq_role_split_probe.py` tested this and the **premise is false**:
- the current split reproduces the clustering exactly (band 0 pole r=0.710, f_norm=0.614 ≈ 13538 Hz);
- **no** permutation of the 4 free coeffs {entry,store,c2,c3} → {b1,b2,a1,a2} × {sub,add} spreads the
  bands — max spread 0.074 of Nyquist vs the ~0.7 a real 5-band EQ needs (falsifier fires against
  "wrong role split");
- the numerator {b0=0.125, entry, store} sums to 1.000–1.009 in every band — a unity-DC-gain numerator
  that *structurally confirms* the split, leaving {c2,c3} as the denominator;
- it is **not** a textbook RBJ peaking EQ (b1=entry≈0.75 ≠ a1=c2≈0.50);
- the per-band response is not five spread bands: the "makeup" coeff is ≈0 in bands 1/3/4, dropping
  them 60–240 dB — it is a routing/mode gate, not an output gain.
⟹ The clustering is a property of the CAPTURED COEFFICIENTS, not the decode. This trace is a
near-default / partly-muted EQ state; per-band centre frequency is not readable from it.
**Redirect (N1'): DONE 2026-09-11 — 13.5 kHz red flag RESOLVED.** Ran the differential capture
(peq_gain.lua flat vs +12 dB gain vs FC-up; `eq_gain_diff_probe.py`, data committed). Results:
the panel EQ coefficients live in **C-RAM 0x00+** as five 6-cell band groups (near-RBJ); **0x03 is
the 2cos ω₀ frequency term** (an FC edit moves it +1.99→−1.09), **0x01 is a gain term** (a +12 dB
edit moves only 0x01 + slightly 0x00/0x02); the 5 bands' 2cos terms are 1.99→1.79 → centres
≈673/966/1405/2091/3219 Hz — **genuinely spread**. The ~13.5 kHz cluster was an artefact of reading
the cursor-walk *D-RAM operand* cells (eq_coef_layout_probe) as the coefficients. Full write-up:
`dsp/analysis/N1-EQ-COEFFICIENT-MEMORY-2026-09-11.md`. **Follow-up (feeds N2):** reconcile the
uploaded C-RAM 0x00+ coeffs (2cos form) with the cursor-walk operands the multiplier uses (0.75/0.5…)
— that transform IS the realization question and may decide the DF-II-family form more cheaply than a
cross-frame state match.

**N2 — Decide the biquad TOPOLOGY by cross-frame state matching (the only valid decode). [multi-session; STARTED 2026-09-11]**
Progress (`N2-CROSSFRAME-STATE-PROGRESS-2026-09-11.md`): built `UPD6383_TRACE_DETAIL` (per-word state
during note-play) + captured a consecutive-frame pair with SPEC_INJECT audio. MEASURED: the input
delay line shifts x0→x1 one cell/frame (0x65[B]==0x64[A] exactly). BLOCKER: the recursion SATURATES
(acc pinned, 0x66/0x67 frozen), so the recursive trajectory is degenerate and cannot decide the form —
NO topology claim made (a constant matches every form). Next: seed a small non-saturating excitation
(BIQSEED-style), capture ~8 frames, run the differential null. Original spec follows.
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
- reverb: ADVANCED 2026-09-11 — built `UPD6383_REVSEED_ONCE` + `reverb_select.lua` (opens the DIGITAL
  REVERB page 0x0A) + retargeted REVSEED to the measured delay-line cells. The reverb now **DECAYS**:
  seeded cells show stable geometric per-frame ratios (0xD0 ×0.767, 0xD2/0x8A ×0.547 decay; 0x8B ×2.024
  growth) — the linear feedback datapath is live and the seed-once impulse-decay method works. STILL
  OPEN: map the ratios to the all-pass gains (0.91/0.1367) — needs the delay-line structure (§73-78);
  the harness (seed-once + reverb page + delay-cell targeting + `reverb_decay_probe.py`) is now in
  place. See `N4-REVERB-DECAY-PROBE-2026-09-11.md`;
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

**Recommended sequencing:** N1 is DONE (offline) and its premise refuted — the role split is
structurally confirmed, not wrong; the clustering is in the captured (near-default) coefficients, so
the successor is **N1'** (differential per-band gain/centre capture), which is emulator-gated and
pairs naturally with N2 (both need fresh `-log` captures of the EQ under controlled panel settings).
Do N1' + N4 (consolidate + reverb DLYSEED) next — cheap, high value, no input route. N2 (topology
cross-frame) is the rigorous flagship but multi-session. N3 (audible) only after N1'+N2.
