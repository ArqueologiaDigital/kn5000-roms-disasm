# BUILD-LANE QUEUE — work that is READY and is only waiting for the serialized lane

**Purpose.** Only one agent may edit source, rebuild or run MAME. Read-only passes have been
producing applicable fixes faster than the lane can consume them. Without this file those fixes
decay into things somebody re-derives in three weeks — which is this project's most expensive
recurring failure (14+ passes lost, rules 3 and 13).

**Status of each item is the state at the time it was filed.** ⚠ `HANDOFF-NEXT.md` §1 and the
register tail are AUTHORITATIVE and fresher; §222 was mid-pass when this was written and may
supersede items 4 and 5. **Check the tail before starting anything here.**

**⇒ §223 CONSUMED items 1, 4 and 6, and VOIDED item 3's vehicle assumption.** See the per-item
banners below and `SPECULATIVE-APPLIED-REGISTER.md` §223.

**⇒ §224 ADDED item 7 (the one thing ready to ship) and item 8, and PART-CONSUMED item 2** (audit
defects 1 and 2 are now documented in the instruments themselves). See `§224`.

**⇒ §225 CONSUMED items 7 and 8** — `UPD6383_LFOWRAP` **SHIPPED** on a restated gate, and the
cell-`0x06` question is **ANSWERED** by the new `§S3` boot-window recorder (`0` is not a fixed
point; the "latch-up" framing is retired). **§225 ADDED item 9**, which was the blocker.
See `SPECULATIVE-APPLIED-REGISTER.md` **§225**.

**⇒ §226 CLOSED item 9 WITHOUT A BUILD, and closed it twice over.** `SQUARING-MULTIPLY_findings.md`
established the squaring is **FAITHFUL** (the coefficient port is hardwired; there is no second
port for a sample) and re-attributed the `1.720 × FS` overflow to the **cursor base**; **§226 then
refuted the base too — from two archived host captures and the ROM's own per-algorithm parameter
map, with no run.** The header's fixed bank is `C-RAM[0x90..0xB4]`, its upload is the boot-time
`cmd 0x02` runs at base `0x90` + `0xAE`, and **the shipped build was already reading it**.
**§226 ADDED item 10**, which is the blocker. See **§226** and `HEADER-BANK_findings.md`.

---

## 1. ~~Narrow the nop guard~~ — ✅ **SHIPPED by §223**

> **DONE.** `addr8 == 0x00` added; `§NG` fired **2 371 200** words (`iw213:1189440`,
> `iw57:1181760`), identical in all three arms. Arm F's whole `upd6383:` report `diff`s against
> §222's archived arm A (`A_pickup_222.log.gz`, same vehicle, same env) in **29 lines**, and **not
> one of them is a measured value** — the reworded gate announcement, six `§90` probe lines,
> `§E1`'s fired count `+1 080 000` (a count, not a value), and the additive `§S1` block.
> ⚠ It also set off a **latent runaway `logerror`** (`§90`, bounded by `m_dbg213 <= 3` where only
> another site increments `m_dbg213`): **1 020 000 lines, a 300× log.** Fixed, arms re-run.
> ⚠ **82 of the 103 words remain UNMEASURED**, not measured-zero.

<details><summary>original entry</summary>

### Narrow the nop guard — **PROVEN BY CONSTRUCTION, ready to ship**

**Grade: FORCED.** Source: `NOP-GUARD_findings.md` (`09edb4e`).

The core's guard tests `hi12 == 0x000 ∧ class4 == 2 ∧ lo12 == 0x000` and **not `addr8`**, swallowing
**103 words across 28 of 40 streams**. **The correct narrower predicate already exists TWICE in this
repo**: `decoded()` (`upd6383d.cpp:728`) requires `ad == 0x00`, and the listings render the extras as
`?word`. **The core is the only one of three implementations that swallows them.**

**Safe by construction**: `exec_alu()` ends with the identical `(cl & 7) == 2 → m_dp += dd`, so the
address generator is bit-identical either way.

