# KN-series disk file formats

Status: partial, and honest about which parts are established. Every number here is measured over
seven real KN-series floppies (`KN7000/floppy-archive/*.zip`), each holding the same six files:

    .CMP  custom accompaniment styles      44,032 or 63,488 B
    .SEQ  sequencer song                    6,144 .. 64,512 B
    .SQF  song file (name-bearing)                20,480 B
    .LSW                                          22,528 B
    .MSP                                           4,096 B
    .TM   sound RAM                               12,288 B

Reproduce with `scripts/analysis/disk_cmp_is_ic19_format.py`, `disk_seq_container.py` and
`disk_tm_sound_ram.py`.

## `.CMP` -- SPECIFIED

**It is the IC19 accompaniment-style format, exactly.** Same 96-byte directory at magic + 0x60 with
the 16-char name at +0x40, same cell, same relative-block pointer rule. Across the seven disks:
184 directory records, 1437 cells, 777/777 pointers resolving, 388/388 back-links agreeing, and
**51,443 events decoding with zero malformed** under the IC19 grammar unchanged.

Header differs only in magic -- `4C 4B 45 00` ("LKE") on disk versus `48 00 4B 00` ("H.K.") in
flash -- and is the same shape from offset 3. Full specification:
`docs/accompaniment-style-format.md`.

## `.TM` -- sound RAM, structure established, fields not

    +0x000  16 B    ASCII magic "KN1500 SOUND RAM"   (note: KN1500, on KN7000-era disks)
    +0x010  40 x 0x121 B   sound records, 16-char ASCII name at +0x00 of each
    +0x2D38 712 B   tail, NOT filler -- varied content, unidentified

40 records of 289 bytes each, consistent on all seven disks. The names are the same everywhere --
"Crystal E.P.", "Heavenly E.P", "Folk Dreams", " Fancy Folk", "Syn String 3" -- but **six of the
seven files differ in content**, so the names are factory defaults over user-edited parameters.
Nothing inside a record beyond the name is identified.

## `.SEQ` -- SOLVED

Built from the same 256-byte cell as the ROM formats, and the two u16 fields **ARE a prev/next
pair**. What hid that is two conventions at once:

    +0x01  u16 LE  PREV cell, ONE-BASED: value v addresses block v-1.  "none" = 0x0000
    +0x03  u16 LE  NEXT cell, ONE-BASED: value v addresses block v-1.  "none" = 0xFFFF
    +0x05  251 B   payload -- the DEMO-SONG grammar, not the IC19 one

The sentinels are **field-specific and not interchangeable**, and the numbering is one-based. Read
them zero-based, or assume 0xFFFF serves both ends, and the links appear not to agree -- which is
the wrong conclusion this document recorded earlier today (48 of 540 back-links).

Read correctly: over 1192 cells in the seven files, 2188 of 2188 pointers resolve and
**1094 of 1094 forward and backward links are mutual**. Each file partitions into exactly seven
doubly-linked chains whose heads are blocks 0..6, and four of the seven also carry a trailing
doubly-linked FREE LIST of unused blocks (byte 0 == 0x00 rather than 0x80). That free list is also
what the "one pointer landing outside the file" per disk turned out to be -- its tail's `next` is
the one-past-the-end sentinel, not a dangling reference.

The payload is 251 bytes from +0x05 and follows the DEMO-song grammar, not the IC19 accompaniment
one: a strict argument-count parse gives 0 malformed over 44,795 events at 251, against
2342/2156/1846/1199 bad at 250/249/248/252.

Reproduce: `analysis/disk-format-probes/disk_seq_chains.py <dir>`, which ASSERTS both properties.

## `.LSW` -- SOLVED (container), contents partly open

    0x0000..0x001F  header, byte-identical on all seven disks: 5A 5A 01 00 "M60" 0A, then
                    00 00 00 EE 03 ... -- the u16 LE at +0x0B is 0x03EE, the offset of the
                    FIRST BLOCK TERMINATOR
    0x0020..0x4E80  a TLV stream: tag u8, length u8, `length` payload bytes, grouped into
                    26 blocks each ended by FF FF at a record boundary. 955 records, and
                    ZERO residue on all seven disks.
    0x4E80..0x5800  NOT TLV. Unframed bytes, a `5A 5A 5A "LKE" 80 00` magic at 0x4EB0, a
                    0x500-byte array of 128 x 10-byte records at 0x4EC0, 12 constant 16-byte
                    records at 0x53C0, and 0x5480..0x5800 which is a **byte-exact copy of the
                    first 896 bytes of the same disk's .MSP**.

