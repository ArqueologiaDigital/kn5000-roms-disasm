# CONTROL AUDIT — what every cited control can DETECT, and what it SILENTLY PASSES

**2026-07-31. Read-only pass. NO BUILD, NO MAME RUN, NO AUDIO CLAIM.** Every output figure below
**quotes its arm**. Nothing here was produced by running the emulator; the live-run numbers are read
out of the **40 archived arm logs** in `analysis/data/*.log.gz`, and the two offline reruns
(`sd_rerun.py control`, `sd_rerun.py value`) are pure-Python tools that touch no ROM but the
committed ones.

> **The prompt for this pass:** `§227` found that `§41` — quoted in every dispatch brief for days as
> *the* calibration guarding output scaling — **cannot detect a scaling change at all**. That is the
> "criterion that cannot fail" failure mode, the one this project has caught thirteen times in its
> **experiments**, sitting inside its **controls**. This pass looks for the others.

---

## 0. THE HEADLINE

**38 controls enumerated. 21 SOUND · 9 MIS-AIMED · 5 CANNOT-FAIL · 3 UNTESTED.**

`§41` is **not** the only one. It is not even the worst one. The worst one is
**SINGLE DELAY's `+0.02149296`** — cited as a live falsifier in four current documents including
the **STRATEGIC REVIEW's priority #1** and **`BUILD-LANE-QUEUE.md` item 9** — whose harness, rerun
today, **accepts exactly the machine it was built to reject** and returns `NO FIRST ECHO` on the
baseline *and* on all three of its own coefficient-scramble nulls. It cannot fire, in either
direction, on anything.

★★★ **AND THE STRUCTURAL FINDING, which is bigger than any single control:** four of the five
CANNOT-FAIL controls (`§54`, `§70`, `§211`, the rule-19 mean/span line) all read the **same proven
null**. `§216` established the output stage presents zero even with body 0 running its whole ladder
on live audio. Therefore **no change upstream of the presentation can move any of them** — and the
archive proves it: across the **31 modern arms** those four are unmoved in **29**, and the only two
that move them (`C_xb85_full_222`, `D_xb85_route_222`) are the two arms that changed the **output
stage itself**. Quoting *"§54 clean | §70/§211 mean 0.0 span 0 — PASS"* as a regression falsifier
for a **kernel-A or body-0 arithmetic change** is quoting four copies of one criterion that
**cannot fail by construction**.

---

## 1. METHOD, AND THE SELF-TEST FIRST (★★★ RULE 20)

### 1.1 How the controls were enumerated (the denominator)

Three enumerations, unioned, none of them a grep for a spelling:

| # | enumeration | denominator | tool |
|---|---|---|---|
| **E1** | every **graded falsifier row** (`label … PASS/FAIL`) in the six live documents | **52 graded rows under 26 distinct labels** | `GRADED` regex over `SPECULATIVE-APPLIED-REGISTER.md`, `HANDOFF-NEXT.md`, `LEDGER.md`, `LEDGER-HEAD.md`, `BUILD-LANE-QUEUE.md`, `STRATEGIC-REVIEW-2026-07-31.md` |
| **E2** | every **`§`-instrument named on a line that also says** *falsifier / calibration / control / known-answer / self-test* | **80 distinct `§` tokens**, of which 24 survive de-noising (`§1`–`§8` are sub-section numbers, not instruments) | same six documents |
| **E3** | every **offline / repo-level check** cited in an evidentiary role | 7 | `dsp/verify.py`, `peq_*`, `sd_rerun.py`, `f31carry.py`, `hdrbase.py`, the §227 panel replay |

Merging E1∪E2∪E3 and collapsing to the unit **"one quantity + one criterion"** gives **38 controls**.
The `W`-labels alone (`W0 W1 W2 W3 W4 W4′ W4′-b W4′-c`) are eight *rows* but read only five distinct
quantities, so rows are not the unit; quantities are.

The graded-row breakdown, for the record — **52 rows, 47 PASS, 5 FAIL**, and **all five FAILs are the
same label** (`W4`, quoted in four documents):

```
   EXT 7P/0F   H1 1/0   H4 1/0   K1 2/0   K2 2/0   K3 2/0   N0 1/0   N1 1/0   N2 1/0
   P0  1/0     P5 1/0   Q1 1/0   Q2 1/0   R  1/0   R1 5/0   R2 1/0   S1 1/0   T5 1/0
   T6  1/0     W0 5/0   W1 2/0   W2 3/0   W4 0P/5F  W4′ 1/0  W4′-b 2/0  W4′-c 2/0
```

⚠ **47 of 52 published falsifier rows PASS.** That ratio is itself a warning sign and is the reason
this audit exists: a battery that almost never fires is either measuring an already-correct machine
or measuring nothing.

### 1.2 The instrument this pass built, and its self-test — **24 of 24 PASS**

The detector is a **demonstrated-sensitivity census**: extract each control's printed value from
every one of the 40 archived arms and count how many **distinct values** it takes. A control that is
**bit-constant across every arm the project has ever run** has never demonstrated sensitivity to
anything.

Per RULE 20 the extractor was validated against known answers **taken from the register before the
script existed**, and the self-test is printed first. It **caught one real defect in its own code on
the first run** (`T12`, the `§S1 iw39` extractor was substring-matching instead of parsing the census
table — the `962`-inside-`962 880` fingerprint trap, in its exact form).

