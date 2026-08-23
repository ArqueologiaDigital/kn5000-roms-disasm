# Where are the ranges the converter refuses with "entry is in no indexed `.byte` block"?

`scripts/converters/convert_reachable_ranges.py --apply` ends its report with

```
refused   39  entry is in no indexed .byte block and in no located .incbin
... 3,430 bytes behind: entry is in no indexed .byte block and in no located .incbin
```

The counter says the entry could not be *placed* in the sources. It does not say where those
bytes actually are, and `scripts/analysis/README-rewrite-refusals.md` could only guess
("runs separated from their anchor by instruction lines"). These probes settle it.

Every script here is READ-ONLY with respect to the repo. `sim.py` and `sim_rounds.py` apply the
converter to a private COPY of `v7/maincpu` and refuse any write outside their sandbox.

Scratch output (a 15 MB pickle, the tree copies) goes to `$KN5000_PROBE_DIR`, default
`$TMPDIR/kn5000-byte-run-placement`. Nothing is written into the repo.

## The answer, measured 2026-08-23 (commit `28bbfe1` + working tree)

| what holds the entry | ranges | bytes |
|---|---:|---:|
| a `.byte` run with **no label of its own**, separated from the previous run by INSTRUCTION lines | 37 | 3,404 |
| the interior of an `aligned_string "..."` **macro invocation** — i.e. an ASCII string | 2 | 26 |
| an `includes/generated/` blob | **0** | **0** |

`0xE000ED` is offset 21 into `FILETYPE_SIG_TABLE_2:  aligned_string "Technics KN5000 Table    DATA
FILE 2/2"` and decodes as `ld W,0x20 / ld XIX,0x20415441 / ld XIZ,0x20454c49` — the immediates are
the ASCII of `DATA` and `FILE`. `0xED10C5` is offset 9 into `"   FILL IN 2    "`. Those two are not
a placement problem; they are call targets that are not code, and no placement rule should reach
them.

The `generated/` question belongs to a DIFFERENT counter — `.incbin slice(s) that are generated/,
not a committed romslice`, 4 ranges / 48 bytes, all four inside
`v7/maincpu/includes/generated/tonekit_param_blocks.bin` (built from
`v7/maincpu/ui_widgets/tonekit_param_blocks.c`), included from `ui_widgets/widget_dispatch.s`.
Their bytes are `00 00 63 00 48 | 00 00 00 63 00 49 | ...` — six-byte records, not instructions.
Splitting that blob would fork the data from the C it is compiled from; the converter is right to
refuse, on the scope rule and on the merits.

## Why the 37 have no address, and the rule that gives them one

`convert_corroborated_blocks.blocks_of()` can address a `.byte` run only when a label the ELF knows
sits immediately above it, and `source_index()`'s cursor (Fix A) extends that to a run separated
from the previous run by **blank or comment lines only**. All 37 sit in runs preceded by an
INSTRUCTION line (`ret`, `ld D,W`, `call ...`), so neither rule applies.

**The rule that reaches them is the one `incbin_index()` already uses for `.incbin` directives,
generalised to every source line: label a COPY of the tree, assemble and link it with the real
`maincpu.ld`, and read the addresses out with `llvm-nm`.** `line_locator.py` does exactly that.

Corroboration, not assumption: of the 6,394 blocks `source_index()` addresses today by label
arithmetic, the assembler agrees with **6,393**. The one disagreement is a defect in the label rule
(below), not in the map.

## Measured yield

| | ranges | bytes |
|---|---:|---:|
| index: `.byte` runs that gain a ROM-verified address | +5,454 runs | +64,165 |
| ranges converted, round 1 | 21 | 2,045 |
| ranges converted, round 2 | 10 | 991 |
| ranges converted, round 3 | 3 | 197 |
| round 4 | 0 | 0 (fixpoint) |
| **total** | **34** | **3,233** |

and at every round the copy rebuilds (`llvm-mc | ld.lld -e 0 | llvm-objcopy -O binary`) to a ROM
that is **byte-identical to `original_ROMs/kn5000_v7_program.rom`**.

