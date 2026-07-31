# BUILD-LANE QUEUE — work that is READY and is only waiting for the serialized lane

**Purpose.** Only one agent may edit source, rebuild or run MAME. Read-only passes have been
producing applicable fixes faster than the lane can consume them. Without this file those fixes
decay into things somebody re-derives in three weeks — which is this project's most expensive
recurring failure (14+ passes lost, rules 3 and 13).

**Status of each item is the state at the time it was filed.** ⚠ `HANDOFF-NEXT.md` §1 and the
register tail are AUTHORITATIVE and fresher; §222 was mid-pass when this was written and may
supersede items 4 and 5. **Check the tail before starting anything here.**

---

## 1. Narrow the nop guard — **PROVEN BY CONSTRUCTION, ready to ship**

**Grade: FORCED.** Source: `NOP-GUARD_findings.md` (`09edb4e`).

The core's guard tests `hi12 == 0x000 ∧ class4 == 2 ∧ lo12 == 0x000` and **not `addr8`**, swallowing
**103 words across 28 of 40 streams**. **The correct narrower predicate already exists TWICE in this
repo**: `decoded()` (`upd6383d.cpp:728`) requires `ad == 0x00`, and the listings render the extras as
`?word`. **The core is the only one of three implementations that swallows them.**

**Safe by construction**: `exec_alu()` ends with the identical `(cl & 7) == 2 → m_dp += dd`, so the
address generator is bit-identical either way.

⚠ **Cite the predicate, not the line** — this guard moved `:4059 → :4075 → :4538` in one day while
two lanes shared the file.

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

## 4. `§E-D85`, the epilogue-crossbar arm — **queued deliberately**

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

---

## 5. Body-0's coefficient cursor at `iw112`

**Grade: pre-registered by §221 as its next-after.** ⚠ §222 may have taken or superseded this.

---

## 6. The mode-1 store unit-rebase divergence — **decide it**

**Grade: MEASURED (inert today).** Source: `PREDICT_D0_producer.md` (`64d1cb0`).

The two mode-1 store sites disagree: `:2914` uses `addr8 | (m_cur_unit1 ? 0x80 : 0)`, `:3491` uses
**bare `addr8`** — beneath a banner reading *"§99: one rule for both store sites"*. Inert in the
resident frame, so it changes nothing today; it is the kind of latent asymmetry that surfaces months
later as an unexplained result. Handed to the lane by the pass that found it.

---

## STANDING CONSTRAINTS FOR WHOEVER TAKES THESE

- ⚠ **`UPD6383_NOZ05` is a RIG, NOT A FIX.** It deletes two stores the corpus contains and its cell
  `0x05` **rails** in the quiet window. Drive signal with it; never ship it; **treat nothing it rails
  on as evidence.**
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
