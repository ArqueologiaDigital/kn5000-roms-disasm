# Technics SX-WSA1R — memory map of both processors

Status: derived from the two boot blocks plus code that touches each device.
Everything here is a byte in `original_ROMs/`, an address, or a stated gap.
Where a claim rests on an interpretation rather than on a byte, it says so in
the row itself.

Reproduce:

    python3 scripts/analysis/mamr_reading_elimination.py   # the window sizes
    python3 scripts/analysis/refute_memory_map.py          # the byte re-reads
    scripts/analysis/dis.sh a 0xF826A9 300                 # CPU 1 reset path
    scripts/analysis/dis.sh c 0xFFF000 240                 # CPU 2 reset path

The two reset paths are converted to real assembly in `prom_a/wsa1_prom_a.s`
and `prom_c/wsa1_prom_c.s`; those files carry the same facts inline, next to the
instruction that establishes each one.

---

## 0. Where the register semantics come from, and where they stop

MAME's `tmp95c061.cpp` **names** the memory-controller registers and does not
**decode** them. `bcs_w` (:1295), `bexcs_w` (:1300), `msar01_w` (:1313),
`msar23_w` (:1329), `drefcr_w` (:1343) and `dmemcr_w` (:1353) are bare stores
into `m_block_cs` / `m_external_cs` / `m_mem_start_reg` / `m_mem_start_mask`,
and nothing else in the device reads those members. The names come from the
debugger symbol table at `tmp95c061.cpp:1359-1391`, the addresses from
`internal_mem()` at `:111-173`, the reset defaults from `:281-300`
(`B2CS = 0x10`, every MSAR/MAMR `0xFF`).

So: **register names = MAME. Field meanings = derived below, and graded.**

### MSAR = A23-A16 of the block start — PROVEN

Inside prom_c, in one routine: `0xFFF038 ldio MSAR0,0x10`, and 0x2F bytes later
`0xFFF067 ld XIX,0x00100000`. 0x100000 is where CPU 2's device cluster lives.

### MAMR = window size, 32 KB per unit — 64 KB ELIMINATED

This is the claim the previous pass got wrong, and it was flagged as the single
most likely error in the whole map. The old argument imported
`technics-docs/tmp94c241-memory-controller.md`, a reconstruction that grades
*itself* "strong, not proven" and records that a rival 64 KB-granularity reading
had also once been "confirmed" — and the external file it cited for the
512 KB row (`kn7000_mame/notes/kn1500-lcd.md:46-47`) in fact says *"~1 MB CS
window; the 512 KB chip mirrors within it"*, i.e. the opposite. That correction
stands: **the old derivation was not a derivation.**

Replaced by an elimination over this machine's own firmware,
`scripts/analysis/mamr_reading_elimination.py`. Eight candidate decoders —
{32 KB, 64 KB} per MAMR unit × {base truncated to the window, base literal} ×
{higher-numbered CS wins, lower wins} — are each fed the register values the two
boot blocks actually write and checked against eight facts that come from the
ROMs:

| | fact | why it is a fact |
|---|---|---|
| F1 | CPU 1 0x600000 is on CS3 | RESET clears it (0xF8279A, 0xF827AF), MSAR3 = 0x60 aims CS3 there, and `ldio P6FC,0x1F` (0xF826B2) makes the CS3 pin LCAS — port 6 is "Shared with CS0, CS1, CS3/LCAS, RAS, REFOUT" (`tmp95c061.h:19`) |
| F2 | CPU 1 0x7E0000 is on CS0 | `0xFE509B ldio B0CS,0x10`, then 256 iterations that each `calr 0xFE4CE0` → `add XWA,0x007E0000` / `ld HL,(XWA)`, then `0xFE50D5 ldio B0CS,0x14` |
| F3 | CPU 1 0x000080 is on CS1 | RESET clears 0x80 upward; MSAR1 = 0x00 |
| F4 | CPU 1 0xF80000 and 0xF00000 are on CS2 | the two EPROMs |
| F5 | CPU 2 0xC00000 is NOT on CS2 | prom_c reads the expansion board header there, `0xFB6B6E ld XIX,0x00C00000` |
| F6 | CPU 2 0xE80000 and 0xF80000 are on CS2 | the flash and this EPROM |
| F7 | CPU 2 0x100000 is on CS0 | the MSAR0 proof above |
| F8 | CPU 2 0x000080 is on CS3 | prom_c's RESET clears it |

**2 of 8 survive:** `32K / truncated base / higher-wins` and
`32K / literal base / higher-wins`.

* **64 KB per unit is dead** under every base convention and every priority
  order. On CPU 1 it either puts 0x7E0000 inside CS1 (contradicting F2) or puts
  the DRAM inside CS0 or CS1 (contradicting F1).
* **Lower-numbered-CS-wins is dead**, for the same two reasons plus, on CPU 2,
  putting the flash on CS1.
* The two survivors **agree on seven of the eight windows** and disagree on
  exactly one — see the CS0 row of CPU 1 below.

Read this as elimination, not proof. All eight candidates assume
`size = unit × (MAMR + 1)` with a contiguous bottom-up mask; a semantics outside
that family is untested here. What can be said without hedging is that the
64 KB reading is refuted **by the WSA1 itself**, not by another model's manual.

Corroboration, offered as corroboration only: the SX-KN1500 uses the same part
and writes `MSAR0=0x78/MAMR0=0x3F, MSAR1=0xC0/MAMR1=0x7F, MSAR2=0xE0/MAMR2=0x3F,
MSAR3=0x00/MAMR3=0x0F` (`kn7000_mame/notes/kn1500-lcd.md:47-52`), and its
service manual pins three chip sizes. Under 32 KB/unit + higher-wins those come
out as 512 KB (IC21 DRAM), 2 MB (IC15 mask ROM) and — after CS2 takes the top
half of CS1's window — 2 MB (IC17): three exact hits. Under 64 KB/unit none of
the three is exact and all require mirroring. ⚠ **This means that note's
"~1 MB CS window; the 512 KB chip mirrors within it", and the KN1500 driver's
`mirror(0x080000)` that was built on it, are probably an artefact of the 64 KB
reading.** Not fixed here — `kn7000_mame` is out of scope for this tree — but it
should be looked at.

