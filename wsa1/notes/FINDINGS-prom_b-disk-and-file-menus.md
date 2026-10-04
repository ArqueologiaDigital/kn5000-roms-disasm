# The disk and file menus, and the third way a display list is entered

**Where.** `prom_b/wsa1_prom_b.s`, `0xF57D4F-0xF5A7FF` (10,929 bytes) — the last
large `.incbin` between INTT2's handler and the SC1 link module.

**Reproduce.** Three committed scripts, all with a `--selftest`:

```
python3 notes/prom_b_dl_stack_sites.py --selftest        # 23 checks — the call-site census
python3 notes/gen_prom_b_f58000_module.py --selftest     # 73 checks — the emitter
python3 notes/prom_b_diskmenu_entrypoint.py              # 13 checks — what draws the disk menu
python3 scripts/analysis/assert_byte_identical.py        # the gate
```

Converted this round: **+7,291 substantive bytes** and 3,638 bytes of disclosed
pad, taking prom_b from 292,087 to **299,378** substantive
(`scripts/analysis/source_coverage.py`).

---

## 1. Why 7 KB of user interface stayed invisible for six rounds

`scripts/analysis/prom_b_display_lists.py` finds a display list by one
instruction shape:

```
ld XIY,<start>   (45 ..)     ld XIX,<end>   (44 ..)     call 0xF417F0 / 0xF417F4
```

**Not one list in this module is entered that way.** The count of register-form
call sites whose start lies in `0xF58000-0xF59C5A` is **zero**. That is why
`notes/prom_b_span_frontier.py` reported this span with `proven 0`, and why six
rounds of display-list work walked past it.

Every entry here is a **stack veneer**. The image has six:

| veneer | frame | calls | interpreter |
|---|---|---|---|
| prom_b `0xF31800` `DisplayList_Run_Stack` | `(XIZ+8)`, `(XIZ+0xC)` | `0xF31A09` | A |
| prom_b `0xF31814` `DisplayListB_Run_Stack` | same | `0xF31AF0` | B |
| prom_b `0xF31828` / `0xF3183D` | `(XIZ+8)` only | one record | A / B |
| prom_a `0xFF75D3` | `(XIZ+8)`, `(XIZ+0xC)`, `(XIZ+0x10)` | `0xF417F0` | A |
| prom_a `0xFF75EF` | `(XIZ+8)`, `(XIZ+0xC)` | `0xF417F4` | B |

`0xFF75D3` also does `ld DE,(XIZ+0x10) / ld (0x2540),E` — **the same variable**
the register-form call sites set with `ld (0x2540),0x00` immediately before
calling. That is what ties the two conventions together: they are the same call
with different argument passing, not two different mechanisms.

Callers push in one order and three shapes:

```
pushw <flag>                          ; interpreter A only
lda XBC,<end>   / push XBC
lda XWA,<start> / push XWA            ; last push  =>  lowest slot  =>  (XIZ+8)
  1.  call 0xFF75D3                                     35 call instructions
  2.  lda XIY,<return> / push XIY / jp (XIX)            97 sites
  3.  jr / jrl into one of the above                    (shares them)
```

Shape 2 is a call through a **cached function pointer**: `lda XIX,<veneer>` once
per routine, then a hand-built return address and `jp (XIX)`. Exactly three
values are ever cached in XIX ahead of that shape — `0xFF75D3` (40 uses),
`T_F42E00` = `DisplayList_Run_Stack` (38) and `T_F42E04` =
`DisplayListB_Run_Stack` (19).

> ★ **That answers a header this tree already carried.**
> `DisplayList_Run_Stack`'s own comment says *"Called from: through the thunk
> table; not yet traced to a specific caller."* It has 38 traced callers, all in
> prom_a, all of shape 2.

**The census is anchored on the CALL, not on the operand pattern.** Scanning for
the four-instruction operand shape finds 33 sites; scanning for `call <veneer>`
finds 35, because two sites (`0xFF4C68`, `0xFF4F04`) have a `cps H,0x00 / jr Z`
wedged between the last push and the call. The span set is the same either way —
the *site count* is not, and a count is what gets published.

**Result: 109 confirmed sites naming 61 distinct `(start, end, interpreter)`
triples, 0 unresolved push pairs, and all 61 FRAME** — the record length bytes
walked from `start` land exactly on `end`.