⚠ Rounds 2+ are INDICATIVE, round 1 is exact. `v7_undisassembled_spans.runs()` assembles with
`cwd=l1.ROOT`, a hard-coded path to the real repo, so the territory map the converter decodes
against always describes the REAL tree no matter where the sandbox is. Round 1 starts from a
verbatim copy, so its input is right; from round 2 the sandbox has moved and the territory map has
not, which is why the refusal bucket REFILLS to 3,259 bytes at the fixpoint — that is 3,233 bytes
of already-converted ranges being re-offered plus the 26 bytes of ASCII, not a backlog.

⚠ The control matters: run on this tree **as committed**, `--apply` converts **0 ranges** — every
range that has a block is refused by the never-drop-a-label guard, and the 39 above have no block.
`--dry-run` reports 33 ranges / 2,278 bytes for the same tree because it counts a placed range as
converted without calling `rewrite()`. Use `--apply` on a copy, not `--dry-run`, to measure a yield.

## One range per run per pass

After the fix, 13 ranges / 1,188 bytes move to `replaced span holds a non-.byte, non-label line`.
Every one of them shares a `.byte` run with a range at a HIGHER address that was applied first
(the apply loop goes bottom-up): the earlier splice put instruction lines inside the run, and the
block record still claims the whole run. So a pass converts at most one range per run, and the
rest come back on the next pass — which is what the round-by-round numbers show.

## A latent defect this exposed: `LABEL:` on a line that also emits bytes

`blocks_of()` matches `^\s*\.byte`, so `MSP_Default_VarIndex:\t.byte 0, 1, 2` is not a `.byte`
line: its 3 bytes are dropped from the run and its label is attached to the NEXT run, whose
address is then too low by exactly those bytes. 23 blocks in `v7/maincpu` have this shape.
`source_index()`'s ROM check catches 22. It does **not** catch
`sequencer/composer_msp_defaults.s:135`, index `0xE16106` vs assembler `0xE16109`, because the run
is `00 01 02 00 01 02 ...` and matches the ROM at both addresses. That block is in the index today
with a wrong address; nothing currently places a range there (no call target in `0xE16000-0xE17000`),
so it is latent, not active. The assembler-derived map removes the whole class.

## The scripts

| script | the question it answers | command |
|---|---|---|
| `line_locator.py` | what ROM address does each source LINE have? | `python3 tools/byte-run-placement/line_locator.py` |
| `dump_unplaced.py` | which ranges land in the refusal bucket, and how many bytes? | `python3 tools/byte-run-placement/dump_unplaced.py` (runs the converter `--dry-run`, ~7 min) |
| `locate_unplaced.py` | which FILE, LINE and construct holds each refused entry? | `python3 tools/byte-run-placement/locate_unplaced.py` |
| `why_no_block.py` | why does that run have no address — no label, symbolic byte, ROM drop? | `python3 tools/byte-run-placement/why_no_block.py` |
| `validate_linemap.py` | does the assembler map agree with the label arithmetic, and what would it add? | `python3 tools/byte-run-placement/validate_linemap.py` |
| `label_line_bug.py` | which blocks does `blocks_of()` address WRONGLY, and does the ROM check catch it? | `python3 tools/byte-run-placement/label_line_bug.py` |
| `sim.py` | what does the rule actually convert, and does the ROM still rebuild? | `python3 tools/byte-run-placement/sim.py base` then `... sim.py augment` (~7 min each) |
| `sim_rounds.py` | what does it converge to, gating every round? | `python3 tools/byte-run-placement/sim_rounds.py 5` (~30 min) |
| `final_table.py` | the per-range evidence table (entry, run, run address, outcome) | `python3 tools/byte-run-placement/final_table.py` |
| `compare_outcomes.py` | control vs proposal, bucket by bucket | `python3 tools/byte-run-placement/compare_outcomes.py` |

Order: `line_locator.py` -> `dump_unplaced.py` -> the rest (they read the pickles those two write).

⚠ `sim_rounds.py` must set `mod.REPO = SIM`. Without it the converter indexes — and would WRITE —
the real `v7/maincpu`. The first version of this rig omitted it and only escaped writing to the
repo because every range with a real-tree block happened to be refused. The guarded `open` now
raises on any write outside the sandbox.