### Everything else about the controller — NOT ESTABLISHED

* **BnCS / BEXCS bit layout.** Proven: bit 2 of B0CS changes CS0's behaviour for
  the duration of a transfer (0xFE509B / 0xFE50D5), so the low bits are per-area
  access timing. The *encoding* of the wait states is unknown. Bit 4 is set on
  every area the firmware enables and matches MAME's reset `B2CS = 0x10`, so it
  is plausibly an enable — but CPU 1 writes `BEXCS = 0x03` with bit 4 clear
  while plainly meaning "and this is how the rest of the space behaves", which
  is in tension with that reading.
* **Bit 3 of BnCS.** Set on CS2 *and* CS3 on both CPUs (CPU 1: 14/17/1B/19;
  CPU 2: 10/14/1B/1B). It is **not** "the two ROM/flash areas" — CS3 is the DRAM
  on both. On this machine those are exactly the two 16-bit-wide areas, which is
  where the width fact below comes in, but the bit is not decoded anywhere.
* **DREFCR = 0x71** (both CPUs), **DMEMCR = 0x8D** (CPU 1) / **0x89** (CPU 2) /
  **0x2D** (CPU 1 power-down). Refresh period, RAS/CAS timing and multiplex
  width: all unknown. MAME stubs both registers.

### One hard bus-width fact

CPU 2's flash unlock addresses are **0xAAAA and 0x5554**, exactly 2× the AMD
byte-mode 0x5555 / 0x2AAA (`0xFC8662 add XBC,0x0000AAAA`,
`0xFC8672 add XBC,0x00005554`). A0 is therefore not routed to the flash; the CPU
consumes it as a byte-lane select. **CS2 on CPU 2 is 16 bits wide**, and prom_c
shares that window, so prom_c is a ×16 device — a complete contiguous byte image
of 0xF80000-0xFFFFFF, not an even or odd half.

CPU 1 carries the same `B2CS = 0x1B`, so prom_a and prom_b are presumably ×16
as well. **INFERRED, not proven.**

---

## 1. CPU 1 — prom_a (0xF80000) + prom_b (0xF00000)

Reset PC `0x00F826A9` (prom_a file 0x7FF00 = `a9 26 f8 00`). The whole boot block
is converted in `prom_a/wsa1_prom_a.s`.

### The writes that are the memory map

| ROM addr | bytes | reg | value |
|---|---|---|---|
| 0xF8272D | `08 3c 78` | MSAR0 | 0x78 |
| 0xF82730 | `08 3e 00` | MSAR1 | 0x00 |
| 0xF82733 | `08 5c e0` | MSAR2 | 0xE0 |
| 0xF82736 | `08 5e 60` | MSAR3 | 0x60 |
| 0xF82739 | `08 3d 3f` | MAMR0 | 0x3F |
| 0xF8273C | `08 3f 7f` | MAMR1 | 0x7F |
| 0xF8273F | `08 5d 3f` | MAMR2 | 0x3F |
| 0xF82742 | `08 5f 0f` | MAMR3 | 0x0F |
| 0xF82763 | `08 5a 71` | DREFCR | 0x71 |
| 0xF82766 | `08 5b 8d` | DMEMCR | 0x8D |
| 0xF82769 | `08 68 14` | B0CS | 0x14 |
| 0xF8276C | `08 69 17` | B1CS | 0x17 |
| 0xF8276F | `08 6a 1b` | B2CS | 0x1B |
| 0xF82772 | `08 6b 19` | B3CS | 0x19 |
| 0xF82775 | `08 6c 03` | BEXCS | 0x03 |

Supporting: `0xF826A9 ldio WDMOD,0x04` + `0xF826AC ldio WDCR,0xB1` (watchdog
disarm); `0xF826AF ldio P6,0x1B` / `0xF826B2 ldio P6FC,0x1F` (five port-6
alternate functions ⇒ RAS and REFOUT out, CS3 pin = LCAS ⇒ the CS3 area is the
DRAM area; CS2 is not on port 6, which is why the boot ROM's own select needs no
enabling).

### Resulting map