⚠ **Cite the predicate, not the line** — this guard moved `:4059 → :4075 → :4538` in one day while
two lanes shared the file.

</details>

**Expect NO behavioural change**: 21 of the 103 execute in the archived vehicle and all read
`mem 0..0` over 1 020 000 frames in seven logs (`iw57` is an exact identity). **The other 82 are
UNMEASURED, not measured-zero** — do not overstate this either way. It ships because it belongs to
the proven-by-construction class (7 of 7 successful fixes), not because a number moves.

---

## 2. Nine instrument fixes — **described precisely, no diffs (the lane owns the file)**

**Grade: MEASURED.** Source: `INSTRUMENT-AUDIT_findings.md` (`6ce3b07`), 203 diagnostics swept.

Highest value first:

1. **Frame-trace header: 13 names over 12 values** ⇒ **`ACCB` prints as `P`, `P` prints as `tempA`**.
   Real columns: `n iw u1 word dp acc accb p cur coef MUL L`. `tA`/`P` ARE captured (`:5116`/`:5121`)
   and simply not printed — §213 was built partly on the belief they were absent.
2. **The trace's `dp` is sampled AFTER `exec_decoded()`; `§104`'s BEFORE** — same column name, one
   word apart. This produced the retracted `0xD0` reading (`0x85 + 0x4B = 0xD0`, arithmetic proof).
   **Pre-increment trap, third occurrence.** Rename one of the two columns.
3. **`m_dwr[]++` sits OUTSIDE the store guard** at both store sites (`:1503`), and `m_dwr_nz`
   (`:3671`) tests **`L`, not the cell** ⇒ `D-RAM WRITES (nonzero/total)` is a **visit** counter.
   **Only `§104`'s `mem` column measures cell content.**
4. **48 of 48 armed instruments have ZERO reset** — every sampler pools across program/mode/boot
   boundaries. `§104` arms at 420 000 and never resets.
5. **`§211`'s ACCB column silently reports ACCA** when `m_speculative` is off.
6. **`§211` gates at 400 000 where the file's own §46 rule says 420 000.**
7. **`store_probe()` truncates at 4 with NO overflow counter** — both sibling tables
   (`prov_bump`, `e1_bump`) have one.
8. **23 self-concealing print sites** (class A): printed under a condition derived from their own
   value. ★ Rule 8 as sharpened by §220: a fired-count must print **unconditionally, with the gate's
   state**.
9. **15 write-only counters** (class B): incremented and never printed on any path.

⚠ **Any future audit of this file must include `string_format`** — 50 of its 266 print sites use it,
and the audit's own first detector missed the known defect by searching `logerror` alone.

---

## 3. Replace `PREDICT_S1`'s calibration — **its falsifier F1 is VOID**

**Grade: FORCED.** Source: `INSTRUMENT-AUDIT_findings.md`.

F1 — the pre-registered calibration for the whole `a70 hi12` bench — grades on `D-RAM WRITES`
**total** rising against a control. Per item 2.3 above, `m_dwr[]++` sits outside the store guard, so
**suppressing a store cannot change the total. F1 CANNOT FIRE** ⇒ void by this project's own rule
that a criterion which cannot fail is not a pass.

⚠ The `hi12` bench itself is **NOT VIABLE as designed** anyway (`cbebbbc`): the nop guard would
account for 100 % of any bit-5 difference, and the null is degenerate (36 of 37 bench words at
`L = 0, P = 0`, where all forms are the identity). **If it is ever revisited**, the vehicle to use is
**`a99 PEQ+OVERDR+DELAY` at TYPE 36 — the TOP RAIL, zero DOWN presses**, avoiding the step-dropping
regime entirely; fingerprint **522 bytes / `I-RAM[84..187]`**.

---

## 4. ~~`§E-D85`, the epilogue-crossbar arm~~ — ✅ **RUN by §222, and the rig it needs does not exist**

