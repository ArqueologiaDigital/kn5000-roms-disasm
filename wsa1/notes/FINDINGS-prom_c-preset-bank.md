# prom_c 0xF80000-0xF97FFF is a PRESET BANK: 16 categories, 129 named 704-byte records

Wave 5, 2026-08-25.  Every number here is produced by

```
python3 notes/gen_prom_c_preset_bank.py --verify    # asserts all of it, exit != 0 on failure
python3 notes/gen_prom_c_preset_bank.py --names     # the 16 category names and the 129 record names
python3 notes/gen_prom_c_preset_bank.py --census    # the per-chunk, per-byte value census
python3 notes/gen_prom_c_preset_bank.py --refs      # the pointer search that found no consumer
python3 scripts/analysis/assert_byte_identical.py   # THE GATE
```

The region is no longer `.incbin`.  It is emitted as `.ascii` / `.short` / `.byte` /
`.fill` in `prom_c/wsa1_prom_c.s` and still rebuilds byte-identically: **91,104
substantive bytes and 7,200 bytes of verified pad**, the largest single unconverted span
this image had.

---

## ⚠ What is NOT established, stated first

* **No instruction that reads this region has been found.**  A search of all four images
  for a 32-bit little-endian pointer into `0xF80000-0xF97FFF` returns 21 hits in prom_c,
  and `--refs` classifies each one against the disassembly in `prom_c/wsa1_prom_c.s` — a
  hit counts as an OPERAND only if the listed instruction containing it renders that
  value.  **None of the 21 does**: eight fall inside instructions that render something
  else (`ld (xiz-9),13`, `set 5,(PB)`, `cp BC,17`, two `jr`s, two `ld (xiz-4),XBC`), and
  thirteen are in data regions with no listed instruction at all.  prom_a's own code lives
  at those addresses in *its* address space and CPU 1's `0xF80000` is prom_a, so prom_a's
  1,843 hits and prom_b's 576 are ambiguous by construction and prove nothing either way.
* **Not one field meaning is established.**  `--census` gives, for every byte position of
  every chunk, how many distinct values occur across the 129 records and what they are.
  That is a fact about the format.  It is not a name for a parameter.  Nothing in the
  emitted source is called pitch, level or wave.
* The word "preset" comes from the ASCII the region contains — sixteen genre names and
  129 instrument names — and from nothing else.

---

## 1. The shape

| range | bytes | what |
|---|---:|---|
| `0xF80000-0xF8001F` | 32 | header: ASCII `ZZZZ`, u16 0, ASCII `WSA1  `, two directory entries, the record stride |
| `0xF80020-0xF801FF` | 480 | zero pad |
| `0xF80200-0xF802FF` | 256 | 16 category names, 16 bytes each |
| `0xF80300-0xF965BF` | 90,816 | 129 records of 704 bytes |
| `0xF965C0-0xF97FFF` | 6,720 | `0x0E` pad, the same byte this image pads with everywhere |

### The geometry rests on four independent facts

1. **Tiling.**  129 × 704 from `0xF80300` reaches `0xF965C0` exactly, and `0xF965C0` is
   precisely the first byte of the trailing `0x0E` pad.  The byte before it is `0xFF`, so
   the boundary is derived and not chosen.  A wrong stride or a wrong count misses it.
2. **Self-termination.**  Inside every record the chunk walk `{u8 tag, u8 length, length
   bytes}` from `+0x000` arrives at `+0x2BE` carrying tag `0xFF`, length `0xFF` — a
   two-byte end marker that puts the record end at `+0x2C0` = 704.  The stride is readable
   from ONE record without looking at the next.
3. **The header agrees.**  `u32le` at `0xF8001C` is `0x02C0` = 704.  Its two directory
   entries are `(id 1, offset 0x000200, count 16)` and `(id 2, offset 0x000300, count
   128)`.  16 × 16 = 256 tiles `0xF80200..0xF802FF` exactly; 128 × 704 tiles
   `0xF80300..0xF962FF` exactly, and the 129th record follows — the one named `Clear`,
   which is a template rather than one of the 128 the header counts.
4. **Uniform layout.**  All 129 records produce the SAME sequence of 24 `(offset, tag,
   length)` triples.  A single desynchronised record would produce a different list.

> ⚠ **One ambiguity, recorded rather than resolved.**  The directory-entry field split is
> undecidable from these bytes: `{u16 id, u32le offset, u16 count}` and `{u16 id, u16
> offset, u16 zero, u16 count}` give identical bytes, because both offsets fit in 16 bits
> and the following u16 is zero in both entries.

---

## 2. The chunk layout inside a record

Identical in all 129:

| offset | tag | len | what is measured |
|---|---|---:|---|
| `+0x000` | `0x78` | 16 | 16 printable ASCII bytes — the name |
| `+0x012` | `0x60` | 12 | only byte 0 differs between records (0 in 116, 1 in 13) |
| `+0x020` | `0x61` | 30 | bytes 23..29 zero in every record |
| `+0x040` | `0x62` | 30 | bytes 23..29 zero in every record |
| `+0x060` | `0x63` | 30 | bytes 23..29 zero in every record |
| `+0x080` … `+0x260` | `0x00..0x07` paired with `0x20..0x27` | 30 each | eight numbered blocks, two chunks per block |
| `+0x280` | `0x92` | 14 | byte-identical in ALL 129 records: `00 00 80 80 80 80 80 80 80 80 80 80 80 80` |
| `+0x290` | `0x79` | 44 | only byte 5 differs, and in exactly one record (`  Unsure Pitz   `, index 120) |
| `+0x2BE` | `0xFF` | — | end marker |

### The one field that is proven

In **all 1,032** blocks tagged `0x00..0x07` (129 records × 8) the payload byte at `+13`
has its LOW NIBBLE equal to the block's own tag.  That is the block index stored inside
the block, and it is what makes the eight pairs an indexed array rather than eight
unrelated chunks.  Checked for every one, the last included
(`0xF9654F = 0xE7`, record 128 block 7).

Its HIGH nibble takes only two values, `0xC` (424 occurrences) and `0xE` (608).  Exactly
one record has all eight high nibbles `0xE`, and it is the one named `Clear`; every other
record has at least two `0xC`, and none has exactly one.

> [INFERENCE, stated as such] that reads like an in-use flag.  Nothing here proves it, and
> the source says so where it says it.

---

## 3. The names

Sixteen categories, in file order:

```
FUSION COMBO1    JAZZ COMBO       WILD WORLD       HAPPY TIME
STRING ORCHESTRA ORCHESTRAL       VOCAL & ORGAN    BIG BAND
PIANO PAD        PERCUSSIVE PAD   ENSEMBLE PAD     SWEEP PAD
GUITAR STACK     SYNTH STACK      ROCK STAFF       DRUM & EFFECT
```

16 categories and 128 numbered records is 8 per category, but **nothing in the data ties a
record to a category**: a search of all 704 byte positions for a field equal to the record
index, to `index // 8`, to `index % 8`, to `index + 1` or to `index // 16` finds none
(`--verify` runs that search).  If the grouping is positional it is positional by
convention, not by a stored field.

The record names are ordinary instrument and setup names — `  Downtown Set  `,
`ReggaeBass Chord`, `E.Bass/Wah Gtr. `, ` Funky Bassoon  `, `Tango Argentina `,
`Avant-gardeMusic` — and the 129th is `    Clear       `.  `--names` prints all of them
with their addresses.

---

## 4. What a next pass should do with it

* **Find the consumer.**  This is the single most valuable follow-up and it is a *negative*
  today.  Candidates the search cannot see: an address built at run time, or a read by
  CPU 1 over the link's remote-bank mechanism (CPU 1 already reads remote banks 0xE8-0xEC;
  bank 0xF8 is prom_c's own ROM and would be reachable the same way).
* **Tie a block to the 0x0010C000 register file.**  The staging struct that
  `Dev10C_WriteAllChanRegs` moves into the device is 22 words; a record here has eight
  numbered 30-byte block pairs.  Those two shapes are not obviously related and no
  attempt to relate them is made here.  See
  `notes/FINDINGS-prom_c-dev10c-producers.md`, which enumerates what actually writes each
  of those 22 words.
* `0xFCC5BE`'s neighbourhood already showed that constants which *could* have been
  immediates get addresses in this firmware because the routines that send them take
  POINTERS.  The same may be true of these records.

PROVENANCE unchanged: the publicly redistributed v2 firmware set, not a chip read
(`../technics_roms/roms/wsa1/PROVENANCE.md`).

---

## Independently re-derived by the wave-5 audit

The "no reader found" claim above was re-run from scratch by the audit pass: `--refs`
reproduces 21 candidates with 0 operands, and the audit additionally inspected the byte
context of all **13** "data region" hits by hand — six are `00 02 f8 00` inside repeating
`00 02 f8 00 / 7f ff ff 00` quadruples, and `0xFDE05B` / `0xFE0DB9` sit inside u16
arithmetic progressions.  All 13 are coincidences.

⚠ The audit also flagged the wording *"no consumer exists"*, used in a round summary, as
stronger than this evidence.  The defensible form is the one this file already uses:
**no instruction that reads this region has been found**, which is not the same claim.
