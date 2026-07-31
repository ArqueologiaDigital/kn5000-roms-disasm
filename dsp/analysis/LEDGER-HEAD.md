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

## TIER 0a — THE CURRENT BLOCKER  (§227, unmoved by §228/§229, 2026-07-31)

> ### ★★★★★ §229 — READ THIS BEFORE QUOTING ANY NULL
>
> **THE OUTPUT STAGE'S OPERANDS ARE 28.492 % ZEROS *WE* INVENT**, and its four distinctive
> words are executed as *"hold, no product"*. Both facts land on **`w78`** — the word
> `§211`'s central null is measured at.
>
> ```
>    FABRICATED ZEROS (src_term()'s `default:'), per REGION -- quote beside any null:
>      kernel A  0.000 %    kernel B  0.000 %    body 1  0.000 %
>      body 0    8.772 %    EPILOGUE 28.492 %    TOTAL 9 832 536 / 246 952 062 = 3.982 %
>      sites: 0x05@iw60  0x01@iw61  0x06@iw68  0x0A@iw78 | 0x13@iw99/108/140/149  0x1C@iw111
>
>    f31 x hi12 BIT 5 -- the corpus rule, confirmed DYNAMICALLY:
>      f31 in {3,6,7} with bit5=0 :  0  in 246 952 062 executions   (corpus: 53 of 53)
>      f31 in {3,6,7} with bit5=1 :  4 424 994, at EXACTLY FOUR SITES
>      iw63(3) iw70(3) iw75(7) iw78(6)  -- ALL EPILOGUE, all words the disasm cannot name
>      ⚠ our model runs all four as `op = f31 & 3' => HOLD, NO PRODUCT
> ```
>
> ⇒ ★★★★★ **`§70` AND `§211` ARE NOT THE SAME KIND OF NULL.** `w73` resolves `SRC 0x10` = the
> accumulator and its `f31` is outside the bit-5 family. `w78`'s **only** operand is a
> fabricated zero **and** its operation code is collapsed. Both print `mean 0.0 span 0`;
> **only one is a statement about the chip.**
> ⇒ **`m_rf[0x8C]`'s permanent zero (1 108 254 stores, 0 non-zero) is 100 % OURS.**
> ✔ **`m_rf[0x8D] = 0x009B26` SURVIVES** — its non-zero stores come from a third site.
> ⛔ **NOT A LICENCE TO IMPLEMENT ANYTHING.** Dead end 4 / rule 4 still forbid the six SRC
> codes; §7.1 of §229 pre-registers the `f31` 3/6/7 arm with its falsifiers, **default OFF**,
> and requires `SRC 0x0A` be done **SECOND, never jointly** — `w78` carries both candidates.
> ★ **UPLOAD LEDGER, and it ends an inference:** 12 runs, **8 distinct images**, matching the
> offline corpus **4 of 4** (KERNEL 60, EPILOGUE 23, CHORUS load 84/70 w, ROOM REVERB 1 load
> 200/133 w). ⚠ **Body 0's region is 116 slots holding a 70-word image — `I-RAM[154..199]` is
> never uploaded.** Declare that 46-slot tail wherever a body-0 denominator is quoted.
> ⚠ **§38's "frame 264 002" is a 48 000 Hz figure (5.500 s).** The last upload measures frame
> **246 078 = 5.581 s** on the 44 100 clock. Convert before comparing.
> ⛔ **STRUCK, NOT DEFERRED:** the `f98` cross-unit A/B (**NOT VIABLE** — its `f98=2` half is a
> structural zero at `iw207` in nine arms, and a kernel pair `w16`/`w17` is already co-resident)
> and the ROCK ROTARY `hi12` bit-5 A/B (**VOID BY CONFOUND** — bit 5 is read in exactly ONE
> place in the device, the nop guard, so the A/B measures our dispatch table and nothing else,
> and the review's own kill-condition cannot fire).


> ### ★★★★ §228 SHIPPED FIRST, AND IT IS NOT THE BLOCKER — IT IS A CLOCK
>
> **THE DSP FRAME CLOCK RAN AT 48 000 Hz AGAINST AN Fs OF 44 100.** Measured from disk before
> anything was built: every archived arm reports **1 440 001 frames on a `-seconds_to_run 30`
> vehicle** = exactly `30 × 48 000`, and its settled window `1 440 000 − 420 000 = 1 020 000` is
> precisely `§S1`'s `706 040` quiet + `313 960` loud. **Every emulated delay, reverb time and LFO
> was +8.844 % fast.** It now ships at **44 100**, by decoupling `run_frame()` from the 48 kHz
> rendering stream with an exact **147/160** phase accumulator.
> `UPD6383_FRAMEHZ=48000` restores the old clock as the two-sided control.
>
> ```
>                       arm A (48000, control)   arm B (44100, DEFAULT)
>    frames run          1440001                  1323000 = 30 x 44100 exactly
>    §228 T4 meas. Hz    47985.602                44086.742   (T5 err 3.0e-4, PASS both)
>    LFO step / period   114..114 / 73584.3 fr    114..114 / 73584.3 fr   <- INVARIANT
>    LFO rate            0.652313 Hz              0.599313 Hz
>    §S1 TOTALS          4.924 % / 4.920 %        4.924 % / 4.920 %       <- INVARIANT
> ```
>
> ⚠⚠ **NEVER GRADE A CLOCK CHANGE ON THE LFO's Hz — IT CANNOT FAIL** (the census's Hz is
> `wraps/frames × DECLARED rate` and `wraps/frames` is rate-invariant; rule 8). Grade on **T4**,
> frames per emulated second against the machine's clock, and on the step/period staying invariant.
> ⛔ **`§196`'s WRAP CENSUS IS SUPERSEDED** — it printed **0.5000 Hz** on every arm ever run
> (denominator included the 264 001 pre-upload frames; numerator truncated the last partial wrap).
> ★★ **And `LEDGER`'s own `0.652 Hz` had never been measured by anything** — it was derived from
> the increment. **Before quoting a figure as MEASURED, find the log line it came from** (rule 20).
> ★ **NO TONE-GENERATOR REGRESSION**: insert-OFF / ON-at-44100 / ON-at-48000 are **byte-identical**
> over 1 440 001 frames (md5 `baffbeee…`), with the positive control passing (peak 21 796,
> 14.5 % non-zero).
> ⇒ ⚠ **EVERY FRAME COUNT IN A PRE-§228 LOG IS ON THE 48 000 CLOCK. COMPARE RATIOS, NEVER COUNTS.**
> Arming gates are FRAME counts and did not move; their wall-clock times did (420 000 = 8.75 →
> **9.52 s**). `§200`'s DELAY AGE ms figures in older logs are **8.84 % high**.
>
> ---
>
> **★★★★ THE BLOCKER, UNCHANGED BY §228, IS: *WHAT DOES THE COEFFICIENT BASE `0x90` MEAN?* BOTH
> CANDIDATE BASES ARE NOW MEASURED TO BE SOMEBODY's PER-ALGORITHM PARAMETER BANK.**
>
> **§227 took the reverb-preset capture §226 asked for, and it REFUTED §226's own positive half.**
> `C-RAM[0x90..0xB4]` is **NOT** a boot-fixed bank — it is **UNIT 1's (the reverb's) parameter
> bank**. A preset change `CONCERT REVERB 1 → ROOM REVERB 1` rewrites **23 cells, every one inside
> `0x90..0xB4` and NOTHING else in the 256-cell C-RAM**; **13 of the header's 20 walk cells move**
> and **2 of the 3 ladder cells (`0x9B`, `0x9C`) move with them**.
> ★ **The control that makes it proof-grade:** an independent 45 s panel run landing on CONCERT
> REVERB 1 reproduces the archived cold-boot capture on **all 256 cells, 0 differ** ⇒ the
> **cold-boot default reverb is CONCERT REVERB 1**, not ROOM REVERB 1.
> ★ Reproduce in one line:
> `python3 dsp/tools/hdrbase.py --score notes/data/kn5000_dsp1_upload_concertreverb1.txt notes/data/kn5000_dsp1_upload_roomreverb1.txt`
>
> **THE THREE READINGS, and a falsifier that DISTINGUISHES them is required first:**
> (a) **row 25 is wrong** — `ldptr` does not seed the coefficient cursor (**K3 has said so all
> along**); (b) the base is right and the header **legitimately reads the reverb's gains** (it runs
> immediately before the reverb's CALL); (c) the **cursor-advance map** is wrong.
> ★★★ **CHEAP AND NEXT: sweep the other twelve reverb presets** —
> `REVIDX=n dsp/tools/reverb_select.lua` + `hdrbase.py --score`, one command each. If the same 23
> cells move every time, that set **is** the reverb's parameter block, measured not inferred.
>
> ### ⛔ THE ALU DECODE OF `iw30/iw32/iw33` IS **CLOSED**. BOTH HALVES REFUTED (§227, four arms).
> * **`f31 == 1` IS the ISA's only accumulate** — `HI_ACC_ADD`, **1309 of 2989** non-C-format
>   corpus words, **695 of 1178** ALU-decoded; op 0 LOADs, op 2 HOLDs *without a product*, op 3
>   gets HOLD's behaviour. The **PARAMETRIC EQ biquad** (grade **SOLVED**, validated against its
>   designer at **0.198 dB**) sums five products through `f31 == 1` words `w6..w10`, rendered
>   **`acc += P`** by this repo's own generator. Without the carry `H(z) = makeup·(−a2)·z⁻²`.
> * **AND THE ARM DOES NOT FIX THE CLIP:** `iw34` becomes `8 388 608` = `2²³` = **FS + 1** and
>   clips `706040/706040` quiet and `313960/313960` loud — **identical to shipped.** Its 13 %→0.4 %
>   `§S1` "win" is **117 655 680 accumulate steps refusing to add**, and it takes `§104` body-0 to
>   100 % input-INDEPENDENT and makes `m_rf[0x8D]` disappear.
> * **`P_SHIFT = 7` IS NOT Q-CONSISTENT AND THE TIED MOVE IS A MEASURED NO-OP.** Coefficients are
>   **Q1.22 (MEASURED)** ⇒ the Q-consistent total is **22**, which ships. Arm P (7/15): the entire
>   `§S1` block is **BIT-IDENTICAL** to the default over 269 279 999 conversions. Arm Q (7/16,
>   untied): **`m_rf[0x8D]` halves, `0x009B26 → 0x004D93`** — and it still clips at `1.110 × FS`.
> * ⚠⚠ **CORRECT THE FALSIFIER LIST EVERYWHERE IT IS QUOTED: `§41` DOES NOT GUARD `P_SHIFT`**
>   (it reads C-RAM *levels* and is unmoved by a 2× product rescale). **`m_rf[0x8D] = 39 718` does.**
>
> ### ⛔ STILL BINDING FROM §226 — do NOT re-derive
> * **DO NOT SEED THE CURSOR AT FRAME START** — row 25 is LIVE (mask bit 12 CLEAR), the epilogue's
>   `iw69 ldptr #$90` is the frame's last pointer load and the epilogue has **ZERO** cursor-advancing
>   words ⇒ `w0` starts at exactly `0x90`. Setting it to what it already is **cannot fail**.
> * **DO NOT AIM THE HEADER AT `0x00`** — that is **unit 0's** per-effect bank (PEQ rewrites all 20
>   cells; §227's reverb capture moves **0 of 80** cells in `[00..4F]`), and the `0x0B` ladder is
>   `+2.733 FS` with PEQ loaded, **1.6× worse than shipped**.
> * **`headerdecode.md` §7.6 STAYS ANSWERED** (the `cmd 0x02` runs at `0x90` + `0xAE`; the packet
>   carries no destination — an `ldptr` in a scratch I-RAM slot does). ⚠ Only their *meaning*
>   changed: they upload the **cold-boot reverb's** coefficients.
> * ⚠ **`kernel.dsm`'s *"base 0x00 MEASURED"* IS A GENERATOR DEFAULT.** Never anchor on it.
> * **THE SQUARING MULTIPLY IS FAITHFUL**; ⛔ **do not touch the `SRC 0x08` source read** (anchored
>   by the CHORUS LFO, `acc = 114 << 16` exactly).

