# What is inside the converter's two biggest refusal buckets? (2026-08-23)

`scripts/converters/convert_reachable_ranges.py` refuses ranges with

    "decoded fewer than 3 instructions"
    "no `ret`, and does not end at a code boundary"

They are the two largest range-count buckets and nobody had looked inside them.
`classify.py` answers the question the tally cannot: **why did each of those
decodes stop where it did, and is there code there at all.**

| script | question it answers | command |
|---|---|---|
| `classify.py` | For every range in both buckets: what made the decode stop, is the stop a property of the BYTES or of the tooling, and what is the data-shape evidence for and against it being code? | `python3 tools/spelling-probes/refusal-buckets/classify.py` |
| `classify.py --closure` | Same, over the branch-closure target list instead of the call-target seed. | `... classify.py --closure` |
| `classify.py --spelling` | If both gates were relaxed, would the SPELLING loop refuse these anyway, and on which forms? | `... classify.py --spelling` |
| `classify.py --dump out.tsv` | The per-range table behind every number above, one row per refused range. | `... classify.py --dump /tmp/b.tsv` |
| `_cache.py` | none on its own -- memoises `decode_range()` output and the full unidasm listing, fingerprinted against the ROM and the territory map. | imported |

READ-ONLY. `--apply` is never invoked. `crr.main()` is called once, with
`decode_range` replaced by the cache, purely to re-derive the official bucket
counts and **assert** they equal this script's membership; that assertion is the
part that can fail.

## The answer, measured 2026-08-23 at `c8e9ec4`

Provenance, because every input here moves (see below):
`v7_call_targets.json` 659 entries sha256 `baed0688c44d04ce`,
ROM sha256 `e7ae0cb76d5111dd`.

**B1 — "decoded fewer than 3 instructions", 169 ranges**

| cause | hyp | ranges | bytes decoded | bytes past the stop |
|---|---|---|---|---|
| C-SHORT-STUB — 1-2 instructions ending in an UNCONDITIONAL `ret`/`reti`/`retd` | (c) | 35 | 92 | 23,587 |
| D-COND-RET-STOP — stopped at a CONDITIONAL `ret <cc>`, which does not end a routine | (d) | 20 | 120 | 5,035 |
| D-TILES-INTO-CODE — the decode consumes the whole run and abuts real code | (d) | 40 | 202 | 0 |
| D-OVERRUN — last instruction runs 1-4 B past the run boundary | (d) | 9 | 43 | 0 |
| D-TRUNCATED-BUFFER — 1-4 B left at the boundary, too few to finish an instruction | (d) | 25 | 5 | 36 |
| B-UNDECODABLE — mid-run `db`, and llvm-mc refuses the same bytes | (b) | 40 | 57 | 88,487 |

**B2 — "no `ret`, and does not end at a code boundary", 160 ranges**

| cause | hyp | ranges | bytes decoded | bytes past the stop |
|---|---|---|---|---|
| D-OVERRUN | (d) | 33 | 4,893 | 0 |
| D-TRUNCATED-BUFFER | (d) | 23 | 2,039 | 31 |
| B-LLVM-DECODER-BUG | (b) | 1 | 11 | 60 |
| B-UNDECODABLE | (b) | 101 | 6,630 | 274,129 |
| B-RUNAWAY — ran to the 16,384 B cap with no terminator and no `db` | (b) | 2 | 32,768 | 193,483 |

⚠ **"bytes decoded" and "bytes past the stop" are different quantities and are
never summed.** The first is what a range would contribute if accepted; the
second is how much of its run lies beyond the stopping point — an upper bound on
what removing the blocker could reach, and only if those bytes are code.

### Hypothesis (a) — a form the tooling cannot spell: **ZERO ranges**

Both buckets are decided **before** the converter tries to spell anything, so a
missing LLVM assembler form cannot be the cause of a refusal here. The analogous
blocker is the DISASSEMBLER, and it was tested: every mid-run `db` is either
refused by llvm-mc's independent TLCS-900 disassembler too (141 ranges), or
decoded by it into text llvm-mc's own **assembler rejects** (1 range: `e8 33` at
`0xED32F3` reads as `bit 13, xwa`, which will not assemble). The round-trip gate
is the only thing separating those two, and without it this probe would have
reported an actionable "missing form" that does not exist.

The top blockers, ranked by bytes past the stop, are `ee 00`, `55`, `54`,
`ec 00`, `80 00`, `50`, `1f` — all of them main-table or sub-table entries MAME
marks `M_DB` and llvm-mc also refuses. `0x50..0x57`, `0x1F` and `0xC6/D6/E6/F6`
are reserved slots in the TLCS-900/H map.

### Hypothesis (c) — rejections the `< 3` threshold makes on its own

* **33 ranges / 86 B** are 1-2 instructions ending in an unconditional
  terminator with no data-shape flag: `FDC_STATUS_COPY` = `ld (0x8988),(0x898a) ;
  ret`, `FDC_Send_Command` = `ld (0x110008),A ; ret`, `Boot_ReadFDCStatus` =
  `ld L,(0x8dce) ; ret`. 2 more end in a terminator but carry a flag.
