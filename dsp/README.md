# KN5000 effects-DSP (IC311, NEC uPD6383GF) program tree

This directory holds the reverse-engineered microprograms that run on the
Technics SX-KN5000's **primary effects DSP** — IC311, an **NEC uPD6383GF-3BA**.
The chip is a 24-bit fixed-point audio DSP with an on-die coefficient RAM,
data/state RAM and instruction RAM, plus an external delay-DRAM controller
(IC309, an M5M44260AJ). It has **no boot ROM of its own**: the Sub CPU
(TMP94C241F) **host-boots** it, streaming a common kernel and the selected effect
microprograms over the uC-IF port as a bytecode of upload records.

Those microprograms are **embedded in the dumped Sub CPU ROM**
(`original_ROMs/kn5000_subprogram_v142.rom`, base `0xEF00`), behind a 100-entry
pointer table `ALGO_TABLE` at `0x0001ED7C` (coefficient streams: `PARAM_TABLE`
`0x0001EF0C`). This tree extracts, disassembles and documents them. **Nothing
here needs the physical DSP, a datasheet, or any undumped ROM** — the whole
effect program set was recovered statically from firmware.

> ⚠️ **DRAFT / RESEARCH INSTRUMENT. THE INSTRUCTION SET IS NOT DECODED.** Seven
> word forms carry a real mnemonic; on the **frame floor** (the 83-word resident
> kernel + the 133-word reverb, i.e. the code that runs in every frame) that is
> **29 of 216 = 13.4 %**, with **35 more words** whose *operation* is determined
> but whose operand encoding is not. Over the body corpus it is **9.0 %** by
> vocabulary. Everything else is emitted as `?word` with its fields, decoded
> `hi12` flags and any MEASURED structural landmark — never a guessed opcode.
> Run `python3 dsp/tools/dsp_coverage.py` for the current table; see
> [`instruction-set.md`](instruction-set.md), whose first section lists the
> **claims that were withdrawn** as falsified.

## What's here

