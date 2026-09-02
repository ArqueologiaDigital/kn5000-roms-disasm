# What is actually left to disassemble — consolidated, 2026-09-02

Result of an eleven-lane parallel push across all 13 gated images. **The byte
gate is green: 13/13 byte-identical, 8/8 KN5000 images assembling with the
pinned toolchain**, re-run centrally on `main` after every merge.

## ★ A LEAD NOBODY HAS FOLLOWED: 13 control transfers into IC19's window

The `tier2byte` lane established that **custom_data (IC19) is a pure data ROM**
— a claim it attacked rather than assumed, because IC19 *is* CPU-fetchable
(`kn5000.cpp:152`), so the claim is not true by construction. All 206
references LOAD its address; `llvm-mc` emits 0 instruction statements from its
source against 36,391 for HD-AE5000; and a spike of proven code scores
3.39–3.61 inside IC19's own address space against its 1.11 ceiling.

⚠ **But 13 control transfers into IC19's address window DO exist**, in
`v10/maincpu/sequencer/accompaniment_engine.s` and its v9 twin — and **all 13
sit inside `.byte`-adjacent misframes**. That lane did not touch them.

Either those 13 are more mis-framed data (the likely reading, and it would
strengthen the pure-data verdict), or IC19 has an entry path nobody has found.
Both are worth one lane's attention, and the second would be a significant
correction. Start from the 13 sites, not from IC19.

## ⚠⚠ RETRACTED THE SAME DAY: "v10's leftover `.byte` runs are undecoded code"

I measured that v10 starts a `.byte` run with one of `{01,04,17,1a,1c}` — five
bytes `llvm-mc` could not decode — **19.2% of the time against 0.4% for
decodable bytes of the same magnitude, a 46x enrichment**, with all four WSA1R
images flat as a negative control. I read that as "v10's residue is largely
undecoded code", wrote it into this file, and **sent it to seven lanes as
actionable**.

**It is retracted.** The number is real; the reading is not.

### The null that settles it

With the five bytes made decodable, **82.8% of v10's blind-starting runs decode
end-to-end clean — and a SHUFFLE of the same bytes scores 82.1%.** Real and
permuted are indistinguishable, so the runs carry **no instruction structure**.
(Uniform random scores 24.2%: that is the architecture's base rate, and the gap
between 24% and 82% is what "these bytes look like data of this shape" is worth,
not what "these bytes are code" is worth.)

Re-run centrally after all merges (`scripts/analysis/blind_run_decode_census.py`,
2026-09-02, 3,104 runs / 7,676 B — the population shrinks as lanes convert):

    whole population   real 82.2% fully clean   shuffled 81.8%   random 24.3%
    runs >= 6 bytes    real 45.3%               shuffled 33.6%   random  5.5%
    runs >= 12 bytes   real 38.9%               shuffled 21.1%   random  2.2%

⚠ **State the population with the number.** On the WHOLE population real and
shuffled are indistinguishable, which is what kills the code reading. On the 90
runs of ≥12 B there IS a real gap — 38.9% against 21.1%, and 69.9% against
41.1% by clean prefix. That gap is not nothing, and it is also not a licence:
the longest of those runs are `04 00 00 00 08 00 00 00 10 00 00 00 …`, which is
**data regularity** — a shuffle destroys a stride as surely as it destroys a
program, so a shuffle null cannot tell those two apart. Anyone converting on
the ≥12 B gap needs a different null, one that preserves stride.

Separately, across six committed images, **not one occurrence of the five
survives inspection as executed code**: every site is a byte ramp, a
power-of-two mask table, a pointer table, a string, or a DSP parameter block.
`scripts/analysis/blind_byte_rom_sites.py`.

### Why the 46x was never evidence — the structural confound

Where a region was converted by a **linear force-disassembly** pass, a `.byte`
run begins at *exactly* the byte the decoder refused. A **decodable** control
byte therefore can almost never START a run — it gets consumed into the
surrounding instruction stream instead. **The control rate is pinned near zero
by construction**, whatever the region actually contains, so the blind/control
ratio is close to tautological for any force-disassembled region. The WSA1R
images are flat because their residue was not produced that way — not because
it is more data-like. My "negative control" controlled for the wrong thing.

