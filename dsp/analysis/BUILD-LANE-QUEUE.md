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

**⇒ §231 CLOSED THE `f31 ∈ {3,6,7}` LEAD AND RE-PRICED THE WHOLE QUEUE.** `alu_decoded()` is a
**conjunction**, so only its FIRST failure is observable — and mirrored over the corpus
(`dsp/tools/f31_367.py`, self-test **1178/3057 = 38.53 %**) the population is:
**ROUTING (SRC/ACT not anchored) 1139 · CLASS 546 · OPERATION 106 · FORMAT 68 · GUARD 7 20.**
⇒ ⛔ **any queue item whose payoff is "decode one `hi12` operation code" is worth ≤ 106 words in
total and typically 8.** ⇒ ★ **The lever is the ROUTING guard**, and it is the same population
§229's fabricated-zero census counts. **File routing/anchoring work above operation-field work.**
See **§231** and `LEDGER-HEAD.md` TIER 0a.

---

## 0. ★★★★ THE UNANCHORED SRC/ACTION CENSUS — **READY, NOT STARTED, TOP OF THE QUEUE**

> **Filed by §231.** The single largest decode population in the corpus (**1139 words, 60.6 % of
> everything undecoded**) and the single largest fabricated-operand population in the device
> (**28.492 %** of the epilogue's operands, §229) are **the same set of codes**.
> **Shape, pre-registered:** a **census FIRST** — per unanchored `SRC`/`ACTION` code: its sites,
> its **index range**, and its consumer. ⛔ **No reading.** Dead end 4 / rule 4 forbid implementing
> a consumer whose index is measured constant, so **the census must print the index range** and a
> constant index **CLOSES** that code (as it already closed `SRC 0x13`:
> `acc 0..0 | m_dp 12..12 | cursor 9..9`).
> **Falsifiers:** `m_rf[0x8D] = 0x009B26`; `§S1`'s `4.924 %` must not **fall** (§227's guard);
> `§54` graded first; `§70`/`§211` as **ONE ROW** (§230).
> **Cost:** one build, one 30 s run on the §228 vehicle. Read-only, no default flip.

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

## 10. ~~THE **ALU DECODE** OF `iw30 / iw32 / iw33`~~ — ✅ **CLOSED by §227, BOTH ARMS REFUTED**

> **DONE, four arms, and the guard fired on the attractive one.**
> * **arm 1 `UPD6383_NOCARRY`** — ⛔ **REFUTED FROM DISK BEFORE IT RAN**: `f31 == 1` is `HI_ACC_ADD`,
>   **1309 of 2989** non-C-format corpus words and **695 of 1178** ALU-decoded; op 0 LOADs, op 2
>   HOLDs *without a product*, op 3 gets HOLD's behaviour ⇒ it is the **only accumulate the ISA
>   has**, and the **PARAMETRIC EQ** biquad (grade SOLVED, validated at **0.198 dB** against its
>   designer) sums five products through `f31 == 1` words `w6..w10`, rendered **`acc += P`**.
>   **AND IT DOES NOT FIX THE CLIP:** `iw34` becomes `8 388 608` = `2²³` = **FS + 1**, clipping
>   `706040/706040` quiet and `313960/313960` loud — **unmoved from shipped.** Its `§S1`
>   `4.924 % → 0.379 %` is **117 655 680 accumulate steps refusing to add**, and it takes `§104`
>   body-0 to **100 % input-INDEPENDENT** and makes **`m_rf[0x8D]` vanish**.
> * **arm 2 `UPD6383_PSHIFT`** — the phrase had **two** meanings and they are different
>   experiments. **TIED (7/15, total still 22): a MEASURED NO-OP** — the entire `§S1` block is
>   BIT-IDENTICAL to the default over 269 279 999 conversions. **UNTIED (7/16, total 23):
>   `m_rf[0x8D]` halves `0x009B26 → 0x004D93`** and it *still* clips at `1.110 × FS`.
>   The core's own header records the total 22 as **FORCED**: coefficients are **Q1.22, MEASURED**.
> * ⚠⚠ **A STANDING CORRECTION:** `§41` is quoted everywhere as a `P_SHIFT` guard. **It is not** —
>   it reads C-RAM *levels* and is unmoved by a 2× product rescale. **`m_rf[0x8D] = 39 718` is the
>   one that fires.**
> **Both gates ship OFF/inert.** `P_SHIFT`/`ACC_SHIFT` are no longer `constexpr`; **arm N vs
> §225's arm M is 4 diff lines and NOT ONE is a measured value.**

