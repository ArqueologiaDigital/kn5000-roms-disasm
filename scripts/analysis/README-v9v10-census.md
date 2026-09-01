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
scope for the time available.
