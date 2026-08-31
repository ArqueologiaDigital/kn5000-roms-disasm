# CPU 2's flash driver, and what the inter-processor link is FOR

Scope: `prom_c` (IC28, CPU 2), the 512 KiB flash at **0x00E80000**, the 64 KiB RAM staging
buffer at **0x00010000**, and the 16 routines converted at **0xFC856C-0xFC89C4** (1,113 bytes)
in `prom_c/wsa1_prom_c.s`.

Reproduce every number below with

```
python3 notes/prom_c_flash_driver_check.py     # asserts each claim against the ROM bytes
python3 scripts/analysis/assert_byte_identical.py   # THE GATE
```

`prom_c_flash_driver_check.py` matches **bytes**, not unidasm's text, so nothing here depends
on the disassembler being right. It prints every check and exits non-zero on any failure.

> **What this note does NOT establish.** What is stored in the flash. What the layer at
> 0xFC38xx-0xFC3Cxx (three callers of `Flash_ReprogramSector`, three more of
> `Flash_ReadSectorToBuffer`) is doing. What the word at 0x00E83232 is. And the part number:
> see §2.

---

## 1. ★★ The link is a flash download path

`Link_ServiceTask` (0xF99E5F, converted earlier) has three deferred jobs, each guarded by one
bit of the flag byte 0x00852C or 0x00852A. Its header used to end *"Unknown: the six 0xFC8xxx
routines the three jobs call"*. All six are in this block:

| job | what it calls, in order |
|---|---|
| bit 7 of 0x00852A | `Link_SendCmdE1(...)` — the reply path, unchanged |
| bit 7 of 0x00852C | `Flash_ReadSectorToBuffer((0x00852D))`, `Flash_ReadResetMode()`, `Flash_SectorErase((0x00852D))` |
| bit 6 of 0x00852C | `Flash_ReadResetMode()`, then spin on `Flash_SectorBlankCheck((0x008531))`, then `Flash_ProgramSectorFromBuffer((0x008531))`, then `Link_SendCmdByte(6)` |
| bit 5 of 0x00852C | `Flash_ProgramSlice1K(n)` for each index `n` the counter at 0x008536 reaches, bounded by 0x008535. ⚠ **Simplified** — the arm has two sub-paths, one of them gated on a `Flash_SectorBlankCheck((0x008568))` that re-sets bit 5 and retries if the erase is not finished; read `Link_ServiceTask` for the exact shape. What is identified here is the call target |

So: **CPU 1 pushes data into CPU 2's RAM buffer over the link, and CPU 2 burns it into flash a
kilobyte at a time.** The sequence is read-sector-into-RAM → erase → fill → verify erased →
program → acknowledge, which is the only safe order for a device whose erase granularity
(64 KiB) is far larger than its write granularity (one 16-bit word).

★ `Link_SendCmdByte(6)` is **command 0xE6** — the routine ORs the argument with 0xE0. That is
derived in `Link_SendCmdByte`'s own header, from the frame layout, not guessed.

⚠ Each row above is a reading of the arms of `Link_ServiceTask`, whose instructions are
converted and whose call targets its header already cited by address. What is new here is the
identification of the targets. **What the downloaded bytes are is still unknown.**

---

## 2. The device: what the ROM says, and what it does not

`Flash_ReadDeviceId` (0xFC859E) issues the JEDEC autoselect sequence
`(0x00E8AAAA)=0xAA / (0x00E85554)=0x55 / (0x00E8AAAA)=0x90`, then reads two words:

* base+0 → the **manufacturer** code, stored at `(0x00E29F)`, accepted if it is **1** or **4**;
* base+2 → the **device** code, accepted if it is **0x2223** or **0x22AB**, returned in WA;
  otherwise WA = 0xFFFF (IX is preloaded with 0xFFFF at 0xFC85AD).

`Flash_ProbeAndStoreDeviceId` (0xFC88A0) runs that once, from MAIN at 0xF98B85, and stores the
device code at `(0x00E29D)` — which is the value `Flash_SectorErase` later tests. **So the
sector geometry is chosen from what the silicon answered at power-on, not from a constant.**

⚠ **The read/reset that ends `Flash_ReadDeviceId` is on the matching path only.** `calr
Flash_ReadResetMode` is at 0xFC85F3 and the `jr NZ,0xFC85F6` at 0xFC85E1 jumps past it whenever
the manufacturer word is neither 1 nor 4. On an unrecognised part the routine therefore returns
with the device still in autoselect mode — where reads return ID words instead of data — and
its one caller does not reset it either. Stated as the instructions read; no claim that it ever
happens in a real machine.