```
==============================================================================
SELF-TEST FIRST (RULE 20).  Known answers taken from the register, not from this run.
==============================================================================
  T1 §41 unmoved in arm N_227                          PASS
  T1 §41 unmoved in arm P_227                          PASS
  T1 §41 unmoved in arm Q_227                          PASS
  T2a rf8D arm N                                       PASS
  T2b rf8D arm P                                       PASS
  T2c rf8D arm Q HALVED                                PASS
  T3 rf8D arm O ABSENT                                 PASS
  T4a §S1 arm K = 4.924 %                              PASS
  T4b §S1 arm L = 5.303 %                              PASS
  T5 bit26 fired 5 881 351                             PASS
  T6a §46 nz = 0 in arm A_off_220                      PASS
  T6b §46 nz = 3 494 021 in arm C_noz05_220            PASS
  T7 §221 F3 w72 L = 4194304 both buckets              PASS
  T8 §S3-C4 = 0 PASS in arm M                          PASS
  T9  NEG §S1 absent from the pre-§223 arm A_off_220   PASS
  T10 NEG §S3 verdict absent from arm I_s2_224         PASS
  T11 §54 present in >= 30 of 40 arms                  PASS   (40)
  T12 §S1 iw39 loud min = 1 991 044 in arm F_satcen_223 PASS  <- FAILED on the first run; code fixed
  T13 NEG §S1 has a row 34 and no row 0                PASS
  T14a §104 body0 raw = 28/32/28 on the NOZ05 rig      PASS
  T14b §104 body0 raw = 2/4/1 on the pre-LFOWRAP arm   PASS
  T15a rule21 D-I body0 = 26/28/27 on the rig          PASS
  T15b rule21 D-I body0 = 0/0/0 shipped                PASS
  T15c rule21 D-I body0 = 26/23/23 on XB85             PASS
  ---> 24 of 24 PASS
```

**Four are NEGATIVE controls** (`T3 T9 T10 T13` — the extractor must return *absent*, not a value,
where the instrument did not exist yet or where the row must not exist). **Fifteen are EXTERNAL**
(the known answer comes from a register section, not from the script). The §104 limbs (`T14`, `T15`)
run through the project's **own** `parse104.py` + `rule21.py`, not a reimplementation.

### 1.3 The census — demonstrated sensitivity over 40 archived arms

⚠ **Arm-family split, and it matters.** `parse104` reports **285 §104 rows** for the modern program
layout and **320** for the legacy one. That is a clean programmatic discriminator: **31 modern arms**
(§211 onward) and **9 legacy** (`bodyonly`, `demux_sweep`, `peq_*` ×4, `ship_*` ×2, `stale138`).
The falsifier lists were written inside the modern family, so the modern column is the one that
grades them.

| control | arms | distinct values, **all 40** | distinct, **31 modern** | which arms move it |
|---|--:|--:|--:|---|
| `§41` level **value** | 40 | 2 (`0x178D0A`/`0x178D0B`) | **1 — NEVER MOVES** | only the pre-§188 legacy family |
| `§41` non-zero **count** | 40 | 5 | 2 | run-length only |
| `m_rf[0x8D]` | 30 | **4** | **4** | `C/D_xb85_222` → `7FFFFF`; `O_227` → **absent**; `Q_227` → `004D93` |
| `§54` tracking | 40 | 10 | **2** | only `C/D_xb85_222` |
| `§70` ACCA@w73 | 40 | **2** | **2** | only `C/D_xb85_222` |
| `§211` ACCB@w78 | 30 | 3 | 3 | only `C/D_xb85_222` |
| rule-19 mean/span | 19 | 3 | 3 | only `C/D_xb85_222` |
| `§61` presentation | 40 | 10 | **2** | only `C/D_xb85_222` |
| `§221 F3` (`w72`, `L`) | 10 | **1 — NEVER MOVED** | 1 | — |
| `§44` tap-table fetches | 40 | **1 (= 0 in 40 of 40)** | 1 | — |
| `§S1` TOTALS | 12 | 6 | 6 | `G H O Q`, and the LFOWRAP pair |
| `§S1` CONTROL row | 12 | 3 | 3 | `O_227`, `Q_227` |
| `§S1` `iw39` | 10 | 2 | 2 | `G/H_223`; **row VANISHES in `O_227`/`Q_227`** |
| `§S3` VERDICT | 7 | **1 (`SETTLING`)** | 1 | — |
| `§S3` ladder | 7 | 3 | 3 | `O_227`, `Q_227` |
| `§S3` TOTAL / `§S3-C4` | 7 | **1 / 1** | 1 / 1 | — |
| `§46` delay port | 40 | 14 | 8 | the send-open family |
| `§48` / `§75` | 40 | 16 / 13 | ~9 | the send-open family |
| `§86` input-dep. writes | 40 | **17** | 10 | many |
| `§104` RAW body-0 | 40 | 8 | **4** (`2/4/1`, `2/9/4`, `28/32/28`, `0/0/0`) | send state **and** LFOWRAP |
| `§104` D-I body-0 | 40 | 4 | **4** (`0/0/0`, `26/28/27`, `17/16/15`, `26/23/23`) | send state **only** |
| `§104` D-I body-1 | 40 | 4 | 4 (`0/0/0`, `2/1/2`, `0/0/1`, `59/44/49`) | send state only |
| `§104` D-I epilogue | 40 | **2** (`0/0/0`, `22/19/9`) | 2 | only `C/D_xb85_222` |

---

## 2. THE CLASSIFIED INVENTORY — 38 controls

Legend: **SOUND** — detects the class it is cited for · **MIS-AIMED** — cited for X, sensitive to Y
· **CANNOT-FAIL** — passes everything in its stated role · **UNTESTED** — nobody has established what
it is sensitive to.

### 2.A Device-report controls (20)

