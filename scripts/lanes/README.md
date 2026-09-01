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
| `byte_accounting_lane_sub.py` | Of the two DUMPED ROMs (ground truth, not source), how many bytes are erased flash / alignment fill (a run of >=64 bytes of one repeated value) versus real content? Written after the coordinator's prom_d data point: pad/erased-flash bytes must get their own line and never be folded into a coverage percentage, because a genuinely blank chip would otherwise look "100% covered" for free. |

Commands run for the lane report's numbers:

    python3 scripts/lanes/audit_lane_sub_byte_code.py v142/subcpu subcpu/boot
    python3 scripts/lanes/convert_lane_sub_byte_code.py --apply v142/subcpu/kn5000_subprogram_v142.s v142/subcpu/subcpu_fp_math.s
    python3 scripts/lanes/byte_accounting_lane_sub.py

Result: 1,230 bytes converted from `.byte` to verified real instructions
(105 blocks: 3 hand-verified singly + 102 by the batch converter). ~976
bytes of genuine code-shaped debt remains in `kn5000_subprogram_v142.s`,
unconverted for two distinct, confirmed reasons: the pinned LLVM tlcs900
backend cannot encode some addressing forms it can decode (the
`DSP_Bytecode_Op01/02/03` handlers, 569 B, matches the source's own
pre-existing note) and cannot re-parse some instruction spellings its own
disassembler emits (e.g. `cpda16_24 D, (HL)`, ~407 B across the
TaskEvent/FIFO/TaskSched family). Neither is a "did not try" gap.

`byte_accounting_lane_sub.py` found that the boot ROM (IC30) is **96.6%
erased flash** (two runs of 0xFF, 98,304 B and 28,211 B) -- only 4,462 B
(3.4%) of the 131,072-byte dump is real content at all, and that sliver was
already fully typed (code + named data tables) before this lane started; the
"100%, zero debt" claim for THIS image survives, but only over a 3.4%
denominator, which the coverage tool's headline number obscures completely.
The v142 payload is the opposite shape: only 0.3% (639 B) is fill, so its
195,969 B of real content is where the ~2,600 B of code-as-`.byte` debt
(found and partly fixed above) actually lived.

## Gate status at hand-off (2026-09-02)

Per the coordinator's instruction, this lane did NOT run `make gate-all` (a
fresh worktree needs to build ~195,000 lines of generated C before the KN5000
half can even start, and that stalls -- three lanes already lost time to it).
What WAS actually run, precisely:

* `make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom
  rebuilt_ROMs/kn5000_subcpu_boot.llvm.rom` (the two targets only, ~45 s) followed
  by a direct zero-tolerance byte compare against `original_ROMs/` (same
  method as `assert_byte_identical.py`: size check + full byte diff) --
  **both images IDENTICAL**, i.e. the two lane-sub conversions introduced zero
  byte drift.
* `wsa1/`'s own gate, which does not depend on the KN5000 generated-C step:
  `make -C wsa1 all` then `python3 wsa1/scripts/analysis/assert_byte_identical.py
  --no-build` (build had just completed, so `--no-build` only skips a
  redundant rebuild) -- **PASS, all 4 WSA1R images identical**.
* This lane's own `make all` (launched before the coordinator's instruction
  arrived) DID finish in the background, ~15 minutes of wall time, exit 0,
  competing with ~8 other lanes' builds on an 8-core box. Its
  `rebuilt_ROMs/` therefore holds fresh artifacts for all 9 KN5000 images,
  but this lane deliberately did NOT run `assert_byte_identical.py` against
  them -- that 9-image (13 with wsa1) certification is the coordinator's to
  run centrally after merge, per instruction.

## Lane MISLABEL (2026-09-02) -- the three self-tagged "MISLABELLED, THIS IS CODE" markers

Assignment: `kn5000_source_coverage.py` prints three spans in
`kn5000_subprogram_v142.s` as "self-tagged still-undecoded markers needing
human adjudication" (`VoiceCC_DataTable_0280FE`, `VoiceCC_DataTable_028F75`,
`VoiceModWheel_DataTable_02A061`). Checked each against the actual bytes
rather than trusting the marker text, since the falsification pass above
(105 blocks / 1,230 bytes, commit `35b5b51d`) could have silently resolved
some of them already.

Result: `VoiceCC_DataTable_028F75` (3,772 B) was ALREADY fully code -- its
marker was pure stale text, rewritten rather than left claiming a debt that
no longer existed. The other two still had real `.byte` residue: 134 B in
`VoiceCC_DataTable_0280FE` (the `AudioMod_Scale_To_Part_1C`/`_1B` pair, which
also contains the separately-named 42 B `Voice_CC_SetModWheelRange`) and all
136 B of `VoiceModWheel_DataTable_02A061`. All three resisted the automated
convert/audit pipeline for the SAME reason: llvm-mc's own `--disassemble`
cannot decode the register-indexed forms involved (`st_rrb`, `ld_sril3`,
`lda_rr`, `ldib_erp`/`cpib_erp`/`inc1b_erp`) even though its assembler can
ENCODE them -- the mirror image of the already-documented DSP_Bytecode gap
(that one can decode but not encode). MAME unidasm supplied the framing;
each block was proved by hand-assembling that text with llvm-mc and diffing
the result against the original bytes before touching the source.

| script | question it answers |
|---|---|
| `verify_mislabel_markers.py` | For each of the three marker addresses: how many `.byte` lines remain in the source between that header and the next one (should be 0), and is the rebuilt ROM byte-identical to the original **exactly across that address range** (not just "the whole-ROM cmp was clean", which does not by itself prove these three spans specifically didn't drift while something else changed too)? |

Commands run for the lane report's numbers:

    make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom
    python3 scripts/lanes/verify_mislabel_markers.py
    python3 scripts/lanes/audit_lane_sub_byte_code.py v142/subcpu subcpu/boot   # before/after totals: 158,821 -> 158,509
    python3 scripts/analysis/kn5000_source_coverage.py                          # confirms all 3 markers gone from the "self-tagged" list

Gate: narrow only, per lane brief (`make gate-all` not run in this
worktree). `rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom` cmp'd
byte-identical to `original_ROMs/kn5000_subprogram_v142.rom` after the
change -- the coordinator's central `make gate-all` is the 13-image
certification.