### The A/B attribution is checked, not asserted

| | |
|---|---|
| spans run by interpreter A | 50 |
| spans run by interpreter B | 11 |
| records claimed by both | **0** |
| highest opcode in an A span | **0x23** (A's bound is 0x24) |
| highest opcode in a B span | **0x08** (B's bound is 0x0F) |
| A spans holding an opcode ≥ 0x0F, so B could not dispatch them at all | **19 of 50** |

### A fourth and fifth shape, found while doing this and left open

`prom_a 0xFF7668`, `0xFF7623`, `0xFF763F` and `0xFF7656` take **one** pointer on
the stack and jump straight into a single interpreter-B *handler* — `T_DLB_Handler_Decimal`
→ `0xF31BA1` (op 00), `T_DLB_Handler_Array8_2`/`T_DLB_Handler_Array8` → `0xF31B57` (ops 03/08),
`T_F417F8` → `0xF31B21` (op 02). Together with `T_F42E08`/`T_F42E0C` they give
**25 single-record entry points into this module**, and they are what run the
orphan records that sit between the framed spans. Each such record's header
names its own sites.
⚠ This file's census covers the two-ended veneers plus these five one-record
ones. **It does not claim to be a census of every entry shape in the image** —
these were found from one region's call sites, and a veneer used nowhere near
`0xF58000` would not appear here.

---

## 2. What is in it — the answer gap V asked for

`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` gap V says the disk path "is
not one press away; it needs either a menu sequence, or a chord", and sends the
reader to "whichever display list in prom_b carries the disk menu". It is here:

| address | what |
|---|---|
| `0xF58000` | **the DISK menu**: `DISK`, `DISK L0AD`, `DISK SAVE`, `MIDI FILE`, `DIRECT PLAY`, `FL0PPY DISK`, `F0RMAT` |
| `0xF580B0` / `0xF58127` / `0xF58162` | the three lists prom_a `0xFF42EE` picks between on the model-variant strap `(0x0000C4)` |
| `0xF585AD` | ten SAVE/LOAD **content types**: ALL, SEQUENCER, COMBINATION, SOUND, PANEL, MIDI SETTING, SOUND RE-MAP, COMBI RE-MAP, DRUM MAP, blank |
| `0xF58625` | their **file extensions**: `.ALL .SEQ .CMB .SND .PNL .MDS .SRM .CRM .DRM` |
| `0xF5864D` | nine spaces — the "no extension" constant for content index 9 |
| `0xF59857` | `.MID` |
| `0xF587B2` | a 37-character name-entry alphabet `_A-Z0-9` |
| `0xF58947` | the DISK SAVE **PASSWORD** screen |
| `0xF58A41` | `MIDI FILE SAVE : FILE SELECTION`, with `SAVE` and `DEL` |
| `0xF59128` | `USER 1` / `USER 2` / `USER1 DRUM` / `USER2 DRUM` |
| `0xF595CD` | 100 numbered slot labels ` 01:` … `100:` |
| `0xF59904` | `COMPOSER LOAD` |

⚠⚠ **RETRACTED 2026-08-25 — this was a SCREEN FIELD, not a file format.**
Until this round the paragraph here read:

> ★ The filename format is readable off one prom_a routine. `0xFF76DA` does
> `ld BC,0x0004 / ld XIY,0x00F58625 / add IX,0x0006`, i.e. four extension bytes
> appended at offset 6 of a six-character name … So a saved file is
> `NNNNNN.XXX`-shaped with a fixed 6+4 layout … **For the emulation lane that is
> a directly usable fact about what a real WSA1 floppy contains.**

The round-2 audit found it and the audit is right. **Nothing on that path touches
a sector.** The helper both arms call, `sub_FF76FE` (`prom_a` `0xFF76FE`), is
`stdi8 (0x2540),0x00 / ldb a,0x06 / swi 7`, and SWI7 service `0x06` is
`LCD_Svc_06_DrawText8x14` (`SWI7_ServiceTable[6]` = `0xF8F039`). Its own loop
does `inc 1,IX` per glyph, so `IX` is a **text cursor**: the `add IX,0x0006` at
`0xFF76E2` steps the cursor six CELLS, because `sub_FF76FE` pushes and pops `XIX`
and therefore hands `IX` back unchanged. The routine draws a six-cell name field
and a four-cell extension field next to it. Two corroborations that it is a
screen field: the index-9 arm at `0xFF76ED` draws **nine** cells
(`ldw bc,0x09`), not the 6+4 = 10 a filename would need; and prom_a's own disk
work documents real FAT12 boot sectors and formatters, where an on-disk name is
8.3 inside a 32-byte directory entry.

**What survives, re-read from ROM.** The nine extensions at `0xF58625`
(`.ALL .SEQ .CMB .SND .PNL .MDS .SRM .CRM .DRM`) and the blank run at `0xF5864D`
are exactly as tabulated above. The extension table's **row stride is 4 and the
row index is the content index**, and that is now proved rather than assumed:
`LCD_Svc_06_DrawText8x14` computes `IZ = HL * BC` before its loop and reads each
glyph from `(XIY + IZ)`, so a caller passing `XIY = 0xF58625`, `HL = content
index`, `BC = 4` selects row `index` of a 4-byte table. Counting from the base,
row 9 is `0xF58649` and is four spaces; the nine-space constant at `0xF5864D`
begins immediately after it, and `0xF58649 + 4 = 0xF5864D` — the thirteen spaces
at `0xF58649-0xF58655` are a blank row plus that constant, not one object.

**Also established, and it is a RAM record, not a disk record:** the caller
`Disk_DrawDirEntry` reads its content code from offset `+6` of the record `XIY` points
at (`inc 6,XIY`, then `sub_FF4936`, then `and L,0x0F`), and draws six characters
from offset `+0`. So *some* six-character name with a type nibble six bytes after
it exists in memory. **What that record IS, and whether it is ever written to a
disk in that shape, is NOT established here.**

Every byte quoted in this correction is re-read from the ROM by
`python3 notes/prom_b_filefield_checks.py` — 22 checks, 0 failures.

★ **For the emulation lane:** the previous sentence promised a fact about what a
real WSA1 floppy contains and did not have one. Do not lay out a disk image from
this note. What it does give the driver lane is the *screen*: a save/load file
field is 6 + 4 cells wide, and its extension comes from a nine-entry table
whose tenth row is blank.

### 2026-10-04: the extensions a WSA1 disk DOES carry -- read from the load and save code

The retraction above withdrew a file-name claim that had been read off a screen field.
The disk code itself does state the extensions. `prom_a`'s `DiskLoad_ByContentType` /
`DiskSave_ByContentType` dispatch on `Disk_ContentType` (0x2725), the byte this module's
record `DL_F583F0` draws from `DLText_F585AD`. Each per-type routine writes three bytes to
`Disk_FileName+8..10`, the extension field of the 8.3 name that `DiskCmd_OpenFile` matches
against the FAT root directory:

| content type | extension(s) | load | save | notes |
|---|---|---|---|---|
| 1 SEQUENCER | `SQF` and `SEQ` (through prom_b `T_SeqFile_Load` / `T_SeqFile_Save`) | `DiskLoad_Sequencer` | `DiskSave_Sequencer` | read 2026-10-04: see the next section |
| 2 COMBINATION | `CMB` | `DiskLoad_Combination` | `DiskSave_Combination` | tag `WSA1`; 0x16300 bytes to 0xEC0000 |
| 3 SOUND | `TM ` | `DiskLoad_Sound` | `DiskSave_Sound` | tag `WSA SOUND RAM S0`; 0x40000 bytes to 0xE80000 |
| 4 PANEL | `LSW` and `SLS` | `DiskLoad_PanelLswFile` + `_PanelSlsFile` | `DiskSave_Panel*` | `SLS` = 0x600 bytes of RAM 0x7000 |
| 5 MIDI SETTING | `MDS` | `DiskLoad_MidiSetting` | `DiskSave_MidiSetting` | |
| 6 SOUND RE-MAP | `SRM` | `DiskLoad_SoundRemap` | `DiskSave_SoundRemap` | to / from RAM 0x5210 |
| 7 COMBI RE-MAP | `CRM` | `DiskLoad_CombiRemap` | `DiskSave_CombiRemap` | to / from RAM 0x5860 |
| 8 DRUM MAP | `DRM` | `DiskLoad_DrumMap` | `DiskSave_DrumMap` | 0x1D0 bytes, RAM 0x5EB0 |
| 0 ALL | every one of the above | | | |

So the `.ALL .SEQ .CMB .SND .PNL ...` strings at `0xF58625` are display text. Only
`CMB`, `MDS` and the three `?RM` coincide with a real extension. The base name is
whatever `Disk_FileName+0..7` holds, which is the name editor's field. Every routine
cited here has its evidence in `notes/prom_ab_read_names_2026_10_04.py`.

### 2026-10-04: the SEQUENCER content type -- two files, `SQF` and `SEQ`

`DiskLoad_Sequencer` / `DiskSave_Sequencer` reach prom_a's sequencer file module (0xFBAC00-0xFBB42E)
through `T_SeqFile_Load` / `T_SeqFile_Save`. Its routines, now named, write two files under the one base name:

| file | what it holds | load window | save window |
|---|---|---|---|
| `SQF` | the sequencer **workspace**, 0xC00 bytes: one bank (`0x603400-0x603FFF`); or, in an all-banks file, the ten bank copies at `0x610000 + n*0xC00` (0x7800 bytes) | `0x603400-0x604000` (`Disk_LoadSqfToWorkspace`), or `0x610000-0x617800` (`SeqFile_LoadAllBanks`) | staging `0x609400-0x60A000` (`Disk_SaveSqfFromStaging`), or `0x610000-0x617800` (`SeqFile_SaveAllBanks`) |
| `SEQ` | the song store's 256-byte **blocks** (FINDINGS-prom_b-block-store.md), `(0x603452) * 16` bytes | at the free head (`SeqFile_LoadSongBlocks`), or the whole heap from `0x617800` | four blocks at a time through staging `0x609400-0x6097FF` (`SeqFile_WriteSeqCompacted`), or the whole heap |

**The all-banks flag** is byte `+4` of the SQF. `SeqFile_SaveAllBanks` sets `(0x610004) = 1` for the write and
clears it after. `SeqFile_Save` clears `+4` in its one-bank staging copy. `SeqFile_ProbeSqfHeader` reads the
first 0x600 bytes back and classifies the file:
- word `+5` must be 4, or the load stops with result 0x10;
- then `+4 = 1` selects `SeqFile_LoadAllBanks`, anything else the one-bank load.

**One bank is saved compacted.** `SeqFile_Save` walks the selected bank's 17 directory entries
(workspace `+0x100`, three bytes each, bit 7 = in use). It renumbers each entry's chain from 1, in
directory order, and stores the running block total in the word at `+0x7E + 2k`.
`SeqFile_WriteSeqCompacted` then copies the blocks in that order, relinking each one
(`SeqFile_RelinkStagedBlock`: previous 0 at a chain's start, next 0xFFFF at its end).

**One bank is loaded relocated.** `SeqFile_LoadSongBlocks` reads the SEQ at the shared heap's free head.
It then adds `FreeHead - 1` to every block number the song holds, skipping 0 and 0xFFFF:
- the 17 start blocks;
- the 17 words at `+0x7E`;
- every block's previous / next links.

`BStore_RebuildFreeChain` then links the remaining blocks as the new free chain. The free head / count
live in the workspace (`0x6034B8` / `0x6034BA`), so they are per bank. `SeqFile_Load` therefore carries
them across the workspace swap (`BStore_StashFreeChain` / `BStore_UnstashFreeChain`). A song that needs
more blocks than are free is refused with result 0x1E.

The bank is `Disk_SeqBank` (RAM 0x272B), 0..9, which `LcdKeyRow4` / `LcdKeyRow5_DiskL0adFile` step.
Results go to `(0x23CB)`: 0x10 bad SQF, 0x1E no room in the store, 7 no room on the disk, otherwise
`Disk_LastError`. Reads succeed with 1 and writes with 3.

⚠ Not established:
- what the workspace word `+0x1C` is. `Smf_WriteFile` refuses to run while it is non-zero (status 9), and
  `BStore_GetDiskBankPassword` / `BStore_GetAnyBankPassword` gather it from all ten banks.
  **ANSWERED the same day:** it is the bank's save PASSWORD (next section).
- `Disk_SaveSeqFile` (window from `0x609000`) has no decoded caller of its entry `T_Disk_SaveSeqFile_Entry`.

Every routine's evidence is a row of `notes/prom_ab_read_names_2026_10_04.py`.

### 2026-10-04: the DISK SAVE PASSWORD -- a hidden page, and banks that clear themselves at boot

`BStore_Password`, workspace word `+0x1C` (`0x60341C`), is a two-character password. Each bank copy
holds its own at `0x61001C + n*0xC00`. The DISK SAVE FILE screen handles it as follows.

**Setting it.**
- Page 1's SoftKeyCol4 counts presses in `DiskSave_PasswordUnlockCount` (0x220C).
- Past six presses, page 3 opens if the bank has no password: "DISK SAVE:PASSWORD / Please set the
  PASSWORD", drawn by `ScreenEnter_DiskSaveFile_Page3`. If it has one, the press shows status 0x0A instead.
- Page 3's LcdKeyRow1 copies the first two characters of the entry buffer `DiskSave_PasswordEntry` (0x22F0,
  16 bytes) into `DiskSave_Password` (0x220F / 0x2210).
- The save writes them into the workspace (`DiskSave_StorePasswordInWorkspace`, when the count is at least
  6), so the SQF carries the password.
- A save that ends with result 3 (OK) zeroes the count and the entered password (`DiskSave_ShowResult`).

**Saving over it.** `DiskSaveFile_CheckDriveThenPassword` senses the drive first.
- It then asks `DiskSave_IsBankPasswordSet`. For SEQUENCER, or screen 0x4E, that checks bank `Disk_SeqBank`
  (`BStore_GetDiskBankPassword`); for ALL, every bank (`BStore_GetAnyBankPassword`, the first non-zero one).
- When one is set, page 4 opens: "PASSWORD is already set." (`DiskSaveFile_AskForPassword`).
- Its LcdKeyRow1 compares the entry with the stored word (`DiskSave_ComparePassword`). A mismatch shows
  status 0x11 and returns to page 1. A match shows status 0x12 and goes on to save.
- The save itself (`DiskSaveFile_SaveOrConfirmOverwrite`) asks for confirmation on page 2 when the selected
  slot already holds a file (`DiskSave_IsSelectedFileNew`: its 8 listing bytes at `0x60A488 + 16*n` are not
  all 0x80; n is `Disk_SelectedEntry`, 0x2724, the listing entry 38 routines index with), unless an SMF write is in progress (`(0x21E8)` bit 7).
- **SMF export is refused** for a bank with a password: `Smf_WriteFile` stops with status 9.

**At boot the protected banks are erased.** `BStore_BootPhase3` calls
`BStore_ClearPasswordProtectedBanks`. It walks banks 0..9 (`BStore_MoveWorkspaceToNextBank`), and for each
bank whose password word is non-zero it runs `SongClear_ClearCurrentBank` -- the SONG CLEAR job's own
routine, `SongClear_ClearBank`, which `SongClear_LcdKeyRow4` calls -- and zeroes the password. So a
password-protected song survives only until the next power-on. `SeqFile_Load` calls the same clear on the
target bank before it reads a one-bank SQF over it.

⚠ Not established: what status codes 0x0A, 0x11 and 0x12 print. They are not tied to their texts here,
though `DL_Error11ThePasswordThatYouEnteredIs` and `DL_PasswordOk` exist.

### 2026-10-04: MIDI FILE DIRECT PLAY streams the file through a reader task and two buffers

DIRECT PLAY does not load a `.MID` file. It streams it:
- **Open.** `MidiFileStream_Open` (directory slot `T_MidiFileStream_Open`, called by `MidiFileDirectPlay_LcdKeyRow1`)
  names the disk module's one FCB, `Disk_Fcb` (0x178E), with extension `MID` and opens it (DiskCmd 0x0F).
  It sets `MidiFileStream_State` (0x170E) = 1 and starts kernel task 4.
- **Read ahead.** Task 4 is `MidiFileStream_ReaderTask`: task-table entry 0xF85EAE, thunk `T_MidiFileStream_ReaderTask`,
  stack 0x60EB00. It sets `MidiFileStream_TaskRunning` (0x17B7) and takes the file size from the FCB's
  `+0x10` (DOS layout) into `MidiFileStream_FileSize` (0x1700). It seeds message queue 2 with two buffers,
  `0x604B00` and `0x605300`.
  - Each buffer is a word count, a word flag, then 0x400 bytes.
  - For each buffer it receives, it reads the next 0x400 bytes into it (`MidiFileStream_ReadBlock`:
    DiskCmd 0x1A, then 0x83) and sends it to queue 3, with the count cut to what is left of the file.
  - A buffer that arrives with a non-zero flag is a stop request. It goes back with flag 0xFFFE, and the
    task clears 0x17B7 and exits.
- **Consume.** `MidiFileStream_GetByte` (`T_MidiFileStream_GetByte`) is what the players call, in
  `MidiFileDirectPlay_Tick` and `SequencerMedley_MidiFileTick`. It returns one byte, or 0xFFFF at the end.
  - When `MidiFileStream_BufLeft` (0x1704) is 0, it takes the next buffer from queue 3
    (`MidiFileStream_Buffer` 0x1706, read pointer `MidiFileStream_ReadPtr` 0x170A).
  - A full buffer it empties goes back on queue 2 to be refilled. A short one, or a non-zero flag, sets
    the state to 2.
- **Close.** `MidiFileStream_Close` (`T_MidiFileStream_Close`, `MidiFilePlay_Stop`) posts a stop request on queue 2 and
  waits until 0x17B7 is clear. It then drains both queues and blanks `Disk_FileName`.

### `L0AD` is not a typo in this note

Many of these labels spell capital **O** with character code **0x30**, the digit
zero — `DISK L0AD`, `FL0PPY DISK`, `F0RMAT`, `L0AD 0PTI0N`, `S0UND GR0UP:`,
`FR0M S0NG NUMBER`. The module uses **both** codes — 67
occurrences of 0x30 and 71 of 0x4F inside its printable runs, and the *same
phrase* appears both ways: `MIDI FILE SAVE : FILE SELECTION` at `0xF58A66` and
`MIDI FILE SAVE : FILE SELECTI0N` at `0xF59226`. It makes no difference on
screen, and the reason is a byte fact: **`Font_Svc06_8x14` cell
0x30 and cell 0x4F are the same fourteen bytes** (both checked in
`gen_prom_b_f58000_module.py --selftest`). Recorded because anyone grepping this
source for `LOAD`, `SOUND` or `SELECTION` will miss half of them.

---

## 3. What draws the disk menu, followed backwards until the evidence stops

`python3 notes/prom_b_diskmenu_entrypoint.py`, 13 checks:

```
prom_a 0xFF42CD   pushes 0x00F580B0 / 0x00F58014, calls 0xFF75D3.
                  A routine start: the byte before it is 0x0E = ret.
   ^  NOTHING CALLS IT.  Zero `call` and zero `calr` sites in any of the three
      images; none of the 654 slots of prom_a's dispatch matrix holds it.
prom_b T_Paint_DiskMenu = `jp 0xFF42CD`, and it is the ONLY place in 1.5 MiB where the
      address 0xFF42CD is spelled at all.
   ^
prom_a 0xF86EC1 — 256 words of 4 bytes.  175 are prom_b directory slots; the
      other 81 all hold 0x00F872C1, which is the byte immediately after the
      table.  ENTRY 96 IS T_Paint_DiskMenu.
   ^
   ⚠ WHAT INDEXES THAT TABLE IS NOT ESTABLISHED.  It is in prom_a, inside an
   `.incbin`, and this lane may not edit prom_a.
```

**So the disk menu is screen 96 of a 256-screen table, and gap V is now one
table lookup wide instead of a subsystem wide.** That is a narrowing, not a
closure: nothing here says which panel event produces the index 96.

The 256 is not a guess. The table runs `0xF86EC1-0xF872C0` = 0x400 bytes, and
**both ends are fixed by something other than the count**: the four bytes below
it read `0x01010101`, which is not an address in this map, and the 81 unused
slots point at the first byte past the table. ⚠ It is **not 4-byte aligned**,
which is why an alignment-assuming scan misses it. Three of the 175 directory
slots it names (`0xF406C4`, `0xF406CC`, `0xF406DC`) are pointer slots rather
than `jp` thunks; that is recorded, not explained.

**→ prom_a lane / emulation lane:** `0xF86EC1` is a 1,024-byte object inside
prom_a's `.incbin` and it is worth converting on its own.

---

## 4. How the non-list bytes are graded

| kind | count | what makes it more than `.byte` |
|---|---:|---|
| `dl` display lists | 12 spans, **431 records** | both ends are operands of a located call site; the walk frames exactly |
| `recs` orphan runs | 16 runs, **45 records** | either named by a one-push single-record site (with the sites listed) or framing exactly from the end of one proven object to the start of the next |
| `rows` tables | **18** | width from the *handler* of the record that points at the table; count from the **extent**, never from the record's AND mask |
| `raw` | 3 objects, **118 bytes** | structure **not** claimed; each says so at its label |

⚠ **The mask is not the count, and in this module it is usually wrong.** The
record at `0xF58798` allows 64 entries and the table at `0xF5881F` holds 37; the
one at `0xF5953B` allows 16 and `0xF5975D` holds 30; the one at `0xF593F3`
allows 4 and `0xF59414` holds 7; the one at `0xF58402` allows 16 and `0xF585AD`
holds 10. Measured over all eighteen — `gen_prom_b_f58000_module.py --selftest`
— **the mask disagrees with the extent for ten**, agrees for six, and two tables
(`0xF58625`, `0xF595CD`) have no naming record at all and are proven another way:
the first by its prom_a reader, the second because its hundredth row literally
reads `100:`. Every count here divides its extent exactly and the extent runs to
the next object something else names.

### One boundary refined

`FINDINGS-prom_b-sc1-link.md` §1 says *"2,982 bytes of `0x00` end at
`0xF5A800`"*. That remains exactly true of the **run of zero bytes**. But its
first byte, `0xF59C5A`, is the **last operand byte of the display-list record at
`0xF59C53`** — opcode 0x0E, handler `0xF31A9F`, three words, so eight bytes
declared and eight bytes read. The module therefore ends at `0xF59C5B` and the
**pad is 2,981**. Both statements describe the same bytes; the source and both
notes now say so.

---

## 5. Round-1 audit finding F2 — fixed, and how the same defect was caught again here

F2 reported 18 citations naming the address of an **operand** rather than of the
instruction that owns it. All 18 are corrected:

* the 14 the tool reaches (`prom_b_audit_callsites.py --evidence` reported
  `OFF-BY-1 14`; it now reports none) — twelve font-table `Evidence:` lines plus
  the summary table at `wsa1_prom_b.s`, and their generator
  `notes/gen_prom_b_fonts.py`;
* the four it cannot: `0xF10702`→`0xF10700`, `0xF110EC`→`0xF110EA`,
  `0xF1172C`→`0xF1172A` (off by **two**, the opcode `e9 c8` of
  `add XBC,imm32`) and `0xF110FB`→`0xF110FA` (off by one, `f2` of
  `lda XBC,imm24`).

`notes/prom_b_screen_arrays.py` now **proves** the pairing instead of tabulating
it: it asserts the bytes between the instruction and the operand equal the
recorded opcode, so a wrong instruction address fails the script (22 checks).

`prom_b_audit_callsites.py`'s docstring used to end *"an OFF-BY row of any kind
is never expected: there are ZERO in both modes"*. That sentence was written
after running only the default mode, and was false about its own tree. It is
replaced by the record of what happened, and by the run line the sentence should
have rested on. **A mode that was not run proves nothing.**

★ **And it happened again in this round's own first draft.** Eleven prom_a
addresses quoted in the new segment headers came from a raw byte scan, which
finds the *operand*: `0xFF577F` for the instruction at `0xFF577E`, and ten more.
Both new scripts now carry a check that every prom_a address they print or quote
**starts an instruction in `prom_a/wsa1_prom_a.s`** (109 site addresses, 66
quoted addresses, 0 failures). Correcting them also **corrected a claim**: the
six sites that spell `0xF587B2` are `lda XBC,0xf587b2`, i.e. the END operand of
the list that stops there — so the name-entry alphabet has **no located reader**,
and the header now says that instead of calling them readers.
