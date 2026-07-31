# LEDGER — every hypothesis, its mask bit, and its verdict

**Read this file before starting any DSP work. It exists because ten passes on this project were
lost to re-asking a question the notes had already answered, or re-trying an approach a previous
section had already refuted.** A 6000-line register does not prevent that; an index read *first*
does.

Tiers, cheapest first — stop as soon as you have what you need:

| tier | what | where |
|---|---|---|
| **0** | the current blocker + **the dead ends** | this page, below |
| **1** | the mask-bit register — every bit, its state, its § | generated, below |
| **2** | the section index — every section, one line each | generated, below |
| **3** | the sections themselves | `SPECULATIVE-APPLIED-REGISTER.md` |

⚠ Tiers 1 and 2 are **generated** by `tools/gen_ledger.py` from the C++ source and the register's
own headings, so they cannot drift. Tier 0 is hand-written. **Re-run the generator after any
section or mask-bit change**; do not hand-edit `LEDGER.md`.

---

## TIER 0a — THE CURRENT BLOCKER  (§225, 2026-07-31)

> **★★★★ `§S2sq` — THE COEFFICIENT SQUARING — IS THE BLOCKER, AND §225 GAVE IT A MEASURED
> CONSEQUENCE.**
> `SRC 0x08` resolves to `C-RAM[m_cursor]`; on a class-A word the multiply reads
> `C-RAM[m_cursor]` **again**, before the post-increment, so the product is the coefficient
> **SQUARED**. It fires **5 100 000** times a run at `iw30 iw32 iw33 iw41 iw89`.
> ★★★ **The FIRST non-zero datum ever placed in D-RAM cell `0x06`** — caught by `§S3` at store
> **#1360**, frame 264 002 — is **`iw33`'s `6 039 795` = `C-RAM[0x9B]² >> 6` = `0.720 × FS`**,
> a coefficient squared and **not a sample**; and `§224` §1 showed `iw33`'s two product terms
> **alone exceed full scale** (`1.720 × FS`; zeroing the `ACT 0x00` bus term still leaves
> `1.220 × FS`). ⇒ **the cell-`0x06` rail and `§S2sq` are the same defect.**
>
> **THE QUESTION:** should the **multiply** read `C-RAM[cursor + 1]` while `SRC 0x08` reads
> `C-RAM[cursor]`?
> ⛔ **DO NOT TOUCH THE SOURCE READ** — ANCHORED by the LFO rate (`C-RAM[0x00] = 114` ⇒
> `+114`/frame, `§109`; `§196` measures the wrap period at 96 000 frames = **0.5000 Hz**).
> **Two-sided, DEFAULT OFF, unconditional fired count.** Falsifiers: `§41`, SINGLE DELAY's
> validated `+0.02149296` three-factor product, **and now `§S3`'s ladder** — a correct reading
> must move store #1357's `1 650 061` and #1360's `6 039 795`, and `§S1`'s 4.924 % with them.
>
> ⇒ ★★★★ **AND §224's "CELL-`0x06` LATCH-UP" IS ANSWERED AND ITS FRAMING RETIRED.** `§S3` — a
> boot-window recorder with **NO FRAME GATE**, ladder unbounded in time — reports `SETTLING`:
> ```
>    §S3 EPOCH-0 (the PRE-EXECUTION state, 0 prior writes): frame 204731 iw73 pre 0 val 0
>    stores #1..#1356 write EXACTLY ZERO   (the ladder's lowest rung is "val >= 1"
>                                           and it first fires at #1357 -- MEASURED)
>    #1357  frame 264002  iw19  pre 0        val 1 650 061  (0.1967 FS)  <- THE ENTRY
>    #1360  frame 264002  iw33  pre 0        val 6 039 795  (0.720  FS)
>    #1362  frame 264003  iw19  pre 8217878  val 8 388 607   RAILED
> ```
> ⇒ ⛔ **`0` IS NOT A FIXED POINT. There is NO second state; "BISTABLE" is RETIRED.** `iw19`'s
> **first ever** store, from an **EMPTY** cell, is already **1.52 ×** the `0.129 703 × FS`
> threshold and the rail follows **on the next frame**. The rail needs a **FORWARD GAIN**
> explained, not an entry.
> ★ **HOW `§S3` BEAT RULE 16, and this is the transferable part:** it does **not** sample a time
> window. It records **STORES** and splits them by a property of the **DATUM** — the first
> store's `pre` is *by construction* the state before any instruction wrote the cell, every later
> `pre` is *by construction* an instruction's result — and prints the verdict as the **RELATION**
> between them (`RESET-STATE` / `SETTLING` / `NO CROSSING`, unconditional).
> ★ **External control passed to the unit:** mask bit 26 counts the identical predicate at the
> identical hook and `§220` measured **5 881 351**; `§S3` reports **5 881 351**.
> ★ **`S3-C4` passed:** **0** host tag-`0x15` writes reach D-RAM `0x06` (mask bit 23 SET ⇒
> `m_rf[0x06]`) — the entry is **not** the host's `+0.5` level poke.
> ⚠ **`§106`'s cell-`0x06` writer list is WRONG** — 5 names of **12**, and `5 881 351` was never
> divisible by `5`. **Quote `nz`, never just the count:**
> ```
>    RAILS IT   (nz on ~every frame INCLUDING all 706 040 SILENT ones)
>       iw19:1176011(nz 1175999)  iw33:1176007(nz 1175999)  iw39:1176003(nz 1175999)
>    INPUT-DEPENDENT (nz 313 127 ~ the 313 960 loud frames) -- NOT what rails it
>       iw21:1176011(nz 313127)   iw27:1176011(nz 313127)
>    ZEROS ONLY (1308 stores -- the traffic holding the cell at 0 for 1356 stores)
>       iw73:98  iw78:196  iw9:23  iw11:19  iw35:8  iw45:4  iw321:960     all nz 0
> ```
>
> ⇒ ★★★★ **AND RULE 21's BLAST RADIUS IS NOW BOUNDED — `28/32/28` SURVIVES.** The discriminator
> is **forced by the instrument's own bucket predicate**
> (`nz = (m_in_val[0] != 0) || (m_in_val[1] != 0)`): the quiet bucket is frames where the input
> is **EXACTLY ZERO**, the same value on all 706 040 of them, so a **DEGENERATE quiet range
> (`min == max`) PROVES input dependence** — nothing free-running can be a point over 706 040
> frames — and a non-degenerate one proves free-running state.
> ```
>    body 0  NOZ05 (send OPEN)   28/32/28 = I 26/28/27 + FREE 0/4/1 + UND 2/0/0
>    body 0  shipped (send SHUT)  2/4/1   = I  0/0/0   + FREE 2/4/1      <- 100 % ARTEFACT
>    body 1  2/1/2 = I 2/1/2  |  XB85 59/44/49 = I 59/44/49  |  epilogue 22/19/9 = I 22/19/9
>    kernel A NOZ05 33/40/29 = I 33/35/27 + FREE 0/5/2
> ```
> ⇒ **`26/28/27` is proof-grade; the free part is EXACTLY the four cell-`0x07` rows.**
> ⇒ ⚠⚠ **`2/4/1` — the shipped-build "null" — IS 100 % FREE-RUNNING. Body 0 on the shipped build
> is `0/0/0`**, so `28/32/28`'s true delta is `26/28/27` over `0/0/0` and the *"the rig delivers
> signal to the bodies"* claim comes out **STRONGER**, not weaker.
> ★ **The two controls that make this more than a criterion somebody invented:** opening the send
> is the *only* difference between arms A and C and a ramp is present in **both**, so the slots
> newly `*` in C cannot be free-running — **the differential and the classifier agree
> `26 = 26 / 28 = 28 / 27 = 27`, and the `mem`/`L` sets coincide element for element.**
> ⛔ **NEVER QUOTE A `§104`/`§86` COUNT AGAIN WITHOUT ITS `D-I` SPLIT.**
> `dsp/tools/rule21_all.py <log>` does it in one line.
> ⚠ Region boundaries, from the device's own labels (`upd6383.cpp:630`): kernel A `0..49`,
> kernel B `50..59`, **epilogue `60..82`**, body 0 `84..199`, body 1 `200..332`. The epilogue is
> INSIDE the low range; a naïve `333..` slice reports `0/0/0` for `22/19/9` forever.
>
> ★ **SHIPPED by §225:** `UPD6383_LFOWRAP` **DEFAULT ON** — `iw91` applies `C-RAM[0x01] =
> 0x7FFFFF` (the constant the source's own annotation calls *"wrap"*) as a **MODULUS**, at the
> adder only, so cell `0x10` carries the chorus LFO instead of a full-scale DC. The gate `W4`
> was **restated** to grade degenerate-quiet markers only (which **cannot** fire on a ramp, and
> which **can** still fail — the XB85 arms score body-0 `D-I` = `26/23/23`) and it is
> `0/0/0` → `0/0/0`; `K1` diffs arm K (no env) against §224's arm J in **7 lines, not one a
> measured value**; `K2` shows `=0` still reproduces arm I exactly. Also shipped: **`§S3`**, and
> `dsp/tools/{parse104,rule21,rule21_detail,rule21_all}.py`.
> Logs: `data/{K_lfowrap_default,L_lfowrap_off,M_s3_census}_225.log.gz`.
> `dsp/verify.py`: **BYTE-MATCH OK.**
>
> ★★★ **METHOD, §225's three:** (1) **RULE 21 is now OPERATIONAL, not a warning** — and its
> `1 %` `X-ramp` threshold is **not load-bearing** (worst FREE extra-reach across 33 logs is
> **0.000048 % of span**, a 20 971 × margin). (2) **A gate must be able to fail, and saying so
> means NAMING AN ARM WHERE IT DOES.** (3) **A boot-window instrument need not trade off RULE 16**
> if it splits epochs by a property of the datum rather than by a time threshold.
> ⚠ **The overflow counter earned its keep on its first run**: `§S3`'s 8-slot writer census
> overflowed **2 352 974** times and *said so* — without it the truncated 8-name list would have
> looked complete and would have "confirmed" `§106`.

## TIER 0a-prev-224 — §224's BLOCKER, SUPERSEDED by §225 (the latch-up framing is RETIRED)

> **★★★ KERNEL A's D-RAM CELL `0x06` IS A LATCH-UP, NOT A GAIN ERROR — AND `§S2` NAMES IT TERM BY
> TERM.**
> §224 built `§S2`, an accumulator TERM census at the adder: per `iw`, per `§54` bucket, the three
> physical addends register row 26 names (`CARRIED`, the `ACT 0x00` `BUS` term, `P`) with their
> full-scale ratios and the `SRC` codes that fed the bus.
>
> ```
>    iw13  carried 239 225 266 218 + bus 549 755 748 352 + P 239 225 266 218 = 1.870 x FS
>    iw14  carried             0   + bus 549 755 748 352 + P 239 225 266 218 = 1.435 x FS
>    busSRC 00 = mem[ptr] = CELL 0x06, at UNITY.  §96: iw19 STORES the clamp back into 0x06.
>    549 755 748 352 = 0x7FFFFF << 16.   §176 shipped:  06:8388607(0..8388607/chg1100)
> ```
>
> **`iw13`'s other two terms sum to `0.870 × FS` — BELOW the rail — so the loop has a STABLE
> SECOND STATE and the shipped build sits in it with zero input.** ⇒ **Find what first drives cell
> `0x06` past ≈ `0.13 × FS`.** ⚠⚠ **`§S1`, `§S2` and `§104` ALL arm at frame 420 000 and CANNOT
> SEE IT** — a boot-window instrument is required and its arming must be stated in the prediction.
>
> ⇒ ★★★ **§223's BLOCKER IS ANSWERED AND ITS CANDIDATE IS REFUTED.** `iw34` is `000.A.FF.407`:
> `lo12 0x407` ⇒ **`SRC 0x10` = the ACCUMULATOR** — the censused conversion is the accumulator
> being placed on the **bus**, not a store's datum, and its value is `§104` row **33**'s
> `acc >> 16`. The ladder is three terms, **not one of them a sample**:
> `C-RAM[9B]² >> 6` (0.720) + `C-RAM[9D] << 16` (0.500) + `C-RAM[9C]² >> 6` (0.500) = **1.720 × FS
> at `iw33`, the true overflow site.** ⇒ ⛔ **zero the `ACT 0x00` bus term and `iw33` still leaves
> `10 234 099 = 1.220 × FS`. STILL CLIPS.** Refuted from disk, no build.
>
> ⇒ ★★★ **WHERE THE BUS TERM *IS* THE CAUSE, THE ADDEND IS THE WRAP CONSTANT.**
> `iw92 − iw91 = 8 388 607` **exactly, both endpoints, both buckets**, and
> `8 388 607 = 0x7FFFFF = C-RAM[0x01]` — which `upd6383.cpp`'s **own** annotation calls *"wrap"*.
> `iw91` is `§118`'s wrap word (`ST mem[Q] <- (phase + INC) mod 2**23`); the model **ADDS the
> modulus**, so `iw92` publishes `clamp(phase + INC + 0x7FFFFF)` and cell `0x10` — `§120`'s
> modulation cell — is a full-scale DC while the phase ramps correctly at `+114`/frame in `0x07`.
>
> **`UPD6383_LFOWRAP=1` (arm J) passes EVERY falsifier but one, and the one that decides it is
> POSITIVE:**
> ```
>    W0 fired 1 176 960, ONE slot (iw91)                                          PASS
>    W1 §S1 quiet 9 884 596 -> 9 178 556 = -706 040 EXACTLY  (5.303 % -> 4.924 %)
>       §S1 loud  4 391 682 -> 4 077 722 = -313 960 EXACTLY  (5.298 % -> 4.920 %) PASS
>    W2 §119 iw94 mem[dp10]  8388607 x8 -> 1006898 1007012 ... 1007696            PASS
>       -- a +114/frame RAMP.  THE CHORUS LFO REACHES ITS PUBLISHED CELL.
>    W3 §41 0x400000/0x178D0B | m_rf[8D]=009B26 | §54 quiet-in 826 040 -> 826 040
>       SILENT / 0 LOUD (peak 0) | §70 mean 0.0 span 0, §211 mean 0.0 span 0,
>       BOTH buckets BOTH arms | §S1 iw39 loud min 1 991 044                      PASS
>    W4 §104 body 0  2/4/1 -> 2/9/4                                               FAIL
>    R1 arm I vs F_satcen_223.log.gz: NOT ONE measured value moved                PASS
> ```
> ⚠ **IT DOES NOT SHIP AS A DEFAULT** because `W4` was a gate this pass set for itself and it
> failed. ⚠ **`W4`'s failure is an INSTRUMENT ARTEFACT (RULE 21 below);** the `acc` column is
> unchanged at 2 and what moved is `mem`/`L` on the six slots that read cell `0x10`.
> ⇒ **§225: restate `W4` so it cannot fire on a ramp, then FLIP `UPD6383_LFOWRAP`.**
>
> ★ **SHIPPED by §224:** `§S2` (read-only, always on, 48-row cap **with** overflow counter, four
> pre-registered cross-instrument controls printed beside the table, and a 44-bit-overflow count);
> `§S2sq`, the coefficient-squaring counter (**5 100 000**, slots `iw30 iw32 iw33 iw41 iw89`);
> the `§S1 PROVENANCE` line; `UPD6383_LFOWRAP`, **default OFF**, gated by **predicate** not line.
> Logs: `data/{I_s2,J_lfowrap}_224.log.gz`. `dsp/verify.py`: **BYTE-MATCH OK.**
>
> ★★★ **RULE 21 (NEW): `§104`'s and `§86`'s quiet-vs-loud markers CANNOT DISTINGUISH
> "input-dependent" from "FREE-RUNNING AND SAMPLED OVER TWO FRAME SETS".** Proof from a case that
> predates the change and sits in **every** log this project has taken:
> `★ cell 07  quiet [4 .. 8388594]  loud [8 .. 8388598]` — that is the **LFO PHASE**, with no
> input in it at all, flagged `INPUT-DEPENDENT` in both arms. Both buckets cover the whole ramp;
> the endpoints differ by **less than one increment (114)** because the buckets are different
> *sets of frames*. **Never grade a cell carrying an LFO, a counter or a free-running ramp on
> them.**
> ★★ **`§S1`'s VALUE IS THE PRE-UPDATE ACCUMULATOR** = the PREVIOUS slot's `§104` `acc >> 16`,
> verified **8 of 8**, both endpoints, from disk. `iw34 = row 33`, `iw92 = row 91`, `iw39 = row 38`.
> ★★ **A CENSUS WHOSE INTERNAL CONSISTENCY IS TRUE BY CONSTRUCTION IS NOT A SELF-TEST** — `§S2`'s
> source says so, and its real controls are **external and pre-registered**.
> ⚠ **The kernel's C-RAM block is Q23** (`0x4CCCCC = 0.600000` … `0x600000 = 0.750000`, eight round
> decimals ≤ 0.75), so `P = (coef × L) >> 6` with `ACC_SHIFT = 16` is **2 ×** a Q23 product. That
> is an **OBSERVATION, NOT A PROPOSAL** — `ACC_SHIFT = 22 − P_SHIFT` ties them, `§41` and
> `m_rf[0x8D]` calibrate `ACC_SHIFT`, and halving the products alone leaves `iw33` at `1.110 × FS`.

