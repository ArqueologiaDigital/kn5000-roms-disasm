# `.LSW` formats 1 (`"M4"`) and 3 (`"NN"`), and why format 2 reads only 10 slots

Companion note to `analysis/disk-format-probes/lsw_formats_1_and_3.py`.

```
python3 analysis/disk-format-probes/lsw_formats_1_and_3.py                    # ROM only
python3 analysis/disk-format-probes/lsw_formats_1_and_3.py /tmp/disk/*/       # + the 7 floppies
python3 analysis/disk-format-probes/lsw_formats_1_and_3.py --quiet /tmp/disk/*/   # just the gate
python3 analysis/disk-format-probes/lsw_formats_1_and_3.py --layout          # print the maps
```

It exits non-zero if any of the thirteen tests stops holding, on v7, v9 **and** v10. Corpus:

    mkdir -p /tmp/disk && cd /tmp/disk
    for z in ~/compartilhado/KN7000/floppy-archive/*.zip; do
        n=$(basename "$z" .zip); mkdir -p "$n"; unzip -o -q -d "$n" "$z"; done

Every ROM address below is **derived from one byte anchor per revision**, never hard-coded, and
the probe prints them. It found, and asserts:

| role | v7 | v9 / v10 |
|---|---|---|
| dispatcher inside `FileData_AllocLoadAndParse` | `FD1F1B` | `FD26EC` |
| header classifier `'M4'`→1 `'M6'`→2 `'NN'`→3 | `FD4AD1` | `FD52A2` |
| **formats 1 and 2** stage 1 (live panel) | `FD1F9D` | `FD276E` |
| **formats 1 and 2** stage 2 (panel memories) | `FD2167` | `FD2938` |
| **format 3** stage 1 | `FD3B95` | `FD4366` |
| **format 3** stage 2 | `FD3D04` | `FD44D5` |
| default-fill one panel memory | `FD4B93` | `FD5364` |
| blank one panel-memory **bank name** | `FD4C85` | `FD5456` |
| format-3 DSP converter | `FD443B` | `FD4C0C` |
| file read (sequential) | `F88967` | `F88D74` |
| file seek | `F88AD3` | `F88EE0` |

---

## 1. Format 1 is format 2 with 24 panel memories instead of 10 — PROVEN

The dispatcher calls **the same two routines** for format 1 and for format 2:

```
fd26f3: cp HL,3 / jr Z   -> fd270f: calr FD4366 ; calr FD44D5      (format 3)
        cp HL,2 / jr Z   -> fd26ff: calr FD276E ; calr FD2938      (formats 1 and 2)
        cp HL,1 / jr NZ  -> ld IZ,0xff9a                           (unknown)
```

and inside stage 2 the *only* thing the format id selects is one immediate:

```
fd293c: ld WA,(fmtvar)
fd2940: cp WA,1 / jr Z, fd29bb -> ld (XSP+0x0c),0x0018     <-- FORMAT 1: 24 panel memories
fd2944: cp WA,2 / jr NZ, error
fd2948:                           ld (XSP+0x0c),0x000a     <-- FORMAT 2: 10 panel memories
```

That count then drives three things, and nothing else in the importer depends on the format:

* `calr FD5364` — fill *count* slots at `0x1ED400 + 960*j` with the factory default (ROM
  `0xEDB3FC`, `0x3C0` bytes);
* `count >> 3` calls of `FD5456` — blank that many panel-memory **bank names**;
* the trip count of the loop that reads `0x300` bytes per slot.

So **format 1 has exactly the layout already documented for format 2, with 24 slot blocks
instead of 10**, and its total size is

    0x20 header + 0x660 (TLV block 0 + TLV block 1) + 24 * 0x300  =  0x4E80  =  20,096 bytes

against format 2's `0x20 + 0x660 + 10 * 0x300 = 0x2480 = 9,344`.

⚠ Note the coincidence and do not over-read it: `0x4E80` is also exactly where the M60 files'
slot array ends. That the `"M60"` container is shaped like a format-1 file with a `0x980` tail
appended is **[INFERENCE]**, not proof; the arithmetic is the whole of the evidence.

## 2. Format 3 is a different, narrower layout — PROVEN

Its two stages are separate routines with their own constants. Everything below is read off
those constants; the destination offsets are checked against the ROM's own factory-default
panel image, so the tags are measured rather than assumed.

```
FORMAT 3 -- live panel (stage 1, FD4366)
    0x0000  0x0020  header (bytes [4],[5] = 'N','N')
    0x0020  0x0114  23 part records of 12 BYTES  ->  0x00F980+0x34, stride 26
                    (formats 1/2 use 32-byte part records and import 24, not 23)
    0x0134  0x0012  tag 0x48   style / rhythm selection + tempo
    0x0146  0x0008  tag 0x90
    0x014E  0x0012  tag 0x70   digital effect
    0x0160  0x0006  tag 0x71   panel-memory ON/OFF
    0x0166  0x000A  tag 0x72
    0x0170  0x02B0  the rest, reached by three whole-buffer converters:
                      * a 4-byte-per-part array at 0x019E, indexed through the 24-entry ROM
                        permutation at 0xEE1584 = 17 14 13 10 11 12 00..0F 15 16
                      * 0x0152 / 0x0153 / 0x0155   -> the DSP slots (see section 5)
                      * 0x0173..0x018B, 0x0200..0x0210, 0x03EE..0x03FE
    total           0x0440

FORMAT 3 -- panel memories (stage 2, FD44D5): 24 records of 0x150
    0x0440 + 0x150*j                 ->  0x1ED400 + 960*j
```

**A format-3 panel-memory record is byte-for-byte the first `0x150` bytes of the live-panel
body.** Every stage-2 offset is its stage-1 counterpart minus `0x20`, on *both* sides — the
same relationship formats 1/2 have, and the probe asserts all five pairs, source and
destination:

| | stage 1 (live) | stage 2 (slot) | tag |
|---|---|---|---|
| src / dst | `0x134` / `+0x2D8` | `0x114` / `+0x2B8` | `0x48` |
| | `0x146` / `+0x2E4` | `0x126` / `+0x2C4` | `0x90` |
| | `0x14E` / `+0x380` | `0x12E` / `+0x360` | `0x70` |
| | `0x160` / `+0x3AA` | `0x140` / `+0x38A` | `0x71` |
| | `0x166` / `+0x38A` | `0x146` / `+0x36A` | `0x72` |

Format 3's total is `0x20 + 0x420 + 24 * 0x150 = 0x23C0 = 9,152 bytes`.

### What format 3 does NOT carry

Formats 1/2's stage 1 also copies tags `0x44`/`0x45`/`0x46` (the drawbar registration),
`0x60`, `0x61`, `0x63`, `0x92` and `0x80` straight across. **Format 3 has no direct copy of any
of them.** It reconstructs `0x60`/`0x61`/`0x63` through the DSP converter (section 5), and its
three converters instead reach block-1 records `0x98`, `0x91`, `0x93` and `0x99`, which formats
1/2's stage 1 never touches.

That the drawbar trio is present in the format-1/2 layout and absent from format 3 is a small
independent corroboration of `README-lsw-drawbar-records.md`: the record the KN5000 must import
from the newer generation and cannot get from the older one is exactly the one identified as a
drawbar registration. **[INFERENCE]** — absence has other explanations (the format-3 machine may
simply have had no drawbars *page*), and this is one bit of evidence, not a proof.

### What "M4" / "M6" / "NN" ARE as products — NOT DETERMINED

The KN5000 clearly reads three *predecessor* formats: its own `.LSW` header is `"HK"`, and the
sound-RAM importer beside it carries the magic list `KN2000 / MKA / MKB / KN3000 SOUND RAM /
KN1500 SOUND RAM / KN5000 SOUND RAM` at `0xEED53B`. But **no string anywhere in the three
program ROMs, the table-data ROM or the sub-program ties `"M4"`, `"M60"` or `"NN"` to a model
name**. The search, on all seven dumped KN5000 images:

```
for f in original_ROMs/kn5000_v7_program.rom original_ROMs/kn5000_v9_program.rom \
         original_ROMs/kn5000_v10_program.rom original_ROMs/kn5000_table_data.rom \
         original_ROMs/kn5000_subprogram_v142.rom original_ROMs/kn5000_subcpu_boot.ic30 \
         original_ROMs/kn5000_custom_data.ic19; do
    echo "$f"; strings -a -n 3 "$f" | command grep -iE 'M60|M40|KN[0-9]{4}|MODEL'; done
```

Exactly one hit for `M60` anywhere: `BM60` at table-data `0x80418` and `0xBAFE6`, which is the
Windows BMP magic `BM` followed by the size field of a 320x240 8-bpp bitmap (`36 04 00 00` /
`28 00 00 00` / width `0x140` / height `0xF0`), not a model name. Naming the formats needs an
`.LSW` of known provenance, not this ROM.

Two facts that constrain the answer and are worth writing down:

* the same generation number appears in the `.SQF` header on these disks. `DataBuf_CheckSubFormat`
  (`FD52D6` / v7 `FD4B05`) classifies a buffer on bytes `[5]`,`[6]`: `1,6`→1, `1,7`→2, `1,3`→3.
  The floppies' `.SQF` opens `5A 5A 5A 5A 01 01 07` → **format 2**, agreeing with their `.LSW`'s
  `"M6"`. So "format 1/2/3" is a *disk generation*, not a per-file-type quirk.
* the `.TM` on these same disks carries `KN1500 SOUND RAM`, and a raw byte search of
  `~/compartilhado/kn7000_scratchpad_snapshot/kn7000_program.rom` and `kn7000_table.rom`
  (4,157,185 and 4,101,332 bytes) finds **no** `"M60"`, `"M40"`, `"LKE"` and no
  `5A 5A 01 00 4D 36 30 0A` — while `"HK"` occurs in both. ⚠ Those two images are the working
  copies in the KN7000 scratchpad, not this repo's ROMs, and a compressed payload inside them
  would not be seen by a raw search; treat this as "not found", not as "absent". The writer of
  these disks is at any rate not a KN5000, which writes `"HK"`.

## 3. Why format 2 imports only 10 of the 24 slot blocks — SOLVED, and no format-1 file was needed

Because only 10 of them carry anything. Measured over all seven floppies:

```
slot block index         0 1 2 3 4 5 6 7 8 9 | 10 11 12 13 14 15 16 17 18 19 20 21 22 23
identical on all 7?      n n n n n n n n n n |  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y
```

* blocks **10..23 are byte-identical across all seven disks** — they carry no per-disk
  information at all;
* they are periodic with period 10: `block[i] == block[10 + (i-10) % 10]` on every file
  (blocks 20..23 repeat blocks 10..13);
* and they are the **defaults**, not merely a constant: on `02BOSSA_.LSW`, user slots 5..9 are
  byte-identical to blocks 15..19 — five untouched panel memories still holding
  `default[5..9]`.

So the array being written is `slot[i] = default[i % 10]` with only slots 0..9 user-reachable.
Ten is the real payload.

**And the firmware's cursor stops exactly there.** Every read on the importer path is
sequential — the seek routine `F88EE0` appears **zero** times in any of the five importer
routines, and `FileIO_CheckRegionSignature` ends by rewinding (its last call reaches a routine
that pushes `whence=0, offset=0L` into the very same `fseek` primitive the seek helper uses),
so the first importer read starts at file offset 0. Total consumed for format 2:

    0x20 + 0x660 + 10 * 0x300  =  0x2480  =  the first byte of slot block 10

The KN5000 reads every byte that carries information and **not one byte more**. Header byte
`+7` is `0x0A` on all seven files, agreeing with the count — though the firmware still ignores
that byte and hard-codes, so "byte +7 is a count" remains **[INFERENCE]**; what is now proven
is that the *value* 10 is right.

⚠ This retires the "settle it with a format-1 file" item in
`README-lsw-region-to-block-map.md` §5. A format-1 file would still be interesting — nobody has
seen one — but it is no longer needed to explain the 10.

## 4. The `0x30` at `0x4E80` and the `0xC0` at `0x53C0` — NOT DETERMINED

### What the ROM can say: nothing, and that is now proven rather than assumed

The KN5000 never *reads* those bytes. The importer's last read ends at `0x2480`; there is no
seek on the path; the native (`"HK"`) loader is not taken for these files because their
signature check fails. Searching the ROM for code that reads file offset `0x4E80` is therefore
not a search that could have succeeded, and reporting "nothing reads them" as a finding about
the ROM would be reporting a property of the question.

### What the data says

`0x53C0..0x5480` (0xC0):

* one 16-byte pattern `00000000 FFFFFFFF FFFFFFFF 00000000` repeated **12 times**, and
* **byte-identical on all seven disks.**

Zero per-disk information. Any 16-byte-record reading of it is unfalsifiable from this corpus,
because an all-empty structure looks periodic at every divisor of its length.

`0x4E80..0x4EB0` (0x30) does vary — six distinct blobs over seven disks:

```
04BOS_MX  9f bb 9e ab 88 a3 08 a2 02 82 00 00 9e bb 9f fb 03 80 9e bb 00 00 18 82 ...
04BROWNI  9f fb 9e bb 08 82 08 82 02 82 00 00 9f bb 9f fb 03 80 9f bb 00 00 08 82 ...
01CAN_SU  9e bb 9e bb 00 82 9e b3 02 92 00 00 9f bf 9e bb 03 80 9f bb 00 00 9e a2 ...
03A_CNAT  df ff 9e bb 00 02 00 02 02 82 00 00 9e b3 9c b3 03 80 9f bb 00 00 1e a2 ...
07MAME__  02 02 00 02 ff ff ff ff 02 ff 00 00 00 00 00 00 03 80 00 00 00 00 ff ff ...
05NEANST  = 04BROWNI
02BOSSA_  02 00 00 00 ff ff ff ff 02 ff 00 00 00 00 00 00 03 80 00 00 00 00 ff ff ...
```

Constant on all seven: `+0x08`=`02`, `+0x0A`,`+0x0B`=`00`, `+0x10`,`+0x11`=`03 80`,
`+0x14`,`+0x15`=`00`, `+0x23`=`00`. Two of the seven (`07MAME__`, `02BOSSA_`) look empty —
`FF FF` / `00 00` where the others hold data — which is why the byte alphabet alone does not
pin a record size.

### The "24 u16, one per slot block" reading is refuted a SECOND time

The original refutation was that `02BOSSA_`'s slots 15..23 duplicate 5..13 while the words do
not. There is now an independent argument that does not depend on one disk: **slot blocks 10..23
are constant across all seven disks, so a per-slot field would be constant there too — and
words 10..23 are not.** The probe checks the reversed word order as well (words 0..13), and
that fails the same way. Both directions are asserted, so the refutation is a test, not a memory.

### What would settle it

In descending order of decisiveness:

1. **A differential capture on the machine that writes these files**: two `.LSW` saved back to
   back with exactly one user-visible setting changed. `0x30` is 48 bytes; a handful of such
   pairs would name every field in it, and it is the only method here that does not need
   another firmware dump. It needs identifying the machine first (section 2).
2. **That machine's program ROM.** Its `.LSW` *writer* names every byte; the KN5000 only ever
   sees the parts it converts.
3. **A `.LSW` written after deliberately filling all 10 panel memories and all 128 style-voice
   entries**, which would show whether the `0xC0` is a tail of the style-voice array (its count
   field says 128, and `0x10 + 128*10` lands exactly on `0x53C0`) or a separate block.

What will *not* settle it: any amount of further searching in the KN5000 ROMs.

## 5. Things that fell out on the way

### The KN5000 has 10 panel-memory BANKS of 8 — and the bank names live at `0x1ED360`

`FD5456` is

```
    if (WA > 9) return;                          ; cp WA,0x0009 / ret UGT
    memset(0x1ED360 + 16*WA, ' ', 16);           ; lda XBC,0x1ED360 / sll 4,WA / memset(.,0x20,0x10)
```

so there are **10 names of 16 characters** at `0x1ED360`, and `0x1ED360 + 10*16 == 0x1ED400`
— they end exactly where the 80 panel-memory slots begin. Stage 2 blanks `count >> 3` of them
for `count` imported memories, i.e. **a bank holds 8 memories**, and `10 * 8 == 80 ==
(0x200000 - 0x1ED400) / 960`. Two independent numbers, one answer.

(Format 3's stage 2 hard-codes both: `ld WA,0x18` = 24 memories and `cp IZ,3` = 3 banks.)

⚠ One rough edge, stated rather than smoothed: 10 imported memories span *two* of the KN5000's
banks, but `10 >> 3` blanks only one name. Either that is a rounding bug, or a bank on the
format-2 machine holds 10. Not settled here.

### A DSP slot's parameter namespace: `+0x00` algorithm, `+0x04` count, `+0x10+i` parameter

The format-3 DSP converter (`FD4C0C`, v7 `FD443B`) carries, in this order:

    0xEE159C -> id 0x4900, 0x4904, 0x4910+i        (writes tag 0x61 payload+0 = 0xFC74)
    0xEE15AC -> id 0x4B00, 0x4B04, 0x4B10+i        (writes tag 0x63 payload+0 = 0xFC8E)

It reads the algorithm number through a translation table, writes it as `0x4?00`, zeroes the
rest of the 24-byte slot record, asks `0x4?04` how many parameters that algorithm has, and
then writes `0x4?10+i` for each. So within a slot's namespace `0x4?00` is the algorithm,
`0x4?04` the parameter count and `0x4?10+i` parameter *i*. **[CODE]**

### A third, independent agreement with the DSP slot table

`README-lsw-leftover-records.md` §1 derived, from `DSPCfg_SlotAcceptsAlgorithm`, that slot 0
(tag `0x61`, ns `0x4900`) accepts everything except 16..27 and slot 1 (tag `0x63`, ns `0x4B00`)
accepts only `{9, 10} ∪ [16, 27]`. The two format-3 translation tables agree without being
asked to:

    0xEE159C  00 01 20 21 23 09 0a 04 05 00 ...   every value accepted by slot 0
    0xEE15AC  11 11 14 15 15 15 0a 0a 0a 0a ...   every value accepted by slot 1

and the agreement is **not vacuous**: swapping the two tables violates both predicates (the
probe asserts that too). This is a third route to "slot 0 = DSP EFFECT, slot 1 = DIGITAL
REVERB", sharing no code with either of the first two. It also says the format-2/3 machine had
**9 DSP-effect types and 10 reverb types**, mapped onto KN5000 algorithms
`{0,1,4,5,9,10,32,33,35}` and `{10,17,20,21}`.

### The v7 symbol reference is offset by `+0x41A` in this block

`symbols/maincpu_v7_symbols_reference.txt` places `FileData_AllocLoadAndParse` at `00FD2305`,
`FileData_RawDataBlock` at `00FD23B7`, `DataBuf_AllocAndLoadFormatted` at `00FD27A5`,
`FileData_LoadAndParseType3` at `00FD426E` and `DataBuf_CheckSubFormat` at `00FD4F1F`. The real
v7 code is at `00FD1EEB`, `00FD1F9D`, `00FD238B`, `00FD3E54` and `00FD4B05` — **every one of
them `0x41A` lower**, and none of the derived addresses appears in that file at all. The v9 and
v10 references are correct, and so is the v7 reference for the neighbouring `F8xxxx` file-I/O
block (`FileIO_CheckRegionSignature 00F86DA2` is right to the byte). Reported, not fixed.

---

## PROVEN vs INFERRED

**PROVEN (from instructions, or from bytes in the seven files):**

* formats 1 and 2 share both importer stages; the only format-dependent value is the panel-memory
  count, `0x18` vs `0x0A`
* format-1 file size `0x4E80`, format-2 `0x2480`, format-3 `0x23C0`
* the format-3 layout table in section 2, including that a slot record is the live body's first
  `0x150` bytes
* the destination tags: every offset lands on a real TLV record start in the ROM's own default
  panel image
* the importer never seeks, and the signature check rewinds, so the format-2 cursor stops at
  file offset `0x2480`
* slot blocks 10..23 are identical across all seven disks, are period-10, and are the defaults
* the `0xC0` at `0x53C0` is one 16-byte pattern × 12 and identical on all seven disks
* the `0x30` at `0x4E80` varies per disk and is not 24 per-slot u16 words, in either order
* 10 panel-memory bank names of 16 bytes at `0x1ED360`; 10 banks × 8 memories = 80
* the DSP parameter namespace shape `+0x00 / +0x04 / +0x10+i`
* the two format-3 DSP translation tables satisfy the slot predicates, and swapping them does not

**[INFERENCE], with the falsifier stated:**

* *the `"M60"` container is a format-1 file plus a `0x980` tail.* Only the arithmetic
  `0x680 + 24*0x300 == 0x4E80` supports it. Falsifier: a real format-1 file that is not `0x4E80`
  bytes, or whose slot count in its own header byte `+7` is not `0x18`.
* *header byte `+7` is the panel-memory count.* It equals 10 on all seven files and the firmware
  uses 10 — but the firmware reads a literal, not that byte. Falsifier: a format-2 file whose
  byte `+7` is not `0x0A`.
* *`"M4"`, `"M60"`, `"NN"` are predecessor-model generations.* Supported by the `.SQF`
  generation byte agreeing, and by the sound-RAM importer's KN1500/KN2000/KN3000 magic list.
  Nothing ties a specific magic to a specific model.

**NOT DETERMINED:** what the `0x30` and the `0xC0` are; which product each format belongs to;
whether the `10 >> 3` bank-name blanking is a bug or a different bank size.

---

## Can it fail?

Checked, in both directions:

* ROM, format-2 slot count `0x000A` → `0x000B` →
  `R[v9] R4: stage2(1/2) constants differ` **and** `R4: expected exactly one ld (XSP+0xc),0x000a`;
* ROM, reverb translation table entry `0x14` → `0x50` →
  `R[v9] R12: 0xEE15AC holds [80], which slot 1 rejects`;
* ROM, the rewind primitive's `whence` `0` → `2` →
  `R[v9] R13: the rewind primitive at 0xf4f5e4 does not push whence=0, offset=0L`;
* file, header `M6` → `M4` → `F1: magic b'M40'`;
* file, one byte of slot block 20 flipped → `F4: block 20 != block 10` and
  `F3: slot blocks 10..23 are NOT identical across the 7 files`;
* file, one byte of the `0xC0` changed → `F7: 0x53c0 is not 12 x ...` and
  `F7: 0x53c0..0x5480 differs between files`;
* **and the honest direction** — running it on a corpus of one file duplicated twice gives
  `F3: slot blocks 0..9 are identical across every file -- the corpus cannot distinguish
  payload from filler`, `F5: no user slot ... equals its default counterpart`, and
  `F8: the "24 u16, one per slot" reading was NOT refuted`. A corpus too weak to support the
  conclusion makes the probe fail rather than pass.

---

## Corrections other files need (not applied here — this pass was told not to edit)

1. `README-lsw-region-to-block-map.md` §5, first bullet: *"Settle it with a format-1 file … or
   with an `.LSW` written by a real M60 machine after storing a 24th panel memory."* Settled
   without either — see section 3. The 14 unread blocks are constant across every disk.
2. Same file, §5, third bullet: *"What `"M4"` and `"NN"` are. Format 3 has its own importer pair
   (`0xFD4366`, `0xFD44D5`), untouched here."* Now read; sections 1 and 2.
3. Same file, §1 table and §2: nothing wrong, but the writer/loader table can gain the
   format-3 pair and the `FD5364` / `FD5456` helpers.
4. Same file, §5, second bullet: the 24-u16 refutation can cite the cross-disk argument, which
   does not depend on `02BOSSA_` alone.
5. `symbols/maincpu_v7_symbols_reference.txt`: the `FileData_*` / `DataBuf_*` block is `0x41A`
   too high — see section 5.
6. `docs/kn-disk-file-formats.md` `.TM` paragraph notes the `KN1500 SOUND RAM` magic as an
   oddity; the magic *list* at `0xEED53B` (`KN2000 / MKA / MKB / KN3000 SOUND RAM /
   KN1500 SOUND RAM / KN5000 SOUND RAM`) explains it — the KN5000 imports several predecessors'
   sound RAM, so a foreign magic on a disk is expected, not anomalous.
