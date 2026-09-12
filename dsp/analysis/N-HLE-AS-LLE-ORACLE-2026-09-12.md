# Using the HLE reconstructions as an LLE oracle — state, a near-term decode, and flags (2026-09-12)

The HLE reconstructions of every effect program now exist (audible in MAME; permanently archived on
the docs site at `/effects-dsp/impl/`). Felipe's directive: use them to push the **LLE** (the
bit-exact `upd6383` device) forward — compare HLE ↔ the partial LLE and fill decoding gaps.
⚠ **The bytecode is the source of truth; the HLE may contain mistakes.** This note grades every
claim MEASURED / STRONG / SPECULATIVE and does not present an inference as a closure.

## 0. What the HLE decisively settles about the "4.2 audio gate"

The input stage is the 12-word `K6_INPUT_STAGE` (`dsp/tools/dsp_disasm.py:547`). The open codes that
make the strict decoder trap it are exactly **SRC {0x08, 0x11}, ACT {0x08, 0x0D, 0x0E, 0x17},
f31=2** (`input_route_guards.py`; `DSP-DATAPATH-DECODE-HANDOFF-2026-09-11.md §2`). The HLE fixes the
**end-to-end requirement** of this stage, which re-frames the whole problem:

- w4/w8 are the audio **PORT READS** (`dsp_disasm.py:552,556`; mem[X+2]/[X+5], read-never-written,
  = cells 0x01/0x04 under X=0xFF, MEASURED 97.58% `output-stage-decode.md §3.5`).
- w9 (strict-decoded) **stores `acc` to X+6 = cell 0x05 = the unit-0 SEND/entry cell** the body reads
  (`output-stage-decode.md §3.5/§4`, E0=0x05 MEASURED).
- So the stage's whole job is: read the latches → **accumulate `coef × audio` into `acc` (w5/w10,
  class-A, f31=1)** → w9 stores `acc` to the send. The multiply `(coef×L)>>6` and the accumulate
  `acc += P` are **MEASURED** (`DSP-DATAPATH-DECODE-HANDOFF §1`).

**⇒ The audio-carrying arithmetic is ALREADY decoded.** The open codes govern only (a) secondary
ACTION side-effects and (b) a bus-operand selector that is otherwise unused on these words. Anchoring
them is about the *correctness of the skip*, not discovering new arithmetic — a materially smaller
problem than "the route is undecoded." (STRONG, from the verified word map + the MEASURED datapath.)

## 1. Near-term decode the HLE supplies: f31=2 = acc-HOLD on the class-2 port reads (STRONG)

`f31=2` blocks three class-2 words: the two audio PORT READS (w4, w8) and the one-frame feedback read
(w2). In the adder, `f31=2` gives `acc + 0` = **acc unchanged** (`acc-adder.md:131`), decoded and
admitted **on class 8**; `acc-adder.md §6` explicitly **refused to generalize it off class 8** because
nothing constrained the choice between its two survivors, **`hold`** and **`AND 0x7FFFFF`** (the
coefficient-AND reading was separately FALSIFIED by the biquad, `acc-adder.md:269`).

**The HLE input-stage semantics supply the missing constraint.** A port read must latch the audio
operand into the pipeline **without disturbing the accumulator `acc` being built across w5/w10** —
otherwise the accumulated `coef×audio` that w9 stores to the send is corrupted, and the body receives
the wrong input (contradicting the MEASURED route above). "Do not disturb `acc`" **is** the `hold`
survivor; the other survivor (`AND 0x7FFFFF`) is the LFO phase-wrap behaviour and has no meaning on a
port read. **⇒ f31=2 on the class-2 port reads reads as `acc-hold`.**

- **Grade: STRONG / CONSISTENT, an inference — not a measured closure.** It is the first constraint to
  distinguish the two survivors off class 8; it rests on the MEASURED route requirement, not on a new
  trace. The build-lane should confirm it (a device arm that reads `acc` across w2/w4/w8 and checks it
  is unchanged) before it is promoted to MEASURED. This is the single best near-term win the HLE
  offers on the gate.

## 2. Weaker eliminations the HLE provides (SPECULATIVE)

- On w5/w10 (class-A, building the accumulate), **`ACT 0x08` and `ACT 0x17` cannot be aliases of
  `ACT 0x00` (`acc←bus`)**: that would set the adder's A-input to `src[accb]` and inject accb instead
  of accumulating the audio, breaking the MEASURED route. Eliminates the "0x00-alias" reading for
  these two codes. (SPECULATIVE — strict only if accb≠0 at those sites.)
