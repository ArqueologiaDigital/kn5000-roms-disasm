# gen_ledger_ext — repo-EXTERNAL graded verdicts vs `dsp/analysis/`

swept `/home/fsanches/compartilhado/kn7000_mame/notes`: **213** notes, **209** verdict-bearing sections. indexed **111** files under `dsp/analysis/`.
presence test: >= 3 tokens that are rare corpus-wide (document frequency <= 4) AND absent from the rest of their own note, co-occurring in ONE analysis file.

⚠ **`BOOKKEEPING-REPAIR_findings.md` is EXCLUDED from the index by design** — it quotes the missing verdicts in order to DRAFT them, and a report about the gap must not close the gap on paper. The gap closes when TIER 0b carries the rows -- §228 filed eleven (rows 31-41). Self-tests **T1/T1c** are the two-sided control for this exclusion.

⚠ **GRADE:** the KN7000 cross-model case was **MEASURED** absent (hand-confirmed: `0.5614`, `0.618`, `0.876`, `0.2435` returned zero hits under `dsp/analysis/`) and is now **FILED** as TIER 0b row 31 -- which is why T1 asserts PRESENT, and why the negative side had to become SYNTHETIC (T1c): a control that IS the open defect is invalidated by its own repair (rule 20). The aggregate count is **INFERRED** -- the threshold is calibrated on two controls, so read it as a LOWER-BOUND WORK QUEUE, not a statistic.

## 0. RULE 20 — the self-test, printed BEFORE the count

| check | result | what it read | what it demanded |
|---|---|---|---|
| T1  the KN7000 cross-model NEGATIVE is reported PRESENT — §228 FILED it as TIER 0b row 31 (was "must be ABSENT" until 2026-07-31) | PASS | `best analysis file=LEDGER.md with 8 shared tokens` | not None -- the filing must be visible to the detector |
| T2  ...and its fingerprint is not empty (an empty one would fake either verdict) | PASS | `21 discriminating tokens: ['0.050', '0.111', '0.125', '0.243', '0.2435', '0.5614']` | >= 5 |
| T1c ⚠ THE NEGATIVE SIDE: a SYNTHETIC fingerprint present in no file is reported ABSENT (so PRESENT cannot mean "matches anything") | PASS | `best=None (0 shared)` | None |
| T1b ...and the verdict is ALSO visible with the drafts counted (consistency of the two index builds) | PASS | `best=LEDGER.md (8 shared)` | not None |
| T3  a verdict the analysis tree DOES carry is reported PRESENT (dsp-register-space-applied.md <-> analysis/register-space.md) | PASS | `best=register-space.md (6 shared)` | not None |
| T4  the detector says PRESENT for a non-trivial share of the corpus | PASS | `23 of 209 records PRESENT` | >0 |
| T5  the analysis index actually loaded | PASS | `111 analysis files indexed` | >50 |
| T6  the notes sweep actually loaded | PASS | `209 verdict records` | >30 |

**8 of 8 self-tests PASS.**

## 1. ★ THE COUNT — and the count IS the finding

| population | total | represented in `dsp/analysis/` | **ABSENT** |
|---|--:|--:|--:|
| all verdict sections | 209 | 23 | **186** |
| DSP-relevant only | 134 | 23 | **111** |

⇒ **111 DSP-relevant graded verdicts live only in `kn7000_mame/notes/` and have no representation in the analysis tree.** `gen_ledger.py` reads neither, so none of them can ever reach TIER 0b. The KN7000 cross-model NEGATIVE is one of them; §228 filed it and the count fell by one, which is what progress looks like here.

## 2. THE ABSENT DSP VERDICTS (draft TIER 0b rows)

