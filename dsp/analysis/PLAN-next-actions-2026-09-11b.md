# Next actions — crack the +2/+3 y-history writer (2026-09-11, later)

The N2 differential null is now localized to ONE concrete question: **what writes the biquad's
+2/+3 y-history cells (e.g. 0x66/0x67)?** They evolve frame-to-frame but no decoded bit-4 DSP store
targets them (full-frame census: every band stores only to its +1 shared-w cell + the 0x50 twin).
This plan cracks that, then the downstream nulls follow. Speculative/complementary techniques, each
with a falsifier.

## P1 — WATCH who writes 0x66 [core diagnostic + capture; the key instrument]
Add `UPD6383_WATCH_CELL=0xNN` (default off): at the general D-RAM write sites (store_mode dest,
the §221 host/external write `m_dram_wp`, and the acc-store `cell`), log every write to the watched
cell with the writing site + iw + frame. Run on the seeded EQ capture and read who writes 0x66.
- **Hypothesis (speculative):** it is the §221 host/external write (`m_dram_wp`, line ~1905) — the
  same external delay-DRAM mechanism decoded for the reverb (READ_CELL−WRITE_CELL, descriptor+G).
  If so, the biquad y-history is populated by the external delay path, NOT the bit-4 store — which
  unifies the biquad and reverb state mechanisms and IS the input-route/external-writer link.
- **Falsifier:** if the watch shows a DSP word with a non-bit-4 store gate writes it, the gate is
  undecoded (decode it); if nothing in the DSP writes it, an external device does (characterize it).

### P1 RESULT 2026-09-11 — the writer is a DECODED word (correcting my over-correction)
`UPD6383_WATCH_CELL=0x66` on the seeded EQ: cell 0x66 is written **every frame by iw=150 via
`store_mode` (site 2)** — data `data/kn5000-dsp-eq-watch-0x66-2026-09-11.txt`. iw=150 is **cur 0x06,
band-1's ENTRY store** (word 0x0212AFF407, hi12=0x212 = store bit + f31=1, class-A, coef −0.49527):
it reads operand 0x65 (prev-band w) and stores the result to 0x66. So the +2/+3 y-history writer is
**NOT external and NOT undecoded** — it is the cross-band entry store, a decoded DSP word on the
`store_mode` path that my earlier **bit-4-only census missed** (store_mode is a distinct, decoded
store path). The factor-of-2 recurs: it writes 55605 while 0x66 reads back 0.006629 = 27803 = 55605/2.
**Correction:** my "writer is outside the decoded store path / re-connects to the input route" was an
OVER-correction — the writer is decoded; the input route is not needed for this. **Consequence:** the
biquad state-update law is now attributable end-to-end (0x65 ← cur 0x02 own-band store; 0x66 ← cur
0x06 cross-band entry store), so the N2 null is unblocked modulo the exact store-target increment
(pre/post) — the last small unknown, and instruction-set.md already narrows it.

## P2 — resolve the state update, then run the N2 null [offline, after P1]
With every writer of 0x65/0x66/0x67 known, the biquad state-update law is complete. Model DF-II
canonical vs transposed with that law + the captured input + coefficients; accept a form only if it
reproduces the trajectory and the rival FAILS. (biquad_topology_probe.py extended.)