| range | size | CS | device | evidence / grade |
|---|---|---|---|---|
| 0x000000-0x00007F | 128 B | — | TMP95C061 internal I/O | `internal_mem()`, tmp95c061.cpp:111-173 |
| 0x000080-0x0051FF | 20.4 KiB | CS1 | static RAM, cleared at boot | `0xF8278A ldw BC,0x1460` / `ld XIX,0x80` / `ld (XIX+),XWA` / `djnz16` → 0x1460 × 4 bytes. A **lower bound**, not the chip size |
| 0x005200-0x3FFFFF | — | CS1 | **NOT ESTABLISHED**. Nothing fixes the chip's size | |
| 0x600000-0x6033FF | 13 KiB | CS3 | work DRAM, cleared at boot | `0xF8279A ld XBC,0xD00` / `ld XIX,0x600000` |
| **0x603400-0x603FFF** | **3 KiB** | CS3 | work DRAM, **deliberately NOT cleared** and live — and now IDENTIFIED: it is the BLOCK STORE's working copy of one of ten banks, `ldir`'d to and from `0x610000 + n*0xC00` by `0xF64BE3` / `0xF64B3D` with n = `(0x360A)`. Its `+0x22` is a 16-byte array, `+0x7E`/`+0xA0` are **17** saved cursors (⚠ CORRECTED 2026-08-25 from 16 — `BStore_FreeList_Init` at prom_b `0xF7A4B9`/`0xF7A4CA` clears each with its own `ld BC,0x0011`, and TLCS-900 `djnz` decrements then tests, so 17 iterations; the word array of 17 ends exactly where the byte array starts, which it would not at 16 — `python3 notes/prom_b_songstore_checks.py --arrays`), `+0xBA` is the free-block count. See `FINDINGS-prom_b-block-store.md` | the clear loops skip it; prom_b reads it at `0xF440A5 ld XHL,0x00603400`. A preserved region across a warm restart |
| 0x604000-0x60FFFF | 48 KiB | CS3 | work DRAM, cleared at boot | `0xF827AF ld XBC,0x3000` / `ld XIX,0x604000` |
| 0x60EB80 | | CS3 | initial stack pointer | `0xF85606 ld XSP,0x0060EB80`, the first instruction after the jump into prom_b's thunk table |
| 0x617800 + n·0x100 | | CS3 | a 256-byte-record array — now IDENTIFIED as the BLOCK STORE's HEAP. Each record is `+0 flags (bit 7 = allocated)`, `+1..2 previous block`, `+3..4 next block (0xFFFF = end)`, `+5..0xFF payload`; the chains are named by a 3-byte directory at `0x00603500`. `0x617800` is the value of `(0x3604)`, forced by the inverse arithmetic cited in the next column against `BStore_SeekBlock`'s `(0x126E) = (0x3604) + (n-1)*0x100`. See `FINDINGS-prom_b-block-store.md` | `0xF61F5B add XHL,0x00617800` then `ld (XHL+IX),0x81`; the inverse at `0xF5E2F4 sub XHL,0x00617800` then `srl 8` |
| 0x610000-0x6177FF | 30 KiB | CS3 | **ten 3 KiB banks** of the `0x603400` workspace, `0x610000 + n*0xC00` for n = 0..9. prom_a bounds n: `0xF8143F cp A,0` refuses to decrement below 0 and `0xF814D2 cp A,0x09` refuses to increment past 9. `0x610000 + 10*0xC00 = 0x617800`, so the ten banks abut the block heap with no slack — ⚠ consistency between two derivations, not proof they are one object | `0xF64BE3` / `0xF64B3D`, read as instructions.  The same `sla 0x0B` + `sla 0x0A` index shape occurs at **48** sites in prom_a+prom_b — 8 in prom_a, 40 in prom_b — counted by `python3 notes/prom_b_bank_index_census.py`, which reports it as an upper bound because it is a byte window, not a decode |
| 0x617800-0x67FFFF | | CS3 | **NOT ESTABLISHED** beyond the heap's start | |
| 0x680000-0x78FFFF | | CS0 | **NOT ESTABLISHED — no device is referenced here** | a byte census of prom_a+prom_b over the `C2/D2/E2/F2 + lo,mid,hi` mem24 forms and the `0x40-0x47` imm32 loads finds 64 + 108 raw hits in this span, every one of them a scattered singleton inside data (the largest, `0x72F2D2` ×26, is a repeating `f2 d2 f2 72` pattern in prom_a at 0xF54C98+). Contrast 0x790000-0x7FFFFF in prom_a: 0x790000 ×73, 0x790001 ×21, 0x7C0000 ×8, 0x7F0000 ×5, 0x7A0000 ×4, 0x7B0004 ×3, 0x7B0005 ×2 — the shape a real device makes |
| 0x790000 / 0x790001 | 2 B | CS0 | display-controller-shaped port. 0x790000 read = status, busy in **bit 6**; written = data. 0x790001 = command, also read for data | `0xF8ECF4 bit 6,(0x790000)` / `0xF8ECFB ld (0x790001),0x46` / `0xF8ED0D ld (0x790000),A`. Command bytes 0x42/0x43/0x46/0x4C. **Part identity UNVERIFIED** — those four match SED1330 MWRITE/MREAD/CSRW/CSRDIR, but the status port is on the wrong side for that part |
| 0x7A0000 | 1 B | CS0 | **the FLOPPY DISK CONTROLLER's data register on the DMA-acknowledged decode** (established 2026-08-25, `notes/FINDINGS-prom_a-fdc.md`). Two paths to this one address: programmed I/O through the pointer at (0x605A3E), and **micro-DMA channel 0** through the pointer at (0x605A3C), armed on **INT7**. `Dev7A_Dma_DeviceToRam` sets DMAS0 = 0x7A0000 fixed / DMAD0 = RAM walking / DMAM0 = 0x00; `Dev7A_Dma_RamToDevice` is the mirror with DMAM0 = 0x08 (mode meanings: `../mame/src/devices/cpu/tlcs900/tmp95c061.cpp:368-372` and `:398-402`). All four references in prom_a+prom_b name 0x7A0000 exactly — `notes/FINDINGS-dev7b-and-int5.md`, re-censused by `notes/prom_a_byte_checks.py`. Added 2026-08-25 | `0xFE59BB`/`0xFE59DA` (DMA, converted) · `0xFE680F ld C,(0x7A0000)` / `0xFE682B ld (0x7A0000),C` (PIO) |
| 0x7B0004 / 0x7B0005 | 2 B | CS0 | **Main Status Register** (read) / **control register** (write) and **Data Register** of a **uPD765-family FLOPPY DISK CONTROLLER** — established 2026-08-25, `notes/FINDINGS-prom_a-fdc.md`; the driver is prom_a 0xFE54EC-0xFE6850. Reached through exactly FIVE accessors, all in prom_a `0xFE54B6-0xFE54EB` and all converted; `INT5_Dev7B_Receive` (`0xFE6866`) is the only consumer. Status bit 7 = MSR_RQM, bit 6 = MSR_DIO, bit 5 = MSR_EXM, bit 4 = MSR_CB, bits 3-0 = drive busy. ⚠ which bit of the WRITE side does what is still not established — `notes/FINDINGS-prom_a-fdc.md`, `notes/FINDINGS-dev7b-and-int5.md` | `0xFE54B6 ld L,(0x7B0004)`, `0xFE54BC ld L,(0x7B0005)`, `0xFE54C5 ld (0x7B0004),A` |
| 0x7C0000 | 1 B | CS0 | **inter-processor link port** — §3 | `0xF8E12B ld XBC,0x007C0000` / `ld (XBC),0xE2` |
| 0x7E0008-0x7E0017 | | CS0 | 16-bit port, **the SECOND STORAGE UNIT of the same block-device layer that drives the floppy** (established 2026-08-25: all seven unit-1 arms of `Fdc_Request` reach its accessors — `notes/prom_a_unit1_backend_check.py`, `notes/FINDINGS-prom_a-fdc.md` §6). FOUR accessors, `0xFE4C73` write byte, `0xFE4C99` write word, `0xFE4CBF` read byte, `0xFE4CE0` read word, each building `0x7E0000 + ((n & 7) \| 0x08)` or `\| 0x10`; those four are the only `add Xrr,0x007E0000` instructions in prom_a+prom_b | in the **only** traced caller (0xFE50A0) both arguments are 0, so the index is the constant 0x08 for all 256 iterations — that site behaves as a **FIFO at 0x7E0008**. "Two banks of eight registers" is read off the index construction alone, not off any sweep |
| 0x7F0000 / 0x7F0002 | | CS0 | address-register + data-register pair; 8 writes per slot, slot = `(n<<5) \| 0x10` | `0xF8319A ld XIX,0x007F0000` / `0xF831A8 ld (XIX),W` / `0xF831AA ld (XIX+0x02),A` |
| 0xE00000-0xEFFFFF | 1 MiB | CS2 | **NOT ESTABLISHED** — CPU 1 never references it | |
| 0xF00000-0xF7FFFF | 512 KiB | CS2 | **prom_b** — CONFIRMED, §4 | |
| 0xF80000-0xFFFFFF | 512 KiB | CS2 | **prom_a** | reset vector at 0xFFFF00 |
| 0x400000-0x5FFFFF, 0x800000-0xDFFFFF | | BEXCS | **NOT ESTABLISHED** — no confirmed access | |

