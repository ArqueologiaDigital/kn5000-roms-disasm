# PLAN — tackling the rest of the KN5000/WSA1R DSP + acoustic work (2026-09-10)

Produced by a research workflow (`plan-the-rest`, run wf_f4bf7a3d-9da): five read-only agents
each grounded a mini-plan for one remaining area in the committed artefacts, then a synthesis
agent merged them. Supersedes the "Next steps" list in MAME-SYNTHESIS-ARCHITECTURE-2026-09-10.md.

★ KEY CORRECTION surfaced by the research (verify + record via Phase 1.2): the EQ biquad LOAD +
4 MACs + BOTH y-writeback stores (hi12=0x212) are ALREADY strict-decoded and FIRING — they write
0 only because the accumulator is 0, and the accumulator is 0 solely because nothing copies the
audio latch (D-RAM 0x05) into the biquad x0 cell (0x64). So the output-stage "store" is NOT the
blocker; the single load-bearing unknown is the 0x05->0x64 input route (Phase 4).

Research areas: DSP LLE output stage → faithful EQ audio through the upd6383 core (pla; Decode the remaining uPD6383 ISA fields to raise executable coverage t; Extend the live-trace LLE decode from the biquad to the other three uP; SX-WSA1R L7A1429 acoustic-modelling chip: remaining non-hardware work ; Wire the validated effects-HLE (Python dsp/hle/) into the MAME KN5000 

---

# Master Plan — Technics KN5000 / WSA1R DSP + Acoustic Preservation

## ★ EXECUTION STATUS (2026-09-11)

- **Phase 1 — COMPLETE (all zero-build).** 1.1 comparator `--eq-trace` retarget ✓ (`fce…`→committed);
  1.2 stores-fire correction ✓ (MEASURED); 1.4 honest ceiling ✓ (`ceiling_partition.py`: open frontier
  = 315 words / 10.3%, not the folklore 93.3%); 1.5 oracle confrontations for one-pole/LFO/delay ✓
  (all selftests green); 1.6 standalone C++ HLE reference + golden A/B ✓ (0.000000 dB vs Python).
  **1.3 REFUTED on verification** — SRC 0x00 is 1-of-N "applied but untested", NOT strict; not promoted.
- **Phase 3 — partial.** 3.2 drop the ad-hoc detune ✓; 3.3 decoded-FITTING excitation ✓ (both verified
  in `wsa1r`: rings 436 Hz, decays). 3.4/3.5/3.6 remain (SESSION, incremental fidelity + docs).
- **Phase 2 — BLOCKED on execution** (see the box below): the KN5000 EQ coefficient order/topology is
  undecoded (WSA1R order is unstable on KN5000), so a faithful in-MAME render needs a decode first
  (new prereq 2.0, via Phase 4). Scaffolding reverted; offline `render_eq_from_capture.py` stays the
  honest audible answer.
- **Phases 4–6 — MULTI-SESSION / build-lane** (input-route decode → live decode → speaker-audible LLE),
  as tagged. **Boundary — HARDWARE** (POSITION scale, IC4 ROMs) unchanged.
- Two plan premises (1.3, 2.3) were caught wrong by verifying against source before executing — the
  grade-by-provenance / never-rig discipline working as intended.

## Ordering rationale

The flagship value is **faithful DSP audio + advancing the LLE decode**, and the project's hard discipline is *never rig audio, grade by provenance, commit the artefact in the same session*. Those two facts fix the order:

1. **Certain, zero-build wins first.** The bit-exact biquad and the already-*decided* routing codes (§233/§234) are the surest assets in the whole program. Turning them into validators, coverage truth, and a C++ reference kernel costs no emulator build and de-risks everything downstream.
2. **Ship the achievable audio next.** The proven-offline HLE biquad, rendered in MAME as a labelled reference path, *is* the deliverable flagship and — critically — it removes all pressure to rig the parked LLE. It must exist before the decode grind, not after.
3. **The input-route frontier is load-bearing but uncertain**, build-lane, and reviewed (device-core), so it sits below the certain wins even though everything live depends on it.
4. **Live-signal decode is downstream of the route**; coverage climbs SPECULATIVE→MEASURED only once signal reaches the words.
5. **Speaker-audible LLE (whole-frame clean gate) is honestly multi-session** and last.
6. The **L7A1429 acoustic track is independent** (different chip, no shared code) and can run in parallel throughout.

One operational blocker is shared by every build-lane capture and is stated once below rather than repeated per task.

---

## Phase 1 — Zero-build foundation: validators, coverage truth, C++ reference kernel
*All SESSION, read-only / pure-Python, no emulator. Highest certainty × leverage; every later phase leans on these.*

- **1.1 Retarget the LLE comparator to KN5000 EQ geometry.** — Extend `dsp/hle/lle_trace_diff.py` with `--base 0x00`, a 6-cells/band KN5000 section map, `--cram-from-trace` (seed the oracle from the trace's own C-RAM dump, not the WSA1R capture), and per-band prints of the resolved D-RAM operand cell + non-zero flags for acc/P; keep the WSA1R selftest path intact as regression control; run on the committed trace, commit tool+output as the (blind) baseline. — *S* — [SESSION]
- **1.2 Correct the record: the stores already fire.** — In the analysis note, document with the field-decode evidence (`upd6383d.h:682`, the seven live band-0 words) that the biquad LOAD + 4 MACs + **both** stores are strict-decoded and executing, and that state stays 0 *solely* for lack of x0 at 0x64; fix any text implying the stores don't fire outside the K6 twelve. Grade MEASURED, cite trace line numbers, commit same session. — *S* — [SESSION]
- **1.3 ~~Reflect SRC 0x00 = mem[ptr] into strict coverage.~~ ⚠ REFUTED ON VERIFICATION (2026-09-10) — DO NOT EXECUTE.** The research over-claimed §233 as "deciding" SRC 0x00. The actual provenance grading is the opposite: `SPECULATIVE-APPLIED-REGISTER.md` grades SRC 0x00 = mem[ptr] as **1-of-6/1-of-7 enumerated, "applied but untested"** (row 20 / lines 499, 888; only SRC 0x08 is MEASURED). §233 refuted ONE rival (the null-MAC), which is not the same as measuring mem[ptr]. `dsp_disasm.py` already correctly keeps `LO_SRC_MEM0` in `_ANCHORED_SRC_SPEC` (speculative), not `_ANCHORED_SRC` (strict), and `coverage_report.py`'s "0x00 … still a guess" is CORRECT. Promoting it to strict would be an over-eager provenance violation and inflate the strict number by ~+348 words on an untested reading. **Per the project discipline (grade by provenance), SRC 0x00 stays SPECULATIVE.** No code change; this refutation is the deliverable.
- **1.4 Re-derive the true ceiling from current tools.** — One-shot script partitioning all 3057 words into strict-decodable / speculatively-decodable / permanently-dark-and-why (DSP2-misparsed streams {79,88,89,90,91} → MN19413 not this chip; data-framed-as-code misframes; open-source-field C-format immediates). Retires the unanchored "~93.3%" folklore; commit beside the numbers. — *S* — [SESSION]
- **1.5 Extend the oracle confrontation suite.** — Add `diff_onepole` (ACT 0x0D/0x0E load-then-accumulate; decide {1-d,d} two-coeff vs coeff+subtract from the two cursor coeffs; pin the y1 cell via dp), `diff_lfo` (cross-frame phase +=114, wrap at 2²³) to `lle_trace_diff.py`, and a `DelayOracle` (ring-buffer address model: read returns input written N samples earlier) + `diff_delay` to `lle_oracle.py`/`test_lle_oracle.py`, each with accept-faithful / reject-corrupted selftests mirroring `diff_section --selftest`. Commit. — *S* — [SESSION]
- **1.6 Port the HLE kernels to a standalone C++ TU + offline golden A/B.** — Write `upd6383_hle.h/.cpp` (BiquadDF1, OnePole, LFO, DelayLine, waveshape; `double` precision to match Python float64; **no** include of / dependency on the execution core; header states "HLE REFERENCE, not LLE") plus a harness running BiquadDF1 over the committed captures and comparing magnitude response to `render_eq_from_capture.py` to ~0.000 dB. Anchors fidelity to committed evidence without a full build or the finicky live capture; commit harness + golden values. — *M* — [SESSION]

---

## Phase 2 — Ship the achievable flagship: HLE-reference EQ audio inside MAME
*The proven-offline biquad made audible as a default-off, A/B-selectable research path that never disturbs the parked LLE. High certainty, high leverage; this is the shippable audio answer while the decode grinds. Reviewed / build-lane for landing.*

> ⚠ **BLOCKED ON A DECODE, discovered on execution (2026-09-11).** 2.3 assumed the KN5000 EQ
> coefficients can be run through the biquad in the WSA1R decode order `[b1,b0,b2,-a1,-a2,makeup]`.
> They CANNOT: on the live KN5000 EQ band-0 coefficients that order is Jury-UNSTABLE (a1=-0.498,
> a2=-0.504, |a1| > 1+a2) with H(DC) = -476 -- an absurd/unstable biquad -- and several bands'
> cell-5 "makeup" is ~0.001/0.0001 (role uncertain, not a plain output gain). So the WSA1R
> coefficient order/topology does NOT transfer to the KN5000 EQ, and a naive cascade would be
> plausible-but-wrong (or unstable) audio -- forbidden. **Phase 2 is therefore gated on a NEW
> prerequisite: decode the KN5000 EQ coefficient ORDER + band-combination topology (cell-5 role;
> cascade vs parallel).** Until then the faithful audible answer stays the offline
> `render_eq_from_capture.py` (Phase A), which is honest about exactly this (per-section, no
> flat-EQ claim). The 2.1/2.2 scaffolding was reverted rather than ship a gate for an unfaithful
> render. New prerequisite task **2.0**: capture a KN5000 EQ frame with signal (Phase 4) and use
> the oracle to solve the coefficient order from the biquad's known DF-I transfer function.
>
> **2.0 PARTIAL (2026-09-11) — the C-RAM coefficient→cell LAYOUT is now READ, not assumed.** With the
> biquad datapath decoded (operand `L = mem[dp]`), `dsp/tools/eq_coef_layout_probe.py` reads the
> actual per-band coefficient→operand-cell order from the SEED8 trace: each band is
> `[prev-band cell (~0.75), INPUT/x0 (0.125), input+1 (~0.12), input+2 (~0.48), input+3 (~0.53), …]`,
> storing `acc>>16` to the next band's input. **b0 = 0.125 on the input cell in ALL 5 bands** (the PEQ
> signature — confirms the input cell 0x64+4k is x0). This is NOT the assumed WSA1R order
> `[b1,b0,b2,-a1,-a2,makeup]`, which is exactly why that order was Jury-unstable here. So the ADDRESSING
> half of the coefficient order is decoded and ungated. ⚠ STILL GATED: which state cell is x1/x2 vs
> y1/y2 — hence the exact transfer function and its stability — needs the cross-frame DELAY-LINE
> update (real signal flow through the band), i.e. the SAME input-route gate as 4.2/5.x. So Phase 2
> converges on the identical bit-encoding/hardware frontier: its addressing is solved, its recursive
> role-assignment is not, for the same reason everything downstream isn't.
- **2.1 Add a read-only `cram_peek` accessor to the upd6383 core.** — `u32 cram_peek(u8) const { return m_cram.read_dword(addr)&0xffffff; }` next to `cram_data_w`; the ONLY core touch, read-only (does not alter `m_cursor`/`execute_run`/`run_frame`, so the LLE path is byte-identical). HLE treats an all-zero EQ region as "no coefficients yet" → passthrough, never invents. Consume the firmware-streamed coefficients; do not re-derive host-side. — *S* — [SESSION] *(reviewed core edit)*
- **2.2 Make DSPCFG a genuine 3-way A/B gate.** — Widen the port mask `0x03→0x07` (`kn5000.cpp:886-895`), add `PORT_CONFSETTING 0x05 = "On + HLE reference EQ (research; the HLE, NOT the LLE)"` (bit0 arms send/return, bit2 selects HLE over `run_frame`); default stays Off. Off = silence, 0x01/0x03 = LLE (silent today), 0x05 = HLE. — *S* — [SESSION] *(reviewed)*
- **2.3 Wire the HLE EQ render into the tonegen insert.** — At the `lrck_edge` block, when the HLE bit is set run the ported cascade over `cram_peek(0x00..0x1D)` (6 cells/band ×5 bands, passthrough if all-zero) with per-channel biquad state kept across LRCK edges; return `wet = eq(dry) − dry` so `mix+wet == eq(mix)` (series filter, not additive insert — sidesteps the double-signal and the unknown per-voice send levels G-2/G-3). Read the gate once per update; prove inert when off. Grade as whole-mix EQ, not per-part. — *M* — [MULTI-SESSION] *(reviewed audio-path edit)*
- **2.4 In-emulator 3-way A/B + spectral capture.** — Rig playing the RULE-12 melody zone `:KEY2 C4..B4`, PARAMETRIC EQ, compare spectra Off / LLE / HLE, confirm the HLE curve matches the Phase-1.6 offline golden; commit rig + spectra. — *L* — [MULTI-SESSION] *(build-lane)*

---

## Phase 3 — L7A1429 acoustic-modelling HLE fidelity (independent chip)
*Behind `WSA1_ENABLE_ACOUSTIC_HLE` (default off). No dependency on the DSP track — can run in parallel throughout. Success = "the documented coupled-resonator model realized as faithfully as the ROMs allow, every stand-in switch-guarded and graded," never "the chip's real audio."*

- **3.1 Drive the HLE from real firmware note events.** — Rig playing a note via `-midiin one_note.mid` (or `keybed_push`), capture WAV under the flag, confirm the voice excites through the natural `Dev104_WriteAllChanRegs` writes (0x0040 **and** 0x0080 now carry real values). This is the validator for every later step; commit rig + `wav_rms` check. End-to-end MIDI-IN acoustic capture is UNTESTED — grade the acoustic leg accordingly. — *M* — [MULTI-SESSION] *(build-lane)*
- **3.2 Remove the ad-hoc INTERACTION-GAIN detune (correctness).** — Delete the `f_sub *= 2^(-kappa*0.03)` nudge in `excite_voice`; rely solely on decoded MAIN/SUB TUNE, which the firmware's `sub_FC4269` solver already detuned. Validate on the 3.1 real-note path (the poke rig hides coupling because 0x0080 is static there). — *S* — [SESSION]
- **3.3 Source excitation shaping from decoded FITTING.** — Replace the arbitrary rise/decay constants with the FITTING rise (0x01C0/0x0200) and decay (0x0140/0x0180) Q15 values through the PROVEN Exp2Rise/Exp2Decay shapes; use `sub_fitting` for the SUB waveguide; expose the 40.69 Hz / 24.576 ms refresh as ONE named constant. Grade the absolute-time mapping [INFERENCE] (refresh measured only for the 0x00C0/0x0100/0x0240 trio, not FITTING). — *M* — [SESSION]
- **3.4 Port the spectral self-validation harness into the MAME path.** — POSITION pickup-comb null migration (timbre moves, pitch doesn't) + MUTING brightness → HF energy, each with a falsifiable pass criterion (compute a null / no-stimulus window). Regression guard for 3.3 and 3.5. — *M* — [SESSION]
- **3.5 Model POSITION MOVEMENT as relative pickup-tap modulation.** — Drive the tap from the `2^(v/3072)` *ratio* of 0x00C0/0x0240 at the 40.69 Hz refresh (`p17*sine/50`). Grade STRONG-mechanism / hardware-gated-calibration: only relative movement is faithful; the absolute depth stays a stand-in (see Boundary). — *M* — [SESSION]
- **3.6 Consolidate + keep the four artefacts in lockstep.** — Update `HLE-GUIDE-l7a1429.md`, the docs page and the note with graded results; run `l7a1429_crosscheck.py` (17 mutation controls) on any register name/count change. Commit every rig/probe/WAV-check same session. — *S* — [SESSION]

---

## Phase 4 — The master unblocker: route input into the biquad state cells
*The single evidence-based decode that unlocks all live-signal LLE work. Genuinely uncertain (could falsify the 0x64=x0 reading), build-lane, and reviewed — hence below the certain wins despite its leverage. Depends on Phase 1.1 (comparator) for validation.*

> **4.1 PROGRESS (2026-09-11).** Censused the committed EQ trace: the input signal is present but
> tiny at D-RAM **0x04 = +0.0051**, while every biquad state cell 0x64..0x77 reads **0** — and NO
> DECODED (traced) word bridges 0x04/0x05 → 0x64. So the bridge is an **undecoded input-stage word**
> (absent from the executed-word trace by construction), confirming 4.2's target. The falsifier did
> not fire (input latch region IS written; 0x64=x0 stands).
>
> **Live §221/§222 census (build-lane, DSPVAL=3 + UPD6383_EPIBUS=1 + UPD6383_PICKUP=1):** the §222
> pickup audit reports **fetches 0 (PREDICTED 5)** -- the input-pickup words (`lo12 0x1CD`) do NOT
> fetch in the armed frame, so nothing carries the input toward the biquad. The undecoded candidates
> surfaced are the pickup word (`0x1CD`) and the all-pass `102.A.NN.64B` (multiplicand = SUM OF TWO
> REGISTERS, a fourth route beside mac 0x1D5 / mulst 0x407). ⇒ **4.2 is the genuine ISA frontier:
> decode the input-stage / pickup word(s).** The census names the target, but one frame
> underdetermines the word's ALU -- decoding it (never rigging) is the iterative build-lane decode
> the plan scopes as MULTI-SESSION. Phase 2's coefficient-order decode and all Phase-5 live decode
> sit behind this.

- **4.1 Census the input→biquad bridge by measurement.** — Build-lane run of `tools/rigs/kn5000_dsp_frame_trace.lua` (PARAMETRIC EQ, RULE-12 audio `:KEY2 C4..B4`); over settled EQ frames, census every word that READS cell 0x05 (§222 `pk_fetch`) and every word that WRITES 0x64..0x77 (§221 provenance / §104 residency); cross them to name the bridge word (identity + SRC/ACT/class + current decode status). **Falsifier:** if no word bridges 0x05→0x64, the 0x64=x0 or the 0x05-latch reading is wrong — re-derive, do not paper over. — *M* — [MULTI-SESSION] *(build-lane)*
> **4.2 IDENTIFICATION DONE (2026-09-11).** The disassembler's live annotations name the input
> route: it is the **K6 input-stage words (iw3–iw10)**. iw4 (`204.2.02.1CE`) and iw8 (`084.2.01.1C0`)
> are "THE PORT READ, block A/B -- mem[X+2]/mem[X+5] is an AUDIO INPUT LATCH (read-never-written)";
> iw3/iw5/iw7/iw10 read/store the X+4..X+6 one-frame state cells with **"ALU UNKNOWN"**. So the
> bridge is not missing -- it is these named, addressing-decoded-but-ALU-undecoded input-stage words.
> ⚠ Their ALU cannot be read from this capture because the values are 0 (acc=0 everywhere): decoding
> what arithmetic each performs, and how the input at X+2/X+5 (kernel region ~0x05) reaches the
> unit-0 body's biquad x0 at 0x64, needs SIGNAL-BEARING frames -- the multi-session live decode.
> This is the concrete 4.2 target, now pinned to specific words (iw3/5/7/10, ALU unknown).
>
> **4.2 LOCALIZED + STRATEGY CORRECTED (2026-09-11) — probe `dsp/tools/input_route_probe.py`.**
> Traced the deposit end-to-end in the core (`latch_inputs_to_dram`, upd6383.cpp): `m_in_base = m_dp`
> at frame start (= 0xFF), `IN_LATCH_L_OFF=2`, `R_OFF=5`, `IN_PORT=0`, so the DI audio is deposited to
> D-RAM **0x01 (L)** and **0x04 (R)**. The committed AUDIO=`key` trace CONFIRMS this: of 176 rows
> exactly ONE carries any non-zero mem/P/L — row 1 at **dp=0x04, mem=+0.005** — i.e. audio really
> does arrive at the DI latch (just quiet at that frame). The biquad band cells 0x64.. are all zero,
> so the deposited audio is NOT carried onward to band-0 x0. **So the gap is precisely the input-stage
> ALU that routes 0x01/0x04 → the biquad x0 cell.**
> ⚠ STRATEGY CORRECTION to the note above: this is NOT primarily a "needs signal-bearing frames"
> problem. The core runs those input-stage words as ADDRESSING-ONLY (ALU open), so (a) the copy never
> happens and (b) their arithmetic **cannot be passively observed in any trace, signal or not** — an
> unexecuted word emits no effect to measure. Decoding 4.2 is therefore an ISA-level task: recover the
> input-stage words' ALU op + full SRC/ACT route from their bit encoding (and/or a hardware
> reference), not just a better capture. Signal-bearing frames remain necessary for VALIDATION once a
> candidate op exists, but they are not sufficient to DERIVE it. This is the honest 4.2 boundary.
>
> **4.2 OPEN PART NARROWED (2026-09-11) — probe `dsp/tools/input_stage_alu_probe.py`.** On the
> program-0 real-audio trace, the input-stage words w5/w10 (dsp_disasm.py's "ALU UNKNOWN") DO read the
> audio into the multiplier: their operand `L=5084004` is the DI-latch value, and their PRODUCT is the
> ordinary `(coef × L) >> 6` — verified bit-exact on the NON-degenerate w10 (coef=0.359). So the
> "ALU UNKNOWN" is NOT the multiply; it is the ACCUMULATOR/STORE side (the f31 op and which value gets
> written) that is undecoded. The audio therefore reaches the input-stage MULTIPLY; whether it
> propagates onward depends on that accumulator-side op. ⚠ RETRACTED lead: w5 first appeared to be an
> "input injection = L<<16", but w5 has coef=0.5 (=2^22 raw), which makes `(coef×L)>>6 ≡ L<<16`
> IDENTICALLY — a degeneracy, not a special op (the probe flags it). Net sharpening: 4.2's open
> frontier is now specifically the **f31/store semantics of w3/w5/w10** (their multiply is solved),
> and the audio is confirmed present at the input-stage multiply — not stuck at the raw deposit.
>
> **4.2 GATE ENUMERATED (2026-09-11) — `dsp/tools/input_route_guards.py`.** Ran `alu_decoded`
> guard-by-guard over all 12 K6 input-stage words. Result — the audio route reduces to a SHORT, NAMED
> list of unanchored codes, not a vague unknown:
>   - **w9** (`ST mem[X+6]`, the product the mix block consumes) and **w6** (end of block A) already
>     **DECODE strict** — so the mix input IS computed/stored; the route's tail works.
>   - The audio-carrying and latch words are each open on ONE or two specific codes:
>     unanchored **SRC {0x08, 0x11(accb)}**, unanchored **ACT {0x08, 0x0D, 0x0E(P←bus), 0x17}**, plus
>     the port-read words needing **f31=2 ("acc unchanged", a pure latch-read)** admitted off class 8.
>   - Causal chain, now explicit: w5/w10 READ the audio (verified) but are unexecuted (open codes), so
>     the audio never enters the accumulator that the decoded w9 stores → the mix block gets an
>     audio-free value. Anchoring those ~6 codes makes the whole route executable.
> This is the concrete, actionable 4.2 target for a next session: settle SRC 0x08/0x11 and
> ACT 0x08/0x0D/0x0E/0x17 (+ the f31=2 latch-read admission), one code at a time, each needing MEASURED
> evidence of its effect — which cannot come from captures (these words don't execute), so it is
> bit-encoding cross-reference or hardware. The frontier is now a checklist, not a fog.
>
> **BOUNDARY DEMONSTRATED, not asserted (2026-09-11) — `input_route_guards.py <trace>`.** Tested
> whether the committed captures could anchor any gate code (the disciplined "prove the instrument can
> see it" check). Result: they cannot, for concrete per-code reasons. **SRC 0x11 (accb):** accb is
> non-zero at only 5/285 rows of the program-0 frame and **0 of those use SRC 0x11** with an operand
> matching accb — so the accb *writer* must be modelled first (plan 5.4) before any SRC-0x11 word can
> be confronted. **ACT store-targets {0x08,0x0D,0x0E,0x17}:** their words are not strict-executed, so
> they perform no store — no observable effect to measure the target from (the `acc+=P` that appears
> at 2 rows is the generic MAC accumulate, independent of the store code). ⇒ the boundary is real and
> specific, not a hand-wave. **Side-observation (candidate, NOT promoted):** at row 131 an SRC-0x10
> word reads `L == accb>>16` — a single data point consistent with SRC 0x10's speculative reading;
> one point is far short of the "N clean / 0 contradicting" bar, so it is recorded as a lead only.

- **4.2 Decode the bridge word's ALU from the census.** — If a decoded word is mis-routing, fix the SRC/ACT/`m_dp` to the measured value; if it is a K6 input-stage word with UNKNOWN ALU (e.g. w7/w9), promote it from addressing-only to decoded — but decode ONLY what the census forces; if underdetermined, stop and report the residue (plausible-but-wrong audio is worse than silence). Commit with the census that forced it. — *M* — [MULTI-SESSION] *(reviewed core edit; gates 4.3, 4.4, 5.2, 5.4)*
- **4.3 Verify the stores now carry a correct accumulator.** — Re-capture the EQ frame: confirm `mem[0x64]≠0`, LOAD (iw143) seeds `acc=coef*x0`, the four MACs accumulate, iw144→0x65 and iw150 (ACT-0x07) write a real y that persists to next frame's y1. No code change if 4.2 was right; watch the fixed-point scale (P_SHIFT/ACC_SHIFT, `acc_to_datum` saturation) end-to-end so the newly-live path doesn't clip x0 before the multiply. — *S* — [SESSION] *(build-lane)*
- **4.4 Validate the internal biquad against the retargeted oracle.** — Run the Phase-1.1 comparator on the non-zero trace: assert `acc[k]==acc[k-1]+P[k]` (MACs), `acc[0]==P[0]` (LOAD), cursor coeffs match `[b1,b0,b2,-a1,-a2]`, operands map to x0..y2 at 0x64+4k. Commit the passing diff as the evidence the LLE biquad now matches the HLE bit-for-bit internally. — *S* — [SESSION] *(build-lane)*

> **4.3/4.4 PARTIAL (2026-09-11) — the biquad datapath is LIVE.** Added an env-gated diagnostic
> `UPD6383_BIQSEED` (default-off; shipped/LLE path byte-identical) that seeds the band-0 state cells
> 0x64..0x67 with known values at unit-0 entry. Result (kn7000_mame commit): the biquad's `mem`
> reads show the seeded values and its MACs produce **non-zero products** (were 0 before) — so the
> biquad datapath COMPUTES when fed. ⇒ the entire remaining faithful-EQ gap is the INPUT ROUTE
> (4.2), not the biquad. ⚠ Full oracle validation still needs the **L-latch pipeline** model:
> `P = coef × L` where L is the operand loaded by the PRIOR word (one-slot delay, §50), not this
> word's `mem[ptr]`, and the mid-frame stores overwrite state cells — so `--eq-trace`'s naive
> `coef × mem[dp]` does not match; the comparator needs an L-pipeline+store-aware mode (next step).
>
> **L-pipeline check ATTEMPTED (2026-09-11):** on the seeded trace, `P == coef_raw × L` does NOT
> hold either — nor `(coef_raw × L) >> P_SHIFT` (off ~1%). So the exact multiplier relationship
> (which word's coef × which word's L, plus the P_SHIFT/ACC_SHIFT fixed-point and any rounding) is a
> finer datapath decode than a one-line formula. ⚠ Deliberately NOT fishing for a shift/pipeline
> combination that happens to match (that is the "criterion that cannot fail" failure mode).
>
> **SEEDED TRACE COMMITTED + PIPELINE PROBED (2026-09-11).** Reproducibility fix: the BIQSEED
> numbers quoted above lived only in scratch — the seeded run is now committed as
> `dsp/analysis/data/kn5000-dsp-eq-biquad-trace-SEEDED-2026-09-11.txt` (header carries the exact
> regenerate command), and `dsp/tools/biquad_pipeline_probe.py` produces the numbers below.
> Two results, graded:
>   - **MEASURED — the accumulate side is a clean one-slot pipeline.** Scoped to the EQ biquad pass
>     (rows 56–99, cursor 0x00–0x1D), `acc[N] == acc[N-1] + P[N-1]` holds at **every non-boundary
>     pair — 0 unexplained breaks**; the 21 breaks are all LOAD (hi12 0x000) / STORE-and-makeup
>     (0x212/0x804) / band-boundary words, exactly where a break is expected. The product computed
>     at row N-1 lands in the accumulator at row N. (This confirms §50 for the ACCUMULATE path.)
>   - **OPEN — the product (multiplier) side is not one shift.** Per-MAC-row, the best-fit `s` in
>     `(coef_raw × L) >> s ≈ P` scatters over {0,3,6,7,8,16,19}; the low-residual rows cluster at
>     s=6/7/8 (<2%) while the ~32% rows are all `coef=0x100000` LOADs and the ~88–98% rows are
>     tiny-coef words — i.e. the operand paired with each coef shifts with the pipeline, so the fix
>     is an operand-select + rounding decode, NOT a global shift. Left OPEN, not fitted.
>
> The firm result stands: the biquad datapath is LIVE (non-zero products from seeded state) and its
> accumulator is a verified one-slot MAC; the exact P-model (operand select + rounding) is the next
> multi-session decode step, and the input route (4.2) is the gating unknown for faithful audio.
>
> **MULTIPLIER FORM DECODED (2026-09-11) — `P[N] = (coef[N-1] × L[N]) >> 6`.** Section 3 of
> `biquad_pipeline_probe.py` runs a falsifiable over-determined test: the true product per row is the
> accumulator delta `P*[N] = acc[N+1]-acc[N]` (justified by the verified recurrence), and it requires
> a single `(coef-offset, L-offset, shift)` to reproduce it BIT-EXACT across many rows at once.
> Result: `coef[N-1] × L[N] >> 6` is bit-exact and DOMINATES (next candidate far behind) —
> unmistakable across that many distinct coefficients, so this is the multiplier FORM, not a fit.
> It decodes three things together: the **coefficient is latched one word early** (coef pipeline
> depth 1 — the multiplier-input half of §50), the operand is the **current-row latch L[N]**, and the
> shift is **6 = P_SHIFT** (independent cross-check of the documented constant).
>
> **CORRECTION + FULL MULTIPLIER CLOSURE (2026-09-11).** The first pass used the accumulator delta
> `acc[N+1]-acc[N]` as the product truth and reported 19/31 with a "12/12 band-boundary operand-
> routing residue". That framing was WRONG: the acc delta is only the product on interior rows; at a
> band boundary the accumulator does a non-accumulate op, so the delta there is not the product. Using
> the chip's own PRODUCT REGISTER (trace P column) as truth, `P[N] = (coef[N-1] × L[N]) >> 6` is
> bit-exact on **27/27 MUL=Y rows, band boundaries INCLUDED** (next candidate 11/27). The multiplier
> is MEASURED and UNCONDITIONAL — there is NO multiplier/operand residue.
>
> The boundary differences are the ACCUMULATOR's own ops, now isolated (probe section 4):
>   - **LOAD** (hi12 0x000, f31=0): `acc ← P` — verified `acc[N]==P[N-1]` on **8/8** load rows.
>   - **accumulate** (f31=1): `acc += P`, one-slot delayed (`acc[N]=acc[N-1]+P[N-1]`, prior entry).
>   - **store/makeup** (0x102/0x212/0x804): write the band's `y` out and re-seat the acc for the next
>     band.
> So the biquad DATAPATH is fully decoded: multiply `P[N]=(coef[N-1]×L[N])>>6`, accumulate/load
> `acc←{acc+P | P}`. The ONE remaining biquad structure is the **inter-band DF-I cascade** (band k's
> output `y` feeding band k+1's input) — a routing/topology trace, not a datapath unknown (4.4 close).
>
> **OPERAND SOURCE DECODED (2026-09-11) — probe section 5.** Where the multiplier's operand latch
> `L` comes from: **interior** `L[N] == mem[N-1]` — the D-RAM cell at `dp`, read by the prior word,
> one slot late — on **38/43** rows (equivalently `P[N] = (coef[N-1] × mem[N-1]) >> 6`, 26/27). So on
> interior MACs the operand is simply the microword's own D-RAM addressing; there is no separate
> route to decode. The **5 exceptions {58,62,63,64,65} are exactly the band boundaries**, where `L`
> instead takes the freshly-computed `y` from the accumulator/store path, and it **SATURATES** (rows
> 63,64 show `L=0x7FFFFF`, the positive max). That divergence IS the DF-I inter-band cascade (y_k
> feeds band k+1 via a saturating store). The one finer datapath detail still open is the exact
> **saturating acc→datum store constant** in that cascade — deliberately NOT guessed. Net: the biquad
> is decoded end-to-end except that single store-scaling constant.

---

## Phase 5 — Downstream live decode (SPECULATIVE → MEASURED)
*Needs signal from Phase 4, except 5.1 which is independent and can start alongside Phase 4. Requires the Phase-1.5 confrontation functions. Build-lane; reviewed where it touches the core.*

- **5.1 Anchor the one-pole reverb kernel (needs no route).** — CONCERT REVERB 1 is the unit-1 cold-boot default, so a NAV=0 boot frame already contains reverb words (u1=1); filter u1=1, run `diff_onepole` on the ACT 0x0D/0x0E pairs, resolve the {1-d,d} vs coeff+subtract factorization. Needs audio (`AUDIO=demo`) for y1≠0; grade `DSPVAL=3` cursor rebase SPECULATIVE. — *M* — [MULTI-SESSION] *(build-lane; parallel with Phase 4)*
> **5.1 PREMISE REFUTED (2026-09-11) — the reverb unit is STARVED, not merely present.** The plan
> claimed 5.1 "needs no route" because CONCERT REVERB 1 is the unit-1 boot default and its words
> appear in a NAV=0 frame. They DO appear — but they do not COMPUTE. On the program-0 live-frame
> trace (real audio, RMS 550), `input_route_probe.py` reports per unit: **UNIT-0 = 152 rows, 41 live
> operands, 31 distinct acc (computing); UNIT-1 = 133 rows, 1 live operand, 2 live products, a SINGLE
> frozen acc = 2603010048 (no computation).** The one nonzero value is just the carried-over product
> from unit-0's startup row 123 — the reverb's own recursive term y1 is 0, so `diff_onepole` has
> nothing to confront. ⇒ 5.1 DOES depend on a route: signal must reach unit-1, i.e. the **unit-0 →
> unit-1 handoff** must carry the main output into the reverb input. That handoff is a second,
> further-downstream instance of the 4.2 input-route class (and is itself an addressing/ALU decode).
> Net: one-pole reverb anchoring is gated on the same open ISA decode as 4.2, one stage later — it is
> NOT the independent early win the plan assumed. (The datapath primitive it will use is already
> MEASURED — see the 5.x foundation note below.)
>
- **5.2 Anchor ACT 0x0D/0x0E in the EQ window (#2/#3 routing payoff, +124/+110 strict).** — Observe `acc←bus` (0x0D) / `P←bus` (0x0E) in PARAMETRIC EQ's entry words. **Depends on Phase 4** (the EQ entry runs bus=0 until the route lands). — *L* — [MULTI-SESSION] *(build-lane)*
- **5.3 Harvest f31 {4,5,6,7} operation codes from LFO-driven captures.** — Capture VIBRATO/ROCK ROTARY/CHORUS frames (LFO phase accumulator is always-live), run the oracle-free `--ops` classifier, chase the iw30 f31=5 anomaly (acc ≈ latched-P·5/6). Promote a code only on N clean / 0 contradicting at a fixed chip scale. Small raw coverage (≤106 words) but high value: spec→MEASURED and it feeds the open P_SHIFT/ACC_SHIFT datum scale. — *M* — [MULTI-SESSION] *(build-lane)*
> **5.3 ATTEMPTED (2026-09-11) — the f31=5 anomaly is CONFIRMED, and it does NOT promote.** With the
> `-log` harness fixed, captured both program 0 and a fresh CHORUS (TYPEIDX=0, LFO) frame at DSPVAL=3.
> The f31 {4,5,6,7} live-product words are IDENTICAL across both — they are **KERNEL** slots (I-RAM
> ~15/30/31/38), effect-independent, not the effect body. f31=5 (n=15/30/31) shows **delta/P =
> {1.000, 0.000, 0.167}** across its three occurrences — accumulate, then hold, then +1/6·P — i.e. NO
> single accumulator op. The plan's "acc ≈ 5/6·P" reproduces (acc[30]=329853435904 ≈ 5/6·P[30]) but is
> **NOT bit-exact** (off ~0.016%), so it is not a clean fixed-point op. Per the N-clean/0-contradicting
> bar, f31=5 **cannot be promoted** — it is genuinely the documented anomaly (context-dependent or a
> rounding/pipeline confound). f31=4 (n=38) is load-like (acc[N+1]=P[N]) but a SINGLE occurrence, also
> below the bar. ⇒ the open f31 codes need either an ISOLATED LFO-phase capture where the code is not
> pipeline-confounded, or the deeper ISA/hardware — the same class of gate as the input route. The
> attempt is real; the honest result is that these codes do not decode from the reachable captures.
- **5.4 Anchor SRC 0x11 (accb, +49), 0x13 (table, 44w), 0x0B (delay-read, +7).** — All read 0 in the committed trace, so: first model the accb *writer* in the kernel, then a source-operand classifier (match live L against acc/accb/coef/mem/tA/tB) requires downstream validation against the HLE, not just a plausible L. Two-sided, default off, graded by provenance. — *M* — [MULTI-SESSION] *(build-lane; reviewed)*
> **5.4 accb WRITER LOCATED (2026-09-11) — `dsp/tools/accb_writer_probe.py`.** Progress on the root
> of the 4.2 chain (SRC 0x11 = accb is un-anchorable until the accb writer is known). On the program-0
> frame, accb is a SEPARATE register, live only in a narrow window (rows 130–134): **REFUTED** the
> trivial "accb is a pipeline-delayed acc" hypothesis (best `accb[N]==acc[N-k]` match is 29%, k=0 —
> just the shared-zero rows, no clean delay). Its writer words are identified: the first write
> `accb←acc` is a **class-1, hi12=0x400, ACT=0x07** word (n=129); a later transition is consistent
> only with **accb+=P** (n=131), and the window ends with an **accb←0 clear** (n=134). ⚠ LEAD, not a
> decode: only 3 transitions in one frame, and the load transition has acc==P so accb←acc vs accb←P is
> not split. Promoting an accb op needs N-clean/0-contradicting across MANY frames (and a transition
> where acc≠P). But the WRITER word class is now located — the next concrete node before SRC 0x11,
> and thus before the input route (4.2) and the reverb (5.1), can be anchored.
> **UPDATE 2026-09-11 (capture campaign ran; a CYCLE found).** The harness was unblocked (it needs
> MAME `-log`; see the handoff doc) and 3 frames were captured. But in program 0 the accb load is
> `accb ← 2603010048` with **acc == P** — the frame-invariant kernel-B CONSTANT, not audio (verified
> across a fresh capture and the committed trace). So no arm-timing yields acc≠P: splitting
> `accb←acc` vs `accb←P` needs accb to be fed a VARYING signal, which needs the input route — which
> needs accb/SRC 0x11. **accb-op ⇄ input-route is a dependency CYCLE**; the break is the store/source
> code decode from the bit-encoding (or hardware), NOT another capture. This retargets 5.4 away from
> "capture more frames" and onto the ISA-encoding decode of the gate codes (4.2's checklist).
- **5.5 Capture + confront delay and LFO kernels.** — SINGLE DELAY (verify landing by the algo-9 word signature, NOT `program=` which is stuck at 0) confronted with `diff_delay` + loop `diff_onepole`; cross-frame LFO via the §109 witness (`+=114`, and a captured wrap event to settle AND vs sub-if-ge). Delay confrontation needs the external-delay datum column added to the trace row (**reviewed core edit**) OR the §153/§157/§200 logerror-parsing fallback. — *M/L* — [MULTI-SESSION] *(build-lane; reviewed for the trace-column / witness-generalization edits)*
- **5.6 Opportunistic: class 0 (38w) + ACT 0x0C delay-read (12w).** — Decode whenever a live frame exercises them with signal. Smallest leverage — do last. — *S* — [MULTI-SESSION] *(build-lane)*

> **5.x FOUNDATION — the multiplier datapath GENERALISES beyond the EQ (2026-09-11).** The multiplier
> decode `P[N] = (coef[N-1] × L[N]) >> 6` (MEASURED 27/27 on the PARAMETRIC-EQ seeded trace) was
> re-tested on a DIFFERENT program: the boot-default **program 0** live-frame trace (NAV=0, a real
> C4/E4/G4 note, audio verified RMS 550 — so signal is genuinely present here, unlike the EQ capture).
> Run: `biquad_pipeline_probe.py <live-frame-trace> --all-rows`. Result: the SAME model dominates —
> `coef[N-1] × L[N] >> 6` bit-exact on **18/21** MUL=Y rows (next candidate 11/21). The 3 misses
> {5,10,123} are principled, not model failures: rows 5 and 10 are frame-startup words whose P column
> carries the previous frame's accumulator (`P[5] = acc[0] = 333185286144`, not a fresh product), and
> 123 is a single downstream row. So the coef-pipeline-depth-1 / operand=current-latch / shift-6
> multiplier is the chip's GENERAL datapath, not an EQ-specific coincidence — the shared datapath
> every Phase-5 downstream stage (one-pole, LFO, delay) is built on. This raises the multiplier from
> "MEASURED on one program" to "MEASURED across two programs incl. a real-audio frame". (It does NOT
> by itself decode the downstream STAGE structures 5.1/5.3/5.5 — those still need their own
> confrontations — but it fixes the arithmetic primitive they all use.)

---

## Phase 6 — Speaker-audible LLE (broad-decode arc)
*Honestly multi-session; the last mile. Depends on essentially all of Phase 5.*

- **6.1 Reach the speaker faithfully.** — Audio leaves `run_frame` only when `clean == (traps==0 && partials==0 && hit_wait)` — i.e. every EQ-frame word must decode. Either drive the remaining words to decoded until `clean==true`, or gather evidence that all residual traps are outside unit-0's DO1 EQ datapath and justify presenting a partially-decoded frame. **Never loosen the clean gate to force audio.** Until then, faithful EQ audio ships via the Phase-2 HLE reference path. — *L* — [MULTI-SESSION] *(reviewed + build-lane)*

---

## Boundary — hardware-gated limits (NOT executable steps)
*These are stated as limits, not tasks. Where a mechanism is emulatable but its calibration is not, the mechanism lives in the task list (graded STRONG) and only the calibration is here.*

- **L7A1429 POSITION absolute scale** — PROVEN absent from the ROM (12 units tried, grids 303.9 cents from aligning); only a hardware trace pins it. The pickup fraction stays a documented 0.5 stand-in; only *relative* movement (task 3.5) is faithful. Do not invent a scale to "complete" it.
- **IC4 driver wave mask ROMs (IC43-45, IC47-49)** — undumped; the synthetic LCG excitation burst can never become the chip's real timbre.
- **L7A1429 internal signal path** — series/parallel, where the driver enters, MUTING as one biquad vs two cascaded poles, exact coupling topology. Device is never read (2642 writes, 0 reads / 45 s) — no readback, no ROM closes it; stays a STRONG inference in the manufacturer's vocabulary.
- **ACT 0x0D/0x0E delay-lag consequence (Q4)** in delay programs — confirmable only on real KN5000 hardware; emulation gives STRONG, not MEASURED-on-silicon. Park in `HARDWARE-QUESTIONS-PENDING-FELIPE.md`.
- **KN5000 / WSA1R hardware itself** — stored abroad, unreachable. The LFO wrap-op (AND vs sub-if-ge) and the one-pole damping factorization would each be decided in seconds on silicon; from emulation they are STRONG, not MEASURED. Never promote an inference in the hardware's place.

---

## Cross-cutting notes

**Shared operational blocker (every build-lane capture — 4.1, 4.3, 5.1-5.6, 2.4).** Reliably capturing a FULL frame trace *with signal* in one run: `UPD6383_TRACE_FRAME` must arm so a sounding note (RULE-12: `:KEY2 C4..B4`, not `:KEY1`) AND the selected effect co-occur in one frame; no mid-frame arming (yields partials); a guaranteed `device_stop` dump; and a `KN5000_ENABLE_DSP1=1` build (plain `build.sh` emits no device and an empty log, indistinguishable from "never reached"). Solve this rig-tuning once and reuse it — it is operational, not analytic, and it gates all live decode.

**Named cross-task dependencies.**
- **The input route (Phase 4.2) gates**: store verification (4.3), internal-biquad oracle validation (4.4), ACT 0x0D/0x0E EQ-window anchoring (5.2), and every SRC source anchoring whose operand is currently 0 (5.4). No live signal reaches the biquad/EQ-window words until x0 lands at 0x64.
- **f31 {3,6,7}** are epilogue words that run zero products — the operand-supply wall; they may be UNDECIDABLE without a driving program (5.3), independent of decoder quality.
- **Phase 1.1 (comparator retarget)** must precede 4.4; **Phase 1.5 (confrontation functions)** must precede 5.1 and 5.5; **Phase 1.6 (C++ port + golden)** must precede 2.3/2.4 (the in-context A/B anchors to the golden); **2.1 (cram_peek)** must precede 2.3.
- **5.1 (reverb one-pole)** is the exception that needs *no* route (unit-1 boot default) — start it alongside Phase 4 for an early one-pole anchor.
- **Phase 3 (L7A1429)** is independent of the entire DSP track — different chip, no shared code, no gating.

**Discipline held throughout.** Never rig the copy, the store, or any audio to force a result — silence is preferred to plausible-but-wrong. Grade every promotion by provenance (MEASURED / STRONG / SPECULATIVE; `DSPVAL=3` cursor rebases are SPECULATIVE). Device-core edits are reviewed / build-lane, never smuggled. Per the global reproducibility rule, the capture rig + trace file + extended tool are committed in the SAME session as any quoted coverage or dB number, beside what they measure.