| Path | Committed? | Contents |
|---|---|---|
| `README.md` | yes | this file |
| `programs.tsv` | yes | GENERATED manifest: one row per distinct image (name, unit, load, words, class-A count, named-coeff count, slots, family, confidence, role) |
| `instruction-set.md` | yes | the ISA as decoded — word format, `hi12` microword bits, addressing, call/return control flow, PROVEN vs OPEN, and the honest coverage figure |
| `algorithms/` | yes | per-family algorithm docs (biquad/EQ and reverb are SOLVED to the bit; the rest are structural), each linking the deep notes rather than duplicating them |
| `flowcharts/` | yes | GENERATED per-program **Mermaid signal-flow flowcharts** — the shared kernel + all 38 effect bodies (structure, not a per-instruction dump); see [`flowcharts/README.md`](flowcharts/README.md) |
| `disasm/index.dsm` | yes | GENERATED rendered manifest of all 38 images + totals |
| `disasm/kernel.dsm` | yes | GENERATED disassembly of the resident kernel part 1 — the 60-word common header, I-RAM 0..59 |
| `disasm/epilogue.dsm` | yes | GENERATED disassembly of the resident kernel part 2 — the 23-word **output stage**, I-RAM 60..82, which runs last in every frame and holds the two per-unit call-vector words the host rewrites (`analysis/k5-output-stage.md`) |
| `disasm/progNN_<name>.dsm` | yes | GENERATED disassembly of each distinct image: per word — fields, decoded `hi12` flags, structural annotation, absolute C-RAM coefficient address, and the named coefficient where known |
| `sym/progNN.sym`, `sym/kernel.sym`, `sym/epilogue.sym` | yes | hand-curated per-program labels/comments (the loss-free annotation source) |
| `analysis/` | yes | per-roadmap-item decode write-ups with explicit PROVEN / DETERMINED / FORCED / INFERRED / OPEN status on every claim (`k5-output-stage.md`, `r1-allpass-motif.md`, `k3-pointers.md`, `k4-cursor.md`, `r2-output.md`, `r3-delaydram.md`) |
| `analysis/isa-adjudication.md` | yes | the **integration pass** that reconciled K3/K4/R2/R3 against each other and against the ISA reference. Confirms R2's census and K4's class-8 result exactly; **falsifies** R3's C-format-contaminated DRAM family and K3's `0x827` D-RAM origin; adds the per-unit STATE-BLOCK BASE |
| `analysis/closure-pointer.md` | yes | the **FRAME-CLOSURE** pass on the D-RAM operand pointer. Shows the closure equation is degenerate in the payload and constrains the reload **SITE** instead; **falsifies** the five `lo12 = 0x820` header words as the frame-closing load (they sit before the unit-0 call, whose pool has 8 distinct net displacements); localises the re-establishment to I-RAM 50..78; and **falsifies** K6 finding 5 under the completed shared-pointer walk |
| `analysis/acc-adder.md` | yes | ★ the **ADJUDICATION** of two passes that reached OPPOSITE determinations about `lo12` ACTION `0x00`. Shows both were right about the value and wrong about the mechanism — the ACTION is a **selector on the accumulator's adder**, not a step before or after the `hi12[3:1]` operation. **FORCED** by the intersection of three independent numeric contexts (bit-identity with the PARAMETRIC EQ biquad, the SINGLE DELAY comb, all 29 LFO blocks): 18 survivors out of 2160 x 3240 x 181440. Also **falsifies** the older SINGLE DELAY model's forcing power |
| `analysis/retraction-sweep.md` | yes | ★ the **PROPAGATION AUDIT**: every claim whose stated PREMISE has since been withdrawn. Finds that `notes/kn5000-dsp-INDEX.md` — the front door — carried **six** dead claims; that `closure-pointer.md` falsified K6 finding 5 and **never went back to K6**; and ★ that a 2026-07-22 note declared the non-returning-pointer problem SOLVED by a reload K3 has since withdrawn, so **the problem is re-opened and is numerically the same defect as the `+121` frame-closure residue**. Confirms **no shipped code depends on a retracted premise**, but corrects two stale **labels** in the device, one of them printed to the user every run |
| `analysis/output-stage-decode.md` | yes | ★ the **OUTPUT-STAGE** pass, I-RAM 60..82 — and the thing it handed over: ★ **the D-RAM ORIGIN is PINNED** by solving the host's own per-algorithm zero-fill against the bodies' pointer walks (three independent derivations; per-unit body entry `0x05` / `0x85`, state block at ENTRY+75 = `0x50` / `0xD0` in 85 of 85 streams), which **CLOSES THE FRAME** — residue **0** with `X = 0xFF` reached two independent ways, against the standing `+121`. Answers the brief's question in the negative (**nothing in 60..82 re-primes the D-RAM base**; the rebase precedes the unit-1 body and its value is a **register**, K4 item D confirmed with a measured value), identifies R2's three unexplained registers `0x8C`/`0x8D`/`0x8F`, and **falsifies** `closure-pointer.md` §6.1's favoured resolution and its one-reload-per-frame premise |
| `analysis/dark-words.md` | yes | ★ **THE DARK SET** — the 86 frame slots that execute NOTHING, characterised as a set for the first time. Shows the boundary is a **theorem** (a word traps *iff* it has no modelled addressing, i.e. `class4 ∈ {0,1,3,4,5,6,7}` or the C format), so the dark set is precisely the part of the chip that is **not** the D-RAM/C-RAM datapath: external delay DRAM (42 of 86 slots), the register/port space, the immediate format. Partitions them by **blocker set** and ranks by *slots recovered per unknown resolved* — the delay-DRAM family is rank 1 on all three metrics and for 37 of 37 unit-0 bodies; resolving it alone moves the frame 108 → 133 decoded of 285 and the reverb 51.9 % → 66.9 %. Separates **aborts the frame** from **merely unexecuted** with a marginal taint walk (the PARTIAL set, not the dark set, is what makes the arithmetic wrong) and shows what the dark set exclusively owns: the delay line and the two per-unit OUTPUT LEVEL words. **Corrects** `dsp-closure-applied.md` §5's DRAM bucket (41 → 42; its twelve buckets sum to 179 against a stated 177) and offers **H-DIR**, a delay-DRAM direction rule scoring 4/4 where the falsified `addr8` rule scores 2/4 |
| `tools/dark_words.py` | yes | the tool behind it — ten subcommands, four controls each *demonstrated rejecting*, and one of its own proposed tests withdrawn for being unable to fail; stdlib only |
| `analysis/register-space.md` | yes | ★ **THE REGISTER SPACE, THE IMMEDIATE AND THE LAST GATE ON THE AUDIO PATH** — the other 44 dark words (everything in `dark-words.md`'s partition except the 42 delay-DRAM slots). Attacks them from the **host's own write log**, which is static and complete: the 100 canned per-algorithm PARAM streams plus the four writer routines. ★ **Cells `0x06`/`0x86` are the user-facing `VOLUME` parameter** — a Q0.23 linear gain from a dB curve table, 49/49 by name, with the two MEASURED cold-boot values landing on the exact curve entries their own algorithms select (and the wrong-curve twin rejected). **Falsifies** `dark-words.md`'s 800-sample pre-delay lead (the word occurs 29× in 11 unit-0 algorithms and 0× in any reverb), **falsifies** its hypothesis (β) for the call-word cells (the host primes `0x0E` with **zero** and never touches `0x0F`), **falsifies** `kn5000_dsp_params.py`'s writer byte-1 formula (`v>>1` should be `v>>17`; 813 of 1751 packets disagree) and **falsifies** the prediction that cell `0x90` is the wet level (it is `REV SEND`). Recovers **zero** dark slots and says so first |
| `tools/register_space.py` | yes | the tool behind it — eight subcommands, seven controls each *demonstrated rejecting*, a degeneracy caught (the published auto-increment tiling leaves `{+1,−1}`) and one of its own discriminators withdrawn for **circularity**; stdlib only |
| `analysis/dram-cursor-closure.md` | yes | ★ **THE DESCRIPTOR CURSOR** — the closure test applied to the *second* pointer this machine walks per frame, the one `dark-words.md` item G showed had never been testable. Exhaustive over 10 reload positions × every ring size × every value against all **948** frames the machine can form: a **free-running** cursor and a **one-reload-per-frame** cursor both have **zero** survivors, so the frame contains ≥ 2 reloads. `880.1.30.00B` is the first DRAM word of the twelve reverbs (cell `0x00`) *and* of 51 unit-0 bodies (cell `0x26`), so **the descriptor base is per-unit STATE, not an instruction field** — which kills R3 candidate **(i)** twice over and leaves **(iii)** alone standing. Closure then pins the **frame-entry cursor at `0x20`** with no free parameter, exactly the bottom of the only gap in the whole descriptor file (`0x20..0x25`, six cells no algorithm writes) — R3's postulated slack, derived. The single-reload machine **misses by exactly 2** and the 16 words that would resurrect it are named. ★ And the pass's headline experiment **FAILS**: the descriptor values are **not** a direction oracle — a word-blind control scores 94.5 %/61 clean against H-DIR's 93.0 %/62, so `DRAM-DIR` stays OPEN and H-DIR keeps exactly its four rows. **Falsification candidates** filed against `r3-delaydram.md` §5.1's "no wrap limit" (76 of 91 algorithms ship exactly two region-boundary cells) and against its rotation **sign** |
| `analysis/store-gate.md` | yes | ★ **THE BIT-7 STORE GATE, enumerated as a FUNCTION and PRICED** — the gate stops being a hand-named list of six lambdas and becomes a map from the six addressable store classes `(bit 7, hi12[3:1])` to one of **33** effects (`none`/`store`/★`LOAD` × value × destination × timing × clear), which absorbs the global `sttime` the published space double-counted. **FORCED: bit 7 really is in the condition** — classes `(0,1)` and `(1,1)` differ in bit 7 alone, the biquad needs `(0,1)` to store and the LFO needs `(1,1)` not to. ★ **The LFO does not force *the store is suppressed*, it forces *the store does not reach `mem[ptr]`***: 0 of 17 928 survivors write it, and `store → elsewhere` and **`bit 7 = a memory-port DIRECTION bit`** both run. **Falsifies** the published price twice: the condition question is worth **1** corpus word (not 13 — nine of those are COMPRESSOR words the decoder already refuses) and its store is dead; the whole gate is worth **17** words in 9 programs (not 130 — 114 trap on unanchored SRC/ACTION codes). ★ `SRC 0x00`: the cell `blocking-read.md` item G conditions on is the user-facing **`FEEDBACK L`** knob, so the ambiguity **does not close** and the emulator capture is superseded |
| `tools/gate_settle.py` | yes | the tool behind it — eleven subcommands; a **mirror** check that reproduces `action00-discriminator.md`'s 3312 and `acc-adder.md`'s 1224 to the digit *and caught a bug in its own author's mapping first*; an observational quotient measured on random states (33 effects → 13/15/17 distinguishable, and `act00`-dependent); the biquad and LFO controls each *demonstrated rejecting*; a structural discriminator shown to fire at 35 sites and change **nothing**; stdlib only |
| `tools/dram_cursor.py` | yes | the tool behind it — six subcommands, five controls each *demonstrated rejecting*, one of its own tests withdrawn for being unable to fail and one of its own controls relabelled as **degenerate**; and an exact affine solver that corrects the bounded-scale search `blocking-read.md` item J used; stdlib only |
| `analysis/adjudication-round4.md` | yes | ★ **ADJUDICATE AND APPLY, round 4** — the three passes above, collided. ★ **`dram-cursor-closure.md` item I's rotation-sign contradiction is DISSOLVED by one unenumerated option and it is the blocking read's shape again**: its two halves are stated in different units. MEASURED over 486 + 384 descriptor cells, **the delay DRAM is one 64 K space split at `0x8000`** — unit-0 owns `[0, 0x7FFF]`, unit-1 `[0x8000, 0xFFFF]` — so MULTI TAP's "line base 0" and ROOM REVERB's "region floor" are the same object and both algorithms say *one cell holds the floor and every other cell is above it*. The four-way disjunction resolves to **the alignment**: every reverb block carries at least two INTERIOR cells that cannot be an address in its own region, and no rigid 1:1 map at any phase δ can skip an interior slot. ★ **The descriptor block is a CONTIGUOUS ADDRESS PARTITION** (9 duplicates at offset +5 plus 1 at +11 in 12 of 12; permutation null 0/4000; ascending null 0/200 000) whose 11 segment differences reproduce `r3-delaydram.md`'s chain 0 **to the digit** — a re-derivation, credited. ★ **The brief's own comb prediction `[127, 435, 489, 183, 522]` is retracted** — r3 §5(c) halved them a round ago and the retraction never propagated; filed as `retraction_sweep.py` premise **P16**, 7 LIVE sites. ★ **`store-gate.md` item F's falsification of the shipped "13 corpus words" is WITHDRAWN**: 11 is the 38-body-image count and 13 the 3057-word one, both right, different denominators. ★ **APPLIED, and it removes a decode**: `upd6383d.h` guard 7's ACTION-0x00 escape rested on an under-enumerated argument (a clear deferred past the ALU IS visible) and is gone — 108 → 107 DECODED, price MEASURED at exactly **one** word, not the 107 the device claimed |
| `tools/adjudicate4.py` | yes | the tool behind it — eight subcommands, **nine** controls each *demonstrated rejecting* (including two permutation nulls that preserve the multiset and a walk shown able to say OBSERVABLE at 66 of 285 planted sites), a corpus-scope collision printed three ways, and one of its own claims corrected mid-pass from "0 exceptions" to "11, all one cell"; stdlib only |
| `tools/output_stage.py` | yes | the seven-subcommand tool behind it — the 23 words with every field, the **C-FORMAT OPCODE** census (`is_c40()` turns out to *be* opcode `0x620`), the D-RAM origin solve, the closing frame walk, the 256-cell map, the `w73`/`w78` evidence and the predict-then-check numbers; stdlib only |
| `tools/retraction_sweep.py` | yes | the re-runnable checker behind it — a declarative catalogue of withdrawn premises, an assertion-vs-retraction classifier biased toward reporting, and a `selftest` that plants both outcomes and fails loudly if either direction stops working; stdlib only |
| `tools/acc_adjudicate.py` | yes | the joint three-context solver behind `analysis/acc-adder.md` — one declared model space, one word executor, and the biquad / SINGLE DELAY / LFO tests scored against it; stdlib only |
| `tools/closure_pointer.py` | yes | the static frame walk plus the closure tests — the unit pools, the admissible-site set, the payload demand, the walk-variant robustness table, the I/O-window collision test and an exhaustive bit-field search; prints every number quoted in `analysis/closure-pointer.md` |
| `tools/isa_adjudicate.py` | yes | re-derives every claim on which two passes can disagree, and prints the verdict; stdlib only |
| `tools/k4_cursor.py` | yes | roadmap **K4** — the C-RAM memory map, the forced constraints on the coefficient-cursor rebase, and the class-1 register file's per-unit banking; prints every number quoted in `analysis/k4-cursor.md` |
| `tools/dsp_disasm.py` | yes | the Python ISA disassembler — a self-contained, byte-faithful mirror of MAME's `upd6383d.cpp` |
| `tools/gen_dsp_disasm.py` | yes | the generator (extract → disassemble → annotate → emit) |
| `tools/r1_allpass_solve.py` | yes | roadmap **R1** — the constraint solver that forces the reverb's 8-word all-pass motif, plus the motif census, the coefficient banks and the delay chains, all straight from the ROM |
| `tools/dsp_coverage.py` | yes | the coverage table quoted in `instruction-set.md`, in two tiers that are never added together (executable decode vs. operation-only) |
| `verify.py` | yes | the byte-match check |

The raw per-image binaries are **not** committed (derived ROM data, regenerable),
matching the repo's "derived data is never committed" policy.

## Regenerating (the whole point)

```
make dsp            # or: python3 dsp/tools/gen_dsp_disasm.py      -- rewrite disasm/, programs.tsv
make dsp-flowcharts # or: python3 dsp/tools/gen_dsp_flowcharts.py -- rewrite flowcharts/
make dsp-verify     # or: python3 dsp/verify.py                    -- byte-match check
git diff --exit-code dsp/disasm dsp/programs.tsv   # also a drift check
```

(The `make` targets pass `TOOLS=$(HOME)/compartilhado/kn7000_mame/tools`; override
with `make dsp TOOLS=<path>` if the research tools live elsewhere.)

The generator is **deterministic and idempotent**. It keeps the tree current as
understanding improves, from two independent sources:

* **the ISA** — `tools/dsp_disasm.py`. Teach it a new instruction form (in step
  with MAME's `upd6383d.cpp`) and *every* listing re-decodes on the next run.
* **the named coefficients** — pulled **live** from the research tools in the
  `kn7000_mame` tree (`kn5000_dsp_namedcoeff` / `kn5000_dsp_params`). As those
  name more of the ~822 class-A multiplies, a re-run picks it up with no edits
  here. Today **391 / 822 (47.6 %)** carry a named coefficient (PARAMETRIC EQ
  60/60, reverb 33/33).

Put analysis in `sym/*.sym` and in the upstream research tools — **never** in the
generated `.dsm` (they are overwritten). Because `sym/*.sym` is merged in at
generation time, regeneration never loses an annotation.

### Provenance dependency

Extraction and the named-coefficient overlay reuse the research tools that live
in the `kn7000_mame` tree (default `~/compartilhado/kn7000_mame/tools`; override
with `--tools`). This is a deliberate, documented dependency — that tree is where
the reverse engineering and its notes live, so re-running the generator is
exactly how future ISA/coefficient improvements flow into these listings. The
disassembler itself (`tools/dsp_disasm.py`) is self-contained and needs nothing
external, so the ISA view is always reproducible.

## How a program is recovered (upload-record format)

The Sub CPU's `DSP_BytecodeInterpreter_Loop` (`subcpu 0x03C2CB`) walks a stream
of records; the high nibble of byte 0 is the opcode, `len = ((b0 & 0x0F) << 8) |
b1` is the total record length:

- **opcode 3** → I-RAM code: a command byte, a 16-bit I-RAM word address, then
  **5-byte** instruction words (one 36-bit word each, right-aligned big-endian).
- **opcode 2** → C-RAM/D-RAM coefficients: **3-byte** words (signed **Q0.23**).
- **opcode F** → terminator; opcodes 0/1/5 carry 5-byte words, opcode 4 is a bare
  command.

The 96 valid programs load at **I-RAM 84** (effect unit 0) or **I-RAM 200**
(effect unit 1); both effect units are resident at once, on top of the shared
kernel. The static extraction has been verified byte-identical against a live
I-RAM dump of the running MAME device.

## The corpus

- **~100 effect slots** are served by **40 distinct microprograms**; the identity
  of an individual effect lives largely in its **coefficient stream**, not its
  code (one reverb program serves 12 reverb presets, one 49-word image is shared
  by 42 slots, etc.).
- **38 distinct images** are disassembled here (see `disasm/index.dsm`). **Five
  malformed streams (algos 79, 88, 89, 90, 91)** load outside the 384-word I-RAM,
  carry no terminator, and are **excluded** (flagged, not disassembled).
- **Two families are SOLVED to the bit**: the **PARAMETRIC EQ** (Direct-Form-I
  bilinear biquad — `algorithms/biquad-eq.md`) and the **REVERB** tank — two
  all-pass diffuser ladders of **five and four** stages, *not* five and five
  (`algorithms/reverb.md`; corrected 2026-07-26, and the coefficient bank now
  agrees with the code at nine stages). The rest are mapped structurally at
  *high* or *medium* confidence, labelled per program.
  Caveat kept in view: the reverb is solved as an *algorithm* — its 33
  coefficients, 9 stages and delay chain — while the per-word roles of its
  all-pass core are narrowed to **two** surviving assignments, not one.

## The chip

- **NEC uPD6383GF-3BA** (IC311), documented as IC302 in the Pioneer
  CDJ-500/CDJ-500G service manual (block diagram + pin table only, **no
  instruction set**). **25 MHz** crystal; **44,100 Hz** sample rate; a 36-bit
  instruction word in a 5-byte container; coefficients signed **Q0.23**; the
  external delay memory is **16-bit** (IC309).
- A **second** effects chip, IC310 (**MN19413**, its own 20 MHz crystal, 8-bit
  delay DRAM IC308), handles effect units 2–4 and is **entirely untouched** here.

## Further reading

- **Narrative** — the MAME development blog, KN5000 effects-DSP series
  (Parts 78–84): how each result was found.
- **Reference** — the project docs site, `/effects-dsp/`
  (`kn5000-docs/effects-dsp.md`): the distilled reference.
- **Deep notes** — the reverse-engineering write-ups in the `kn7000_mame` tree,
  indexed by `notes/kn5000-dsp-INDEX.md` (encoding, hi12, addressing, spaces,
  semantics, biquad, reverb, named coefficients, effect-map, …). The algorithm
  docs here link the relevant note instead of duplicating it.

## Same approach, sibling models

The generator takes the ROM/tables as inputs, so the same method serves the
KN6000/KN6500 sibling effect chips if their program pools are ever recovered. The
KN5000's own second DSP (MN19413) awaits its own tree.
