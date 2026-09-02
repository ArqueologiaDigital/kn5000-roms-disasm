# Lane TIER2BYTE, 2026-09-02 — the `.byte` debt of the four "100.0 % source" images

`scripts/analysis/kn5000_source_coverage.py` reports **zero verbatim debt and
100.0 % source** for `v142/subcpu`, `subcpu/boot`, `custom_data` and
`hdae5000`. That instrument counts `.incbin` and cannot see a `.byte` run.
This lane measured what it could not.

## The three-way split

`scripts/analysis/tier2_byte_split_census.py --report`, at the tree state this
note was written against. **214,245 B** of the four images sit in
`.byte`/`.hword`/`.short`/`.word`/`.long` directives.

| image | `.byte`-family | (a) real code | (b) untyped structure | (c) genuine byte tables |
|---|---:|---:|---:|---:|
| v142 subcpu payload | 68,454 | 2,188 | 3,079 | 63,187 |
| subcpu boot (IC30) | 99,186 | 0 | 98,451 | 735 |
| custom data (IC19) | 21,360 | 0 | 15,828 | 5,532 |
| HD-AE5000 (IC4) | 25,245 | 9 | 6,824 | 18,412 |
| **total** | **214,245** | **2,197** | **124,182** | **87,866** |

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
| FP(a) — CODE test on proven `.ascii`/`.asciz` text | 1,051 literals, 21,357 B | **0.10 %** |
| FP(a2) — CODE test on hand-annotated jump tables | 2 tables, 144 B | **0/2** |
| FP(a3) — CODE test on the PNG-derived bitmap assets | 1,899 windows, 313,076 B | **0.00 %** |
| FP(b) — STRUCTURE test on proven called code | 5,928 regions, 196,957 B | **0.39 %** |
| TP(a) — CODE test on proven code (floor: ENTRY only) | same 5,928 | 88.5 % |
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

**100,605 B**, all byte-exact, each rebuilt from a removed prerequisite so no
compare certifies a stale object.

* **subcpu boot, 98,304 B.** The erased 96 KiB at 0xFE0000-0xFF7FFF was 98,304
  lines of `.byte 0xff`, 97 % of the file. Now one `.fill`. Negative control:
  changing the fill value to 0xfe makes the compare fail at byte 1.
  `subcpu/boot/tools/convert_erased_fill.py`
* **v142, 2,154 B** across nine runs, including both halves of
  `DSP_Bytecode_Programs`, which the source itself calls "CODE, not data — six
  opcode handlers". Framed by unidasm, spelled by llvm-mc where it decodes and
  by a spelling search where it does not, then re-encoded and compared byte for
  byte. `v142/subcpu/tools/convert_arm_blocks.py`,
  `v142/subcpu/tools/convert_code_byte_runs.py`

### The framing evidence, which the gate cannot give

The four arm blocks carry **33 interior arm labels and comments**, placed by
hand long before this lane, and every one lands on an instruction boundary of
the decode. A control over the known-data runs of `subcpu_data_tables.s` shows
the check discriminates: of three decodable runs with interior labels, **two
had a label off-boundary**.

### ⚠ "The toolchain blocks this" was wrong before it was written

Five byte sequences `llvm-mc --disassemble` refuses all **assemble** perfectly
once you find the spelling this tree already uses — `cp (xwa), 0` is
`80 3f 00`, `or_sriw_rm hl, 7, 240, 232` is `d3 07 f0 e8 e3`. Only the decoder
lacks them. `v142/subcpu/tools/spell_search.py` is the one-line check that has
to happen before any refusal blames the toolchain. Measured against llvm-mc
`6f456a19f05b`; the installed build moved from `6fe210fb0a81` mid-push, and
decodability is a property of a specific build.

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
* **The (c) bucket, 87,866 B** — genuine byte tables. Retyping them would be
  churn, not coverage.

## Reproduce

```
python3 scripts/analysis/tier2_byte_split_census.py --selftest
python3 scripts/analysis/tier2_byte_split_census.py --report
python3 scripts/analysis/tier2_byte_split_census.py --control
python3 custom_data/tools/customdata_falsification.py
```
