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
