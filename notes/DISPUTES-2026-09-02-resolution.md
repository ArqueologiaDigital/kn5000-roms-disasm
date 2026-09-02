# Lane DISPUTES -- resolution of the two open disputes, 2026-09-02

Scope: `notes/lanes/BRIEF-2026-09-01.md` (both 2026-09-02 addenda) and
`notes/DEBT-INVENTORY-2026-09-02.md`, sections "DISPUTED:
AccPatch_VoiceAssignDataBlock" and "The weakest evidence currently in the
tree: v7 batch F". Both disputes are RESOLVED. Zero reverts.

## Dispute 1 -- `AccPatch_VoiceAssignDataBlock` (v7, 0xF6AFA1, 2,175 B)

**Verdict: CODE, all the way through. No head/tail split.**

Tool: `scripts/analysis/v7_dispute_voiceassigndatablock_reader.py`
(run: `python3 scripts/analysis/v7_dispute_voiceassigndatablock_reader.py`).

The brief's own resolution test -- "find the region's reader; a `call` means
code, a stride reader means the head is a table" -- gives an unambiguous
answer:

* **External reader**: `v7/maincpu/sequencer/accompaniment_engine.s:13046`,
  inside `AccPatch_ComplexDataBlock`, contains `call 16166817` (= 0xF6AFA1,
  the region's exact start address). The surrounding code is a plain
  string-tag dispatcher: it compares `(xiy+256)`/`(xiy+1)`/`(xiy+2)` against
  the ASCII bytes for `'M'`,`'K'`,`'B'`/`'A'` and calls one of two routines
  depending on the match -- ordinary accompaniment-style-tag dispatch, not a
  table walk.
* **Internal reader**: the region itself contains `call 16167311` (= base +
  494 = 0xF6B18F) at 0xF6B189, one instruction before the target -- matching
  the auto-generated positional label `AccPatch_VoiceAssignDataBlock_0x1EE`
  already present in `v7/maincpu/shared/positional_labels.s`. This is a
  second, self-referential entry point (a subroutine with two labelled
  entries), the ordinary code shape, not a stride index.
* **Full-span decode**: `unidasm` decodes all 701 instructions across the
  2,175 B span with **zero** undecodable opcodes, ending on a plain `ret`.
* **The "record motif" re-examined**: the opening bytes the DATA side of the
  dispute read as an 8-byte record (`8d 00 21 c9 cf .. 6e ..`, `8d 01 ..`,
  `8d 02 ..`, plus a `f1 fe 36 00 00 68 ..` separator) decode cleanly as
  `ld A,(XIY+n); cp A,imm; jr nz,...` -- a **repeated string-compare idiom**
  (testing accompaniment tags like `"mka"`/`"fka"`/`"mkb"` byte by byte, the
  same style-tag idiom as the caller at line 13046), not a fixed-width data
  record. The DATA side's own measurement -- whole-region self-match peaking
  at only 0.104 at stride 8 -- is exactly what an unrolled compare-idiom with
  different literal bytes per iteration produces; it does not corroborate a
  table, it corroborates code with several similar-but-not-identical
  branches.

No split is proposed because there is no table: the "table head" reading was
a misidentification of a repeated code idiom, and the region's own two
readers (one external `call`, one internal `call`) both land on ordinary
instruction boundaries.

## Dispute 2 -- v7 batch F (22 regions, 3,883 B, commit `b272c040`)

**Verdict: all 22 regions CONFIRMED as genuine code. No reverts.**

Tool: `scripts/analysis/v7_batchf_recheck.py`
(run: `python3 scripts/analysis/v7_batchf_recheck.py`).

### Recovering the 22 regions

Batch F's own worklist JSON was session-scratch and is gone. Recovered by:

1. `git worktree add --detach <scratch> 211f6f43` (the commit immediately
   before batch F landed) -- read-only, never touched the shared tree or
   this lane's branch.
2. Seeding that worktree's gitignored generated includes
   (`v7/maincpu/includes/`, `custom_data/includes/`, `table_data/includes/`)
   from this lane's own worktree so it can assemble (same generated content
   regardless of commit -- these are derived from the ROM images, which do
   not change).
3. Running the census + worklist pipeline exactly as
   `scripts/analysis/v7_region_worklist.py`'s own docstring prescribes
   (`--prepare`, `--census v7`, then the worklist script itself) against
   that pre-batch-F tree state -- reproducing the SAME ranked candidate list
   batch F was drawn from.
