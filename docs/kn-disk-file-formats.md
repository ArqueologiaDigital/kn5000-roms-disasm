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

## `.SEQ` -- container established, field semantics NOT

Built from the same 256-byte cell as the ROM formats: 0x80 marker at +0, two u16 little-endian
fields at +1 and +3, payload from +5. Over 596 cells in seven files, every one of the 1087 in-range
pointers lands on a real cell, and each file has exactly one pointer landing outside itself.

⚠ **The two fields are NOT a prev/next pair here** -- 48 of 540 back-links agree, against 514 of
514 in the IC19 styles. Unlike `.CMP`, this variant uses **0x0000** rather than 0xFFFF for "none",
and a plain block index rather than a section-relative one. What the field at +1 actually is
remains open, and is deliberately not guessed: assuming that pair produced three wrong readings of
the IC19 header on 2026-08-21.

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
