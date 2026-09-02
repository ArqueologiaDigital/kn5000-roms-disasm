# Lane V7SLICESPLIT, 2026-09-02 -- splitting v7's misclassified DATA romslices

Target named in the brief: of v7's 180 (later 167, after a correspondence bug
fix below) DATA-kind romslices, 152/153 (68,934 / 69,634 B) are a short data
header glued onto a following routine, misclassified wholesale because
`v7_slice_v9v10_correspondence.py` judges a slice's kind from the label's
FIRST line only.

## Bug found and fixed first: same-line label misattribution

`list_slices()` searched backward for a romslice's owning label starting at
`i - 1`, one line ABOVE the `.incbin`. An incbin sharing its own line with its
label (`Label:\t.incbin ...`) was silently attributed to the label BEFORE it.

Confirmed concretely: `CharMap_ValueData_A` (already real `.byte` data, two
lines above an incbin) was reported as the owner of a romslice whose actual
bytes -- verified against the raw v7 ROM dump -- belong to
`CharMap_ValueData_B`, the label on the incbin's own line. Every downstream
consumer (run-extent, my header-value check) inherited the wrong name and the
wrong v9/v10 comparison target. Fixed in `5d96ff56` by checking line `i`
itself first; both JSONs regenerated (167 DATA-kind slices, 71,301 B, changed
from 180/71,520 B).

## Method: `v7_slice_split_plan.py`

For each UNSAFE run-extent verdict:

1. **Header value check**, not just count: reconstruct the literal bytes the
   v9/v10 header directives encode and compare byte-for-byte against the v7
   slice's own raw bytes, requiring >=60% similarity (not 100%) -- tolerating
   real cross-revision payload drift. Confirmed instance:
   `VoiceMode_ParamConfigTables` differs from v9 in exactly 1 byte of 264
   (0xcc vs 0x97), a genuine per-revision config value, not a wrong region.
   A `.long` header whose operands are bare symbols (a pointer/jump table)
   cannot be value-checked this way and is refused outright --
   **33 slices / 21,956 B**. Checked concretely for the two largest
   (`TuningSystem_Handler_Table` 9,252 B, `SoundEffect_Dispatch_Table`
   5,156 B): their raw v7 4-byte words are not even plausible ROM addresses
   (values like `0x020f6406`, far outside `0xE00000-0xFFFFFF`), so this is
   not merely "can't check a pointer" -- the region does not hold the same
   structure in v7 at all. Correctly refused.
2. **Bounded local search** (+/-32 B around the v9/v10 run length) for the
   offset where the tail round-trips through llvm-mc byte-exact with zero
   decode warnings.
3. **Trivial-opcode fraction guard**: reject any candidate where >=20% of
   decoded instructions are `nop` (0x00) or `swi N` (a fixed one-byte
   opcode either way, so a run of them round-trips no matter what the bytes
   actually mean). This is what caught the two most important false
   positives found this session:
   - `KeyScaleNoteStr_G` -- already documented in
     `v7_slice_code_roundtrip.py` as a confirmed false positive. Its v9 body
     right after the 6 B data header is a short code stub *immediately
     followed by an `aligned_string` macro*; the `\0`/`\xff` padding between
     short strings decodes into a long nop/swi chain that passes a naive
     round trip. Independently rediscovered here from v7's own raw bytes
     (`47 20 00 ff 20 20 | 20 20 00 ff | 3c 25 73 3e 00 ff | ...` -- literally
     `<%s>\0\xff` and other short strings), before checking the existing
     note.
   - `Rhythm_SeqResetTable` (95% trivial) and `AccPatch_ChannelToParamTable`
     (83% trivial) -- both mostly-zero sparse data tables, not code.
4. Named-boundary check (does a real label sit at the v9/v10 offset?) is
   recorded but was 0/26 for this batch -- every accepted split point is
   positional-only (`<Label>_Code`), not corroborated by a pre-existing name.

## Result

**26 of 153 unsafe slices split and converted: 1,108 B** (header + code, both
independently verified), across 5 commits, gate green after each:
`292e4095`, `455c5a5d`, `897866ed`, `8eb7d845`, `0be58244`.

**Could NOT convert, with reason:**

* **33 slices / 21,956 B** -- `SYMBOLIC_HEADER`, refused for cause (see above).
* **94 slices / 46,570 B** -- `NO_OFFSET_FOUND`: no offset within the search
  window round-trips through llvm-mc clean of decode warnings AND below the
  trivial-opcode threshold. This matches `v7_slice_code_roundtrip.py`'s
  already-documented finding for CODE-labelled v7 romslices ("0 decode
  warning-free above ~50 B") -- the pinned tlcs900 backend's spelling gaps
  (DEBT-INVENTORY's "9,463 unspellable instances") block whole-tail
  conversion for anything beyond a few dozen bytes in most of these. This is
  an orthogonal, already-known backend limitation, not a flaw in the split
  method: a longer tail fails if even ONE instruction inside it doesn't
  round-trip, and this ROM's remaining unconverted code is disproportionately
  where the backend's coverage is thinnest.

## Corroboration

* `verify_converted_call_targets.py --tag v7 --git-diff 3d0041aa HEAD`:
  30 distinct call/calr targets, **23 hit / 7 miss (77%)** against routines
  already named in the tree before this session.
* `v7_call_target_boundary_audit.py`: of those 30, **23 exact-label hits + 6
  land on a real instruction boundary = 29/30 (97%) corroborated**. The one
  exception, `0xf65da9` (+4 into `TimeSig_DisplayStrings_0x8A0`), is a `call`
  inside `CmpSetTtl_Dispatch2`'s converted tail whose target address is baked
  into the original ROM bytes (not synthesized by this conversion); the
  misalignment is in how `TimeSig_DisplayStrings` -- an unrelated,
  pre-existing region in a different file -- is labelled, not evidence this
  session's split point is wrong. Left as an open note rather than reverted:
  reverting would only hide the same `call 16145833` back inside an
  unaudited `.incbin`.
* Retroactive lda-audit (the check that caught six bad conversions elsewhere
  in this push): grepped the whole v7 tree for any `lda*` instruction loading
  one of the 26 new `<Label>_Code` symbols. **Zero hits** -- none of this
  session's new code labels are jump-table targets.

## Narrow gate

`make rebuilt_ROMs/kn5000_v7_program.llvm.rom` then `cmp` against
`original_ROMs/kn5000_v7_program.rom`: green after every commit, confirmed
again at the end of the session.

## Reproduce

    python3 scripts/analysis/v7_slice_v9v10_correspondence.py
    python3 scripts/analysis/v7_slice_data_run_extent.py
    python3 scripts/analysis/v7_slice_split_plan.py
    python3 scripts/converters/apply_v7_slice_splits.py            # dry run
    python3 scripts/converters/apply_v7_slice_splits.py --apply    # writes
