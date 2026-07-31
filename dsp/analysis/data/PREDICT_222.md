# PREDICT_222 — `iw205`'s HEAD: the EPILOGUE CROSSBAR (`§E-D85`) + the PICKUP AUDIT (`§E-D0`)

**Committed BEFORE `build.sh` was run.** Every number below is read out of a log already in
`dsp/analysis/data/`, out of the ROM corpus via `dsp/tools/pat_corpus.py` +
`dsp/tools/dsp_disasm.py`, or out of `kn7000_mame/src/devices/cpu/upd6383/upd6383.{cpp,h}`.

---

## 0. WHAT THIS PASS IS, AND WHY IT IS NOT "DECODE `ACT 0x0D`"

`§221 §10` handed forward **"body-1 `iw205` — `ACT 0x0D`'s DESTINATION"**. The owning note
`IW205-DRAM-D0_findings.md` (`e49da4b`, written in parallel with §221) **already decided the
destination**, and it decided it against a measurement that cannot be argued with:

```
   iw85 = 000.2.0E.1CD   -- the UNIT-0 TWIN of iw205, identical lo12, identical SRC 07 / ACT 0D
   §104 row 85, NOZ05 rig (B_epibus_noz05_221):
        L    quiet  8388607..8388607   loud  -8388608..8388607
        acc  quiet  549755748352..549755748352   loud  -549755813888..549755748352
        8388607 x 65536 = 549755748352   EXACT      -8388608 x 65536 = -549755813888   EXACT
   => ACT 0x0D writes  acc <- L << 16 .  That is m_bx_sel0d = 1, bx_acc_w(L,false), and
      NOTHING ELSE IN THE EIGHT-VALUE MENU produces it.
```

