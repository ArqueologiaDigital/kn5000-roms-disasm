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

## `.SQF`, `.LSW`, `.MSP` -- NOT ESTABLISHED

    .SQF   opens 5A 5A 5A 5A, then a song name in ASCII ("07VALSE_"), plus "PERSON"; 30% non-filler
    .LSW   opens 5A 5A 01 00 "M60"; 49% non-filler; all seven disks DIFFER -> user data
    .MSP   opens 4C 4B 45 ("LKE") then 5A 5A 5A, the same header shape as .CMP; 4,096 B;
           **byte-identical on all seven disks** -> a constant, probably a default or empty bank.
           `scripts/analysis/extract_composer_msp.py` already reads part of it.

The `5A 5A 5A` signature recurs across `.SQF`, `.LSW`, `.CMP`, `.MSP` and the IC19 section headers,
so it is a family marker rather than a per-format magic.

## What this is worth

One of the three protocol subsystems graded SKETCHED at the start of 2026-08-21 was "user-disk file
formats". `.CMP` is now fully specified with an asserting probe; `.TM` has its record geometry;
`.SEQ` has its container with an explicit open question. Three of six file types remain
unestablished, and this document says so rather than implying coverage it does not have.