## TIER 0a-prev-226 — §226's BLOCKER, CLOSED by §227 (both halves refuted; see TIER 0a)

> **§226's headline was:** *"the header's fixed coefficient bank is FOUND — `C-RAM[0x90..0xB4]`,
> uploaded by the boot-time `cmd 0x02` runs at base `0x90` (30 values) + `0xAE` (7); `headerdecode.md`
> §7.6 is ANSWERED; the shipped build was already reading it; 22 of the 37 cells are written by no
> algorithm; the blocker moves to the ALU decode of `iw30/iw32/iw33`."*
>
> ⛔ **RETRACTED by §227:** *boot-fixed*, *15 of 20 invariant*, *ladder cells `9B/9C/9D` ALL
> invariant*, and the *"CHORUS + ROOM REVERB 1"* label on the cold-boot image (it is **CONCERT
> REVERB 1**). Of the "22 written by no algorithm", **15 move under a preset change**
> (`93 94 95 97 9A 9B 9C A1 A2 A3 A4 AD AE B3 B4`) ⇒ that list measured a **gap in the ROM's T1
> map**, not a property of the chip.
> ✔ **SURVIVES:** the upload half and `headerdecode.md` §7.6's answer; base `0x00` is unit 0's
> per-effect bank and is still refuted; the frame-start seed is still refuted; `kernel.dsm`'s
> *"base 0x00 MEASURED"* is still a generator default.
> ⇒ **the ALU decode it handed on is now CLOSED (§227) and the blocker is TIER 0a.**

