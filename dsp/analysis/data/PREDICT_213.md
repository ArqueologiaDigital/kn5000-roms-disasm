# §213 — WHERE THE INPUT DIES IN KERNEL A: pre-registered BEFORE the build

Written and committed **before** `build.sh` was run and before the emulator was launched.
2026-07-31.

## 0. WHAT IS ALREADY ESTABLISHED, from `data/outstage_211.log.gz` — NOT predictions

These are re-readings of the SHIPPED §211 run.  They are written down here so that nothing below
can be confused with something the new run produced.  Every one is a direct quote of that log.

```
 F1  iw20 000.A.00.64D  SRC 0x19 = tempA :  L quiet 0..0   loud -5 579 776..4 994 816   '*'
 F2  iw25 000.2.00.2D9  SRC 0x0B = the DELAY-READ register, ACT 0x19 = tempA <- bus :
                        L quiet 0..0   loud 0..0   '='
 F3  iw27 012.2.01.655  SRC 0x19 = tempA :  L quiet 0..0   loud 0..0   '='
 F4  iw35 012.A.00.1C0  SRC 0x07 = mem[0x05] : L quiet 5 084 004  loud -5 307 593..8 388 607  '*'
     iw36 400.A.00.000  SRC 0x00 = mem[0x05] : L 4 194 304 .. 4 194 304 in BOTH buckets
     iw37 092.A.01.1C0  SRC 0x07 = mem[0x05] : L 4 194 304 .. 4 194 304 in BOTH buckets
 F5  §104 mem: cell 0x06 holds 6 039 795 at iw38 AND at iw39, although the §109 probe logged
     iw34 storing 8 388 607 to cell 0x06.  Nothing writes 0x06 between them.
 F6  §98  kernel A mode-2 cells:  01r 02w 03r 04r [05rw] 06w [07r]   -- cell 06 is WRITE-ONLY,
     and 0x06 appears in NO other region (body 0, body 1, kernel B, epilogue).
 F7  §176 06: 8 388 607 (0..8 388 607 / chg 1100) over 1 440 001 frames -- the datum parked in
     0x06 is at the 24-bit RAIL on all but ~1100 frames.
 F8  §112 class-A ACT-07 latched P instead of storing: 3 630 720 = exactly 3 per settled frame
     (the three kernel words iw32, iw34, iw39).
```

## 1. THE TWO CLAIMS THE BUILD TESTS

**C-A (the §211 §6 lead is a PROBE ARTEFACT).**  `upd6383.cpp:3487`'s `else` is **unbraced**:
only `store_mode()` is guarded by it, so when the §112 arm (mask bit 25, ON in the shipped
default) takes the latch branch, `kwatch()`, `watch_store()`, `store_probe()` and `m_dwr[]` still
run and record a store the machine did not perform.  F5 is the measurement that proves it
independently of the source.  ⇒ `iw39` performs **ONE** store, not two, and cell 0x06 keeps the
bit-4 datum.

**C-B (tempA is not "empty", it is ZEROED at iw25).**  F1/F2/F3 bracket it: tempA is
input-dependent at iw20 and hard zero at iw27, and the only writer between them is iw25, whose bus
is `SRC 0x0B` = the delay-read register, which §46/§48 measure as 0 on 100 % of reads.

## 2. WHAT IS BUILT — both read-only with respect to the machine

1. **The store-probe fix**, env `UPD6383_STPROBE` (default **1** = fixed, `0` = the old
   phantom-recording behaviour), with a fired count.  Suppresses `kwatch`/`watch_store`/
   `store_probe`/`m_dwr` on the §112 latch arm only.  `lvl_hit`/`ab_hit` are left exactly as they
   were so the A/B isolates one thing.
2. **§213 per-slot `P` / `tempA` census**, same arming threshold (frame > 420 000) and the same
   quiet/loud predicate as §104, printed for the kernel `iw 0..59`, plus a bitmask of `m_pw`
   (who last wrote P: 5 = §112 class-A ACT-07, 6 = THE MULTIPLY).