**CS0's window itself is the one row the elimination leaves open:**
`0x600000-0x7FFFFF` (base truncated to the window) or `0x780000-0x97FFFF` (base
literal). Both survivors agree every device listed above is on CS0. The literal
reading is the one that makes `MSAR0 = 0x78` mean anything and matches the fact
that every CS0 device sits at or above 0x790000; the truncated reading is what
the sibling project assumes. **NOT ESTABLISHED. Do not quote a CS0 range without
this sentence.**

### Runtime changes to the controller — only two survive verification

* `0xF830AC ldio DMEMCR,0x2D`, immediately before `0xF830B0 set 5,(P6)` and
  `0xF830B3 halt` — DRAM self-refresh for power-down.
* `0xFE509B ldio B0CS,0x10` … 256 iterations … `0xFE50D5 ldio B0CS,0x14`. CS0
  timing is changed for the duration of a 0x200-byte transfer read through
  0x7E0008. (⚠ 256 iterations of 2 bytes — `0xFE50CD inc 2,IZ` /
  `0xFE50CF cp IZ,0x0200`. An earlier pass said 512.)

Rejected as data mis-traced as code, each checked by reading the surrounding
disassembly: `0xF1BBEA "ld (MSAR1),0x1C"` (font-glyph bytes — prom_b file
0x1BBE0 is `08 08 08 08 08 08 08 08 08 08 08 3e 1c 08 00 00`, a down-arrow
glyph), `0xF2B26C`, `0xFF3CD5`.

---

## 2. CPU 2 — prom_c (0xF80000)

Reset PC `0x00FFF000`. The whole boot block is converted in
`prom_c/wsa1_prom_c.s`.

| ROM addr | bytes | reg | value |
|---|---|---|---|
| 0xFFF038 | `08 3c 10` | MSAR0 | 0x10 |
| 0xFFF03B | `08 3d 07` | MAMR0 | 0x07 |
| 0xFFF03E | `08 3e c0` | MSAR1 | 0xC0 |
| 0xFFF041 | `08 3f 7f` | MAMR1 | 0x7F |
| 0xFFF044 | `08 5c e0` | MSAR2 | 0xE0 |
| 0xFFF047 | `08 5d 3f` | MAMR2 | 0x3F |
| 0xFFF04A | `08 5e 00` | MSAR3 | 0x00 |
| 0xFFF04D | `08 5f 03` | MAMR3 | 0x03 |
| 0xFFF050 | `08 68 10` | B0CS | 0x10 |
| 0xFFF053 | `08 69 14` | B1CS | 0x14 |
| 0xFFF056 | `08 6a 1b` | B2CS | 0x1B |
| 0xFFF059 | `08 6b 1b` | B3CS | 0x1B |
| 0xFFF05C | `08 6c 00` | BEXCS | 0x00 |
| 0xFFF05F | `08 5a 71` | DREFCR | 0x71 |
| 0xFFF062 | `08 5b 89` | DMEMCR | 0x89 |

`0xFFF01A ldio P6FC,0x1F` — the same five port-6 functions as CPU 1, so the CS3
pin is LCAS here too and the CS3 area is the DRAM area.

Both surviving decoders give identical windows on this CPU: CS0
0x100000-0x13FFFF, CS1 0xC00000-0xFFFFFF, CS2 0xE00000-0xFFFFFF (so CS1's
effective span is 0xC00000-0xDFFFFF), CS3 0x000000-0x01FFFF.