## TIER 0a-prev-225 — §225's BLOCKER, SUPERSEDED by §226 (the squaring is FAITHFUL; the base is RIGHT)

> **★★★★ `§S2sq` — THE COEFFICIENT SQUARING — WAS THE BLOCKER, AND §225 GAVE IT A MEASURED
> CONSEQUENCE.** ⛔ **`SQUARING-MULTIPLY_findings.md` then established the squaring is FAITHFUL
> and re-attributed the overflow to the cursor base; §226 refuted THAT too. Do NOT re-open
> `cursor + 1`.**
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

★★ **TWO KINDS OF ENTRY LIVE HERE NOW.** Entries 1–30 come from `SPECULATIVE-APPLIED-REGISTER.md`,
which `gen_ledger.py` reads. Entries **31+** include **REPO-EXTERNAL** verdicts from
`kn7000_mame/notes/`, which **NO GENERATOR READS** — they are filed by hand and they must be,
because the index is repo-scoped while the evidence is not. `python3 dsp/tools/gen_ledger_ext.py`
sweeps the notes and reports what is still unfiled: **112 DSP-relevant graded verdicts** as of
2026-07-31 (⚠ INFERRED aggregate — a lower-bound work queue, not a statistic).
⚠ **And entries 1–30 stopped at §220.** Nothing from §221–§227 was filed for eleven days while
those seven sections refuted six distinct candidates. **File the refutation in the same pass that
earns it.**