`Flash_SectorErase` (0xFC8646) masks its argument to a 64 KiB boundary and then has three arms:

| condition | sectors erased | sizes |
|---|---|---|
| `(0x00E29D) == 0x22AB` **and** sector `== 0x00E80000` | +0x0000, +0x4000, +0x6000, +0x8000 | 16K, 8K, 8K, 32K |
| sector `== 0x00EF0000` (any other device code) | +0x70000, +0x78000, +0x7A000, +0x7C000 | 32K, 8K, 8K, 16K |
| neither | one erase at the sector base | 64K |

The two are exact mirror images, the top one starts seven 64 KiB sectors up, and
7 × 64K + 64K = **512 KiB**.

⚠ **This size is not a new result.** `notes/FINDINGS-memory-map.md` §2 derived it from this
same routine before the block was converted. What is new is that it is now asserted by a
script instead of read by hand, and that the manufacturer half of the ID check is documented.

⚠ **The part number is an inference**, the same one the memory map already records: that
sector map with a `0x22xx` word-mode device ID is the AMD Am29F400B/Am29F400T family and its
second sources, and JEDEC assigns manufacturer 0x01 to AMD and 0x04 to Fujitsu. **No datasheet
is in these trees, and no label in the source names a part.**

⚠ The two special arms are keyed on different things — the first on the device code *and* the
address, the second on the address alone. Device code 0x22AB with sector 0x00EF0000, or
0x2223 with 0x00E80000, both fall through to the single-erase arm, which on a split boot block
would erase only its first sub-sector. Recorded as the instructions read; no claim that either
combination occurs.

---

## 3. The staging buffer at 0x00010000

Three routines load `0x00010000` literally (`0xFC8903`, `0xFC8945`, `0xFC89B3`) and four mask a
flash address with `0x00FF0000` (`0xFC8908`, `0xFC8951`, `0xFC8992`, `0xFC89B8`). The two block
writers compute their destination as `flash address − 0x00E70000` (`0xFC87AE`, `0xFC881B`,
`0xFC8851`), which is `0x00010000 + (address − 0x00E80000)`.

So the buffer is one whole sector held in RAM, at a fixed address, shadowing the flash from
0x00E80000. ⚠ **It only covers the first 64 KiB of the device**: for a sector above
0x00E8FFFF the block writers would address past it. Stated as read.

This fills in a row `notes/FINDINGS-memory-map.md` had as **NOT ESTABLISHED** (CS3
0x010080-0x01FFFF).

---

## 4. ★ One loop counts with an 8-bit register where its siblings use 16

| routine | count set | loop ends with | prefix byte | register | bytes actually covered |
|---|---|---|---|---|---|
| `Flash_ProgramSectorFromBuffer` 0xFC88F9 | `ld BC,0x8000` | `djnz BC` @0xFC8935 | **0xD9** | BC (16-bit) | 0x8000 words = 64 KiB |
| `Flash_ProgramSlice1K` 0xFC893B | `ld BC,0x0200` | `djnz BC` @0xFC8989 | **0xD9** | BC (16-bit) | 0x200 words = 1 KiB |
| `Flash_SectorBlankCheck` 0xFC898F | `ld BC,0x4000` | `djnz B` @0xFC89A5 | **0xCA** | **B (8-bit)** | **64 longs = 256 bytes** |

B is the *high* byte of BC, so `ld BC,0x4000` leaves B = 0x40 = 64, and each pass compares a
32-bit long (`ld XWA,0xFFFFFFFF` at 0xFC899B, `cp XWA,(XIY+)` at 0xFC89A0). The blank check
therefore inspects the **first 256 bytes** of the sector, not the 64 KiB the `0x4000` implies.

The prefix → register mapping is MAME's, not assumed: `oC8()` / `oD8()` and
`get_reg8_current()` in `mame/src/devices/cpu/tlcs900/900tbl.hxx` (lines 115-150, 5672-5690).
`prom_c_flash_driver_check.py` asserts both prefix bytes and all three counts.

⚠ **Whether this is a defect or a deliberately short poll is not established.** Every caller
uses it only as *"has the erase finished yet"* — `while (check(addr) == 0xFFFF) ;` — and for
that a 256-byte sample is adequate. As *"is this sector blank"* it is not. Recorded, not
judged.

---

## 5. The 16 routines

