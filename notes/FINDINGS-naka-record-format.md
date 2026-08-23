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

## ⚠⚠ SCOPE CORRECTION — the sections below describe a DIFFERENT STRUCTURE

Everything from here down documents the **query descriptor** consumed by the
dispatch at `0x00FCCCF8`. I appended it under this document's heading, which
implied it describes the `naka_header` records catalogued above. **It does not.**

MEASURED 2026-08-23, the distribution of the byte at `+0x0C` across the
`naka_header` records, by type:

| type | n | most common `+0x0C` | in the dispatch's 0..6 domain |
|---|---:|---|---:|
| 0x59 | 32 | `0x08` (32) | **0%** |
| 0x2E | 149 | `0x08` (149) | **0%** |
| 0x1F | 163 | `0x08` (163) | **0%** |
| 0x22 | 119 | `0x08` (118) | 0% |
| 0x28 | 42 | `0x18` (42) | **0%** |
| 0x20 | 77 | `0x08` (76) | 1% |

The dispatch does `ld A,(XWA+0x0c) ; cps a,7 ; jr nc` — anything `>= 7` returns
without dispatching. A `naka_header` record has `0x08` there, so **every one of
them would bail out immediately**. They are not this dispatch's input.

Two distinct structures, then:

* the **`naka_header` record** — `XX 00 60 01` header, 2,857 instances, lengths
  and field layouts as measured in the first half of this document;
* the **query descriptor** — whose `+0x0C` is a mode in 0..6 and whose fields are
  documented below.

I flagged twice that nothing related a record's TYPE to the dispatch's MODE and
that they were different fields. That caution was right, and the measurement now
says why: they belong to different structures. The field meanings below are NOT
properties of the `naka_header` records.

⚠ What the query descriptor's own header looks like, and where its instances
live, is NOT established. Finding its callers is the next step.

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

### What the state blocks ARE: the live panel memory (2026-08-23)

The mode-1/3/4/5/6 handlers all index `0x00EE1160` to get a state block. Reading
that table:

```
 [ 0] 0x0000F9B6    [ 1] 0x0000F9D0    [ 2] 0x0000F9EA   ...   [22] 0x0000FBF2
```

**23 consecutive entries, stride exactly 0x1A = 26 bytes**, spanning
`0x00F9B6..0x00FBF2` (598 B), followed by `0xFD62`, `0xFD7C`, `0xFC0C` and then
zeros.

These are LOW addresses — work DRAM, not ROM. And the range is not arbitrary.
`docs/kn-disk-file-formats.md` records the `.LSW` panel-memory layout, verified
in an earlier pass:

> writes 0xE40 in four parts (32-byte header from `0xF980`, **TLV block 0 from
> `0xF9A0`**, **TLV block 1 from `0xFD60`**, and 0x800 from `0x1E7800`)

and `kn7000_mame/notes/FINDINGS-kn5000-splash-restored.md` records that
`DRAM[0xF980..0xFFEE]` is copied to the IC21 battery-backed SRAM at power-down.

So:

| state-block entry | lands in | offset into it |
|---|---|---|
| `0xF9B6` … `0xFBF2` (23 blocks) | **`.LSW` TLV block 0** (from `0xF9A0`) | +0x16 |
| `0xFD62`, `0xFD7C` | **`.LSW` TLV block 1** (from `0xFD60`) | +0x02 |

**The NAKA widget query descriptors read the live panel memory** — the same bytes
the instrument writes into a `.LSW` file and preserves across a power cycle in
battery-backed SRAM. A widget asking "what should I display" is reading persisted
instrument state through a 26-byte-strided block array.

That ties three separate investigations together: the NAKA record format (here),
the `.LSW` disk format, and the power-down/restore path.

⚠ VERIFIED, not inferred: the table contents are read from the ROM at
`0x00EE1160`; the `.LSW` part offsets are quoted from the disk-format document,
which records them as directly dumped; the persistence range is quoted from the
splash findings. What is NOT established is the 26-byte block's own field layout,
or which block index corresponds to which panel control.

---

## Where the query descriptors come from: a RAM hash table (2026-08-23)

The correction above leaves "where do query descriptors live" open. The code
immediately before the dispatch answers it
(`v7/maincpu/boot/interrupt_vector_trampolines.s:30-66`):

