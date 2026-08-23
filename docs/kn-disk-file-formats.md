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

    +0x000  16 B    ASCII magic "KN1500 SOUND RAM"   (see below: NOT an anomaly)
    +0x010  40 x 0x121 B   sound records, 16-char ASCII name at +0x00 of each
    +0x2D38 712 B   tail, NOT filler -- varied content, unidentified

⚠ The `KN1500` magic on a KN7000-era disk was recorded here as an oddity. It is not one. The
KN5000 carries a LIST of accepted magics at `0xEED53B`, verified by dump:

    KN2000 / MKA / MKB / KN3000 SOUND RAM / KN1500 SOUND RAM / KN5000 SOUND RAM

So the instrument imports several predecessors' sound RAM, and a foreign magic on a disk is
EXPECTED rather than anomalous. Recorded 2026-08-23; the "note:" that stood here invited the
next reader to hunt for an explanation that the ROM already gives.

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
    0x4E80..0x5800  NOT TLV. Unframed bytes, a `5A 5A 5A "LKE" 80 00` marker at 0x4EB0, a
                    0x500-byte array of 128 x 10-byte records at 0x4EC0, 12 constant 16-byte
                    records at 0x53C0, and 0x5480..0x5800 which is a **byte-exact copy of the
                    first 896 bytes of the same disk's .MSP** -- re-verified on all seven disks
                    by `analysis/disk-format-probes/lsw_tail_vs_msp.py`.

`"LKE"` is **not an `.LSW` magic**. It is the `.MSP` format's own signature: an `.MSP` file opens
`4C 4B 45 ...` (`"LKE"`) with `5A 5A 5A` (`"ZZZ"`) at +0x0B. The bytes at `.LSW` 0x4EB0 are the same
two tokens in the other order, `5A 5A 5A 4C 4B 45 80 00`. Together with the `.LSW` header's own
`5A 5A 01 00 "M60" 0A`, `0x5A` reads as a family framing byte across these formats.

⚠ TRAP, hit while measuring this. Searching for `.MSP` windows inside the `.LSW` tail with a
fixed-size probe reports dozens of extra hits, all resolving to one offset -- runs of `0x00`
matching other runs of `0x00`. **A probe made of constant bytes matches wherever that constant
repeats.** The committed script skips single-byte windows, which removes every false hit; 10 of the
14 windows in the copied region are informative.

Block geometry: block 0 is 37 records ending at 0x03EE; block 1 is 30 records ending at 0x067E;
blocks 2..25 are 37 records each on a fixed 0x300 grid. The length byte is load-bearing -- the same
tag takes different lengths in different blocks (0x48: 14/10, 0x90: 6/5, 0x70: 12/5) -- so this is
genuinely TLV and not a fixed record array.

Two caveats kept deliberately: `FF FF` terminates only at a RECORD BOUNDARY (four 0xFF bytes occur
inside a block-1 payload at 0x048D and must not be mistaken for one), and **no code in the
disassembly has been shown to parse this** -- the only ROM mention of "LSW" is the filename
extension table at 0xEA038C -- so the framing is [INFERENCE] from data shape, however exact.

### The file-type enumeration (settles what the 24 blocks are NOT)

`SeqFileType_CodeTable` at ROM 0xEA0340 is an array of ten LE32 pointers to the extension strings
at 0xEA0368..0xEA038C, terminated by `FF FF FF FF`:

    index 0  LSW      index 5  MSP
    index 1  PMT      index 6  RCM
    index 2  SQT      index 7  "MD "
    index 3  CMP      index 8  SQF
    index 4  "TM "    index 9  SEQ

It is used to build filenames -- `file_demo_proc.s` scales the type index by 4, reads the pointer
and appends the extension via `FileIO_BuildFilePath`. Note two extensions carry a trailing space,
`"MD "` and `"TM "`, which a filename builder must reproduce.

**`PMT` and `LSW` are separate file types in the same table.**

> ⚠ **RETRACTED (2026-08-22).** This paragraph used to argue that the "24 slot blocks are panel
> memories" reading was "not merely unsupported, it is contradicted". **It was right.** The slots
> ARE panel memories: the format-2 importer reads them 0x300 at a time into `0x1ED400 + 960*j`,
> bracketed by calls named `PrePmLoad`/`PostPmLoad`, and 960 = 0x3C0 = the size of TLV block 0,
> with `(0x200000-0x1ED400)/960 = 80` exactly. A panel-memory slot is the live panel block minus
> its 0x20 header -- every stage-2 destination is stage-1's minus 0x20.
>
> The inference that misled me was reasonable and still wrong: `.PMT` existing as its own type
> does NOT mean panel memories cannot appear inside a `.LSW`. A separate extension for saving one
> slot is compatible with the current-panel file carrying all of them.
> Prover: `analysis/disk-format-probes/lsw_region_to_block_map.py`.

What `.LSW` IS has since been settled from the KN7000 UI -- **"CURRENT PANEL"**, the live panel
setup, as against `.PMT` "PANEL MEMORY", the stored slots. See *What the extensions mean* below.
That refines this paragraph rather than overturning it: the two really are different things, and
the 24 blocks still are not memory slots.

### Every mention of "LSW" in the KN5000 program ROM

There are exactly three, and together they bound what can be learned here:

1. **0xEA038C** -- the extension string in `SeqFileType_CodeTable` (above).
2. **0xE1FE24** -- the glob **`A:\HAMA\*.LSW`**, in a factory-test string block alongside
   `TEST Finishd!!`, `init`, `OK`, `NG`. So `.LSW` files are read from a `HAMA` directory during a
   factory test or initialisation pass. (`scripts/analysis/extract_hama.py` already exists in this
   repository and is the place to start on that directory.)
