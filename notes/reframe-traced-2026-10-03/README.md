# Trace-guided re-framing (2026-10-03)

Tool: `scripts/converters/reframe_traced.py --image <v> [--apply] [--report OUT]` (about 3
minutes of tracing per tree).  `report_<tree>.json` lists the spans and the trace's conflicts.

The trace enters at every `call`/`calr` target and every code label a `.long` table holds; in
v10 it reaches 255,206 instructions with 3 conflicts (two `halt`s and one undecodable byte).
Where a traced instruction starts inside a source line that is not a macro invocation, the
source frames executed bytes wrongly.  Before the pass, v10 had 131 such starts (49 in
instruction lines, 46 in `.byte` rows, 36 in data directives such as `.asciz " E@!"` in
storage/flash_floppy_handlers.s).

| tree | spans | applied | refused: gap in traced code | no clean resync | crosses a file |
|---|---|---|---|---|---|
| v10 | 34 | 34 | 17 | 1 | 0 |
| v9 | 35 | 35 | 17 | 1 | 0 |
| v7 | 45 | 43 (2 refused by scoop_reframe) | 43 | 452 | 6 |

Then symbolize_numeric_branches.py --apply --verify: v10 34, v9 26, v7 18 more branches.
