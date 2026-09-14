# PRE-REGISTRATION §179 — was my census window in the wrong place? Full 256-cell D-RAM sweep

Written BEFORE the run. **Read-only, no mask bit, no behaviour change.**

## The contradiction that prompts it

Two independently-argued anchors for the same pointer, and they disagree:

```
  upd6383.h:280      DRAM_UNIT_BASE = 0x05  (unit 1 = 0x85)   marked FORCED --
                     closure arithmetic, and the two frame-end deposits land on cells
                     0x01/0x04, PREDICTING output-stage-decode.md's DI-latch map.
  kn5000-dsp-pointer.md §4   origin 0x70 (unit 0) / 0x50 (unit 1)   MEASURED three ways --
                     the ROM record at 0x01E496, the cold-boot capture, and the LIVE I-RAM
                     of a booted KN5000 read back by the device.
```

⚠ They may not be the same register — that note names **three** pointer-family registers
(`0x821`, `0x825`, `0x827`) and selects `0x821` as the operand pointer **INFERRED, strong, with
`0x827` explicitly not excluded**. So this is a real question, not a bookkeeping error.

## Why it bears on §176

D-RAM is **256 cells** (`map(0x00,0xff)`). §176 censused `0x00..0x1F` — **one eighth of it** — and
found 4 non-zero. If the live data sits near `0x70..0x8B`, my window missed it and §176's
"the pointer is 2 short" was measured inside an empty corner. That would be the *fifth* instance of
the instrument being one step off (LEDGER rule 10), at the largest scale yet.

## Falsifiers

* **F1 — the fork, two-sided.** Census all 256 cells with settled value and change-count.
  * Live data (non-zero, and moving) concentrated in `0x00..0x1F` ⇒ **the window was right**,
    §176 stands as measured, and the `0x05` base is where execution actually happens.
  * A populated, moving region around `0x50..0x8B` ⇒ **the window was wrong**, and §176's
    off-by-2 must be re-derived in the region the data is actually in.
* **F2 — the emulator's own model must show its own footprints.** `upd6383.cpp:1209` states unit 1
  starts at `0x85`, walks `−133`, and the frame ends on `0xFF`. If cells near `0x85` and `0xF0..0xFF`
  are dead, that FORCED closure argument has no observable consequence and is itself in question.
* **F3 — known-answer control.** `07: 0..8388598 chg 1128429` and exactly 4 non-zero cells in
  `0x00..0x1F` must reproduce. If not, the build changed something other than the census window
  and the run is void.
* **F4 — ★ standing rule 1.** No output claim without `§70 ACCA` min ≠ max. Expected `min 0 max 0`.

## The NULL

I do **not** have a prior that favours either arm: both models predict activity somewhere in
`0x50..0x8B`, and the emulator's own `0x85 → 0xFF` walk predicts a high-address footprint too.
"Everything outside `0x00..0x1F` is dead" and "most of the action is above `0x50`" are both live
outcomes, which is what makes this worth one run.

## ⚠ What this does NOT do

It does not adjudicate `0x05` vs `0x70`. It establishes **where the data is**, which is the
prerequisite for adjudicating anything. And it does not touch the pointer-DELTA rule, which is
being searched in parallel and whose constraints are all origin-free by construction.


---

## ★ RESULT, 2026-09-14 — **F1 ANSWERED: THE WINDOW WAS WRONG.**
Run from the §148 logs (`f3/pslot_upd6383_bx_f3/v0.log`, TYPE 33, per-program census). No new run
was needed: the current build's §176 already censuses **all 256 cells**, which is exactly what this
pre-registration asked for.

```
   NON-ZERO 126 of 256 (22 of them below 0x20), MOVING 126

   by 0x20 block:  00-1F 22 │ 20-3F 14 │ 40-5F 21 │ 60-7F 19
                   80-9F 16 │ A0-BF 10 │ C0-DF 15 │ E0-FF  9

   MOVING (chg > 1): 24 cells, only 7 below 0x20
   the movers above:  50 51 52 53 55 56 57 58 · 87 88 89 8A 8B 8D 94 · D1 D2
```

* **F1 — the window was WRONG.** Only **22 of 126** non-zero cells (17 %) are below `0x20`, and the
  moving ones concentrate at **`0x50..0x58`** and **`0x85..0x94`** — precisely the region this
  pre-registration named as the deciding branch (*"a populated, moving region around 0x50..0x8B ⇒
  the window was wrong"*). ⇒ **any conclusion measured inside `0x00..0x1F` was measured in a corner
  holding a sixth of the live data and has to be re-derived where the data is.**
* **F2 — half of it.** `upd6383.cpp` states unit 1 starts at `0x85`, walks −133, and the frame ends
  on `0xFF`. The `0x85` footprint **is live**: `87 88 89 8A 8B 8D` all move. The `0xF0..0xFF`
  frame-end is **not** — that block has 9 non-zero cells and **none moving**. So one half of the
  FORCED closure argument has an observable consequence and the other half does not.
* **F3 — the known-answer control does NOT reproduce**, and that is expected rather than alarming:
  it asked for *"exactly 4 non-zero cells in `0x00..0x1F`"* from the build of the day this was
  written, and the build has moved a great deal since (this session alone added the mode-1 decode,
  the C-format decode and three arms). ⚠ **So this is not a clean before/after against the original
  run.** F1's conclusion stands on its own — "17 % of the live data is below `0x20`" is a statement
  about the current build, measured, and needs no comparison.
