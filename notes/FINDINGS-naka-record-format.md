# The NAKA widget record format

Measured 2026-08-23. Reproduce with:

```
python3 scripts/analysis/l3_naka_record_format.py          # length per type
python3 scripts/analysis/l3_naka_field_layout.py --all     # fields per type
python3 scripts/analysis/l3_naka_field_layout.py --type 0x1f
```

## What was missing

The completeness spec asks for the data format of every structure. The NAKA
blobs — ~903 KB across 248 `.incbin` spans, the largest data structure family in
this firmware — had names for their contents (3,709 `.equ` offsets) but no
format: no record length, no field layout, no idea which fields were pointers.

They resisted the usual method because the named-offset gap histogram is diffuse.
That is not disorder; it means the records are **variable-length and defined by a
header**, so there is no single stride to find.

## The header

This tree's own macro says what a record starts with:

```asm
.macro naka_header type
	.byte \type, 0x00, 0x60, 0x01
.endm
```

Scanning the blob spans for `XX 00 60 01` gives **2,857 headers**, against **13**
in a byte-shuffled copy of the same spans. `XX` is the record TYPE.

## Length per type

Measuring each record as distance-to-next-header pins a length for 10 types:

| type | length | consistency | type | length | consistency |
|---|---:|---:|---|---:|---:|
| 0x59 | 36 | **100%** | 0x66 | 42 | 92% |
| 0x2E | 26 | 97% | 0x1F | 40 | 89% |
| 0x20 | 44 | 97% | 0x27 | 24 | 89% |
| 0x28 | 28 | 95% | 0x22 | 42 | 87% |
| 0x31 | 26 | 84% | 0x1E | 38 | 80% |

Twelve further types are genuinely variable — their length is carried inside the
record, and that is where to look next.

## Fields

Stacking every record of one type and classifying each byte position across the
population (CONST / FLAG / VARY / PTR) gives a layout per type. **The records are
u16 fields**: the layouts are full of VARY-then-`CONST 0x00` pairs, which is a
little-endian u16 whose high byte never sets.

Pointer fields located, with their resolve rate against the 1.79% null:

| type | length | pointer field(s) | resolve |
|---|---:|---|---:|
| 0x10 | 24 | `+0x0C`, `+0x14` | 40%, **100%** |
| 0x1E | 38 | `+0x19` | **100%** |
| 0x20 | 44 | `+0x19` | 97% |
| 0x22 | 42 | `+0x12` | 92% |
| 0x27 | 24 | `+0x10`, `+0x14` | 26%, **100%** |

⚠ `+0x19` is an ODD offset. These are packed records in a byte-addressed ROM, so
an unaligned u32 is expected rather than suspicious, but it is worth stating
because it rules out reading the record as an array of aligned words.

## The control, and two versions of it that could not fail

The claim is "records of a given type share a field layout". The null is
"arbitrary equal-length chunks cut from the same blobs share one". Sampling
chunk starts uniformly from the blob bytes gives **0 CONST positions against
10–29 for every real type** — the layouts are real.

⚠ Two earlier controls were incapable of failing, and I ran both. Each shifted
every record by a constant (first 2, then 1 and 3) on the theory that wrong
framing should destroy the structure. Shifting the whole population identically
only RELABELS the columns; the alignment BETWEEN records — the entire thing under
test — is untouched. Both duly reported "20 CONST vs 20 real", and I first read
that as a weak control rather than as no control at all. The shift-by-2 version
was additionally doomed by the finding itself: the records are u16, so a 2-byte
shift preserves exactly the alignment it was meant to break.

## What this does not settle

Field MEANINGS. A `CONST 0x00` at `+0x1D` is a fact about the format, not a name
for it. The next step is to read the field offsets off the code that consumes
these records — the widget dispatch handlers — and attach names to positions.
