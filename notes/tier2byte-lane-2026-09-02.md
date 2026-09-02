# Lane TIER2BYTE, 2026-09-02 — the `.byte` debt of the four "100.0 % source" images

`scripts/analysis/kn5000_source_coverage.py` reports **zero verbatim debt and
100.0 % source** for `v142/subcpu`, `subcpu/boot`, `custom_data` and
`hdae5000`. That instrument counts `.incbin` and cannot see a `.byte` run.
This lane measured what it could not.

## The three-way split — BEFORE

`scripts/analysis/tier2_byte_split_census.py --report`, measured at
`98e55da6`. **214,245 B** of the four images sat in
`.byte`/`.hword`/`.short`/`.word`/`.long` directives.

| image | `.byte`-family | (a) real code | (b) untyped structure | (c) genuine byte tables |
|---|---:|---:|---:|---:|
| v142 subcpu payload | 68,454 | 2,188 | 3,079 | 63,187 |
| subcpu boot (IC30) | 99,186 | 0 | 98,451 | 735 |
| custom data (IC19) | 21,360 | 0 | 15,828 | 5,532 |
| HD-AE5000 (IC4) | 25,245 | 9 | 6,824 | 18,412 |
| **total** | **214,245** | **2,197** | **124,182** | **87,866** |

## AFTER, at `65d29f69`, gate green 13/13

| image | `.byte`-family | (a) real code | (b) untyped structure | (c) genuine byte tables |
|---|---:|---:|---:|---:|
| v142 subcpu payload | 66,300 | 34 | 3,079 | 63,187 |
| subcpu boot (IC30) | 882 | 0 | 147 | 735 |
| custom data (IC19) | 21,360 | 0 | 15,828 | 5,532 |
| HD-AE5000 (IC4) | 26,705 | 0 | 6,824 | 19,881 |
| **total** | **115,247** | **34** | **25,878** | **89,335** |

⚠ **The `.byte` population is not a burn-down and the HD-AE5000 row goes UP.**
100,458 B left the `.byte` population by becoming instructions or a `.fill`,
and 1,460 B *entered* it by ceasing to be mnemonics it never should have been.
Retyping data-as-code as `.byte` is progress that makes the headline number
worse; a lane measured on "`.byte` bytes removed" would be paid to leave those
1,460 B misframed.

Addresses come from the pinned assembler, never a parser: every source line
gets a zero-size probe label, the image is rebuilt, the build is asserted
byte-identical to the dump, and `llvm-nm` supplies the map. The tool aborts
rather than print a number from an unverified build.

## The classifier's controls

The byte gate cannot adjudicate any classification here — every one of them
re-assembles to the same bytes. So the error rate is the only quality signal.
`--control`:

| control | population | rate |
|---|---|---|
| FP(a) — CODE test on proven `.ascii`/`.asciz` text | 1,051 literals, 21,357 B | **0.00 %** (0.10 % before) |
| FP(a2) — CODE test on hand-annotated jump tables | 2 tables, 144 B | **0/2** |
| FP(a3) — CODE test on the PNG-derived bitmap assets | 3,531 windows, 313,061 B | **0.00 %** |
| FP(b) — STRUCTURE test on proven called code | 5,931 regions, 197,056 B | **0.39 %** |
| TP(a) — CODE test on proven code (floor: ENTRY only) | same 5,931 | 88.5 % |
| TP(b) — STRUCTURE test on proven data | 515 literals | 100 % |

The two positive controls exist because a detector that never fires has a
perfect false-positive rate.

### How the classifier could be wrong — five named failure modes

1. **(a) fires on data.** Dense 8-bit data decodes into plausible programs.
   Measured by FP(a)/FP(a2)/FP(a3).
2. **(b) fires on code.** Real code is periodic and full of printable bytes
   and real addresses. Measured by FP(b).
3. **The population is wrong.** Aborts if the probe build is not
   byte-identical.
4. **ENTRY inherits unidasm's blind spots.** A call it cannot decode is a
   missed entry, so (a) is a lower bound by that defect. Stated, not corrected.
5. **Erased flash decodes and fills.** 0xFF is a legal `swi 7`. Handled
   structurally by carving fills out before anything is judged, plus a
   dominant-mnemonic cap as a second net.

### Five defects the controls actually caught

Each moved a real number, and none would have turned the byte gate red.

* `unidasm` prints **five-digit** addresses for the v1.42 payload (base
  0x400); the line regex demanded six. Every v142 decode silently failed.
* A **label sharing a line with a directive** (795 such lines here) was read as
  an instruction — which is how 1,973 B of the documented 12 × 6-byte
  `DSP_AlgoChannel_SelectorRecords` came out as "real code".