## TIER 0a-prev-223 — §223's BLOCKER, SUPERSEDED by §224 (and its CANDIDATE refuted)

> **★★★ THE BLOCKER IS A WORD, NOT A RIG: `iw34` CONVERTS A CONSTANT `14 428 403` = 1.720 × FULL
> SCALE AND CLIPS ON 1 020 000 OF 1 020 000 CONVERSIONS — QUIET AND LOUD, SHIPPED BUILD AND BOTH
> RIGS.**
> §223 built `§S1`, a saturation census on `acc_to_datum()`'s **pre-clamp** value, per `iw`, per
> `§54` bucket, settled frames only. Run on the **shipped default** with the input **exactly zero**:
>
> ```
>    arm F  SHIPPED   quiet  9 884 596 clip / 186 394 560 conversions = 5.303 %   <- ZERO INPUT
>                     loud   4 391 682 clip /  82 885 440             = 5.298 %   <- LOWER
>    arm G  NOZ05=1   quiet 14 826 840 / 177 922 080 = 8.333 %
>    arm H  NOZ05=2   quiet 17 651 000 / 180 746 240 = 9.766 %
>       H - G = +2 824 160 clip / +2 824 160 conv (quiet), +1 255 624 / +1 255 840 (loud)
>             = EXACTLY iw9's row, and 100 % of iw9's quiet conversions CLIP
>    SEVEN sites clip on 100 % of quiet frames in arm F.  iw34: 14 428 403 in BOTH buckets, ALL
>    THREE ARMS.  iw92 (body 0): pre-clamp MINIMUM 8 388 725 -- above the rail before the range opens.
>    §54 all three arms: quiet-in 826 040 -> 826 040 SILENT / 0 LOUD (peak 0); loud-in 313 960
>                        -> 313 960 silent / 0 loud (peak 0).  §70/§211 mean 0.0 span 0, both buckets.
>    §104  arm F 27/26/20 | 2/4/1 | 0/0/0 | 0/0/0   arms G AND H  33/40/29 | 28/32/28 | 2/1/2 | 0/0/0
> ```
>
> ⇒ ★★★ **THE PEDESTAL IS IN THE SHIPPED MODEL.** `UPD6383_NOZ05` does not create it; it removes
> the two stores that were **hiding** it from body 0. §222's *"the pedestal is the rig's own rail"*
> is corrected to that.
> ⇒ ⛔ **§222's PRE-REGISTERED NEXT EXPERIMENT IS REFUTED FROM DISK, WITH NO RUN.** `iw35`'s
> POST-update accumulator `908 714 800 127 >> 16 = 13 865 887` = **1.653 × FS, CLIPS**; `iw45`'s
> `538 760 587 509 >> 16 = 8 220 834` = **98.0 % of FS, constant in both buckets**. A post-update
> store deposits **the rail** it was proposed to remove.
> ⇒ ⛔ **NO STORE-SUPPRESSION RIG AVOIDS THE RAIL.** `NOZ05 = 2` (the narrow rig: `iw35`/`iw45`
> only, 2 stores instead of mode 1's **8**) reproduces `28/32/28` / `33/40/29` / `2/1/2` **column
> for column** and **still rails** `D-RAM[05]` at `8 388 607`, with `iw9` restored and railing too.
>
> ⇒ **NEXT: (1)** name the words that build the accumulator between `iw30` and `iw34` and grade
> each one's contribution against full scale — **no rig needed**, `iw34` is input-, rig- and
> arm-independent. Grade on `§S1`'s per-`iw` clip count, **never** on `§70`/`§211`.
> **(2)** `ACT 0x00`'s **BUS TERM** is the leading structural candidate: row 26 makes ACTION `0x00`
> **ADD** `L << 16`, the kernel's bus carries coefficient-magnitude constants (`4 194 304` is
> exactly **½ FS**), so three such words pass full scale with no attenuation — **a unity-gain comb
> fed a DC ramps to the rail**. Two-sided, env-gated, DEFAULT OFF, fired count; the falsifier is
> `§S1`'s quiet clip rate FALLING while `§41` and `m_rf[0x8D]` do not move.
> **(3)** body-0's coefficient cursor at `iw112` — `RISK-TRIAGE_findings.md` §5 resolved the
> `coef 0..24` vs `0x1364D9` conflict with zero runs and the **×24 attenuation STANDS**.
> ⛔ **NOT `ACC_SHIFT`** on a moved number — `§41` (`0x400000` / `0x178D0B`) and
> `m_rf[0x8D] = 0x009B26` calibrate it and both passed in all three arms.
> ⛔ **NOT `ACT 0x0D` / `m_bx_sel0d` / `iw205`**; ⛔ **NOT `SRC 0x03`/`ACT 0x03` as a latch**;
> ⛔ **NOT the epilogue's operand set** — all closed by §222 and unchanged.
>
> ★ **SHIPPED by §223:** `§S1` (read-only, always on, 48-row cap **with** an overflow counter);
> `UPD6383_NOZ05` as a **mode** (0/1/2, default OFF, mode 1 verified bit-identical to §222 arm B);
> the **nop guard narrowed** by `addr8 == 0x00` — `§NG` = 2 371 200 words, and arm F's whole report
> `diff`s against §222's archived arm A in **29 lines of which NOT ONE is a measured value**;
> and a **latent runaway `logerror`** (`§90`, bounded by a counter another site owned) fixed.
> Logs: `data/{F_satcen,G_noz05m1,H_noz05m2}_223.log.gz`.
> ★★ **METHOD, and it cost a control:** **state which side of the slot a predicted number came
> from, in the prediction.** `PREDICT_223`'s `S2` took `iw34`'s value from `§104` row 34's `acc`,
> which is *"acc AFTER the slot"*, where the store's datum is the **PRE**-update accumulator —
> row 33's. Off-by-one, **fifth occurrence**. ★ **A pure observer's known-answer control must come
> from a different instrument:** `§S1` printed `iw39`'s loud minimum as `1 991 044`, the number §220
> established by `kwatch` two sections earlier, digit for digit, without being told.