Selector **6** (ADD) is excluded by the absent pedestal (row 84 leaves `acc` at
`902 698 916 773`; an ADD would put row 85's minimum at `−1 391 207 691 857`); selectors
**0/2/3** are excluded by `act0d.py`/`sel0d.py` against a calibration that passes (anchored
`ACT 0x14` = 42/42 on tempB); **4** is a self-write no-op at this site; **5/7** rail unit 1
(`§135`). ⇒ **`ACT 0x0D`'s destination is the ACCUMULATOR, and `m_bx_sel0d` is a REGRESSION
CONTROL, not a worklist item.** `iw205` is a **MESSENGER**: it faithfully loads an empty cell.

**So the head of §221's chain is not the word — it is the CELL.** `D-RAM[0x85]` has no producer.
This pass therefore runs the two experiments the two owning notes pre-registered for exactly that:

* **`§E-D85`** (`PREDICT_D0_producer.md` §5.1) — the **epilogue crossbar** arm, queued behind
  §221 by its own text. It is the ONE actionable form of the structural break §4.3 names:
  **unit 0's producer/consumer pair is (pointer, pointer); unit 1's is (register, pointer)** —
  the only cross-space pair in the machine.
* **`§E-D0`** (`IW205-DRAM-D0_findings.md` §6) — the **pickup address-and-provenance audit**,
  READ-ONLY. Its whole point is `F2`: *does any route write `D-RAM[0x85]`?* It is also the
  CALIBRATION for `§E-D85`, because with the crossbar armed it must report **exactly one**.

⚠ **`m_bx_sel0d` IS FROZEN AT 1 AND NOTHING IN THIS PASS TOUCHES IT.** No global change is made
anywhere. The crossbar arm touches **2 of 285** resident slots.

---

## 1. THE MECHANISM UNDER TEST, STATED SO IT CAN BE WRONG

```
   w63 = 02A79051C3  = 2A7.9.05.1C3   mode 1  addr8 = 05   SRC 07   ACT 03
   w70 = 02A61850C7  = 2A6.1.85.0C7   mode 1  addr8 = 85   SRC 03   ACT 07
   XOR = 0001880104 ; differing bits {2, 8, 19, 23, 24}; bit 19 = addr8 bit 7 = THE UNIT BIT.
   SRC and ACT are TRANSPOSED, and the two addresses are the two units' BASE CELLS.
```

`SRC 0x03` and `ACT 0x03` occur **once each in 2557 plain corpus words**, both in the EPILOGUE,
inside a private contiguous `0x01..0x06` numbering that occurs nowhere else — a crossbar sub-ISA.
The reading under test: **`ACT 0x03` latches the bus; `SRC 0x03` sources that latch; and for
those two words the index is in POINTER space, not register space.** Then

```
   body 0 -> iw111 (bit-4 store, mode 2, dp = 0x05) -> D-RAM[0x05]
          -> w63 reads index 05 -> LATCH -> w70 stores index 85 -> D-RAM[0x85]
          -> iw205 (next frame) -> body 1 -> iw332 -> m_rf[0x8F] -> w65 -> epilogue acc -> w73/w78
```

`§104` row 112 on the rig measures `D-RAM[0x05]` **after `iw111`** as
`8 388 607..8 388 607` quiet / `−8 388 608..8 388 607` loud, flagged `*` and scored
**INPUT-DEPENDENT** by `s104_score.py`. Nothing writes `0x05` between `iw111` and `w63`
(body 1's window is `0x8x`+`0x0E`; kernel B's is `FC..FE`+`0F/8A/D0`). So the latch has a live
term to carry — **and it is the FIRST live term ever offered to the epilogue** (`§221 F1` = 0
of 14).

⚠⚠ **THE RIG'S RAIL IS INHERITED.** `UPD6383_NOZ05` is a RIG, NOT A FIX: its cell `0x05`
**rails at `8 388 607`** in the quiet window. Any downstream quantity it feeds therefore has a
**CONSTANT quiet bucket by construction**. That is a property of the rig, not evidence of a DC —
and it is also not evidence of audio. **Report both buckets; never quote the quiet one alone.**

---

## 2. THE ARMS — ONE BUILD, THREE RUNS, `timeout`-WRAPPED, ONE AT A TIME

| arm | env | role |
|---|---|---|
| **A** | `PICKUP=1 EPIBUS=1` | shipped default. Must reproduce `A_epibus_221` in every shared column |
| **B** | `PICKUP=1 EPIBUS=1 NOZ05=1` | **the rig control**. Must reproduce `B_epibus_noz05_221`. **This is the NULL** |
| **C** | `PICKUP=1 EPIBUS=1 NOZ05=1 XB85=1` | **the experiment** |

Bisection, pre-registered and available **without a rebuild** if C is positive:
`XB85=2` = array route only (no latch, no load); `XB85=3` = latch + load only (no array route).

Vehicle: identical to §217/§220/§221 — `kn7000-emulator`, `-rompath ./roms -skip_gameinfo -log`,
isolated `-nvram_directory`, isolated `-cfg_directory` **carrying `:DSPCFG value="3"`**,
`-pluginspath ./plugins`, `-autoboot_script ../kn7000_mame/scratchpad/coldnotes2.lua`,
`-seconds_to_run 30`, `-window -resolution 640x480` (**never `-video none`**).

---

## 3. THE NULL — COMPUTED FROM THE LOGS ON DISK, BEFORE THE RUN

### 3.1 Vehicle calibration (**a miss VOIDS the run**)

| # | quantity | predicted |
|---|---|---|
| **cal-1** | frames | **1 440 001** |
| **cal-2** | `§104` `nq/nl` | **706 040 / 313 960** |
| **cal-3** | `§54` loud-in frames | **313 960**. **A loud count of 0 VOIDS the run** |
| **cal-4** | settled census window (gate > 900 000) | **540 000 frames** = 226 040 quiet + 313 960 loud |

### 3.2 `§E-D0` — the PICKUP audit. ★ **THE ROW COUNT IS PRE-REGISTERED** (§221's `E1_SLOTS` lesson)

| # | quantity | predicted |
|---|---|---|
| **P0** | **ROWS in the `lo12 == 0x1CD` census** | **exactly 5**: `iw85`, `iw130`, `iw205`, `iw319`, `iw330`. **A different count means the watch list truncated or the machine is not what the static walk says** |
| **P1** | pointer **BEFORE** the post-increment | `05`, `03`, `85`, `85`, `85` — constant on 100 % of settled frames |
| **P2** | pointer **AFTER** the post-increment | `13`, `0D`, `D0`, `8D`, `00` (`addr8` = `+14, +10, +75, +8, +123`) |
| **P3** | route / resolved index | all five `m_dram[m_dp]` **at the BEFORE index** (SRC 0x07, mode 2 ⇒ pointer route) |
| **P4** | writers of **`D-RAM[0x05]`**, settled | **arm A: 6** — `iw9`(site 2), `iw11`(site 3), `iw35`(2), `iw37`(2), `iw45`(2), `iw111`(2), each **540 000**. **arms B/C: 3** — `iw11`, `iw37`, `iw111` (NOZ05 suppresses `iw9/35/45`) |
| **P5** | writers of **`D-RAM[0x85]`**, settled | **arms A and B: ZERO.** **arm C: exactly ONE — `iw70`, site 3, 540 000** |
| **P6** | writers of **`m_rf[0x85]`**, settled | **arms A and B: `iw70`, site 3, 540 000, value `0..0`.** **arm C: ZERO** |
| **P7** | writers of `m_rf[0x05]` | **ZERO in every arm** (host once, pre-settled) |
| **P8** | `ACCB` after `iw205`, arms A and B | **`0..0`**, quiet and loud |

### 3.3 `§222` — the `:2914` / `:3491` UNIT-REBASE DIVERGENCE

Settled statically this pass, and **the run must confirm it is inert**:

```
  resident MODE-1 ACT-07 store words (the :3491 site) : 9
        iw58 addr8=8A  iw59 addr8=0F  iw66 addr8=8C  iw70 addr8=85  iw72 addr8=06   (kernel B / EPILOGUE)
        iw98 iw107 iw139 iw148  addr8=20  -- ESC delay, and mask bit 61 (SET) routes them to m_dp
  of those, executing in UNIT-1 context : 0
  resident MODE-1 BIT-4 store words (the :2914 site)  : 5 ; ONE is in unit 1 --
        iw332 = a16 ROOM REVERB 1 w132, addr8 = 0F -> REBASED to 0x8F
        and §221 MEASURED w65 <- iw332 via m_rf[0x8F] on 540 000 / 540 000 frames.
  corpus BODY images, mode-1 destinations : 7 of 7 are UNIT-RELATIVE (addr8 bit 7 CLEAR),
        0 of 7 absolute -- 5 bit-4 (a08 w101, a09 w47, a10 w67, a16 w132, a72 w53)
        + 2 non-ESC ACT-07 (a04 FLANGER w64, a05 PHASER w105, both addr8 = 0x0E).
```

| # | quantity | predicted |
|---|---|---|
| **D1** | `§222 REBASE DIVERGENCE` count, every arm | **0**, over a **non-zero** evaluation count (~5 per frame). **A non-zero divergence count VOIDS arm C's verdict**, because the two rules then disagree somewhere in the resident frame and the arm is confounded |

### 3.4 `§E-D85` — the crossbar arm's own numbers

| # | quantity | predicted |
|---|---|---|
| **X0** | the FOUR fired counts in arm C, printed **unconditionally with the gate's state** | **all four non-zero**, each ~once per frame. **ANY ZERO ⇒ the arm did not run and no number in it may be quoted** (rule 8, §220-sharpened) |
| **X1** | `§99 MODE-1 STORES -> register file` | arms A/B: **13 cells** including `85:1203840`. arm C: **12 cells, `85` ABSENT.** A machine-reported, unconditional check that the store route actually moved |
| **X2** | `§160 register file, ALL non-zero cells` | **42** in every arm (`m_rf[0x85]` is 0 either way, so it never appears) |

---

## 4. THE FALSIFIERS — EACH NAMES A SPECIFIC WRONG NUMBER

> **`F0` — THE INSTRUMENT CALIBRATION (`§E-D0` `F3`), and it can fail.**
> In arms B and C, `ACCA` after `iw85` equals **`L × 65536` exactly**, with `L` loud
> `−8 388 608 .. 8 388 607` and `acc` loud `−549 755 813 888 .. 549 755 748 352`.
> **`F0` FAILS ⇒ the run is VOID** — the pickup the whole model rests on is broken and no other
> number may be quoted. Named wrong numbers: row-85 `acc` min **`−1 391 207 691 857`** (an ADD
> arm); operand address **`0xD0`** (a post-increment-sampled instrument, third occurrence of that
> trap).

> **`F1` — THE REGRESSION CONTROL WHOSE ANSWER IS ALREADY KNOWN.**
> `§160` must still read **`8D=009B26`** (`= 39 718 = 2 603 010 048 >> 16`, EXACT) and `§41` must
> still read **unit0 `0x400000`, unit1 `0x178D0B`, non-zero on 1 172 160 / 1 172 160**.
> **`F1` FAILS ⇒ the gate leaked past its two words; VOID.** Neither value is produced by the
> route under test (`0x8D` comes from a mode-1 **bit-4** store, `0x400000` from the **host** via
> the mode-1 **read**), which is what makes this a calibration and not a restatement.

> **`F2` — THE RESULT, AND THE NUMBER TO BEAT IS NOT ZERO.**
> `§104` row 205's `mem` column becomes `*`, and body 1's `s104_score.py` counts rise **above
> `2 / 1 / 2`** (acc / mem / L). ★ **`2/1/2`, not `0/0/0`** — body 1 already scores `2/1/2` in
> BOTH `NOZ05` arms (`iw202` mem+L, `iw203`/`iw204` acc, `iw325` L). Predicted row-205 `mem` if
> the arm works: **quiet `8 388 607..8 388 607`, loud `−8 388 608..8 388 607`** — i.e. exactly
> row 112's column on the same rig, one frame late.
> **`F2` FAILS ⇒ the crossbar reading is DEAD**, `iw70` is exonerated for good, and `SRC 0x03` /
> `ACT 0x03` / the bit-23 routing come off the worklist. **Given `PREDICT_D0_producer.md` §2,
> `F2` FAILING IS THE PREDICTED OUTCOME and is a full result.**

> **`F3` — THE BODY-0 REGRESSION CONTROL.**
> Body 0 must stay at **`28 / 32 / 28`** and `§104` row 85's `acc` must stay exactly `L × 65536`.
> **`F3` FAILS ⇒ VOID.** Named wrong number: `w78` mean **`79 438 ± 90`** — the −59 dB DC that
> passes standing rule 1 *and* §211's translation rule and **IS** the signature of a broken
> `iw85` pickup.

> **`F4` — RULE 19, MECHANISED (`§70` / `§211` now print MEAN and AC SPAN).**
> **Report `§70` and `§211`'s mean AND AC span, in BOTH buckets, in BOTH arms, before the word
> "audio" is used anywhere.** A non-zero presentation is a **DC** unless the loud AC span exceeds
> the quiet AC span by more than **2.2×** — the ratio the `79 438 ± 90` counter-example already
> achieves *without being audio*.
> ⚠ **THE CONSTANT-FILL TRAP, with its numbers named in advance:** if row 205's `mem` reads
> **`39 718`** or **`4 194 304`**, or row 205's `acc` reads **`2 603 010 048`**, the arm has
> published a **DC** and must be REJECTED. A reverb fed a constant is a constant.
> ⚠ And the rig's own rail: a **quiet AC span of 0** in arm C is EXPECTED and is NOT a DC verdict
> by itself, because `NOZ05`'s cell `0x05` rails in the quiet window.

> **`F5` — ATTRIBUTION.** `§99`'s mode-1 census must lose `85:` in arm C (13 cells → 12).
> **`F5` FAILS ⇒ the store route did not fire**, and any movement in `F2` is unattributable to
> this arm.

---

## 5. THE DECISION RULE, WRITTEN BEFORE THE DATA

* **`F0` or `F1` or `F3` fails, or `D1` ≠ 0, or any of `X0`'s four counts is 0** ⇒ **VOID.**
  Fix the scope, re-run. **No number from a void run may be quoted anywhere.**
* **`F0`/`F1`/`F3` hold and `F2` fails** (the PREDICTED outcome) ⇒ the epilogue crossbar is
  **dead**; `iw70`'s routing is exonerated; unit 1's starvation folds into §216/§221's single
  blocker; `SRC 0x03`, `ACT 0x03` and bit-23 routing are RETIRED. A **NULL is a fine outcome.**
* **`F2` holds** ⇒ **BISECT FIRST** (`XB85=2` route-only vs `XB85=3` latch-only), then report.
  ⚠ **NO DEFAULT FLIP IN THIS PASS REGARDLESS OF THE RESULT.** A compound three-part arm that
  moves a number is a *claim*, not a fix — §217, §218, §219, §220 and §221 all correctly declined
  on exactly this ground, and this arm is the most speculative of the six (`n = 1` per code; no
  corpus statistic can support or refute the latch reading).

---

## 6. WHAT SHIPS, AND WHAT DOES NOT

**SHIPS regardless of outcome:**
* `UPD6383_XB85` — env, **DEFAULT OFF**, announced unconditionally, **four** fired counts printed
  unconditionally with the gate's state.
* `UPD6383_PICKUP` — env, **DEFAULT OFF**, READ-ONLY, fired count printed unconditionally.
* the `:2914`/`:3491` **unit-rebase unification** *plus* its unconditional divergence counter —
  justified by measurement (`iw332 → 0x8F` read back by `w65`, 540 000/540 000) and by the corpus
  (**7 of 7** body-image mode-1 destinations unit-relative, **0 of 7** absolute), and **provably
  inert in the resident frame** (`D1 = 0`). ⚠ If `D1 ≠ 0` the unification is a behaviour change
  and must be gated instead — that is the pre-registered fallback.
* `dsp/tools/rebase_census.py`, three logs, this file, and register section **§222**.

**DOES NOT SHIP:** any default flip; any mask bit; any change to `m_bx_sel0d`; `UPD6383_NOZ05`
stays **DEFAULT OFF** (§220 §6's three reasons are untouched). `dsp/verify.py` must stay
**BYTE-MATCH OK**.

---

## 7. HONEST LIMITS, STATED BEFORE THE RUN

* **The arm is COMPOUND.** Latch, load and array route are inseparable *a priori*. A positive
  `F2` cannot be attributed to one of them without the `XB85=2`/`XB85=3` bisection.
* **`SRC 0x03` and `ACT 0x03` are `n = 1` each.** No corpus statistic can decide the latch
  reading. Grade: **SPECULATIVE**, deliberately.
* **The rig rails.** Everything downstream of `NOZ05` inherits a constant quiet bucket. Nothing
  the rig rails on is evidence (§176's warning, fourth occurrence).
* **One frame of latency is assumed**, because `w63`/`w70` execute *after* body 1 in the frame.
  If the real chip's crossbar is intra-frame, this model is right in kind and wrong by one sample.
* **`§221` guarantees the epilogue currently receives nothing** (`F1` = 0 of 14). If `F2` holds,
  that is because this arm *created* the link — which is precisely why no default flip follows
  from one run.