* **FALLOUT alone** was accepted as reachability, and `jp (xiy)` was not a flow
  terminator. Between them, two already-typed PPORT jump tables were classified
  as code — the exact trap the lane brief names.
* **PTRTAB** fired on any four in-range words anywhere in a run, calling
  6,367 B a pointer table on the strength of 16 bytes.
* The address-map **cache was keyed on the image tag**, so it served a
  pre-conversion map to a converter after a source had been rewritten.

## What was converted

**101,918 B touched**, all byte-exact, each image rebuilt from a removed
prerequisite so no compare certifies a stale object. `make all && make
gate-all` is green: **13/13 byte-identical**, 9 KN5000 + 4 WSA1R.

* **subcpu boot, 98,304 B.** The erased 96 KiB at 0xFE0000-0xFF7FFF was 98,304
  lines of `.byte 0xff`, 97 % of the file. Now one `.fill`. Negative control:
  changing the fill value to 0xfe makes the compare fail at byte 1.
  `subcpu/boot/tools/convert_erased_fill.py`
* **HD-AE5000, 1,460 B** of data-as-code across twelve never-called regions —
  see the census section below.
* **v142, 2,154 B** across nine runs, including both halves of
  `DSP_Bytecode_Programs`, which the source itself calls "CODE, not data — six
  opcode handlers". Framed by unidasm, spelled by llvm-mc where it decodes and
  by a spelling search where it does not, then re-encoded and compared byte for
  byte. `v142/subcpu/tools/convert_arm_blocks.py`,
  `v142/subcpu/tools/convert_code_byte_runs.py`

### The framing evidence, which the gate cannot give

The four arm blocks carry interior arm labels and comments placed by hand long
before this lane, and every one lands on an instruction boundary of the decode:
**12/12 counted by unique address**, and **10/10 informative in-block branch
targets** land on a boundary too, at ~2.8× the boundary density. A control over
the known-data `.byte` runs of `subcpu_data_tables.s` shows the check
discriminates: of the **9 runs that decode end to end, 6 have a mark
off-boundary**.

⚠ An earlier version of this note and of the converter's commit message said
"33 interior labels", counting source LINES (a label, its comment and a blank
at the same address counted three times). The reproducible figure is 12 unique
addresses; the committed script is
`v142/subcpu/tools/arm_block_evidence.py`. The same script also corrects the
control, first quoted from a scratch one-liner as "2 of 3".

    python3 v142/subcpu/tools/arm_block_evidence.py

### ⚠ "The toolchain blocks this" was wrong before it was written

Five byte sequences `llvm-mc --disassemble` refuses all **assemble** perfectly
once you find the spelling this tree already uses — `cp (xwa), 0` is
`80 3f 00`, `or_sriw_rm hl, 7, 240, 232` is `d3 07 f0 e8 e3`. Only the decoder
lacks them. `v142/subcpu/tools/spell_search.py` is the one-line check that has
to happen before any refusal blames the toolchain. Measured against llvm-mc
`6f456a19f05b`; the installed build moved from `6fe210fb0a81` mid-push, and
decodability is a property of a specific build.

## HD-AE5000: the data-as-code census, finished

`hdae5000/tools/data_as_code_census.py`. DEBT-INVENTORY records this image's
census as **PARTIAL**, with two instances found and converted (the 309 B
version string and the 6,356 B `HDAE5000_RECORD_TABLE`).

**The instrument is "who reads it", not a byte statistic.** RECORD_TABLE was
settled by one argument — every reference LOADS its address, nothing calls or
jumps into it — which depends on no decoder, no threshold and no framing
judgement. ⚠ The **blind-start enrichment was offered for this job and is not
used**: it was retracted on 2026-09-02 (a shuffle of the same bytes scored 82.1 %
against the real 82.8 %, and the ratio is structurally confounded).

**Findings: 12 regions, 1,460 B, all converted.** Every one is a labelled
region that nothing branches into and whose source already writes 70–100 % of
its bytes as data directives: `Display_Params`, `Panel_Save_UI`,
`Multilingual_Messages`, `UI_Page_Titles`, `Credits`, `Dir_Strings`,
`Demo_Data`, `Char_Tables`, `Config_Strings`, `UI_Descriptors`,
`Test_Strings`, `Path_Strings`. Every name says data.

`HDAE5000_Char_Tables` (0x2E2E76, 1,561 B) is the clearest case: the file
header calls it "Character set tables", it holds 4-byte-stride records and the
ASCII `"FLS NAME "`, 70 % was already `.byte`, and the other 470 B read as
`setm 0, (xwa-72)` / `cps de, 2` over an ascending byte ramp.