> **DONE and then some.** §222 ran it as arms C/D/E: the array route reproduces the compound arm
> digit for digit, the **latch is REFUTED** by a two-sided bisection, and the whole thing rails.
> §223 then showed **no store-suppression rig avoids the rail** — the narrow rig (`NOZ05 = 2`)
> rails too — so *"re-ask `w63`'s READ on a non-railing rig"* has **no vehicle** until the
> shipped build's own **5.303 %** quiet-bucket clip rate is dealt with.

<details><summary>original entry</summary>

### `§E-D85`, the epilogue-crossbar arm — **queued deliberately**

**Grade: pre-registered, unrun.** Source: `PREDICT_D0_producer.md` (`64d1cb0`).

One env var, **two of 285 words**, unconditional fired counts, on the NOZ05 rig.
★ **The NULL to beat is `2/1/2`, NOT `0/0/0`** — body 1 is `0/0/0` in arms A/B but **`2/1/2` in both
NOZ05 arms**. Known-answer controls: `m_rf[0x8D] = 0x009B26 = 39 718 = 2 603 010 048 >> 16` exact;
`§41 = 0x400000 / 0x178D0B`; `w72`'s `L = 4 194 304`; body 0's `28/32/28`.
**Named wrong numbers**: row-205 `mem` = `39 718` or `4 194 304` ⇒ constant-fill DC; `w78` mean
`79 438 ± 90`; row-85 `acc` min `−1 391 207 691 857`.
**Its own predicted outcome is that F2 FAILS and `iw70` is correctly routed** — a full result.
⚠ It was queued behind §221/§222 because their census may settle it with no run at all. **Re-check
whether it is already answered before running it.**

</details>

---

## 5. Body-0's coefficient cursor at `iw112` — **STILL OPEN, and now half-answered for free**

**Grade: pre-registered by §221 as its next-after; §222 and §223 both declined it.**
★ `RISK-TRIAGE_findings.md` §5 **resolved** the declared-unreconciled `coef 0..24` vs `0x1364D9`
conflict with **zero runs** — they are one cursor step apart (the pre-increment trap's *fourth*
occurrence) — and the **×24 attenuation STANDS**. What is left is measuring what that costs.
It is independent of the rail, the send and the output stage.

---

## 6. ~~The mode-1 store unit-rebase divergence~~ — ✅ **DECIDED AND UNIFIED by §222**

> Corpus body images name mode-1 destinations **unit-relative 7 of 7, absolute 0 of 7**;
> `iw332 → m_rf[0x8F]` is measured (§221, 540 000/540 000); **0 disagreements in 5 976 000
> resolutions**, all five arms. Also closes a latent cross-unit corruption in `a04`/`a05`.

<details><summary>original entry</summary>

### The mode-1 store unit-rebase divergence — **decide it**

**Grade: MEASURED (inert today).** Source: `PREDICT_D0_producer.md` (`64d1cb0`).

The two mode-1 store sites disagree: `:2914` uses `addr8 | (m_cur_unit1 ? 0x80 : 0)`, `:3491` uses
**bare `addr8`** — beneath a banner reading *"§99: one rule for both store sites"*. Inert in the
resident frame, so it changes nothing today; it is the kind of latent asymmetry that surfaces months
later as an unexplained result. Handed to the lane by the pass that found it.

</details>

---

## 7. ~~FLIP `UPD6383_LFOWRAP` TO DEFAULT ON~~ — ✅ **SHIPPED by §225**

> **DONE.** `W4` was restated to grade body 0 on **degenerate-quiet markers only** — which by the
> bucket predicate **cannot fire on a ramp**, and which **can still fail** (the XB85 arms score
> body-0 `D-I` = `26/23/23` on the same instrument, column and vehicle). It is `0/0/0` → `0/0/0`.
> Two further limbs added and passed: every body-0 FREE marker sits at cell `0x07`/`0x10` and
> nowhere else, and kernel A's `D-I` is unmoved at `27/21/18`.
> **`K1`: arm K, the new default reached with NO ENV, vs §224's arm J — 7 diff lines, NOT ONE a
> measured value.** **`K2`: `UPD6383_LFOWRAP=0` still reproduces §224's arm I exactly**, so the
> arm stays bisectable in both directions. `dsp/verify.py` BYTE-MATCH OK.