**No gate, no decode, no mask bit is changed.**  The NULL is therefore that the audio is
bit-identical to §211's silence.

## 3. THE CALIBRATION THAT CAN FAIL — run it first

* `coldnotes2.lua` must print `located=true`, `NOTE ON` and `NOTE OFF`.
* `§54 TRACKING` must report a loud bucket in `250 000 .. 380 000` frames (§211: 313 960).
  **A loud count of 0 VOIDS the run** and no number in it may be quoted.
* `§104` must report **27 INPUT-DEPENDENT / 2 free-running** in the `acc` column, slots
  `9..31, 35..38`.  A different split means the build changed the machine ⇒ the "read-only" claim
  is false and the change must be reverted before anything else is read.

## 4. PREDICTIONS

| # | prediction | falsifier |
|---|---|---|
| **P1** | the §109 store witness prints **NO site-3 store** at `iw32`, `iw34`, `iw39` | a site-3 line survives at any of the three ⇒ C-A's control-flow reading is wrong |
| **P2** | it **KEEPS** the site-3 store at `iw72` (class 1) and `iw78` (class 0xD) — neither is class A, so §112 never applies to them | either disappears ⇒ the guard is too wide and the fix is over-reaching |
| **P3** | `§96` loses `cell 07 written by iw32` and `cell 06 written by iw34` (both hi12 = 0x000, no HI_ST ⇒ the phantom was their ONLY store) and **KEEPS** `iw19`, `iw21`, `iw27`, `iw33`, `iw39` on 0x06 and `iw9`, `iw11`, `iw35`, `iw45` on 0x05 (all HI_ST, site-2, real) | any of the five/four disappearing ⇒ over-reach; iw32/iw34 surviving ⇒ the phantom is not where I say |
| **P4** | the new fired count equals the §112 latch count **exactly** (`3 630 720` on a 1 210 240-settled-frame run; the IDENTITY, not the literal — standing rule 5) | inequality ⇒ my reading of the ladder is wrong |
| **P5a** | §213: `tempA` after `iw20` is INPUT-DEPENDENT; after `iw25` it is `0..0` in **both** buckets and stays `0..0` through `iw45` | tempA non-zero anywhere in `iw26..45` ⇒ C-B is refuted and the section is rewritten |
| **P5b** | §213: `P` after `iw36` is INPUT-DEPENDENT and `P` after **`iw37`** is the CONSTANT `401 321 689 088` in both buckets | P37 input-dependent ⇒ the "iw35 clobbers the cell iw36/iw37 re-read" mechanism is wrong |
| **P5c** | §213: `P` after `iw39` is `0..0` both buckets with `pw` bit **5** (§112 class-A ACT-07); `P` after `iw41` is `538 760 587 509` with `pw` bit **6** (the multiply) | either differs ⇒ the "delay-read → tempA → P → acc → send" chain is not the send's datapath |
| **P6** | ⚠ standing rule 1: `§70 ACCA AT w73` and `§211 ACCB AT w78` are **min == max == 0**, quiet and loud | `min != max` ⇒ do NOT report audio; characterise it, and a constant is still not audio |
| **P7** | the NULL: `§61` both ports **0 non-zero, peak 0**; `§54` VERDICT unchanged | any non-zero output ⇒ the change is not read-only, revert |

## 5. WHAT WILL **NOT** BE DONE

* ⛔ No store will be suppressed to make a value survive.  §211 named "suppress one of the two
  stores" as an anchor-value fix at a symptom; C-A says there is no second store to suppress, so
  that fix was a **no-op on the machine** and would only have silenced a probe line.
* ⛔ `iw35`'s bit-4 store will NOT be re-targeted, and `iw45`'s send will NOT be re-sourced.
  Both are anchor-value moves on FORCED anchors (`§109` PRE, k6 finding 7's 37x over-determination).
* ⛔ No claim of audio without `§70 ACCA min != max` **and** a no-stimulus window.
* A NULL is an acceptable deliverable.  So is "this is undecidable with instrument X".