```asm
	ld   XBC,0x000007ff
	call 0xff0435              ; XWA mod XBC -> HL   (a MODULO, not a hash)
	ld   IX,HL
.Lc_fccce0:
	ld   BC,IX
	extz XBC
	sll  XBC, 0x03             ; bucket index x 8
	ld   XWA,0x00034100        ; TABLE BASE, in work RAM
	add  XWA,XBC
	ld   XDE,(XWA)             ; entry +0x00 = the KEY
	cp   XDE,0x00ffffff        ; 0x00FFFFFF = EMPTY slot
	jr   nz, .Lc_fcccb4
.Lc_fcccb4:
	cp   XIZ,XDE               ; XIZ = the key being searched for
	jr   z, .Lc_fcccbf
	...
.Lc_fcccbf:
	ld   XWA,(XWA+0x04)        ; entry +0x04 = POINTER TO THE DESCRIPTOR
	ld   (XSP+0x06),XWA        ; -> becomes the dispatch's argument
.Lc_fccccb:
	inc  1,HL                  ; LINEAR PROBE
	cp   HL,0x07ff
	jr   ugt, .Lc_fcccf8       ; ran off the end -> give up
	ld   WA,IX
	inc  3,WA                  ; step 3
	extz XWA
	div  WA,0x07ff             ; wrap modulo 0x7FF
	ld   IX,QWA
```

### The structure

| property | value |
|---|---|
| base | `0x00034100`, work RAM |
| buckets | `0x7FF` = 2047 |
| entry size | **8 bytes** (`sll XBC,0x03`) |
| table size | 2047 x 8 = 16,376 B |
| entry `+0x00` | u32 key; `0x00FFFFFF` means EMPTY |
| entry `+0x04` | u32 pointer to a **query descriptor** |
| lookup | `bucket = key mod 0x7FF` — see the correction below |
| collision | linear probe with **step 3**, wrapping `div WA,0x07ff`, giving up after `HL > 0x7FF` |

So the full path is:

```
key (XIZ) --hash--> bucket --probe--> entry --+0x04--> query descriptor
                                                          |
                                          +0x0C = mode 0..6
                                                          |
                                    handler --+0x04--> panel-memory block
                                                          |
                                      ((block[+0x05] ^ +0x0A) & +0x06) >> +0x09
```

⚠ A probe step of 3 against a modulus of `0x7FF` (2047 = 23 x 89) is coprime, so
the probe sequence does visit every bucket — worth stating because a badly chosen
step would make the table silently lossy, and that would be a firmware property
worth knowing rather than an artefact of my reading.

### `0x00FF0435` is a 32-bit divide helper, not a hash

⚠ CORRECTION. I described this as "hash via the routine at `0x00FF0435`". It is
a general **32-bit division** routine:

```asm
ff0435:  calr 0xff043b        ; the divide core
ff0438:  ld XHL,XDE           ; return the REMAINDER
ff043a:  ret
ff043b:  cp XBC,0x00000001    ; divisor == 1  -> shortcut
ff0441:  jr Z, ...
ff0443:  jr C, ...            ; divisor == 0  -> error path
ff0445:  cp XWA,XBC
ff0447:  jr ULE, ...          ; dividend <= divisor -> shortcut
ff0449:  cp QBC,0             ; 64-bit path when the high half is set
ff044c:  jr NZ, ...
ff0450:  div XWA,BC
ff0458:  ld HL,WA             ;   HL = QUOTIENT
ff045a:  ld DE,QWA            ;   DE = REMAINDER
```

The core returns quotient in `HL` and remainder in `DE`; the `0xFF0435` wrapper
then does `ld XHL,XDE`, so **it returns `XWA mod XBC`**. With `XBC = 0x7FF` the
call computes `key mod 2047` — the bucket index is a plain modulo, and there is
no hash function in this path at all.

That also makes `0x00FF0435` a reusable library routine worth naming: 32-bit
modulo, with shortcut paths for divisor 1, divisor 0, dividend <= divisor, and a
64-bit dividend.

### The key derivation — there IS a hash, computed inline

⚠ REFINES THE CORRECTION ABOVE. Saying "there is no hash function in this path"
was itself too strong. `0x00FF0435` really is only a modulo — but the hash is
computed INLINE, in the eleven instructions before the call
(`interrupt_vector_trampolines.s:9-31`):

