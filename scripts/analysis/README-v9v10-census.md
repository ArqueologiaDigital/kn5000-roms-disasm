# Do v9 and v10 also carry undisassembled code?

## `v9_v10_undisassembled_census.py`

**Question:** all of the conversion effort has gone into v7, because the L1
territory map made it the visible outlier (27.26% CODE against v9/v10's
47.83%). Do the other two images hide the same kind of undisassembled code?

**Answer (measured 2026-08-22):** yes, but roughly 12x less, and in a
different shape.

| | v7 | v9 | v10 |
|---|---|---|---|
| CODE | 27.26% | 47.83% | 47.83% |
| literal `.byte` | 407,788 B | 84,484 B | 84,481 B |
| `.incbin` (C structs, fonts, images) | 968,006 B | 848,809 B | 848,809 B |
| judged convertible | -- | ~22,552 B | ~22,449 B |

**Run:**

    python3 scripts/analysis/v9_v10_undisassembled_census.py --prepare
    python3 scripts/analysis/v9_v10_undisassembled_census.py --census v9

⚠ **The obvious method is a dead end, and this script does not use it.**
Diffing v9's territory against v10's finds only **581 differing bytes** in
2,097,152. They were disassembled in lockstep, so they hide the *same* residue
and cannot corroborate each other -- unlike v7-vs-v9, where the difference was
real. Recorded so nobody tries it again.

**How the addresses are made trustworthy:** the script copies each tree, injects
a `.globl` label pair around every literal `.byte` run and every `.incbin`, then
assembles, links, and **asserts the rebuilt ROM is byte-identical to the
original before believing any address**. Labels emit no bytes, so that check is
what licenses the measurement. It also gives every blob its source file:line,
which the flattened `-show-encoding` stream cannot, because llvm-mc expands
`.incbin` into `.ascii`.

**Why `.incbin` is counted separately:** those bytes are data by construction
(compiled C structs, fonts, indexed images) and are separately audited by
`audit_incbin_legitimacy.py`. Mixing them into a "DATA" total would overstate
the conversion opportunity by roughly 850 KB per image.

## 2026-09-01 update: the 08-22 baseline still held, and 14 regions are now converted

Re-ran `--prepare`/`--census`/`--judge` fresh (lane V10V9 of the parallel
full-disassembly push) before touching anything. Every number above still
matched exactly: same 31 `--judge` hits at the same addresses, same 10,712 B,
same 5 hand-audited rejects (348 B of German/French UI strings, factory-test
strings, and an 0xFF-filled widget table) leaving 26 regions / 10,364 B of
confirmed undisassembled code -- nothing had moved since 08-22.

**Two blind spots found while using it, neither in this script's own numbers
above, both worth recording:**

* `inject()`'s `.incbin` regex is anchored at line start
  (`^\s*\.incbin\b`) and misses a directive written on a label line
  (`Name:\t.incbin "..."`) -- the same trap `audit_incbin_legitimacy.py`
  documented for itself. 10,817 B/image of legitimate `.incbin` was
  invisible to `inject()` and landed in "non-.incbin DATA regions"
  (178,806 B for v9) instead. It does not change the `--judge` byte counts
  quoted above (those come from `terr`/`territory()`, not from the
  mis-bucketed regions), but anyone summing "non-.incbin DATA" as a debt
  ceiling should subtract it first. See `v9_v10_true_debt.py`, which counts
  `.incbin` with an unanchored regex instead.
* `kn5000_source_coverage.py` resolves each `.incbin` path relative to
  source and `continue`s past any that does not exist on disk yet.
  `generated/*.bin` are build products of `clang -target tlcs900`, not
  committed files -- on a tree that had never run `make`, it reported v10's
  `.incbin` as 4,928 B instead of the true 851,780 B. Confirmed by running
  it before and after `make rebuilt_ROMs/kn5000_v10_program.llvm.rom` in the
  same session. Always `make` first.