| range | size | CS | device | evidence / grade |
|---|---|---|---|---|
| 0x000000-0x00007F | 128 B | — | internal I/O | |
| 0x000080-0x01007F | 64 KiB | CS3 | work DRAM, cleared at boot | `0xFFF085 ld XBC,0x8000` / `lda XIX,0x80` / `ld (XIX+),WA` → 0x8000 × 2 bytes. A lower bound |
| 0x00FFF0 | | CS3 | initial stack pointer | `0xFFF006 ld XSP,0x0000FFF0`. Moved down to 0x00FA00 at the main entry (`0xF9816B`) |
| 0x010000-0x01FFFF | 64 KiB | CS3 | **the FLASH STAGING BUFFER** — one whole flash sector, held in RAM. `Flash_ReadSectorToBuffer` copies a sector into it with one `LDIRW`, `Flash_ProgramSectorFromBuffer` burns it back, and `Flash_ProgramSlice1K` burns one 1 KiB slice of it; the block writers address it as `flash address − 0x00E70000`, which is `0x00010000 + (address − 0x00E80000)`. ⚠ It shadows only the FIRST 64 KiB of the flash. ⚠ It also overlaps the last 0x80 bytes of the boot DRAM clear, whose extent is a lower bound | `0xFC8903`, `0xFC8945`, `0xFC89B3` all `ld XIX,0x00010000`; `0xFC87AE`, `0xFC881B`, `0xFC8851` all `sub XBC,0x00E70000`. All six asserted from the ROM by `notes/prom_c_flash_driver_check.py`; the driver is converted at `prom_c/wsa1_prom_c.s` 0xFC856C-0xFC89C4 |
| 0x100000 | 1 B | CS0 | **inter-processor link port** — §3 | `0xF999F9 ld XBC,0x00100000` / `ld (XBC),A` |
| 0x104000 (+0 sel / +2 data) | | CS0 | 16-bit address/data register pair, **64 channels x 19 parameter registers**, numbered `block*0x40 + channel`. Role NOT established — see `notes/FINDINGS-prom_c-tone-generator.md` §0 for the tone-generator inference and why the labels say `Dev104_` and not `TG2_` | `0xFB7802 ld XBC,0x00104000` / `ld (XBC),DE`; the whole per-channel map from `Dev104_WriteAllChanRegs` 0xFB77EF, checked by `notes/prom_c_tg_regmap.py --dev104` (FAILURES: 0) |
| 0x108000 (+0 event / +2 status) | | CS0 | **KEY-SCAN PORT** — the 61-key keybed. +2 read is a status word whose bit 0 gates a read; +0 read is one 16-bit key event, low byte = bit 7 note-on and bits 6..0 key number, high byte = the touch measurement. ⚠ **NOT** the "+0 address / +2 data" shape of the rows above and below: at init `Dev108000_Preload_80toBF` writes +2 **first** (0x0080+i) and +0 **second** (0x8000), the opposite order, and every other access is a bare read | 3 literal sites at +0 (0xF9914D, 0xF99776, 0xF998C6) and **2 at +2** (0xF99146, 0xF99762) — `notes/prom_c_xrefs.py 0x00108000 --no-window --classify` and the same for 0x00108002. Meaning: `KeyScan_ReadEvent` 0xF9973D, whose two bytes are pushed straight into `ToneGen_VelocityFromTouch`; see `notes/FINDINGS-prom_c-keyboard-and-touch.md` |
| 0x10C000 (+0 sel / +2 data / +4 readback) | | CS0 | 16-bit address/data device, nop-padded for bus timing. **102 references — by far CPU 2's busiest device**; a flat table hides that. **64 channels x ~22 parameter registers**, `block*0x40 + channel`, with three per-channel gate registers pulsed bit-15 set→clear. Role NOT established — labels say `Dev10C_`; see `notes/FINDINGS-prom_c-tone-generator.md` §0 | `0xFA667E ld XIX,0x0010C000`; `0xFAC12D ld (XBC),DE` / `0xFAC132 ld (XBC+0x02),0xFF00` followed by five `nop`; `0xFA690A ld HL,(XBC)` with XBC = +4 |
| 0x110000-0x13FFFF | | CS0 | **NOT ESTABLISHED** | |
| 0xC00000 + 0x18, +0x31 | | CS1 | **expansion board.** Header fields read at +0x18 and +0x31; the signature it is checked against, `"WSA1 EXTBD"`, is in prom_c **twice**, at file 0x6129E and 0x61EC9 | `0xFB6B6E ld XIX,0x00C00000` / `ld C,(XIX+0x31)` / `ld C,(XIX+0x18)` |
| 0xC00040-0xDFFFFF | | CS1 | **NOT ESTABLISHED** | |
| 0xE00000 (+0 / +2) | | CS2 | address/data register pair — byte-identical driver shape to CPU 1's 0x7F0000 | `0xF98057 ld XBC,0x00E00000` / `ld (XBC),A` / `ld (XBC+0x02),E`, after `sll 0x05,A; set 0x04,A` |
| **0xE80000-0xEFFFFF** | **512 KiB** | CS2 | **FLASH — size ESTABLISHED** | see below |
| 0xE00004-0xE7FFFF, 0xF00000-0xF7FFFF | | CS2 | **NOT ESTABLISHED** | |
| 0xF80000-0xFFFFFF | 512 KiB | CS2 | **prom_c** | reset vector at 0xFFFF00 |

> ⚠ **Correction (round 4).** The 0x108000 row previously read *"same shape. **Three** sites, not five: 0xF9914D, 0xF99776, 0xF998C6"*, with an empty evidence column — "same shape" meaning the address/data register pair of the rows either side. Not one of those three sites is a select/data pair: all three are bare 16-bit accesses to +0. The three-site count was also a census of the +0 literal only and could not see the +2 literal at 0xF99762, which is where the status read lives. The device's role was established in the same round that left this row standing.