And the composition gives it away: `0x01` and `0x04`, two of the commonest data
values in any image, are **93.6%** of v10's blind run-starts (2,188 + 993 of
3,395). `0x1a` and `0x1c` — the `jp`/`call` bytes that made the finding sound
important — are 28 and 62.

### Three lanes found it independently, from three directions

* **`ui_widgets/widget_dispatch.s`: 2.1x**, below the script's own threshold —
  65 of its 74 blind starts are a **tag's low byte** in six-byte
  `{u16 tag, u32 ptr}` records, at a boundary manufactured by an interposed
  `.long`.
* **`sequencer/seq_event_playback.s`: 40.9% → 1.7%** after clearing
  data-as-code misframes, **converting nothing into an instruction**. A wrong
  stream breaks at every refused byte, so a misframe manufactures the signature
  in bulk.
* **`audio/sound_editor_ui.s`** is the strongest, because its population was
  certified data by an **external** authority — a C struct compiled by the
  project's toolchain emitting exactly those ROM bytes, which depends on no
  decoder and no framing judgement: blind starts are **enriched 1.29x INSIDE
  spans proven not to be code at all** (20.1% vs 15.6%).

### ★★ AND IT IS WORSE THAN CONFOUNDED — IT POINTS THE WRONG WAY

The naka lane ran the identical statistic **inside v10**, on regions whose
status was settled first by independent evidence:

| region | runs | blind | control |
|---|---:|---:|---:|
| 18-byte records 0xEDCAD6–0xEE0010 — **PROVEN DATA** | 1,873 | **68.4%** | 0.0% |
| `extensions/extension_data.s` — whole file | 2,950 | 58.3% | 0.0% |
| `boot/system_handlers.s` — **KNOWN CODE**, 652 call targets | 88 | **14.8%** | 0.0% |

**The proven-data block scores 4.6× HIGHER than the known code.** So the
statistic does not merely fail to indicate undecoded code; on this image it
*anti*-correlates with code. Note the control column is 0.0% in every row
**including the known-code one** — the floor is what drives the ratio, exactly
as the structural argument above predicts.

`scripts/analysis/blind_start_enrichment_control.py`.

★ And `extension_data.s`, the file whose 58.3% I told a lane to treat as a code
candidate, **is data**: 1,590 of its 1,721 blind starts sit inside 18-byte
records of a 956-entry pointer table, clustered at field offsets (+0x0C alone
48.0%, which holds the value 1 in 781 of 956 records), `0x01`/`0x04` are 97.9%
of them, and **0 of 59,849** absolute call/jp/jr targets in `v10/maincpu` land
anywhere in the file. The stride hypothesis raised on `widget_dispatch.s` is
confirmed here at twenty times the scale, and it accounts for the whole of that
file's image-worst rate.

⚠ I told that lane twice, in opposite directions. The first message —
"probably type it, not decode it", reasoned from the filename — was right, and
I talked it out of that on the strength of the retracted statistic.

### What survives

A high blind rate means **the region is framed wrongly** — and that resolves in
BOTH directions, which the midi/display lane demonstrated within one lane:
`midi_dispatch_handlers.s` was data spelled as code (typed, never
disassembled), while `graphics_text_vga.s` is honest undecoded code. So it is a
weak *pointer* to suspect framing, never a verdict, and never a byte count.

⚠ **Do not schedule a v10 residue conversion lane on this finding.**

★ The decoder gap it caused to be closed was worth closing on its own merits —
a decoder that cannot see a byte reports nothing there rather than reporting a
problem — but it is not a route to converting v10.

## ★★ SX-WSA1R: 13,206 B → 481 B in one push (2026-09-02)

**Three of the four SX-WSA1R images are at ZERO verbatim debt. The fourth,
prom_b, holds 481 bytes.** Seven lanes, all merged and gated together from a
clean rebuild: `make all` in `wsa1/` then `assert_byte_identical.py`, 4/4
byte-identical.

| image | start of push | now |
|---|---:|---:|
| prom_a | 2,542 B | **0** ✅ |
| prom_b | 10,664 B | **481 B** (99.9% source) |
| prom_c | 0 | **0** ✅ |
| prom_d | 0 | **0** ✅ |

Every lane's figure proved exact and additive: 2,995 + 2,453 + 1,757 + 1,139 +
1,115 + 811 = 10,183, and 10,664 − 10,183 = 481 to the byte.