4. Matching batch F's actual converted labels (recovered independently from
   `git diff -U100000 211f6f43 b272c040 -- v7/`, i.e. full-context diff so no
   label is cut off by a truncated hunk) against the regenerated worklist by
   ROM address. All 22 converted spans are present, each with `n_calls=2,
   n_call_hits=1` (the "small sample" 50%-per-region shape the commit
   describes), summing to exactly 3,883 B.

Eight of batch F's underlying pre-existing labels do not appear as their own
worklist entries because the census's blob boundary is the *maximal* `.byte`
run, which silently crossed an unreferenced interior label in six of the 9
touched files (e.g. `MidiChannel_ResetAndConfigure` through
`MidiCh_IterateExpression` in `audio_control_engine.s` are one 755 B census
region, not six) -- this is the flip side of the commit's own "8 candidates
... failed the interior-label check" line, for labels that DID pass.

### Independent reproduction of the commit's own numbers

* Byte histogram over the concatenation of all 22 regions' *original* bytes:
  **223/256 distinct values, longest identical-byte run 4 B, most common
  byte 0x00 at 4.9%** -- reproduces the commit message's own uniform-fill
  check exactly.
* `11/20 = 55%` distinct call targets resolving to a pre-existing name --
  reproduced exactly (target `0xff0295` is shared by 14 of the 22 regions
  across 5 different files, matching the commit's "five unrelated regions in
  five different files" convergence claim).

### The check that actually settles it: boundary audit

`scripts/analysis/v7_call_target_boundary_audit.py` asks a strictly stronger
question than "does the target resolve to a name" -- does it land **exactly
on an instruction boundary**, walking forward from the nearest preceding
named label in a freshly-built ELF? Ran it against all 20 distinct targets,
using the disputes worktree's own current build
(`make rebuilt_ROMs/kn5000_v7_program.llvm.rom`, confirmed
**byte-identical** to `original_ROMs/kn5000_v7_program.rom` via `cmp` before
trusting the labels from `llvm-nm`):

* **11/20 exact matches** to a pre-existing symbol name.
* **9/20 land exactly on an instruction boundary** for an as-yet-unnamed
  target. One of these (`0xFCCC66`) is more than 400 B past its nearest
  named label -- past the boundary tool's default walk window, which
  produced a false "SUSPECT" on the first pass. Re-walked with a 1,400 B
  window: it lands cleanly, immediately after a `retd 0002` three bytes
  earlier -- an ordinary, if unnamed, subroutine entry point. (Recorded here
  as a real limitation of `v7_call_target_boundary_audit.py`'s hardcoded
  400 B window -- a future pass could make it grow the window until it either
  reaches the target or crosses the next named label, instead of reporting
  "uncorroborated" on a short window alone.)
* **0/20 uncorroborated** once re-walked correctly.

=> **20/20 = 100%** of distinct call targets land on a real instruction
boundary, against the "weak" 55%-resolve-to-a-name headline. The 55% figure
undersold the evidence: it only counts targets that happened to already have
a name, not targets that are simply valid code the tree hasn't named yet.

### Other guards, all clean

* **Retroactive `lda*` check**: none of the 27 distinct labels underlying
  the 22 regions is ever the target of an `lda*` (load-address) instruction
  anywhere in v7 -- ruling out "read as a jump/pointer-table entry" for
  every one of them (this is the exact check that caught six bad conversions
  elsewhere in the tree the same night, per the brief's addendum).
* **Full-span decode**: `unidasm` decodes all 22 regions' original bytes
  with **zero** undecodable opcodes, each ending cleanly on `ret`/`jr T`/`jp`.
* **`looks_like_a_table_tail()`**: already `False` for all 22 in the
  regenerated worklist (computed from the pre-batch-F ROM bytes, i.e.
  ground truth regardless of current conversion state).

### Gate

`make rebuilt_ROMs/kn5000_v7_program.llvm.rom` then
`cmp rebuilt_ROMs/kn5000_v7_program.llvm.rom original_ROMs/kn5000_v7_program.rom`
-- **byte-identical**, confirmed in this lane's worktree before trusting the
`llvm-nm` labels used by the boundary audit. `make gate-all` was
deliberately NOT run (narrow gate only, per the brief).

## Files added this session

* `scripts/analysis/v7_dispute_voiceassigndatablock_reader.py` -- dispute 1,
  self-contained, reruns cleanly.
* `scripts/analysis/v7_batchf_recheck.py` -- dispute 2, self-contained (the
  22-region list is hardcoded from the recovery procedure above since the
  original worklist JSON no longer exists anywhere retrievable; the census
  worktree used to cross-check it was scratch and has been removed).
* This file.
