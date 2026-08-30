# HANDOFF — the join/split/kernel work. Read this first.

Written at 99% context. Everything needed to continue is here or in a committed script; nothing
load-bearing lives only in a transcript.

## Status: PLAN APPROVED, execution started, A1 not yet written

`notes/PLAN-join-and-split.md` is the approved plan (§0–§10). This file is the operational state.

## The approved constraints — these are not negotiable

1. **Both trees' byte gates stay green at every commit.**
   `python3 scripts/analysis/assert_byte_identical.py` in each of
   `~/compartilhado/wsa1-roms-disasm` and `~/compartilhado/kn5000-roms-disasm`.
   Both PASS today; KN5000 clean at `46a916e`.
2. ⚠⚠ **Do not destroy pre-existing comments, documentation headers or semantic structures in
   EITHER tree.** Modify one only when demonstrably better, and say why in the commit. Verify it the
   way the coverage rounds did: every hunk accounted for, a diff that shows movement not rewriting.
3. ⚠ **Do not flatten KN5000.** The goal is per-subject files in BOTH trees. KN5000's subcpu core is
   a 1,394 KB monolith and `subcpu/boot` another 1,256 KB — splitting KN5000 FURTHER is part of the
   deliverable.
4. **Semantics stay deferred** except where comparative analysis yields a name WITH a byte diff and
   a differing count.

## ★ A1 — THE SHARED KERNEL SOURCE. Do this first. The design is measured and settled.

`python3 notes/kernel_shared_source_probe.py` (4 checks) — 938 instructions across 76 routines:

    858  byte-identical                        91.5%
      5  differ by EXACTLY the 0x12B65 offset  self-references, need NO conditional
     75  differ by something else              REAL per-CPU differences

★ **The 75 are a handful of recurring CONSTANTS, not 75 edits.** Deltas repeat: −46 ×13, −524 ×13,
−2 ×9, −596 ×8, −544 ×5, −556 ×5. Three kinds:

    ld XSP,0x0060eb80  vs  ld XSP,0x0000fa00    STACK TOP -- different RAM maps
    ld (0xbf),WA       vs  ld (0x91),WA         an SFR ADDRESS, delta -0x2E
    ld HL,0x0330       vs  ld HL,0x0124         a SIZING CONSTANT

★ **DESIGN: symbolic `.equ` per CPU, NOT `.if/.else` wrapped round code.** The body then stays
genuinely shared and each difference is named once instead of duplicated at every site.

    kernel/kernel.s              the shared body, using symbols
    kernel/kernel_maincpu.inc    .equ KERNEL_STACK_TOP, 0x0060eb80  etc
    kernel/kernel_subcpu.inc     .equ KERNEL_STACK_TOP, 0x0000fa00  etc

`prom_a/wsa1_prom_a.s` and `prom_c/wsa1_prom_c.s` each `.include` their `.inc` then `kernel.s`.
⚠ **The byte gate is the proof.** If one equate is wrong, both images stop rebuilding. A shared
source that assembles to the SAME BYTES in both CPUs is proof the sharing is real.

Facts A1 needs:
* the kernel block: **prom_c `0xF98xxx`–`0xF989EF`**, prom_a = prom_c − **`0x12B65`**, every pair.
* 77 kernel routines are findable by label prefix (`Kernel_`, `MsgQueue_`, `SoftTimer_`,
  `IRQ_Epilogue`, `INTT3_`) — `kernel_pairs()` in the probe does it.
* ⚠ **`Kernel_InitRam` is the ONE exception** (76 of 77): an 8-byte inline data block
  (`SoftTimer_Request_Boot`) decodes differently on each side. Do not force it; duplicate it or
  handle it explicitly.
* A1 does NOT require the maincpu join. Do it independently.

## Address map, both trees

    WSA1  prom_b 0xF00000 512K maincpu LOW    KN5000 maincpu    0xE00000 2M (v7,v9,v10)
    WSA1  prom_a 0xF80000 512K maincpu HIGH   KN5000 subcpu     0x000400 251K
    WSA1  prom_c 0xF80000 512K subcpu         KN5000 subcpu boot 0xFE0000 128K
    WSA1  prom_d  not established  data       KN5000 table_data 0x800000 2M
                                              KN5000 custom_data 0x300000 1M
                                              KN5000 hdae5000   0x280000 512K