## 11. ~~CAPTURE A **REVERB-PRESET CHANGE**~~ — ✅ **DONE by §227, AND IT REFUTED §226**

> **DONE, two screen-verified captures, and the answer is the one §226 named as its own threat.**
> `CONCERT REVERB 1 → ROOM REVERB 1` rewrites **23 cells, every one inside `0x90..0xB4` and
> NOTHING else in the 256-cell C-RAM**: `[00..4F]` **0 of 80**, `[50..8F]` **0 of 64**,
> the header's own walk `[90..A3]` **13 of 20**, and the ladder cells `[9B..9D]` **2 of 3**
> (`0x9B`, `0x9C`). ⇒ **`C-RAM[0x90..0xB4]` IS UNIT 1's PER-ALGORITHM PARAMETER BANK**, not a
> boot-fixed one; it looked fixed only because both §226 captures carried the same reverb.
> ★ **The control:** an independent 45 s panel run landing on CONCERT REVERB 1 reproduces the
> archived cold-boot capture on **all 256 cells, 0 differ** ⇒ **the cold-boot default reverb is
> CONCERT REVERB 1**, so every *"CHORUS + RR1"* label in §226 names the wrong preset.
> ★ In Q1.22 the ladder cells read as reverb gains: CONCERT `1.200/1.000/1.000`,
> ROOM `1.000/0.800/1.000`. The ladder is `+1.720 FS` on one preset and `+1.320 FS` on the other —
> **the overflow itself is preset-dependent.**
> Tools: `dsp/tools/reverb_select.lua` (`REVIDX=n`) + `python3 dsp/tools/hdrbase.py --score <a> <b>`
> (3 controls, **orientation-sensitive** — run it the wrong way round and two limbs fail, which is
> how the cold-boot preset was identified).

---

**⇒ §228 CONSUMED the strategic review's action 2 (the frame clock) and its action 5 (the
bookkeeping repair, P1–P9), and it did NOT touch items 12 or 13, which remain the blocker and the
cheap next thing.** The DSP frame clock now runs at **44 100 Hz**, decoupled from the 48 kHz
rendering stream by an exact 147/160 phase accumulator; `UPD6383_FRAMEHZ=48000` is the two-sided
control. ⚠ **Every frame count in a pre-§228 log is on the 48 000 clock** — a `-seconds_to_run 30`
vehicle gave 1 440 001 frames and now gives 1 323 000. **Compare ratios, never counts.**
⛔ **`§196`'s LFO wrap census is SUPERSEDED** by `§228`'s RISE CENSUS; it printed 0.5000 Hz on every
arm ever run. See **§228**.

---

## 12. ★★★★ WHAT DOES THE COEFFICIENT BASE `0x90` **MEAN**? **THE BLOCKER.**

**Grade: the MEASUREMENT is settled (§227); the reading is UNDECIDED.**

Both candidate bases are now measured to be somebody's per-algorithm parameter bank — `0x00` is
unit 0's (§226) and `0x90` is unit 1's (§227). So a **canned, effect-independent header** is
reading the **user's reverb-preset coefficients** as its own. Three readings, and they are
separable:

1. **row 25 is wrong** — `ldptr` does not seed the coefficient cursor. **K3 FORCED that selector
   `0x21` is not the implicit cursor and has said so all along**; row 25 has always been
   SPECULATIVE. If it goes, the kernel's base comes from somewhere else and everything downstream
   of `0x9B` is re-derived.