<details><summary>original entry</summary>

### FLIP `UPD6383_LFOWRAP` TO DEFAULT ON — **fully measured, one gate left**

**Grade: MEASURED, two arms, every falsifier but one passing.** Source: `§224` (`I_s2_224.log.gz`
/ `J_lfowrap_224.log.gz`).

`iw91` — `§118`'s wrap word — **ADDS** its `SRC 0x08` operand, and that operand is
`C-RAM[0x01] = 0x7FFFFF`, the constant `upd6383.cpp`'s own C-RAM annotation calls **"wrap"**.
Consequence, measured: `iw92` publishes `clamp(phase + INC + 0x7FFFFF)` and D-RAM cell `0x10`
(`§120`'s modulation cell) is a full-scale DC. With the arm on it becomes a `+114`/frame ramp
(`§119`: `8388607 ×8` → `1006898 … 1007696`) and `§S1`'s quiet clip rate falls `5.303 % → 4.924 %`
by **exactly** `iw92`'s 706 040 conversions.

⚠ **THE ONE GATE LEFT:** `W4` (body 0's `§104` tally, `2/4/1 → 2/9/4`) failed, and §224 §4 shows
the failure is **RULE 21** — the marker cannot tell a free-running ramp from an input-dependent
cell, and it has been mis-flagging cell `0x07` (the LFO phase) in **every log ever taken**.
**Restate `W4`** — grade body 0 on the `acc` column alone, or require the loud range to *contain*
values the quiet range cannot reach — **then flip.** No other change is needed; the code is
already in the tree, env-gated, with a fired count.

---

</details>

---

## 8. ~~Kernel A's cell-`0x06` LATCH-UP needs a BOOT-WINDOW instrument~~ — ✅ **BUILT AND ANSWERED by §225**

> **DONE, and the answer retires the question's own premise.** `§S3` — read-only, always on,
> **no frame gate**, ladder unbounded in time — reports `SETTLING`: cell `0x06` is **0** before
> any instruction writes it; **stores #1..#1356 write exactly 0** (measured — the ladder's lowest
> rung is *"val ≥ 1"* and first fires at #1357); then `iw19`'s **first ever execution**, frame
> 264 002, puts `1 650 061 = 0.1967 × FS` **into an empty cell** — already **1.52 ×** the
> `0.129 703 × FS` threshold — and the rail follows **on the next frame**.
> ⇒ ⛔ **`0` IS NOT A FIXED POINT. There is no second state; "BISTABLE" is RETIRED.** The rail
> needs a **forward gain** explained, not an entry.
> ★ **How it beat RULE 16:** it splits epochs by a property of the **datum** (had an instruction
> already written this cell?), not by a time threshold, and prints the verdict as the RELATION
> between them. **External control passed to the unit** — mask bit 26 counts the identical
> predicate at the identical hook and §220 measured 5 881 351; `§S3` reports 5 881 351.
> ⚠ **`§106`'s writer list was 5 names of 12** and `5 881 351` was never divisible by 5.

<details><summary>original entry</summary>

### Kernel A's cell-`0x06` LATCH-UP needs a **BOOT-WINDOW** instrument

**Grade: MEASURED (the latch), UNMEASURABLE with what exists (its cause).** Source: `§224` §2.

`§S2` shows `iw13`/`iw14` taking `mem[0x06]` onto the `ACT 0x00` bus **at unity** while `iw19`
stores the clamped accumulator back into `0x06`; `iw13`'s other two terms sum to `0.870 × FS`, so
the rail is a **stable second state**, not a gain error.
⚠⚠ **`§S1`, `§S2` and `§104` all arm at frame 420 000** (`S1_ARM_FRAME`, the audit's unified
window) **and therefore CANNOT SEE the transition into it.** Whoever takes this must build a
boot-window sampler and **state its arming in the prediction** — the opposite trap to §193/§204's
("a histogram over boot measures boot"), and just as expensive.

---

</details>

---

## 9. ~~`§S2sq` — THE COEFFICIENT SQUARING~~ — ✅ **CLOSED by `SQUARING-MULTIPLY_findings.md` + §226, NO BUILD**

> **DONE, and the answer is a double negative.** ⛔ **The squaring is FAITHFUL**: the multiply has
> one **hardwired** coefficient port (`C-RAM[ccur]`, no instruction field selects it) and **one**
> operand bus, so a word routing the coefficient onto that bus has no second port for a sample.
> `SRC 0x08 = C-RAM[cursor]` is ANCHORED by the CHORUS LFO (`acc = 114 << 16` exactly).
> Census `123 / 893 = 13.77 %` against a `0.05 %` null, `z = +90` — **evidence FOR the decode.**
> ⛔ **And the re-attribution to the CURSOR BASE is ALSO refuted (§226):** base `0x00` is the
> unit-0 effect's own per-effect parameter bank (PARAMETRIC EQ rewrites all 20 cells), while the
> shipped base `0x90` is the boot-fixed bank `headerdecode.md` §5 predicted — `15 of 20` header
> cells invariant, **ladder cells `9B/9C/9D` ALL invariant**, and the same ladder at `0x0B` with
> PEQ loaded reaches **`2.733 × FS`**.
> ⇒ ⛔ **DO NOT re-open `cursor + 1`, and DO NOT seed the cursor at frame start.**

<details><summary>original entry</summary>

### `§S2sq` — THE COEFFICIENT SQUARING. **THE BLOCKER.**

**Grade: MEASURED (the population), UNDECIDED (the reading).** Source: `§224` §3, `§225` §4/§7.

`SRC 0x08` resolves to `C-RAM[m_cursor]`; on a class-A word the multiply then reads
`C-RAM[m_cursor]` **again**, before the post-increment, so the product is the coefficient
**squared**. It fires **5 100 000** times a run at `iw30 iw32 iw33 iw41 iw89` (1 020 000 each).

★★★ **§225 GAVE IT A MEASURED CONSEQUENCE.** The **first non-zero datum ever placed in D-RAM
cell `0x06`** is `iw33`'s **`6 039 795` = `C-RAM[0x9B]² >> 6` = `0.720 × FS`** — a coefficient
squared, not a sample — and `§224` §1 showed `iw33`'s two product terms **alone exceed full
scale** (`1.720 × FS`; zeroing the `ACT 0x00` bus term still leaves `1.220 × FS`).
⇒ **the cell-`0x06` rail and `§S2sq` are the same defect.**

**The question:** should the **multiply** read `C-RAM[cursor + 1]` while `SRC 0x08` reads
`C-RAM[cursor]`?
⛔ **DO NOT TOUCH THE SOURCE READ.** It is ANCHORED by the LFO rate (`C-RAM[0x00] = 114` ⇒
`+114`/frame, `§109`; `§196` measures the wrap period at 96 000 frames = **0.5000 Hz**).
**Two-sided, default OFF, unconditional fired count.** Falsifiers: `§41`, SINGLE DELAY's
validated `+0.02149296` three-factor product, **and now `§S3`'s ladder** — a correct reading
must move store #1357's `1 650 061` and #1360's `6 039 795`, and `§S1`'s 4.924 % with them.

</details>

---

## 10. ★★★★ THE **ALU DECODE** OF `iw30 / iw32 / iw33`. **THE BLOCKER.**

**Grade: the ADDRESSES are settled (§226, MEASURED); the ALU reading is UNDECIDED.**
Source: `§226`, `HEADER-BANK_findings.md` §9, `§224` §1.

`iw33`'s three terms are `CARRIED 0.720` + `BUS C[0x9D] = 0.500` + `P C[0x9C]² = 0.500`
= **`1.720 × FS`**, and **not one of them is a sample**. §226 established the addresses are right
and the constants boot-fixed, so the defect is in **what the three words do**.

**The one untested reading:** `iw33`'s `f31 = 1` should **not CARRY** `iw32`'s accumulator.
Drop the carried term ⇒ `0.500 + 0.500 = 1.000 FS` (still at the rail); drop it **and** apply the
Q-consistent `P_SHIFT = 7` ⇒ `0.500 + 0.250 = 0.750 FS`, in range.
⚠ **BISECT — two changes at once is not an experiment.**
⛔ **`P_SHIFT` may NOT move on a number alone** — `§41` (`0x400000 / 0x178D0B`),
`m_rf[0x8D] = 0x009B26` and SINGLE DELAY's validated `+0.02149296` three-factor product calibrate
the chain end to end, and `ACC_SHIFT = 22 − P_SHIFT` ties the two.
**Falsifiers:** `§41`; SINGLE DELAY's `+0.02149296`; `§S3`'s ladder (store #1357 `1 650 061`,
#1360 `6 039 795`); `§S1`'s `4.924 %` quiet / `4.920 %` loud; and **PARAMETRIC EQ + SINGLE DELAY
must stay bit-identical** — they carry **zero** squaring words between them and share the header,
so a header-only change must move them **not at all**.

---

## 11. ★★★ CAPTURE A **REVERB-PRESET CHANGE** — one capture, no build

**Grade: the gap §226 named in its own result.** §226's invariance evidence is **one capture pair
in which unit 1 did not change**. The ROM's per-algorithm map says a reverb preset rewrites
`0x9E..0xB2`, and `0x9E/0x9F/0xA0` are **inside** the header's `0x90..0xA3` walk. If those move
under the user's reverb knob, the header reads live reverb parameters and the "fixed bank" result
needs qualifying. `python3 dsp/tools/hdrbase.py` scores a new capture in one line.

---

## STANDING CONSTRAINTS FOR WHOEVER TAKES THESE

- ⚠ **`UPD6383_NOZ05` is a RIG, NOT A FIX** — and **it deletes EIGHT words, not two**
  (`iw9 iw19 iw21 iw27 iw33 iw35 iw39 iw45`; its own per-`iw` breakdown always said so).
  ★ **Use `NOZ05 = 2` from now on** (§223): `iw35`/`iw45` only, **2** stores, and it reproduces
  `28/32/28` / `33/40/29` / `2/1/2` **column for column**. ⚠ **It still rails**, and so does the
  shipped build: `§S1` measures **5.303 %** of all accumulator conversions clipping on the shipped
  default with the input **exactly zero**, at a rate **higher** than the loud bucket.
  **The rail is upstream of the send entirely.** Treat nothing that rails as evidence.
- ★★★ **NEW INSTRUMENT — `§S2`, the ACCUMULATOR TERM CENSUS (§224).** Read-only, always on,
  settled frames. Splits `acc <- CARRIED + BUS + P` per `iw` per bucket with FS ratios and the
  `SRC` codes that fed the bus. **Quote it whenever `§S1` says something clipped** — `§S1` says
  *whether*, `§S2` says *which term*. ⚠ Its internal `carried + bus + P == result` is **true by
  construction**; its real controls are the four pre-registered per-term values printed beside it.
- ★★★ **RULE 21 (§224), NOW OPERATIONAL (§225): `§104`'s and `§86`'s quiet-vs-loud markers
  CANNOT DISTINGUISH "input-dependent" from "free-running and sampled over two frame sets" —
  BUT THE SPLIT IS COMPUTABLE, and `dsp/tools/rule21_all.py <log>` does it in one line.**
  The discriminator is **forced by the instrument's own bucket predicate**
  (`nz = (m_in_val[0] != 0) || (m_in_val[1] != 0)`): the quiet bucket is frames where the input
  is **EXACTLY ZERO**, so a **DEGENERATE quiet range proves input dependence** and a
  non-degenerate one proves free-running state.
  ★ **`28/32/28` SURVIVES — `26/28/27` proof-grade**, free part `0/4/1` = the cell-`0x07` rows.
  ★ **`2/1/2`, `59/44/49` and `22/19/9` are 100 % input-dependent.**
  ⚠⚠ **`2/4/1` — the shipped-build "null" — IS 100 % FREE-RUNNING. Body 0 on the shipped build
  is `0/0/0`.** ⛔ **NEVER QUOTE A `§104`/`§86` COUNT AGAIN WITHOUT ITS `D-I` SPLIT.**
  ⚠ Region boundaries, from the device's own labels (`upd6383.cpp:630`): kernel A `0..49`,
  kernel B `50..59`, **epilogue `60..82`**, body 0 `84..199`, body 1 `200..332`.
- ★★★ **NEW INSTRUMENT — `§S3`, THE CELL-`0x06` BOOT-WINDOW RECORDER (§225).** Read-only,
  always on, **NO FRAME GATE**; ladder unbounded in time. It beats RULE 16 **by construction**:
  it records STORES and splits them by a property of the DATUM (had an instruction already
  written this cell?), not by a time threshold, and prints the verdict as the RELATION between
  the two. **Copy this shape for any other boot-window question.**
  ⇒ **`0` IS NOT A FIXED POINT and the "latch-up / stable second state" framing is RETIRED**:
  `iw19`'s FIRST store, from an EMPTY cell, is `1 650 061 = 0.1967 × FS` — **1.52 ×** the
  `0.129 703` threshold — and the rail follows on the next frame.
  ⚠ **`§106`'s cell-`0x06` writer list is WRONG** (5 names of 12; `5 881 351` is not divisible
  by 5). Use `§S3`'s census, and **quote `nz`, never just the count**: `iw19`/`iw33`/`iw39`
  are non-zero on ~every frame **including all 706 040 SILENT ones** — they are what rails it;
  `iw21`/`iw27` are non-zero on 313 127 ≈ the loud-frame count; the other **seven store only
  zeros**.
- ★★ **`§S1`'s value is the PRE-UPDATE accumulator** = the PREVIOUS slot's `§104` `acc >> 16`
  (verified 8 of 8 from disk; now printed as a `§S1 PROVENANCE` line). `iw34 = row 33`.
- ★★★ **INSTRUMENT — `§S1`, the SATURATION CENSUS.** Read-only, always on, settled frames,
  pre-clamp min/max and clip counts per `iw` per `§54` bucket, 48-row cap **with** an overflow
  counter. **Quote it beside `§54` in every future pass**: `§54` sees a DC only once it reaches the
  output; `§S1` sees the clamp that makes one.
- ★★ **`m_bx_sel0d` is FROZEN at 1, globally** — changing it breaks body 0's only working pickup and
  the regression **IS** the `79 438 ± 90` rule-19 DC.
- ⛔ **Mask bit 23 is CONFOUNDED** (six sites; it *is* the `m_rf`/`m_dram` split). **Bit 26 is dead
  end 30.** u64 mask **EXHAUSTED programmatically**: 61 of 64 bits referenced, the only three
  unreferenced (1, 2, 3) are **SET**. New gates are env vars, default OFF, unconditional fired-count.
- ⚠ **VEHICLE**: `-cfg_directory` must carry `:DSPCFG value="3"` (fresh cfg ⇒ **zero DSP frames**,
  no report at all); **`-log` REQUIRED**; `timeout`-wrapped; visible video, **never `-video none`**;
  isolated `-nvram_directory`; ONE run at a time. `build.sh` **exits 0 on compile failure** — grep
  `error:` AND check binary mtime/size; `tools/publish-binary.sh` after every rebuild;
  `dsp/verify.py` must stay **BYTE-MATCH OK**.
- ★★★ **RULE 19 is mechanised**: `§70`/`§211` print **mean and AC span**. `79 438 ± 90` passes
  min-vs-max, the no-stimulus check *and* the translation rule, and is a **DC at −59 dB**. Report
  mean AND AC span, both buckets, both arms, before calling anything audio.
- **Do not ship a default flip on a moved number or a model argument alone.** §217–§221 all correctly
  declined. **A NULL is a fine outcome.**
