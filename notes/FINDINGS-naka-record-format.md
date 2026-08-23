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

---

## Field MEANINGS, read off the consuming code (2026-08-23)

The section above ends by saying field meanings need the code that consumes these
records. Here it is. `v7/maincpu/boot/interrupt_vector_trampolines.s:66`:

```asm
	ld   XWA,(XSP+0x06)        ; XWA = the record pointer (the argument)
	or   XWA,XWA
	jr   z, .Lc_fccd1f         ; null record -> nothing
	ld   A,(XWA+0x0c)          ; <-- FIELD +0x0C
	cps  a, 7
	jr   nc, .Lc_fccd1f        ; bounded: 0..6
	extz WA
	sla  WA, 0x02              ; x4 = u32 table index
	lda_24 xbc, (Naka_MainDispatch_Table_0xDC0)
	lda_dri xbc, 0x07, 0xe4, 0xe0
	ld   XHL,(XBC)
	call (XHL)                 ; dispatch on +0x0C
```

**`+0x0C` is a dispatch selector with domain 0..6**, enforced by the `cps a,7`.
The table is `Naka_MainDispatch_Table + 0xDC0` = `0x00EE10D0`, seven u32:

| sel | handler | note |
|---:|---|---|
| 0 | `0x00FCD1EC` | `ld HL,0xffff ; ret` — the "no result" stub |
| 1 | `0x00FCD1F0` | bit-extraction, below |
| 2 | `0x00FCD22E` | indexes a second table at `0x00EE0180` |
| 3 | `0x00FCD272` | |
| 4 | `0x00FCD2D5` | |
| 5 | `0x00FCD31A` | |
| 6 | `0x00FCD373` | |

### Handler 1 defines six more fields

```asm
fcd1f0:  ld HL,0xffff
fcd1f3:  ld C,(XWA+0x04)      ; <-- +0x04
fcd1f8:  sla 0x02,BC          ;     x4
fcd1fb:  lda XDE,0xee1160     ;     into a u32 table at 0x00EE1160
fcd200:  ld XDE,(XDE+BC)
fcd205:  or XDE,XDE
fcd207:  ret Z                ;     null entry -> 0xFFFF
fcd209:  ld C,(XWA+0x05)      ; <-- +0x05
fcd20e:  ld L,(XDE+BC)        ;     byte index INTO the block just fetched
fcd215:  ld E,(XWA+0x06)      ; <-- +0x06
fcd21a:  ld C,(XWA+0x0a)      ; <-- +0x0A
fcd21f:  xor HL,BC            ;     value ^= +0x0A
fcd221:  and HL,DE            ;     value &= +0x06
fcd223:  ld A,(XWA+0x09)      ; <-- +0x09
fcd226:  and A,0x0f           ;     low nibble only
fcd229:  ret Z                ;     shift 0 -> return as-is
fcd22b:  sra A,HL             ;     value >>= +0x09
fcd22d:  ret
```

So a selector-1 record is a **bit-field extraction descriptor** over a state
block:

| field | width | meaning |
|---|---|---|
| `+0x04` | u8 | index into the block-pointer table at `0x00EE1160` (u32 entries) |
| `+0x05` | u8 | byte offset within the block that entry points to |
| `+0x06` | u8 | AND mask applied after the XOR |
| `+0x09` | u8 | right-shift count, **low nibble only** (`and A,0x0f`) |
| `+0x0A` | u8 | XOR operand, applied before the mask |
| `+0x0C` | u8 | dispatch selector, 0..6 |

Evaluation order is fixed by the code: `((block[+0x05] ^ +0x0A) & +0x06) >> +0x09`,
with `0xFFFF` returned when the block pointer is null and the unshifted value
returned when the shift count is zero.

Selector 2 reads `+0x0B` and indexes a different table (`0x00EE0180`), so
**`+0x0B` is a second selector whose domain belongs to that handler**, not a
global field.

⚠ SCOPE. These meanings are established for records reaching this dispatch, which
selects on `+0x0C`. They are NOT established for every type byte in the census
above — a record's TYPE (the `naka_header` byte) and its DISPATCH SELECTOR
(`+0x0C`) are different fields, and nothing here shows how they relate. Six
handlers remain unread.

⚠ This also does not contradict `+0x0C` being classified PTR for type 0x10 in the
stacked-field table: that classifier reads a u32 at `+0x0C`, this code reads a
BYTE there. Both can hold for different record types, and which types reach this
dispatch is exactly what is not yet established.

### All seven handlers (2026-08-23)

Read from `0x00FCD1EC`–`0x00FCD395`. The record is a **state-query descriptor**
and `+0x0C` picks the query MODE. Three tables are involved:

| table | contents | used by |
|---|---|---|
| `0x00EE1160` | u32 pointers to STATE BLOCKS | modes 1, 3, 4, 5, 6 |
| `0x00EE0180` | u32 pointers, a different block family | mode 2 |
| `0x00EE019C` | u32 pointers to 6-entry u16 VALUE LISTS | mode 4 |

| mode | semantics |
|---:|---|
| 0 | `return 0xFFFF` — the no-op descriptor |
| 1 | `((block[+0x05] ^ +0x0A) & +0x06) >> +0x09`; null block → `0xFFFF`; shift 0 → unshifted |
| 2 | `b = EE0180[+0x0B]`; if `+0x0B == 2`, assemble a 14-bit value from `b[0]` (bit 6 from `b[0]<<6 & 0x40`, plus `(b[0]>>1 & 0x7F)<<7`), clamped: `>= 0x3FC0` → `0x3FFF`; otherwise `b[0] & +0x06` |
| 3 | identical extraction to mode 1, addressed through `XBC` instead of `XWA` |
| 4 | `v = u16 at block[+0x05 * 2]`; scan the 6-entry list `EE019C[+0x0B]` for `v`; return its index, else 0 |
| 5 | if `bit 2 of block[+0x05 + 1]` is set → skip; otherwise the mode-1 extraction |
| 6 | `u16 at block[+0x08] & 0x01FF` — a 9-bit field; ignores `+0x05/+0x06/+0x09/+0x0A` |

### The field table, complete for this dispatch

| field | width | meaning | used by modes |
|---|---|---|---|
| `+0x04` | u8 | state-block selector, index into `0x00EE1160` | 1, 3, 4, 5, 6 |
| `+0x05` | u8 | offset in that block — BYTE for 1/3/5, WORD (×2) for 4 | 1, 3, 4, 5 |
| `+0x06` | u8 | AND mask, applied after the XOR | 1, 2, 3, 5 |
| `+0x09` | u8 | right-shift count, **low nibble only** | 1, 3, 5 |
| `+0x0A` | u8 | XOR operand, applied before the mask | 1, 3, 5 |
| `+0x0B` | u8 | secondary selector — into `0x00EE0180` (mode 2) or `0x00EE019C` (mode 4) | 2, 4 |
| `+0x0C` | u8 | **query mode, 0..6**, bound enforced by `cps a,7` | dispatch |

Modes 1, 3 and 5 share one extraction and differ only in addressing and guard,
which is why `+0x05/+0x06/+0x09/+0x0A` carry the same meaning across all three.
Mode 6 ignores them entirely — a descriptor with mode 6 says nothing about those
bytes, so they are not required to be meaningful in every record.

⚠ STILL NOT ESTABLISHED: what the state blocks at `0x00EE1160` *are*, and how a
record's TYPE (its `naka_header` byte) relates to its MODE (`+0x0C`). Those are
different fields and nothing read so far connects them.
