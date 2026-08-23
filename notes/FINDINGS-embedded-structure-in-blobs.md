# Structure sealed inside `.incbin` blobs the audit passes

Measured 2026-08-23. Reproduce with
`python3 scripts/analysis/l3_embedded_structure_scan.py`.

## The blind spot

`audit_incbin_legitimacy.py` runs `l3_slice_structure_triage.py`, which
classifies each blob **as a whole**. A structured region that is a small fraction
of a large file cannot move that file's byte statistics, so the audit reports
"0 illegitimate blob bytes" while structure sits inside the blobs it passed.

A windowed re-scan finds **45 regions / 25,344 B** across 391 OPAQUE blobs, each
surviving a per-region byte-shuffle control.

⚠ **This is a lower bound.** The scan aligns its windows, so a region not
starting on a window boundary is split and may classify as neither thing. The
table that motivated the whole investigation is itself missed for that reason —
see below.

## The clearest case: `naka_effects_seq.bin` 0x006700–0x007100

2,560 bytes = **640 little-endian u32**, of which 605 are distinct and 603 of 639
consecutive steps are non-decreasing. Deltas cluster at 26/36/42/44/38/40 —
variable-length records in ascending address order.

They point into `0xE2841C … 0xE2E5D6`. Reading the ROM there:

```
0xe2841c:  1f 00 60 01  00 00 ff ff  07 00 05 00 ...
0xe28444:  1f 00 60 01  00 00 ff ff  08 00 06 00 ...
0xe28494:  2b 00 60 01  00 00 ff ff  0a 00 08 00 ... 'FREQ' 00 ff
```

`XX 00 60 01` is exactly what this project's own macro emits:

```asm
.macro naka_header type
	.byte \type, 0x00, 0x60, 0x01
.endm
```

So the region is a **pointer table addressing NAKA widget descriptor records**,
and the records are the very structure the `naka_header` macro exists to express.
Both the table and the records are sealed in `.incbin` blobs. The better form
(`.long <symbol>` plus `naka_header`) is not merely available in principle — it
is already implemented and used elsewhere in this tree.

## `naka_widget_descriptors.bin` — documented and still opaque

150,888 B, class OPAQUE, "earns no better format on this evidence". The comment
printed directly above its `.incbin` line documents four tables inside it:

| table | shape | verified |
|---|---|---|
| `DspParamUnit_Table` | 86 × 2 | — |
| `DspParamName_Table` | 86 × 17 | ASCII, e.g. `VOLUME          :` |
| `DspEffectName_PtrTable` | 128 × u32 | **128/128 land in the ROM address range** |
| `DspEffectName_Strings` | 128 × 18 | ASCII, e.g. `   ----------   \x00\xff` |

⚠ This table sits at blob offset `0x1c1a`, which is not window-aligned, so it is
**not** among the 45 the scan reports. The scan that exposed the blind spot has a
smaller version of it.

## What this does and does not establish

ESTABLISHED from the bytes: the regions exist, hold ROM-range u32s and readable
ASCII, and their shuffle controls are clean.

NOT established: that converting them is straightforward. Each blob is
`.incbin`'d as one unit and other modules index into it by offset, so splitting
one means re-expressing those offsets. The converter already splits `.incbin`
slices, so the machinery exists; the work is per-blob and is not done here.

---

## The 30 regions NOT converted, and why (2026-08-23)

After the P1 (symbol) and P2 (record signature) paths converted 12,288 B, thirty
regions / 13,056 B remain. They are **not** left out for lack of evidence that
they hold addresses — they hold addresses:

| blob | region | P1 resolve | vs null (1.879%) |
|---|---|---:|---:|
| `gui_display_struct_data.bin` | 0x000b00 | 25.3% | 13× |
| `naka_widget_names_charmap.bin` | 0x004c00 | 54.7% | 29× |
| `naka_widget_tables_1.bin` | 0x001000 | 40.6% | 22× |
| `naka_sequencer_channels.bin` | 0x001500 | 28.1% | 15× |

They are left out because "holds addresses" does not establish "is a flat table
OF addresses". A RECORD ARRAY carrying one pointer per N words produces exactly
these fractions — a 2-word record with one pointer resolves at ~50%, a 4-word
record at ~25% — and emitting every word as `.long` would describe the
non-pointer fields wrongly while staying byte-identical, so no gate would object.

TEST: are the resolving words at a regular stride, as a record array requires?

```
naka_widget_names_charmap 0x4c00  105/192 resolve   mod2 50%  mod3 34%  mod4 26%
naka_widget_tables_1      0x1000   26/64  resolve   mod2 50%  mod3 34%  mod4 26%
naka_sequencer_channels   0x1500   18/64  resolve   mod2 50%  mod3 33%  mod4 27%
gui_display_struct_data   0x0b00   97/384 resolve   mod2 65%  mod3 44%  mod4 48%
```

Chance is 50% / 33% / 25%. The first three are AT chance — scattered, not
strided, so the record-array reading is not supported for them either. The
fourth is not: 48% at one residue mod 4 against 25% chance says
`gui_display_struct_data` is partly strided, i.e. genuinely record-like.

So the test did not resolve the question; it only showed the two readings are
not separable by stride alone for three of the four. **Both readings remain
open, and the honest state is unconverted.** What would settle it: find the code
that INDEXES each region and read its stride off the addressing arithmetic —
`.incbin` offsets are reached by known index expressions elsewhere in the
sources, and that is a fact about this ROM rather than a statistic.

⚠ Note the asymmetry that makes this worth resisting: converting them would
raise the "structure exposed" figure by 13,056 B and pass every gate in the
project. Nothing here can punish a wrong description, only a wrong byte.
