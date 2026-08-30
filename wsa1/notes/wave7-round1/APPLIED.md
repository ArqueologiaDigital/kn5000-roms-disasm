# Which round-1 corrections have been applied

`README.md` in this directory is the skeptics' findings, generated from
`round1-results.json`. This file tracks what has been **done** about them. It is
hand-maintained; keep it short and keep it true.

Rule for this wave: **a correction is not applied until a check pins it.** Every entry below that
says "applied" added a self-test check, because the reason each of these errors survived in the
first place is that no check reproduced the number.

| lane | correction | status |
|---|---|---|
| a1 | 116 empty / 76 filled / 14 distinct in the 0xFAE3A2 table, not "88" | ✅ applied, 3 checks |
| a1 | 18 inline jump tables, not 19; ten in module 1, not eight | ✅ applied, 4 checks |
| a1 | 261 accept()-promoted bytes (3.7%), not "~306 (~4%)" | ✅ applied (docstring) |
| a1 | frontier-ranking justification was false; it is the largest `.incbin` | ✅ applied (docstring) |
| a1 | uncaught IndexError killed ~40 checks after a PTRBLOB failure | ✅ guarded |
| a2 | systematic off-by-one on ~31 citations (cited the imm32, not the opcode) | ✅ `--sites` mode + check K2 |
| a2 | the 0xFA8FF8 table's 25 blocks are identical; row index selects nothing | ✅ applied, 5 checks |
| a3 | "four display lists" names three, and only two are `.s`-invisible | ⬜ pending |
| a3 | "32 PC-relative branches" matches none of 71/43/20/8 | ⬜ pending |
| a3 | three evidence citations name a different instruction | ⬜ pending |
| b1 | **REFUTED** — six AMBIG segments not three, and the omitted three are the weakest | ⬜ pending, do not convert |
| b1 | prose and script disagree on four segment KINDS | ⬜ pending |
| b1 | record/pointer/display-list counts (231, 24, 70, seven) reproduce as nothing | ⬜ pending |
| b3 | nine of eleven data objects have a named reader, not eleven | ⬜ pending |
| b3 | 22 display-list sites below the segment end, not 24 | ⬜ pending |
| b3 | thirteen `link XIZ` routines in 0xF09E85-0xF09FFB | ⬜ pending |
| b3 | three byte triples read on a frame **shifted by 2** | ⬜ pending |
| g1 | conclusion holds, but the cited copy is a different memcpy | ⬜ pending |
| d1 | its own label count (25,675) and script count (194) struck; 17,438 / 191 stand | ⬜ pending |
| — | gap T: five PA writes, not four (found against MY census, not a lane's) | ✅ applied |

## Converted

**a1 / prom_a 0xFAD800-0xFB2000 — CONVERTED, gate green.** 18,432 bytes, by
`notes/gen_prom_a_fad800_module.py`, which re-derives the layout on every run and refuses to print
unless the emitted text re-assembles to the ROM exactly. It retired all three thunk runs that
pointed into it (prom_a's frontier went 14 runs -> 11) and added 84 `sub_XXXXXX:` labels, each
carrying the entry-point evidence that justifies it. It is the only span in this wave that has
been converted, and it is the one whose dossier survived verification AND had its corrections
applied first.

## Not verified at all

**a4** (prom_a 0xF85FF9), **b2** (prom_b 0xF4F000) and **c1** (the prom_c 0xFCD0F7 interpreter
hunt) have no skeptic verdict — a4's verifier and both of the others' lanes died on API errors, and
the re-run hit the account's weekly usage limit. a4 has a dossier; b2 and c1 have only their
scripts, written before they died.

**Do not convert any of those three spans on the strength of what is in `round1-results.json`.**
Every documented error in this project's history was plausible and gate-clean, and the three lanes
above are exactly the ones nothing has attacked.

## Round 2 outcome (2026-08-29)

| lane | outcome |
|---|---|
| a4 `0xF85FF9` | **Not refuted as a layout, REFUTED as a dossier** — convert the tiling, do not copy the prose. 45 segments tile exactly; all 28 instruction citations decode AT the cited address (no a2-style off-by-one). Seven prose claims that would have become routine headers are wrong. NOT YET CONVERTED. |
| b1 `0xF17559` | Re-audited after refutation. 5 of 6 AMBIG segments resolved **by mechanism**, 4 of 6 shown to be reached at all; 19 bytes (0.12% of the span) reached by nothing the census sees. Eight corrections (C1–C8) required **before** conversion. NOT YET CONVERTED. |
| b2 `0xF4F000` | **Safe to convert on the layout unchanged** — 43 segments, every correction is to prose, no boundary moves. NOT YET CONVERTED. |
| writer prom_a | ✅ `0xFA5AEB-0xFAA000` converted, 17,685 B, 227 labels, **100 semantic**. |
| writer prom_c | ✅ 15 routines named with evidence from a graded census of 539. |
| writer prom_d | ✅ three descriptor blocks reframed as array+pool; new region `ToneDB_DescCurveBank`; 1,302 labels. |
| crossref X1 | TLCS-900: 68 shared register NAMES, **exactly one shared ADDRESS**. A sibling SFR address imported here is wrong 67 times in 68. |
| crossref X2 | MN10300: three Latin glyph faces shared byte-for-byte; 195 of 252 sound names shared; 74 runs at the 81-byte stride. Code negative **proven**: 0 of 389 runs contains an instruction start. |

**prom_b is still the frontier**: 159,459 bytes in 124 spans, and the three audited spans
(`0xF17559`, `0xF4F000`, and a4's `0xF85FF9` in prom_a) are all cleared for conversion but not
converted. That is round 3's work, and b1 needs its eight corrections applied first.

## Coordinator decision, round 11: the 90 position-named panel proposals are ACCEPTED

Two lanes disagreed and only one reading could be applied, so this is decided here rather than by
silence.

**Lane X1** proposed 117 names for the panel handlers, of which 90 end in a position number —
`SoftKeyCol1`…`SoftKeyCol8`, `LcdKeyRow1`…`LcdKeyRow5`. **The prom_b writer lane refused exactly
those**, calling them round 6's `Write3602_Index5` shape: a name whose distinguishing part is a bare
number, which grades as content while stating nothing.

**The refusal does not apply here, and the difference is checkable.** Run:

```
python3 notes/wave7_panel_button_codes.py --physical
```

The service manual's own legends for those switches are, verbatim:

```
3.0  SW25  LCD RIGHT 1 (top)      4.0  SW33  SOFT KEY col 1 lower
3.4  SW29  LCD RIGHT 5 (bottom)   4.1  SW34  SOFT KEY col 1 upper
```

★ **The number is printed on the instrument.** `Write3602_Index5` named a position in a RAM array
that nothing outside the code refers to; `LcdKeyRow1` names the key the manual calls "LCD RIGHT 1",
which a person can point at. A legend that happens to contain a digit is still a legend.

So: **tier B is accepted**, on the condition that each Evidence line cites the manual legend it
comes from rather than the slot number alone. Tier A (the 27 legend-named `Exit`, `NumberPad`,
`Page`) was never in dispute and is applied.

⚠ The reasoning, not just the verdict, matters for the next round: the test is **whether the number
has a referent outside the code**, not whether the name ends in a digit. `SoftKeyCol1` passes;
`Dispatch_F54248_Arm3` still does not.

## ★ COVERAGE GOAL: the runs that must be REFUSED, not converted

`python3 notes/reachability.py --evidence` grades every reachable run by whether anything
POSITIVELY says execution enters at its start: a graded seed names it, or already-converted code
falls through into it. A run with neither was queued while the walk was **decoding**, and the walk
can decode its way into data.

**prom_a 87 bytes and prom_b 80 bytes have no start evidence. They must stay `.incbin`.**

The decisive case, and it nearly shipped twice:

    prom_a 0xFA369A-0xFA36AB   17 B   53 4f 55 4e 44 20 47 52 4f 55 50 20 4e 41 4d 49 4e 47
                                      = "SOUND GROUP NAMING"

A coverage brief (mine) told a lane to convert those 17 bytes. Framing them emits
`ld XIX,0x4f524720` — and **the byte gate passes**, because the bytes are unchanged. The lane
refused against its instruction and cited the prior audit. That is the second time in two rounds
that the gate would have accepted a wrong decode, and it is why the evidence test exists.

⚠ **A refusal can expire.** `0xFDE75D` was listed as unevidenced by a run that predated the splice
of `0xFDE729`; the `jr z` at `0xFDE72D` targets it exactly, so converting `0xFDE729` *created* the
evidence. Re-run `--evidence` after every conversion — its answer is a function of the tree, not a
property of the address.