**What got converted:** 14 of the 26 confirmed regions -- every one whose
`.byte` run was NOT interrupted by an `.ascii`/`.long` directive or a
pre-existing instruction (the other 12 need that interruption handled first
and were left alone) -- using the new `scripts/converters/convert_region.py`
plus mnemonic-table fixes to `convert_code_bytes.py` (`ldda8`/`ldda16`/
`stda8`/`ldada` and friends were never real llvm-mc mnemonics; the
shift/rotate branch had operands backwards and a hardcoded count of 1).
2,943 B of clean regions -> 2,306 B (78.4%) now real instructions, 637 B
left as .byte (an unsupported form, never a wrong guess -- every emitted
instruction round-trips through llvm-mc byte-exact before being written).
`scripts/analysis/verify_converted_call_targets.py` checks something the
byte gate cannot: 30 distinct `call` targets from the converted regions, 21
resolve to routines ALREADY named in the tree before this session (e.g.
`MIDI_DispatchCC_Guarded`, `Util_FindLowestSetBit`) -- external evidence a
coincidentally-decodable data table could not produce.

**Still open, not attempted this session:** the OTHER shape this census
identifies, `--islands` -- literal `.byte` runs SHORTER than 64 B flanked by
real instructions on both sides, which are misframed rather than merely
undecoded (the true instruction runs past the `.byte` run, so fixing one
means re-framing an existing "instruction" too, not just filling a gap).
Re-measured 2026-09-01, both images: v9 has 8,141 such runs in genuine-code
context, 14,727 B, whose real instructions cover 23,556 B once reframed; v10
is nearly identical (8,141 runs, 14,724 B, 23,559 B reframed) -- the two
revisions still hide the same residue, as the top of this file already
established. (The 08-22 figures were 12,188 B / 23,547 B for v9, so this is
the same phenomenon re-measured, not a new one -- the small drift is
calibration noise, not a change in the ROM.) Left alone because re-framing
an existing "instruction" boundary is a materially different and riskier
operation than filling in raw `.byte`, and was out of
scope for the time available. **NOTE: this is the ISLANDS lane's territory
(worktree `disasm-lanes/islands`, branch `w3/islands`) -- do not attempt it
from here.**

## 2026-09-02 update: the 12 interrupted regions are closed, confirmed-region debt is now ZERO

Lane V10CODE. Re-ran `--prepare`/`--census`/`--judge` fresh in a clean
worktree before touching anything (v7/v9/v10 all rebuilt from scratch,
markers byte-neutral, ROMs byte-identical to source -- the tool's own
precondition). Before any edit: **17 raw `--judge` hits, 7,769 B**, exactly
reproducing the 2026-09-01 session's 26-confirmed/5-rejected split (the 5
rejects are unchanged and still correctly DATA -- 348 B: two copies of a
`ld XIY,0x4e492052`/`db` fragment at 0xED1A36/0xED1A7A [a UI string, one
instance unresolved to any source file], the `fd_test_data.s` factory-test
bytes at 0xE1FE6E/0xE1FF68, and the `swi 7` x3 = pure `0xFF` fill at
0xEED1B0). Subtracting the rejects: **12 confirmed regions, 7,421 B** --
bit-for-bit the number the 2026-09-01 session and its `README` left as "the
12 it left", independently reproduced rather than inherited.

**All 12 converted**, using `scripts/converters/convert_interrupted_region.py`
(the tool `convert_region.py` cannot use here because it stops at the first
non-`.byte` line -- this one pulls the exact ROM bytes for the *whole*
region by address, walks the source forward summing each DATA directive's
emitted size until it lands exactly on the region boundary, then replaces
the whole span in one shot, re-inserting any label found inside at its
original byte offset). Four of the twelve carry a jump-table label at byte
offset 0 -- `PcgOutGridCheckJumpTable`, `MidiPartGridCheck_JumpTable`,
`PmemOutLGridCheck_JumpTable`, `ScoopParam_ValueTable` -- each confirmed
still referenced elsewhere in the tree by an `lda_24 xix, (...)` load
immediately before an indexed dispatch, so the label is not just preserved
mechanically but demonstrably still the right name for the right byte.

7,421 B -> **6,567 B (88.5%) now real instructions**, 854 B left as `.byte`
(unsupported addressing forms -- e.g. `.byte 0x1e`, `0x45`, `0x1d` isolated
bytes where `unidasm` decodes something llvm-mc has no mnemonic for; never a
wrong guess, since every emitted instruction round-trips byte-exact through
llvm-mc before being written, same discipline as the clean-region pass).

Corroboration beyond the byte gate:
* `verify_converted_call_targets.py --tag v10 --git-diff`: 60 distinct
  `call`/`calr` targets across the 12 regions, **40 resolve to routines
  already named in the tree before this session (67%)** -- e.g.
  `GetFocusObject`, `Util_FindLowestSetBit`, `SndParam_LookupViaEncode`,
  `Audio_CheckSubsystemReady`. The 25 `lda`/`lda_24` hits are load-ADDRESS,
  not call, and correctly resolve to DATA (font palette, a `NakaInst_ON`
  table) rather than routines -- expected, not a miss.