3. **0xEAEA55** -- the event name **`EV_LSWDATA`**, inside a 44-entry UI event enumeration:

       EV_NONE EV_SHOW EV_HIDE EV_INIT EV_MOVE EV_RESIZE EV_ACTION EV_SWIN EV_SWON EV_SWOFF
       EV_ALLPAINT EV_PAINT EV_REPAINT EV_DRAW EV_SELEDRAW EV_PARADRAW EV_RESET
       EV_CHANGEPROPERTY EV_TIMER EV_ACTIVATE EV_CHANGE_MODE EV_CHANGE_TITLE
       EV_INTERRUPT_TITLE EV_INDEXSW_UP EV_INDEXSW_DOWN EV_INDEXSW_UP_AIC
       EV_INDEXSW_DOWN_AIC EV_INDEXSELECT **EV_LSWDATA** EV_RAMDATA EV_PAGECHANGE EV_DIAL
       EV_SOUNDNAME EV_RHYTHMNAME EV_PMEMNAME EV_SOUNDSWNO EV_BITDATA EV_MEMODRAW
       EV_AUTOINC EV_SWIN_AIC EV_RETURN_TITLE EV_IAMSELECTED EV_YOUARESELECTED

   This is a full windowing/widget event set. `SW` means SWITCH throughout it (`EV_SWON`,
   `EV_SWOFF`, `EV_INDEXSW_DOWN`, `EV_SOUNDSWNO`), and `EV_LSWDATA` sits directly beside
   `EV_RAMDATA` as the other "...DATA" delivery event.

> ⚠ **RETRACTED (2026-08-22).** This said **"No KN5000 code has been shown to read or write
> `.LSW` CONTENTS"**. False, and the cause was a case-sensitive search: the ROM carries
> `PostLswSave`, `PreLswSave`, `PostLswLoad`, `PreLswLoad` -- mixed case `Lsw`, not `LSW` -- in the
> factory-test table at `0xE1F726..0xE1F755` (verified by direct dump). A search for the uppercase
> spelling returns a clean zero and reads like a result.
>
> The KN5000 both writes and reads these files. It writes 0xE40 in four parts (32-byte header from
> `0xF980`, TLV block 0 from `0xF9A0`, TLV block 1 from `0xFD60`, and 0x800 from `0x1E7800`), and
> `FileIO_CheckRegionSignature(0)` requires `"HK"` at file offset 4 (table `0xEA0104`). The ROM's
> own factory-default panel image at `0xEDB3DC` begins `5A 5A 00 00 48 4B` -- it satisfies the
> loader's check, i.e. the live panel area IS a `.LSW`.
>
> What the letters stand for is still NOT established; the neighbouring names make "switch" likely
> for the SW and nothing establishes the L.

### Traced, and the answer is that it is NOT HERE

The `EV_LSWDATA` step was taken. Each of the three mentions leads away from the format:

* **The glob is factory-test scratch.** `A:\HAMA\*.LSW` sits in
  `FDTest_String_TestTitleFunc_0xDC`, inside the HAMA factory-diagnostics subsystem
  (`v7/maincpu/factory_test/`). `FDLoadSaveTest` there allocates a 2 KB buffer, fills it with a
  counting pattern 0..0x3FF, writes it to a file, reads it back and compares byte by byte. So that
  glob names a SCRATCH FILE the disk test writes and re-reads -- it says nothing about the format
  of a user's `.LSW`.
* **The extension-table entry** only lets the file browser build the name `NAME.LSW`.
* **`EV_LSWDATA`** is one of 44 UI widget events; the enumeration is a windowing system, and the
  event is a data-delivery notification, not a parser.

Putting those together produced a conclusion that was **WRONG**, kept here because the way it failed
is worth more than the claim was:

> ~~**The KN5000 firmware never parses `.LSW` contents.** It names the extension, uses `*.LSW` as a
> disk-test scratch pattern, and carries a widget event named after it. No code reads or writes the
> 26 blocks, the TLV records or the 24 slots.~~
>
> ~~That is a definite answer rather than a failed search, and it has a consequence: **the 24 slot
> blocks cannot be identified from these ROMs at all.**~~

**RETRACTED.** The KN5000 handles `.LSW`, and has a dedicated handler for it in every revision. The
string search above is complete and correct -- and irrelevant, because **the code never names the
type. It uses the INDEX 0** into `SeqFileType_CodeTable`. A search for `"LSW"` cannot find code that
only ever says `0`.

### `.LSW` is file type 0, and type 0 has a handler

`FileIO_SaveAllRegions` walks eight 6-byte records at **0xEA0210**
(`Resource_Region3_Start_0x10`):

    +0  u16  file-type index into SeqFileType_CodeTable   -- 0 = LSW
    +2  u32  handler, fetched via Resource_Region3_Start_0x12 and `call (xhl)`

Both offsets come from the code rather than from the shape of the bytes: `_0x10` feeds the type
index passed to `FileIO_ReadHeader` in `e`, and `_0x12` is loaded into `xhl` and indirectly called
in `FileDemo_ProcessCallback`. All eight types 0..7 appear exactly once, each with a handler:

| type | 0 LSW | 1 PMT | 2 SQT | 3 CMP | 4 TM | 5 MSP | 6 RCM | 7 MD |
|---|---|---|---|---|---|---|---|---|
| v7 | **F876E9** | F8777B | F8789F | F8791F | F87A34 | F87989 | F879F3 | F87833 |
| v9/v10 | **F87AF6** | F87B88 | F87CAC | F87D2C | F87E41 | F87D96 | F87E00 | F87C40 |

Reproduce: `scripts/analysis/lsw_saveall_table.py`, which exits non-zero if the table stops covering
types 0..7 with in-range handlers.

**The v7 handler corroborates "CURRENT PANEL" independently.** Its first act is to size the region
`0xF980..0xFFC0` and add `0x1E7800..0x1E8000` to it:

    f876f0  lda XBC,0xffc0        ; \  0xFFC0 - 0xF980 = 0x640
    f876f4  lda XWA,0xf980        ; /
    f876fe  lda XBC,0x1e7800      ; \  + 0x800
    f87703  lda XIZ,0x1e8000      ; /
    f87713  cp XHL,XWA            ; need >= 0xE40 bytes free, else error 0xFF9B
    f87722  ld DE,0               ; file type 0 = LSW

`0xF980..0xFFC0` is the DRAM work area the firmware preserves across power-down -- i.e. the live
panel state. So the KN5000 handler and the KN7000 UI label agree, by two entirely separate routes.

### The writer, disassembled -- and a size that does not add up

The v7 handler is 0x92 bytes, complete and short. Reproduce with:

    dd if=original_ROMs/kn5000_v7_program.rom of=/tmp/h.bin bs=1 skip=$((0x1876E9)) count=$((0x92))
    unidasm /tmp/h.bin -arch tlcs900 -basepc 0xF876E9

