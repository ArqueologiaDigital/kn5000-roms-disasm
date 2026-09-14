# PRE-REGISTRATION — the per-site product invalidate: WHICH kernel C-format word?

Written **before** the run. 2026-09-14.

## The question §118/§119 reduced it to
Clearing the one-slot product at **every** C-format word takes the chorus LFO to `mean step
114.2560` — **0.6 % from the ROM's `floor(0.5993 × 2²³/44100) = 114`**, against a shipped model
**255× wrong** — and simultaneously empties the per-unit hand-off cell. Restricting it to `is_c40`
(the body's words) does neither; clearing at the block CALL does neither. ⇒ **it is the KERNEL's
own eight C-format words**, and they sit at **iw 1, 15, 22, 29, 31, 40, 48, 56** — spanning both
sides of the **iw45** that writes the hand-off.

★ If the word the input stage consumes and the word the LFO inherits are **different**, clearing at
one and not the other fixes both. `UPD6383_PCLRIW=<iw>` clears `P` at exactly one slot.

## The sweep
iw ∈ {1, 15, 22, 29, 31, 40, 48, 56}, chorus (TYPE 0), `UPD6383_CENSUS_PERPROG=1`, true default
otherwise.

| | prediction |
|---|---|
| **U1** | each arm FIRES at its slot (count > 0) — a slot that never executes says nothing |
| **U2** ★★ | **at least one** slot gives LFO `mean step` at or near **114** |
| **U3** ★★ | **at least one** of those also leaves the hand-off `0x05` LIVE (±2.9 M, ~175 660 changes) |
| **U4** | if U2 ∧ U3 hold at the same slot ⇒ **the LFO rate defect is fixed with no trade**, and §116's chain unblocks: the auto-pan discriminator becomes usable for `f31` 3/4/5/7 |
| **U5** | outcome B — every slot that fixes the LFO also kills the hand-off ⇒ one word serves both and the fix is not a clear but a **driver**: something must SUPPLY `P` there rather than the residue. Reported as such |
| **U6** | ⚠ before any promotion: the 10-program hand-off regression, 0 BROKEN, and the PARAMETRIC EQ's railed-cell count unchanged (§56's criterion) |

⛔ Even a clean pass decodes **no word**: it fixes a datapath defect and unblocks a discriminator.
The coverage number moves only when that discriminator is then run.


---

## RESULT — **ONE WORD. `iw40`, and nothing else.**
Data: [`pclriw_2026-09-14.txt`](pclriw_2026-09-14.txt).

```
   iw   fired       LFO mean (ROM 114)   hand-off 0x05
    1   1 602 594   15 543.9286          live
   15   1 602 594   15 543.9286          live
   22   1 602 594   15 543.9286          live
   29   1 601 712   15 543.9286          live
   31   1 601 712   15 543.9286          live
 ★ 40   1 601 712   ★  114.2560          ⛔ ABSENT -- destroyed
   48   1 601 712   15 543.9286          live
   56   1 579 662   15 543.9286          live
```

**U1 HIT** everywhere. **U2 HIT at exactly one slot.** **U3 MISS** — that same slot is the one that
kills the hand-off. ⇒ **U5, outcome B**: one word serves both consumers, so the fix is **not a
clear but a DRIVER** — something must SUPPLY `P` at `iw40` rather than leaving the residue there.

### ★★★ And `iw40` is `0C4A1C0820` — a `lo12 = 0x820` word
The five `lo12 = 0x820` words are the project's longest-standing unsolved family, all in the
kernel:

```
   w15 0C0A292820 op605 A=20 | w22 0C04312820 op602 A=24 | w29 0C42457820 op621 A=34
   w31 0C0A4B1820 op605 A=37 | w40 0C4A1C0820 op625 A=14   ★ THE ONE
```

`closure-pointer.md` item H spent a whole pass on them and closed it with a null: *"The five
`0x820` words are not solved, and the field search says so cleanly. Every contiguous bit-field of
the 36-bit word was enumerated: no field makes all five …"* — and item B FALSIFIED them as the
frame-closing pointer reload.

⇒ **the unsolved `0x820` semantics are load-bearing for BOTH the audio input path and the LFO
rate, and `w40` is the single site.** Two long-standing open problems — the `0x820` family and the
LFO's 255× rate error — are the same problem, and that was not visible from either end alone.

### What the next pass should ask
Not *"what clears `P`"* but **"what does `w40` DRIVE `P` with?"** It is a C-format word (opcode
`0x625`, A = 14) sitting five slots before the `iw45` that writes the hand-off, and its product is
consumed by the input stage and inherited by the body's LFO. A driver that satisfies both ends has
a known answer at each: the hand-off live at ±2.9 M, and the ramp at the ROM's 114.
