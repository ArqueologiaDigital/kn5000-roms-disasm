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

## 7. ★★★ FLIP `UPD6383_LFOWRAP` TO DEFAULT ON — **fully measured, one gate left**

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

## 8. Kernel A's cell-`0x06` LATCH-UP needs a **BOOT-WINDOW** instrument

**Grade: MEASURED (the latch), UNMEASURABLE with what exists (its cause).** Source: `§224` §2.

`§S2` shows `iw13`/`iw14` taking `mem[0x06]` onto the `ACT 0x00` bus **at unity** while `iw19`
stores the clamped accumulator back into `0x06`; `iw13`'s other two terms sum to `0.870 × FS`, so
the rail is a **stable second state**, not a gain error.
⚠⚠ **`§S1`, `§S2` and `§104` all arm at frame 420 000** (`S1_ARM_FRAME`, the audit's unified
window) **and therefore CANNOT SEE the transition into it.** Whoever takes this must build a
boot-window sampler and **state its arming in the prediction** — the opposite trap to §193/§204's
("a histogram over boot measures boot"), and just as expensive.

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
- ★★★ **RULE 21 (§224): `§104`'s and `§86`'s quiet-vs-loud markers CANNOT DISTINGUISH
  "input-dependent" from "free-running and sampled over two frame sets".** Cell `0x07`, the LFO
  phase, has been flagged `INPUT-DEPENDENT` in every log ever taken and has no input in it.
  **Never grade a cell carrying an LFO, a counter or a ramp on them.**
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