It is a **writer**, and that is proven rather than assumed at two points: it passes `DE = 0` (the
extension index for `LSW`) to `0xF88D9E`, whose first six instructions match `FileIO_ReadHeader`
exactly (`dec 2,XSP / push XIZ / ld (XSP+0x04),E / ld XIZ,XWA / ...`); and it opens with the mode
string at `0xEA01F0`, which is **`"wb"`**.

    f876f0  size check   (0xFFC0 - 0xF980) + (0x1E8000 - 0x1E7800) = 0x640 + 0x800 = 0xE40
    f87715  if free < 0xE40 -> error 0xFF9B
    f87722  ld DE,0            ; extension index 0 = LSW
    f87724  call 0xF88D9E      ; build "<name>.LSW"
    f87730  call 0xF887BA      ; fopen, mode "wb" @ 0xEA01F0
    f8774a  call 0xF88A1B      ; write 0x640 bytes from 0xF980
    f87755  call 0xF88A1B      ; write 0x800 bytes from 0x1E7800
    f87759  call 0xF887B5      ; close

So the payload is **0xE40 = 3,648 bytes** from two regions: `0xF980..0xFFC0` (the DRAM work area
preserved across power-down -- the live panel) and `0x1E7800..0x1E8000` (unidentified).

**And 0xE40 matches neither corpus.** There are two distinct populations of `.LSW` in the tree:

| corpus | count | size |
|---|---|---|
| `KN7000/floppy-archive` (the seven disks analysed above) | 7 | **22,528 B (0x5800) uniform** |
| `kn7000_scratchpad_snapshot/kn6scan/ext` | 8+ | **~2,050 B, variable** (2041, 2049, 2050, 2051, 2074, 2076, 2354) |

Neither is 3,648.

⚠ I first guessed that `0xF88A1B` might pack, since it branches on a global at `0x7EA8` before
writing -- which would have turned a fixed payload into variable output near 2 KB. **That guess was
wrong, and disassembling the function killed it.** `0xF88A1B` is a plain chunked `fwrite`: it splits
the copy into runs of at most 0x7FFF bytes, calls `0xF4EAB5(buf, 1, chunk, fp)`, and loops until the
count is exhausted. `0x7EA8` is the FILE handle, not a mode flag -- a null there is the error
`0xFF9C`. There is no compression anywhere on this path.

And the regions are not revision-specific: v9's handler at `F87AF6` names the same four addresses as
v7's, so **all three revisions write exactly 3,648 bytes**. The prover asserts this and fails if a
revision ever changes them.

**Therefore neither corpus was written by this firmware.** 22,528 != 3,648 and ~2,050 != 3,648. The
KN5000 writes `.LSW`, but it did not write *these* `.LSW` files. Both facts are now proven, and they
are not in tension -- they simply mean the seven floppies came off a different machine.

**The consequence is uncomfortable and worth stating plainly: the 26-block TLV structure documented
above describes a format this firmware does not produce.** The TLV reading remains exact on its own
corpus -- 955 records, zero residue on all seven disks -- but it is a description of some other
model's panel file, and the "24 slots" question belongs to whatever wrote it.

### The KN7000 side, as far as it goes

`0x4852F887` is the KN7000's build-`"<name>.<ext>"` routine, type index in `d0`. Its callers divide
sharply:

* **types 1..13 each have literal constant call sites** -- PMT, SQT, CMP, TM, MSP, EFC, MD, FAV,
  HMP, AST, SQF, SEQ, ACT;
* **type 0 (`LSW`) has none**, in an image where every sibling does;
* **33 sites pass the index dynamically**, which is where a UI-selected type flows -- and the SD
  menu does offer LSW (`SD_LD2_BLSW` -> `PANEL`).

So the KN7000 reaches `.LSW` only through the dynamic path. That does not identify the writer of the
22,528-byte files, and it is recorded as a measured asymmetry rather than an explanation.

⚠ Two traps here, both of which produced wrong answers before being caught. The function's **entry
is 0x4852F887, not its 0x4852F882 prologue** -- searching for calls to the prologue address returns
zero, as does searching for the address as a constant, which reads as "never called" when it is
called 62 times. And a backward byte-scan for `mov imm,d0` **misses `clr d0`**, a single `0x00` byte
and precisely the encoding a zero index would use; that scan also invented types 16, 20, 253, 6237
and 35533 out of mid-instruction matches and counted TM 16 times instead of 2. Reproduce with
`tools/callsite-types/kn7000_filetype_callsites.py` in the KN7000 repo, which decodes backwards with
unidasm and only trusts a window when a decoded instruction starts exactly on the call.

**Next, and now sharply testable:** the file size is a fingerprint of the writer. Find the KN7000's
type-0 handler and sum its regions -- if they come to **0x5800**, that identifies the machine that
wrote the seven floppies outright, and the 24 slots become a KN7000 structure with a known layout.
The `kn6scan` population is variable-length, so it is a different kind of file again and nobody has
parsed it. Also still unmapped: what lives at `0x1E7800..0x1E8000`.

⚠ **The lesson, since it will recur.** "Searched the whole ROM for the name, found nothing, therefore
the firmware does not do it" is only valid when the code would have to say the name. Table-driven
code says an index. Before concluding absence from a string search, ask what the code would say if
the feature existed.

### Where the answer IS -- checked, not assumed

`~/compartilhado/kn7000_scratchpad_snapshot/kn7000_program_decompressed.bin` (4,157,184 B) holds
seven `LSW` occurrences, and they show the KN7000 treats `.LSW` as a **first-class user file type**
rather than a scratch name:

* its file-type table at 0x26441C lists fourteen extensions --
  `LSW PMT SQT CMP TM MSP EFC MD FAV HMP AST SQF SEQ ACT` -- against the KN5000's ten, with `LSW`
  first in both;