### What the spans actually were — and it was almost never "undecoded code"

Across six independent lanes the same answer kept arriving: **display-list data
named by pointers**, and the reason it had been left behind was always the same
mechanism.

> **Round 1 sized each object by a reachability walk, and a walk's extent is not
> an object's extent.** It reached an object's FIRST byte through a 32-bit
> pointer and stopped, because it had no notion of how big the pointed-at thing
> is. The display-list HANDLER does: `0xF31ABE` gives BC×HL for a bitmap,
> `0xF31B57` is `sla 3,HL` ⇒ 8-byte entries, `0xF31B86` is `mul HL,6`,
> `0xF31B21` takes the width from the record's `+0x0B`. That one fact closed
> most of the remaining debt.

The small-span lane made the mechanism visible statistically: of 55 spans ≤128 B,
**44 follow a data directive and 48 are followed by a label**. They were never
gaps *between* objects — they are the **rest of the object above them**, left
when the walk cut a fixed-stride array mid-entry.

★ Consequently **several object extents in the tree were too long**, each having
warned in its own header that its extent was the walk's and not the object's.
`Data_F3C37D` was recorded as 257 B and is 48 — it ran through an entire second
array and one byte into its 27th entry.

### The exceptions, which are the interesting part

* **prom_a 0xF96504** (1,889 B) is a **bit-field script interpreter** whose
  reader was already converted one screen above; its three literals all land
  inside the span. Walking every script the two tables name tiles
  0xF9667A–0xF969A1 exactly: 18 scripts, 259 records, no gap, no double-claim.
* **prom_a 0xFDFFDF** (33 B) is **linker slack** holding the middle of a stale
  routine prologue — 31 of 33 bytes match four prom_b copies against a 15% null,
  and it begins and ends mid-instruction because it was overwritten at both ends.
* **prom_b 0xF00C4D** (2,995 B) really was code: 828 instructions, framed
  without using reachability at all — an exact `unidasm` tiling with no `db`
  inside against 26 in the 786 bytes after, all 54 internal branch targets on
  instruction starts, and 26 pointers held OUTSIDE the span all landing on
  instruction starts. ★ **And it is in the image but not in the machine**: only
  14 of its 34 prom_a call targets are instruction starts in a window that is
  20,372 of 20,480 bytes framed as instructions. It appears linked against a
  *different* prom_a, so **no routine there may be named for what its target
  does in the prom_a we have.**

### Two hazards this push demonstrated live

⚠ **A tool in the tree would have silently reverted 2,453 bytes.**
`gen_prom_b_cover_round1.py --splice` replaces a whole `COVER-R1` block with its
own emission, and its no-overwrite guard collects the converted lines *outside*
the markers — so work spliced *inside* one is invisible to it and would be
reverted to `.incbin` **with the byte gate still green**, because `.incbin`
reproduces the ROM by construction. A guard and a probe are now committed.

⚠ **Two lanes framed the same array from bases 48 bytes apart** — exactly six
whole entries, so both put every entry boundary in the same place and emitted
identical bytes. The gate cannot distinguish them. The disagreement is written
into the source at `DLTable_F3C3AD` rather than silently resolved; the
record-anchored base was kept.

### Refusals, which are results

**17 spans / 551 B were refused** by an exhaustive search that finds a
decomposition for 1 of 18 candidates and none for the other 17 — display-list
record streams with no anchored boundary, or 8-byte-looking arrays whose base is
declared nowhere. One worth someone's time is `0xF3B656`: `Data_F3B651` starts
`00 0B`, but as op 0x00 length 11 its record ends at 0xF3B65C while the next
record demonstrably starts at 0xF3B65B. Either op 0x00 does not carry its length
at +1 in this interpreter, or `DL_F3B65B` is off by one. Guessing would put a
wrong boundary into the tree that the gate would certify.

⚠ Every lane demonstrated the gate goes **red** on a deliberate one-byte
perturbation of its own conversion, then green on restore. A green gate never
shown to fail on the change certifies nothing.

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

