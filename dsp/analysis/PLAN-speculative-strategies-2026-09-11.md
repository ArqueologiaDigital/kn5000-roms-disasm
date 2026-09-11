# KN5000 effects-DSP — speculation-friendly strategies to push decode → audible LLE

**Mandate (Felipe, 2026-09-11):** *"Write a new plan for additional strategies we can use to
continue improving the decoding and implementation. You can rely on speculation in order to try
to make things fit in place."*

This plan is the deliberate counterpart to `PLAN-the-rest-2026-09-10.md`. That plan was
strict-measured: a code was promoted only on N-clean/0-contradicting bit-exact evidence, and every
remaining item was correctly shown to be gated on evidence that in-session captures cannot supply.
**This plan lifts that gate on purpose.** It permits *speculative* readings — adopt a candidate,
wire it in, and judge it by whether the whole effect then **FITS** (runs trap-free and produces
output that matches the independent HLE reference), rather than by isolated bit-exact proof.

## 0. The one idea that makes speculation safe and productive

We already have a **bit-exact, hardware-rooted oracle**: the HLE reference (`dsp/hle/`), whose
parametric-EQ biquad reproduces the chip's solved transfer function to 0.000 dB, plus the
now-**MEASURED** LLE datapath (multiply `(coef[N-1]×L[N])>>6`, accumulate/load on `hi12[3:1]`,
store `acc>>16`; `run_decode_regression.sh`). So a speculative reading of an *undecoded* code is not
a shot in the dark — it has an **acceptance test**:

> **Adopt the speculative code → run the LLE frame → compare the LLE's per-word acc/P/output against
> the HLE oracle fed the same coefficients and the same input. If they agree, the speculation FITS
> and is promoted "by construction"; if they diverge, the reading is wrong and is discarded.**

This is legitimate validation (the memory rule *fake-with-the-real-mechanism*: route through the
correct datapath, label it, make it drop-in-replaceable, gate it with a spectral A/B). Every
speculative result stays **flag-gated, default-off, and labelled SPECULATIVE** until a measured
anchor or hardware confirms it — plausible-but-wrong is still never shipped as *faithful*, but it
IS allowed to exist as a labelled research path that we iterate against the oracle.

Ordered by leverage (highest first). Each strategy states: the **speculative move**, the **fit
test** that accepts/rejects it, and the **risk/label**.

---

## S1. Wire the input route speculatively, and let the biquad oracle judge it *(highest leverage)*

**Why first.** The input route is the single gate between the decoded datapath and audible LLE.
Everything downstream (reverb, second accumulator) sits behind it. And we have the perfect judge:
the biquad datapath is MEASURED, so if the route is right, the biquad's output on real audio must
match the HLE biquad fed the same input.

**Speculative move.** Adopt the standing speculative readings of the input-stage codes and wire the
route end to end:
- source `SRC 0x11 = accb`, `SRC 0x08 = ?` (try `mem[ptr]` then `acc`);
- action `ACT 0x0E = P←bus`, `ACT 0x0D = acc←bus`, `ACT 0x08 = ?`, `ACT 0x17 = ?` (enumerate the
  small candidate set; the "bus" is the DI-latch datum at acc-scale, `<<16`, which we already
  observed live);
- admit `f31 = 2` (operand-unchanged) on the two port-read words so the latch read executes.
Implement behind `UPD6383_SPEC_INROUTE` (env, default off), in the disassembler's
`alu_decoded_spec()` path so the strict decode is untouched.

**Fit test.** Play a note (RULE-12 `:KEY2`), capture with `-log`, and confirm: (a) `mem[0x64] ≠ 0`
(audio reached band-0 `x0`); (b) the biquad's per-word `acc`/`P` now match the HLE biquad fed the
same captured `x0` and the captured coefficients, word-for-word; (c) the frame runs trap-free. If
(b) holds, the input route is correct *by construction* — the only reading that makes the measured
biquad produce the oracle's output. Enumerate the candidate code assignments and keep the one (if
any) that passes (b); if several pass, report the ambiguity honestly.

**Risk/label.** SPECULATIVE until a measured anchor lands. But note the acceptance test is
strong: an incorrect route almost never reproduces the bit-exact biquad oracle on live audio.

