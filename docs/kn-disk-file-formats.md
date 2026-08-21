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

**`PMT` and `LSW` are separate file types in the same table.** So the tempting reading of `.LSW`'s
24 slot blocks as panel memories is not merely unsupported, it is contradicted: panel memory has
its own extension, and these disks do not carry a `.PMT` at all. Recorded because that reading is
the first one anybody will reach for.

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

**No KN5000 code has been shown to read or write `.LSW` CONTENTS** -- only to name the extension,
glob for it in a test path, and carry an event named after it. What the letters stand for is NOT
proposed here; the neighbouring names make "switch" likely for the SW and nothing establishes the L.

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

**What the 24 blocks are** is still open. "Current panel" makes a per-part or per-section reading
plausible, but plausible is where the panel-memory reading started too, and that one was wrong.

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

Consequence: no dumped firmware validates the `.LSW` header, so **the format cannot be recovered by
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
