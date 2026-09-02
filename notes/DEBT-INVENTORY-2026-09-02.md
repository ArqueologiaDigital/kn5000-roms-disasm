# What is actually left to disassemble — consolidated, 2026-09-02

Result of an eleven-lane parallel push across all 13 gated images. **The byte
gate is green: 13/13 byte-identical, 8/8 KN5000 images assembling with the
pinned toolchain**, re-run centrally on `main` after every merge.

## ⚠ Read this before quoting any number below

**There are TWO kinds of debt and they are counted by different instruments.**
Quoting one as the total is the mistake this whole push exists to correct.

| kind | what it is | counted by |
|---|---|---|
| **verbatim** | bytes handed back through `.incbin` of a blob with no generating source | `scripts/analysis/kn5000_source_coverage.py` |
| **code-as-`.byte`** | real instructions spelled as data directives | per-image census tools; **NOT in the column above** |
| **data-as-code** ★ | data disassembled into plausible instruction mnemonics | ⚠ **NOTHING COUNTS THIS** |

★ **The third kind was identified on 2026-09-02 and no instrument measures it.**
It is invisible by construction: a `.byte`/`.incbin` scanner sees mnemonics and
moves on, and the byte gate cannot object because re-assembling a wrong
interpretation reproduces the same bytes. Two confirmed instances, both in
HD-AE5000: the 309-byte version string (*"Technics Software section
M. Kitajima"*) disassembled as ~35 garbage instructions, and
**`HDAE5000_RECORD_TABLE` at 0x29C0AA — 6,356 bytes written as ~6,150 lines of
instruction mnemonics**, whose only references load it as an ADDRESS, with zero
call or jump sites anywhere in the tree. A smaller instance exists in
`HDAE5000_Lang_Codes`. ★ **FIRST MEASURED 2026-09-02, on v10: 7,128 B across 264 spans**
(`scripts/analysis/v10_data_as_code_census.py`, tight rule, 0.3–2.3%
false-positive against its own control). ⚠ Do NOT quote the raw
"375,743 B unreached" figure that census also prints — its own null shows a
17.3% seed-coverage gap, so the raw number is dominated by REAL code reached
through dispatch mechanisms static analysis cannot follow. ★ **ALL THIRTEEN IMAGES ARE NOW MEASURED** (2026-09-02). Detectors:
`scripts/analysis/v10_data_as_code_census.py`, `wsa1/notes/data_as_code_audit.py`,
`scripts/analysis/kn5000_rest_data_as_code_audit.py`. Null across them: 0.3–2.3%.

| image | verdict |
|---|---|
| subcpu boot, table_data, custom_data | **CLEAN — caveat lifted** |
| prom_a, prom_b, prom_c, prom_d | **CLEAN — caveat lifted** |
| v10 | measured; 196 spans / 5,633 B converted |
| HD-AE5000 | measured, partial; RECORD_TABLE (6,356 B) converted |
| **v9, v7, v142** | ⚠ **caveat NOT lifted** |

⚠ **WHY THE CAVEAT SURVIVES FOR v9, v7 AND v142.** Their seed-coverage gaps are
**51–74%** — that fraction of proven code is not reachable from address-taken
seeds, because it is reached through indirect or computed dispatch that static
analysis cannot follow. So their LOW buckets (751 KB for v9, 365 KB for v7) are
**dominated by real code and must not be quoted as debt**, exactly as v10's raw
375,743 B figure must not be. Their HIGH-confidence findings are small and
usable: v9 7,796 B / 141 spans, v7 1,702 B / 44, v142 0.

⚠ **A MEASUREMENT BUG WORTH REMEMBERING**: `.org` is SECTION-RELATIVE, and
treating it as absolute-minus-base silently no-ops it. That undercounted v7 by
55,570 B, subcpu boot by 28,259 B, table_data by 56,868 B and v142 by 1,024 B
before it was caught.

A `.byte` run is exactly as un-decoded as an `.incbin`, and it passes every
"no `.incbin`" test. This project has now shipped that false claim twice.

## ⚠ THE HEADLINE, NOW THAT EVERY IMAGE HAS BEEN MEASURED

**Code-as-`.byte` is the dominant debt in this tree, not verbatim blobs.**
v7 alone holds 275,822 B of it — more than the 225,670 B of real verbatim debt
across all thirteen images put together. Every "95%+ source" figure ever quoted
here came from an instrument that could not see it.

## Verbatim debt: 501,506 B counted, ⚠ only 183,038 B is real

**Figures refreshed 2026-09-02 from a live `kn5000_source_coverage.py` run — do
not quote this file without re-running it, it drifts within hours while lanes
convert.**

The tool reports 501,506 B of 12,386,304 (96.0% source). **318,468 B of that is
the six table_data BMPs, which are the genuine shipped artefact in their best
form — see below. Subtracting them leaves 183,038 B, i.e. 98.5% source.**
Quote 183,038; the headline counts a correctly-represented asset as debt
because the tool classifies by MECHANISM (`.incbin` with no generator) rather
than by whether anything is actually unknown.

### Priority images (owner's standing order: v10 and the WSA1R first)

| image | verbatim | code-as-`.byte` |
|---|---:|---|
| **KN5000 v10** | **0** ✅ | ~22,785 B, confirmed-region backlog CLOSED |
| **wsa1/prom_c** | **0** ✅ | 0 — survived falsification |
| **wsa1/prom_d** | **0** ✅ | 0 — survived falsification |
| wsa1/prom_a | 15,722 B | none (audited clean) |
| wsa1/prom_b | 26,013 B | none (audited clean) |

Deprioritised: v7 (123,733 B verbatim, 275,822 B code-as-`.byte`), v9.

    python3 scripts/analysis/kn5000_source_coverage.py

Zero verbatim debt: subcpu v142, subcpu boot, custom data, HD-AE5000,
wsa1/prom_c, wsa1/prom_d. Remaining, in order:

* **table data 336,038 B — and ⚠ 318,468 B of it IS NOT DEBT AT ALL.**
  ★ CORRECTED 2026-09-02. Those 318,468 B are six **genuine, uncompressed 8bpp
  Windows BMPs** — `BM` magic, 40-byte DIB header, compression 0, 256-colour
  palette at the declared offset, header size field matching the file, verified
  per file by `scripts/analysis/verbatim_bmp_header_audit.py`. They are directly
  viewable in any image tool, and the `.incbin` reads that exact committed file.
  There is no raw blob to bridge back to, so **a round-trip generator would add
  machinery for zero viewability gain** and would discard the genuine artefact as
  shipped by Technics's own toolchain. This entry previously said "the fix is a
  round-trip generator"; that was wrong, and `docs/COMPLETENESS-STATUS.md` had
  already said so. The remaining 17,570 B is a documented stale remnant.
  **Real verbatim debt is therefore 225,670 B, not 544,138 B**, and v7 — not
  table_data — is the largest genuine block in the tree.
* **v7 123,927 B** — 272 live `romslices/*.bin` transplants plus 2 raw patches,
  itemised by `scripts/analysis/v7_no_source_bytes.py`. The mechanical
  pointer-table technique is EXHAUSTED (0 candidates remain).
* **wsa1/prom_a 41,761 B**, **wsa1/prom_b 32,556 B** — per-span forensic work.

## Code-as-`.byte`: the part the column above cannot see

Measured this push, per image where a census exists:

* **v9 and v10: confirmed-region backlog CLOSED — 0 B.** ★ Corrected
  2026-09-02; this entry previously said 8,058 B each and was stale. Both images
  now report only the same small set of hand-audited DATA rejects (v10: 5
  regions / 348 B, v9: 4 / 277 B — they differ because a duplicate is not
  present at a second address in v9, real content divergence, not a tooling
  artefact). `scripts/analysis/v9_v10_undisassembled_census.py --judge`
* ⚠ **Islands: DO NOT QUOTE A STATIC NUMBER.** This entry used to say
  "~14,727 B each". Island counts are not a fixed pool — every region conversion
  creates new short islands at the new code/data boundaries, and v7's population
  was measured going 2,268 → 6,854 in a few hours with nothing regressing.
  Measure fresh and state the commit you measured at.
* **subcpu v142: 0 B.** ★ Corrected 2026-09-02: the 569 B of
  `DSP_Bytecode_Op01/02/03` were converted once the decoder was fixed, and the
  ~407 B once attributed to a TaskEvent/FIFO encoder gap was RETRACTED — it was
  a measurement bug, not a gap. Historical note on the original cause (the
  pinned LLVM backend could DECODE these addressing forms but could not ENCODE
  them; fixed
  2026-09-02 in `ad8129f59880`, 569 B proven convertible, conversion itself
  owned by a separate lane). ⚠ CORRECTED 2026-09-02: the ~407 B
  TaskEvent/FIFO/TaskSched figure was never a real decoder gap. It was an
  artifact of `llvm_roundtrip_probe.py` trusting `--show-encoding`'s
  `encoding: [...]` field as the true consumed-byte count, when it can be a
  RE-ENCODE shorter than what the disassembler actually consumed (proof and
  the corrected per-instruction verification method:
  `scripts/converters/convert_taskevent_fifo_family.py`). Of the 672 B across
  the 18 flagged `.byte` runs: 50 B is genuine DATA (loaded as an address,
  never executed — left as `.byte` deliberately, not debt) and 622 B is real
  code that decodes and reassembles byte-exact once verified correctly; all
  622 B is now converted. **True remaining blocked total for this family:
  0 B.**
* **HD-AE5000: 13,288 B** undocumented `.byte`, overwhelmingly scattered
  single-byte numeric fields. `hdae5000/tools/measure_debt.py`
* **wsa1/prom_b: audited and clean** — all 188 runs of 64 B or more are typed and
  understood, so its true debt equals its `.incbin` count.
* ★ **v7: 275,822 B — MEASURED 2026-09-02, and it is the largest single debt in
  the tree.** 797 confirmed code-shaped regions (247,603 B) plus 2,268 misframed
  islands (28,219 B). This is separate from, and more than twice, v7's 123,927 B
  of verbatim romslice debt. 9,681 B of it has since been converted.
  ⚠ v7 calibrates as HIGH RISK for this measure — DATA-control false-positive
  rates of 15.7%/11.7% against v9's 1.0%/0.2%, because v7 is only ~30% CODE and
  far more fragmented — so the figure was corroborated before being trusted:
  788 of 1,048 absolute call targets (75%) across all 797 regions resolve to
  routines already named in the tree. Treat the figure as sound in aggregate
  and each individual region as needing its own check.

The coverage tool also prints six **self-tagged** markers, three of which say
`MISLABELLED, THIS IS CODE` in the v1.42 payload. Those are the tree telling you
where it knows it is wrong; they are not in any debt column.

## ⚠ Four instruments were wrong, all understating debt

Every one was fixed this push; none could have turned the byte gate red.

1. The coverage regex matched `.incbin` inside dead `; Was: .incbin ...`
   comments, counting 313,076 B of HD-AE5000 graphics **twice** — 626,152 B
   against a 524,288 B ROM, giving a NEGATIVE source figure.
2. `reachability.py` was wrong TWICE, both understating. Its `FLOW_END` never
   matched a short jump, because `unidasm` writes even the unconditional one as
   `jr T,0xaddr`, while the `jp` pattern matched CONDITIONAL jumps and hid their
   fallthrough. And its `BRANCH` alternation listed only short forms — a `jr`
   word boundary cannot match inside `jrl`, so **every long relative jump and
   call target was invisible**, to seeding and to the walk itself, in every
   image. Both corrected; debt RISES each time. Current figure: **STRONG 9,
   ANY 3,877, in 55 spans** (was ANY 1,372 in 34 before the `jrl` fix).
3. `prom_a_f85ff9_layout.py` and `corpus_bytes` were blind to 1,038 shared-source
   instructions — and the blindness was deliberately MIRRORED so the two agreed
   perfectly over an incomplete corpus.
4. `convert_code_bytes.py` carried mnemonics that were never valid llvm-mc
   syntax; every hit fell back silently to `.byte`.

## ⚠ And a green gate is not proof of correct interpretation

The HD-AE5000 image held 309 B disassembled as ~35 garbage instructions chained
by five local labels referencing nothing outside the span — a self-contained
illusion of code. It is the firmware version string, *"Technics Software section
M. Kitajima"*. It re-assembled byte-exactly the whole time, because that is all
the gate checks.

So conversions need corroboration the gate cannot give. The standard set this
push: the v10/v9 lane checked its converted regions' call targets and found **21
of 30 land on routines already named in the tree beforehand**; the subcpu lane
proved each conversion by round trip (disassemble, re-assemble that exact text,
require the original bytes).

## Erased flash is its own class, never folded into coverage

* wsa1/prom_d: **37.0%** erased (one 193,767 B run at 0x050B09-0x07FFF0 — *not*
  the trailing tail; 16 bytes of content follow it, the ASCII `wsad_54.ssf`).
* subcpu boot IC30: **96.6%** erased. Its "100% covered" is true over a 3.4%
  denominator.
* custom data IC19: **39.6%** proven erased or zero fill.

## A spelling trap in natural memory syntax — ⚠ NOT a miscompile

★ CORRECTED 2026-09-02. This entry previously called it a silent wrong-encoding
defect, "the fifth in this backend". **That was wrong.**

`(Xrr+d8)` is SIGNED. A displacement written as `+151` does not fit the signed
8-bit field, so it legitimately assembles to the 5-byte `(Xrr+d16)` form. And
`+151` and `-105` are **different addresses** — not one byte read two ways —
with hundreds of genuine d16 displacements in that range across this tree. The
assembler is behaving correctly.

The trap is for a HUMAN transcribing a raw disp8 byte out of a disassembly
listing: to reproduce raw byte `0x97` in the 2-byte encoding you must write the
signed form `-105`, because `+0x97` means something else. It cannot be upgraded
to an error, nor silently re-encoded as d8, without changing what already-correct
spellings assemble to — the one thing this backend forbids. It is therefore a
**warning**, added in `TLCS900MCCodeEmitter.cpp`, naming the signed spelling to
use.

## ⚠ A recurring sizing defect worth hunting in other images

Found three times in `prom_b` on 2026-09-02, each time by a different span. An
earlier coverage round sized several `Data_Fxxxxxx` reachability objects **2 to
83 bytes TOO LARGE**, so each silently swallowed the leading records of the
display list beginning immediately after it. The symptom is invisible: the
oversized object looks like ordinary unconverted data, and the truncated list
looks like it simply starts later.

The fix each time was to shrink the object back to its independently verifiable
extent — a coordinate or pointer table with recomputable structure — and walk
from the recovered boundary, which then lands with **zero drift** on a neighbour
that is already call-site documented or already converted. That zero-drift
landing is the corroboration; without it the shrink would be a guess.

★ **29 KNOWN INSTANCES AS OF 2026-09-02, all in prom_b** — 3 original fixes
(1,890 B), 2 found by the detector, and 23 more across three further rounds
(2,071 B). This is not a handful of slips; it is a systematic property of one
coverage-generation pass, and **~3,961 B has been recovered from it so far**.

⚠ The false-positive shape is now characterised too: SINGLE-record walk hits
with no second signal. Nine were excluded, one of which began midway through a
bitmap raster table rather than at any declared object boundary. Require a
multi-record landing.

**1,890 B recovered in prom_b this way**, plus two further instances found
2026-09-02 (`Data_F02F52`, `Data_F3281C`, identical shape: 29 B declared against
a real 24 B pointer table, each freeing a 48-byte span that frames as 4 records
and lands exactly on an already-committed label). Detector:
`wsa1/scripts/analysis/sizing_defect_hunt.py`, validated by reproducing all
three original fixes from their pre-fix source, null 2.10% for the walk alone.

⚠ **THE OTHER IMAGES ARE NOT KNOWN TO BE CLEAN — THEY ARE UNSEARCHABLE BY THIS
METHOD.** The hunt reported 0 hits in prom_a, prom_c, prom_d, v7, v9, v10,
table_data and custom_data, and the reason is NOT that they were checked and
found sound: **none of them contains a `; Label -- N bytes` reachability object
at all.** That labelling convention is produced only by prom_b's own coverage
generator. So the detector had nothing to search, and a zero here means "no
foothold", not "no defect". Finding the equivalent shape elsewhere needs a
different signature derived from how those images declare object extents.

## ⚠ Converting regions CREATES islands — the debt is not a fixed pool

Measured 2026-09-02. v7's misframed-island population was 2,268 candidates when
a lane was briefed on it and **6,854** when that lane measured it fresh a few
hours later. Nothing regressed: other lanes' confirmed-region conversions had
landed in between, and **every new code/data boundary produces new short
islands**.

Consequences for planning: an island figure is only valid against a stated tree
state, "islands remaining" cannot be tracked as a burn-down while region work
continues, and a lane briefed with an island count will find a different one.
Measure fresh, and say which commit you measured at.

## ⚠ In-tree comments naming call targets are frequently WRONG

192 `.byte` runs carry a `; call NAME (v7 addr)` comment added by an earlier
pass. Three were checked by hand and **all three named a different or unnamed
routine than the byte-verified target**. Harmless to conversion, which reads the
bytes and not the comment — but do not use these comments as evidence of
anything, and do not propagate them into new headers.

## ⚠ A wrong START frames fake records that pass the gate

Demonstrated 2026-09-02 by a lane on its own work, which is why it is worth
recording rather than warning about abstractly.

Searching prom_b's untouched span pool, a first pass accepted op `0x20`'s weak
`("min", 4)` length rule together with a coincidental starting offset, and
framed **three entirely fake records out of a caption table's own bytes** at
`0xF2B8F9`. The result reassembled **byte-exact** and passed `make gate-wsa1`.

It was caught only by re-deriving the start from independent structure: reading
from the true start yields ONE interpreter-B record whose own `+0x07`/`+0x0B`
fields self-name the adjacent 65-entry table. Correcting it closed 153 B more
than the false framing had.

**The generalisable point: a walk that begins at the wrong offset produces
plausible records indefinitely, and every byte-level check passes.** The
defence is not a better length rule — it is requiring the start to be fixed by
something outside the walk (a call site, a pointer landing on it, a record that
names the next structure), exactly as the FC4000 and 0xFDE74C closures did.

## ⚠ No converter has a structural defence against a uniform fill

Found 2026-09-02 by testing a known-DATA region and expecting a rejection that
did not come. `convert_interrupted_region.py` does NOT abort on the `swi7`x3
region at `widget_dispatch.s:8073`: it proposes converting 55 of 64 bytes,
because **a run of `0xFF` trivially round-trips as repeated `swi 7`**. Only the
documented hand-audit rejects it.

This generalises beyond that one tool and that one byte value. Any uniform or
near-uniform fill whose byte happens to be a valid opcode will:

* decode cleanly,
* re-assemble to the identical bytes,
* pass the byte-identity gate,
* and produce a long, plausible-looking instruction run.

Every defence this tree has built is aimed at something else — context tiling
proves a run is *reachable*, `looks_like_a_table_tail()` catches *periodic
record* structure, call-target corroboration needs *calls to exist*. A fill has
no records, no calls, and sits between real code by construction.

**Practical rule until a guard exists: measure the repeated-byte run BEFORE
walking.** That is exactly how prom_b's `0xF33F01` was handled correctly — a
naive walk there produced 44 plausible records of `[op 0x0E, len 14]`,
indistinguishable from the ROM's own padding, and measuring the run instead
revealed 255 B of genuine `.fill` with the real list starting after it.

## ⚠ DISPUTED: AccPatch_VoiceAssignDataBlock (v7, 2,175 B)

**Two lanes reached opposite conclusions about this region on 2026-09-02, and it
was converted. It is the first thing to re-examine in v7.**

* Lane V7REGIONS2 hand-checked it as its strongest table-tail candidate and
  called it **a genuine fixed-width data table** — already named `...DataBlock`,
  with a visible period in the raw bytes. On that basis it left all 135 of its
  table-tail exclusions alone.
* Lane V7TABLETAIL, adjudicating the 32 regions where the guard disagreed with
  100% call-target corroboration, converted it **as code**.

Evidence on both sides, measured directly from the ROM:

* **For data**: the opening bytes carry an unmistakable 8-byte record motif with
  an incrementing index — `8d 00 21 c9 cf .. 6e ..`, `8d 01 21 c9 cf ..`,
  `8d 02 21 c9 cf ..` — and a recurring `f1 fe 36 00 00 68 ..` separator.
* **For code**: every call target in the region resolves to an already-named
  routine (that was the selection filter), and the converted text reads as
  coherent routine code — `calr`/`ldw_d16`/`stda16` against a consistent block
  of RAM addresses, ending in a real `call`.
* **Against a simple table**: whole-region self-match peaks at only **0.104** at
  stride 8, with **203 distinct byte values across 2,175 B**. A uniform
  fixed-width table of small fields would show far stronger periodicity.

⚠ The most likely reading is that BOTH are partly right — a table head followed
by code, the same head/tail split this lane confirmed elsewhere in
`DrumKit_GroupAssignTable` + `RhythmROM_LoadDrumKit`. If so the conversion
absorbed a real table head. **Nothing in the build can detect this**: the bytes
are unchanged either way.

Resolve by finding the region's reader. If code reaches it via `call`, it is
code; if something indexes it with a stride, the head is a table.

## ⚠ CORRECTED: v7 region conversion was overstated by ~9%

`run_v7_worklist_batch.py` overstated converted-byte counts whenever a region
auto-shrank, subtracting `remaining` from the PRE-SHRINK worklist size rather
than the size actually touched. It was caught reporting "137 B converted" for a
region whose `git diff` showed **zero changes**. Fixed 2026-09-02.

Re-derived from the merge diffs themselves — counting `.byte` values removed
minus those added back — rather than from any tool's own report:

| lane | reported | **actual net** |
|---|---:|---:|
| v7regions2 | ~32,700 B | **29,682 B** |
| v7islands2 | 566 B | 566 B (exact) |

**So v7's region conversion was ~3,000 B (9%) less than reported.** The islands
figure was exact, and the romslice lane's diff correctly shows `.byte` INCREASING
(it converted slices INTO typed data, which is the intended direction there).

⚠ Any byte count produced by that driver before the fix is an **upper bound**.
Re-derive from diffs, which is what this table does.

## ⚠ The weakest evidence currently in the tree: v7 batch F

Recorded 2026-09-02 so it is not forgotten under an aggregate. v7's confirmed-region
conversions were done in four batches of decreasing selectivity, and the
call-target corroboration fell with it:

| batch | regions | targets resolving to already-named routines |
|---|---:|---|
| A | 11 | 37/37 = **100%** |
| C | 21 | 142/157 = 90% |
| E | 46 | 78/103 = 76% |
| **F** | **22** | **11/20 = 55%** |
| total | 100 | 243/281 = 86% |

**Batch F's 55% is the weakest evidence supporting any conversion in this
tree.** Its defence is CROSS-REGION CONVERGENCE — five unnamed targets reached
independently from separate regions, which is genuine but strictly weaker than a
target landing on a name that existed beforehand. Re-examine batch F before
building anything on it, and prefer it as the first place to look if a v7
conversion is ever found wrong.

⚠ Note the shape: the 86% aggregate is true and hides this. Quote the gradient,
not the average.

## v7 islands: the whole population has been worked once

At commit `0d642c00` the population was **7,496 islands / 44,766 B** (up from
2,268 when first briefed, then 6,854 — region conversions keep creating them).
All 7,496 were classified across 12 gated slices. **566 B was kept.**

That ratio is the point, not a disappointment. Where the rest went:

| outcome | count |
|---|---:|
| table-tail rejects | 2,111 |
| near-uniform-run rejects | 1,044 |
| refused at write time by the VALUES-mismatch guard | most of 260 spellable |
| jump-table-label rejects | 3 |
| **kept** | **566 B** |

Corroboration on what was kept: **22 distinct call targets, 22 corroborated** —
12 exact-label hits and 10 landing on a genuine instruction boundary inside
another named routine.

⚠ **Two bad conversions still got past every automated guard** and were reverted
only because someone read the diff: a 2-byte zero field below a guard's
min-length floor, and a 34-byte chain containing an implausible `srl xsp, 98` —
the same shape a previous lane had to revert by hand. Both round-trip
byte-exact. **Reading the shape is not yet replaceable by a check.**

⚠ Flagged, not acted on: one enclosing label (`CmpBkslSTtl_FillIn4`) is itself a
jump-table base — loaded via `lda_24` then `jp_ind` elsewhere. The converted
candidate sits well after it, but the label's whole pre-existing body deserves a
look.

## Where the next pass should aim

1. ~~A round-trip generator for table_data's six BMPs~~ — **DONE, as a refusal:
   they are already in their best form. See the correction above.** The next
   largest genuine block is v7's 123,927 B of romslice transplants.
2. The v9/v10 misframed islands (~14,727 B each), the largest measured
   code-as-`.byte` debt.
3. ~~Teach the LLVM backend to encode the forms it can already decode~~ —
   **PARTLY DONE 2026-09-02, and the picture changed.** Two decoder bugs fixed
   (`ad8129f59880`), one of them a SILENT MISCOMPILE: the ROM's
   `bf 04 02 01 00` disassembled to text that re-encoded as `bf 04 14 01 00`,
   accepted with no diagnostic. **569 B unblocked and measured** — the three
   `DSP_Bytecode_Op01/02/03` handlers now round-trip byte-exact, 203
   instructions. **The 569 B are CONVERTIBLE**, conversion owned by a
   separate lane (stay off `DSP_Bytecode_Op01/02/03` if you are not that
   lane). ⚠ CORRECTED 2026-09-02: the ~407 B TaskEvent/FIFO/TaskSched figure
   is retracted — it was a measurement artifact, not a decoder gap; see the
   correction above and `scripts/converters/convert_taskevent_fifo_family.py`.
   622 B of that family is now converted (0 B remains blocked); the same
   script's docstring names four decoder-level gaps a future LLVM pass should
   fix so the DISASSEMBLER (not just a hand-written workaround) can spell
   these forms: the explicit-zero-displacement `LD` print/encode collapse
   (the dominant one, ~490 B here), `RESm`/`SETm`/`BITm` missing from
   `decodeMemPrefix()` (with `BITm` silently misdecoding as `AND` rather than
   failing), and `LDC CR16,r16` having no decoder branch at all despite the
   mnemonic already being used elsewhere in this same file.
4. Measure v7's code-as-`.byte` debt — the one image with no census in that shape.

5. ★ **The DECODE leg, which is now the bigger half.** The disassembler has
   *zero* support for two whole families the assembler encodes fine:
   the register-indexed `SriRR*` group (`st_rrb`, `ld_rr*`, `lda_rr`, …) has no
   case anywhere in `TLCS900Disassembler.cpp`, and `decodeERPPrefix()` is a
   literal stub returning `Fail` for ~20 mnemonics. This is why 312 B stayed
   invisible to every automated audit for months, and why **33 of 34 v7 code
   slices fail a disassemble/re-assemble round trip**. Its price tag is
   unknown, unlike the encode leg's.

6. ~~A latent ENCODER ambiguity~~ — **RETRACTED. There is no collision.**
   `ST_RRB`/`ST_RRW`/`ST_RRL` encode distinctly: the trailing byte is `0x41`,
   `0x50`, `0x60` respectively, confirmed with `llvm-mc --show-encoding`. The
   collision was real once and was fixed on 2026-08-22 by `1b9432474daa`,
   eleven days before this entry claimed it was open — the claim came from
   reading the emitter's `Opcode < 0xF0` guard without checking the bytes, and
   `TLCS900InstrInfo.td` already spells these sub-opcodes out per size for
   exactly that reason. A full audit of all 22 call sites of that guard found
   **no other instance**: two formats have no live instantiations, those fixed
   below `0xF0` get the size adjustment by construction, and every family at or
   above it already spells its sub-opcode per size.