CPU 2 makes **no** runtime change to the CS or DRAM controller. (`0xF84AC5`,
`0xF88A0B`, `0xF952C5`, `0xFCD2FB` are all data; verified by disassembling
around each.)

### The flash, and why its size is established

The sector-erase routine at `0xFC8646` sets the device base
`(XIZ+0xFC) = 0x00E80000` (`0xFC864B`), takes the caller's address in XIX and
masks it to a 64 KiB block (`0xFC8656 ld XWA,0x00FF0000` / `0xFC865B and XIX,XWA`),
then unlocks with the AMD/Fujitsu sequence at base+0xAAAA / base+0x5554
(`0xFC8662`, `0xFC8672`) and command 0x80.

It then special-cases exactly two 64 KiB blocks:

* `0xFC869D cp XIX,0x00E80000` → erase at base+0x0000 (`0xFC86A8`), +0x4000
  (`0xFC86AF`), +0x6000, +0x8000;
* `0xFC86CF cp XIX,0x00EF0000` → erase at base+0x70000 (`0xFC86DA`), +0x78000
  (`0xFC86E7`), +0x7A000 (`0xFC86F4`), +0x7C000 (`0xFC8701`);
* anything else falls through to one generic 64 KiB erase, `0xFC870F`.

Those are the **first and last** blocks of a device whose highest sector base is
`0xE80000 + 0x7C000 = 0xEFC000`, with 16/8/8/32 KiB at the bottom and
32/8/8/16 KiB at the top. **The flash is 0xE80000-0xEFFFFF = 512 KiB = 4 Mbit.**
Chip erase is 0x10 at `0xFC863E`.

Which of the two geometries is used is selected by
`0xFC8694 cp (0x00E29D),0x22AB` — a 16-bit device-ID compare. A `0x22xx`
word-mode ID with a bottom/top boot pair is **Am29F400B/T-class**; that is an
inference from published ID tables, with **no datasheet in these trees**.