```asm
	ld   XIZ,XWA               ; XIZ = the KEY (the function's 32-bit argument)
	ld   XHL,XIZ
	and  XHL,0x000000ff        ; b0 = key & 0xFF
	ld   XWA,XHL
	sll  XWA, 0x09
	add  XWA,XHL               ; h = b0 * 513        (x<<9 + x)
	ld   XHL,XIZ
	srl  XHL, 0x08
	and  XHL,0x000000ff        ; b1 = (key >> 8) & 0xFF
	add  XHL,XWA               ; h += b1
	ld   XWA,XHL
	sll  XWA, 0x09
	add  XWA,XHL               ; h *= 513
	ld   XHL,XIZ
	srl  XHL, 0x00             ; (shift by zero -- a no-op)
	and  XHL,0x0000001f        ; b2 = key & 0x1F
	add  XHL,XWA               ; h += b2
	ld   XWA,XHL
	ld   XBC,0x000007ff
	call 0xff0435              ; bucket = h mod 2047
```

So the full key schedule is a **base-513 polynomial hash**:

```
h = ((key & 0xFF) * 513 + ((key >> 8) & 0xFF)) * 513 + (key & 0x1F)
bucket = h mod 2047
```

and the KEY is simply the routine's 32-bit argument, preserved in `XIZ` for the
later `cp XIZ,XDE` comparison against each entry's `+0x00`.

⚠ Two oddities worth recording rather than smoothing over. `srl XHL,0x00` shifts
by zero, so the third term re-uses the LOW 5 bits of the key, which the first
term already consumed — the hash mixes bits 0..4 twice and ignores bits 16..31
entirely. And 513 = 0x201, chosen because `x*513` is one shift and one add.

⚠ STILL NOT established: what the key VALUE means (which quantity callers pass),
and who populates the table.

---

## A SECOND dispatch on the same descriptor: `+0x0D`, nine modes (2026-08-23)

Searching the ROM for the table base `0x00034100` gives 10 sites, and one of them
(`0x00FCCA90`) is a second routine over the same hash table — same 2047 buckets,
same 8-byte entries, same `0x00FFFFFF` empty sentinel, same step-3 probe, same
`+0x04` descriptor fetch. It then dispatches on a DIFFERENT field:

```asm
fccad0:  cp  (XSP+0x0a),0x0005      ; a mode argument from the caller
fccad5:  jr  Z, ...
fccad7:  ld  C,(XWA+0x0d)           ; <-- FIELD +0x0D
fccada:  cp  C,0x09
fccadd:  jr  NC, ...                ; bounded 0..8  -> NINE handlers
fccae1:  sla 0x02,BC
fccae4:  lda XDE,0xee10ec           ; second dispatch table
fccaf1:  ld  DE,(XSP+0x0a)          ; args passed through
fccaee:  ld  BC,(XSP+0x0c)
fccaf6:  call T,XHL
fccaf8:  ld  XBC,XHL                ; handler returns a POINTER
fccafa:  cp  (XBC),0xffff           ;   +0x00 == 0xFFFF means invalid
fccb00:  ld  WA,(XBC+0x02)          ;   +0x02 is the value
```

### The two tables are adjacent, and so are their handlers

| table | address | entries | handler range |
|---|---|---:|---|
| `+0x0C` dispatch | `0x00EE10D0` | 7 | `0x00FCD1EC` … `0x00FCD395` |
| `+0x0D` dispatch | `0x00EE10EC` | 9 | `0x00FCD396` … `0x00FCD9E4`+ |

`0xEE10EC - 0xEE10D0 = 0x1C = 7 x 4`, so the second table begins exactly where
the first ends; and `+0x0D` handler 0 starts at `0x00FCD396`, exactly where
`+0x0C` handler 6 finishes. **One 16-handler module in two families**, which is
strong corroboration that both tables were read at their true extents rather than
guessed — the boundaries meet with no gap and no overlap.

### What this means for the descriptor

The query descriptor carries **two independent operation selectors**:

| field | domain | family |
|---|---:|---|
| `+0x0C` | 0..6 | READ — returns a value in `HL`, `0xFFFF` for "none" |
| `+0x0D` | 0..8 | RESOLVE — returns a POINTER to a 4-byte cell (`+0x00` u16 validity, `+0x02` u16 value), taking two caller arguments |

⚠ ESTABLISHED: the two dispatches exist, their domains, their table addresses and
extents, their handler ranges, and the return convention of each.

⚠ NOT ESTABLISHED: the semantics of the nine `+0x0D` handlers (only the dispatch
was read, not the bodies), what the `(XSP+0x0a) == 5` special case does, and what
the two caller arguments are.