| address | name | one line |
|---|---|---|
| 0xFC856C | `Flash_ReadResetMode` | AA / 55 / 0xF0, then a 16-bit read of 0x00E83232 whose value every caller discards |
| 0xFC859E | `Flash_ReadDeviceId` | autoselect; §2 |
| 0xFC85FE | `Flash_ChipErase` | AA/55/0x80, AA/55/0x10. **No caller found.** Does not wait |
| 0xFC8646 | `Flash_SectorErase` | §2. Runs at interrupt level 6 (`ei 6` 0xFC865D → `ei 0` 0xFC8713) |
| 0xFC8719 | `DSP_WriteChans0to3_FromE29D` | four hand-built calls to `DSP_ChannelRegs_Write8` for channels 0..3, all from 0x00E29D. **No caller found.** See below |
| 0xFC876B | `sub_FC876B` | one `ret` |
| 0xFC876C | `Flash_ReprogramSector` | erase + wait + program the buffer. Three callers at 0xFC39E1, 0xFC3B17, 0xFC3CAB |
| 0xFC8792 | `Flash_WriteBlockIntoSector` | read-modify-write: sector → buffer, erase, patch, wait, program |
| 0xFC87FF | `Flash_WriteTwoBlocksIntoSector` | the same with a second block. ⚠ only ONE sector is erased and committed, so the second block must lie in it; nothing checks that. **No caller found** |
| 0xFC88A0 | `Flash_ProbeAndStoreDeviceId` | three instructions; called once from MAIN |
| 0xFC88AC | `MemFillWordRamp` | `dest[i] = i`, count in WORDS |
| 0xFC88CA | `Flash_WriteRampPattern_E81000` | fills 0x0000F000 with a ramp and writes 256 bytes of it to 0x00E81000. **No caller found**; looks like a production test |
| 0xFC88F9 | `Flash_ProgramSectorFromBuffer` | AA/55/0xA0 per word, skipping 0xFFFF, data-polling until the read-back matches |
| 0xFC893B | `Flash_ProgramSlice1K` | the same over `index << 10 .. +0x3FF`. ⚠ the index is OR-ed, not added, into both pointers, so 0..0x3F is the valid range and nothing bounds it here |
| 0xFC898F | `Flash_SectorBlankCheck` | §4 |
| 0xFC89AF | `Flash_ReadSectorToBuffer` | one `LDIRW`, 0x8000 words, flash → buffer |

"No caller found" always means `notes/prom_c_xrefs.py <addr> --no-window` reports no literal
and no `calr` displacement. That tool does not search the short PC-relative forms, so it is
never proof that nothing reaches a routine.

### ⚠ The odd one out

`DSP_WriteChans0to3_FromE29D` (0xFC8719) is not a flash routine at all: it writes 32 registers
of the DSP at 0x00E00000, eight in each of channels 0..3, all four from the same 8 bytes at
0x00E29D. It sits in the middle of the flash driver, and 0x00E29D is exactly where
`Flash_ProbeAndStoreDeviceId` stores the device code (with the manufacturer code at 0x00E29F) —
so the first four of those eight bytes are the two flash ID words. **Whether that is deliberate
or whether 0x00E29D is simply a scratch buffer two unrelated things share is not established.**
Its call convention is verified rather than assumed: each block pushes `&0x00E29D`, then the
channel word, then the address of the following block, then `jp XIX` — which puts the channel
at (XSP+4) and the pointer at (XSP+6), exactly `DSP_ChannelRegs_Write8`'s documented layout,
and 0xFC8763 drops 0x18 = 4 × 6 argument bytes.

---

## 6. What the next pass needs

* **0xFC38xx-0xFC3Cxx.** Six calls into this block come from there
  (`Flash_ReprogramSector` ×3, `Flash_ReadSectorToBuffer` ×3). It is the layer that decides
  *which* sector and *what* goes in it, and it is the shortest path to knowing what the flash
  holds.
* **What 0x00E83232 is.** Read by `Flash_ReadResetMode`, returned, discarded by every caller.
* **Whether anything reaches `Flash_ChipErase`, `Flash_WriteTwoBlocksIntoSector`,
  `Flash_WriteRampPattern_E81000` or `DSP_WriteChans0to3_FromE29D`** — four routines with no
  literal caller. A pointer table would explain all four.
* **The 8-bit `djnz` in §4** — comparing prom_a for the same routine would say whether the
  other CPU's build has the same encoding, and that would separate "compiler/source quirk"
  from "one-off".