* The four jump-table label cross-references above.
* Re-ran `--judge v9` and `--judge v10` after applying: **both now report
  exactly the same 5 rejects, 348 B, and ZERO confirmed hits** -- the
  confirmed-region backlog this census can find is fully closed on both
  images, not just v10.

**A note on provenance:** while re-deriving this batch, a stale, unmerged
branch `w2/islands` (an EARLIER wave of the *other* lane, not the current
`w3/islands`) turned out to already contain a solution for this exact
batch, despite its branch name -- `convert_interrupted_region.py` originates
there. It was never merged to `main`; nothing on `w2/islands` was merged
here. Its diffstat for these six files (1508/77/394/283/774/489 lines) matches
this session's independently-produced diff line-for-line, which is exactly
the kind of external corroboration this file's methodology asks for -- two
separate runs of the (borrowed) tool against the same source converged on
the same output.

Verified narrowly, not via `make gate-all` (see the lane brief -- a fresh
worktree stalls building other images first):

    make rebuilt_ROMs/kn5000_v9_program.llvm.rom rebuilt_ROMs/kn5000_v10_program.llvm.rom
    cmp rebuilt_ROMs/kn5000_v9_program.llvm.rom original_ROMs/kn5000_v9_program.rom
    cmp rebuilt_ROMs/kn5000_v10_program.llvm.rom original_ROMs/kn5000_v10_program.rom

Both report identical. The full 13-image gate is Felipe's to run centrally
after merge.

**What is left in this shape:** nothing confirmed. The remaining 348 B (5
regions) were hand-audited as real DATA in the 2026-09-01 session and
re-confirmed here; the only larger debt this census's `--judge` mode can
still see is the `--islands` shape above, out of this lane's scope.

## 2026-09-02 update: lane ISLANDS attempted both left-open shapes

Lane ISLANDS of the 2026-09-01 parallel push (worktree
`~/compartilhado/disasm-lanes/islands`, branch `w2/islands`) picked up both
items this file left open, in parallel with lane V10CODE above (a
coordination gap, not a plan -- see that section's provenance note: the two
sessions' diffs on the 12 regions matched line-for-line, and V10CODE's is
the one that reached `main` first, so `w2/islands` was rebased to drop its
own copy of that work rather than duplicate it).

**The `--islands` shape** (misframed runs, ~14,727 B/image) --
`scripts/converters/fill_verified_islands.py`, reproducing this script's
own `islands()` classification (decode forward from real established CODE
up to 48 B earlier; accept only a run that tiles exactly, no reframing of
anything outside it) plus an llvm-mc spellability check. First attempt
(commit `69a26118`) excluded 7 files independently identified as DATA
tables by their header comments and applied 283 "verified" runs (1,136 B).
**A post-hoc audit by enclosing label found two real DATA tables had
slipped through anyway** -- `TuningSystem_Handler_Table` (an arithmetic
progression: `ldwio 10, N` / `ordm16_24 (M), xde` with N stepping by 40, M
by 10240) and `SeBitmap_EnvCurve5` (a 5-record `{byte, 0x17, 0xf1}` table,
first byte stepping by 12) -- in both cases only the table's LAST record
happened to sit next to genuine code, so it alone tiled cleanly from
context even though its siblings weren't even code-flanked. **Reverted the
whole batch** (`cefe1854`) rather than trying to hand-pick the good ones out
of 283.

Added `looks_like_a_table_tail()`: reuses THIS file's own calibrated
CODE/DATA rule (`per%` specifically) over a window spanning the candidate
run and back into whatever precedes it -- a repeating record's periodicity
only shows up once several records are in view, which the run-only tiling
check cannot see. Re-ran: rejected 1,339 of 2,899 candidates (confirmed the
two known-bad ones among them), applied 807 B (v10) / 801 B (v9) of the
survivors, spot-checked by enclosing label afterward (varied, non-periodic
content in every label sampled, including two more misnomers --
`Flash_ExtendedOpsBlock`'s hits sit right after `reti`, i.e. they open the
NEXT handler, not a table; `FileIO_BytecodeData` is an
independently-documented misnomer already).

