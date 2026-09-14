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
