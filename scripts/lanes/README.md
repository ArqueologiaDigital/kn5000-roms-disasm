# Lane scripts

Scripts written by parallel-push lane agents (see `notes/lanes/BRIEF-2026-09-01.md`).
Kept per-lane so provenance is obvious; promote to `scripts/analysis/` or
`scripts/converters/` if a later pass wants to reuse one elsewhere.

## Lane SUB (2026-09-01) -- subcpu payload v1.42 + subcpu boot (IC30)

Assignment: verify the shared coverage tool's "100.0% source, zero bytes
handed back verbatim" claim for these two images. It does not survive: the
tool (`scripts/analysis/kn5000_source_coverage.py`) only subtracts `.incbin`
bytes, and both images' remaining debt is written as `.byte` -- the exact
failure mode the project has already shipped once (8,496 bytes of maincpu
sound code counted as "source" for the same reason). A precedent for this
exact fix already existed for maincpu audio code:
`scripts/converters/convert_byte_to_native.py`; these two scripts are the
subcpu-territory equivalent, done independently because that script's
data-label exclusion list is hard-coded per maincpu file.

| script | question it answers |
|---|---|
| `audit_lane_sub_byte_code.py` | How many bytes of the subcpu payload v142 and subcpu boot sources sit in `.byte` at all, and of those, how many are non-uniform runs that llvm-mc disassembles with zero warnings (candidate undecoded CODE, not the `.incbin` blindspot)? A **detector**, not a verdict -- data tables of low-entropy bytes (curves, pointer tables) also decode "cleanly" by coincidence; each hit needs a human/context check (see the lane report for the ones checked). |
| `convert_lane_sub_byte_code.py` | Of the candidates found above, which can be converted to real mnemonics **right now, with proof**? For each `.byte` run: disassemble with llvm-mc, then re-**assemble** that exact disassembly and require an EXACT byte match against the original run before touching the source. A block that decodes but doesn't round-trip (an LLVM tlcs900 backend gap, e.g. `cpda16_24` parses on disassembly but is refused as an operand string) is left as `.byte`, unconverted -- same treatment as the already-documented "cannot be converted, unsupported addressing modes" DSP bytecode handlers. Only run against `kn5000_subprogram_v142.s` and `subcpu_fp_math.s` -- NEVER against `subcpu_data_tables.s` or `subcpu/boot`, where the same clean-decode heuristic produces false positives on genuine data (verified by hand: `Voice_FineTune_Curve`, `Voice_Part_PoolPtr_ModeA`, the boot ROM's reserved-area padding). |

Commands run for the lane report's numbers:

    python3 scripts/lanes/audit_lane_sub_byte_code.py v142/subcpu subcpu/boot
    python3 scripts/lanes/convert_lane_sub_byte_code.py --apply v142/subcpu/kn5000_subprogram_v142.s v142/subcpu/subcpu_fp_math.s

Result: 1,230 bytes converted from `.byte` to verified real instructions
(105 blocks: 3 hand-verified singly + 102 by the batch converter). ~976
bytes of genuine code-shaped debt remains in `kn5000_subprogram_v142.s`,
unconverted for two distinct, confirmed reasons: the pinned LLVM tlcs900
backend cannot encode some addressing forms it can decode (the
`DSP_Bytecode_Op01/02/03` handlers, 569 B, matches the source's own
pre-existing note) and cannot re-parse some instruction spellings its own
disassembler emits (e.g. `cpda16_24 D, (HL)`, ~407 B across the
TaskEvent/FIFO/TaskSched family). Neither is a "did not try" gap.
