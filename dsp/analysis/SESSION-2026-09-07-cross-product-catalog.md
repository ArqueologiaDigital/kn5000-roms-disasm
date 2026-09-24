# Cross-product DSP catalog + topology session (2026-09-07)

An autonomous session that built the missing WSA1R half of the effects-DSP deliverable and
used the two products together to advance and cross-validate the decode — all static /
emulator, no hardware. Index of what landed and how it feeds the parked decode effort.

## New deliverables

**WSA1R disassembly tree** (`wsa1/dsp/`, mirrors the KN5000 `dsp/` tree):
- `disasm/eff*.dsm` — 48 named effect program bodies (I-RAM 0x6E), each disassembled +
  commented with the graded readings + a KN5000 cross-reference.
- `disasm/kernel.dsm` — the 63-word shared kernel = the ONLY program that runs at runtime
  (45/45 resident words; proven by the bus capture).
- `disasm/struct_*.dsm` — the remaining structural records (0x00 header, 0x30 variants, the
  6 orphan 0x6A alternates). **All 57 distinct op3 pool programs are now listed.**
- `programs.tsv`, `README.md`; generator `analysis/gen_wsa1_dsp_disasm.py`.

**Cross-product tools** (`dsp/tools/`, work on both products from the committed `.dsm`):
- `dsp_topology_fingerprint.py` — idiom counts vs the textbook algorithm per effect.
- `dsp_idiom_sequence.py` — per-word idiom string; `--crossval` scores every shared effect.
- `dsp_residue_sudoku.py` — the prioritised decode roadmap over both corpora.

**Analysis notes:** `TOPOLOGY-vs-ALGORITHMS.md`, `CROSSVALIDATION-by-algorithm.md`,
`RESIDUE-SUDOKU-ROADMAP.md`. Public: `technics-docs/effects-dsp.md` §8. Blog: part 225.

## How it feeds the decode

1. **A second silicon witness, per effect.** 28 of 31 shared effects are the *structurally
   same program* on both chips (idiom-similarity ≥ 0.95). PARAMETRIC EQ is byte-structurally
   the KN5000's SOLVED DF-I biquad, so its decode is **validated by construction** on the
   WSA1R. Any per-word reading that holds on one chip's PEQ must hold on the other's.
2. **A prioritised residue roadmap.** 1002 distinct words across both products, 86.7 %
   spec-executable; the top 9 residue groups reach the ~93.3 % ceiling, each with a
   topology-constrained proposal (`dsp_residue_sudoku.py`). This is the promote-next list.
3. **A metric correction.** The residue's biggest group (C-format immediate loads) is a
   *disassembler-metric* gap — the MAME device already executes them (`upd6383.cpp:2697`,
   imm13 → `m_cimm`). The genuinely device-side residue is the non-C-format OPEN-action groups.
4. **A cross-product design difference to keep in mind.** The reverbs are NOT the same
   algorithm between products (KN5000 all-pass diffuser ladder vs WSA1R comb/FDN), so reverb
   readings do **not** transfer between them the way the other effects' do.

## What this session did NOT do, and why (honest)

- **No device-core edits.** `upd6383.cpp` is delicate, parked and (per the handoff) contested;
  its speculative-mask mechanism is intricately allocated. Adopting a residue reading into
  execution needs the standing regression gates (`m_rf[0x8D]`, clip rate, byte-match) and, for
  most, real hardware (the ACT 0x0D/0x0E lag is Q4). That validation is not available
  autonomously, and a wrong reading is silent corruption — so the sudoku fills are delivered as
  a *graded hypothesis roadmap*, not applied.
- **No new decode arm run** (SRC 0x00, SRC 0x11). Those are specified in the handoff with
  pre-registered falsifiers and a contested in-progress lane (`w25/src00`); running them
  autonomously risks conflicting with that careful state. The roadmap points at them; the
  handoff owns the execution.
- **Acoustic-modelling LSI**: already at the safe implementation limit (register interface +
  full parameter decode, 2026-09-05). Its audio is blocked on the undumped wave ROMs (the
  resonator excitation), which no static work can supply.

## Resume points

- Decode: unchanged — `dsp/analysis/HANDOFF-NEXT.md` (SRC 0x11 lever) and
  `SRC00-HANDOFF-2026-09-04.md` §4. Now with the residue roadmap and cross-product evidence
  above as inputs.
- Catalog: `gen_wsa1_dsp_disasm.py` and the cross-product tools are deterministic; a re-run is
  a drift check.