## TIER 0a-prev-222 — §222's BLOCKER, SUPERSEDED by §223 (and its ATTRIBUTION corrected)

> **★★★ THE BLOCKER IS NOW THE RIG ITSELF: `UPD6383_NOZ05` RAILS `D-RAM[0x05]` AT `8 388 607` ON
> EVERY QUIET FRAME, AND IT IS THE ONLY ARM THAT MAKES UNIT 0 LIVE.**
> §222 forced unit 1's empty input cell open (the epilogue-crossbar arm, `UPD6383_XB85`), and the
> output stage **left zero for the first time in the project** — `§70`/`§211` went from
> `min 0 max 0` to means of `3.53e11` / `1.21e12`, body 1 from `2/1/2` to `59/44/49`, the epilogue
> from `0/0/0` to `22/19/9`. ⛔ **AND IT IS NOT AUDIO:**
>
> ```
>    §54 arm C   quiet-in 826 040 -> 0 silent / 826 040 LOUD (peak 8 388 607)   <- THE FATAL CASE
>                loud-in  313 960 -> 0 silent / 313 960 loud (peak 2 692 742)   <- LOWER than quiet
>    §70  quiet mean 352 943 168 421.0 span 0 | loud mean 352 935 830 162.3 span 329 906 836 205
>    §211 quiet mean 1 212 718 186 496.0 span 0 | loud mean 1 212 708 031 370.7 span 1 207 096 377 344
>    (gate raised 400 000 -> 420 000 per INSTRUMENT-AUDIT R6 and ALL FIVE ARMS RE-RUN; verdict unmoved)
>    m_rf[8D] 009B26 -> 7FFFFF ; body 0 28/32/28 -> 28/27/24 ; w65's operand a RAILED CONSTANT
>    arm D (route only)  == arm C in EVERY s104 column and in §70, both buckets
>    arm E (latch only)  fired 1 204 800 + 1 203 840 times; its §E-D0 block diffs EMPTY vs control
> ```
>
> ⇒ **The pedestal is the rig's own rail — `D-RAM[0x05]` reads `8 388 607` on every quiet frame in
> the CONTROL arm, before any crossbar exists.** ⇒ ⛔ **NOTHING SHIPPED BEHAVIOURALLY.**
> ⇒ **NEXT: (1) STOP THE RIG RAILING** — §220's residual: the bit-4 store writes the PRE-update
> accumulator; at `iw35` the POST-update accumulator is INPUT-DEPENDENT, so a post-update store
> would DEPOSIT audio instead of destroying it, **without deleting a store the corpus contains**.
> Grade it on `§54` first (`quiet-in → LOUD-out` must stay **0**). **(2)** `w63`'s READ is the
> narrow one-word form of the bit-23 question and §222 §4 proves it is the *entire* mechanism —
> re-ask it **only on a non-railing rig**. **(3)** body-0's coefficient cursor at `iw112`
> (`coef 0..24`, −111 dB).
> ⛔ **NOT `ACT 0x0D` / `m_bx_sel0d` / `iw205`** — §222 closed the destination **at the site**:
> `iw205`'s own `ACCB` = its own operand `× 65536`, both endpoints (`547 518 × 65536 =
> 35 882 139 648` EXACT). `m_bx_sel0d` is FROZEN at 1 and is now a regression control.
> ⛔ **NOT `SRC 0x03` / `ACT 0x03` as a crossbar latch** — REFUTED by the two-sided bisection.
> ⛔ **NOT the epilogue's operand set** — `§221 F1` is **still 0 with the link open**; the operand
> the crossbar delivers is provenance `iw11`, **kernel A's dry deposit**, not body 0.
>
> ★ **`D-RAM[0x85]` HAS NO WRITER AT ALL — now MEASURED**, not inferred, by an audit that names
> `iw70` the instant one exists. ★ **The `:2914`/`:3491` mode-1 unit-rebase divergence is DECIDED
> and UNIFIED**: corpus body images unit-relative **7 of 7**, `iw332 → m_rf[0x8F]` measured, and
> **0 disagreements in 5 976 000 resolutions**; it also closes a latent cross-unit corruption in
> `a04 FLANGER` / `a05 PHASER`.
> ⚠ `UPD6383_XB85` and `UPD6383_PICKUP` are **DEFAULT OFF**, fired counts printed unconditionally.
> Logs: `data/{A_pickup,B_pickup_noz05,C_xb85_full,D_xb85_route,E_xb85_latch}_222.log.gz`.
> ★★ **METHOD, and it cost a falsifier:** a regression control must be **UPSTREAM** of the arm.
> `m_rf[0x8D]` is `acc_to_datum(ACCA)` written by `iw60`/`iw61` — downstream — so when it railed it
> could not tell "the gate leaked" from "the arm worked". `§41` was upstream and passed everywhere.

## TIER 0a-prev — §221's BLOCKER, TRUE IN EVERY PART (and §222 could not refute it)

> **★★★ THE OUTPUT STAGE IS NOT STARVED — IT IS NOT CONNECTED, AND THAT IS MEASURED BY PROVENANCE.**
> §221 ran `§E1`, the operand-provenance census, on the `NOZ05` rig: for every operand the output
> stage fetches it names **the array, the index, and the `iw` that last wrote it** (standing
> RULE 17; rule 15 is why liveness could never have decided it).
>
> ```
>    §221 F1 : epilogue operands (iw60..81) tracing to BODY 0 (iw84..153):  0 of 14
>    §221 F1b: ...to BODY 1: 1 -- w65 <- iw332 via m_rf[0x8F], 540 000/540 000, VALUE ZERO
>    §221 F2 : ACCA at w73, PRODUCER = kernel-B iw54, 540 000 of 540 000 (100.00 %), BODY 0 = 0
>    §221 F3 : CALIBRATION PASS -- w72 -> m_rf[06] = 4 194 304, both buckets
>    diff(arm A §E1 census, arm B §E1 census) = EMPTY, all 18 rows, all 3 provenance columns
>    arm B  s104 body 0: 28/32/28 (arm A 0/0/0) | §46 3 494 021 nz reads | §75 2 351 009
>    BOTH   §70/§211  min 0 max 0, MEAN 0.0, AC SPAN 0, quiet AND loud
> ```
>
> ⇒ **body 0 runs its whole ladder on live audio and NOT ONE BYTE of the epilogue's operand picture
> moves.** §216 said the output stage is a null independent of its input; §221 says why.
> **⇒ NEXT: (1) body-1 `iw205`, `ACT 0x0D`'s destination — `iw`- or unit-SCOPED only,
> `m_bx_sel0d` is FROZEN at 1 globally; (2) body-0's coefficient cursor at `iw112` (`coef 0..24`,
> −111 dB). ⛔ NOT the epilogue and NOT its decode gap — `§E1b` measured all twelve counterfactual
> operands CONSTANT in both buckets, in both arms.**
>
> ⚠ `UPD6383_EPIBUS` is **DEFAULT OFF**, read-only, fired count **120 960 000** printed
> unconditionally. Logs: `data/{A_epibus,B_epibus_noz05}_221.log.gz`.
> ★ New instrument, always on: **`§70`/`§211` now print MEAN and AC SPAN** (standing rule 19), so
> `OUTPUT-STAGE-NULL_findings.md` §6.5(ii)'s `79 438 ± 90` DC counter-example is caught by the log.

## TIER 0a-prev — §220's BLOCKER, still true in every part

> **★★★ THE SEND IS SOLVED AS A DIAGNOSIS AND THE OUTPUT STAGE IS NOW THE WHOLE PROBLEM.**
> §219 located the unit-0 send at **D-RAM cell `0x05`** and named `iw35`/`iw45` as the two stores
> that overwrite the audio `iw9`/`iw11` deposit there. **§220 CONFIRMED IT BY INTERVENTION**:
> suppress those stores (`UPD6383_NOZ05=1`, env, **DEFAULT OFF**) and body 0's `§104` columns go
> from **`0/0/0`** input-dependent slots to **`28/32/28`, slot for slot identical to the §215
> `SRC0B2` calibration arm**; the delay line fills (`§46` non-zero reads **0 → 3 494 021**, `§75`
> writes-with-content 1 175 999 → **2 351 009**) — **and `§70 ACCA at w73` / `§211 ACCB at w78` are
> STILL `min == max == 0`, quiet and loud, in all four arms.**
> ⇒ ★★★ **EVERY UPSTREAM LINK IS DEMONSTRABLY ALIVE AND THE OUTPUT IS STILL A HARD NULL.
> Work the OUTPUT STAGE, with `UPD6383_NOZ05=1` as the rig.**

Decided from `data/{A_off,B_mirror06,C_noz05,D_noz05_drpub}_220.log.gz` — four arms, one build,
the §217 clean vehicle, 1 440 001 frames each. **Cite the run, not the section** (rule 11):

```
   arm A  shipped default -- IDENTICAL, slot for slot, to drpub_A_off_217:  body-0 idep 0/0/0
   arm B  mask bit 26 ON  -- fired 5 881 351, iw84 STILL 0 ‖ 0, kernel A STRICTLY WORSE
                            (acc 27→22, mem 21→10, L 18→12)              ⛔ DEAD-END 30
   arm C  UPD6383_NOZ05=1 -- fired 3 528 080 (iw9/iw35/iw45, +55 pointer-drift strays)
                            §104 iw84 mem 8 388 607 ‖ -8 388 608..8 388 607  *   THE PICKUP, LIVE
                            s104 acc 63 (body0 28) | mem 73 (body0 32) | L 59 (body0 28)
   arm D  NOZ05 + DRPUB=1 -- m_dr non-zero at iw25 on 1 174 369 of 1 211 520 (arm C: 0),
                            provenance iw12 age 0; new live slots ONLY at L iw25/27/39/40 and
                            acc iw41..44  <- SRC 0x0B at iw25 confirmed BEHAVIOURALLY
   ALL FOUR:  §70/§211  min 0 max 0  in the loud bucket AND the 726 040-frame quiet window