### ⚠ The census's first answer was ZERO, and the granularity was why

Twice.

1. Merging maximal runs of instruction lines gave **15 regions for the whole
   image, one of them 50 KB** — and something in a 50 KB span is always called,
   so a data island inside one is invisible.
2. Splitting label-to-label *or at the first data directive* chopped a misframe
   — mnemonics, a short `.byte` the decoder refused, more mnemonics — into
   dozens of sub-24-byte fragments every test then declined to examine.
   **Interleaving is the signature of the defect, not a reason to stop
   looking.** `Char_Tables` fell straight through that gap.

### ⚠ And the content test could not see either calibration case

`--selftest` exists because of this. A first version asked `struct_signal`
about each region as one span and returned **None for both known instances**:
the version string is text plus alignment padding, and RECORD_TABLE is 312 B of
records, 5,832 B of zeros and 212 B of strings, so no single signal owns either
span. Segmenting first puts them at **92 %** and **71 %**. A detector that
cannot fire on the cases it generalises measures nothing.

The content test is still reported, and still cannot decide a MIXED region — it
scores `Char_Tables` at 5 %. The rule that decided the twelve is *never called*
plus *≥ 30 % already-data interleave*, whose null against this image's own
proven-called regions is **1/314 = 0.32 %**.

### Bounds, stated not hidden

* `call (xhl)` resolves to nothing statically, so "never called" is
  over-inclusive on its own — which is why a second signal is required.
* 1,374 regions under 24 B (14,316 B) are too short for any test here.
* A data region of dense, non-structured, non-interleaved bytes would still be
  missed.

## custom_data (IC19): a pure data ROM — claim SURVIVED falsification

`custom_data/tools/customdata_falsification.py`, 9 checks, 0 failed. Method
ported from `wsa1/notes/prom_cd_falsification_2026_09_02.py`.

* **Q1** IC19 IS CPU-fetchable — `kn5000.cpp:152` maps 0x300000-0x3FFFFF as
  CPU-readable ROM. So "no code" is not true by construction.
* **Q2** 13 control transfers into the window exist in v10 and v9 sources
  (`jp 0x3540f1`, `jp 0x379bf1`, `jp 0x37c9f1`) — and **all 13 sit inside
  `.byte`-adjacent misframes** in `sequencer/accompaniment_engine.s`. Zero come
  from a clean code context. ⚠ This is a finding about **v10/v9**, not IC19,
  and is left for the lane that owns those files.
* **Q3** 206 references across the three images, every one an address **load**.
  That is the signature that settled `HDAE5000_RECORD_TABLE`, and it needs no
  statistic.
* **Q4** llvm-mc turns 0 statements of custom_data's source into instructions;
  the same instrument returns 36,391 for hdae5000's.
* **Q5** Branch-target coherence normalised by boundary density, calibrated on
  ground truth from HD-AE5000: **proven-code windows 3.05–3.61, proven-data
  windows 0.49–2.97, no overlap.** IC19's 54 scorable windows: min 0.62,
  median 0.91, **max 1.11** — nothing within reach of the 3.05 code floor. Of
  the 74 unscorable windows, 43 are ≥ 90 % a single byte value.
* **Q5b THE SPIKE.** ⚠ The first spike scored **0.66** and the failure was the
  instrument's, not the ROM's: 8 KiB taken from an arbitrary v10 offset was v10
  DATA. Spliced from windows independently proven to be code, the same spike
  scores **3.39–3.61 inside IC19's address space**. The test can see what it
  reports the absence of.

## What was refused, and why

* **v142 0x01FEDF (8 B)** — contains `c7 fd 01`, which unidasm calls invalid
  too. Nothing frames it; it stays `.byte`.
* **v142 0x03CB8E (26 B)** — decodes to 9 instructions that re-encode to 24 B.
  The shorter-re-encode trap already on record in DEBT-INVENTORY.
* **subcpu boot's three small uniform runs** (95 B of 0x02, 32 B of 0x01, 20 B
  of 0x00, at 0xFF812A-0xFF828F) — they are fields of named velocity-curve
  tables inside the documented eight-object boot data region, not padding.
  Collapsing them would fragment objects the source already explains.
* **The (c) bucket, 89,335 B** — genuine byte tables. Retyping them would be
  churn, not coverage.

## Reproduce

```
python3 scripts/analysis/tier2_byte_split_census.py --selftest
python3 scripts/analysis/tier2_byte_split_census.py --report
python3 scripts/analysis/tier2_byte_split_census.py --control
python3 custom_data/tools/customdata_falsification.py
```