* **38 ranges / 199 B** are 1-2 instructions that tile their run exactly and abut
  code — the converter's own `ends_at_code` rule would take them at 3.
* **20 ranges / 120 B look like (c) and are NOT.** They stop at a *conditional*
  `ret <cc>`, after which execution continues. `decode_range` matches
  `TERMINATORS` on the mnemonic alone, so `ret Z` truncates a decode exactly as a
  bare `ret` does — the same mistake `UNCOND_JUMP` was written to avoid for `jr`,
  on the other side of the same test. Raising the threshold would convert two
  instructions of a longer routine and stop there.

### Hypothesis (d) — the decode does not tile the run

90 ranges (42 D-OVERRUN + 48 D-TRUNCATED-BUFFER) miss the boundary by **1-4
bytes**: 12/16/11/3 ranges overshoot by 1/2/3/4 B, and 32/14/1/1 fall short by
1/2/3/4 B. `next terr` is `CODE` for all 90, so the decode and the existing
sources disagree about where an instruction boundary is. The probe does not say
which side is wrong. Two mechanisms produce the same fault: **unidasm zero-pads
past the end of its input file**, so `decode_range` can return an instruction
built partly from bytes that are not the ROM's (`0xFD5021` ends `call 0x00afa2`
where the ROM holds `call 0x00FDAFA2`), and when the padding does not decode it
prints `db` instead — 48/48 of those decode cleanly when given 64 real ROM bytes.

### Hypothesis (b) — not code

141 B-UNDECODABLE + 1 B-LLVM-DECODER-BUG + 2 B-RUNAWAY. The positive evidence is
the `ptrtable` column: **44 of the 329 refused ranges** sit on (or one byte
inside) a run of little-endian `.long` ROM addresses. `0xED77ED` is one byte
before `00ED3598, 00ED35BE, 00ED35EC, 00ED3618`; `0xED32F3` one byte before
`00ED340C, 00ED33FA, 00ED33E8, ...`. Both are branch/call "targets" that landed
mid-entry in a pointer table.

## Controls, and one that FAILED

* `ptrtable` — 44/329 measured, **0/329** on the same ranges with their own first
  64 bytes shuffled, **2/617** on CODE-territory addresses. Separates.
* `ascii` — 4/329 measured against **3/329** shuffled. **Does not separate**, so
  no conclusion here rests on it. The column is kept visible rather than deleted,
  because a rule that fails its control has to be seen to be distrusted.

The controls are chosen to be capable of failing (anti-pattern 10): a uniform
u32 lands in `0xE00000..0xFFFFFF` with probability 1/2048, so uniform noise could
not have exposed a loose pointer rule; a byte-shuffle of the real ranges can.

## What the classifier CANNOT distinguish

* **B-UNDECODABLE is not proof of data.** It means "no instruction under either
  decoder at that offset". A mis-framed entry into real code has the same
  signature, and the probe cannot separate the two.
* **C-SHORT-STUB is not proof of code.** Anti-pattern 13: two bytes of a table
  containing a `0x0E` decode as something ending in `ret`. The `implausible` and
  `ptrtable` columns are the only counter-evidence offered.
* **A-DECODER-GAP would prove disagreement, not correctness.** Which decoder is
  right is a question for the Toshiba manual.
* **`next terr` cannot say which side of a straddling instruction is wrong** —
  the entry point, or the existing disassembly's boundary.

## ⚠ Every input to this moves, and it moved twice while this was written

`v7_branch_closure_targets.json` went 1,131 → 1,109 entries in ten minutes; then
an `--apply` round landed and `v7_call_targets.json` went 687 → 659, taking
bucket B1 from **200 ranges to 169** with no script changing. The 200/160 figures
that prompted this investigation therefore describe a tree that no longer exists;
re-deriving them needs a worktree at the older commit and a full build of it
(anti-pattern 14).

So: `classify.py` prints the targets file's sha256 and entry count, the ROM's
sha256 and both decoder paths in its header, and `_cache.py` fingerprints both
pickles against the ROM and the territory map and **discards** a cache built
against a different tree rather than serving stale decodes. A count from this
probe quoted without that provenance triple beside it is a count about an unknown
tree.

For the record, the same run over the branch-closure list (1,077 entries, sha256
`601f59baf1bf5a3f`): B1 253 ranges — C-SHORT-STUB 68, D-COND-RET-STOP 25,
D-TILES-INTO-CODE 51, D-OVERRUN 11, D-TRUNCATED-BUFFER 30, B-UNDECODABLE 68;
B2 228 ranges — D-OVERRUN 58, D-TRUNCATED-BUFFER 34, B-LLVM-DECODER-BUG 1,
B-UNDECODABLE 133, B-RUNAWAY 2. Hypothesis (a) is zero there as well.