2. **the base is right and the header legitimately reads the reverb's gains** — it does run
   immediately before the reverb's own CALL, and an input stage reading a send level is not absurd.
3. **the cursor-advance map is wrong**, so the header's cells are not `base+0x00..base+0x13`.

⚠⚠ **A FALSIFIER THAT DISTINGUISHES THEM IS REQUIRED BEFORE ANY OF THEM IS TRIED.** §226 and §227
both caught the same failure mode: *a base that makes a number smaller is not a reading.*
⛔ **NOT base `0x00`** (unit 0's bank; `+2.733 FS` with PEQ loaded, 1.6× worse). ⛔ **NOT a
frame-start seed** (§226; it cannot fail). ⛔ **NOT `NOCARRY`, NOT `P_SHIFT`** (§227).

---

## 13. ★★★ SWEEP THE OTHER TWELVE REVERB PRESETS — one command each, no build

**Grade: the gap §227 named in its own result.** §227 measured **two** presets of fourteen. If the
same 23 cells move for every preset, that set **is** the reverb's parameter block and its
boundaries become MEASURED rather than inferred from the ROM's T1 map — which §227 showed is
**silent on 15 of the 23** movers. `REVIDX=n dsp/tools/reverb_select.lua` then
`python3 dsp/tools/hdrbase.py --score <a> <b>`. ★ Also re-derive **§226 item G's** ten runtime-poke
attributions against the **right** preset.

---

## STANDING CONSTRAINTS FOR WHOEVER TAKES THESE

- ⚠ **`UPD6383_NOZ05` is a RIG, NOT A FIX** — and **it deletes EIGHT words, not two**
  (`iw9 iw19 iw21 iw27 iw33 iw35 iw39 iw45`; its own per-`iw` breakdown always said so).
  ★ **Use `NOZ05 = 2` from now on** (§223): `iw35`/`iw45` only, **2** stores, and it reproduces
  `28/32/28` / `33/40/29` / `2/1/2` **column for column**. ⚠ **It still rails**, and so does the
  shipped build: `§S1` measures **4.924 %** quiet / **4.920 %** loud of all accumulator conversions
  clipping on the shipped default with the input **exactly zero**, at a rate **higher** than the
  loud bucket in the pre-§225 arm and level with it now.
  ⚠ **`5.303 %` / `5.298 %` are the `UPD6383_LFOWRAP=0` CONTROL ARM's numbers** (§223/§224,
  `L_lfowrap_off_225.log.gz`), NOT the shipped build's — §225's `LFOWRAP` ship removed exactly
  `iw92`'s 706 040 quiet / 313 960 loud conversions. **Quote the arm with the number.**
  ★ **§228 RE-CONFIRMED 4.924 % / 4.920 % ON BOTH FRAME CLOCKS** (48 000 and 44 100), to three
  decimals, while the raw counts scaled with the frame count — which is what a pure clock change
  must do, and is the inertness proof for that pass.
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
- ⚠⚠ **`§41` DOES NOT GUARD `P_SHIFT` (§227).** It reads the C-RAM output *levels* `0x06`/`0x86`
  and is UNMOVED by a 2x product rescale (arm Q: `§41` unchanged while `m_rf[0x8D]` halved).
  **`m_rf[0x8D] = 0x009B26 = 39 718` is the guard that actually fires.** Fix this wherever the
  three-guard phrase is quoted.
- ⚠ **VEHICLE**: `-cfg_directory` must carry `:DSPCFG value="3"` (fresh cfg ⇒ **zero DSP frames**,
  no report at all); **`-log` REQUIRED**; `timeout`-wrapped; visible video, **never `-video none`**;
  isolated `-nvram_directory`; ONE run at a time. `build.sh` **exits 0 on compile failure** — grep
  `error:` AND check binary mtime/size; `tools/publish-binary.sh` after every rebuild;
  `dsp/verify.py` must stay **BYTE-MATCH OK**.