* the SD-card LOAD and SAVE menus carry per-type widgets, `SD_LD2_LBLSW` / `SD_LD2_BLSW` and
  `SD_SV2_LBLSW`, beside the equivalents for PMT, SQT, CMP and TM. So a KN7000 user can save and
  load `.LSW` files from the SD menu. (Originally written as "the reader and writer this one does
  not" -- see the retraction above: the KN5000 has them too.)

⚠ An earlier investigation reported that the KN7000/KN6000 program ROMs "contain no readable ASCII
at all under either even/odd interleave" and were probably compressed. That is true of the packed
images and false of the tree: a DECOMPRESSED image already exists at the path above, and it is
plainly readable. Check for a decompressed artefact before concluding a ROM is opaque.

### What the extensions mean -- recovered from the KN7000 UI

Tracing `SD_LD2_LBLSW` in the KN7000 image does **not** reach the load routine (see below), but it
does answer a different open question: what each file type is CALLED on screen.

The firmware registers two parallel 840-entry arrays at 0x4854EBAE -- descriptors at 0x48760848,
debug names at 0x48761568, same index into both. A descriptor carries its label-string pointer at
+0x18. Widget #148 is `SD_LD2_LBLSW`, and its label is **`CURRENT PANEL`**:

| widget | label | | widget | label |
|---|---|---|---|---|
| `SD_LD2_LBLSW` | **CURRENT PANEL** | | `SD_LD2_LBPMT` | PANEL MEMORY |
| `SD_LD2_LBMD` | USER MIDI SETTINGS | | `SD_LD2_LBPAD` | PERFORMANCE PADS |
| `SD_LD2_LBSQT` | SEQUENCER | | `SD_LD2_LBFAV` | FAVORITES |
| `SD_LD2_LBCMP` | COMPOSER | | `SD_LD2_LBAST` | ALL CUSTOM STYLE |
| `SD_LD2_LBTM` | SOUND MEMORY | | `SD_LD2_LBEFC` | EFFECT MEMORY |
| | | | `SD_LD2_LBHMP` | HOME PAGE |

Reproduce: `tools/widget-map/kn7000_widget_labels.py <decompressed.bin> SD_LD2_` in the KN7000
repo. It carries a **self-test that can fail**: three abbreviations whose meaning is independently
obvious (`MD`->MIDI, `SQT`->SEQUENCER, `CMP`->COMPOSER) must appear in their own labels, and the
script exits non-zero if the +0x18 rule stops holding.

Four further confirmations are external to the firmware entirely -- real files carry exactly these
types: `01CTMINI.AST` (ALL CUSTOM STYLE), `02UMDINI.MD` (USER MIDI SETTINGS), `03FAVINI.FAV`
(FAVORITES), `04HPGINI.HMP` (HOME PAGE). And a second, independent widget agrees on LSW: the row of
LOAD buttons has `SD_LD2_BLSW` -> **`PANEL`**.

⚠ Provenance: these labels come from the **KN7000** firmware. Both models use `.LSW`, and the
KN5000 header `5A 5A 01 00 "M60"` is stable across all seven disks, but no KN5000 code names the
type -- so "CURRENT PANEL" is [CROSS-MODEL EVIDENCE], strong but not from the machine whose disks
were parsed above.

### The framing is FIRMWARE FACT, and the schema is a ROM table (2026-08-22)

The paragraphs below were written when the TLV framing was `[INFERENCE] from data shape, however
exact`, and when the seven floppies looked like a foreign format because KN5000 firmware writes
3,648 bytes and they are 22,528. Both readings are now superseded, and the second was wrong in an
interesting way: **the files are the same format, at a different revision.**

The KN5000's live panel work area is itself a tag/length/value stream, and its layout is a table in
ROM. `analysis/disk-format-probes/lsw_panel_schema_from_rom.py` reads it:

    block 0   0xED8FE0   46 entries, base 0x00F9A0
    block 1   0xED91AC   30 entries, base 0x00FD60
    entry = { u32 offset_from_base ; u32 -> field descriptors ; u8 tag ; u8 length }

and each descriptor block gives every field a TYPE, OFFSET, MASK, MIN, MAX and DEFAULT. Verified by
hand: entry[0] is `00 00 00 00 dc 8a ed 00 78 12` (offset 0, descriptors at 0xED8ADC, tag 0x78,
length 0x12), and the descriptor block at 0xED8B9E opens `03 00 ff 00 a7 15` -- type 3, offset +00,
mask 0xFF, **min 0, max 167, default 21**.

`lsw_file_vs_firmware_schema.py` then aligns each block of a real `.LSW` against that firmware
sequence: **37/37 tags aligned in order on every block of all seven disks, no permutation.** The
lengths differ systematically -- all 24 sound records 24->22, tag 60 4->12, tag 61/63 24->30, tag 71
2->4, tag 80 14->10 -- which is what a format revision looks like, not a different format.

### The voice selector's 168 options are NAMED (2026-08-22)

`+0` is a flat panel sound number and `+1` is its variation bank. Two ROM tables resolve the pair,
and the names come out in plain ASCII:

    program ROM   SoundData_CategoryDesc  0xE023A0 ; category names 0xE023F0, stride 16, 18 entries
    table ROM     bank map 0x830100 -> tone number 0x830180 -> offset table 0x831B00 (629 x LE32)
                  -> 16-byte space-padded name at 0x830000 + offset

Decoded by hand, walking those tables directly: slot 0 `Piano`, 1 `Bright Piano`, **21
`Jazz Ac.Guitar`**, 40 `Electric Bass`, 48 `Trumpet`, 96 `Violin`, 127 `Orchestra Hit`. Slot 21 is
the schema's own `default=21`, which is the kind of agreement that is hard to arrange by accident.

Three checks, `analysis/disk-format-probes/lsw_voice_selector_names.py`, exits non-zero on failure:

* **C1 pins the alignment.** The map's domain ends at exactly index 167 in v7, v9 and v10 alike --
  the same 167 the field descriptor gives as `max`. An off-by-one would make one of the two 166.
* **C2** names all 128 bank-0 factory slots (117 distinct tone records).
* **C3 is the semantic check.** In the seven floppies, tag 0x13 has 175 records and **171 (97.7%)
  resolve into category BASS**, against a 4.8% null -- 8 of 168 options are BASS.

⚠ Stated limits, not smoothed over. C3 rules out a WRONG TABLE (shifting the index by 8 collapses it
to 0.0%) but NOT an off-by-one, because the 8 BASS slots are contiguous -- a +1 shift still scores
97.7%. C1 is what pins it. And **options 128..167 have no name in any ROM**: they are user Sound
Memories in battery-backed RAM, so no ROM search can produce them, and no floppy in the corpus uses
a value >= 128 for these tags.

⚠ A CONTRADICTION worth resolving: `README-lsw-panel-schema.md` labels tag 0x14 "Bass" and 0x13
"Rhythm". The corpus says 0x13 is the bass part (171/175 BASS) and 0x14 carries no `+0` sound
descriptor at all. The newer evidence is stronger, but the older note has not been retracted here
because it was written from different reasoning that deserves its own review.

### The five effect slots, and what each one drives (2026-08-22)

`SlotToTag` at **0x00EE636C** is literally `61 63 65 66 64 FF` -- dumped and checked here -- so the
slot order is an artefact rather than an assertion. `DSPCfg_SlotAcceptsAlgorithm` then validates
record byte 0 per slot, which is what names them:

| slot | tag | accepts | what it is |
|---|---|---|---|
| 0 | 0x61 | all but 16..27 (47) | DSP EFFECT (38) plus the 9 belonging to slots 2/3/4 |
| 1 | 0x63 | 9, 10, 16..27 (14) | DIGITAL REVERB -- 12 reverbs and 2 delays |
| 2 | 0x65 | 57..60 | ACOUSTIC ILLUSION (STANDARD / PERCUSSIVE / SYMPHONIC / DEEP SPACE) |
| 3 | 0x66 | 88..91 | ROOM / KARAOKE / BATH ROOM / STAGE |
| 4 | 0x64 | 79 | EQUALIZER |

Byte 0 IS the algorithm number, proven rather than inferred: the ROM reverb/EQ preset blobs at
0xEDB36C/0xEDB394 are copied straight to 0xFC8E/0xFCA8 and carry 16..27 and 79.

Three independent agreements with `docs/effects-dsp.md`, which was derived from the SUB CPU with no
shared code path: slots 2/3/4 together are exactly the nine IC310 algorithms, slots 0/1 exactly the
IC311 ones, and 47 - 9 = **38**, its DSP EFFECT page count. Corpus gate: **350 records across the
seven floppies, 0 violations**, byte-0 value sets disjoint between slots.

⚠ Correction to an earlier note: the "notify ids 0x4002/0x4006" are the slots' ON/OFF BITS, not slot
identifiers -- 0x4002/0x4004/0x4006 are tag 0x60 payload+1 bits 7/6/5 for slots 1/2/4, and 0x4140 is
tag 0x43 +0 bit 7 for slot 3.

### The record container: `<tag><len><payload>` (measured 2026-08-23)

The tag→address table at `0x00EDAE64` has **4-byte entries**, one per tag index,
each holding the address of a record's PAYLOAD in panel DRAM. 77 tags are
populated, covering 74 distinct addresses.

Reading the two bytes immediately BEFORE each payload gives the container:

```
<tag u8> <len u8> <payload: len bytes>
```

| check | result |
|---|---|
| header tag byte == table index | **74 / 77** |
| the 3 exceptions | **aliases**, not a format variant |

The three are `0xD0`/`0xD5` → `0xFF1A`, `0xD3`/`0xD6` → `0xFF56`, `0xD7`/`0xD8` →
`0xFF7E`: two tag indices naming the same record. In all three the header carries
one of its own aliases, so **every record's header tag matches a table index that
points at it — the rule holds 100% once aliasing is accounted for.**

Consequences worth having:

* **Tags `0x00`–`0x16` are the 23 per-part records**, `len = 0x18` = 24, at
  `0xF9B6` + 26·N. The stride of 26 is `2 + 24`, header included.
* These are exactly the blocks the NAKA widget query handlers read through the
  table at `0x00EE1160` — see `notes/FINDINGS-naka-record-format.md`. **The
  widget state queries read `.LSW` records by tag.**
* **Tag `0x9A` declares `len = 0x1A` = 26**, a different shape from the per-part
  records — and that matches the independently-derived split recorded below,
  where its subscriber accepts payload offsets 4..19 and the schema declares
  0..3 and 20..25, tiling exactly 26.
* Tag `0x9A`'s factory default is **26 zero bytes**, while the bytes around it are
  populated, so the zeros are specific to the record and not an empty area.

⚠ The factory default image at `0x00EDB3DC` is what makes this measurable from a
ROM dump at all: the records live in DRAM, but that image is their initial
content and it satisfies the loader's own `"HK"` signature check.

⚠ An earlier reading of this table at stride 2 gave `0xFFFF` for index `0x9A` and
appeared to contradict the `0xFFA4` recorded below. The stride was wrong — at 2
bytes every index is halved. `0xFFA4` is correct.

### Tag 0x9A: "touched by nothing" was half wrong

The earlier pass reported 0x9A as untouched. **Refuted in part**: it has a live subscriber written
specifically for it, accepting payload offsets **4..19 only**, indexing RAM 0x00F1A0 and classifying
through a ROM table at 0x00EE8EA2. And the split is exact -- the schema descriptors declare offsets
**0..3 and 20..25**, precisely the ten bytes the handler refuses. Together they tile all 26 with no
gap and no overlap, which is not the kind of agreement that happens by chance.

**Confirmed in part**: no instruction names it. The census returns 1/1/1/2/1/0 candidates across the
six dumped images and every one is explained -- all but one are `.. f1 b0 ff`, the tail of
`cp XBC,XWA` + `ret NC` seen mid-instruction, and the exception is a table-data interrupt vector
whose 0x00FFxxxx value is boot ROM in the pre-remap map, not panel DRAM at all.

⚠ The search is shown CAPABLE of finding one: the same scan collects 267-268 candidates for tags
0x78/0x48/0x80. And its limits are stated -- 75 of 131 queue-post sites pass the tag in a register
rather than a literal, so "nothing posts 0x9A" is NOT established, and the generic tag->address
table at 0x00EDAE64 holds 0xFFA4 at index 0x9A, so computed-pointer access is not excluded.

Also identified: **0x43 is the microphone record** -- on/off, a 0..127 level and a second on/off, on
one 9-cell screen at 0x00E34750 carrying slot 3's algorithm and its four values. The word
"microphone" is [INFERENCE] from the algorithm names and the `MIC LEVEL & REVERB` page title; the
screen-to-record binding and the field shapes are proven. **0x68 is declared, saved and ignored** --
no field descriptors, no parameter id, one bulk copy, and a subscriber whose entire body is four
`ret`s.

**RESOLVED 2026-08-22 -- `0x44/0x45/0x46` are the DRAWBAR (organ) registration, one record per
keyboard part: `0x44` = RIGHT 1, `0x45` = RIGHT 2, `0x46` = LEFT.**

The paragraph that stood here said they "have no parameter ids". That was an artefact of the
search, not a property of the data: the scan was restricted to ids `0x4000..0x4FFF`, and these
records carry **48 ids in `0x8200 / 0x8600 / 0x8A00`** -- one namespace per part, stride exactly
`0x400`. Widening the window found them immediately.

Evidence (addresses identical in v7, v9 and v10):

| what | where |
|---|---|
| 16 identical fields per record, ids differing by `0x0400` | `0xEDC946`, `0xEDCBAE`, `0xEDCE00` |
| nine fields with **max = 8**, tiling payload `+3..+7` as nibble pairs | ids `0x_280..0x_288` |
| the DRAWBAR page's item table, the nine max-8 ids first | `0xE9F88C`, read by `MainMemDrawControl` (`cp wa,0x8`) |
| the strings `DRAWBAR SETTING` and the nine-footage row `16' 5 1/3' 8' 4' 2 2/3' 2' 1 3/5' 1 1/3' 1'` | `0xE841E0`, `0xE84266` (fractions are separate glyphs) |
| the group index -- `ld A,(XSP+0x0c) / add A,0x44` | v9 `0xF84D42`, v7 `0xF848BB` |
| part <= 2 is arithmetic, not assumed: `u32[0xEDAE64+4*tag]` = `FC26/FC32/FC3E`, while `0x4A..0x5F` are all `FFFFFFFF` | verified by dump |
| part 0/1/2 = RIGHT1/RIGHT2/LEFT, from the DESCENDING name table | `0xE9F374` (RIGHT1), `0xE9F36C` (RIGHT2), `0xE9F364` (LEFT) |
| ROM power-on default, all three `00 00 00 88 80 80 00 00 00 00` = `16'=8 5⅓'=0 8'=8 4'=8 2⅔'=0 2'=8 1⅗'=0 1⅓'=0 1'=0` | `0xEDB3FC..0xEDB7BA` |

⚠ Stated limit: only three distinct byte values (`00 80 88`) occur in the corpus, so the corpus
check catches a gross misreading, NOT an off-by-one. The nibble order is pinned by the descriptor
table -- each id carries its own mask and shift -- not by the corpus.
⚠ Name trap: the handler lives in `demo/fdemotext_routines.s` and everything there is named
`FDemoText_*`, from an adjacent `Start the internal DEMO` string block. The module has nothing to
do with the demo.

**`0x71` -- role determined, LABEL still not determined.** No parameter descriptor anywhere names
it, and its only tag-specific subscriber is a bare `ret`. A whole-image census finds six candidate
sites in every version -- five real, one a false positive landing mid-instruction -- and **every
real site touches bit 1 only**: three `PmemOutLGridCheck` arms (set/clear/display, choosing
`0xE8013E " ON  "` / `0xE80144 " OFF "`) and the `bit 1,(0xFD2C)` gate in
`BitMapOut_Snapshot_PostProcess`. Since block 0 is `0x3C0` = 960 and `0xFD2C - 0xF9A0 = 0x38C`,
the grid's `0x1ED400 + index*0x3C0 + 0x38C` **is tag 0x71 payload+0 of panel-memory slot `index`**
-- so the bit is a **per-panel-memory ON/OFF flag**. Its UI name, and **bit 0** of the `0x03` mask
(touched by nothing in v7/v9/v10), remain open.

Provers: `analysis/disk-format-probes/lsw_drawbar_records.py` (9 tests on all three ROMs, exits
non-zero on failure; shifting one namespace or moving one field offset makes it fail) and
`README-lsw-drawbar-records-ADDENDUM.md`.

### The C0..D4 run is one companion block PER PART (2026-08-22)

The 21 consecutive tags `C0..D4`, plus `D7`, are not an array of something new: record `0xC0+T`
belongs to part record `T`. That is settled by a ROM POINTER TABLE, not by reading routine names.
`VoiceData_LookupPtrByChannel` (0x00FC9E04) indexes `u32[0x00EDB264 + 4*A]`, and that table reads:

    [00]..[14]  0xFDDA, 0xFDEE, 0xFE02 ...  stride 20, one-to-one with C0..D4
    [15]        0xFF1A  == entry [10]       part 0x15 SHARES part 0x10's block
    [16]        0xFF56  == entry [13]       part 0x16 SHARES part 0x13's block
    [18]        -> D7 ;  [19]..[1F] none ;  [48] -> tag 0x49

Verified here by dumping the table directly. The aliasing is what explains the family's shape:
**`D5` and `D6` were never needed** because parts 0x15 and 0x16 share their neighbours' blocks, and
tag `0x49` is the same kind of block for the style record `0x48`.

⚠ It LOOKED dead, and three machine-checked negatives say why -- all three run on v7, v9 and v10:
`SwbtWr_DispatchLoop` does `cp L,0xbf / jr UGT` before indexing its callback table, so **every event
tag >= 0xC0 is dropped**; none of the 64 `SwbtWr_QueuePostEvent` sites names a tag >= 0xC0; and a
whole-ROM direct-address census (653/746/746 candidates, 582/617/617 instruction-aligned, checked
against unidasm so it does not depend on how much `.byte` has been converted) finds ZERO real
accesses. All 154 C-family records in the seven floppies are zero. The block is reached only through
that pointer table, which is exactly the kind of access a name- or event-based search cannot see.

Other identifications, with grades, in `analysis/disk-format-probes/lsw_nonpart_records.py`:
`0x78` is the 16-character Music Stylist style name (`Strncpy(0xF9A2, StyleRec+43, 0x10)`, blank
filled with 0x20 -- which is why its descriptor says min=32 max=125 default=32); `0x61 63 65 66 64`
are five 24-byte DSP/effect slots; `0x48` style+tempo; `0x80` sequencer/MIDI clock; and part-record
offset **+0x0C is the MIDI channel**, from flash default blobs that set 0..15 for tags 0x00..0x0F
and 0xC0 ("none") for the drum parts.

**Re-verified 2026-08-23 with disassembly, and the negative got stronger.** A byte search for
`0xFFA4` (the record's address, from the 4-byte-stride tag table) returns 10 hits. Disassembling a
window around each shows **nine are byte coincidences** and the single operand-level hit —
`push 0xffa4` at `0x00F777A7`, inside `PcgOutCheck_SendPreset1` — is a **numeric argument**, not an
address: the callee `0x00FF0295` treats its FIRST pushed argument as an output buffer
(`ld (XWA),0x00`) and the pushes are values being formatted. So **zero of ten are a reference to
the record.**

That is the fourth time in one session that a byte-pattern search over this ROM produced plausible
false references (see spec anti-pattern 25). Here it matters in the safe direction: had the hit been
believed, `0x9A` would have been reported as "referenced by the preset-send path", which it is not.

### `0x9A` has NO tag-specific handler, in any dumped revision (2026-08-23)

`0x00EDAA64` holds a **tag -> handler table**: 256 consecutive u32, every one a
ROM code address, sitting `0x400` below the tag -> address table at `0x00EDAE64`.
**86 tags have a handler of their own; 170 share a default.**

| revision | table | default | tag `0x9A` |
|---|---|---|---|
| v7 | `0x00EDAA64` | `0x00FC8E02` x170 | `0x00FC8E02` — **DEFAULT** |
| v9 | `0x00EDAA64` | `0x00FC95CD` x170 | `0x00FC95CD` — **DEFAULT** |
| v10 | `0x00EDAA64` | `0x00FC95CD` x170 | `0x00FC95CD` — **DEFAULT** |

So across every dumped firmware, `0x9A` is dispatched generically. Together with
the other measurements it now has a complete PROFILE and no identity:

* container `<tag><len><payload>`, **`len = 26`** (from its own header)
* payload at `0xFFA4`, **factory default 26 zero bytes** in a populated area
* **no tag-specific handler** in v7, v9 or v10
* **zero code references** to its address (10 byte-matches, all disassembled: 9
  coincidences and one numeric argument to a formatting routine)

⚠ TENSION, not resolved: the subscriber finding above says `0x9A` has a live
subscriber accepting payload offsets 4..19 and classifying through
`0x00EE8EA2`. That is a different mechanism from this dispatch table, so both
can hold -- generic in the tag dispatch, specific in the subscriber -- but until
someone reads that subscriber against this table, the two descriptions are not
reconciled and should not be summarised as one.

**Still unidentified, stated plainly:** `0x9A` is touched by nothing but the generic init walk.
`0x68 0x43 0x71 0x44 0x45 0x46` have known shapes but no distinguishing routine. Which effect
`0x61/0x65/0x66` drive is unsettled, and the C-family's index-space meaning is [INFERENCE].

### Individual FIELDS attributed, from the firmware that writes them

`analysis/disk-format-probes/lsw_field_evidence.py` goes one level further and asks what byte N of
the record with tag T means. Two independent sources: every absolute access landing in
`0x00F9A0..0x00FFC0` mapped through the ROM schema onto (tag, offset) with its enclosing routine,
and the event protocol `SwbtWr_QueuePostEvent(e = tag, d = payload offset, a = value, w = mask)`.

That addressing rule is stated falsifiably and holds: **20 of 21 cross-checkable sites agree**; the
one exception is reported rather than smoothed over, and two more are skipped because their
neighbourhood is still `.byte`.

What the writers say the fields are -- the ROUTINE is proven, the human reading is [INFERENCE]:

| offset | routine that writes it | reading |
|---|---|---|
| +0 | `SeMenu_InitTrackInfo`, `EffectMode_CopyVoiceParams`, `BitMapOut_RestoreVoiceChannels` | the voice/tone selector -- and the ROM schema gives this field min=0 max=167 default=21, i.e. a 168-option selector, which agrees |
| +4 | `EffectMode_UpdateBitFlags` | effect bit flags |
| +13 | `AccPlay_RestoreMuteStates` | the part's mute byte |
| +14, +15 | `BitMapOut_ApplyIOChange_Port<N>` | I/O routing |
| +17 | `BitMapOut_ApplyIOChange_Port<N+3>` | second I/O routing |

**Ten of the record's 24 bytes are dead, and that is a measured claim.** `+10` has no descriptor
and no code touching it at all; nine more -- `+6 +11 +16 +18 +19 +20 +21 +22 +23` -- are declared by
a field descriptor and never touched by any code in v7 or v9. `+6` is stepped over explicitly: the
block copy moves `+5` then `+7`. So a third of the per-part record is reserved or abandoned, which
is worth knowing before anyone tries to give those bytes a meaning.

That measurement needed a second attribution method. `lsw_field_evidence.py` scans ABSOLUTE operands
only, and most of the record is never reached that way; `lsw_part_record_fields.py` adds a
base-pointer + displacement pass and gets **294 attributions against 280 absolute**. It also proves
the event protocol rather than correlating it: `SwbtWr_QueuePostEvent` at 0xFDB3F1 appends
`(XHL)=DE, (XHL+2)=WA` to a queue at 0xBF39, so the entry IS `[tag, offset, value, mask]`.

⚠ Two traps it hit, both recorded in that probe: the assembler prints displacement 0 as `+256`
(`ld a,(xiy+256)` is `[0x8d,0x00,0x21]`), so a naive scan invents an offset 256; and the ±12-line
cross-check copied from `lsw_field_evidence.py` produced 8 disagreements that were **all the gate's
fault** -- a line window can pair one clone's pointer with the next clone's event. Routine-scoped,
15 of 15 agree. The older probe still uses the line window and passes only by luck of layout.

**The strongest structural result is in that port number.** It TRACKS THE TAG: tag 00 writes Port0,
tag 01 Port1, tag 02 Port2 at +14/+15, and Port3/4/5 at +17. Twenty-four records each owning a port
pair is what a per-PART table looks like, which settles what the 24 slots are -- not 24 saved
setups, but the 24 parts of one setup.

So: the 24 slots are 24 instances of the panel record set; the container is proven from firmware
rather than inferred from shape; and per-field TYPES AND RANGES are readable out of the ROM without
any hardware. What is still open is the human meaning of each field -- a field with min=0 max=167
default=21 is plainly a selector with 168 options, but which selector it is needs the bench or the
UI strings.

**What the 24 blocks are, structurally, is now measured** -- 24 instances of ONE fixed TLV schema,
identical across all seven disks:

    block 0      37 records, tags 0x00..0x16 + 0x19 at 30 B each   (extended form)
    block 1      30 records, a DIFFERENT tag set, opening 0x17 0x18 ...
    blocks 2..25 37 records, tags 0x00..0x16 + 0x19 at 22 B each   (the 24 slots, 692 B each)

    slot schema:  00..16,19 x 22 B  |  44 45 46 48 x 10 B  |  90 x 5  |  60 x 12
                  61 x 30  |  63 x 30  |  70 x 5  |  72 x 14  |  92 x 14  |  71 x 4  |  80 x 10

Three things make this more than a shape. **The tag space is partitioned**: 0x17 and 0x18 appear only
in block 1 and never in a slot, whose sequential run stops at 0x16 and resumes at 0x19 -- a split
that is deliberate, not incidental. **Block 0 carries the same tag sequence with larger payloads**
(30 B where a slot has 22 B, and four other records longer too), so it reads as an extended form of
what the slots hold compactly. And **the same 17 of 37 records vary between slots on every disk**,
the other 20 being constant, so the schema has a stable identity part and a stable payload part.
Between 15 and 20 of the 24 slots hold distinct content depending on the disk.

Reproduce: `analysis/disk-format-probes/lsw_slot_schema.py <dirs>`, which asserts 26 blocks, one
shared 37-record 692-byte schema across 24 slots, and one varying-record set across all disks.

Inside the 22-byte records there are **two layouts**, separating exactly where the tag families do
(`--map` reproduces this; X varies across slots, c constant non-zero, `.` constant zero):

    tags 00..0F     ...cc..cccccccc..c....     trailing bytes carry constants
    tags 10..16,19  XX.XX..Xcccc.X........     last nine bytes always zero

Tags 04..0E and 16 are byte-identical across all 24 slots. Tags 00, 01, 02, 10, 11, 12 carry the
most variation, and byte 0 of those spans 0..119 -- consistent with a 0..127 program number, though
that is [INFERENCE] and not shown.

⚠ **One reading tested and REJECTED.** Byte 13 of the `10..16,19` records spans 192..207 across
slots, which is exactly MIDI Program Change status `0xC0|channel` -- a very inviting fit. Dumping it
per slot kills it: the value is `0xC0` in nearly every slot for every one of those records, so it is
not a per-record channel. An attractive numeric range is not a field identification.

**What is still open is the meaning of the tags**, and it cannot be settled from these files alone.
"Current panel" makes a per-part reading plausible, but plausible is where the panel-memory reading
started too, and that one was wrong. Two things would settle it: the firmware of whatever WROTE
these files (not the KN5000), or an A/B on real hardware -- change one panel setting, re-save, diff
the slot. The second is cheap for anyone with the instrument in front of them.

### Searched and absent -- the header magic is in NO dumped firmware

A reader that validates `.LSW` would have to compare against the header. It does not exist to
compare against:

| searched for | KN5000 | KN6000 (`kn6000_program_full.bin`, 4,160,049 B) | KN7000 (decompressed, 4,157,184 B) |
|---|---|---|---|
| `"M60"` | absent | absent | absent |
| `5A 5A 01 00` | absent | absent | absent |
| `"LKE"` (the 0x4EB0 magic) | absent | 1 FALSE POSITIVE | absent |

So `"M60"` is **not** a model code the way `M60`/KN6000 invites you to read it -- the KN6000 image
does not contain that string either.

⚠ The single `"LKE"` hit, at KN6000 file offset 0x3BCCF3, is **not** the magic. It straddles two
entries of a pointer array whose elements all look like `XX 45 27 4C` (LE32 0x4C2745XX), so the
`4C 4B 45` there is `...L` + `KE...` of two adjacent pointers. A three-character magic is short
enough to occur by chance in a pointer table -- always dump the context before believing the hit.

> ⚠ **RETRACTED (2026-08-22).** "No dumped firmware validates the `.LSW` header" is false --
> `FileIO_CheckRegionSignature(0)` checks `"HK"` at offset 4 via the table at `0xEA0104`. What
> follows about `"LKE"` not being a magic still stands; the error was concluding from one absent
> magic that NO check exists. The seven floppies are `"M60"` headers, which the loader classifies
> as format 2 (`FileData_AllocLoadAndParse` tests bytes [4],[5] for `'M','4'`/`'M','6'`/`'N','N'`)
> and imports through a converter -- so a failing `"HK"` does not stop the load.

Superseded text: no dumped firmware validates the `.LSW` header, so **the format cannot be recovered by
finding its magic check** in any image we hold. Either the loader reads the blocks without checking,
or the writer of these files is something not dumped. Note the same disks' `.LSW` embeds a byte-exact
copy of their `.MSP` prefix, and the KN5000 does parse `.MSP` -- so a KN5000-family machine wrote
them, which the "no KN5000 code parses `.LSW`" result above does not explain. That tension is the
sharpest remaining thread.

**The handles for whoever continues**: the widget-NAME trace is now spent -- `SD_LD2_LBLSW` is a
static label descriptor (geometry + text) with no code attached, the same shape as its 36 siblings.
The parser hangs off the LOAD action, not the label: `SD_LD2_R1SW` / `SD_LD2_R1LB` ("LOAD") and the
`SD_LD2_B*SW` switch widgets are the untried entry points.

**One dead end already eliminated, so nobody repeats it.** The KN7000's file-type table is at
address **0x48664454** (image base 0x48400000, confirmed by its own pointer values), 14 entries.
It has exactly three code references -- 0x4852F89E, 0x485300AB, 0x48532300 -- and the first
disassembles as a FILENAME BUILDER, not a type dispatch:

    4852F887  mov d0,d2                 ; d2 = file-type index
    4852F889  call 0x4852F762           ; copy the name
    4852F88F  mov 0x48664588,a1         ; the constant "." (verified: bytes 2E 00)
    4852F895  call 0x4852F7AE           ; append
    4852F89B  asl2 d2                   ; index * 4
    4852F89C  mov 0x48664454,a0         ; the extension pointer array
    4852F8A2  mov (d2,a0),a1            ; a1 = extension string
    4852F8A5  call 0x4852F7AE           ; append

i.e. `name + "." + ext[type]` -- the same role the equivalent table plays in the KN5000
(`FileIO_BuildFilePath`). So the extension table leads to filename construction in BOTH firmwares
and will not lead to the parser in either. Start from the SD-menu widget handlers instead.

Disassemble with: `unidasm <slice> -arch mn10300 -basepc <addr>`, where the file offset is
`addr - 0x48400000`. unidasm does not seek, so `dd` the bytes out first.

**ESTABLISHED (2026-08-22): the 24 slot blocks are PANEL MEMORIES**, 0x300 each at file
0x0680..0x4E80. Proven from the format-2 importer, whose 37 hard-coded offsets reproduce the
measured 24-slot schema to the byte across all seven files, and whose destination stride of 960
equals TLV block 0's size. See the retraction above for why the earlier "in tension with the
extension table" reasoning was wrong.

Still open, and stated plainly: **why format 2 imports only 10 of the 24** (`0x000A` is a literal;
format 1 uses `0x0018`). Header byte +7 is `0x0A` = 10, but the firmware ignores it, so that byte
is NOT shown to be a count. A format-1 (`"M4"`) file would settle it. Also open: the 0x30 gap at
0x4E80 and the 0xC0 at 0x53C0 -- the "24 u16 words" reading was TESTED AND NOT SUPPORTED (in
`02BOSSA_.LSW` slots 15..23 duplicate 5..13 while the words do not).

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