```

⚠ **NOTHING SHIPPED. `UPD6383_NOZ05` is a DIAGNOSTIC, DEFAULT OFF**, for three reasons: its cell
`0x05` **rails** (`§86` quiet `[8 388 607 .. 8 388 607]`, full scale with no notes — §176's warning,
third occurrence); there is **no decode** under which `iw35`/`iw45` do not store (both carry
`HI_ST`, both `mode 2`, and **neither carries bit 7**, so `§109`'s CO-EQUAL store-gate ambiguity —
mask bit 29 — cannot refuse them under either reading); and by §216 it produces no audio.

**⇒ NEXT: (1) THE OUTPUT STAGE, with `UPD6383_NOZ05=1` on so a fix is not masked by a zero input.
(2) the send's residual question is the store's DATUM, not its address — the bit-4 store writes the
PRE-update accumulator (`iw39` stores `acc_to_datum(130 485 107 904) = 1 991 044`, `iw38`'s
post-value); at `iw35` the POST-update accumulator is INPUT-DEPENDENT, so a post-update store would
DEPOSIT audio there. `iw45`'s post-value is still constant, so it does not finish the job alone.**
⚠ **`UPD6383_DRPUB`: DEFAULT OFF still.** It now has a measurable consequence (arm D) — but only
with NOZ05 on, and the shipping condition names the **SHIPPED** build's delay line.
⚠ **rule 8, SHARPENED by §220:** a fired count that prints only when non-zero makes "0 fires" and
"never ran" the same log line. **Print it unconditionally with the arm's flag.** Audit a bit before
arming it with `dsp/tools/bit26_audit.py`.

---

## TIER 0a-prev-219 — the §219 blocker, SUPERSEDED by §220 but TRUE IN EVERY PART

> **★★★ THE SEND IS D-RAM CELL `0x05`, AND `iw35` OVERWRITES THE AUDIO THAT `iw9`/`iw11`
> DEPOSITED THERE.** `§213 §4`'s *"one corpus-unique word whose `SRC` is a GUESS"* (`iw25`,
> `SRC 0x0B`) **stopped being a guess in §215**, and **no `SRC` on the send path can decide a
> stored value anyway** — the delay WRITE and the `HI_ST` store both take `acc_to_datum(m_acc)`,
> never the bus. ⇒ **DO NOT look for the send defect in a SOURCE-field decode** (dead-end 28).
> ⚠ **"the delay line is EMPTY" is IMPRECISE** (dead-end 29): `§75` counts **1 175 999 delay
> writes with content** on the shipped build — the kernel's `iw46` writing the DC `0x7D70`.

---

## TIER 0a-prev — the §218 blocker, SUPERSEDED by §219. Kept so the closure is legible

> **★★★ THE WHOLE `iw25` LINE OF ENQUIRY IS CLOSED — decode, delivery, schedule, line index,
> register width and latency. §218 refuted the last open rival (the CROSS-FRAME pipeline) with
> NO run and NO rebuild, and corrected the census it rested on: there are **7** class-2
> `SRC 0x0B` words in the corpus, not 9, and `ENSEMBLE w62` is not one — its `lo12 0x40B` carries
> `SRC 0x10` (the ACCUMULATOR); the `0B` §217 §5 read was the ACTION field.**
> ⛔ Its handover — *"NEXT: the SEND, `§213 §4`'s one corpus-unique word whose `SRC` is a GUESS"* —
> is **RETIRED BY §219**: the guess was decided in §215 and no `SRC` on the path is load-bearing.

```
   arm A  §217 provenance at iw25  540000 evals | age 1..1 | read by iw289 x540000   <- SINGLE BIN
   arm B  (DRPUB=1)                540000 evals | age 0..0 | read by iw12  x540000
   the cross-frame rival predicted  read by iw26, age 1..1                <- 0 % of the mass
   §218  41 delay words (21 READS) between iw26(N-1) and iw25(N) -- one-deep cannot span it
   §218  item A "+4 after the PRECEDING read" is 6/6 at ENSEMBLE; the rival is UNDEFINED at w92
