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

> ⚠️ **DRAFT / RESEARCH INSTRUMENT. THE INSTRUCTION SET IS NOT DECODED.** Six
> word forms carry a real mnemonic; the honest instruction coverage is **~9 %**
> of the corpus vocabulary, **~18 %** by operand-role. Everything else is emitted
> as `?word` with its fields, decoded `hi12` flags and any MEASURED structural
> landmark — never a guessed opcode. See [`instruction-set.md`](instruction-set.md).

## What's here

| Path | Committed? | Contents |
|---|---|---|
| `README.md` | yes | this file |
| `programs.tsv` | yes | GENERATED manifest: one row per distinct image (name, unit, load, words, class-A count, named-coeff count, slots, family, confidence, role) |
| `instruction-set.md` | yes | the ISA as decoded — word format, `hi12` microword bits, addressing, call/return control flow, PROVEN vs OPEN, and the honest coverage figure |
| `algorithms/` | yes | per-family algorithm docs (biquad/EQ and reverb are SOLVED to the bit; the rest are structural), each linking the deep notes rather than duplicating them |
| `flowcharts/` | yes | GENERATED per-program **Mermaid signal-flow flowcharts** — the shared kernel + all 38 effect bodies (structure, not a per-instruction dump); see [`flowcharts/README.md`](flowcharts/README.md) |
| `disasm/index.dsm` | yes | GENERATED rendered manifest of all 38 images + totals |
| `disasm/kernel.dsm` | yes | GENERATED disassembly of the shared 60-word kernel (common header) |
| `disasm/progNN_<name>.dsm` | yes | GENERATED disassembly of each distinct image: per word — fields, decoded `hi12` flags, structural annotation, absolute C-RAM coefficient address, and the named coefficient where known |
| `sym/progNN.sym`, `sym/kernel.sym` | yes | hand-curated per-program labels/comments (the loss-free annotation source) |
| `tools/dsp_disasm.py` | yes | the Python ISA disassembler — a self-contained, byte-faithful mirror of MAME's `upd6383d.cpp` |
| `tools/gen_dsp_disasm.py` | yes | the generator (extract → disassemble → annotate → emit) |
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
  bilinear biquad — `algorithms/biquad-eq.md`) and the **REVERB** tank (two
  ladders of five all-pass diffusers — `algorithms/reverb.md`). The rest are
  mapped structurally at *high* or *medium* confidence, labelled per program.

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
