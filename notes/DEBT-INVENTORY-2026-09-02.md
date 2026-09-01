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
`HDAE5000_Lang_Codes`. **This category is unmeasured across all 13 images**, so
every "remaining debt" figure in this file is a LOWER BOUND.

A `.byte` run is exactly as un-decoded as an `.incbin`, and it passes every
"no `.incbin`" test. This project has now shipped that false claim twice.

## Verbatim debt: 544,138 B counted, but ⚠ only 225,670 B is real

The tool reports 544,138 B of 12,386,304 (95.6% source). **318,468 B of that is
the six table_data BMPs, which are the genuine shipped artefact in their best
form — see below. Subtracting them leaves 225,670 B, i.e. 98.2% source.**
Quote 225,670; the 544,138 figure counts a correctly-represented asset as debt
because the tool classifies by MECHANISM (`.incbin` with no generator) rather
than by whether anything is actually unknown.

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

* **v9 and v10: 8,058 B each** of confirmed code still as `.byte`, plus
  **~14,727 B each** of shorter misframed islands, measured and deliberately not
  attempted (fixing one means re-framing an instruction already present, not
  filling a gap). `scripts/analysis/v9_v10_undisassembled_census.py`
* **subcpu v142: ~976 B**, and the reason is named rather than "did not try":
  the pinned LLVM backend can DECODE addressing forms it cannot ENCODE
  (`DSP_Bytecode_Op01/02/03`, 569 B) and cannot re-parse some spellings its own
  disassembler emits (~407 B, TaskEvent/FIFO/TaskSched).
* **HD-AE5000: 13,288 B** undocumented `.byte`, overwhelmingly scattered
  single-byte numeric fields. `hdae5000/tools/measure_debt.py`
* **wsa1/prom_b: audited and clean** — all 188 runs of 64 B or more are typed and
  understood, so its true debt equals its `.incbin` count.
* **v7: NOT MEASURED in this shape.** Its 123,927 B figure is verbatim only.

The coverage tool also prints six **self-tagged** markers, three of which say
`MISLABELLED, THIS IS CODE` in the v1.42 payload. Those are the tree telling you
where it knows it is wrong; they are not in any debt column.

## ⚠ Four instruments were wrong, all understating debt

Every one was fixed this push; none could have turned the byte gate red.

1. The coverage regex matched `.incbin` inside dead `; Was: .incbin ...`
   comments, counting 313,076 B of HD-AE5000 graphics **twice** — 626,152 B
   against a 524,288 B ROM, giving a NEGATIVE source figure.
2. `reachability.py`'s `FLOW_END` never matched a short jump, because `unidasm`
   writes even the unconditional one as `jr T,0xaddr`; and `jp\s` matched
   CONDITIONAL jumps, hiding their fallthrough. Corrected, debt RISES: ANY
   1,702 → 2,071 in 37 spans.
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

## Where the next pass should aim

1. ~~A round-trip generator for table_data's six BMPs~~ — **DONE, as a refusal:
   they are already in their best form. See the correction above.** The next
   largest genuine block is v7's 123,927 B of romslice transplants.
2. The v9/v10 misframed islands (~14,727 B each), the largest measured
   code-as-`.byte` debt.
3. Teach the LLVM backend to encode the forms it can already decode; that alone
   unblocks 976 B in the subcpu payload.
4. Measure v7's code-as-`.byte` debt — the one image with no census in that shape.