> **S1 EXECUTED (2026-09-11) — audio flows through the measured biquad; output saturates.**
> `UPD6383_SPEC_INJECT` (upd6383.cpp, env, default off) copies the deposited audio (D-RAM 0x01)
> into band-0 `x0` (0x64) at unit-0 entry. Captured a real-note PARAMETRIC-EQ frame: band-0 x0
> now carries the live audio (−0.0797), the biquad's b0 word forms a **non-zero product from it**,
> and the whole EQ pass has **41 non-zero products cascading** — the measured biquad runs on real
> audio for the first time (the plan's core goal). ⚠ BUT the cascade **over-gains and saturates**:
> band 0 turns an 8%-FS input into a **100%-FS (saturated) output**, band 3 into 75%, peak |acc| =
> 3.5×FS. That is the recursion mis-wired — matching the Phase-2 finding that these coefficients are
> Jury-unstable in the assumed `[b1,b0,b2,-a1,-a2]` order. ⇒ **S1 and S4 are COUPLED**: the input
> route is bridged, but faithful EQ output needs the correct `x1/x2` vs `y1/y2` role assignment
> (S4) so the feedback terms are right. Real, honest progress — audio is in the datapath — with the
> remaining faithfulness gap localized to the recursive structure, not the input route.

---

## S2. Close the loop: an HLE-oracle-driven LLE bring-up harness

**Speculative move.** Generalise S1's judge into a standing tool: `lle_vs_hle.py` that, given a
captured frame, runs BOTH (i) the LLE datapath model with the current (measured + speculative)
code table and (ii) the HLE reference wired from the same captured coefficients, and reports the
first word where they diverge. Speculative code assignments are toggles in a table.

**Fit test.** The harness *is* the fit test for every other strategy here — it turns "does this
speculation fit?" into a bit-for-bit diff with a named first-divergence word. Drive S1/S3/S5/S6 by
minimising that divergence.

**Risk/label.** None new — it is an instrument. Commit it beside the probes; it makes every
speculative promotion in this plan reproducible and falsifiable.

---

## S3. Promote the `f31 {4,5,6,7}` accumulator codes speculatively, judged downstream

**Speculative move.** Assign each open `f31` code its best-fit op and let the frame vote:
`f31 = 4 → acc←P` (load-like, seen once); `f31 = 6,7 → ` try {`acc += P<<1`, `acc += P>>k`,
saturating-add}; the anomalous `f31 = 5 → ` try the `≈5/6·P` reading as a **rounded** op
(`acc = (5·P)/6` with the chip's rounding) *and* as a two-word {hold; +⅙P} idiom. Wire each behind
a spec toggle.

**Fit test.** Run S2's harness on the kernel words that carry these codes; accept the assignment
that makes the whole-frame acc trajectory match the HLE reference (or at least stops the frame
trapping there). The `5/6` reading is accepted only if a consistent rounding rule makes it
*bit-exact* across all `f31=5` occurrences — otherwise keep it labelled ANOMALY.

**Risk/label.** SPECULATIVE; the `f31=5` anomaly may be a rounding/pipeline artefact, so prefer the
reading that also explains *why* it looks like 5/6 (e.g. a shift+add that approximates it).

---

## S4. Cross-frame "seed-once" capture to assign the biquad x/y roles (Phase-2 closure)

**Speculative move.** Add `UPD6383_BIQSEED_ONCE` (seed the band-0 state only on the first frame,
then let it evolve). Speculatively assign the state-cell roles `x1,x2,y1,y2` from the read order +
the store cascade already decoded (`b0=0.125` on `x0`, store `acc>>16` → next band).

**Fit test.** Capture ~3 consecutive frames (raise the trace cap, or 3 runs at adjacent arm
frames); observe how each seeded cell's value moves frame-to-frame and match it to the assumed
delay-line shift (`x0→x1`, `y→y1`). Accept the role assignment whose implied transfer function is
(a) **stable** and (b) matches the designed peaking-EQ response for the captured coefficients. The
instability of the WSA1R order is the control: the correct order must be the stable one.

**Risk/label.** SPECULATIVE; the biquad is Jury-unstable in the wrong order, so the first frames
before blow-up carry the signal — read the *first* transition.

> **S4 localized by S1 (2026-09-11).** Tracing band 0 on the injected real audio: the over-gain is
> NOT the input (x0 = 0x64 = −0.08, b0 = 0.125) — it is the **state cells 0x66 = +1.0 (saturated)
> and 0x67 = +0.5**, which the biquad multiplies by ~0.5 coefficients into a huge product
> (547232219436 at cur 04), driving acc to +1.36 FS by the makeup word. So the LLE biquad running the
> chip's microcode on live audio is **unstable in its executed recursion**, while the real chip's EQ
> is stable ⇒ the gap is the **state/recursion writeback**: either the executed cell-role order is
> wrong (0x66/0x67 are being read as the wrong taps) or the LLE does not model the per-frame delay-
> line update (y written back to y1, shift), so the feedback reads runaway values. This is the exact
> thing S4's cross-frame seed-once capture must settle, and it is now pinned to two cells.
>
> **S4 stability-shortcut tried — UNDER-CONSTRAINED (2026-09-11).** The speculation-friendly hope was
> to pick the cell-role order by "which assignment is stable + sensible EQ", using the captured
> band-0 coefficients (b0=0.125 fixed on x0; the other five permuted into b1,b2,a1,a2,makeup, each
> recursive term tried ±). Result: **336 assignments pass** — the stability+gain criterion does not
> fail enough to decode the order (a criterion that cannot fail is not a decode). So the order cannot
> be speculated from stability alone. The real determinant is the **state WRITEBACK** (which cell
> receives the computed y each frame): an unstable writeback — not a coefficient mislabel — is what
> made S1 saturate, and 336 stable *interpretations* exist regardless. ⇒ S4 needs a genuinely
> constraining input: EITHER the cross-frame seed-once capture (observe which cell y lands in and how
> the taps shift), OR the firmware EQ designer's intended (f0, gain, Q) for this band from the
> parameter record (design the target biquad, match the one order that reproduces it). Both are
> reachable; neither is the stability shortcut.
>
> **S4 SIGN DECODED (2026-09-11) — the feedback must SUBTRACT.** The stability search was
> under-constrained across *permutations*, but fixing the natural order `[b1,b0,b2,-a1,-a2,makeup]`
> (b0=0.125 at cur01, confirmed) and testing only the FEEDBACK SIGN is decisive. The recursive
> coefficients are stored **positive** (cur03=+0.498, cur04=+0.504, sign bit 0). ADD them (the
> summary's "pre-negated → += MAC" convention): denominator `1 − 0.498z⁻¹ − 0.504z⁻²`, **pole 1.001,
> UNSTABLE** — precisely S1's saturation. SUBTRACT them (stored = the true a1,a2): denominator
> `1 + 0.498z⁻¹ + 0.504z⁻²`, **poles 0.710, STABLE**, with sensible bounded gain. ⇒ the KN5000 EQ
> biquad is stable ONLY with **subtractive feedback**; the "+=, pre-negated" convention (in the
> session summary and docs §9) is WRONG for the KN5000. The concrete LLE fix: the recursive MACs
> must subtract (or the y-state cell is stored negated). Wiring that should turn S1's saturating
> cascade into a faithful EQ — the next build-lane step, and it also corrects effects-dsp §9.
> ⚠ Still speculative on the *mechanism* (subtractive MAC vs negated y-store); the SIGN is forced by
> stability. This is the "make it fit" result the mandate asked for: the one sign that makes the
> captured coefficients a real filter.
>
> **S4 MECHANISM COMPLETE + full cascade validated (2026-09-11).** (a) The full 5-band cascade with
> subtractive feedback is STABLE (IR tail 4.5e-13) and a coherent peaking EQ — the decoded KN5000
> parametric EQ is a real filter, all 5 bands (poles 0.710–0.752). cur05 ("makeup") is [0.5, 0.001,
> 0.375, 0.0001, 0.0] ⇒ a **band-ENABLE** (bands 1/3/4 off in this preset). (b) The recursive words
> cur03(-a1)/cur04(-a2) use **f31=1 (ADD)**, not a subtract op — verified. So the only way the chip
> gets the required subtractive feedback with an adding MAC is a **NEGATED y-state**: the biquad
> stores −y, and coef·(−y) added = −coef·y. **The exact LLE fix is therefore: negate the
> recursive-feedback operands** (the cells read by the -a1/-a2 words, 0x66/0x67 per band) — or
> equivalently negate the y-state writeback. Reproduced by `biquad_stability_probe.py`. This closes
> the S4 ANALYSIS (sign + mechanism + exact fix, offline-validated); the remaining step is the
> engineering wiring of that negation into the core, then re-run S1 for faithful non-saturating LLE
> EQ (S6). ⚠ Still speculative that 0x66/0x67 are the y-state vs x-state (the 336-order ambiguity),
> but the fix is sign-forced: whichever cells the recursive words read must enter negated for the
> captured coefficients to be the stable filter they provably are.
>
> **EXACT LLE WIRING SPEC (for the next reviewed core edit).** In `exec_alu` (upd6383.cpp), the
> multiply operand is latched at `m_l = u32(L) & 0xffffff` (~line 4975). The fix, behind a new
> env flag `UPD6383_SPEC_SUBFB` (default off, speculative): when the operand's source cell is a
> **y-state cell** — band_input+2/+3, i.e. the set {0x66,0x67, 0x6A,0x6B, 0x6E,0x6F, 0x72,0x73,
> 0x76,0x77} — negate `L` before the multiply (equivalently negate the product for the recursive
> -a1/-a2 words). ⚠ Two review hazards: (1) the source cell here is `m_dp`, which is POST-incremented
> inside exec_alu (the pre/post-increment trap, memory `kn5000-dsp-handoff-next`) — read the operand
> address BEFORE the increment; (2) confirm the y-state set against a real capture (the 336-order
> ambiguity) — the empirical accept test is that S1 (`UPD6383_SPEC_INJECT`) + SUBFB stops saturating
> and renders a stable EQ matching `biquad_stability_probe.py`'s peaking response. This is a careful
> reviewed core edit, not an end-of-session rush; the analysis behind it (sign, mechanism, stable-
> filter proof) is complete and committed.
>
> ⛔ **S4 WIRING TESTED — "negate the operands" is the WRONG FIX (2026-09-11).** Implemented
> `UPD6383_SPEC_SUBFB` (negate the operand read from in+2/in+3) and ran the accept test with a
> multiply-site instrument. RESULT: the negation reached the multiply exactly as coded (iw147 −a1
> consumed L=+8388608 = −(−8388608), the negation of an exact −1.0 rail), yet the cascade still
> saturates (band 1 in = −0.99996). ROOT CAUSE, measured: the cells the −a1/−a2 words read
> (in+2/in+3 = 0x66/0x67 per band) are **never written by ANY store word in the whole frame** and
> are **constant/stuck** across it (distinct=1 on every one). There is no functioning recursion to
> stabilize — the negation just flipped a dead rail. The only EQ-block stores target **in+1**
> (0x65,0x69,0x6D,0x71,0x75). ⇒ the true S4 gap is the **delay-line STATE UPDATE / cell mapping**,
> not the feedback sign. The sign result (subtractive ⇒ stable) stands for the TRUE filter; the LLE
> cannot realize it until its recursive reads hit live, per-frame-updated y-history.
> **New lead:** the frame's store targets fall in TWO parallel stride-4 blocks — `0x51,0x55,0x59,
> 0x5D,0x61` (a 0x50 block) AND `0x65…0x75` (the 0x64 block). The biquad reads only the 0x64 block;
> the 0x50 block is written and never read by the recursive words. Candidate: the live y-history
> lives in the 0x50 block and the −a1/−a2 reads are aimed at the wrong block (a pointer-mapping
> gap), which would explain the stuck 0x66/0x67 exactly. Under investigation.
> **→ REFUTED (same day).** The 0x50 block is the **STEREO TWIN**: a second, parallel 5-band × 4-cell
> cascade (cursor 0x54–0x72) that is read AND stored — every value 0.0, because only the 0x64
> channel is injected. It is not the y-history. But it confirms the structure twice over: in BOTH
> channels only `in+1` is ever stored and `in+2/in+3` are read but never written. ⇒ for a working
> IIR the chip must **rotate/shift the history each frame** (y→y1→y2 — a circular pointer or an
> explicit shift); the LLE's per-frame pointer is FIXED at 0x64+4k and it performs no shift, so the
> recursion is dead by construction. **This is the true S4 gap — the delay-line shift — and it is
> directly testable:** `UPD6383_SPEC_SHIFT` (upd6383.cpp, env, default off) rotates each band's
> history at unit-0 entry (in+3←in+2, in+2←in+1) so the −a1/−a2 reads hit LIVE y1/y2. Accept test:
> does the cascade stop railing? If it stabilizes, the feedback-sign question is then settled
> empirically on a live recursion (SHIFT alone vs SHIFT+SUBFB) rather than on a dead one.

---

## S5. Adopt the delay-pipeline (§74/76/78) model and make the reverb ring

**Speculative move.** Turn on the core's own speculative delay-pipeline (mask bits 19/20: the delay
WRITE word is the read consumer; one-deep per-line pipeline) and adopt `SRC 0x1A = tempB ←
delay-read`, with the class-8 path applying the `0.91/0.1367` gains (try: the delay WRITE scales the
stored value by the feedback gain; the read applies the feedforward gain).

**Fit test.** Seed the delay line (`UPD6383_DLYSEED`, AS_DELAY space) with an impulse and check the
reverb output is a **decaying echo train** whose decay rate matches `0.91` per loop and whose
spectrum matches the HLE all-pass ladder reference (spectral A/B). The core's §73 control applies:
the loop behaviour MUST change when the gains change — if it does, the feedback is finally wired.

**Risk/label.** SPECULATIVE and the most intricate; the payoff is the first audible reverb tail.
Keep the §73 falsifier (gain-sensitivity) as the accept/reject gate.

---

## S6. Speaker-audible LLE behind a labelled flag (Phase-6, speculative build)

**Speculative move.** With S1 (+ S5) in place, route the LLE frame's output to the mix behind
`UPD6383_SPEC_AUDIO` (env, default off), replacing the "discard every frame" gate with "play the
frame if it ran trap-free under the speculative table."

**Fit test.** Spectral A/B the speculative-LLE speaker output against the HLE reference render for
the same effect + parameters (`render_eq_from_capture.py` / the HLE showcase). Ship it **only** as
the labelled `SPEC_AUDIO` path — never the default, never called "faithful". A match promotes the
whole speculative table from "fits the oracle internally" to "fits audibly"; a mismatch localises
which stage is still wrong.

**Risk/label.** SPECULATIVE audio, clearly labelled, default-off, drop-in-replaceable, and always
presented next to the HLE reference so no one mistakes it for measured-faithful. This honours the
standing rule (never ship plausible-but-wrong as faithful) while still delivering audible progress.

---

## S7. Cross-check speculative readings against the SX-WSA1R twin

**Speculative move.** The WSA1R runs the same uPD6383 core with the same kernel; its PEQ is the same
biquad (validated by construction). Where a KN5000 code is ambiguous, adopt the reading that is
*consistent across both products* — a speculative reading that only works on one is suspect.

**Fit test.** Run S2's harness on captured WSA1R frames with the same code table; a reading is
strengthened if it fits both, weakened if it needs per-product special-casing.

**Risk/label.** SPECULATIVE corroboration, not proof; a cheap consistency filter on S1/S3/S5.

---

## S8. Feed everything back into the disassembler's speculative tier

**Speculative move.** Each reading that passes its fit test graduates from OPEN into
`alu_decoded_spec()` / `_ANCHORED_*_SPEC` with a one-line provenance ("fits the HLE oracle on
frame X, S1"), lifting the speculative decode-coverage number and, more importantly, making the
next capture *interpretable*.

**Fit test.** `ceiling_partition.py` re-run: speculative coverage should climb as codes graduate;
the strict tier stays untouched (the honest floor).

**Risk/label.** Bookkeeping; keep the strict vs speculative columns strictly separated so the
honest measured coverage is never inflated.

---

## Guardrails (unchanged, and they make speculation safe)

1. **Two tiers, never merged.** Strict-measured stays the honest floor; everything here lands in the
   SPECULATIVE tier with provenance. `run_decode_regression.sh` remains the measured-only truth.
2. **Every speculative reading is falsifiable via S2** (the HLE-oracle diff) and is discarded the
   moment it diverges — speculation that *cannot* fail is not adopted.
3. **Speculative audio is labelled, default-off, and always shown beside the HLE reference.** We are
   allowed to be wrong here; we are not allowed to *claim* we are right.
4. **Hardware questions stay parked** (`notes/HARDWARE-QUESTIONS-PENDING-FELIPE.md`): POSITION scale,
   IC4 ROMs, and any reading only Felipe's hardware can settle are flagged for him, not guessed into
   the measured tier.

**Recommended order:** S2 (build the judge) → S1 (input route) → S4 (biquad roles) → S3 (f31) →
S5 (reverb) → S6 (audible) → S7/S8 (corroborate + record). S1 alone, if its fit test passes, is the
breakthrough: real audio through the measured biquad, judged bit-for-bit by the oracle.