- ★★★ **RULE 19 is mechanised**: `§70`/`§211` print **mean and AC span**. `79 438 ± 90` passes
  min-vs-max, the no-stimulus check *and* the translation rule, and is a **DC at −59 dB**. Report
  mean AND AC span, both buckets, both arms, before calling anything audio.
- ★★★ **RUN `python3 dsp/tools/lint_handoff.py` BEFORE HANDING OFF.** It exits non-zero when
  `HANDOFF-NEXT.md`, `LEDGER.md` or this file quotes a mask literal, clip rate, gate default,
  rule number or declared count that disagrees with `upd6383.h` or with the current
  shipped-default log. ⚠ It is scoped to those three files and **NEVER** the register, whose
  older sections legitimately quote superseded values — **do not widen that scope**, it is the
  tool's kill-condition. Findings inside a ⛔/SUPERSEDED heading are INFO by design.
  ⚠ `LEDGER.md`'s tier 0 is a verbatim copy of `LEDGER-HEAD.md` — **edit the HEAD and regenerate.**
- ★★★★ **THE DSP FRAME CLOCK IS 44 100 Hz (§228), NOT THE TONE GENERATOR'S 48 000.** The
  rendering stream is still 48 000 and is load-bearing (the EG law, the voice LP coefficient and
  the pitch step are all expressed against it); `run_frame()` is gated by a 147/160 phase
  accumulator instead. `UPD6383_FRAMEHZ=48000` restores the pre-§228 clock as the two-sided
  control. ⚠ **EVERY FRAME COUNT IN A PRE-§228 LOG IS ON THE 48 000 CLOCK**: a
  `-seconds_to_run 30` vehicle gave **1 440 001** frames and now gives **1 323 000**. The
  arming gates (`S1_ARM_FRAME` 420 000, `§54`'s 300 000, `§38`'s 264 002) are FRAME counts and
  did not move, so their WALL-CLOCK times did (420 000 = 8.75 s → 9.52 s). **Compare RATIOS
  across the clock change, never counts.**
- **Do not ship a default flip on a moved number or a model argument alone.** §217–§221 all correctly
  declined. **A NULL is a fine outcome.**

---

## 14. ★★★★ THE `f31` 3/6/7 READING — **PRE-REGISTERED BY §229, BISECTED, NOT YET RUN**

**Grade: the POPULATION is MEASURED; the reading is UNDECIDED.**

`f31 ∈ {3,6,7}` occurs only with `hi12` bit 5 set — **53 words, 53 of 53** in the corpus, and
**0 counterexamples in 246 952 062 live ALU executions**. It fires at **exactly four sites, all in
the epilogue**: `iw63(3) iw70(3) iw75(7) iw78(6)` — the annotated *"symmetric pair"*, the
*"class 8 post-sum step, OPERATION UNKNOWN"*, and the machine's **only class-D word**, which is
where `§211` measures `ACCB`. **Our model runs all four through `op = f31 & 3` ⇒ HOLD, no product.**

⚠⚠ **`w78` CARRIES TWO CANDIDATE DEFECTS AT ONCE** — the collapsed operation code **and** a
fabricated-zero operand (`SRC 0x0A`, 1 106 028 times). **A joint arm cannot attribute anything.**
Do the `f31` reading FIRST; `SRC 0x0A` SECOND, never together. §226 and §227 both died of exactly
this failure mode.

**Required shape:** env gate, **DEFAULT OFF**, two-sided, unconditional fired count.
**Falsifiers (from §229 §7.1, written before any build):** `m_rf[0x8D]` must stay `0x009B26`;
PARAMETRIC EQ within **0.198 dB**; SINGLE DELAY's `+0.02149296` untouched; `§54` graded FIRST;
`§70`/`§211` as mean AND AC span, both buckets. ★ **§227's guard applies with full force:** a clip
rate that falls because a term stopped being added is a **REGRESSION wearing a good number**.
**Kill condition:** if the reading leaves `§104`'s body-0 and epilogue columns input-INDEPENDENT,
the operation field is not the defect and the four words' silence is elsewhere.

---