```

---

## TIER 0a-prev — the §215 blocker, RETIRED by §217 and §218. Kept so the closure is legible

> ⛔ **"THE BLOCKER IS THE §78 PER-LINE PUBLISH SCHEDULE" is REFUTED (§217).** The datum is not
> lost — it is published intact to `iw98`, 540 000/540 000. The line index is a RED HERRING.

> **THE `iw25` DECODE IS CLOSED — `SRC 0x0B` = the delay-read data register IS RIGHT, on a class-2
> word as on a class-1 one, REFUTING the rival by the corpus. THE BLOCKER MOVES ONE HOP UPSTREAM:
> the datum `iw12` fetches NEVER REACHES `iw25`. In the arm where the delay line was FULL of audio,
> `m_dr` at `iw25` was non-zero on `0` of `1 211 520` evaluations while `§80` published `181 521`
> non-zero data. THE BLOCKER IS THE §78 PER-LINE PUBLISH SCHEDULE.**

Established by runs `data/src0b2_A_off_215.log.gz` (shipped) and `data/src0b2_B_on_215.log.gz`
(rival forced ON), same build, clean vehicle, `-log`, 1 440 001 frames, ~314 000 loud — cite the
run, not the section (rule 11). Scored against `data/PREDICT_215.md`, committed **before the
build**; N1/N2/N3 and the calibration all held.

```
   arm B  §46  24 922 560 reads, 181 521 returned NON-ZERO      (arm A: 0)
          §80  latched 24 922 560 (181 521 nz) | publish hits 24 922 552 (181 521 nz)
          §215 m_dr non-zero AT iw25:  0 of 1 211 520           <- the blocker, in one line
   arm A  §215 mem[ptr] at iw25 non-zero on 313 169 ~= 313 960 loud frames | m_dr non-zero on 0
```

**THE DECODE, settled by the corpus (41 listings, 3057 words):** `lo12 0x2D9` is 36 words — 29
delay WRITE, 6 delay READ (ENSEMBLE), 1 = kernel `iw25`. Its consumer `0012201655` (`mac ta`) has
a **0.43 %** base rate and **13 of 13** of its sites are immediately preceded by a class-1
`addr8 0x20` DELAY READ. ENSEMBLE fuses read+capture in one `2D9`; the kernel splits the identical
`2D9` off one word ahead of its read — **same lo12, same idiom, same successor.** The rival would
need one lo12 to mean two things on two classes and would leave the kernel's two delay READs with
no consumer. ⇒ `UPD6383_SRC0B2` **default OFF, NOT SHIPPED.**

**⛔ THE FOUR FALSIFIERS OF `HANDOFF-NEXT.md` §1.2 ARE RETIRED AS A TEST.** All four passed under
the rival — and had to: arm A measured `mem[ptr]` at `iw25` non-zero on ≈ the loud-frame count
*before the rival ever ran*. They grade **"is the operand alive"**, not "is it `mem[ptr]`".
★ RULE 15: *a criterion that every live operand satisfies is a reach test, not a decode test.*

**★★★ AND THE RESULT THAT OUTLIVES IT:** with the send FORCED open, body 0 ran its whole ladder on
live audio (28 input-dependent slots, `acc` last-dependent slot `iw38` → **`iw204`**), fed body 1 —
and `§70 ACCA at w73` / `§211 ACCB at w78` stayed **`min 0 max 0`, quiet AND loud**, `§61` both
ports 0 non-zero, `§54` 0 loud output frames. ⇒ **The output stage is a null INDEPENDENTLY of what
the send carries.** §211 asserted it; §215 proved it by feeding it.

**Next:** does `iw12`'s datum ever reach `iw25`? Instrument the publish immediately preceding
`iw25`, per frame. If it never carries, decide between the **line index**
(`line = descriptor_value & 0x3f`, and §46 shows the kernel's descriptors resolving to `0000`, so
every kernel delay word shares line 0), the **ordering**, and the **single `m_dr` register** — in
that order. Env gates, default OFF, fired counts; the u64 mask is EXHAUSTED.

⚠ **TWO VEHICLE TRAPS, one run each:** the isolated `-cfg_directory` must carry
`:DSPCFG value="3"`, **and** MAME must be given **`-log`** or the entire `upd6383:` report is
discarded and the run looks like a crash.

**⛔ RETRACTED by §213 — the previous blocker's "one gradeable lead" was a PROBE ARTEFACT.**
`upd6383.cpp`'s ACT-0x07 site had an **unbraced `else`**, so `kwatch`/`watch_store`/`store_probe`/
`m_dwr` ran on every VISIT while §112's latch arm (mask bit 25, ON) stored nothing. `iw39` performs
**one** store, not two. Fixed under `UPD6383_STPROBE` (default 1): fired count **3 630 720 = the
§112 latch count exactly**, and the §104 census is identical slot-for-slot to §211 in all three
columns. ⇒ *"suppress one of the two stores"* would have been a **no-op on the machine**.
⚠ Do not read "cell X is write-only" off §98: its READ hook sits only on the anchored `SRC 0x07`
evaluator, so `SRC 0x00` reads are invisible to it (§213 §5.2).

---

## TIER 0a-old — the previous blocker  (§165, 2026-07-30), still open but no longer the headline

> **The LFO phase RAMPS in D-RAM cell `0x07` and does not REACH the class-6 word.
> The defect is ROUTING over a handful of words, not generation.**

Established by run `runs164/A_control`, mask `0x3910E446A39B440F`, cold-boot CHORUS,
1 392 430 frames — **cite the run, not the section** (see rule 10):

```
  §164  07: 0..8388598  chg 1128429 / 1392430 frames     full Q0.23 sweep
  §162  at the class-6 word:  acc 0..0 | m_dp 12..12 | cursor 9..9