★ **Both WSA1R verdicts were attacked a SECOND time on 2026-09-02, by a lane
that set out to break them, and both held** — see
`wsa1/notes/FINDINGS-prom_cd-falsification.md`,
`python3 wsa1/notes/prom_cd_falsification_2026_09_02.py` (55 checks). What is
new is the direction: this attacked **code typed as DATA**, the inverse of the
hazard this table usually tracks, which the byte gate is equally blind to. The
instrument is branch-target coherence normalised by boundary density, calibrated
on prom_c windows labelled code/data by the assembler's own DWARF line-table
census (76,647 instruction statements in prom_c, **0** in prom_d), and spiked
with real prom_c code to prove it can fail. prom_c code scores 2.42–3.09,
prom_c data 0.81–1.34, prom_d 0.29–1.16 over every scorable window.

⚠ Two limits are on the record rather than buried: the test's reach is a
**contiguous ~2 KiB routine** — anything shorter would evade it — and
prom_d 0x26000–0x2BFFF (`ToneDB_EnvDescTable`) has too few branches to score at
all. The `.fill` totals (prom_c 129,216 B, prom_d 193,767 B) were re-derived
from byte VALUES, by rebuilding each image with every fill value XORed 0xFF and
diffing against the dump.

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

## ✅ RESOLVED: AccPatch_VoiceAssignDataBlock is CODE

Settled 2026-09-02 by finding both readers, which is what the note said would
settle it. An external `call` lands on the region's exact start, from a
string-tag dispatcher comparing bytes against accompaniment tags; an internal
call reaches base+494, matching a pre-existing positional label. All 701
instructions decode with zero failures.

★ **The evidence that looked like a table is explained by the code reading.**
The 8-byte motif with an incrementing index (`8d 00 …`, `8d 01 …`, `8d 02 …`)
decodes as a repeated string-compare idiom — load a byte at an index, compare
against an immediate, branch if not equal. And the low whole-region self-match
of 0.104 is precisely what that idiom produces, not evidence against a table in
spite of the motif. Two observations that appeared to point in opposite
directions point the same way once the consumer is known.

The lesson generalises: **structural signals measured without a reader can be
read either way.** Find the consumer first.

## ✅ RESOLVED: v7 batch F holds — 20/20 on the stronger test

The 55% that made this the tree's weakest evidence was NAME RESOLUTION. Under
the boundary audit — does the target land exactly on an instruction boundary —
**20 of 20 pass**: 11 exact pre-existing names plus 9 boundary-corroborated
valid entry points. None of the 27 underlying labels is ever `lda*`-referenced,
ruling out table use, and all 22 regions decode with zero undecodable opcodes.
Zero reverts.

⚠ Keep the distinction that produced the scare: a name-resolution rate and a
boundary-corroboration rate measure different things, and the weaker one is the
easier to compute. Quote which you mean.

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

## ⚠ sizing_defect_hunt.py's landing test is weaker than the strict audit

Found 2026-09-02 while acting on that tool's output. Its "zero-drift landing"
check walks with a looser **op-shape** rule than
`prom_b_dl_length_audit.py`'s strict per-handler length rule. One of its
candidates (`Data_F34CA2`/`Data_F34CAD`) would have been typed as an
interpreter-A record when the ROM's own handler tables say **interpreter-B**.