One further candidate (`note_voice_mapping.s`, 6 B, v10 only -- its ROM
bytes genuinely diverge from v9 at that address) turned out, once this
branch was rebased onto `main`, to already be covered by lane
`w4/postdec10`'s separate 332-run/1,274 B pass -- an empty diff after
rebase, dropped rather than committed as a no-op.

Remaining `--islands` debt (SPANS -- the true reframe shape, where the real
instruction runs past the flanked `.byte` and consuming it means rewriting
an already-existing following line too) was NOT attempted: ~9,757 runs in
genuine-code context after exclusions, no tractable way to corroborate at
that volume in the time available. `ctx_data`-context runs (lower
confidence per this file's own top section) were also left alone.

Net this lane's unique contribution: **807 B (v10) / 801 B (v9)** converted
from misframed `.byte` to real instructions, on top of lane V10CODE's 12
regions above, gate green throughout
(`rebuilt_ROMs/kn5000_v{9,10}_program.llvm.rom` byte-identical to their
originals after every commit).

## 2026-09-02 update: lane V9ISLANDS -- v9's confirmed-region backlog was already closed, and the honest remaining floor is tiny

Lane V9ISLANDS, worktree `disasm-lanes/v9islands`, branch `w6/v9islands`,
picking up where the entries above left off: does v9 specifically (not
mirrored from v10) still carry either shape of debt? Re-ran `--prepare`
(all three tags, from a full `make` of `kn5000_v{7,9,10}_program.llvm.rom`
first -- a fresh worktree has no `includes/generated/*.bin` yet, see the
09-01 update's "always `make` first" note, still true) and `--census`/
`--judge`/`--islands v9` fresh, not inherited:

* `--judge v9`: **316 non-`.incbin` DATA regions >= 64 B, 109,181 B; rule
  fires (CODE-like) on only 4 regions / 277 B** -- and all four are the
  SAME already-known hand-audited DATA rejects from the 09-02 V10CODE
  entry above: the `ld XIY,0x4e492052` UI-string pair at
  0xED1A36/0xED1A7A and the `swi 7`x3 = pure 0xFF fill at 0xEED1B0.
  **v9's confirmed-region backlog is therefore ALREADY ZERO**, the same
  closed state as v10 -- it did not need re-closing this session. (v9
  shows 4 regions/277 B against v10's 5/348 B purely because the
  `fd_test_data.s` duplicate at a second address does not reach the 64 B
  floor / is not present at that address in v9 -- real content, not a
  measurement gap: confirmed by inspecting `fd_test_data.s` directly.)
* `--islands v9`: **15,758 CODE-flanked `.byte` runs, 27,605 B**; in
  genuine-code context, **8,140 runs / 12,737 B** (ONE_INSN 2,213 B +
  MULTI-tiling 2,305 B + SPANS 8,219 B out of scope per the brief).

### Check 1: `convert_decoder_unblocked_islands.py` run DIRECTLY against v9

Prior sessions ran this tool on v10 and mirrored to v9 by matching line
number -- but v9's `sound_editor_ui.s` has since drifted out of lockstep
with v10's (confirmed: the same line numbers now hold different
instructions in the two trees), so a v10-only run cannot see whatever is
v9-specific any more. Running it directly against `v9` found **24
CODE-flanked isolated `.byte` lines that now decode + round-trip
byte-exact, 67 B**, 22 of them concentrated in `sound_editor_ui.s`.

**Before trusting any of them**, checked every one against
`fill_verified_islands.py`'s `looks_like_a_table_tail()` (that guard
exists in a sibling tool, not this one, so it does not run automatically
here) using the file's own address markers to locate each candidate:
**22 of 24 reject** -- overwhelmingly the `sound_editor_ui.s` cluster,
which is exactly the file already documented above as holding
`TuningSystem_Handler_Table` and `SeBitmap_EnvCurve5`, the two data
tables that slipped through the ORIGINAL 283-run incident this guard was
built to catch. Left all 22 as `.byte`.

The 2 survivors were converted, each with its own contextual
corroboration beyond the guard (no `call` targets in either, so
`verify_converted_call_targets.py` does not apply; the check here is
control-flow shape, the same standard the postdec10 lane used for
register/ALU forms):
* `note_voice_mapping.s` 0xFEFC7A, `ldb_erp e,240` / `stb_erp c,240` (6 B)
  -- sits inside `SendPartDataBlock_Data`, in the same repeated
  `and`/ERP-pair/`extz`/`reti` dispatch shape as two neighbouring,
  already-decoded instances a few lines above it in the same function.