★ prom_b+prom_a ARE contiguous (0xF00000–0xFFFFFF, 1 MiB) → clean maincpu join.
⚠ prom_c+prom_d is NOT a joinable pair — prom_d's base is not established and `prom_d.ld` argues
ORIGIN 0 is a decision. subcpu = prom_c alone; prom_d stays a separate data image.
★ **Only 4 label collisions** for the maincpu join, out of 10,976: `IndexedTable_GetPtr`,
`LCD_ScreenRedraw_Begin`, `LCD_ScreenRedraw_End`, `end`. Three are byte-identical duplicates round 8
proved, so the rename should say so (`_PromA`/`_PromB`), not use a number.

## KN5000 state, measured

    incbin directives: v7 3,810 · v9 3,642 · v10 3,642 · table_data 28 · custom_data 11 · hdae5000 10
    ★ v142/subcpu 0 and subcpu/boot 0 -- ALREADY TERRITORIALLY COMPLETE

So the KN5000 coverage pass gates only the **maincpu** split. All sub-CPU work can start now.

## Two tracks

    TRACK A (nothing blocks it)
      A1 ★ shared kernel source, WSA1 maincpu+subcpu, .equ per CPU, gate green
      A2 three-way kernel test done properly -- see below
      A3 if A2 lands, extend the shared source to KN5000's subcpu
      A4 split BOTH sub-CPUs into per-subject files at byte-matched boundaries
    TRACK B (parallel; gates the maincpu split only)
      B1 port notes/reachability.py to KN5000 maincpu
      B2 convert KN5000 maincpu's reachable code, semantics deferred
      B3 join WSA1 maincpu, split both trees' maincpu trees

## A2 — the three-way test is UNDERPOWERED, not negative

`notes/kernel_three_way.py`: 0 kernel routines found in any of 41 KN5000 images, **but only 5 were
long enough (≥24 B) to count and 32 were too short.** The instrument is sound — negative control
absent from all 41, positive control (the known shared run at `0xFDE32B`) FOUND.
**Redo it** against `prom_c_kernel_map.py`'s real pair extents, with STRUCTURAL matching (same
mnemonic sequence, different operands) — because §A1 shows two WSA1 CPUs already differ by operands,
so a third processor would differ at least that much.

## The open disagreement to settle before aligning names

WSA1 prom_d: tag bit 7 → **6 bytes when CLEAR, 8 when SET**.
KN5000 `table_data/tone_database_aux.s:718`: bit 7 **SET → 6 bytes, CLEAR → 4**.
⚠ These do not contradict cleanly — **the sizes differ too (4 vs 8)**. Either one tree has the
polarity backwards, or the machines use different record formats and the WSA1 note's "same field"
premise is itself wrong. WSA1 has its null (0 of 318 under inversion); KN5000 needs the equivalent.
**Rule: the side with the reproducible measurement wins; if neither has one, NEITHER tree changes.**

## Traps this project has paid for — carry them forward

* ⚠ **68 shared SFR register NAMES between the machines, exactly ONE shared address** (`PBFC`).
  A name may transfer; an ADDRESS may not. Every borrowed name needs a byte diff with the count.
* ⚠ The KN5000 label transplant's first version named the wrong object at all EIGHT sites (a spliced
  ROM plus an offset constant short by `0xEB00`). Read
  `scripts/analysis/transplant_kn5000_labels.py`'s retraction banner before reusing it.
* ⚠ `notes/wave7_kn5000_transplant_residue.py`: the transplant is COMPLETE for prom_c (15 of 19
  applied); the 4 residuals must NOT be imported — they name sub-objects of structures this tree
  models better.
* ⚠ **Line shapes differ per image and have broken an address regex three times.** prom_a writes
  `<text> ; ADDR hh hh`; prom_b `<llvm text> ; ADDR <mame text>`; prom_c likewise with no hex bytes.
  Never assume one shape.
* ⚠ **A guessed block boundary desynchronises a paired decode** (5,121 vs 6,749 instructions here).
  Pair per routine on proven boundaries.
* ⚠ `prom_d/wsa1_prom_d.s` is GENERATED by `scripts/analysis/gen_prom_d_asm.py`. A hand-edit is
  reverted on the next run.

## Coverage goal state (previous goal, MET)

STRONG reachable-and-unconverted: **17 bytes**, and those 17 are `"D GROUP NAMING"` at
`0xFA369A` — a walk artefact with no start evidence, formally refused. prom_b and prom_c are at 0.
`notes/reachability.py --targets` / `--evidence` / `--selftest` (11 checks).