> **Round 4.** The whole driver is now converted — `prom_c/wsa1_prom_c.s`
> 0xFC856C-0xFC89C4, 16 routines — and every number in the two paragraphs above is
> re-derived from the ROM bytes by
> `python3 notes/prom_c_flash_driver_check.py` (not from unidasm's text), so this
> section is reproducible rather than hand-read. Two things it adds:
> **where `(0x00E29D)` comes from** — `Flash_ReadDeviceId` (0xFC859E) issues a real
> JEDEC autoselect (`AA / 55 / 0x90`), reads the manufacturer word at base+0 into
> `(0x00E29F)` and the device word at base+2, accepts manufacturer **1 or 4** and
> device **0x2223 or 0x22AB**, and returns 0xFFFF otherwise;
> `Flash_ProbeAndStoreDeviceId` (0xFC88A0) runs it once from MAIN at 0xF98B85 and
> stores the result. So the geometry is chosen from what the silicon answered at
> boot. And **what the flash is written by**: see
> `notes/FINDINGS-prom_c-flash.md`.

---

## 3. Inter-processor communication

The same driver on both sides, same packet format, different port and different
handshake pins.

| | CPU 1 | CPU 2 |
|---|---|---|
| data port | **0x7C0000** | **0x100000** |
| strobe out | P7 bit 0 (`0xF8E122 res 0,(P7)`, `0xF8E14A set 0,(P7)`) | PA bit 0 (`0xF99AE0 res 0,(PA)`, `0xF99AFF set 0,(PA)`) |
| busy in | P7 bit 3 (`0xF8E136 bit 3,(P7)`) | PA bit 3 (`0xF999D0`, `0xF99A06`) |
| timeout | 0x4E20 spins (`0xF8E113`) | 0x4E20 spins (`0xF999D9`, `0xF99A0F`) |
| busy flag | `(0x6007D9)` | `(0x00F32C)` |
| engine | **micro-DMA channel 2**: `0xF8E166 ldio DMA2V,0x12` then `0xF8E169 set 2,(TRUN)` | **the same**: `0xF99A2A ldio DMA2V,0x12` then `0xF99A2D set 2,(TRUN)` |

⚠ Two corrections to an earlier pass. The register at 0x7E is **DMA2V**, not
DMA3V (`tmp95c061.cpp:1390`), and `tlcs900_process_hdma` computes the trigger as
`(DMAnV & 0x1f) << 2 = 0x48 = INTT2` (`tmp95c061.cpp:353`, vector map `:322-346`)
— which is exactly the interrupt slot both vector tables point at a handler for.
And CPU 2 is **not** "engine: —"; it programs the identical channel.

Header byte = `(channel << 5) | (len - 1)`, or a bare command `0xE0 | n`
(`0xF8E1AB or D,0xE0`; CPU 2 `0xF99AEC or H,0xE0`). Observed commands 0xE1,
0xE2, 0xE4.

**Command 0xE2 = remote memory read.** `0xF8E0FE` builds a 10-byte packet in
CPU 1 work RAM at **0x600793** (`0xF8E105 lda XIX,0x600793`), lays it out as
`+0x00` remote address (32-bit, `0xF8E150`), `+0x04` local destination (32-bit,
`0xF8E155`), `+0x08` length (16-bit, `0xF8E15B`), writes 0xE2 to 0x7C0000
(`0xF8E130`) and hands the packet to micro-DMA 2. Two callers pin the layout:
`0xF828A1` passes (dest 0x2640, len 0x0A, remote 0xC00000) and `0xFB24D3` passes
(dest 0x60A000, len 0, remote 0xE80000).

⚠ **The addresses inside these packets are CPU 2's, not CPU 1's.** 0xC00000 is
CPU 2's expansion board and 0xE80000-0xECxxxx is CPU 2's flash. Anything that
reads them as CPU 1 bus addresses is wrong. The 0xC00000 read is followed by a
comparison against `"WSA1 EXTBD"` at prom_a file 0x28C7 — the same string prom_c
holds.

---

## 4. prom_b sits at 0xF00000 — CONFIRMED

Four independent proofs.

1. **prom_a's vector table points into prom_b.** File 0x7FF1C = `a4 00 f4 00` →
   0x00F400A4; 0x7FF28 → 0x00F40EDC; 0x7FF30 → 0x00F42D28. At prom_b file
   **0x400A4** sits `1b a5 e9 f8 jp 0xF8E9A5`; at **0x40EDC**,
   `1b 7f e4 f8 jp 0xF8E47F` followed by more 4-byte-aligned `jp`s. A linker
   thunk table, perfectly aligned; one byte of base error destroys it.
   (⚠ An earlier pass wrote these as prom_b file 0x000A4 / 0x00EDC. Those
   offsets hold unrelated bytes.)
2. **The reset path jumps there.** `0xF827C4 jp 0xF42D60` → prom_b file 0x42D60
   = `1b 06 56 f8 jp 0xF85606`, and 0xF85606 is `ld XSP,0x0060EB80` — a
   plausible main entry, and the first stack this machine has.
3. **A PC-relative call crosses the boundary.** `0xF80007 calr 0xF7F245`; prom_b
   file 0x7F245 is a well-formed function. prom_b sits immediately below prom_a.
4. **The thunk the EXTBD caller needs is in prom_b.** `0xF828A1 call 0xF40EF0`,
   and prom_b file 0x40EF0 is `1b fe e0 f8 jp 0xF8E0FE` — the 0xE2 remote-read
   entry. prom_b's 0x40000-0x434F4 is a large thunk region: of the 3388
   4-byte-aligned slots in it, **1971** hold `1B lo mid hi` with a target inside
   0xF00000-0xFFFFFF.

⚠ Correction to an earlier pass: prom_b **does** contain "WSA" strings — 13 of
them, e.g. file 0x2E13F `"WSA and cannot be played"`, 0x30810 `"WSA1 "`, 0x48C00
`"WSA SOUND RAM S0WSA1"`, 0x59275 `"WSA    HEADER"`. The narrow claim that
survives is that prom_b contains **no lowercase `wsa` string at all**, and in
particular no `wsaX_NNN` build tag at file 0x7FFF0 — prom_a, prom_c and prom_d
each have one there — because prom_b's 0x7FFF0 is code:
`1d 78 2a f4 1e 8f 00` = `call 0xF42A78` / `calr 0xF80086`, then RET padding.
That is consistent with prom_b being the low half of a contiguous 1 MiB image.

---

## 5. prom_d — TIED TO AN INSTRUCTION 2026-08-25, and its base is 0xF00000

> ★★★ **CORRECTED 2026-08-25 (wave 5 round 3).** This section was titled
> *"strongly supported as the **0xE80000** flash image, one link short"* and ended
> **"Still missing: a byte-level tie between a specific prom_d structure and a
> specific instruction."** That tie now exists, and it moves the base.
>
> `VersionScreen_Show` (prom_a `0xF82A28`) reads **11 bytes from remote
> `0x00F7FFF0`** into RAM `0x264C` and displays them under the ASCII label
> **`WSA-D:`**. prom_d's last sixteen bytes are `wsad_54.ssf`, at file offset
> `0x7FFF0` — so remote `0x00F7FFF0` is prom_d and its base is **`0x00F00000`**,
> not `0xE80000`. The firmware even carries a branch shaped for prom_d's
> one-byte-shorter tag (`cp (XIX+0x15),0x6673` at `0xF82A93` tests bytes +9/+10
> for the ASCII `"sf"`, which `wsad_54.ssf` has and `wsac_230\x02ssf` does not).
>
> ⚠ The tone-data reads at remote banks `0xE8`-`0xEC` are `0x80000` **below**
> that. ~~Either prom_d is a different part from the tone flash, or the two windows
> are the two halves of one larger part with prom_d as the upper half. **This
> evidence does not choose between them and neither reading is asserted.**~~
>
> ★★ **CHOSEN 2026-08-25 (round 2), and it is the FIRST reading: a DIFFERENT PART.**
> The "two halves of one larger part" alternative is refuted by prom_c's own flash
> driver. `Flash_SectorErase` holds the device base `0x00E80000` (`ld XBC,0x00E80000`,
> `0xFC864B`) and picks its TOP boot-block map by testing the requested 64 KiB sector
> against `0x00EF0000` (`cp XIX,0x00EF0000`, `0xFC86CF`), then erases sub-sectors at
> device offsets `0x70000`, `0x78000`, `0x7A000`, `0x7C000` — the last covering
> `0x7C000-0x7FFFF`. So the firmware's own model of that part ends at
> `0x00E80000 + 0x7FFFF = 0x00EFFFFF`, **below** prom_d's base; a 1 MiB part with
> prom_d as its upper half would put its top boot block at `0x00F70000` and that
> compare would read `0x00F70000`. Corroborated by the two device codes the probe
> accepts, `0x2223` and `0x22AB`, which are 4 Mbit = 512 KiB parts (§2 and
> `FINDINGS-prom_c-flash.md` §2). Checked from the ROM bytes by
> `python3 notes/prom_d_base_checks.py` (12 checks, FAILURES: 0).
> ⚠ Still not asserted: which part prom_d is, or that prom_d is a flash at all.
>
> Full argument and 11 independent checks:
> `notes/FINDINGS-prom_a-boot-and-version-screen.md` §1,
> `python3 notes/prom_a_boot_checks.py`.

The evidence that stood before the tie, unchanged:

* prom_d is **exactly 0x80000 bytes**, exactly the span §2 proves for the flash.
* Its content ends at 0x50B08. From **0x50B09 to 0x7FFEF it is one unbroken
  0xFF run** — 0x2F4E7 bytes, the only 0xFF run ≥ 0x1000 in the file — and the
  build tag `wsad_54.ssf` sits at 0x7FFF0. That is an **erased-flash image**.
* Its header at 0x00-0xB0 is 44 offsets, all 0-based and all < 0x80000
  (word[0] at +0x000 is 0xFFFFFFFF, not an offset), max **0x050AFA** — 14 bytes
  short of where the content stops.
* prom_d holds the tone/voice data: names at 0x50200+ ("Helicopter",
  "Telephone", "Orchestra.Hit"), 0x1A1D1 (" Dark Universe ").
* prom_d contains **no absolute code pointers**. Taking every aligned LE32 word
  whose top byte is 0x00 and whose value is >= 0x1000 — i.e. everything that
  could be a 24-bit address — and counting bank bytes: prom_d's are flat noise
  (0x40:1267, 0x1E:784, 0x64:722 out of 20076), while prom_a's pile into its own
  address space (0xFA:524, 0xFF:309, 0xFE:267) and prom_b's into the pair's
  (0xF7:709, 0xF1:533, 0xF0:495, 0xFB:457).
* CPU 1 fetches tone data from the remote flash over the link, at remote bank
  bases 0xE8, 0xE9, 0xEA, 0xEB, 0xEC.

⚠ One argument from an earlier pass does **not** work and must not be reused:
the remote banks observed in prom_a stop at 0xEC (offsets 0x00000-0x4FFFF),
while prom_d's largest header offset 0x050AFA is in bank 0xED. The offset table
does *not* match the observed bank list; it matches the *device*, which is
larger than the part of it prom_a happens to reference.

**~~Still missing:~~ SUPPLIED 2026-08-25** — see the correction at the head of
this section. ~~What is *still* missing is narrower: nothing indexes prom_d's
44-entry offset header or its 274-entry pointer directory, so the tie is to the
image, not to its internal structures.~~ prom_d's linker script keeps ORIGIN 0 as
a build convenience.

> ★★ **NARROWED FURTHER 2026-08-25 (round 7).** Something in prom_c now *does*
> index this image with 0-based offsets, at the base this section establishes.
> `ExtBoard_ProbeAndInstallBases` (prom_c `0xFB051E`/`0xFB0523`) stores
> **`0x00F00000`** into RAM `0x00D7ED`, and `Voice_SelectKeyZone_Reg0040`
> (`0xFA81AC`-`0xFA81F1`) relocates **three** nested 32-bit fields of a voice's
> tone object against it — a 128-byte key map indexed by the played note, a byte
> array behind it, and a record array whose first word it sends to the tone
> device's register `chan + 0x0040`. The alternative base, `0x00D80D`, is
> `0x00C00000`, the expansion board, or 0 when none is fitted. So prom_d's
> *"every value is a 0-based file offset"* and prom_c's *"base + offset against
> 0x00F00000"* are the same scheme meeting at the same address.
> ⚠ Still NOT proven: that a *specific* prom_d structure is one of those arrays.
> The offsets live in RAM objects whose loader is not traced.
> `notes/FINDINGS-prom_c-dev10c-register-meanings.md` §4b;
> `python3 notes/prom_c_dev10c_meaning_checks.py` section 16.

---

## 6. Explicit list of what could NOT be established

* **BnCS / BEXCS bit layout**, beyond "the low bits are access timing".
* **DREFCR / DMEMCR fields.**
* **CS0's window on CPU 1** — 0x600000-0x7FFFFF or 0x780000-0x97FFFF (§0).
* **Whether MSAR's base is truncated to the window or taken literally.**
* **CPU 1 CS1 above 0x0051FF**; the clear loop is a lower bound.
* **CPU 1 0x610000-0x67FFFF, 0x680000-0x78FFFF, 0xE00000-0xEFFFFF, and the whole
  BEXCS space** — nothing referenced.
* **CPU 2 0x010080-0x01FFFF, 0x110000-0x13FFFF, 0xC00040-0xDFFFFF,
  0xE00004-0xE7FFFF** — nothing referenced. ⚠ **`0xF00000-0xF7FFFF` was on this
  list and has been REMOVED (2026-08-25):** no prom_c instruction names it, but
  CPU 1 reads `0x00F7FFF0` over the link from prom_a `0xF82A5F`, and that is
  prom_d — §5.
* **The identity of the remaining CS0 devices on CPU 1** (0x790000/1,
  0x7F0000 — 0x7A0000, 0x7B0004/5 and 0x7E0008 were identified 2026-08-25,
  `notes/FINDINGS-prom_a-fdc.md`) **and on CPU 2** (0x104000, 0x108000,
  0x10C000). Register interfaces are described; part numbers are not.
* **Whether CPU 1's 0x7F0000 and CPU 2's 0xE00000 are one dual-ported chip or
  two instances.** The driver shape is byte-identical; that is all.
* **prom_d's base** (§5).
* **Coverage.** Recursive descent from the vectors plus thunk-table seeding
  reaches 36.7% of prom_a+prom_b and 42.6% of prom_c
  (`scripts/analysis/trace_code2.py`). Devices touched only from unreached code
  are missing from this map. 0x790000 is exactly such a case — real
  (`0xF8ECF4`) but outside the reached set.

## 7. Method warning, recorded because it nearly manufactured a device

Linear disassembly of prom_c decodes the IEEE-754 double table at file 0x4B27E
(CPU 0xFCB27E; `18 2d 44 54 fb 21 09 40` is π) into a tidy stride-4 register
file. 280 phantom "registers" spanning 0xFCB27E-0xFCCA7E came out of that before
`trace_code.py` existed. Every address in this document was confirmed by reading
the disassembly around its site. The ones that failed that check are named in
`scripts/analysis/README.md` as known artefacts.