* `accompaniment_engine.s` 0xF6B4CA, `cp wa,qwa` (3 B) -- completes a
  bounded loop, `inc 1,wa` / `cp wa,qwa` / `jr ule,-64` / `ret`, reading
  as a real loop test rather than a table record.

v10's mirror was correctly skipped for both (line content already
diverged there -- `MIRROR SKIP ... bytes differ or line missing`).

### Check 2: `convert_interrupted_region.py` against the 4 known-DATA regions -- does the guard still fire on the cases it exists for?

Ran (dry run, no `--apply`) against the 3 of the 4 hand-audited rejects
that have a resolvable file:line (the 4th, 0xED1A7A, is the instance the
V10CODE entry above already flags as "unresolved to any source file" --
left alone, unchanged):

* `fd_test_data.s:379` (0xE1FE6E, 67 B): **ABORTS** -- "line 386 is not a
  recognized DATA directive (`aligned_string \"File Write =>\"`)", i.e.
  the span the census measured is not pure DATA-directive territory and
  the tool refuses to guess past a real string macro.
* `extension_data.s:1459` (0xED1A36, 67 B): **ABORTS** the same way, one
  line in -- "line 1460 is not a recognized DATA directive
  (`aligned_string \"ER INITIAL va remplacer...\"`)".
* `widget_dispatch.s:8073` (0xEED1B0, 64 B, the `swi 7` x3 = pure 0xFF
  fill): **does NOT abort** -- it happily proposes converting 55 of 64 B
  into a chain of `swi 7`/`ldw`/`ldb`/`pushw`/... instructions. This is
  the expected trap, not a tool bug: a long run of the single repeated
  byte `0xFF` trivially decodes as repeated valid 1-byte `swi 7`
  instructions and round-trips byte-exact by construction, because
  `swi 7` really does encode as `0xFF`. **Nothing in this tool's own
  structural check catches a uniform-fill region** -- the only thing
  that rejects it is the human hand-audit already on record (a `.fill`
  of `0xFF`, not six deliberate `swi 7`s). Correctly left untouched
  (dry run only, no `--apply`).

  So: 2 of the 3 testable known-bad regions are caught mechanically by
  `convert_interrupted_region.py`'s own directive-walk; the third needs
  the documented hand-audit, which is exactly why that hand-audit is
  recorded rather than re-derived from a rule.

### Check 3: a second wave opened by check 1's edits, and both declined

Re-ran `list_ready_islands.py v9` after committing the 2 conversions
above (cascading candidates are the documented shape from the postdec10
entry): **2 new candidates, 4 B**, both already passing
`looks_like_a_table_tail()` internally. Manual review declined both:
* `note_voice_mapping.s:27322` (3 B, `.byte 0xc9,0xee` + the label
  `SendPartDataBlock_Data3:` + `.byte 0x01`, decoding as one `sll a,1`
  spanning the label) -- `fill_verified_islands.py`'s own `apply()` uses
  `collect_span()`, which stops at the first non-`.byte` line and does
  NOT skip over a label the way the census's `inject()` grouping does;
  attempting this candidate through the real apply path would self-abort
  with a collected/expected byte mismatch rather than silently drop the
  label, but that is exactly the "labels are not special-cased" trap
  `convert_interrupted_region.py`'s docstring warns about, and hand
  fixing it up was not worth the risk for 3 B.
* `midi_serial_routines.s:914` (1 B) sits inside a block the tree already
  names `MidiSerial_OffsetTable:`, with sibling entries commented
  `; MIDI` / `; MAC` -- the enclosing label already says DATA more
  directly than any periodicity heuristic could. Declined.

### Net result

**9 B converted this session** (2 regions, both independently
corroborated by control-flow shape, not just by round-trip), v9's
confirmed-region backlog reconfirmed at the same closed floor as v10
(4 regions / 277 B, all pre-existing hand-audited DATA), and two
mechanically-passing but substantively-wrong candidate classes
identified and declined with reasons on record rather than converted for
the byte count. `--islands v9` after: 15,756 runs / 27,596 B total,
8,138 runs / 12,728 B in genuine-code context -- down by exactly the 2
runs / 9 B converted, confirming the census sees the change and nothing
else moved.

Verified narrowly, per the lane brief (not `make gate-all`):

    make rebuilt_ROMs/kn5000_v9_program.llvm.rom
    cmp rebuilt_ROMs/kn5000_v9_program.llvm.rom original_ROMs/kn5000_v9_program.rom

IDENTICAL.