Block geometry: block 0 is 37 records ending at 0x03EE; block 1 is 30 records ending at 0x067E;
blocks 2..25 are 37 records each on a fixed 0x300 grid. The length byte is load-bearing -- the same
tag takes different lengths in different blocks (0x48: 14/10, 0x90: 6/5, 0x70: 12/5) -- so this is
genuinely TLV and not a fixed record array.

Two caveats kept deliberately: `FF FF` terminates only at a RECORD BOUNDARY (four 0xFF bytes occur
inside a block-1 payload at 0x048D and must not be mistaken for one), and **no code in the
disassembly has been shown to parse this** -- the only ROM mention of "LSW" is the filename
extension table at 0xEA038C -- so the framing is [INFERENCE] from data shape, however exact.

NOT established, and deliberately unnamed: what the 24 slot blocks ARE. Their geometry and their
user/untouched split are proved, but the firmware evidence says `.LSW` is the CURRENT PANEL and
that panel memory is a separate `.PMT` extension these disks do not carry, so the tempting "24
panel memories" reading is in tension with the extension table and is NOT adopted.

Reproduce: `analysis/disk-format-probes/disk_lsw_container.py <dir>`.

## `.MSP` -- SOLVED (container), contents open

It uses the IC19 cell container: block 0 is a header, blocks 1..15 are cells with 0x87 at +0x05
and +0xFF and a 249-byte payload at +0x06. Six cell chains decode under the IC19 event grammar
with **zero malformed events**.

The IC19 96-byte style directory does NOT apply. Instead the header **self-describes its own
directory geometry** in the same u16 LE triple `.CMP` uses: at +0x10 it reads offset 0x0020,
stride 0x0010, count 0x000E -- fourteen 16-byte records at +0x20.

⚠ The file is byte-identical on all seven floppies, so this is **one sample, not seven**. Whether
it is factory or user content was investigated and the evidence supports BOTH readings; no
conclusion is drawn.

Reproduce: `analysis/disk-format-probes/disk_msp_container.py <dir>`.

## `.SQF` -- slot geometry established, contents not

    +0x000  4 B     magic 5A 5A 5A 5A
    +0x009  8 B     ASCII name -- "07VALSE_" on all seven disks
    +0x0C1  10 x 0x800 B   slots, 8-char ASCII name at +0 of each

Ten slots of 2,048 bytes. On every one of the seven disks the first slot is named `PERSON` and the
other nine are `________`, which is what an empty slot looks like -- so these disks carry one
populated entry and nine free ones. **All seven files differ in content** despite sharing that
layout and those names.

The header name "07VALSE_" is identical across all seven and follows the two-digit-prefix
convention seen in style names, so it is probably not per-disk user text. Nothing inside a slot is
identified.

## `.LSW`, `.MSP` -- NOT ESTABLISHED

    .LSW   opens 5A 5A 01 00 then ASCII "M60"; 49% non-filler, densely packed with no record
           stride visible in a gap histogram; `ZZZ` recurs at 0x4EB0 and 0x548B; all seven disks
           DIFFER, so it is user data
    .MSP   opens 4C 4B 45 ("LKE") then 5A 5A 5A -- the same header shape as .CMP -- 4,096 B, and
           **byte-identical on all seven disks**, so a constant: a default or empty bank.

⚠ CORRECTED: an earlier version of this file said `scripts/analysis/extract_composer_msp.py`
"already reads part of" the disk `.MSP`. **It does not.** That script extracts Music Style Preset
data out of the PROGRAM ROM source, shares nothing with the disk format but three letters, and is
a spent one-shot migration that rewrites the maincpu source in place -- it must not be repaired and
re-run. Nothing in this repository reads a disk `.MSP`.

The `5A 5A 5A` signature recurs across `.SQF`, `.LSW`, `.CMP`, `.MSP` and the IC19 section headers,
so it is a family marker rather than a per-format magic.

## What this is worth

One of the three protocol subsystems graded SKETCHED at the start of 2026-08-21 was "user-disk file
formats". `.CMP` is now fully specified with an asserting probe; `.TM` has its record geometry;
`.SEQ` has its container with an explicit open question. Three of six file types remain
unestablished, and this document says so rather than implying coverage it does not have.