**Verify every hunt candidate against the real `HTBL_A`/`HTBL_B` tables before
converting it.** The tool is a lead generator, not an adjudicator — and note it
says so itself on its weaker verdicts ("structural tail found but NO zero-drift
walk landed — do not convert on this alone"), which were correctly honoured.

## ⚠ A span is not homogeneous: embedded tables inside code

Two prom_a spans were refused for months on symptoms that turned out to be the
same cause.

`0xF8C485` was refused because a dispatch target landed **three bytes off** a
decode boundary beside suspicious mnemonics. Those bytes are three **embedded
data tables** — a 16-word bitmask sized by its own reader's index range, and two
3-entry bucket tables whose values match the same routine's hardcoded fallback
constants. Excise them and 4 of 8 dispatch targets land exactly on the resulting
code starts.

`0xF8C652`'s recorded "8 undecodable bytes at a ~16-byte stride" **undercounted**:
two further embedded tables decode as individually valid-looking WRONG
instructions and never trip an undecodable flag at all.

**The lesson: "mostly code with a few bad bytes" is often code with a table in
it.** Look for a reader that sizes the anomaly before concluding the framing is
wrong — an undecodable-byte count only finds the tables that happen not to
decode.

## ★ v7's remaining debt is TOOLCHAIN-BLOCKED, not analysis-blocked

Established 2026-09-02, and it changes what the next pass should be.

Of v7's 153 header-plus-code romslices (69,634 B), only 1,108 B converted. The
rest did not resist analysis — it resisted the assembler:

| outcome | slices | bytes |
|---|---:|---:|
| converted | 26 | 1,108 |
| symbolic `.long` headers, refused for cause | 33 | 21,956 |
| **no offset round-trips cleanly — llvm-mc spelling gap** | **94** | **46,570** |

The same ceiling shows in the confirmed regions: a lane found the strict pool
down to 15 regions, ALL blocked by an interior-label/decode-boundary conflict,
with corroboration flat at ~30% below that — and stopped rather than convert.

**So more conversion lanes on v7 will not move it.** The lever IS the backend:
teach `llvm-mc` to spell the forms it currently cannot.

⚠ **THIS PARAGRAPH HAS NOW BEEN WRONG TWICE, IN OPPOSITE DIRECTIONS. Read the
whole entry before acting on it.**

**Version 1** said the lever was the backend. A lane was sent to pull it and
came back with the totals UNCHANGED — 94 slices / 46,570 B still blocked — plus
a census showing six single-byte opcodes (`0x01`, `0x04`, `0x17`, `0x1a`,
`0x1c`, `0x1f`) that the backend cannot decode at all.

**Version 2** concluded from that census that those six were RESERVED OPCODE
SPACE, therefore not code, therefore v7's remainder was data and the lever was
the wrong one. **That conclusion is RETRACTED.** It inferred a fact about the
ROM from a fact about our assembler, and the two are not the same thing:

| byte | tlcs900_backend | MAME `unidasm` |
|---|---|---|
| `0x01` | no decode | **`normal`** |
| `0x04` | no decode | **`max`** |
| `0x17` | no decode | **`ldf 0xnn`** |
| `0x1a` | no decode | **`jp 0xnnnn`** — a 16-bit absolute JUMP |
| `0x1c` | no decode | **`call 0xnnnn`** — a 16-bit absolute CALL |
| `0x1f` | no decode | `db` — genuinely undefined |

Five of the six are **real TLCS-900 instructions this backend has never been
taught**, and two of them are CONTROL FLOW. A region whose decode stops at a
`jp` or a `call` is code by the most direct evidence available. ★ And `0x1f`,
the one byte that IS undefined, **gates zero slices and zero bytes** — so the
entire basis for calling the remainder data was the five bytes that turned out
to be instructions.

**21 slices / 16,683 B are blocked by those five real instructions alone.** The
top blocker overall, `0xC1` (14 slices / 6,434 B), is the 16-bit direct-address
prefix — mapped in the backend, but missing the `BITm`/`SETm`/`RESm` 16-bit
forms a lane already identified. All of it is assembler work.

### The rule this cost twice over

**Never conclude anything about the ROM from a backend refusal without asking a
second decoder.** `TOOLCHAIN_VERSION` already records SEVEN occasions where "the
backend cannot do this" meant "a spelling I had not tried"; this is the eighth,
and the first where the wrong inference was written into the plan of record.

The evidence lives in two committed scripts, and the FIRST one is a lesson in
its own right:

* `scripts/analysis/leading_byte_reserved_probe.py` — sweeps 393,216 operand
  continuations per leading byte. ⚠ Its **foil control caught two too-shallow
  versions of itself**: a second-byte-only sweep called four known-mapped bytes
  reserved, and a second-and-third sweep still called `0xC1` reserved, because
  `0xC1`'s sub-opcode sits behind two address bytes. A criterion that cannot
  fail is not evidence; this one failed twice before it was trustworthy.
* `scripts/analysis/unmapped_byte_oracle.py` — asks `unidasm` what a
  backend-unmapped byte really is. This is the disproof above.

## ★ A guard against opcodes that round-trip regardless of meaning

`nop` and `swi` are fixed one-byte opcodes, so a run of them re-assembles to the
same bytes whatever those bytes actually are. A candidate that is 20% or more
trivial opcodes is now rejected outright — this caught a documented false
positive and two mostly-zero data tables before they were committed as code.

It generalises the uniform-fill hazard: the problem was never `0xFF`
specifically, it is **any byte sequence whose decoding is insensitive to whether
it is code**.

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