## 15. ★★★ RE-GRADE EVERY PUBLISHED NULL AGAINST §229's FABRICATED-ZERO TABLE — no build

Any null quoted for **body 0** (8.772 % invented operands) or the **epilogue** (**28.492 %**) must
now carry that share. **Start with `§211`.** Also **declare the 46-slot body-0 tail**
(`I-RAM[154..199]` is never uploaded; the resident image is 70 words at `[84..153]`) wherever a
body-0 denominator is published, and **convert `§38`'s 264 002** to the 44 100 clock (= frame
246 078 = 5.581 s, measured) wherever it gates an instrument.

---

## ⛔ STRUCK FROM THE STRATEGIC REVIEW'S ACTION LIST — DO NOT DEFER, DO NOT RE-PROPOSE

* **Action 3, the `f98` cross-unit A/B** — ⛔ **NOT VIABLE**, TIER 0b dead end **42**.
* **Action 6's `hi12` bit 5 via ROCK ROTARY** — ⛔ **VOID BY CONFOUND**, TIER 0b dead end **43**;
  the review's own kill-condition cannot fire.
* **Action 6's other two items SHIPPED in §229** (loud fabricated-zero census; unconditional
  per-upload provenance line).
* **Action 2, the 44 100 Hz frame clock — SHIPPED in §228.** **Action 5, the bookkeeping repair —
  SHIPPED in §228** (P1–P9).

---

## 15–19. ★★★ FIVE **CONTROL** REPAIRS — specified by §230, **not shipped** (the lane was contested)

**Grade: FORCED (each replacement is a quantity an existing instrument ALREADY PRINTS).**
Source: `CONTROL-AUDIT_findings.md` (`f601303`) §6 + register **§230**.

⛔ **§230 made NO source change**: `upd6383.cpp` carried **211 uncommitted lines** from a
concurrent lane throughout that pass (register §230 §0). All five are **print-text only** — no
behaviour change, no gate, no mask bit. **Ship them as ONE arm**, certified by the **diff-line**
control (`D1`): every differing line must be one of the restated criteria and **not one a measured
value**. ⚠ **Cite the predicate, not the line** — this file's own item 1 records a guard that moved
`:4059 → :4075 → :4538` in a single day.

**15. `§S1 CONTROL` prints a criterion that was REFUTED on its first run.** It reads
*"must be clips = 0"* and has printed **`706040/706040` — 100 %** in all 12 arms that carry it,
ever since §223 §2 refuted it (the off-by-one, **fifth occurrence**). A permanently-violated
criterion printed beside a result is a trap with a fuse on it.
⇒ **Restate the criterion, not the instrument:** *"`iw34`'s pre-clamp quiet value must equal
**14 428 403**"* — a number **the same line already prints**, and which **moved** in both §227 arms
(`9 311 353` in Q, `8 388 608` in O). Zero new measurement.

**16. `§S3`'s *"EXTERNAL"* control is the SAME PREDICATE AT THE SAME HOOK, and the source says so.**
`if (mode != 1 && dest == 0x06) s3_boot(...)` sits immediately above the mask-bit-26 site with the
identical expression, under a comment calling the identity *"deliberate"*. It validates **counter
plumbing**; it cannot detect a wrong predicate, a wrong `pre`, a wrong epoch-0, a wrong ladder or a
wrong verdict — which is everything `§S3` exists for. This is §224's own *"internal consistency
true by construction is not a self-test"*, one section later.
⇒ **Replace with a genuinely external limb, both already printed:** `§176`'s
`06:8388607(0..8388607/chg1100)` change-count, **or** `§104` row 19's `acc`. ✔ `§S3`'s **ladder**
is independently sound (it moved in `O_227` and `Q_227`), so nothing downstream falls — only the
word *"EXTERNAL"* has to go.

**17. `§44` TAP-TABLE fetches print a clean `0` in 40 of 40 arms.** RULE 20, verbatim: a census
printing a clean zero is indistinguishable from a correct negative. Nobody has established what it
is sensitive to.
⇒ **Print it as *"0 — UNTESTED in this vehicle"***, the way `§NG` and §227's `NOCARRY` banner
already do, **or** point it at a program known to fetch the tap table.