| # | control | DETECTS | SILENTLY PASSES | class |
|---|---|---|---|---|
| **A1** | **`§41` level at presentation** — `m_lvl_seen[unit]`, the last value read out of `m_rf[0x06]`/`m_rf[0x86]` | the **host-payload decode path** (§111 ×2, §188 LSB, §197 poke nibble — the `0x178D0A → 0x178D0B` step is §188 firing), the source-select bits 6/23, and any writer that clobbers `0x06`/`0x86`; **and whether the presentation ran at all** | **every arithmetic change in the machine.** It is a *stored register value*, never a product. `0x400000 / 0x178D0B` is **bit-identical in 31 of 31 modern arms**, including `Q_227` which halves every product | **MIS-AIMED** |
| **A2** | **`§41` LEVEL GUARD** (mask bit 5) — suppressed zero-stores onto `0x06`/`0x86` | an unsupported source overwriting the host's level | unknown — **the line is conditional on `m_lvlguard_n` and is absent from all 40 arms**; the guard has never been observed to fire | **UNTESTED** |
| **A3** | **`m_rf[0x8D] = 0x009B26 = 39 718`** (`§160` register dump; `= 2 603 010 048 >> 16`, and `§104` rows 60/61 print that accumulator) | **`ACC_SHIFT` / product scaling** (`Q_227` → `0x004D93 = 19 859`, exactly half); the removal of the accumulate (`O_227` → **cell absent**); epilogue crossbar routing (`C/D_xb85_222` → `0x7FFFFF`). **It has actually FAILED, in §222 §3** | anything not reaching `w61`'s self-loop — i.e. **body 0, body 1, the delay path, the send.** `§221` established `0 of 14` epilogue operands trace to body 0 | **SOUND** ★ the one that fires |
| **A4** | **`§221 F3` — `w72`, `L = 4 194 304`, provenance HOST** | that the `§E1` provenance census **resolves a known cell to its known value** (route + index + datum) | ⚠⚠ **everything `§41` passes — because it is the same datum.** `4 194 304 = 0x400000 = m_rf[0x06]`. `§41`'s unit-0 level and `F3`'s `L` are **one number read twice**. `RISK-TRIAGE` calls `F3` *"the same value by a second route"* — a second **route**, not a second **datum**. **Never moved in 10 of 10 arms** | **MIS-AIMED** (quoted as independent corroboration of A1) |
| **A5** | **`§54` TRACKING** — quiet/loud frame split, peaks, `DC / SILENT / TRACKS` verdict | a **DC or a pass-through that reaches the output**. It has fired: `C/D_xb85_222` go `q826040→0/826040 pk8388607` | ★★★ **every change upstream of the output-stage null.** Unmoved in 29 of 31 modern arms. `§216` proved the null by feeding it | **CANNOT-FAIL** in the falsifier role (`W3`, `H5`); SOUND in its own role |
| **A6** | **`§70` ACCA at `w73`** min/max, both buckets | a non-zero reaching `ACCA` at the presentation | same as A5. `q[0..0] l[0..0]` in **29 of 31 modern arms** — including `C_noz05_220`, where **body 0 runs at `28/32/28` on live audio** | **CANNOT-FAIL** in the falsifier role |
| **A7** | **`§211` ACCB at `w78`** min/max | a non-zero reaching `ACCB` | same as A5/A6 | **CANNOT-FAIL** in the falsifier role |
| **A8** | **`§221` rule-19 mean vs AC span** | a **DC dressed as audio** (`\|mean\| >> span`) — the `79 438 ± 90` pedestal case | same as A5/A6/A7. `A:0.0/0,0.0/0 B:0.0/0,0.0/0` in 17 of 19 arms that print it. **Rule 19 is a correct rule mechanised onto a quantity that is structurally zero** | **CANNOT-FAIL** in the falsifier role |
| **A9** | **`§61` per-unit presentation** exec / non-zero / peak | the presentation firing, and any output | same as A5 (2 distinct values in 31 modern arms) | **SOUND** for cadence; weak for content |
| **A10** | **`§S1` TOTALS clip rate** (`4.924 % / 4.920 %` shipped) | **any change to the accumulator's magnitude** — 6 distinct values over 12 arms, spanning `0.379 %` (`O_227`) to `9.766 %` (`H_noz05m2_223`) | a change that moves values without crossing full scale; and **everything before frame 420 000** | **SOUND** |
| **A11** | **`§S1` CONTROL — *"must be clips = 0"*, `iw34` and `iw40`** | nothing, **as printed**. `iw34` reads **`706040/706040` clips/calls — 100 %, in every one of the 12 arms that print it.** `iw40` reads `0/0` — **zero samples** | ⚠ the criterion was refuted on its first run (§223 §2, the off-by-one, **fifth occurrence**) and the *line still prints the refuted criterion*. Its `[q min..max]` field **is** sensitive (`14 428 403` → `9 311 353` in `Q_227` → `8 388 608` in `O_227`) — the control is reading the right number under the wrong predicate | **MIS-AIMED** |
| **A12** | **`§S1` `iw39` loud min `1 991 044`** | scaling and datum changes on `iw38`'s post-value. Moves to `1 991 044 → −19 962 850` on `G/H_223` | ⚠⚠ **its own evaluability is conditional on the null.** `§S1` emits a row **only where it clips**; in `O_227` and `Q_227` — precisely the two arms that changed the scaling — **the `iw39` row does not exist at all**, so the falsifier silently becomes vacuous rather than failing | **SOUND** ⚠ evaluability-conditional |
| **A13** | **`§S1` PROVENANCE line** (every row is the PRE-update accumulator = the previous slot's `§104 acc >> ACC_SHIFT`, verified 8 of 8) | the after-slot/before-slot off-by-one, mechanised into the log | nothing else — it is a **statement**, not a measurement | **SOUND** (its purpose is to make a documented trap unrepeatable) |
| **A14** | **`§S2`'s `T1`–`T4` external term controls + the `T6` row exclusion** | wrong per-term decomposition — four values derived from `§104` + the frame trace **before the code existed**, matching digit for digit; `T6` is two-sided (`iw34` must **not** appear, and does not) | terms that are wrong in both instruments identically | **SOUND** ★ the model control battery |
| **A15** | **`§S3`'s "EXTERNAL" control — mask bit 26's `5 881 351`** | that the two counters agree, across builds and arms | ⚠⚠ **the source itself says the predicate is identical**: `upd6383.cpp:1326` `if (mode != 1 && dest == 0x06) s3_boot(...)` and `:1327` `if (… && mode != 1 && dest == 0x06)` — **the same expression, at adjacent lines, on the same call**. So it validates **counter plumbing**, and cannot detect a *wrong predicate*, a wrong `pre`, a wrong epoch-0, a wrong ladder or a wrong verdict — which is everything `§S3` exists for. This is §224's own *"internal consistency true by construction is not a self-test"*, one section later | **MIS-AIMED** |
| **A16** | **`§S3` EPOCH-0 / ladder / VERDICT** | scaling and datum at the entry — the ladder **moved** in `O_227` (`#1360 iw33 6 039 795`) and `Q_227` (`#1357 val 394 475`, vs `1 650 061` shipped) | the verdict itself is coarse: `SETTLING` in **7 of 7** arms | **SOUND** (ladder) |
| **A17** | **`§S3-C4`** — host tag-`0x15` writes to D-RAM `0x06` must be `0` | a host poke reaching the cell (would fire if mask bit 23 were cleared) | `0 PASS` in **7 of 7** arms; **never exercised in the direction that would make it fire** | **UNTESTED** |
| **A18** | **`§46` DELAY PORT** reads / non-zero / writes | the send state, decisively: `nz 0 → 3 494 021` between `A_off_220` and `C_noz05_220`; 8 distinct values in the modern family | scaling; anything not touching the delay port | **SOUND** |
| **A19** | **`§44` TAP-TABLE fetches** | unknown. **The count is `0` in 40 of 40 arms.** A census printing a clean zero is indistinguishable from a correct negative — RULE 20, verbatim | unknown | **UNTESTED** |
| **A20** | **`§48` / `§75` delay-consumption counters** | delay-path liveness (16 / 13 distinct values over 40 arms) | scaling | **SOUND** |

### 2.B Cross-arm `§104` tallies (7)

| # | control | DETECTS | SILENTLY PASSES | class |
|---|---|---|---|---|
| **B1** | **`§104` RAW `*` marker tally** (`28/32/28`, `2/4/1`, `2/9/4`, `2/1/2`, `22/19/9`) | that a slot's quiet range differs from its loud range at all — 4 distinct body-0 values in the modern family, and it **did** move for LFOWRAP (`2/4/1 → 2/9/4`) | **the difference between input-dependence and a free-running ramp sampled over two frame sets** — that is RULE 21, and it is why `W4` "failed" | **SOUND** as a marker census, provided the `D-I` split is quoted with it |
| **B2** | **`§104` RULE-21 degenerate-quiet (`D-I`) discriminator** | proof-grade input dependence, forced by the instrument's own bucket predicate `const bool nz = (m_in_val[0] != 0) \|\| (m_in_val[1] != 0);` | ⚠ **the send being SHUT.** With the send shut, body 0 sees no input at all, so `D-I` is **structurally `0/0/0`** whatever the arithmetic does | **SOUND** as a discriminator; see B3 for its mis-use |
| **B3** | **`W4′` — "body 0 `D-I` `0/0/0 → 0/0/0`"**, the gate that shipped `UPD6383_LFOWRAP` | **the send opening.** It fires on `NOZ05` (`26/28/27`), `XB85` (`26/23/23`), `SRC0B2` (`17/16/15`) | ⚠⚠ **every arithmetic change made with the send shut** — which is the entire class `LFOWRAP` belongs to. **`0/0/0` in 20 of 20 send-shut modern arms (29 of 40 counting the 9 legacy arms)**, spanning four different mask defaults, the store-probe fix, `EPIBUS`, `PICKUP`, `NOCARRY`, `PSHIFT`, and both LFOWRAP polarities. §225's defence — *"the XB85 arms score `26/23/23` on the same instrument"* — names an arm in a **different class**; within `W4′`'s own class it has no reachable failure | **MIS-AIMED** |
| **B4** | **body 1's `2/1/2`** | quoted as a proof-grade tally | ⚠ **the same trap the brief flags for `26/28/27`, and it is not flagged anywhere.** `2/1/2` is the RAW tally on 9 arms, but its `D-I` split is `2/1/2` **only on the NOZ05 family**; on `src0b2_B_on_215` and `drpub_C_on_src0b2_217` the identical raw `2/1/2` grades **`0/0/1`** | **MIS-AIMED** when quoted without its arm |
| **B5** | **the epilogue's `22/19/9`** | the epilogue crossbar. RAW **and** `D-I` are both `22/19/9`, and both are `0/0/0` in 38 of 40 arms | everything outside `C/D_xb85_222` | **SOUND** (100 % input-dependent, correctly stated) |
| **B6** | **§220's *"`28/32/28`, slot for slot IDENTICAL to the §215 `SRC0B2` calibration arm"*** | ✔ **the raw-marker claim is literally true** — verified here, the marker **sets** are equal element for element: body 0 `acc` 28≡28, `mem` 32≡32, `L` 28≡28; body 1 `2/1/2` ≡ `2/1/2` | ⚠⚠ **the content behind those markers.** Under the project's own RULE-21 grade the two arms are **not** equivalent: body-0 `D-I` **26/28/27 (rig) vs 17/16/15 (SRC0B2)**, body-1 `D-I` **2/1/2 vs 0/0/1**. Nine body-0 `acc` slots (`122 124 125 126 127 129 131 132 142`) are proof-grade on the rig and undecidable on the calibration arm. The identity was cited to certify *"the rig delivers the same signal"*; it certifies *"the rig marks the same slots"* | **MIS-AIMED** |
| **B7** | **`§86` input-dependent kernel D-RAM writes** | a great deal — **17 distinct values over 40 arms**, the most sensitive control in the inventory | subject to RULE 21 exactly as `§104` is (§224 states this) | **SOUND** |

### 2.C Offline / repo-level checks (7)

| # | control | DETECTS | SILENTLY PASSES | class |
|---|---|---|---|---|
| **C1** | **`dsp/verify.py` BYTE-MATCH OK** (cited as `K3`/`R2` on the LFOWRAP and PSHIFT gates) | that the `dsp/` disassembly tree round-trips the ROM — 91 IC311 programs, kernel and epilogue | ⚠ **every possible change to `upd6383.cpp`.** It reads `original_ROMs/*.rom` and `dsp/disasm/*.dsm` and imports one ROM parser; **it has no dependency on the emulated device whatsoever.** A C++ gate cannot move it, in either direction | **CANNOT-FAIL** in the gate role; SOUND in its own role |
| **C2** | **PARAMETRIC EQ, `0.198 dB` against its designer** | ✔ **the `f31 == 1` carry** — this is a real falsifier and §227 used it correctly (without the carry `H(z)` collapses to `makeup·(−a2)·z⁻²`); also a wrong coefficient decode (`peq_tf.py`'s ISO-centre pole check) | ⚠ **anything upstream of the biquad's first `f31 == 0` word.** `dsp/README.md` already records this in terms: *"THE BIQUAD CANNOT DECIDE IT, AND THAT IS A CONTROL THAT CANNOT FAIL — all four readings score the baseline 0.198 dB exactly, because PEQ's biquad begins with an `f31 = 0` word (`acc ← P`) which discards the accumulator"*. Also passes **any `P_SHIFT`/`ACC_SHIFT` change**: the offline model is floating-point and has no such split | **SOUND** for the carry; documented **CANNOT-FAIL** for `f31hi` and for `P_SHIFT` |
| **C3** | **SINGLE DELAY's `+0.02149296` three-factor product** — cited as a falsifier in `HANDOFF-NEXT.md` §1.-0.3 item 1, §224 item 3, `BUILD-LANE-QUEUE.md` item 9, and `STRATEGIC-REVIEW-2026-07-31.md` priority #1 | ⚠⚠ **nothing that any committed code can evaluate.** `ROADMAP-2026-07-29.md` already recorded *"`lag 1001, gain +0.02149296` is reproducible from no committed code anywhere"* and *"SINGLE DELAY cannot pass"*. **Rerun here, today:** `sd_rerun.py value` returns `NO FIRST ECHO` on `BASELINE`, on all four `dest07` calibration limbs, **and on all three coefficient-scramble NULLs** — one outcome for eight configurations | in principle it would track the coefficients (`single-delay-restored.md` §5.5); in practice the harness emits nothing | **MIS-AIMED** — cited live, cannot be run |
| **C4** | **the SINGLE DELAY control leg** (`sd_rerun.py control`) — *"the harness must PASS a machine that should work and FAIL one that should not"* | ⚠⚠ **it is INVERTED, and reproducibly so.** Rerun today, verbatim: `CORRECTED (dram_dir, +1)` → **`NO SIGNAL`**; `reversed + cursor −1` (the doubly-defective round-6 configuration) → **`500 ★ MATCHES the descriptor`** | — | **MIS-AIMED** (actively inverted; worse than cannot-fail) |
| **C5** | **`f31carry.py` — 18 of 18, 7 external** | a great deal: corpus counts, four raw kernel words, five values imported from **other instruments** (`§S2`, `§S1`, `§S3`), two ROM captures, and **one two-sided `CONTROL` limb that must DIFFER** (`ladder @0x0B != §S2`) | it is a static/corpus tool; it cannot see the live machine | **SOUND** ★ the best-built control battery in the repo |
| **C6** | **`hdrbase.py --score` — 3 of 3, orientation-sensitive** | it **fails in the other direction** (run with ROOM 1 as control, limbs 2 and 3 FAIL) — a genuine two-sided design | — | **SOUND** |
| **C7** | **§227's 45 s panel replay — 256 C-RAM cells, 0 differ** | replayer fidelity, navigation perturbation, and the identity of the cold-boot preset; **it could have failed on any of 256 cells** | — | **SOUND** ★ external and decisive |

### 2.D Meta / bookkeeping controls (4)

| # | control | DETECTS | SILENTLY PASSES | class |
|---|---|---|---|---|
| **D1** | **"*N* diff lines, NOT ONE a measured value"** (`K1`, `K2`, `R`, `R1`, and §227's inertness proof) | ★ **the broadest control the project has** — it reads the entire `upd6383:` report. Reproduced here: `N_227` vs `M_s3_census_225` = **4 diff lines, all four env-var banners** (`NOCARRY` announce, `PSHIFT` announce, and their two fired-count lines); `M` vs `K` = 2 lines, the widened `§S3` census; `K` vs `J` = 12 lines, all banners plus the newly-added `§S3` block | ⚠ everything the report does not print, and **everything before the arming frame** (see §3.4); the *"none a measured value"* verdict is **human judgement, not mechanised** — `lint_handoff.py` checks staleness, not this. ⚠ the line-count convention is **inconsistent between citations** (`K1` says 7 where a raw both-sides `diff` gives 12; `N vs M` quotes 4 where both sides give 4) | **SOUND** ⚠ un-mechanised, inconsistent unit |
| **D2** | **unconditional fired count** (rule 8) | that a gate was **exercised**, separating "0 fires" from "never ran". `W0`'s `1 176 960 / 1 slot` is the model case | whether the fire was *correct* | **SOUND** |
| **D3** | **`lint_handoff.py` — 8 of 8** | stale masks, clip rates, gate defaults, rule numbers, counts quoted in the handover docs | anything not a literal it knows about | **SOUND** |
| **D4** | **`gen_fixlist.py` — 17 of 17** | the shipped-fix denominators, derived from the source's own gate declarations | attribution where two gates share a comment block — **and it says so rather than picking** | **SOUND** |

### 2.E Counts

| class | n | of 38 | which |
|---|--:|--:|---|
| **SOUND** | **21** | 55 % | A3 A9 A10 A12 A13 A14 A16 A18 A20 B1 B2 B5 B7 C2 C5 C6 C7 D1 D2 D3 D4 |
| **MIS-AIMED** | **9** | 24 % | **A1 A4 A11 A15 B3 B4 B6 C3 C4** |
| **CANNOT-FAIL** | **5** | 13 % | **A5 A6 A7 A8 C1** |
| **UNTESTED** | **3** | 8 % | **A2 A17 A19** |

⚠ **A concentration worth naming:** the 5 CANNOT-FAIL entries are **not 5 independent weaknesses**.
`A5 A6 A7 A8` are four readings of **one** quantity — the value presented at `w73`/`w78` — which
`§216` proved is a null independent of everything upstream. The falsifier lists quote all four as
though they were four checks.

---

## 3. WHICH RECORDED CONCLUSIONS REST ON A WEAK CONTROL — RANKED

Ranked by **how load-bearing**, not by how wrong.

### ★★★★ 1. `BUILD-LANE-QUEUE` item 9 / `STRATEGIC-REVIEW` priority #1 — the **next** experiment is gated on a falsifier that cannot fire

Not a past conclusion — a **forward commitment**, which is why it ranks first. The `§S2sq`
`cursor + 1` question and the kernel-A rail are both pre-registered with the falsifier list
*"`§41`, SINGLE DELAY's validated `+0.02149296` three-factor product, and now `§S3`'s ladder"*.
Of those three:

* **`§41` is MIS-AIMED** (§227 established it; it is still in the sentence).
* **SINGLE DELAY's `+0.02149296` cannot be evaluated** — verified live above, in both legs.
* **`§S3`'s ladder is SOUND**, and is doing all the work alone.

⇒ **Two of the three named falsifiers for the project's next build-lane experiment are inert.**
A `cursor + 1` reading that is wrong would be caught by `§S3`'s ladder and `§S1`'s rate, and by
nothing else on the list. **This is the item to fix before the lane runs.**

### ★★★ 2. §220 — *"`28/32/28`, slot for slot IDENTICAL to the §215 `SRC0B2` calibration arm"*

The cross-arm corroboration of **THE send model** — quoted in `LEDGER.md` TIER 0a-prev, in
`HANDOFF-NEXT.md`, and in `MEMORY.md`. The identity is **true for the raw markers** (verified: the
sets are equal element for element) and **false for the proof-grade content** (`26/28/27` vs
`17/16/15`; body 1 `2/1/2` vs `0/0/1`). The comparison quantity is exactly the one RULE 21 later
retired.
✔ **The conclusion survives** — §225 re-graded the rig *on its own* and got `26/28/27` proof-grade
against a `0/0/0` null. What falls is the **corroboration**, and with it the claim that the two arms
deliver the same thing.
**Cheapest fix, one command:** `dsp/tools/rule21_all.py data/C_noz05_220.log.gz data/src0b2_B_on_215.log.gz`
prints both splits on one screen. Re-word the claim to *"the same slots, with different proof-grade
content"*.

### ★★★ 3. §225 — the falsifier list that shipped `UPD6383_LFOWRAP` (**a shipped gate**)

Eleven graded rows. **Three of the eleven could not have caught the gate's failure mode:**

| row | quantity | why it could not fire |
|---|---|---|
| `W3` (part) | `§41`, `§54`, `§70`/`§211` mean/span | §41 unmoved in 31/31 modern arms; the other three read the proven output null |
| `W4′`, `W4′-b`, `W4′-c` | body-0 `D-I` | `0/0/0` on 20/20 send-shut modern arms, whatever the arithmetic |
| `K3` | `dsp/verify.py` BYTE-MATCH | reads ROMs and `.dsm` files; cannot see `upd6383.cpp` |

✔ **The gate is NOT at risk.** `W0` (fired `1 176 960`, one slot), `W1` (`§S1` moves by **exactly**
`−706 040` / `−313 960`) and `W2` (`§119 iw94` becomes a `+114`/frame ramp — §225's own *"the
decider"*) are all sound, two-sided and did move. What is at risk is the **published strength of the
evidence**, which reads as 11 of 11 and is really 6 of 11 plus `m_rf[0x8D]`.

### ★★ 4. §225 — *"`§S3`'s first control is EXTERNAL and passed to the unit"*

This retired §224's *"cell `0x06` is a BISTABLE"* framing and installed `SETTLING` / *"0 is not a
fixed point"* in TIER 0a. The control is **the same predicate at the same hook**, by the source's own
admission. It proves the counters agree; it does not touch the epoch split, the `pre` semantics, the
ladder thresholds or the verdict.
✔ The **ladder** is independently sound (it moved in `O_227` and `Q_227`), so the conclusion is not
falling — but *"EXTERNAL"* overstates it.
**Cheapest replacement, already printed:** `§176`'s `06:8388607(0..8388607/chg1100)` gives an
independent change-count for the same cell from a different instrument, and `§104` row 19's `acc`
gives the datum. Either is a genuine external limb.

### ★★ 5. §222 — *"the `F1` half that WAS upstream — `§41` … — PASSED in every arm, including C and D"*

In the same two arms the co-cited `m_rf[0x8D]` control **FAILED** (`0x009B26 → 0x7FFFFF`). The
"passing" half is the half that cannot fail. §222's conclusion rests on other evidence (`P5`,
`D-RAM[0x85]` has no writer) so the risk is contained — but this is the clearest single instance in
the archive of a mis-aimed control and a sound one sitting side by side and being reported as two
results.

### ★ 6. Every table that quotes body 1's `2/1/2` without its arm

`§220`, `§222`, `§223`, `§225` tables. The brief's own warning about `26/28/27` applies verbatim to
`2/1/2` and is nowhere recorded. Low load, trivially fixed by the same one-line rule as item 2.

### ★ 7. `§S1 CONTROL (must be clips = 0)`

Refuted on its first run (§223 §2, off-by-one, fifth occurrence) and **still printed unchanged in
every arm since**, at `706040/706040`. §223 explicitly said not to quote `iw40` as a pass, so nothing
downstream depends on it — but a permanently-violated criterion printed beside a result is a trap
with a fuse on it.
**Cheapest fix, zero new measurement:** the same printed line already carries `[q 14 428 403 ..
14 428 403]`. Restate the criterion as *"`iw34`'s pre-clamp quiet value must equal `14 428 403`"* —
that quantity moved in both §227 arms (`9 311 353`, `8 388 608`).

### ★ 8. `§41` as a `P_SHIFT` guard

Already corrected by §227 and by `BUILD-LANE-QUEUE` item 10's standing correction. Listed for
completeness; residual risk is the copies still in prose.

---

## 4. THE QUESTION THE BRIEF ASKS DIRECTLY

> **Was any of the 8 shipped gates (across 11 sections) certified by a control that could not have
> caught its failure mode?**

**YES — one, and it survives anyway.**

`UPD6383_LFOWRAP` (§224/§225, one of the 7 env gates whose `.h` initialiser is `true`) was certified
by an eleven-row battery of which **three rows — `W3`'s `§41`/`§54`/`§70`/`§211` limb, the whole
`W4′` family, and `K3` — could not have caught its failure mode** (§3 item 3). It is not at risk,
because `W0`, `W1` and `W2` are two-sided, sensitive and did move.

**No other shipped gate is in that position, on the evidence available:**

* `UPD6383_PSHIFT` / `UPD6383_NOCARRY` (§227) ship **OFF and inert**, certified by the diff-line
  control — **reproduced here as 4 diff lines, all four env-var banners, not one a measured value**.
* `UPD6383_DSCPRE` / `UPD6383_DSCRING` (§209) — 16 of 16 against a pre-registration committed before
  the build, with three counter-arms each matching its own signature. Sound.
* `UPD6383_ROTSIGN` / `UPD6383_BODYIX` (§200/§201/§202) — ⚠ **this gate's certification WAS found
  defective once**: §207 declared §202's "bit-exact" numbers the wrong block; §209 measured it and
  §210 recorded that §207 had **over-corrected** — §202's cells were right, one of two lines was
  attributed to the wrong body. Re-baselined on §209's 16-of-16. **Sound now, and the episode is the
  project's own precedent for this audit.**
* `UPD6383_CFMTIX` (§203/§204) — §203 recorded itself as *"INERT by the only instrument that could
  grade it. Not shipped"*, and §204 **built a new instrument** before shipping. Exemplary.
* `UPD6383_STPROBE` (§112/§213) — bookkeeping-only; ⚠ carries a known instrument defect
  (`store_probe()` truncates at 4 with no overflow counter), already filed.
* §223's ungated nop-guard narrowing — 29-line diff, no measured value moved, and the source
  **prints its own blind spot** (`(none -- UNTESTED in this vehicle)`; 82 of 103 words unmeasured).

---

## 5. ⚠ ERRORS FOUND IN THE DISPATCH BRIEF (the brief asked for these; that is a result)

| # | brief said | measured |
|---|---|---|
| **1** | *"**PEQ's** `+0.02149296` and its **0.198 dB** designer validation"* | ⛔ **`+0.02149296` is SINGLE DELAY's gain (algo 9), not PEQ's.** Two different programs and two different controls: SINGLE DELAY's three-factor product `−0.207331 × −0.207331 × 0.500000` (`single-delay-restored.md` §5.2) and PARAMETRIC EQ's `0.198 dB` biquad. They differ in class as well as in program — see C2 (SOUND for the carry) vs C3 (cannot be run) |
| **2** | *"`§41` … **1 172 160 of 1 172 160** presentations"* | ⚠ **numerator-as-denominator.** `§41` prints only the non-zero count; `§61` in the same log gives the denominator, **`1 203 840`**. The `31 680` shortfall is the ungated boot. The error originates in register §222 and `PREDICT_D0_producer.md`; `INSTRUMENT-AUDIT_findings.md` §8 and `RISK-TRIAGE_findings.md` already carry the correction |
| **3** | *"body 0's **`0/0/0`** shipped null"* | ⚠ **true only for the RULE-21 `D-I` split.** The RAW shipped null is **`2/4/1`** (pre-LFOWRAP) and **`2/9/4`** (current shipped default, arms K/M/N/P/Q). Quoting `0/0/0` without *"D-I"* invites the same confusion `W4` fell into |
| **4** | *"⚠ `26/28/27` belongs to the NOZ05 RIG only — never quote it for a non-rig arm"* | ✔ **correct, and understated.** The identical warning is needed for **`2/1/2`** (body 1): `D-I` `2/1/2` on the NOZ05 family, **`0/0/1`** on `src0b2_B_on_215` / `drpub_C_on_src0b2_217`, from the *same* raw `2/1/2`. No document records this |
| **5** | *"`§54`'s quiet-vs-loud peak comparison"* | ✔ exists, but ⚠ **`§54`'s population is not `§S1`'s.** `§54` arms at `m_frames_run > 300000` (`upd6383.cpp:5307`); `§S1`/`§S2`/`§70`/`§211`/`§104` arm at `S1_ARM_FRAME = S70_ARM_FRAME = 420000`. `§S1`'s header says *"bucket = `§54`'s `in_nz`"* — the **predicate** is shared, the **population** is not: `§54` counts `826 040` quiet frames where `§70` counts `706 040` (the loud count, `313 960`, is identical, so all 120 000 extra frames are quiet) |
| **6** | *"§227 (`1ed20e9`-adjacent)"* | ⚠ §227 is commit **`a2cbed3`**; `1ed20e9` is the next commit (the f98 cross-unit note). Cosmetic |

Everything else the brief asserted checks out, including the `§41` finding itself, the
`m_rf[0x8D] = 0x009B26 = 39 718 = 2 603 010 048 >> 16` arithmetic (verified from `§104` rows 60/61),
`w72`'s `L = 4 194 304`, the epilogue's `22/19/9`, `§S1 iw39`'s `1 991 044`, bit 26's `5 881 351`,
and **8 gates across 11 sections**.

---

## 6. THE CHEAPEST REPLACEMENTS — one line per weak control

Preferring quantities **already printed by an existing instrument**, so nothing new has to be built.

| control | replace with (already printed) |
|---|---|
| **A1 `§41`** as a scaling guard | **`m_rf[0x8D]`**, from the `§160` register dump in the same report. Keep `§41` for the level/host-payload question, which it does correctly |
| **A4 `§221 F3`** as independent corroboration | it is the same cell as `§41`. For a genuinely second datum use `§160`'s `86=178D0B` **or** `§E1b`'s counterfactual line, which reads a different array |
| **A5–A8 `§54`/`§70`/`§211`/rule-19** in the regression role | **`§S1 TOTALS`** (moved 6 ways in 12 arms) + **`§S2`'s `iw33` FS figure** + **`§176`'s D-RAM census**. All three are printed in the same report and all three are **upstream of the null**. Keep `§54`/`§70`/`§211` as the output-stage watch they are — but stop counting them as four checks |
| **A11 `§S1 CONTROL`** | change the criterion, not the instrument: *"`iw34` pre-clamp quiet must equal `14 428 403`"*, a number the same line already prints |
| **A15 `§S3` external control** | **`§176`'s `06:…/chg1100`** change-count, or `§104` row 19's `acc` — a different instrument on a different quantity |
| **B3 `W4′`** | body 0's **RAW** tally with its `FREE`/`UND` split — `rule21_all.py` prints all three in one line, and the raw column **did** move `2/4/1 → 2/9/4`. Or `§176` cell `0x10`'s range, which is what `W2` already used and which is the row that decided the gate |
| **B4 / B6** quoting a tally | never quote a `§104` tally without its arm **and** its `D-I` split: `python3 dsp/tools/rule21_all.py <log>` |
| **C1 `dsp/verify.py`** as a gate falsifier | keep it as a repo invariant; for a device change the equivalent is **D1**, the diff-line control. Do not count it as a falsifier row |
| **C3 / C4 SINGLE DELAY** | **strike the citation until `sd_rerun.py control` accepts the corrected configuration** (`ROADMAP-2026-07-29.md` item F already specifies the repair and its consequence). Live substitute for a coefficient-index change, already printed every run: **`§175 PER-SITE … coef <min>..<max>`** (per-site coefficient ranges) plus **`§S2`'s `iw30`/`iw32`/`iw33` term values** — both move when the multiply's coefficient index moves |
| **A2 `§41` level guard** | arm mask bit 5 once, in a throwaway arm, and record the fired count. Until then quote it as **UNTESTED**, not as clean |
| **A17 `§S3-C4`** | clear mask bit 23 once to show the count can be non-zero |
| **A19 `§44`** | either point it at a program that is known to fetch the tap table, or print it as *"0 — UNTESTED in this vehicle"* the way `§NG` and `§227 NOCARRY` already do |
| **D1 diff-lines** | fix the **unit**: state whether the count is one-sided or both-sided. `K1`'s *"7"* does not reproduce as either 6 or 12 |

---

## 7. WHAT THIS PASS IS BLIND TO

* **It grades sensitivity by what the archive happens to contain.** A control unmoved in 40 arms is
  not *proved* insensitive — it is **demonstrated never to have fired**. Where a structural argument
  is available (`§41` reads a register, not a product; `verify.py` cannot see `upd6383.cpp`;
  `§S3`'s control is the same predicate at the same hook; `W4′` is `0/0/0` while the send is shut)
  the classification is forced. Where it is not, the class is **UNTESTED**, not CANNOT-FAIL.
* **Common-mode arming.** `§S1`, `§S2`, `§70`, `§211`, `§104` and `§86` **all arm at frame 420 000**
  and `§54` at 300 000. Every control built on them shares one blindness to the boot window. Only
  `§S3` escapes it, by construction. This is a **single point of failure across most of the battery**
  and it is not recorded anywhere as such.
* **`§E1`/`§221`, `§S2`'s internal columns, `§209`'s ring census and the `§133` sweep** were graded
  from their published write-ups, not re-derived from the logs.
* **No audio claim is made or implied.** Nothing here was heard, rendered or measured at an output.

---

## 8. TEN-LINE SUMMARY

1. **38 controls enumerated**, from 52 graded falsifier rows (26 labels) ∪ 24 de-noised `§`-instruments cited in a control role ∪ 7 offline checks, across 6 live documents and 40 archived arms.
2. **21 SOUND · 9 MIS-AIMED · 5 CANNOT-FAIL · 3 UNTESTED.** The detector self-tested **24 of 24** (4 negative, 15 external) and caught one defect in its own code first.
3. **`§41` is not the only mis-aimed control, and not the worst.** Its level value is bit-identical in **31 of 31 modern arms**, including the arm that halves every product.
4. **The worst is SINGLE DELAY's `+0.02149296`** — cited live in four documents; rerun today its `control` leg **accepts the machine it was built to reject** and its `value` leg returns one outcome for all eight configurations.
5. **Four of the five CANNOT-FAIL controls are one criterion counted four times** — `§54`, `§70`, `§211` and the rule-19 line all read the output-stage null `§216` proved, so no upstream change can move them; the archive confirms it in 29 of 31 modern arms.
6. **`W4′` — the gate that shipped `UPD6383_LFOWRAP` — is a send-state detector, not an arithmetic one**: body-0 `D-I` is `0/0/0` on **20 of 20** send-shut modern arms regardless of the arithmetic.
7. **YES, one shipped gate was certified partly by controls that could not have caught its failure mode** — `UPD6383_LFOWRAP`, 3 of its 11 rows. **It survives**: `W0`, `W1` and `W2` are two-sided, sensitive and did move.
8. **The single most load-bearing conclusion at risk is §220's *"`28/32/28` is slot for slot IDENTICAL to the §215 `SRC0B2` calibration arm"*** — the raw-marker identity is exact (verified element for element) but the RULE-21 content is **26/28/27 vs 17/16/15** and body 1 **2/1/2 vs 0/0/1**. The send model **survives** on §225's independent re-grade of the rig; the cross-arm corroboration does not.
9. **Most urgent forward risk:** two of the three named falsifiers for the project's **next** build-lane experiment (`§41`, SINGLE DELAY) are inert; `§S3`'s ladder is carrying it alone.
10. **Six errors found in the dispatch brief**, chief among them that `+0.02149296` is **SINGLE DELAY's** gain, not PEQ's, and that `§41`'s *"1 172 160 of 1 172 160"* is a numerator quoted as its own denominator (`§61` gives **1 203 840**).
