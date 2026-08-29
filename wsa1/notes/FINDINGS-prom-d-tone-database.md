# prom_d is a TONE DATABASE, and it is the KN5000's design

Measured 2026-08-24 from `original_ROMs/wsa1_prom_d.bin` alone, plus one
cross-reference ROM. Reproduce every number below with

```
python3 scripts/analysis/prom_d_tone_database.py       # asserts, exits non-zero on any failure
python3 scripts/analysis/gen_prom_d_asm.py             # regenerates prom_d/wsa1_prom_d.s
python3 scripts/analysis/assert_byte_identical.py      # THE GATE
```

> ## ★★ CORRECTIONS AND ADDITIONS — wave 7 round 2, 2026-08-29
>
> Reproduced by `python3 notes/prom_d_structures_round2.py` (78 checks, all held).
> Four of §7's open items are closed and one number below is **wrong as written**.
>
> 1. **The descriptor blocks at `+0x30`, `+0x38` and `+0x70` are not "N × 14 + a
>    remainder".** There is no remainder. Each is an **array of 14-byte descriptor
>    records followed by a data pool**, and the boundary is stated by the records
>    themselves: bytes `+0x01` and `+0x05` of a descriptor are 32-bit 0-based file
>    offsets, every non-null one lands past the array and inside the block, and the
>    **smallest of them is exactly where the array ends**.
>
>    | slot | descriptors | header | pool | tiles |
>    |---|---:|---:|---:|---|
>    | `+0x30` | 318 | 4,452 | 29,709 @0x23E9F | 34,161 ✓ |
>    | `+0x38` | 161 | 2,254 | 1,098 @0x4426A | 3,352 ✓ |
>    | `+0x70` | 4 | 56 | 8,772 @0x44B26 | 8,828 ✓ |
>
>    Both ends are pinned: the **last** descriptor's second offset is the last
>    object in its pool (6, 6 and 24 bytes short of the block end). `+0x30`'s 318
>    (part A, part B) pairs **partition** its pool exactly — 0 bytes uncovered, 0
>    covered twice. In `+0x30`, descriptor tag **bit 7** governs the part-B row
>    size: clear in 187 records and then always a multiple of 6, set in 131 and
>    then always a multiple of 8, no exception; the rule is discriminating for 264
>    of the 318 (the other 54 lengths are multiples of 24 and decide nothing).
>    ⚠ `+0x70`'s records are a different class (tag 0x92, null part A) and its
>    objects are multiples of 6 despite bit 7 being set, so the rule is **not**
>    claimed there. So "2440 × 14 + 1", "239 × 14 + 6" and "framing not
>    established" in §1 and §7 are all superseded.
>
> 2. **The "768 extra bytes at `+0x28`" are six 128-byte curves at 0x22A3B.** The
>    index map is 2,048 bytes like its eleven siblings. What says the 768 are a
>    separate object is inside the image: the head word of **every one of the 318**
>    part-A objects of `+0x30` is a 32-bit offset naming one of exactly those six
>    addresses (318/318; no part-B object does), and `+0x38`'s single shared part A
>    names the sixth. Each curve is 128 bytes, starts at 0 and is monotonically
>    non-decreasing; end values 10, 20, 27, 34, 34, 107; curve 0 is exactly
>    `index // 12`. Curves 3 and 4 share their end value **and** their sum but
>    differ in 14 of 128 bytes. ⚠ What the index *means* is not established — 128
>    entries is the MIDI note range, which is suggestive and is not evidence.
>
> 3. **The two 541-byte Drawbar records are not short of anything.** 541 =
>    217 + 4·81 exactly: four element blocks and **zero** wave-select records, and
>    the "172 bytes short" of §3 is precisely the 4 × 43 that are absent. The four
>    blocks match the modal-byte profile of the 451 ordinary element blocks in
>    53–54 of 81 columns (those 451 average 57.2 among themselves) against 20–32
>    for the same windows shifted by ±3, ±5, ±7.
>
> 4. **The five catalogue footers are PARTITIONS, not merely self-sized.** In all
>    five, the *n* group bytes **sum to** the LE16 count, which is the catalogue's
>    row count. The stray `0x08` at 0x50B08 is outside that partition and stays
>    unexplained (it is not the payload's sum8, xor8, or the footer region's sum8).
>
> 5. **⚠ WRONG AS WRITTEN, in §3.** "Bytes +0x00..+0x02 are `7F 7F 7F` and
>    +0x0D..+0x0F are `7D 80 54` in every record inspected" does not hold over the
>    full populations. Measured first record to last:
>    `+0x18` 312/322 and 261/322 · `+0x20` 203/208 and 158/208 · `+0x3C` 64/64 and
>    **18/64**. This is the project's signature failure — a shape read off the
>    first record and quoted as a universal.
>
> 6. **A tie between a NAMED structure here and an instruction still does not
>    exist.** 46 prom_d offsets × 3 encodings × 3 code ROMs produced 5 candidate
>    byte matches; all five are adjudicated false positives by name in §Q5 of the
>    script (two are `ld DE,0x0100` / `or DE,0x0180` in prom_c's EEPROM bit-banger
>    where the third byte of the "LE24" is the next instruction's opcode). The tie
>    to the *image* and its base 0x00F00000 stands, from wave 5.

`prom_d/wsa1_prom_d.s` is no longer one `.incbin`. All 524,288 bytes are now
emitted as `.long` / `.short` / `.byte` / `.ascii` inside labelled regions with
their record geometry stated above them, and it still rebuilds byte-identically.

> **Two shared files still need a one-line edit that this pass deliberately did
> not make**, because three other sessions were converting prom_a/b/c in the same
> working tree at the same time and both files are contested:
> `README.md` still says "`prom_b` and `prom_d` are still one `.incbin` each" and
> its conversion table has no prom_d row; and `scripts/analysis/README.md` has no
> entry for the two scripts this pass added (they are documented at the bottom of
> this file instead). Whoever integrates should fix both.

---

## ⚠ What the gate does NOT certify, stated first

The build gate compares bytes. It is blind to a wrong label and a wrong comment,
and this document leans hard on a cross-reference. So, before anything else:

* **No WSA1 instruction that reads any of these structures has been found.**
  ~~prom_d's base address is not established either (`prom_d/prom_d.ld`).~~ Every
  *name* below is transplanted from the KN5000 slot at the same offset. They are
  hypotheses with a stated basis, not derivations.

  > ★★ **CORRECTED 2026-08-25.** The base IS established: **`0x00F00000` on CPU 2's
  > bus** (`notes/FINDINGS-memory-map.md` §5, from prom_a's remote read of the build
  > tag at `0x00F7FFF0`). And round 7 supplies a CONSUMER of this image's addressing
  > scheme, though not yet of a named structure in it: prom_c's
  > `ExtBoard_ProbeAndInstallBases` stores `0x00F00000` into RAM `0x00D7ED`
  > (`0xFB051E`/`0xFB0523`) and `Voice_SelectKeyZone_Reg0040` relocates three nested
  > 32-bit **0-based offsets** of a voice's tone object against it, ending in a
  > 128-byte key map indexed by the played note and a record array whose first word
  > goes to the tone device's register `chan + 0x0040`
  > (`notes/FINDINGS-prom_c-dev10c-register-meanings.md` §4b,
  > `python3 notes/prom_c_dev10c_meaning_checks.py` section 16).
  > ⚠ The first bullet still stands as written: no instruction has been tied to a
  > structure NAMED BELOW. The tie is to the scheme and the base.
  > ⚠ `prom_d/prom_d.ld` still says "BASE -- NOT ESTABLISHED" with the superseded
  > `0xE80000` hypothesis. It is stale; another lane owns that file.
* **No field meaning is established anywhere in this image.** What is measured is
  shape: entry counts, strides, which spans divide exactly, which populations
  share modal bytes above a null. A stride is a fact about the format, not a name
  for it.
* Where prom_d's content contradicts the KN5000's role for a slot, the label here
  follows the **content**, and the row says so.

---

## 1. The 48-slot directory at file 0x0000

prom_d opens with 48 little-endian 32-bit slots. Every other region in the image
is reached from them, and every value is a **0-based file offset** — prom_d
contains no absolute pointers at all, which is one of the arguments in
`prom_d/prom_d.ld` for reading it as a data flash rather than an execute-in-place
ROM.

The KN5000 has the same table, at the same slot offsets, at its `ToneDB_Base`
(ROM 0x830000). It is documented in
`../kn5000-roms-disasm/table_data/tone_database_directory.s`, and that file is
the source of every "KN5000 label" below.

### Correspondences that hold, and are the reason to trust the transplant

| check | result |
|---|---|
| slot `+0x08` is the tone-record offset table | in **both** |
| slots `+0x9C`/`+0xA0`/`+0xA4` alias `+0x24`/`+0x28`/`+0x2C` | in **both** |
| `+0x18` == `+0x1C`, and `+0x30` == `+0x34` | in **both** |
| tail scalars `+0xD0`,`+0xD4`,`+0xD6`,`+0xD8`,`+0xDA` = 3,3,2,3,2 | **identical** |
| tail scalar `+0xE8` = **426** | **identical** (in the KN5000 that is 21+5·81, its longest tone record) |
| slot `+0x50` is a catalogue of 16-byte named wave rows beginning `Piano L`, `Piano R`, `Mono Piano` | in **both** |
| the 81-byte per-element block inside a tone record | **the same structure** — see §4 |

### Correspondences that do NOT hold, recorded so they are not quietly assumed

| slot | KN5000 | prom_d | note |
|---|---|---|---|
| `+0x04` / `+0x6C` | `+0x04` names the bank map, `+0x6C` a second bank map | `+0x6C` = 0x100 (bank map), `+0x04` = 0x180 (tone-number banks, exactly 0x80 above it) | the same **pair** of tables, but the two slots name opposite ends of it, and prom_d has only one copy |
| `+0x3C` / `+0x40` | unused | a third 64-record array of 43-byte wave-select records | prom_d uses two slots the KN5000 leaves empty |
| `+0x88` | the scalar **338** (a DSP1 stream-index bias) | `0x125` | **unresolved.** 0x125 is both a plausible scalar (293) and a valid file offset. 293 exceeds the 274-entry offset table, so the KN5000's reading does not carry over. Nothing here decides it. |
| `+0xA8` | unused | 0x0FC8, eight 128-byte records | no name to transplant, and none is invented |
| `+0xB0` | `PercName_Pack` (packed 10-char names) | a 713-byte 4-element tone record named `     Clear      ` | different content, so the KN5000 name is **not** used |
| `+0xB4` | unused | one 150-byte drum-instrument record named `Silent       ` | byte-identical to drum-instrument record 0 |
| `+0xE0`, `+0xEA`, `+0xEC`, `+0xEE`, `+0xF0`, `+0xF2` | 28, 11, 15, 58, 11, 15 | 24, **43**, 14, **150**, 43, 14 | same *slots*, different values. Two of prom_d's are independently confirmed by its own geometry: 43 is the wave-select record size and 150 is the drum-instrument record size |

### Full slot table

| slot | value | size | what it is here | KN5000 label |
|---|---|---:|---|---|
| `+0x00` | `0xFFFFFFFF` | — | unused | unused |
| `+0x04` | `0x00180` | 2560 | **ToneDB_ToneNumBanks** — 10 × 128 LE16 | `ToneDB_BankMap_Main` |
| `+0x08` | `0x00B80` | 1096 | **ToneDB_ToneOffsetTable** — 274 LE32 | `ToneDB_ToneOffsetTable` |
| `+0x0C` | `0x1C965` | 2048 | ToneDB_ToneIndexMapA — 1024 LE16 | same |
| `+0x10` | `0x1D165` | 2048 | ToneDB_ToneIndexMapB — 1024 LE16 | same |
| `+0x14` | `0x2DF5C` | 2048 | ToneDB_PercSourceIndexMapA — 1024 LE16 | same |
| `+0x18` | `0x1D965` | 13846 | **ToneDB_MixerDefaultTable** — 322 × 43 | same |
| `+0x1C` | `0x1D965` | — | alias of `+0x18` | same |
| `+0x20` | `0x416AC` | 8944 | **ToneDB_PercMixerDefaultTable** — 208 × 43 | same |
| `+0x24` | `0x21A3B` | 2048 | ToneDB_ToneIndexMapC — 1024 LE16 | same |
| `+0x28` | `0x2223B` | 2816 | ToneDB_ToneIndexMapD — 1024 LE16 **+ 768 bytes unaccounted** | same |
| `+0x2C` | `0x2E75C` | 2048 | ToneDB_DrumToneIndexMap — 1024 LE16 | same |
| `+0x30` | `0x22D3B` | 34161 | ToneDB_EnvDescTable — 2440 × 14 + 1 | same |
| `+0x34` | `0x22D3B` | — | alias of `+0x30` | same |
| `+0x38` | `0x4399C` | 3352 | ToneDB_EnvDescTable, percussion family — 239 × 14 + 6 | same block in the KN5000 |
| `+0x3C` | `0x20F7B` | 2752 | **ToneDB_MixerDefaultTable_3C** — 64 × 43 | *unused* |
| `+0x40` | `0x20F7B` | — | alias of `+0x3C` | *unused* |
| `+0x44` | `0x4809A` | 2048 | ToneDB_SourceIndexMapA — 1024 LE16 | same |
| `+0x48` | `0x4889A` | 2048 | ToneDB_SourceIndexMapB — 1024 LE16 | same |
| `+0x4C` | `0x4F0DC` | 2048 | ToneDB_PercSourceIndexMapB — 1024 LE16 | same |
| `+0x50` | `0x46D6A` | 4912 | **ToneDB_SourceNameList1** — 307 × 16 | same |
| `+0x54` | `0x4909A` | 18 | ToneDB_SourceList1_Footer — count **307** | same |
| `+0x58` | `0x4A44C` | 2048 | ToneDB_SourceIndexMapC — 1024 LE16 | same |
| `+0x5C` | `0x4AC4C` | 2048 | ToneDB_SourceIndexMapD — 1024 LE16 | same |
| `+0x60` | `0x502FA` | 2048 | ToneDB_PercSourceIndexMapC — 1024 LE16 | same |
| `+0x64` | `0x490AC` | 5024 | **ToneDB_SourceNameList2** — 314 × 16 | same |
| `+0x68` | `0x4B44C` | 18 | ToneDB_SourceList2_Footer — count **314** | same |
| `+0x6C` | `0x00100` | 128 | **ToneDB_BankMap** | `ToneDB_BankMap_Coeff` |
| `+0x70` | `0x44AEE` | 8828 | DrawbarPreset_EnvDescTable — **framing not established** | same |
| `+0x74` | `0x2CF5C` | 4096 | DrumKit_NoteMapA — 2048 LE16 | same |
| `+0x78` | `0x2EF5C` | 75600 | **PercInst** — 504 × 150 | `PercInst_000_Silent` |
| `+0x7C` | `0x4D3CE` | 4096 | DrumKit_NoteMapB — 2048 LE16 | same |
| `+0x80` | `0x4B45E` | 8048 | **ToneDB_DrumSourceNameList** — 503 × 16 | same |
| `+0x84` | `0x4E3CE` | 14 | ToneDB_DrumList_Footer — count **503** | same |
| `+0x88` | `0x00125` | — | **unresolved: scalar 293, or an offset** | scalar 338 |
| `+0x8C` | `0x4E3DC` | 3328 | **ToneDB_PercSourceNameList1** — 208 × 16 | same |
| `+0x90` | `0x4F8DC` | 14 | ToneDB_PercList1_Footer — count **208** | same |
| `+0x94` | `0x4F8EA` | 2576 | **ToneDB_PercSourceNameList2** — 161 × 16 | same |
| `+0x98` | `0x50AFA` | 14 (+1) | ToneDB_PercList2_Footer — count **161** | same |
| `+0x9C`/`+0xA0`/`+0xA4` | | — | aliases of `+0x24`/`+0x28`/`+0x2C` | identical aliasing |
| `+0xA8` | `0x00FC8` | 1024 | **Unk_0FC8_Table** — 8 × 128, purpose unknown | *unused* |
| `+0xAC` | `0x1C58A` | 124 | **ToneDB_DefaultLayerParams** — 81 + 43 | same |
| `+0xB0` | `0x1C606` | 713 | tone-record template `Clear` | `PercName_Pack` (**different**) |
| `+0xB4` | `0x1C8CF` | 150 | drum-instrument template `Silent` | *unused* |
| `+0xB8`/`+0xBC` | `0xFFFFFFFF` | — | unused | unused |

---

## 2. The tone lookup path

```
   bank selector ──► ToneDB_BankMap[sel]          (0x0100, 128 bytes)
                          │ = row r
   program 0..127 ──► ToneDB_ToneNumBanks[r][prog] (0x0180, 10 × 128 LE16)
                          │ = tone index 0..273
                     ToneDB_ToneOffsetTable[tone]  (0x0B80, 274 LE32)
                          │ = file offset
                     the tone record; its first 16 bytes are the displayed name
```

This is the KN5000's documented walk (`ToneDB_Find_PatchRecord`) with the same
tables at the same directory slots and — for the bank map and the tone-number
banks — at the *same file offsets*, 0x100 and 0x180.

**The bank map resolves only ten selectors**: 0..7 → rows 0..7, 0x20 → row 8,
0x27 → row 9. Every other entry is 0.

**Rows 0–7 name only melodic tones** (index 0x000–0x0FF) and **rows 8–9 name only
drum kits** (0x100–0x111), over all 1280 entries. So the ten rows are eight
melodic variation banks plus two drum banks.

**The program order is NOT General MIDI.** Row 0 program 1 is `Honky-Tonk Piano`
where GM has Bright Acoustic Piano; programs 32–39 are Harp / Banjo / Harp /
Mandolin / Shamisen / Koto / Sitar / Kalimba where GM has the bass family. It is
a Technics-internal ordering, and nothing measured here says which panel control
it corresponds to.

**274 tones**, all offsets distinct, all landing on 16 printable bytes:
256 melodic (`     Piano      ` … `    Gun Shot    `) and 18 drum kits
(`   Jazz Kit     ` … `GM Orchestra Kit`).

---

## 3. The tone-record layout — 217 + N·(81+43)

```
    +0x000   16 B   name, ASCII, space-padded and centred
    +0x010    1 B   record-type byte (see below)
    +0x011    1 B   ELEMENT MASK -- four 2-bit fields, one per element slot
    +0x012  199 B   common part, fields unidentified
    +0x0D9   81·N   N element blocks
   +81·N     43·N   N wave-select records
```

Total 217 + N·124 → **341 / 465 / 589 / 713** for N = 1..4. Population: 110 / 93
/ 49 / 2 records.

**The element mask is real, not decorative.** Byte `+0x11` partitions the 253
fixed-layout records by N with *no value shared between two different N*:

| N | observed `+0x11` |
|---|---|
| 1 | `0x01` |
| 2 | `0x05`, `0x11`, `0x41` |
| 3 | `0x15`, `0x45`, `0x51` |
| 4 | `0x55` |

Read as four 2-bit fields, the number of set fields **is** N in every record. The
element data is stored packed (N entries), while the mask says which of the four
slots those entries occupy.

### Byte `+0x10` is a record-type byte, and the KN5000 branches on the same one

Not identified, but not free either:

| `+0x10` | population |
|---|---|
| `0x80` | all **18** drum kits, and no melodic record |
| `0x10` | 248 of the 254 melodic records |
| `0x00` | 6 melodic records |
| `0x71` | the two Drawbar records |

The KN5000's sub-CPU branches on **bits 7:6 of the same byte of its own tone
record** — `../kn5000-roms-disasm/symbols/proposals/subcpu-region-12.txt:136`:
"bits 7:6 of tonerec[+0x10] … 0x80 or 0 → next part, tonerec type 0xC0 → call
`VoiceSlot_FullInit`, tonerec type 0x40 → `Voice_PortamentoTargets_SetAll` then
`VoiceSlot_AltInit`". Its own records hold 0/16/32/48 there, i.e. bits 7:6 = 00
in 578 of 579. **That is the KN5000's code, not this machine's** — it is recorded
because it says which byte to look at first when a WSA1 consumer is finally
found, not because it decodes the WSA1.

### The KN5000 has the same mask, off by one

The KN5000 tone record carries the same 4×2-bit field at the same offset `+0x11`,
but its set-field count is **N−1**, not N — it has an implicit first element:

| N | KN5000 `+0x11` | set fields |
|---|---|---:|
| 1 | `0x00` (25 records) | 0 |
| 2 | `0x01` (247) | 1 |
| 3 | `0x05`, `0x11`, `0x41` (170) | 2 |
| 4 | `0x15`, `0x45`, `0x51` (77) | 3 |

519 of 519 records with no exception. ⚠ The rule **breaks** for the KN5000's
426-byte "N=5" class: 37 of those 60 records carry a mask with fewer than four
set fields, so that size class — measured, like all of them, as
distance-to-next-record — is not trustworthy as "five elements". The WSA1 has no
N=5 class, so nothing here depends on resolving that.

### The 124 cuts as 81 + 43, and this was under-evidenced before

`../technics_roms/tools/wsa1_rom_anatomy.py` prints "217 + N*124 → a 217-byte
common part + N tone layers" and that was judged under-evidenced. It is now
established, three independent ways:

1. **Split sweep.** Cut the 124-byte per-element budget as W + (124−W) for
   W = 20..104, stack all element blocks and all remainder blocks across the
   whole population, and score by total column entropy. W = 81 scores **221.1
   bits**; the next best W scores **324.2** — a 103-bit gap, with no other local
   minimum. The worst W scores 374.4.
2. **The arrays are separate, not interleaved.** Reading the body as
   `A0 B0 A1 B1 …` (a contiguous 124-byte layer) costs a further **117 bits**.
   The image stores all N element blocks first, then all N wave-select records.
3. **The directory says 43, and there is a one-of-each specimen.** The directory
   word at `+0xEA` is **43** — the KN5000 reads the same word as its wave-select
   record stride. And directory slot `+0xAC` points at a block that is *exactly*
   124 bytes: one 81-byte element block followed by one 43-byte wave-select
   record, which is what `ToneDB_DefaultLayerParams` is in the KN5000 too.

### The 43-byte wave-select record

The same record appears in four places: the second per-element array of every
tone record, the tail of `ToneDB_DefaultLayerParams`, and three standalone arrays
at slots `+0x18` (322 records), `+0x20` (208) and `+0x3C` (64) — each of whose
spans divides by 43 **exactly**. ~~Bytes +0x00..+0x02 are `7F 7F 7F` and
+0x0D..+0x0F are `7D 80 54` in every record inspected~~ — **RETRACTED, see
correction 5 at the head of this file**: the true counts are 312/322, 203/208,
64/64 and 261/322, 158/208, 18/64. No consumer has been read and no field is named.

### The two Drawbar records — an open discrepancy, not smoothed over

Tone indices 0x058 and 0x059, `<<< Drawbar 1>>>` and `<<< Drawbar 2>>>`, live
apart from the rest at 0x446B4 and are **541 bytes** each. 541 − 217 = 324, which
is not a multiple of 124. Their element mask is `0x55` — all four slots — and
217 + 4·124 = 713, so they are 172 bytes short of the layout their own mask
implies. Emitted as bytes. Left open.

---

## 4. The 81-byte element block is the KN5000's, measured

The KN5000's tone records are documented as **21 + 81·N**
(`../kn5000-roms-disasm/analysis/disk-format-probes/README-lsw-voice-selector-names.md`),
and re-measuring its 629-entry offset table confirms it: sizes 102/183/264/345/426
= 21 + 81·N for N = 1..5.

Stack every element block from both machines and compare the modal byte of each
of the 81 columns:

| | columns sharing the modal byte, of 81 |
|---|---|
| **aligned** (1637 KN5000 blocks vs 451 WSA1 blocks) | **63** |
| byte-shift nulls (±1,2,3,5,8,13,21,40) | 18 – 29 |
| rotation nulls (+1,2,3,7,11,17,29,40) | 19 – 28 |

Of the 34 columns whose KN5000 modal byte is non-zero — the ones a "both are
mostly 0x00" objection cannot explain — **24 still agree**, including
col 1 = `0x40`, col 7 = `0x32`, cols 9/11/13/15 = `0x1E`, col 19 = `0x42`,
col 25 = `0x60`, cols 26/48/57/73 = `0x42`, cols 27/49 = `0x18`,
cols 32/33/36/37/50/59 = `0x7F`, cols 40/77 = `0x64`, col 46 = `0x08`,
col 54 = `0x61`.

**So the WSA1 and the KN5000 share the per-element voice parameter block.** What
differs is the head (217 B here against 21 B there) and the extra per-element
43-byte wave-select array, which the KN5000's tone record does not have.

This is the same family result the code side already has: `kn5000_shared_runs.py`
puts 28,916 of 32,795 shared code bytes in **prom_c**, i.e. WSA1 CPU 2 and the
KN5000 sub-CPU are the same design. The data format follows the controller.

---

## 5. Drum kits and drum instruments

**18 drum-kit records of 408 bytes**, tone indices 0x100–0x111:

```
    +0x000   16 B   name
    +0x010  136 B   common part
    +0x098  128 × LE16   one entry per MIDI note 0..127
```

The head is *related* to the melodic tone-record head without being the same
structure. The 8-byte token `11 00 01 63 1E 06 00 54` sits at melodic record
+138 (246 of 254) and at drum-kit record +82 (18 of 18) — the drum head reaches
that landmark **56 bytes earlier**. Past it the two agree: **55 of 70** columns
share a modal byte, against 17–27 for every shift null. But the melodic head runs
79 bytes past the landmark and the drum head only 70, so they are not
interchangeable.

**504 drum-instrument records of 150 bytes** at slot `+0x78`, stride taken from
the directory's own word at `+0xEE`; 75,600 / 150 divides exactly and all 504
start with 13 printable bytes (`Rock Bass Drm`, `Room BassDrm1`, `Slap Shot`).
The KN5000 slot `+0x78` holds the same thing with stride 58.

The chain that is **not** confirmed: a kit's per-note LE16 runs up to 0x0530,
past the 504 records, so it is not a direct index into them. It is consistent
with an index into `DrumKit_NoteMapA`/`B` (slots `+0x74`/`+0x7C`, 2048 LE16 each,
whose values *are* all valid drum-instrument indices, max 503), but no code has
been read that performs that step.

---

## 6. The wave catalogues, and the footer that proves their sizes

Five catalogues of 16-byte rows — 13 ASCII characters then 3 bytes:

| slot | rows | first rows | footer slot | footer's LE16 |
|---|---:|---|---|---:|
| `+0x50` | 307 | `Piano L`, `Piano R`, `Mono Piano` | `+0x54` | **307** |
| `+0x64` | 314 | `Piano L`, `Piano R`, `Mono Piano` | `+0x68` | **314** |
| `+0x80` | 503 | `Silent`, `Rock Bass Drm`, `Room BassDrm1` | `+0x84` | **503** |
| `+0x8C` | 208 | `Silent`, `Square Wave`, `Rock Bass Drm` | `+0x90` | **208** |
| `+0x94` | 161 | `Silent`, `Square Wave`, `Rock Bass Drm` | `+0x98` | **161** |

Each "footer" block (the KN5000 calls these `..._Footer`, slots `+0x54`, `+0x68`,
`+0x84`, `+0x90`, `+0x98`) is **self-sized**: LE16 value, one length byte n, then
n bytes. The LE16 is the row count of its catalogue in all five cases. That is a
genuine internal cross-check — the counts in the table above were first derived
from span/16 and the footers agree with all five independently.

Four of the twelve 1024-entry LE16 index maps close the loop the same way: the
maximum value of `+0x48` is 306 = 307−1, of `+0x5C` is 313 = 314−1, of `+0x14`
is 207 = 208−1, and of `+0x2C` and `+0x60` is 160 = 161−1. Each map tops out
exactly one below the catalogue its directory neighbour declares.

What the maps *select* is still not established; the value ranges are recorded
because they pin which array each map can possibly address:

| slot | max value | distinct | plausibly addresses |
|---|---:|---:|---|
| `+0x0C` | 321 | 196 | the 322-record wave-select array at `+0x18` |
| `+0x10` | 316 | 125 | same |
| `+0x24` | 316 | 192 | same |
| `+0x28` | 317 | 125 | same |
| `+0x14` | 207 | 208 | the 208-row catalogue at `+0x8C` |
| `+0x4C` | 207 | 208 | same |
| `+0x2C` | 160 | 161 | the 161-row catalogue at `+0x94` |
| `+0x60` | 160 | 161 | same |
| `+0x48` | 306 | 126 | the 307-row catalogue at `+0x50` |
| `+0x5C` | 313 | 126 | the 314-row catalogue at `+0x64` |
| `+0x44` | 181 | 182 | a subset of the `+0x50` catalogue |
| `+0x58` | 188 | 189 | a subset of the `+0x64` catalogue |

---

## 7. What resisted, and is flagged rather than guessed

* ⚠ **SUPERSEDED IN WAVE 7 ROUND 2 — the remainder does not exist.** The bullet
  below concluded "supported-not-proved" because nothing placed the leftover
  byte(s). There is no leftover: each block is an ARRAY of 14-byte descriptors
  followed by a DATA POOL, and the descriptors' own 32-bit offsets say where the
  array stops (the smallest of them is exactly the array's end, and the last
  one's part B is the last object in the pool, so both ends are pinned).
  Re-derived on every run of the generator by
  `notes/prom_d_structures_round2.py`, which refuses to emit if a boundary moved.
  The text is kept below because the *reasoning* it records — the entropy sweep,
  and why it was not enough — is worth keeping.
* **The descriptor blocks at `+0x30`, `+0x38`, `+0x70`.** The directory's stride
  words `+0xEC`/`+0xF2` are 14, and each block *starts* with clean 14-byte
  records (`40 9F 3E 02 00 AE 3E 02 00 00 7F 42 80 42` then `40 B4 3E 02 00 C3
  …`). A stride sweep over 10..19 scoring column entropy picks 14 for `+0x30`
  (4.649 against ≥4.76 for every neighbour) and for `+0x38` (2.209 against ≥3.38).
  But `+0x30`'s span is 2440·14 **+ 1**, `+0x38`'s is 239·14 **+ 6**, and `+0x70`
  is worse: its sweep prefers periods that are multiples of 6, and the block
  visibly switches to 6-byte rows at 0x44B26 (`8A 00 00 80 00 00 | 8A 00 00 A6 00
  00 | …`). A leading-tag-byte framing was tried and **fails** — 2222 of 8828
  bytes have bit 7 set. Emitted on a 14-byte grid for readability, labelled as
  supported-not-proved.
* ⚠ **SUPERSEDED IN WAVE 7 ROUND 2 — the 768 extra bytes at `+0x28` are not part
  of that map.** They are `ToneDB_DescCurveBank`: six 128-byte non-decreasing
  curves. What says so is inside the image — the head word of every one of the
  318 part-A objects in the `+0x30` descriptor pool is a 32-bit file offset
  naming one of exactly these six addresses. In wave 7 round 5 the six were
  renamed from `ToneDB_DescCurve_0..5` to names derived from their own run
  lengths (`Step12`, `Step6`, `Step4`, `Step3`, `Step4And2`, `Step1`);
  `notes/prom_d_understanding_round5.py` Q3.
* **`Unk_0FC8_Table` at `+0xA8`.** Eight 128-byte records, almost entirely zero:
  the only non-zero bytes sit at record-relative +0x0E, +0x58..+0x5F, +0x7A and
  +0x7E, values 0xF4 (and 0x0C at +0x7A in five of the eight), repeating on a
  0x80 grid in all eight records. The KN5000 leaves this slot unused, so there is
  no name to transplant and none is invented. ★ Round 5 adds the two facts a
  per-record label cannot carry: the eight records are only **three** distinct
  byte strings ({0,4,5,6,7}, {1,3}, {2}), and **0 of the 1,024 bytes are
  printable**, so the round-4 "the record contains its own name" mechanism has
  nothing to work with here.
* **Directory slot `+0x88` = 0x125.** Scalar or offset — see §1.
* **One stray byte.** The `+0x98` footer is 14 bytes (`3 + 11`, consistent with
  the other four), and then there is a single 0x08 at 0x50B08 before the erased
  region begins. Unaccounted for.

---

## 8. The tail

The payload's last byte is at **0x50B08**. From 0x50B09 to 0x7FFEF the image is
one unbroken 0xFF run of 0x2F4E7 bytes, then the 16-byte build tag
`wsad_54.ssf` + five NULs. That erased-flash shape is the strongest single
argument in `prom_d/prom_d.ld` for reading this image as a FLASH device rather
than a mask ROM. ⚠ **That file's `0xE80000` placement is superseded**: the base is
`0x00F00000` (`notes/FINDINGS-memory-map.md` §5). "Erased flash" survives; "at
0xE80000" does not. prom_d's `ORIGIN` correctly stays 0 either way, because this
image is addressed by 0-based offsets and holds no absolute pointers.

---

## 9. Wave 7 round 5 — which of the remaining framed labels could be named at all

Round 4 took prom_d from 44.5% to 83.0% content on
`notes/wave7_documentation_metrics.py` by rewriting 778 record labels as the camel
form of each record's **own** ASCII name field. 622 labels were left FRAMED — a
kind plus a number. Round 5 asked the only honest first question about those 622:
**which of them sit on an object that carries a name, and which genuinely have
none?** `notes/prom_d_understanding_round5.py` (65 checks) answers it:

| labels | object | verdict |
|---|---|---|
| 594 | 43-byte wave-select records (`+0x18`, `+0x20`, `+0x3C`) | **no name field.** Widest printable run in any record: 4, 4, 5 bytes, against the 13 of the narrowest name field this image uses. Stay framed |
| 10 | program-map rows (128 LE16 each) | no name field, but **2 of the 10 are named by what they select** |
| 8 | `Unk_0FC8` records | no name field; 0 printable bytes of 1,024 |
| 6 | descriptor curves | no name field, but **each states its own shape** |
| 3 | `+0x70` pool objects | the round-4 refusal, re-measured and still refused |
| 1 | `ToneRec_05D_161` | ★ a **metric artefact**: this record IS named from its own bytes, `"    16' & 1'    "`, and the camel form of an organ registration is all digits. NOT renamed — the camel rule is round 4's and an independent reviewer re-derived all 778 names with it at 0 mismatches |

**8 of the 622 promoted, 614 left framed with the gap stated.** That is the
correct output, and the gaps are not empty:

* **`ToneNumBank_DrumKits` / `ToneNumBank_SpecialSound`** (rows 8 and 9). All 128
  entries of row 8 name a tone record whose own name ends in `Kit`; row 9 holds
  `Jazz Kit` 127 times and, at program 127, tone 0x110 `' Special sound '`, which
  no other row in all 1,280 entries selects. Rows 0-7 keep `Melodic_<r>`: what
  they share is measured (no entry ≥ 256 in any of the 1,024) and it is not enough
  to tell them apart; they differ from row 0 in 36/37/25/18/9/9/6 of 128 entries
  and nothing in the image says what that variation means.
* **The six curves** are named from their own run lengths by a rule, not by hand:
  strict plurality → `Step<n>`, two-way tie → `Step<hi>And<lo>`, which is why
  curve 4 (interior 4,2,2,4; 4 and 2 occur 14 times each) is `Step4And2`. Their
  interiors are periodic with period 12, splitting each block into 1/2/3/4/4/12
  zones. ⚠ 12 is **not** claimed to be an octave and the domain is **not** claimed
  to be a note number.

### ★★ The one positive result that is not a naming: field `+0x0B`

Every wave-select banner ended `⚠ NOT established: what any of the 43 bytes
means, or what the head/tail split is FOR`. Both halves are now wrong, and the
text is corrected rather than left standing. prom_c's `sub_FBC725`:

    0xFBC741  ld A,(XBC+0x0b)       the record's field +0x0B
    0xFBC744  and A,0x3f            its LOW 6 BITS
    0xFBC74C  cp WA,0 / jr NZ       0 takes a different arm entirely
    0xFBC7B6  ld XIY,(XWA+0x3c)     the +0x3C array
    0xFBC7C3  mul XIY,(XIZ+0xf2)    * that 6-bit value
    0xFBC7D6  ld (XWA+0x0b),H       the chosen record's +0x0B, written back
    0xFBC7D9..0xFBC805              then bytes 13..42, copied over

Six bits addresses 64 values and the array holds exactly 64 records. **And the
array confirms it without the code**: its record N carries N in the low 6 bits of
its own `+0x0B`, 63 of 64 — the exception is record 0, which index 0 can never
reach because that value takes the other arm. 28 records set bit 6, which the
mask strips. The same self-index test scores 2 of 322 on `+0x18` and 1 of 208 on
`+0x20`. So the block is renamed `ToneDB_MixerDefaultTable_3C` →
**`ToneDB_WaveSelTailPresets`** (the old name was copied from the `+0x18` array's
shape for a slot the KN5000 does not use, i.e. a guess), and the 13/30 head/tail
split has a reason: the tail is exactly what a preset replaces.

### The refusals, and why two of them got stronger

* **`+0x70`'s three pool objects** — re-measured through round 2's own
  segmentation: still 0 part-A objects, so round 4's index chain cannot start.
  Refused.
* **The 161 perc catalogue transfer** — the two maps still agree in 988 of 1,024.
  Refused.
* ★ **The 208 records of `ToneDB_PercMixerDefaultTable`** — this is the new one,
  and it is the strongest refusal the round produced. Two *independent* candidate
  name sources exist: the 208-row catalogue at `+0x8C` taken positionally, and the
  drum-instrument record whose last 43 bytes are **byte-identical** (196 of 208
  have one; 106 have exactly one). Where both exist and are unique they **agree in
  only 45 of 106**. Two derivations that contradict each other are better evidence
  than either alone, and what they are evidence for is that *neither may be used*.
  The byte overlap itself is real and is not retracted; each of the 208 records now
  carries a header naming its carriers.
* **The melodic side has no such overlap at all**: 0 of 322 and 0 of 64 records
  occur anywhere else in the payload.

### The base-address search, which had to come up empty to be worth anything

`prom_d/prom_d.ld` argues ORIGIN 0 is a decision. The way that decision could be
**wrong** is a prom_c instruction carrying the absolute address of a prom_d
object. Over all 76,013 instruction lines of prom_c's converted assembly there is
**exactly one** operand literal in `0x00F00000-0x00F7FFFF`, and it is the base
itself at `0xFB051E`. A raw byte scan finds 84 `ld Xrr,imm32` patterns in that
window; 83 are phantom decodes inside data, 75 of them in the undecoded byte-code
stream at `0xFCD0F7-0xFDD2AA`. ⚠ The search is therefore complete over prom_c's
*instructions* and not over its data, and prom_a cannot contribute a
counter-example (prom_b occupies `0xF00000-0xF7FFFF` on CPU 1's bus; prom_a's one
genuine reach into prom_d, `ld XWA,0x00F7FFF0` at `0xF82A5F`, is the source
argument of a remote block read). ORIGIN 0 stands, now on a search that could have
overturned it. The Q6d null runs the same scanner over `0xE80000-0xEFFFFF` and
finds 15 literals, so the zero is an absence and not a broken scanner.

---

## Scripts added by this pass

Both live in `scripts/analysis/`; `scripts/analysis/README.md` was left alone to
avoid colliding with the other images' concurrent sessions, so their entries are
here instead.

* **`prom_d_tone_database.py`** — *"Is prom_d a tone database of the KN5000's
  design, and what is in it?"* Every number quoted above is produced here and
  every claim that can fail is an `assert`. Reads `original_ROMs/wsa1_prom_d.bin`
  and, for §4 only, `../kn5000-roms-disasm/original_ROMs/kn5000_table_data.rom`.
  Exits non-zero if anything fails. `--quiet` prints only failures.
* **`notes/prom_d_understanding_round5.py`** — *"Which of the 622 still-framed
  labels sit on an object that carries a name at all, and is there any prom_c
  instruction that addresses a prom_d object absolutely?"* 65 checks, ⚠ **run it
  before quoting any number in §9**. Exports `curve_names()`, `row_names()`,
  `perc_overlap()`, `perc_carriers()` and `wavesel_preset_index()` to the
  generator, which **refuses to emit** if any of those shapes moved — both
  refusal paths were exercised deliberately, not assumed.
* **`gen_prom_d_asm.py`** — *"Emit the whole image as structured assembly."*
  Writes `prom_d/wsa1_prom_d.s`. Region boundaries come from the image's own
  directory; the script asserts its region list tiles 0x00000–0x80000 with no gap
  and no overlap before writing. Re-running it must leave the gate green.
  ⚠ **`prom_d/wsa1_prom_d.s` IS GENERATED BY THIS SCRIPT.** A hand-edit to the
  `.s` is silently reverted the next time it runs — which is exactly how a
  corrected false claim came back verbatim in wave 7 round 4. Every prose change
  to prom_d goes in the generator, and a claim is better DERIVED than asserted.