**18. `§41`'s LEVEL GUARD (mask bit 5) has NEVER been observed to fire.** Its line is conditional on
`m_lvlguard_n` and is **absent from all 40 arms**. ⇒ **arm mask bit 5 once, in a throwaway arm, and
record the fired count.** Until then quote it as **UNTESTED**, never as clean.

**19. `§S3-C4` reads `0 PASS` in 7 of 7 arms and has never been exercised in the direction that
would make it fire.** ⇒ **clear mask bit 23 once** to show the count *can* be non-zero.
⚠ Bit 23 is **CONFOUNDED** (six sites) — this is a throwaway demonstration arm, **not** a candidate
for shipping.

★ **AND A SIXTH, cheap and not print-text:** `D1`'s **unit is inconsistent between citations** —
`K1` says *"7 diff lines"* where a raw both-sides `diff` gives 12. **State whether the count is
one-sided or both-sided**, once, wherever `D1` is defined.

---

## ⚠⚠ STANDING ADDITION FROM §230 — READ BEFORE WRITING A FALSIFIER LIST

- ⛔ **`§54` / `§70` / `§211` / rule-19 / `§61` / `§104`'s epilogue `D-I` tally ARE ONE CRITERION.**
  Measured as a **set identity** over the 33 modern arms: identical move-set
  `{C_xb85_full_222, D_xb85_route_222}`. Five of the six are functions of **one local variable at
  one program point** in `present()`. **Quote them as ONE ROW.** Keep them as the output-stage
  watch they are; stop counting them as a battery.
  ⚠⚠ **AND `§70` AND `§211` DIFFER IN KIND** (§229): `w73` reads the accumulator; `w78`'s only
  operand is a zero the emulator **fabricates** (`SRC 0x0A`, 1 106 028 times) with its operation
  code collapsed. Both print `mean 0.0 span 0`; **only one is a statement about the chip.**
- ★★★★ **THE INDEPENDENT SECOND CHECK ON THE OUTPUT STAGE IS `m_rf[0x8D] = 0x009B26 = 39 718`.**
  Its move-set **strictly contains** the null's, it lives in the output stage (`w61`'s self-loop,
  `§104` rows 60/61), **it has actually failed** (`→ 0x7FFFFF` §222; halved in Q; absent in O), and
  §229's fabricated-zero census **clears it** (its non-zero stores come from a third site).
- ★★★ **SINGLE DELAY's falsifier IS USABLE AGAIN, with a restated criterion:**
  `python3 dsp/tools/sd_rerun.py control` — an impulse must return at lag **1001** with sample
  **45074**, the ROM's three-factor product in fixed point. **1 ACCEPT / 7 REJECT, 8 of 8**,
  self-test 13/13. ⛔ It is **SINGLE DELAY's** gain, **not PARAMETRIC EQ's** (PEQ's is the separate
  **0.198 dB** biquad).
- ⛔ **`dsp/verify.py` IS NOT A DEVICE CONTROL** — it reads ROMs and `.dsm` files and **cannot see
  `upd6383.cpp`**. Repo invariant, never a falsifier row for a C++ change.
- ⚠ **`§46`'s non-zero count is a DELAY-LINE-CONTENT detector, not a clean send-state
  discriminator** — `O_227` moves it **1 175 999** times and still scores body-0 `D-I = 0/0/0`.
  **Quote the rig, not the port.**
- ⚠⚠ **CHECK `git -C kn7000_mame status` BEFORE ANY BUILD**, and **never `git checkout` a shared
  working tree**. §230 found 211 uncommitted lines from another lane mid-pass. `gen_ledger.py` and
  `gen_fixlist.py` now take **`UPD6383_SRC_DIR`**; `lint_handoff.py` now considers **git-tracked
  logs only** (it had graded four documents against an untracked arm dropped mid-pass).
