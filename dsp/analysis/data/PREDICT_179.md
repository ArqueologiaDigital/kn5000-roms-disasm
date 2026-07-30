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