| # | note | § heading | the verdict, as the note states it |
|--:|---|---|---|
| 1 | `audit/kn5000-audit-output.md` | 0. TL;DR | gains") is **FALSIFIED**. |
| 2 | `audit/kn5000-audit-output.md` | 4. AUDITED AND FOUND CORRECT | `gain_R = reg[21]>>8`) are **FALSIFIED** — `reg[20]` and `reg[21]` are *envelope stage 0 |
| 3 | `audit/kn5000-output-design.md` | 1. (a) STEREO — the pan path, decoded end to end | ("Pan Left / Pan Right, 0x00=silent, 0x3C=center, 0x78=full") is **FALSIFIED** — the measured |
| 4 | `audit/kn5000-output-design.md` | 1.6 Why `+0x840`/`+0x880` are NOT the L/R gains — and what e | ("Pan Left / Pan Right, 0x00=silent, 0x3C=center, 0x78=full") is **FALSIFIED** — the measured |
| 5 | `audit/kn5000-output-design.md` | 2. (b) EFFECT SENDS — VERDICT: **there are none; ignoring th | 2. (b) EFFECT SENDS — VERDICT: **there are none; ignoring them is correct |
| 6 | `audit/kn5000-output-design.md` | 4. Corrections this pass makes to existing notes/docs | \| `kn5000-docs/tone-generator.md:107-108,135-136,481-482` \| `+0x840`/`+0x880` = "Pan Left/Right, 0=silent, 0x3C=center, 0x78=full" \| **FALSIFIED** (§1 |
| 7 | `dsp-allpass-rerun-applied.md` | (preamble) | INFERRED** / **EDUCATED GUESS** / **FALSIFIED** / **OPEN**. |
| 8 | `dsp-alu-crossval.md` | 7. The acceptance test — what is actually runnable | `H_in·H_out`. (K5 also FALSIFIED the old reading that disconnect *attenuates*: a |
| 9 | `dsp-alu-structure.md` | Is `L` really two fields, `[4:3]` + `[2:0]`?  TESTED, NOT SU | Is `L` really two fields, `[4:3]` + `[2:0]`? TESTED, NOT SUPPORTED |
| 10 | `dsp-alu-structure.md` | 10. Alternatives tested and REJECTED | FORCED read `2D4` and write `655` both agree. **FALSIFIED** by SINGLE DELAY: |
| 11 | `dsp-audiopath-wired.md` | (preamble) | \| `envelope / level detector` (`hi12 == 0xC40`) \| **FALSIFIED at all 61 sites** \| a 13-bit C-format **immediate load** (`analysis/k5-output-stage.md`  |
| 12 | `dsp-audiopath-wiring.md` | 6. WHAT THIS NOTE CHANGES IN THE EXISTING WRITE-UPS | \| `dsp-critical-path-coverage.md` §B3 \| "the chip has three serial input ports and **this board uses one stereo pair**" \| **FALSIFIED.** All three DI  |
| 13 | `dsp-closure-applied.md` | (preamble) | FALSIFIED** / **OPEN**. |
| 14 | `dsp-frame-advance.md` | 0. Result in one page | \| **E** \| ★ **FRAME CLOSURE BECAME A REAL MEASUREMENT AND IMMEDIATELY FAILED.** ⚠ **The label on the criterion is RETRACTED (2026-07-26, `analysis/ret |
| 15 | `dsp-k6-input-stage-applied.md` | (preamble) | \| `envelope / level detector` (`hi12 == 0xC40`) \| **FALSIFIED at all 61 sites** \| a 13-bit C-format **immediate load** (`analysis/k5-output-stage.md`  |
| 16 | `dsp-k6-input-stage.md` | 0. Executive summary | \| 2 \| **The block split is 0..6 / 7..11, not 0..5 / 6..11.** Three independent lines agree. The brief's proposed 6+6 split is **FALSIFIED**. \| **MEASU |
| 17 | `dsp-k6-input-stage.md` | 9. By-products and corrections | \| "two parallel six-word blocks, iw 0..5 and iw 6..11" \| the K6 brief \| **FALSIFIED** (§2). The blocks are 0..6 and 7..11 \| |
| 18 | `dsp-k6-input-stage.md` | 9.3 Corrections to earlier notes | \| "two parallel six-word blocks, iw 0..5 and iw 6..11" \| the K6 brief \| **FALSIFIED** (§2). The blocks are 0..6 and 7..11 \| |
| 19 | `dsp-mirror-sync.md` | 0. Result in one page | \| **B** \| ★ **THREE MORE FALSIFIED LABELS WERE FIRING ON LIVE I-RAM**, not just on the ROM corpus. The four host-written call-vector words were labell |
| 20 | `dsp-next-steps-roadmap.md` | 1. ADJUDICATIONS — the contradictions between A, B and C | 1.3 "the two patched words are written by firmware that computes a level from a UI parameter" (B §8) → **FALSIFIED |
| 21 | `dsp-next-steps-roadmap.md` | 1.3 "the two patched words are written by firmware that comp | 1.3 "the two patched words are written by firmware that computes a level from a UI parameter" (B §8) → **FALSIFIED |
| 22 | `dsp-next-steps-roadmap.md` | 1.4 "`hi12`/`class4`/`addr8` track the effect selection" (C  | 1.4 "`hi12`/`class4`/`addr8` track the effect selection" (C §B4) → **FALSIFIED; it is a reload bracket |
| 23 | `dsp-next-steps-roadmap.md` | REVERB | operations, the operand is `lo12`, and the "bracket" reading is FALSIFIED as a bracket (§1.6) though |
| 24 | `dsp-next-steps-roadmap.md` | R3 — the `880.1.**` delay-DRAM words — 36 of every frame (13 | operations, the operand is `lo12`, and the "bracket" reading is FALSIFIED as a bracket (§1.6) though |
| 25 | `dsp-next-steps-roadmap.md` | (preamble) | SPECULATIVE** or **FALSIFIED**. §1 adjudicates the contradictions between A, B and C by going |
| 26 | `dsp-perframe-execution.md` | Headline | imbalance; the "bracket" reading is FALSIFIED as a bracket.** (§6.3) |
| 27 | `dsp-perframe-execution.md` | 6.3 CORRECTION — the delay-DRAM "bracket" does not bracket | program-dependent. **The pair reading is FALSIFIED as a bracket.** What survives is that |
| 28 | `dsp-perframe-execution.md` | (preamble) | \| `envelope / level detector` (`hi12 == 0xC40`) \| **FALSIFIED at all 61 sites** \| a 13-bit C-format **immediate load** (`analysis/k5-output-stage.md`  |
| 29 | `dsp-schroeder-applied.md` | 1.1 The three conflicts, and how each was settled by re-deri | \| **`ACTION 0x19`** \| `tB ← bus` FORCED (strict); `tA ← acc` + a bus route FORCED (joint) ⇒ the strict vocabulary is FALSIFIED \| `tempA ← bus`, FORCED |
| 30 | `dsp-schroeder-applied.md` | (preamble) | INFERRED** / **EDUCATED GUESS** / **FALSIFIED** / **OPEN**. |
| 31 | `dsp-unit-roles-live-capture.md` | ★ HEADLINE: the fixed-function unit map (LIVE FACT now, thre | REFUTED**, and with it the bank↔serial-line 1:1 hypothesis. The three TG |
| 32 | `kn5000-dsp-INDEX.md` | BACKLOG — open investigations | DONE + FALSIFIED (`-origin-capture.md`): the EQ was selected in MAME and the uC-IF stream |
| 33 | `kn5000-dsp-INDEX.md` | DSP, near-term | DONE + FALSIFIED (`-origin-capture.md`): the EQ was selected in MAME and the uC-IF stream |
| 34 | `kn5000-dsp-avsdrv-unpack.md` | 4. ★ THE 19 MICROPROGRAMS — and the word size | 4.4 Cross-corpus comparison with the KN5000 — NEGATIVE, and why |
| 35 | `kn5000-dsp-avsdrv-unpack.md` | 4.4 Cross-corpus comparison with the KN5000 — NEGATIVE, and  | 4.4 Cross-corpus comparison with the KN5000 — NEGATIVE, and why |
| 36 | `kn5000-dsp-axes.md` | Headline | 2. **★★★ R1 IS FALSIFIED, R2 IS CONFIRMED, AND THE HOST MAP AGREES.** The chorus note |
| 37 | `kn5000-dsp-axes.md` | 2. THE PHASER, AND THE SECOND OPERAND ROUTE | R1 FALSIFIED. R2 CONFIRMED** — and confirmed by measurement (§2.2), not merely left |
| 38 | `kn5000-dsp-axes.md` | 2.3 The host-map test: R1 is dead (**MEASURED**) | R1 FALSIFIED. R2 CONFIRMED** — and confirmed by measurement (§2.2), not merely left |
| 39 | `kn5000-dsp-axes.md` | 4.4 ★ THE DECISIVE TEST: is the information additive? (**MEA | VERDICT (MEASURED): M2 is FALSIFIED and M4 does not follow.** Over this corpus the |
| 40 | `kn5000-dsp-axes.md` | 7. Corrections and additions to earlier notes | \| R1 vs R2 for the phaser's coefficient source — open \| `-chorus.md` §5.2, §8, §9 item 3 \| **CLOSED. R1 FALSIFIED** (host writes none of `0x45..0x58`, |
| … | *(71 more; run with `--all`)* | | |

