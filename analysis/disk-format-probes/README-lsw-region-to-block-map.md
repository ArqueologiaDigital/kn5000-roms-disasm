# `.LSW` — which DRAM region lands at which file offset

`docs/IS-IT-DONE.md` item 1 states the gap this answers:

> **Still open:** the handler moves 0x640 + 0x800 bytes and the file is 0x5800, so the
> region-to-block mapping is unread. The next pass has a function to disassemble.

The function was disassembled. There are in fact **three** functions, and the gap closes
because the KN5000 writes one `.LSW` layout and *reads two more*.

```
python3 analysis/disk-format-probes/lsw_region_to_block_map.py                 # ROM side only
python3 analysis/disk-format-probes/lsw_region_to_block_map.py /tmp/disk/*/    # + the seven floppies
python3 analysis/disk-format-probes/lsw_region_to_block_map.py --map /tmp/disk/Bosm/
python3 analysis/disk-format-probes/lsw_region_to_block_map.py --quiet /tmp/disk/*/   # just the gate
```

Corpus (same as the other `.LSW` probes):

    mkdir -p /tmp/disk && cd /tmp/disk
    for z in ~/compartilhado/KN7000/floppy-archive/*.zip; do
        n=$(basename "$z" .zip); mkdir -p "$n"; unzip -o -q -d "$n" "$z"; done

## The three routines

| role | v7 | v9 / v10 |
|---|---|---|
| **writer** `FileIO_SaveRegion0_VRAM` | `F876E9` | `F87AF6` |
| **loader** `FileIO_LoadRegion0_VRAM` — checks the signature, else hands off | — | `F8744F` |
| **header classifier** — `'M','4'`→1, `'M','6'`→2, `'N','N'`→3 | `FD4AD1` | `FD52A2` |
| **importer stage 1** — the current panel | `FD1F9D` | `FD276E` |
| **importer stage 2** — the panel memories | `FD2167` | `FD2938` |

The v7 loader was not located and is not asserted; the writer, the classifier and both
importer stages are, in all three revisions, and they are found by byte signature rather
than by hard-coded address.

## 1. What the KN5000 WRITES: 0xE40 bytes, four parts

The writer is two raw `fwrite`s, no header and no packing (asserted: the two calls go to
the same routine, and the sources are the literals `0x00F980` and `0x001E7800`):

| file offset | size | RAM |
|---|---|---|
| `0x0000` | `0x0020` | `0x00F980..0x00F9A0` — the **32-byte file header** |
| `0x0020` | `0x03C0` | `0x00F9A0..0x00FD60` — TLV block 0, 45 records, `FF FF` at file `+0x3DE` |
| `0x03E0` | `0x0260` | `0x00FD60..0x00FFC0` — TLV block 1, 29 records, `FF FF` at file `+0x63E` |
| `0x0640` | `0x0800` | `0x1E7800..0x1E8000` — the per-style accompaniment voice table |

**The first 32 bytes really are a file header, and that is proved rather than assumed.**
`FileIO_CheckRegionSignature(0)` demands the bytes `"HK"` at **file offset 4** (table at
`0xEA0104`: `{ptr, offset 4, length 2}`), and the factory-default image of the panel work
area — ROM `0xEDB3DC`, 0x20 bytes, copied to `0x00F980`, immediately followed by ROM
`0xEDB3FC`, 0x620 bytes, copied to `0x00F9A0` — reads

    5A 5A 00 00 48 4B 00 00 ...
              ^^^^^ "HK"

so the live panel area *is* a `.LSW` file that satisfies the loader's own check on the
KN5000's own header bytes. The two ROM blobs are contiguous and total exactly `0x640`.

## 2. What the KN5000 READS: also the 22,528-byte "M60" files

When the `"HK"` check fails the loader does **not** give up — it calls
`FileData_AllocLoadAndParse`, which reads the 32-byte header and classifies it on bytes
`[4],[5]`. The seven floppies open `5A 5A 01 00 "M60" 0A`, i.e. `'M','6'` → **format 2**,
which dispatches to a two-stage importer:

* **stage 1** mallocs **0x680** — exactly `0x20 + 0x3D0 + 0x290`, the header plus both
  panel TLV blocks of these files — reads `0x660` after the already-read header, and
  converts 37 records into the live panel area at `0x00F980`;
* **stage 2** then reads **0x300 at a time** into panel memory `0x1ED400 + 960*j`,
  **24 times for format 1 and 10 times for format 2**.

`960 == 0x3C0 ==` the size of TLV block 0, and `(0x200000 - 0x1ED400) / 960 == 80`
exactly — the KN5000 has 80 panel memories and each one is a copy of the live panel block.

### So the 24 slot blocks are PANEL MEMORIES

Stage 2's hard-coded offsets are the 24-slot schema `lsw_slot_schema.py` measured from the
files, to the byte: parts at `24*i` for `i<24`, then `0x240 0x24C 0x258` (tags 44/45/46),
`0x264` (48), `0x270` (90), `0x277` (60), `0x285`/`0x2A5` (61/63), `0x2C5` (70), `0x2CC`
(72), `0x2DC` (92), `0x2EC` (71), `0x2F2` (80), `FF FF` at `0x2FE` → `0x300`. Thirty-seven
constants, thirty-seven tags, all agreeing.

⚠ **This contradicts `docs/kn-disk-file-formats.md`**, which says the 24 blocks are *not*
panel memories ("panel memory has its own extension, and these disks do not carry a
`.PMT`") and calls what they are "NOT established, and deliberately unnamed". The
firmware says otherwise: stage 2 is bracketed by `PrePmLoad` / `PostPmLoad` (`0xFDB490` /
`0xFDB491`) and writes the panel-memory array. Those paragraphs need retracting; this
probe is the evidence. Not edited here only because this session was forbidden to touch
existing files.

⚠ Also contradicted: *"no dumped firmware validates the `.LSW` header"* and *"no KN5000
code has been shown to read or write `.LSW` CONTENTS"*. Both are false. The string search
behind them missed the mixed-case names `PreLswLoad` / `PostLswLoad` / `PreLswSave` /
`PostLswSave`, which sit in the factory-test string table at `0xE1F726..0xE1F755` beside
`PrePmLoad`/`PostPmLoad`/`PreTmLoad`/`PreMidiLoad`, and
missed the whole importer because it never names the type.

## 3. The full 0x5800 accounting

Measured on all seven floppies, identical every time:

| file span | size | what it is | read by the KN5000? |
|---|---|---|---|
| `0x0000..0x0020` | `0x0020` | header (`5A 5A 01 00 "M60" 0A`, then `EE 03` at `+0x0B` = the block-0 terminator offset) | yes — bytes 4,5 classify it |
| `0x0020..0x03F0` | `0x03D0` | TLV block 0, 37 records — the current panel | yes, importer stage 1 |
| `0x03F0..0x0680` | `0x0290` | TLV block 1, 30 records | yes, importer stage 1 |
| `0x0680..0x4E80` | `0x4800` | **24 panel memories**, `0x300` each | first **10** only |
| `0x4E80..0x4EB0` | `0x0030` | unidentified | no |
| `0x4EB0..0x53C0` | `0x0510` | style-voice table: `5A 5A 5A` `"LKE"` u16 count=**128**, then `count`×10 bytes | no |
| `0x53C0..0x5480` | `0x00C0` | 12 identical 16-byte records, unidentified | no |
| `0x5480..0x5800` | `0x0380` | byte-exact mirror of this disk's own `.MSP` | no |

**So the `0x5800` is `0xE40`'s content plus 0x4800 of panel memories plus a 0x380 `.MSP`
mirror, at a revision whose records are wider.** The two extra parts have no counterpart
in what the KN5000 writes: its own `.LSW` carries the current panel only, and its panel
memories go to `.PMT` (file type 1, region `0x1ED350..0x200000`).

The style-voice block is the same structure as the KN5000's second saved region. That
region's factory default (ROM `0xE47F7F`, `0x7E0` bytes, installed by `AccStyle_InitVRAM`)
opens `5A 5A 5A | 48 00 4B | C8 00` — `ZZZ`, the flash-side `"H.K."` magic, and a u16
count of **200** — and `0x10 + 200*10 == 0x7E0` is exactly the length that routine copies.
The file's block is the same header with the disk-side `"LKE"` magic and count 128, and
`0x10 + 128*10` lands exactly on `0x53C0` where the array stops. The header field
predicting the array length in both is what ties them together. *The correspondence is
[INFERENCE] from that shape: the importer never reads this block.*

## 4. Cross-checks worth keeping

* The file carries tag `0x99` in block 1; the KN5000 carries it in block 0. The converter
  at `0xFD38FF` reads file `+0x442` bit by bit into RAM `0xFD30` — and file `+0x442` is
  exactly the payload of the block-1 record `0x99`, while `0xFD30` is exactly the payload
  of the block-0 record `0x99`. That is why `lsw_file_vs_firmware_schema.py` measured
  "the file inserts tag 99 after 98".
* A panel-memory slot is the live panel block *minus* its 32-byte header: every stage-2
  destination is its stage-1 counterpart minus `0x20`.

## 5. What is NOT settled

* **Why format 2 imports only 10 of the 24 panel memories** (`0x000A` is a literal in the
  code; format 1 uses `0x0018`). The files carry 24. Header byte `+7` is `0x0A` = 10,
  which *may* be the count the writer recorded — but the KN5000 ignores it and hard-codes,
  so nothing here proves that byte is a count rather than the `\n` it also looks like.
  Settle it with a format-1 (`"M4…"`) file, or with an `.LSW` written by a real M60
  machine after storing a 24th panel memory.
* `0x4E80..0x4EB0` (0x30 B) and `0x53C0..0x5480` (0xC0 B). The 0x30 is 24 u16 words, one
  per slot, which is inviting — and was tested and **not supported**: in `02BOSSA_.LSW`
  slots 15..23 duplicate slots 5..13 while the corresponding words do not.
* What `"M4"` and `"NN"` are. Format 3 has its own importer pair (`0xFD4366`, `0xFD44D5`),
  untouched here.

## Can it fail?

Yes, in both directions, checked:

* corrupting one tag byte inside panel memory 0 of a real file →
  `F3: slot 0 offset 0x264 tag (183, 10) != (72, 10)`;
* setting header byte 5 to `'4'` → `F1: header [4],[5] = b'M4' -> format 1, expected 2`;
* changing one expected ROM immediate (`DSTB 0x34` → `0x35`) →
  `R4: stage-1 immediates differ`.