```

The phase changes 1 128 429 times against the class-6 word's 1 129 389 executions — ratio
**0.99915**, so it advances once per body execution. That identifies it as the LFO beyond doubt.
Rate puts the increment at **114** (0.652 Hz against the panel's 0.599), not §108's measured 57.

⛔ **§163's blocker — "kernel `iw32` pins the phase at `0x400000`" — is DEAD.** It was inherited
from §108, written several shipped gates earlier, and never re-measured. §108's whole kernel-`iw32`
/ `DRAM_UNIT_BASE` analysis is aimed at a symptom this build no longer has.

Everything downstream is built and waiting:
* **§161** — the wavetable is intact: `m_rf[0x1D..0x40]`, 36 cells,
  `0.9500000 × 2^23 × sin(2πk/24 + 0.100000 rad)` to within 2 LSB, period exactly **24**.
* **§162** — the class-6 lookup is four lines *once the index varies*, and not before.

**Next:** trace `0x07` → the class-6 word. The path runs through `082.2.00.1C0` (`SRC 0x07` =
`mem[ptr]` → acc) and the class-6 word's own `SRC 0x13`, which has **no reading anywhere** and
silently returns 0 (`upd6383.cpp` SRC evaluator default). `SRC 0x13` is the table read port
(§162) — that is the most likely single missing link.

---

## TIER 0b — ⛔ DEAD ENDS. DO NOT RETRY ANY OF THESE.

Each cost at least one full pass. The refutation is worth more than the hypothesis was.

⚠ #1 and #2 were aimed at §163's *"kernel `iw32` pins the phase"* blocker, which §165 then
measured out of existence. They stay listed: the refutations are still sound, and the ideas are
the ones a reader would reach for again.

| # | the idea | why it is dead | where |
|---|---|---|---|
| 1 | Fix the phase clobber by changing **`DRAM_UNIT_BASE`** | **FORCED**: kernel A's walk begins where the previous frame *closed*, so base and window are coupled and `iw32` follows the cell wherever it moves. Bit 27 ran it — gate fires, `dp` `0x07`→`0x08`, **every value bit-identical** | §108 §5 |
| 2 | Decode `040.0.**.C63` / `012.4.01.1CE` as the missing phase producers | Both **already modelled**: `SRC 0x11/ACT 0x03` = `tempB ← ACCB`, `SRC 0x07/ACT 0x0E` = `P ← mem[ptr]`. Their presence in the roadmap's *"no reading of any kind"* list is a **corpus statistic, not a statement about the emulator** | §163 |
| 3 | `addr8` on the class-6 word = the **table extent** | The `0x28` sites are fed by scale `0x000010` = 16; `0x000028` does not occur in the coefficient corpus at all. The `24`/`0x18` agreement was coincidence | `lfo-ramp.md` P-16 |
| 4 | Implement the class-6 lookup **now** | Every index candidate is constant (`acc 0..0 \| m_dp 12..12 \| cursor 9..9`, 1 129 389 hits). A frozen lookup returns one entry forever, and that reads as *refuting the sine* against the "226 not 240" test | §162 |
| 5 | `SRC 0x08` = **unity** | The rival reading saturates the accumulator on the LFO's very first word. `SRC 0x08 = the COEFFICIENT` reproduces the ROM ramp constant exactly (`mem[0x04]` 1000→1228, step +228 = `0x0000E4`) in 11 of 19 corpus constants | `upd6383.cpp:2124` |
| 6 | The brief's anchors **`SRC 0x1C` = "LFO out"**, **`SRC 0x08` = "LFO phase"** | Neither is anchored anywhere in this repository, the MAME device, or its disassembler. A *word*-level landmark was read as a *field*-level one | `lfo-ramp.md` §11 |
| 7 | `st_gate = always` | 0 survivors of 276 480 | `lfo-ramp.md` P-9 |
| 8 | Remap the three internal writes onto **output ports 0/1** | Reverted: the resulting wet was rms 1.0 — a ±1 LSB constant present *even in silence* | `upd6383.cpp:2011` |
| 10 | **Bit 54** (latch to `m_k`) and **bit 54 + bit 4** (§40 reads it) to route the phase | §136's *"the pair has never been evaluated together"* is discharged: bit 54 alone is **bit-identical to control in every cell**; the pair produces `§70 ACCA min = max = 176 471 605 248`, the exact DC §137 retracted | §165 §4 |
| 17 | The descriptor payload is truncated 24→16 bits (`m_dscbank = u16(v & 0xffff)`) | ⛔ **REFUTED §190.** `r3-delaydram.md` P5, MEASURED over 870 cells: the delay map is `[0x0000,0x10000)` and no firmware address reaches 2¹⁶ (max 64 899). 16 bits is correct, and "every unit-1 cell has bit 15 set" is just unit 1's range `[0x8000,0x10000)` | §190 |
| 18 | The cold-boot unit-1 program is not ROOM REVERB 1 | ⛔ **REFUTED §190.** §170's 16-word fingerprint applied to load address 200: `prog16_room_reverb_1`, loaded once at transfer 18 | §190 |
| 15 | Model the bit-11 `lo12` words on an **ALU route** | ⛔ There is no ALU route to model — `bit11-family.md` §9 establishes bit 11 selects a **second encoding** with no `SRC` and no `ACTION` field (bits 11/5 co-vary 90 of 90; the ALU reading needs 4 field values attested nowhere else). `alu_decoded()` refusing them is correct | §182 |
| 16 | `ACT 0x03`, `ACT 0x04`, `ACT 0x1C`, `SRC 0x02`, `SRC 0x04` | ⛔ **These codes do not exist** — parse artefacts of applying the bit-11-clear encoding to bit-11 words (`bit11-family.md` §9.3, 2026-07-27). ⚠ One genuine exception: `epilogue w63 = 2A7.9.05.1C3` carries `ACT 0x03` with bit 11 clear, in the output stage | §182 |
| 13 | `C63` writes the index register `m_tb` via `SRC 0x11 / ACT 0x03` (**§166 §3**) | ⛔ **REFUTED §181.** `lo12 = 0xC63` has bit 11 set, and `upd6383d.h:609` routes those words to *addressing only, no ALU effect*. It never writes `m_tb`. §166's 53/53 bijection is a measurement and stands | §181 |
| 14 | `SRC 0x11`'s reading explains `m_tb` being frozen | ⛔ Three experiments (§168, §181 arm D, the whole `SRC 0x11` line) tested **the source of a write that never happens** | §181 |
| 11 | `ACT 0x15` is a no-op, so the LFO index multiply never issues (**§169 §2**) | ⛔ **RETRACTED §174.** The multiply's gate is `coeff_consumer(w) = class4==0xA && !c_format(w)` — the ACTION field is not in it. `lfo-ramp.md` §10 said so in the paragraph §169 quoted. Takes §171 §4 and §173 §3 with it | §174 |
| 12 | "one cause — the frozen cell is just the dead multiply", displacing §168 | ⛔ Premise gone with #11. §168's addressing diagnosis is **confirmed** instead: 7 of 12 multiply sites have `L` identically zero while `coef` is live | §174 |
| 19 | `iw39` stores TWICE to cell `0x06` and the second store wins (**§211 §6**) | ⛔ **RETRACTED §213.** The site-3 record is a **PHANTOM**: an unbraced `else` at the ACT-0x07 site let `kwatch`/`watch_store`/`store_probe`/`m_dwr` run on every VISIT while §112's latch arm stored nothing. Fired count after the fix = **3 630 720 = the §112 latch count exactly**; §211's own log already contradicted it (`iw34` logged storing 8 388 607 to `0x06` while §104 shows `6 039 795` still there two slots later). "Suppress one store" was a **no-op on the machine** | §213 |
| 20 | `tempA` is empty at `iw39` because its producer has never been identified (the `SRC 0x13` shape) | ⛔ **ANSWERED §213, not a hole.** `tempA` is INPUT-DEPENDENT `iw7..iw24` and is **zeroed at `iw25`** by `SRC 0x0B` + `ACT 0x19` — the delay-read register, 0 on 24 922 560 of 24 922 560 reads. A correct consequence of §48, and the send inherits it | §213 |
| 21 | `SRC 0x0B` at a CLASS-2 word is a different code (`mem[ptr]`, or anything but the delay register) | ⛔ **REFUTED §215, by the corpus.** `lo12 0x2D9` is 36 words — 29 delay WRITE, 6 delay READ, 1 = kernel `iw25`. Its consumer `0012201655` (`mac ta`, **0.43 %** base rate) sits within 3 slots of a class-1 `addr8 0x20` DELAY READ at **13 of 13** sites. ENSEMBLE `w10` fuses read+capture in one `2D9`; the kernel splits the identical `2D9` off one word ahead of its read, with the SAME successor. The rival needs one lo12 to mean two things on two classes AND leaves the kernel's two delay READs with no consumer | §215 |
| 22 | `HANDOFF-NEXT.md` §1.2's FOUR FALSIFIERS as a decode test | ⛔ **RETIRED §215.** All four passed under the refuted rival, and had to: arm A measured `mem[ptr]` at `iw25` non-zero on **313 169** ≈ the **313 960** loud frames *before the rival ran*. `iw25`'s pointer sits on a LIVE cell, so ANY live operand scores 4/4. They grade **reach**, not **identity** | §215 |
| 23 | "the output-stage null is an artefact of a zero send" | ⛔ **REFUTED §215.** The send was FORCED open: body 0 ran its whole ladder on live audio (28 input-dependent slots, last dependent `acc` slot `iw38` → **`iw204`**), fed body 1 — and `§70 ACCA at w73` / `§211 ACCB at w78` stayed `min 0 max 0` in **both** buckets, `§61` 0 non-zero, `§54` 0 loud frames | §215 |
| 24 | The **LINE INDEX** (`line = descriptor_value & 0x3f`) loses `iw12`'s datum — "the kernel's delay words all share line 0" | ⛔ **REFUTED §217.** That came from `§46`'s descriptor dump, which is an **UNGUARDED BOOT-TIME SAMPLE** (`m_dly_dsc[]` has no `m_frames_run` guard, so it freezes the pre-upload state where every cell reads `0000`). `§204`'s **guarded** census, *in the same log*, gives the kernel three distinct lines (`0x01`/`0x20`/`0x00`) with `iw12 ↔ iw98` paired exactly as `§79` says. Standing rule 10, third occurrence | §217 |
| 25 | **Widen `m_dr`** / "it is a single-register problem" | ⛔ **MOOT §217.** One register is enough: `§217` measured **`publishes strictly between iw12 and iw25: 0`** — nothing overwrites it in `iw13..iw24`. The fault was *when* `m_dr` is written (only at a delay word, and `iw25` is not one), not *how many* registers there are | §217 |
| 26 | The class-2 `SRC 0x0B` pipeline is **one-deep and CROSS-FRAME** — the word captures the datum of the read that FOLLOWS it, from the previous frame, so `DRPUB`'s `age 0` is off by one frame | ⛔ **REFUTED §218, three ways, with NO run.** (a) Pre-registered discriminator: the rival predicts tag `iw26`; arm A's histogram is **SINGLE-BIN `iw289`**, age 1..1, 540 000/540 000 — `iw26` holds **0 %** (`m_prov_other` silent in all three arms). (b) FORCED: **41 delay words, 21 of them READS**, execute between `iw26`(*N−1*) and `iw25`(*N*) — *one-deep* forbids the retention *cross-frame* needs. (c) Corpus: item A's "+4 after the PRECEDING read" is exceptionless **6/6** at ENSEMBLE, while "the FOLLOWING read" is **UNDEFINED at `w92`** and −30 at `w34` | §218 |
| 27 | **`ENSEMBLE w62` / `MULTI TAP w25` are class-2 `SRC 0x0B` words** "ahead of their read" (§217 §5's residue) | ⛔ **WRONG FIELD, §218.** `lo12 0x40B` = `SRC 0x10` (**the ACCUMULATOR**, anchored) + `ACT 0x0B`; the `0B` is the ACTION. The corpus has **7** class-2 `SRC 0x0B` words, not 9 — which `upd6383.cpp`'s own `case 0x0B` comment has said since §215. ⇒ §217 §5's "a shape no latency model explains" is **EMPTY**: `w62` is not in the class, and `iw25` at **+13** is *inside* item E's `land ≤ 4` with 0 intervening publishes | §218 |
| 28 | The **SEND is decided by a guessed `SRC`** (`§213 §7`, `HANDOFF-NEXT.md` §1 item 1) | ⛔ **DOUBLY REFUTED §219, statically.** (a) The guess — `SRC 0x0B` at `iw25` — **stopped being a guess in §215** (13/13 successor identity, the ENSEMBLE/kernel `2D9` twin), was provenance-graded in §217 and its population re-verified in §218. (b) **No `SRC` on the path decides a stored value**: the delay WRITE (`upd6383.cpp:2081-2090`) and the `HI_ST` store (`:2942`) both take `acc_to_datum(m_acc)`, never the bus, so a `SRC` there changes a GAIN OPERAND, never whether anything is injected. `tools/src0b_census.py sendpath` grades all 44 non-C-format words of kernel A | §219 |
| 29 | "the delay line is **EMPTY**" as an independent fact | ⚠ **IMPRECISE §219.** `§75` in the same report as `§46`: **1 175 999 writes carry content** (one per settled frame — the kernel's `iw46` writing the DC `0x7D70`), and `§200` reports reads resolving with 0..4401-frame ages. The reads return zero because the **bodies** write zero, because their input cell `0x05` is zeroed by `iw45`. "Empty" names a symptom of dead-end 28's replacement, not a cause | §219 |
| 30 | **Mask bit 26** (`0x4000000`, `m_mirror06_n`) — mirror the kernel's `0x06` result into `0x05` to fix the DEPOSIT ADDRESS | ⛔ **REFUTED §220, by running it.** It **fired 5 881 351 times** — exactly 5 per kernel-A pass (`iw19/21/27/33/39`, mode 2; **not** `iw72`, whose mode is 1) — and body 0's `§104` pickup at `iw84` stayed `0 ‖ 0`, because **every mirror site is upstream of `iw45`**, whose zero store is the last write to `0x05` before the CALL. Worse, it made kernel A **strictly less input-dependent** (`acc 27→22, mem 21→10, L 18→12`) via a cross-frame path through cell `0x06`. ⇒ **the mirror destroys input dependence, it does not create it.** ⚠ And §219 §8's reading *"a null means the gate never fired"* is wrong: this is a null with a fired count of 5.9 M | §220 |
| 9 | "the delay tap **sweeps** ±240" / "each voice ramps 0→depth, a **sawtooth**" | Both retracted. The first pooled voices of opposite sign; the second censused across the boot transient. The settled modulation value is **CONSTANT** | §155, §157 → §158 |

---

## TIER 0c — STANDING RULES, each earned by a retraction

1. **Before reporting any non-zero output, read `§70 ACCA` and compare min against max.** Two
   "IC311 outputs audio" claims have been retracted; one was a DC. *(§137)*
   ★ §211 adds the unit-1 half: **`§211 ACCB AT w78`**, same buckets. `§61`'s "DO2 peak 0" cannot
   tell an empty ACCB from an empty unit-1 OUTPUT LEVEL — read both.
2. **Report absolute audio statistics from a CLEAN vehicle** — `scratchpad/coldnotes2.lua`, cold
   boot, notes after ~19 s. The `peq_gain` vehicle *creates* a unit-1 rail through ~55 mid-run
   effect uploads; use it for **deltas only**. *(§148)*
3. **Check the owning note first — for EVERY component of a claim, not just the one you doubt.**
   Ten occurrences. §163 is the sharpest: the note was checked for the *table* and skipped for the
   *phase*, and the answer had been sitting in §108 for days.
4. **Before implementing a consumer, measure that its inputs VARY.** A datapath whose every input
   is constant cannot be validated by its output. *(§162, fourth occurrence)*
5. **An absolute event count is not a falsifier across runs** — cold-boot frame totals vary
   (1 128 480 vs 1 156 269). Pre-register the *relation between two counters*, never the literal.
   *(§161)*
6. **A reading that measures INERT is a hypothesis about a MISSING CONSUMER, not a refutation.**
   *(§156, third occurrence)*
7. **Enumerate mask bits programmatically — match the bit, not the spelling.** `grep 0x40000\b`
   missed `0x40000u` and double-booked bit 18, confounding a whole run. *(§129)*
8. **A criterion that cannot fail is not a test**, and **compute the NULL before interpreting a
   table, not after**.
   ★ **SHARPENED, §220: a fired count must be PRINTED UNCONDITIONALLY, with the arm's own flag
   beside it.** `m_mirror06_n` had an increment *and* a `logerror` and still made "0 fires" and
   "this code never ran" the same log — because the print sat inside `if (m_mirror06_n)`. That is
   exactly the ambiguity a fired count exists to remove. Fixed for `§106`; `§220 NOZ05` prints its
   count **and the per-`iw` breakdown**, which is what caught 55 pointer-drift fires in 3 528 080.
   ★ **And AUDIT A MASK BIT BEFORE ARMING IT** — `dsp/tools/bit26_audit.py` parses the C++ with
   comments and string literals stripped, enumerates every mask literal, decides whether the bit
   is set in the shipped default, counts the sites that test it (two sites = confounded, stop) and
   checks the fired count reaches a `logerror`. Never grep a spelling (rule 7's constructive form).
9. **When the fix you reach for is an ANCHOR VALUE, stop.** Every anchor here is pinned by closure
   arithmetic; the defects are per-word **decodes**. *(§108 §5, named as a standing bias)*
10. **When a measurement surprises you, the first hypothesis is that it answered a DIFFERENT
    QUESTION than the one you asked. Move the instrument one step toward what you care about
    before theorising.** Four in one day: `m_p` read at the consumer not the producer (§169);
    36 M firings **pooled across sites** instead of keyed (§174); a census printing only the cells
    that *changed*, so "static and non-zero" and "static and **zero**" were indistinguishable
    (§176); and a table capped below the case of interest (§176 F3). Each was invisible until the
    previous was fixed. *(Part 109)*
11. **A blocker is a MEASUREMENT, and measurements expire.** Before building a task on a symptom
    reported in an earlier section, re-run it on the current build — several gates ship between
    passes. **Cite the run, not the section.** *(§165: the headline blocker had been fixed by
    other work and nobody re-measured it)*
    ★ **Second occurrence, §211:** §141's *"`w73` erases the accumulator at the door"* was measured
    **with mask bit 55 ON**. That bit is 0 in the shipped default and fires **0 times**; on the
    shipped build the accumulator is zero from `w65`. A measurement taken under a gate belongs to
    that gate — **quote the arm with the number, every time.**
12. **A DIFFERENCE BETWEEN TWO BUCKETS IS NOT INPUT DEPENDENCE.** Free-running quantities (ramps,
    counters, phases) sampled over buckets of unequal length report different ranges by
    construction. The discriminator, and it is cheap: **do both range endpoints translate by the
    same constant?** If yes it is free-running. *(§211 — under the raw flag, body 0 appears to
    carry the signal at `iw90/91`; it does not, and `dsp/tools/s104_score.py` applies the rule)*
13. **AIM THE PROBE YOU ALREADY HAVE.** §150 §4 named the exact instrument and the exact slot —
    *"point the §109 store witness at slot 73 and read it"* — and 60 sections passed with the probe
    in the build and the slot missing from its list. **Before designing an experiment, check
    whether an existing instrument merely needs pointing.** *(§211)*
    ★ **Second occurrence, §218, and it paid the most:** the whole cross-frame rival was decided
    from three logs that already existed and a corpus already committed — **zero MAME runs, zero
    rebuilds**. ⇒ **A STATIC DECISION IS THE BEST OUTCOME, NOT A LESSER ONE.** Before designing
    an experiment, prove the existing logs *cannot* answer it.
14. **Instrumentation must follow the EFFECT, not the visit.** A probe placed beside a
    conditional rather than inside it reports events that did not happen — and the next pass
    builds a task on them. §211's headline lead was one unbraced `else`: three phantom stores
    per frame, polluting `§96`, `§109` and the `m_dwr` census at once. **When a gate's fired
    count and a store census disagree, suspect the census.** *(§213)*
15. **A CRITERION THAT EVERY LIVE OPERAND SATISFIES IS A REACH TEST, NOT A DECODE TEST.** §215's
    four pre-computed falsifiers all passed under a reading the corpus refutes — because `iw25`'s
    pointer sits on a **live cell**, so *any* substitution that puts a live value on the bus scores
    4/4. The counterfactual was measurable in the DEFAULT arm (`mem[ptr]` non-zero on 313 169
    ≈ the 313 960 loud frames) **before the rival was ever built**. ⇒ **Count, in the control, how
    many arms would pass your test. If the answer is "all of them", it is not a test.** And when a
    decode question has a CORPUS answer, the corpus outranks any run. *(§215)*
16. **A census that enumerates "cells touched" only sees the hooks it has.** §98 marks kernel
    cell `0x06` write-only because `pwatch()`'s READ hook sits on the anchored `SRC 0x07`
    evaluator alone; `0x06` is in fact a cross-frame carry read by `SRC 0x00`. Check the hook
    before quoting an absence. *(§213 — numbered 16 in §218; it and rule 15 were both filed as 15)*
17. **★ GRADE BY PROVENANCE, NEVER BY LIVENESS — and state the WRONG `iw` NUMBER as the failure
    mode.** The constructive fix for rule 15. §217's instrument tags every delay latch with the
    `iw` that performed the READ, carries the tag with the datum and histograms it at the consumer;
    a wrong source then reports a **wrong `iw`**, which no amount of liveness can fake. It graded a
    decode **with every value counter still at zero** (arm B: provenance flipped `iw289`→`iw12`,
    `§215 m_dr nz at iw25` still 0), and §218 refuted the cross-frame rival on the same histogram.
    ⇒ **A decode test must be able to name the specific wrong answer it would print.** *(§217, §218)*
18. **★ GRADE A FIELD CENSUS WITH THE DISASSEMBLER'S OWN ACCESSORS, NEVER BY EYE AND NEVER BY THE
    `lo12` STRING.** §217 §5 re-derived in prose a census `upd6383.cpp`'s `case 0x0B` comment had
    carried correctly since §215, read `lo12`'s **ACTION** field (`lo12[4:0]`) as its **SOURCE**
    field (`lo12[10:6]`), got **9** class-2 `SRC 0x0B` words instead of **7**, and built a
    handover question on the two impostors. **11** distinct `lo12` values occur on both class-1
    delay words and class-2 words, so the `lo12` string carries no class information at all.
    Use `dsp_disasm.lo_src` / `lo_act`, and control the result against a published corpus
    statistic (§218 reproduced `register-space.md` §4's `82`/`50` split digit-for-digit).
    ⇒ **And when a re-derived number disagrees with the source comment beside the counter, the
    comment is evidence — reconcile before building on the new number.** *(§218)*