⚠ #1 and #2 were aimed at §163's *"kernel `iw32` pins the phase"* blocker, which §165 then
measured out of existence. They stay listed: the refutations are still sound, and the ideas are
the ones a reader would reach for again.

| # | the idea | why it is dead | where |
|---|---|---|---|
| 1 | Fix the phase clobber by changing **`DRAM_UNIT_BASE`** | **FORCED**: kernel A's walk begins where the previous frame *closed*, so base and window are coupled and `iw32` follows the cell wherever it moves. Bit 27 ran it — gate fires, `dp` `0x07`→`0x08`, **every value bit-identical** | §108 §5 |
| 2 | Decode `040.0.**.C63` / `012.4.01.1CE` as the missing phase producers | Both **already modelled**: `SRC 0x11/ACT 0x03` = `tempB ← ACCB`, `SRC 0x07/ACT 0x0E` = `P ← mem[ptr]`. Their presence in the roadmap's *"no reading of any kind"* list is a **corpus statistic, not a statement about the emulator** | §163 |
| 3 | `addr8` on the class-6 word = the **table extent** | The `0x28` sites are fed by scale `0x000010` = 16; `0x000028` does not occur in the coefficient corpus at all. The `24`/`0x18` agreement was coincidence | `lfo-ramp.md` P-16 |
| 4 | Implement the class-6 lookup **now** | Every index candidate is constant (`acc 0..0 \| m_dp 12..12 \| cursor 9..9`, 1 129 389 hits). A frozen lookup returns one entry forever, and that reads as *refuting the sine* against the "226 not 240" test. ★ **CONFIRMED DOWNSTREAM (§158):** the settled tap modulation is **CONSTANT per voice** — `§104` gives `iw96 15729946 \| iw105 15729540 \| iw137 −15727740 \| iw146 −15727740`, **all `min == max`** in quiet *and* loud — *because the lookup is a no-op*. ⇒ rule 4: the consumer cannot be validated until its index varies. See also entries 3 and 9 | §162, §158 |
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
| 31 | Open the **KN7000 / SHARC effects engine as a cross-model oracle** for IC311's coefficients | ⛔ **RUN 2026-07-22, VERDICT: NEGATIVE.** **Zero** arbitrary coefficient is shared. 208 KN5000 constants vs 548 KN7000 floats: 12 shared two-decimal round values against ~5 expected from an independent draw of the same ~100-value pool (shared **habit**, not shared **data**), and the only two non-round shared values are **±0.125 = 2⁻³**, a shift. KN5000's signature **2/π = 0.63662 (53 occurrences)** appears nowhere in the KN7000 records; KN7000's **0.618 / 0.5614 / 0.876 / 0.2435 / 0.111 / 0.243** appear nowhere in the KN5000 set. ⚠ A naive float-set baseline predicts 1.8 ± 1.3 against 16 observed and **looks significant** — it is wrong, because both real sets are biased toward round decimals; split the sets and the signal vanishes. ★ **The note flagged its own trap in advance**: *"recording this because it is exactly the sort of number that could have been reported as a correlation"* | `kn7000_mame/notes/kn5000-dsp-coefficients.md` §5 / §5.1 |
| 32 | **Delay tap lengths survive the change of chip** — "N milliseconds is the same physical quantity on either instrument", so KN7000 taps should locate KN5000's (Felipe's strongest cross-model hypothesis) | ⛔ **FALSIFIED 2026-07-22.** Raw intersection of the two tap sets is **`{200}`** — one value, and it is round. Over **26 × 37 = 962 pairs** with a ±0.3 ms window spanning 5–500 ms: **2 of 26** at 32 kHz, **7 of 26** at 44.1 kHz, **4 of 26** at 48 kHz — consistent with chance, and **the test cannot even pin the sample rate**. ★ **The reason is the transferable part: both machines design their delay lines in round SAMPLE counts, not round milliseconds** (KN5000: 160 200 520 600 640 720 840 1100 1160 1240 1550 1760 12800; KN7000: 200 250 400 512 800 1000 4000 5000 8000 32768). A tap is an **address in a delay buffer**; a designer moving to a new chip with a new buffer geometry re-picks them from scratch. The physical-quantity argument holds for a spec sheet, not for an implementation | `kn7000_mame/notes/kn5000-dsp-coefficients.md` §5.2 |
| 33 | **Seed the coefficient cursor at frame start** (`UPD6383_CURSEED`, base `0x00`) — "the cursor is never seeded, so the header runs on whatever the previous frame's unit-1 body left behind" | ⛔ **REFUTED §226, FROM DISK, NO RUN — and both halves of the premise are wrong.** (a) **The base IS seeded, by an instruction**: the epilogue's own `iw69 = 801.0.90.821 ldptr #$90` reaches register row 25's `is_ldptr` branch (`m_cursor = ad` under `!(m_specmask & 0x1000)`; **bit 12 is CLEAR in the default**), and the epilogue contains **ZERO** cursor-advancing words, so the next frame's `w0` starts at **exactly `0x90`, every frame**. (b) **Base `0x00` is the UNIT-0 EFFECT's own per-effect parameter bank** — selecting PARAMETRIC EQ rewrites `0x00..0x1E` wholesale and moves **every one of `0x00..0x13`** while writing nothing at or above `0x50`; the header is a **literal canned image in Sub CPU ROM** and cannot read a per-effect bank. (c) At base `0x00` the same ladder reaches **`2.733 × FS`** with PEQ loaded — **1.6× WORSE**. ⇒ ★★★★ **A CLIP RATE THAT FALLS BECAUSE A COEFFICIENT BECAME *SOMEBODY ELSE'S* IS ALSO A REGRESSION.** ⚠ And *"set it to the value it already has"* **cannot fail** — rule 8 | §226, `HEADER-BANK_findings.md` item E |
| 34 | **`ACT 0x00`'s bus term is a missing general attenuation** — the unity-gain bus addend is what overflows the kernel ladder, so attenuate it | ⛔ **REFUTED §224, FROM DISK, FOR `iw34`.** Zero the `ACT 0x00` bus term and `iw33` **still leaves 10 234 099 = 1.220 × FS. It still clips.** ⚠ **HALF RIGHT, AND THE HALF MATTERS**: the mechanism IS real — a unity-gain bus addend exists — but at `iw34` it is not the cause, and at `iw13`/`iw91` the fault is **WHAT THE BUS CARRIES** (a railed memory cell; a modulus), not that it is added. The named addend at `iw91` is `iw92 − iw91 = 8 388 607 = 0x7FFFFF = C-RAM[0x01]` **exactly, at both endpoints** — the constant `upd6383.cpp`'s **own** C-RAM annotation calls *"wrap"*, which §225 then shipped as `UPD6383_LFOWRAP`. ⇒ **do not re-propose "attenuate the bus"; ask what is ON it** | §224, superseding §223 §8.2 |
| 35 | **`SRC 0x03` / `ACT 0x03` as an epilogue crossbar latch** (`§E-D85`) | ⛔ **REFUTED §222 by a two-sided bisection.** Arm E fired 1 204 800 / 1 203 840 and its `diff`s are **EMPTY**; arm D equals arm C in every column. `iw205` is a **MESSENGER** — its operand `547 518 .. 8 388 607` gives `ACCB 35 882 139 648 .. 549 755 748 352 = L × 65536` at both endpoints — and **`m_bx_sel0d` stays FROZEN at 1**, where changing it breaks body 0's only working pickup and the regression **IS** the `79 438 ± 90` rule-19 DC. ⚠ **`D-RAM[0x85]` has NO WRITER AT ALL** on settled frames, measured by an instrument that names `iw70` the instant one exists | §222 |
| 36 | **A store-suppression rig will produce a non-railing vehicle** | ⛔ **REFUTED §223.** The narrow rig (`NOZ05 = 2`, `iw35`/`iw45` only, 2 stores) reproduces `28/32/28` / `33/40/29` / `2/1/2` column for column **and still rails** — and so does the shipped build, which clips **4.924 %** quiet / **4.920 %** loud of all accumulator conversions with the input **exactly zero** (⚠ **5.303 % is the `LFOWRAP=0` CONTROL arm's number**, not the shipped build's, since §225). ⇒ **the rail is upstream of the send entirely**; the rig removes the two stores that were HIDING it from body 0, it does not create it. **Treat nothing that rails as evidence**, and do not build another suppression rig looking for a clean vehicle | §223, correcting §222's attribution |
| 37 | **Kernel A's cell `0x06` is a BISTABLE / a latch-up with a stable second state** | ⛔ **RETIRED §225. `0` IS NOT A FIXED POINT.** `§S3` — read-only, always on, **no frame gate** — reports `SETTLING`: cell `0x06` is 0 before any instruction writes it, **stores #1..#1356 write exactly 0** (measured: the ladder's lowest rung is *"val ≥ 1"* and first fires at #1357), then `iw19`'s **first ever execution** at frame 264 002 puts `1 650 061 = 0.1967 × FS` **into an empty cell** — already **1.52 ×** the `0.129 703 × FS` threshold — and the rail follows **on the next frame**. **There is no second state.** The rail needs a **FORWARD GAIN** explained, not an ENTRY. ⚠ **`§106`'s writer list was 5 names of 12** and `5 881 351` was never divisible by 5 — quote `nz`, never just the count | §225, retiring §224 §2 |
| 38 | **The multiply should read `C-RAM[cursor + 1]`** (`§S2sq`, the coefficient squaring) | ⛔ **CLOSED WITHOUT A BUILD, TWICE.** (a) `SQUARING-MULTIPLY_findings.md`: the multiply has **one hardwired coefficient port** (`C-RAM[ccur]`; no instruction field selects it) and **one** operand bus, so a word routing the coefficient onto that bus has **no second port for a sample** — the squaring is **FAITHFUL**. Census `123 / 893 = 13.77 %` against a `0.05 %` null, `z = +90`: **evidence FOR the decode.** (b) The re-attribution to the cursor BASE is refuted by §226 (entry 33). ⛔ **`SRC 0x08 = C-RAM[cursor]` is ANCHORED** by the CHORUS LFO (`C-RAM[0x00] = 114` ⇒ `+114`/frame; ★ §228 MEASURED the resulting ramp at **step 114..114 CONSTANT** over 1 175 985 frames) — **do not touch the source read** | `SQUARING-MULTIPLY_findings.md`, §226 |
| 39 | **`iw33`'s `f31 = 1` should not carry** (`UPD6383_NOCARRY`) — "the kernel ladder overflows because a term is being added that should not be" | ⛔ **REFUTED §227, FROM DISK BEFORE IT RAN, AND THEN MEASURED INERT.** `f31 == 1` is `HI_ACC_ADD`, **1309 of 2989** non-C-format corpus words and **695 of 1178** ALU-decoded; op 0 LOADs, op 2 HOLDs *without a product*, op 3 gets HOLD's behaviour ⇒ **it is the only accumulate the ISA has**, and the **PARAMETRIC EQ** biquad (grade SOLVED, validated at **0.198 dB** against its designer) sums five products through `f31 == 1` words `w6..w10`. Without the carry `H(z)` = `makeup · (−a2) · z⁻²`. **AND IT DOES NOT FIX THE CLIP:** `iw34` becomes `8 388 608` = `2²³` = **FS + 1** and clips `706040/706040` quiet, `313960/313960` loud — **unmoved from shipped.** ⇒ ★★★★ its `§S1` `4.924 % → 0.379 %` is **117 655 680 accumulate steps refusing to add**: **a clip rate that falls because a term stopped being added is a REGRESSION wearing a good number.** Collateral: `§104` body-0 goes 100 % input-INDEPENDENT and **`m_rf[0x8D]` vanishes** | §227 |
| 40 | **`P_SHIFT = 7` is the Q-consistent shift** — "`>> 6` is one bit short" | ⛔ **REFUTED §227, and the phrase had TWO meanings which are different experiments.** The core's own header records coefficients **Q1.22 (MEASURED from the firmware's scale constants)** and data Q0.23 ⇒ the Q-consistent TOTAL is **22**, which is what ships. **TIED (7/15, total still 22) is a MEASURED NO-OP** — the entire `§S1` block is BIT-IDENTICAL to the default over **269 279 999** conversions, the only differing line being the header text `>> 16` vs `>> 15`. **UNTIED (7/16, total 23) halves `m_rf[0x8D]` `0x009B26 → 0x004D93`** and *still* clips at `1.110 × FS`. ⚠⚠ **AND `§41` DOES NOT GUARD `P_SHIFT`** — it reads C-RAM *levels* `0x06`/`0x86` and is UNMOVED by a 2× product rescale; **`m_rf[0x8D] = 39 718` is the guard that fires.** Fix the three-guard phrase wherever it is quoted | §227 |
| 41 | **`C-RAM[0x90..0xB4]` is the header's BOOT-FIXED coefficient bank** (§226 item D, in its strong form) | ⛔ **REFUTED §227 BY THE CAPTURE §226 ITSELF ASKED FOR.** A preset change **CONCERT REVERB 1 → ROOM REVERB 1** rewrites **23 cells, every one inside `0x90..0xB4` and NOTHING else in the 256-cell C-RAM**: `[00..4F]` 0 of 80, `[50..8F]` 0 of 64, the header's own walk `[90..A3]` **13 of 20**, the ladder cells `[9B..9D]` **2 of 3**. ⇒ **it is UNIT 1's per-algorithm parameter bank**; it looked fixed only because both §226 captures carried the **same** reverb. ★ The control that makes it proof-grade: an independent 45 s panel run landing on CONCERT REVERB 1 reproduces the archived cold-boot capture on **all 256 cells, 0 differ** ⇒ **the cold-boot default reverb is CONCERT REVERB 1**, so every *"CHORUS + RR1"* label in §226 names the wrong preset. ⛔ **This does NOT re-open base `0x00`** (entry 33) | §227 |
| 42 | **The `f98` CROSS-UNIT A/B** — select GATED REVERB into unit 0 with a reverb preset in unit 1, making `012.A.00.1D5` / `212.A.00.1D5` co-resident in one frame (strategic review action 3) | ⛔ **NOT VIABLE, FROM DISK, NO BUILD.** The `f98 = 2` half sits at **`iw207`, inside body 1's third-death region, measured an EXACT ZERO on every channel in BOTH buckets across NINE archived arms** (§220 A/B/C/D, §221 A, §222 A, §223 F, §224 I, §225 K: `dp = 0xD0`, `acc 0..0`, `mem 0..0`, `L 0..0`) — **you cannot A/B a live number against a structural zero.** ★ And it is **UNNECESSARY**: `KERNEL w16 = 0192A00455` (`f98=1`) and `w17 = 0292A00455` (`f98=2`) differ in `f98` **and nothing else** and run **back-to-back in every frame of every program ever emulated**, already printed by `§104`/`§S1`/`§S2`. ⚠ Even that perfect pair is not a controlled measurement — it is a CHAIN (`iw17`'s carried term IS `iw16`'s result) and the two words necessarily read different coefficients. ⇒ **restate the closure: not *"no co-resident pair"* (falsified four ways) but *"NO DISCRIMINATOR"*.** ⚠ The review's sentence also dropped `a10 MULTI TAP DELAY`, which carries the same word | `PREDICT_F98_CORESIDENT.md`, §229 |
| 43 | **`hi12` bit 5 via ROCK ROTARY** — `000.2.00.000` vs `020.2.00.000` co-resident in `a15`, "one program load decides whether a `nop` the disassembler prints 62 times is a `nop`" (strategic review action 6) | ⛔ **VOID BY CONFOUND, AND THE CONFOUND IS 100 % OURS.** `000.2.00.000` matches the §223 nop guard on **all four** terms (`hi12 == 0x000 && class4 == 2 && addr8 == 0x00 && lo12 == 0x000`) and is **swallowed**; `020.2.00.000` fails the first term, falls through, and runs a full `exec_alu()` that **clears and reloads the accumulator** (`acc <- 0 + (mem[dp]<<16) + P`). Under `DSPCFG = 1` it **TRAPS** and the frame is discarded instead. §223's `addr8` narrowing does not help — `000.2.00.000` has `addr8 = 0x00` too. ★★★★ **DECISIVE: `hi12` bit 5 is read in EXACTLY ONE PLACE in the whole device — that guard's `hi12 == 0x000` equality.** Remove the guard ⇒ the two words execute **bit-identically**; keep it ⇒ the difference **IS** the guard. ⇒ **the review's own kill-condition (*"measures identical ⇒ bit 5 inert"*) CANNOT FIRE** — rule 8. ⚠ Also: the pair is co-resident in **TWO** images (`a70 AUTO WAH+S.DELAY` too, and `a70` is the one with a written vehicle), and the *"ready recipe"* is `verified: false` (29 of 224 are verified). ★ **STRIKE IT, DO NOT DEFER IT** — but keep §229 §2.1: the corpus DOES constrain bit 5 (`f31 in {3,6,7}` is bit-5-only, **53 of 53** static, **0 counterexamples in 246 952 062** live executions) | §229 |

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