- The reverb energy-flow HLE eliminates **30 of 36** `0x0D×0x0E` combinations in favour of
  **`ACT 0x0E = mem[ptr] ← bus`** (`three-codes.md B/C`, `SPECULATIVE-reverb-run.md §2`). STRONG as a
  lead, unreconciled with §4b below.

## 3. ⚠ Committed-doc disagreements to reconcile (flagged, not resolved here)

1. **`ACT 0x0E` has THREE incompatible committed readings:** `mem[ptr] ← bus` (`three-codes.md`,
   `SPECULATIVE-reverb-run.md §2`, most corroboration) vs `acc → bus` (`DSP-TOPOLOGY-INSTRUCTION-
   INSIGHT-2026-09-11.md`) vs **`P ← bus`** (`DSP-DATAPATH-DECODE-HANDOFF §4b`, the **newest**, a live
   REVSEED sighting of `P = seed<<16`). The newest live observation contradicts the most-corroborated
   distributional reading. **Unresolved — must be settled from the bit-encoding before `ACT 0x0E` is
   called decoded.**
2. **`ACT 0x0D/0x0E` labelling:** `TOPOLOGY-vs-ALGORITHMS.md` / `EFFECT-ALGORITHMS-implementation-
   spec.md` still call it the "biquad z⁻¹ pair"; `DSP-TOPOLOGY-INSTRUCTION-INSIGHT-2026-09-11.md`
   corrects it to a **universal** state-I/O mixing op (the true 2nd-order-section state is ACT
   0x12/13/14). The older docs carry the superseded label.
3. **`SRC 0x08`:** `lfo-ramp.md` ("unity multiplicand, class-A") and the topology note
   ("LFO/modulation source") are compatible (same class-A sites) but read as separate findings, and
   both silently exclude the one class-2 instance (input-stage w0).

## 4. The honest structural boundary — `SRC 0x11` (=accb) is NOT an HLE problem

accb is the top open code (`HANDOFF-NEXT.md §1`, +49). Its decode is caught in a **documented
dependency cycle** (`DSP-DATAPATH-DECODE-HANDOFF §4.1`): anchoring it needs a *varying* non-zero accb
to match the operand against, but every reachable program feeds accb the frame-invariant kernel-B
constant, and the only program that would vary it is the blocked reverb input route. A speculative-ISA
capture (DSPVAL=3) confirmed unit-1 stays frozen even under permissive execution. **The HLE does not
model the chip's second accumulator, so it cannot crack accb** — this needs the true bit-encoding or
hardware, not an HLE insight. The HLE has taken it as far as stating precisely what the route must
produce (§0).

## 5. The inverse direction worked this session: the bytecode corrected the HLE

Comparing the HLE against the bytecode (source of truth) found + fixed a real **HLE** gap: SINGLE
DELAY (prog09) PROVES an in-loop damping filter at **C-RAM 0x03..0x05** ("damping filter tap 0/1/2",
role damping PROVEN) that the HLE delay omitted. Added a one-pole low-pass on the fed-back tap (coeff
from cell 0x03); A/B vs the pre-change binary (PCM pluck) = every echo ~35% less high-band energy
(hi_frac echo1 0.0042→0.0028, echo3 0.0028→0.0017) at unchanged level (kn7000_mame 6aee24e). This
also **cross-confirms the bytecode's PROVEN damping-role decode is audibly correct** — a small but
real agreement between the two sides.

## 6. Next levers (in dependency order)
1. Build-lane: confirm **f31=2 = acc-hold** on w2/w4/w8 (device arm reading `acc` across them). If it
   holds, f31=2 generalizes off class 8 and the two port reads + the feedback read stop trapping.
2. Reconcile **ACT 0x0E** (§3.1) from the bit-encoding — it is the blocker that three docs disagree on.
3. ✅ **DONE this session:** `dsp/hle/lle_oracle_delay.py` composes the primitive oracles
   (`DelayOracle` + `OnePoleOracle`) into the whole SINGLE-DELAY signal flow (tap → in-loop HIGH
   DAMP → feedback fold → dry/wet mix), with a selftest proving the echo structure (impulse → peaks
   at N/2N/3N decaying; damped 2nd echo < undamped). It prints exactly what a seeded **DLYSEED**
   trace must reproduce per frame (read address, damp, the mixing fold, write, mix) — so the delay's
   remaining open words (the ACT 0x0D/0x0E mixing order, the SRC 0x00 read address) become
   constraint-solving targets, as `lle_trace_diff.py` + BIQSEED did for the biquad. ⚠ Needs the
   build-lane to add DLYSEED and produce the trace; the oracle is the ready target.
4. `SRC 0x11`/accb and the rest of the routing guard remain hardware/bit-encoding items (§4).
