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

## Not verified at all

**a4** (prom_a 0xF85FF9), **b2** (prom_b 0xF4F000) and **c1** (the prom_c 0xFCD0F7 interpreter
hunt) have no skeptic verdict — a4's verifier and both of the others' lanes died on API errors, and
the re-run hit the account's weekly usage limit. a4 has a dossier; b2 and c1 have only their
scripts, written before they died.

**Do not convert any of those three spans on the strength of what is in `round1-results.json`.**
Every documented error in this project's history was plausible and gate-clean, and the three lanes
above are exactly the ones nothing has attacked.