### P2 RESULT 2026-09-11 — ran the null; it is NON-DISCRIMINATING (constant input)
Captured a clean 6-frame seeded band-0 trajectory (`data/kn5000-dsp-eq-null-trajectory-2026-09-11.txt`):
0x64 (x0) = 0.004419 **constant** every frame; 0x65 settles to 0.004419 = 0x64 **exactly**; 0x66 (y1)
grows quadratically (constant 2nd difference ≈0.0043 — a double pole at DC, the known instability);
0x67 (y2) = 0x66[n−1]/2 exactly. `biquad_null_discriminates.py` shows DF-II canonical and transposed
have identical OUTPUT (topology-invariant) and their shared internal state differs only under a
TRANSIENT input; under the captured CONSTANT input the shared cell degenerates (x1 = x = w-ish), so
**the trajectory cannot tell the forms apart — a criterion that cannot fail.** NO topology call made.
Subtlety worth noting: 0x65 tracking x EXACTLY leans toward it being the delayed input x1 (a DF-I-like
separate history), which is in tension with the store-bit reading (0x65 written by cur 0x02) — and
that tension is itself resolvable only with a transient. **P2 next:** excite 0x64 with a NON-CONSTANT
input (an impulse via a one-shot seed of 0x64, or varying audio) and re-run the null; only a transient
excites the discriminator.

## P3 — M2 cont.: does PARAMETRIC EQ constrain SRC 0x08/0x11? [offline]
PEQ's biquad is bit-exact. If its program uses SRC 0x08/0x11 in a spot whose output is validated,
that constrains those readings the way SINGLE DELAY located ACT 0x0D/0x0E. Grep PEQ for them.

### P3 RESULT 2026-09-11 — technique N/A; codes already partially characterized
Census: SRC 0x08 is used in 22 programs, SRC 0x11 in 33 — but NEITHER known-answer program (SINGLE
DELAY, PARAMETRIC EQ) uses them, so they cannot newly constrain the readings by matching a validated
output. However, prior work already partially decodes both: **SRC 0x08 = put C-RAM[c] (a coefficient)
on the bus** (§224 §S2sq, the coefficient-squaring MACs), **SRC 0x11 = the accb register** (a separate
44-bit accumulator). So P3's specific technique adds nothing new; the codes are not "unanchored" in
the way ACT 0x0D/0x0E are. Net: the input-route residue that matters is ACT 0x0D/0x0E (M2, located as
delay-line mixing), not SRC 0x08/0x11.

## P4 — M5: N4 gain-mapping from the decoded delay [offline]
Read the reverb descriptor block for the per-tap delay length; relate the measured decay ratios
(0xD0 ×0.767, 0xD2/0x8A ×0.547) to the all-pass gains (0.91/0.1367) through that length; test the
C-RAM>>1 factor-of-2 for the 0x8B ×2.024 growth. Falsifier: if no length fits, recensus the taps.

### P4 RESULT 2026-09-11 — the mapping premise was wrong; the reverb tail is already decoded
Prior work (reverb-head-tail.md, reverb-topology-round7.md) already decodes the reverb's decay
structure: early-reflection taps at **6000/12000/18000/24000 samples**, an L/R decorrelation ratio
**1.2006**, and the topology narrowed to the **pipe-comb / series-comb** family (all-pass, parallel
comb, Moorer, nested all-pass, lattice all REJECTED, and rejected in the topology-neutral pool too).
Those long delays live in **external delay-DRAM**, which REVSEED (local D-RAM cells) does not reach —
so my measured local decays (0xD0 ×0.767, 0xD2/0x8A ×0.547) are LOCAL damping/feedback, NOT the
reverb-tail comb gain. My N4 "map the decay ratio to the all-pass gains 0.91/0.1367" framing rested
on a wrong assumption (that the local cells are the tail). Honest net: the reverb is more decoded than
that framing implied; to measure the tail gain one must seed the external delay-DRAM, not the local
cells — and the tail STRUCTURE (comb family, sample delays) is already on record.

## P5 — M6: audible EQ default-off [after P2]
Once P2 fixes the realization: SPEC_DF2 + SPEC_AUDIO (default off), spectral A/B vs peq_ab.py.
Behavioral merge stays review-gated; building+testing default-off is not.

**Order:** P1 now (the instrument for the one open question), then P2 (the null). P3/P4 in parallel
(offline, independent). P5 last. P1 is the linchpin: it converts "unidentified writer" into a
decoded mechanism, and the two nulls follow.