19. **★ REPORT MEAN AND AC SPAN SEPARATELY, BOTH BUCKETS, BOTH ARMS, BEFORE CALLING ANYTHING
    AUDIO.** `min != max` is not signal: `79 438 ± 90` passes min-vs-max, the no-stimulus check
    *and* the translation rule, and is a **DC at −59 dB**. Mechanised — `§70`/`§211` print both.
    ⚠ `m_bx_sel0d` is FROZEN at 1 globally because the regression from moving it **IS** this DC.
    *(§221; and rule 1's two retracted "IC311 outputs audio" claims are the same shape)*

20. **★★ A NEW DETECTOR IS NOT EVIDENCE UNTIL IT HAS REPRODUCED AN ANSWER ALREADY ON RECORD —
    AND THE SELF-TEST IS PRINTED FIRST, NOT APPENDED.** A census printing a clean zero is
    indistinguishable from a correct negative, and a classifier agreeing with itself is
    indistinguishable from a correct one. Before interpreting ANY output of a new instrument:
    * validate it against known answers, **at least one of which would FAIL if the detector were
      broken** — a control every arm passes is rule 15's reach test, not a test;
    * prefer at least ONE **EXTERNAL** control — an answer produced by a *different* instrument.
      §225's `§S3` earned its keep this way: mask bit 26 counts the identical predicate at the
      identical hook and §220 measured **5 881 351**; `§S3` reported **5 881 351**;
    * ⚠ **internal consistency that is TRUE BY CONSTRUCTION IS NOT A SELF-TEST.** `§S2`'s
      `carried + bus + P == result` cannot fail — the terms are split out of `src_term` itself —
      and the source says so; its real controls are four pre-registered per-term values;
    * ⚠ **a control must be a case whose answer is known INDEPENDENTLY of the thing under test.**
      *(new, 2026-07-31: a sweep's "known PRESENT" control was itself one of the known-ABSENT
      cases, and demanded the opposite of the right answer);*
    * ⚠⚠ **AND AN INSTRUMENT CAN BE WRONG WHILE EVERY ARM AGREES WITH IT** *(new, §228)*: the
      `§196` LFO wrap census printed **0.5000 Hz** on every arm anyone ever ran, because its
      denominator included the **264 001** frames before the program is uploaded (during which
      the ramp is frozen) and its numerator truncated the last partial wrap. The rate it was
      hiding — **0.652313 Hz** — had been quoted in `LEDGER.md` for weeks as if measured; it had
      only ever been **derived from the increment**. ⇒ **before quoting a figure as MEASURED,
      find the log line it came from.** A number nobody can point at in a log is a derivation.
    * **print the result of every check, PASS or FAIL, before the finding** — reporting only the
      passes is how `§121` ran seven arms that were all the same arm.
    ⇒ **Report your failed controls out loud.** `UNWRITTEN-CELLS_findings.md` §2 opens *"two of
    them FAILED"*, and that is what makes the other five worth reading.
    *(named across §224/§225/§226; `hdrbase.py` 10 self-tests + 3 external, `f31carry.py`,
    `SQUARING-MULTIPLY_findings.md` §1, `HEADER-BANK_findings.md` §1 — all invoked it, none
    defined it, for 17 citations across 10 files; DEFINED HERE by §228)*

21. **★★ `§104`'s AND `§86`'s QUIET-VS-LOUD MARKERS CANNOT DISTINGUISH "INPUT-DEPENDENT" FROM
    "FREE-RUNNING AND SAMPLED OVER TWO FRAME SETS" — BUT THE SPLIT IS COMPUTABLE.**
    Proof, from a case in every log this project has ever taken: cell `07` quiet `[4 .. 8388594]`
    loud `[8 .. 8388598]` — the LFO phase, with no input in it; the endpoints differ by **less
    than one increment (114)** because the buckets are different *sets of frames*.
    ★ **The discriminator is FORCED by the instrument's own bucket predicate**
    (`nz = (m_in_val[0] != 0) || (m_in_val[1] != 0)`): the quiet bucket is the frames where the
    input latch reads **EXACTLY ZERO**, the same value on all 706 040 of them, so a **DEGENERATE
    quiet range (`min == max`) PROVES input dependence** and a non-degenerate one proves
    free-running state. `dsp/tools/rule21_all.py <log>` does it in one line.
    ⛔ **NEVER QUOTE A `§104`/`§86` COUNT AGAIN WITHOUT ITS `D-I` SPLIT.** Under it, `28/32/28`
    survives as `26/28/27` proof-grade + `0/4/1` free-running, and the shipped build's `2/4/1`
    "null" is **100 % free-running — body 0 is `0/0/0`**. Damage is confined to rows reading cell
    `0x07` or `0x10`; every other published tally is proof-grade. *(§224, operational §225)*
