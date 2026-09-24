# Wave 6 Plan — the sub-CPU payload source and the TMP94C241 dynamic memory map

Source: a wave-6 investigation (6 scanner packages + 1 adversarial critic + 1
adjudicator) over the payload-source question raised by
`v10/maincpu/kn5000_v10_program.s:346-360`, plus Felipe's testimony of
2026-08-08 about how IC30 and IC19 were dumped. Machine-readable findings and
per-package artifacts live under
`/home/fsanches/.claude/jobs/d0e1b1c2/tmp/wave6/`; the adjudicator's
re-verification of every load-bearing byte is in
`w7-adjudicator/reverification.txt`.

Published documentation from this wave (technics-docs, committed 2026-08-08):
`tmp94c241-memory-controller.md`, `subcpu-payload-provenance.md`,
`mame-emulation-gaps.md`, plus provenance sections in `rom-reconstruction.md`
and `subcpu-firmware-images.md` and corrections to `boot-sequence.md`,
`system-update-discs.md`, `custom-data-flash.md`, `lzss-compression.md`,
`subcpu-payload-loading.md`, `reverse-engineering.md` and
`ssf-presentation.md`.

**Evidence standard used throughout.** A claim needed bytes, an address, a
file:line or a measured output. Two traps recurred and both cost a retraction
inside the wave itself:

1. **Grep in the wrong number base.** The disassembler emits direct SFR
   addresses in decimal (`stdi8 (331), 192` = `LD (MSAR2), 0xC0`). A text grep
   for `MSAR` found nothing and produced the false premise the whole wave was
   launched on. *Search the binary.*
2. **Fitting a decode rule to the answer you want.** Two packages calibrated
   the MSAR/MAMR mask semantics on different single data points, got
   incompatible rules, and each reported "exact confirmation" from the same
   MAME map. Any address-range table in wave 6 is an **interpretation**.

---

## What wave 6 settled — do not re-derive this

| # | Fact | Grade |
|---|---|---|
| 1 | The firmware programs all six chip-select blocks, once per CPU, in one 24-write block. Main: `MSAR 1E 10 C0 00 80 00`, `MAMR 0F 3F 7F 1F FF FF`, `BnCSL 11 33 11 22 11 22`, `BnCSH 80 81 C2 8A 82 81`. Sub: `MSAR 10 11 FF 00 12 13`, `MAMR 07 03 01 1F/0F 01 01`. | proven |
| 2 | Exactly **one** runtime address change exists: `MSAR2 := 0x80` at table-data `0x9FB6D3` (`Boot_PrepareJump`), three instructions before `JP (XWA)` with `XWA = 0x00FFFEDC`. Independent of any decode rule: `0xFFFEDC` reads `FF FF FF FF` in the table-data image and `1B 0F 05 EF` in the program image. | proven |
| 3 | Control enters the program flash at `Boot_InitIOPorts` `0xEF050F`, not at `RESET_HANDLER` `0xEF03C6`. MAME starts at the latter. | proven |
| 4 | `B5CSL := 0x66` (from `0x22`) at four sites, all immediately before HD-AE5000 access. Timing, not addresses. `MSAR5`/`MAMR5` are never rewritten anywhere. | proven |
| 5 | IC19 and `hd-ae5000_v2_06i.ic4` contain **zero** chip-select accesses in any encoding. | proven |
| 6 | The IC19 dump is in linear chip order: eight `48 00 4B 00` section markers at exactly the eight firmware-derived offsets and nowhere else; wallpaper zero-run exactly at `0x0C0000`, length exactly 320×240+1024; `HK \0` exactly at `0x0D3000`. | proven |
| 7 | `kn5000_v10_disk.img` (sha1 `a892bedc…`) carries `HKMSPRG.SLD` = two SLIDE4K streams which decode byte-exactly to `kn5000_v10_program.rom` (2,097,152 B, consuming 965,545) and `kn5000_subprogram_v142.rom` (196,608 B, consuming 93,203). Reproduced three times with independently written decoders. | proven |
| 8 | `kn5000_subprogram_v142_compressed.rom` is byte-identical to disc `[0x0F03A9, +93203)` — carved, not synthesised. | proven |
| 9 | Type-007 install: erase IC19 `0x3E0000`+`0x3F0000`, decompress stream 1 into the `0x800000` window, copy stream 2 **verbatim** (`0x20000` bytes) to `0x3E0000`. Post-install image = 93,203 B stream + 68 × `0x00` + 37,801 × `0xE5`. | proven |
| 10 | `0x1FFEEB..0x1FFEEF` = `FF FF FF 00 FF` in v7, v9 **and** v10 — the payload-source chooser does not differ across versions, and the IC19 branch is always taken. | proven |
| 11 | IC30 census: 220 ROM-address operand references, all in dumped windows, none in an undumped range; one indirect `CALL T,XWA` bounded by an 8-entry all-dumped table; payload calls back at exactly `0xFFFEA1` and `0xFFFE86`. | proven |
| 12 | The sub-CPU boot ROM has a **strap-conditional** CS write: Port G bit 0 selects `MAMR3` `0x1F`/`0x0F` and `B3CSH` `0x8A`/`0x89` — a real board variant MAME does not model. | proven |
| 13 | MAME's `tmp94c241` stores `MSAR`/`MAMR`/`BnCS` and never consults them; `0x160`-`0x167` are unmapped and fall through to driver DRAM. | proven |
| 14 | MAME's `amd_29f800b_16bit_device` is an exact match for IC19 (size, width, ID `0x2258` accepted by the firmware's ID gate). `FUJITSU_29LV800B` would be rejected. | proven |
| 15 | `kn5000_floppies` registers `default_mfm_floppy_formats`, which lacks `FLOPPY_PC_FORMAT` — the driver cannot mount a raw `.img`. | proven |

## What wave 6 overturned

- **"No writes to the CS registers"** — false negative, decimal operands (see trap 1).
- **"The MSAR2 handover is a no-op under the calibrated mask rule"** — the rule was
  wrong, not the hardware. No external glue needs to be invented.
- **"Sub CS2 = 128 KB at 0xFE0000, therefore 116,736 undumped bytes"** — depends on
  the refuted 64 KB rule. Under the rule the main-CPU handover forces, sub CS2 is
  64 KB at `0xFF0000` and at most ~52 KB is both addressable and undumped.
- **`technics-docs/system-update-discs.md`** said type 7 stages the *program* ROM at
  `0x3E0000` for a later boot to flash. Wrong on both counts. **Fixed.**
- **`kn5000-roms-disasm/subcpu/boot/kn5000_subcpu_boot.s:231,237`** (and the ASL
  mirror at `archive/asl/subcpu/boot/kn5000_subcpu_boot.asm:232,238`) call the
  `0xFF` region "erased flash". IC30 is a **mask ROM** and the region is
  **UNDUMPED**. *Not fixed — read-only repo this wave. See package D1.*
- **"The blank tail stops at a data boundary, so the chip was never programmed"** —
  overstated. The last non-`0xFF` byte marks where the *data* ended, not where the
  *dump* ended.
- **"BnCSH bit 7 is a per-block enable"** — contradicted by the local register
  reference; the low nibble is bus width and cross-checks five chips correctly.

## The one question that is actually open

Every dumped firmware gates on `program[0x1FFEED] = 0xFF` and takes the IC19
`0x3E0000` branch. Our IC19 image has 131,072 blank bytes there and no `SLIDE`
magic anywhere. The fallback at table-data `0x800100` is `0xF7` filler behind an
LE32 pointer table. **A machine in the state of our dumps could not run its
sub-CPU** — so the IC19 image is not the state of Felipe's working instrument.

That is a **provenance** question, not a memory-map question and not a firmware
question. Three variants remain byte-indistinguishable in the file:

- (i) the region was never programmed on that unit;
- (ii) a `007h` install erased and did not write;
- (iii) the dump is truncated somewhere in `0x0D3450`-`0x0FFFFF` and `0xFF`-padded.

Everything downstream of "where is the payload" is blocked on separating these.

---

## Blocked on a hardware measurement or an external artifact

Ordered by cost. Items H1 and H2 are free, take minutes, and unblock the rest.

| # | Ask | Procedure | What it decides |
|---|---|---|---|
| **H1** | Felipe, on the instrument | Built-in memory-dump screen (`DBMEMORYDUMPPROC`, `0xFA2EE6`) at `0x3E0000`; look for ASCII `SLIDE4K` | Present ⇒ variant (iii), our dump is incomplete. Absent ⇒ (i) or (ii). No desoldering. |
| **H2** | Felipe, from memory | Was the keyboard producing sound at the time IC19 was read, or was the sub-CPU already dead? | Sound ⇒ (iii) forced. Silent ⇒ (i)/(ii) live. |
| **H3** | Felipe, from memory | Was IC19 read **in-system** through the CPU (like IC30) or off-board on a programmer? | In-system ⇒ a readback-window limit is a natural explanation for a truncated tail. |
| **H4** | Felipe, from the rating plate | Model suffix / AREA strap value | Whether the Region-4 two-die flash branch is even relevant to his unit (Brazil maps to Region 3) |
| **H5** | Felipe, chip markings | IC1/IC3 house numbers and package; IC19 top-boot vs bottom-boot marking | Whether the table-data ROMs are mask or flash (a fourth flash device?), and IC19's sector geometry |
| **H6** | Full IC19 re-dump | Device programmer, off-board or in-circuit with the CPU held in reset; search `53 4C 49 44 45 34 4B` | Definitive on the payload question |
| **H7** | Full IC30 re-dump | Re-run `subcpu_send.asm` over `0xFF0000-0xFF77FF` and `0xFF9800-0xFFEFFF`, **plus a control read at `0xFD0000-0xFD07FF`** | Converts 116,736 assumed bytes to measured; the control tells us whether `0xFF` is the open-bus value (which would make the `0xFE0000` window meaningless). Lets `BAD_DUMP` be removed from `kn5000.cpp:1466`. **Will NOT answer the payload question** — the payload is larger than the whole chip. |
| **H8** | TMP94C241(F) hardware manual | Acquire; read the chip-select / wait-controller section | The MSAR/MAMR decode rule and the reset defaults. **Gates any real CS-decoder implementation.** |
| **H9** | `kn5000_v5_program.rom` or `kn5000_v6_program.rom` | Read one byte at file offset `0x1FFEED` | Non-`0xFF` proves candidate A was the live path on early boards, i.e. it is a legacy path, and reframes the whole puzzle as generation skew |
| **H10** | v5-v9 update discs | Any of them | The v141→v7/v8 and v140→v5/v6 BIOS pairings are currently filename inference |
| **H11** | A `CMPCUSTOMDATA` (005h) disc | Any copy | The only artifact that would settle whether the IC19 dump is complete *below* `0x0D3450` |

---

## Analysis packages we can do now

Read-only where marked; each returns evidence, not conclusions.

### Group A — close the last analysis-side contradiction (do first)

| package | scope | blocks |
|---|---|---|
| **A1 `two-updaters`** | There are two complete copies of the flash-update subsystem — table-data `~0x9FA000-0x9FFFFF` and program flash. Pre-handover `0x800000` is the program pair; post-handover it is the table pair. But the **program-flash** copy of the 007h handler decompresses the 2 MB *program* image to `0x800000`, which post-handover is the *table* pair. Determine whether that copy is reachable at all (updates may always enter through the bootloader, which owns the boot FDC driver at `0x9FD8A5`), or whether a **second remap** exists that nobody has found. Method: enumerate every caller of the program-flash updater entry; check whether any path from `Boot_InitIOPorts` reaches it without re-entering the bootloader. | C3 (memory_view shape) |
| **A2 `mirror-scan`** | Scan `kn5000_v10_program.rom` and `kn5000_table_data.rom` for 24-bit immediates in `0xC00000-0xDFFFFF`. If the firmware uses the lower program-flash mirror, MAME's `map(0xe00000,0xffffff).mask(0x1fffff)` is incomplete and the "accidentally correct" framing is too generous. | C3 |
| **A3 `schematic-decode`** | Service-manual page 32, already rendered at 9921×7008 (`critic/raw32-000.png`, crops `c_ic19.png` / `c_dec.png` / `c_ic11.png`). Trace IC19 pin 12 (/CE) and pin 14 (/OE), IC14's /CE, and IC11 pins 4 and 6 back to their drivers. Record the result in `kn7000_mame/notes/`. **This is the physical ground truth for the whole CS question** and it is one afternoon of image work, not a hardware ask. | C1, C3, H8 partially |
| **A4 `sub-cs2-window`** | Decide whether sub-CPU CS2 is 64 KB @ `0xFF0000` or 128 KB @ `0xFE0000`. All 4,352 non-`0xFF` bytes lie in the upper 64 KB and the 2 KB read at `0xFE0000` came back blank. If 64 KB, MAME's `map(0xfe0000,0xffffff)` is over-generous and the "89% undumped" headline must be restated as "~52 KB addressable and undumped". Method: A3's trace plus the sub-CPU board schematic. | H7 scope |

### Group B — documentation and disassembly-repo corrections (independent, cheap)

| package | scope |
|---|---|
| **B1 `ic30-erased-comment`** | `subcpu/boot/kn5000_subcpu_boot.s:231,237` and `archive/asl/subcpu/boot/kn5000_subcpu_boot.asm:232,238` say "96KB of 0xFF (erased flash)". IC30 is a mask ROM and the region is UNDUMPED. Also make any "sub-CPU boot ~99% disassembled" figure state that only 3.3% of the chip is real data. (Overlaps Wave-3b package `subcpu-fill` in the binclude plan — merge them.) |
| **B2 `flash-id-comment`** | `custom_data/kn5000_custom_data.s:8-13` names IC19 an **AM29LV800B** with IDs `0x2223`/`0x22AB`. Both wrong: those two IDs are the 4 Mbit **AM29F400B**, the two 8 Mbit IDs (`0x22D6`, `0x2258`) are missing, and the family is 5 V AM29F400/800B. (Already corrected in technics-docs.) |
| **B3 `updater-renames`** | `LZ_Decompress_Init` (`0xEF4D95`) **is** the SLIDE4K decompressor and targets `0x800000`; `LZSS_Decompress_ToFlash` (`0xEF4CF8`) performs **no** decompression (verbatim `0x20000` copy to `0x3E0000`); `Parport_ReadNextByte` (`0xEF4C07`) is the floppy stream reader; `Flash_ProgramByte` (`0xEF3D7B`) programs a 32-bit long; `Flash_BurnWithProgress` (`0xEF4702`) chip-erases and burns nothing; `HDAE5000_Flash_Verify` is a chip-erase command sequence. |
| **B4 `boot-comment-fixes`** | `table_data/kn5000_table_data.s:246-247` says the fallback is `0x830000` — it is `0x800000`. `:3822` says `0x3E0000` is "Table Data ROM" — it is IC19. Also, `boot_hw_init.s` labels Block 4 "Table Data" while the CS2/CS4 reading (and `kn5000.cpp`) puts the table pair on CS2 — mark it unconfirmed rather than asserting either. |
| **B5 `docs-msar-tables`** | `technics-docs/boot-sequence.md` and `docs/table_data_boot_code.md` read MSAR literally as a base and ignore MAMR masking; `docs/mame-driver/cpu-peripherals.md` lists the SFR block as `0x140-0x14B` BxCS / `0x14C-0x151` MAMR / `0x152-0x157` MSAR, contradicting `sfr_tmp94c241.s` and the MAME core, which interleave per block. (boot-sequence.md is done; the disasm-repo docs are not.) |
| **B6 `kn1500-crosscheck`** | The only other TLCS-900 sibling in the tree is `kn1500.cpp` (TMP95C061), whose crt0 already has a chip-select setup. Diff it against `boot_hw_init.s:85-134`. If it uses the same "catch-all CS + external 138/139 decode" idiom, that is house style and independently supports A3's expected result. Cheap, and nobody has done it. (KN6000/KN6500/KN7000 are MN10300 and have **nothing** to compare — do not waste a package there.) |

### Group C — MAME work, in dependency order

| package | scope | prerequisites |
|---|---|---|
| **C1 `fdc-formats`** | Switch `kn5000_floppies` to `default_pc_floppy_formats` so raw `.img` discs mount. One line. Separately, evaluate `UPD72067` → `UPD72069` (the real part is a µPD72068GF; `mpc2000.cpp` sets the precedent) by **logging which aux bytes the firmware writes to `0x110008`** — decide from the measurement, not from the datasheet lineage. | none |
| **C2 `flash-devices`** | Instantiate `AMD_29F800B_16BIT` for IC19; model the `0x800000` and `0xE00000` pairs as two 16-bit AMD devices on a 32-bit bus (unlock at 4× word address). ⚠ **`intelfsh16::nvram_default()` byte-swaps a ROM-region preload** relative to `read_raw()` — a `ROM_REGION16_LE` preload of the IC19 dump reads back wrong. Also decide top-boot vs bottom-boot (H5). | C1 for testing |
| **C3 `memory-view`** | A **two-state `memory_view`** (table-data-high / program-high) reproducing the single CS2 swap. **Do not build a general CS decoder** — the decode rule is not established (H8). Two knock-ons: the driver's runtime `space.install_device(0x000000,0x2fffff,…)` for the HD-AE5000 slot and `m_extension->program_map(...)` in `machine_start()` will be shadowed if that range becomes view interior; and the IVT is ROM-resident at `0xFFFF00` and must swap atomically with the code. | A1, A2; ideally H8 |
| **C4 `update-mode-entry`** | The real end-to-end blocker. Update mode is gated on ROM `0xFFFFE8 == 0xFF` (`Get_Firmware_Version` `0xEF0534`) **and**, on hardware, a panel button held through power-on. Which button, and how to hold it from reset through the HLE'd `kn5000_cpanel_device`, is unknown. Same class of problem as the unsolved KN7000 self-test entry. | C1 |
| **C5 `install-replay`** | Acceptance test: boot with `kn5000_v10_disk.img`, run a type-007 update, dump `0x3E0000-0x3FFFFF`, compare against `w6-update-disks/ic19_3e0000_postinstall.bin` (93,203 B stream + 68 × `0x00` + 37,801 × `0xE5`, crc32 `9071988a`). Exact and mechanical — any deviation is a bug, not an interpretation dispute. | C1, C2, C4 |
| **C6 `bootloader-liveness`** | Second acceptance test, once C3 lands: assert the CPU executes `0xFFB4E8` before `0xEF050F`, and that a read of `0xFFFEDC` returns `FF FF FF FF` before the `MSAR2` store and `1B 0F 05 EF` after. | C3 |
| **C7 `secondary-gaps`** | Record, and fix where cheap: Region 4 is unreachable (`AREA` dip has no `0x00` setting) though its two-die flash branch exists; sub-CPU Port G is unimplemented so one DRAM board variant is silently chosen; the HD-AE5000 `0x280000` window is banked in firmware (8 × 128 KB via the PPI at `0x160000`, `hkt_` signature at `0x2FFFC0` with bank 7) but flat in `hdae5000.cpp`; `set_am8_16` is never called for either CPU. | none |

### Group D — provenance hygiene

| package | scope |
|---|---|
| **D1 `rom-provenance-notes`** | Land the IC30/IC19 provenance record in the disassembly repo's own notes (technics-docs already carries it). Include the exact measured split and the fact that the window boundaries are documentary, not measurable. |
| **D2 `overlay-honesty`** | Decide whether the `ROMX_LOAD` overlay of the compressed payload should carry a marker (the composite is a reconstruction and nothing flags it; the base `ROM_LOAD` has a clean CRC/SHA1). Discuss with Felipe before touching MAME ROM definitions — this is a policy call, not a technical one. Related: `/home/fsanches/compartilhado/kn5000_custom_data_with_preset.ic19` is **not** independent evidence (canonical dump + a grafted 27,967-byte SLIDE4K blob); it should be labelled or moved out of the way. |

---

## Ordering

```
  H1 + H2 + H3   (free, minutes, ask Felipe)
      │
      └──> decides variant (i)/(ii)/(iii) for IC19
               │
               ├── (iii) ──> H6 full IC19 re-dump ──> payload question CLOSED
               └── (i)/(ii) ──> the question moves off IC19 entirely;
                                 next suspects are H9 (was candidate A live?)
                                 and H11 (what should IC19 hold?)

  A3 schematic trace ────┐
  A1 two-updaters  ──────┼──> C3 memory_view ──> C6 liveness test
  A2 mirror scan   ──────┘        ▲
                                  └── H8 datasheet (would upgrade the view
                                      into a real CS decoder; not required)

  C1 fdc-formats ──> C2 flash-devices ──┐
                     C4 update-entry ───┴──> C5 install replay (exact test)

  Group B and A4 are independent of everything and can absorb spare capacity.
  Group D waits on a conversation with Felipe, not on analysis.
```

**Do not** start C3 before A1. A second remap, if one exists, changes the view's
shape, and A1 is the only thing that could reveal it.

**Do not** build a general chip-select decoder before H8. Two mask rules that
both "fit" already exist; a third guess is not progress.

---

## Non-negotiables

- Read-only on `kn5000-roms-disasm` and `kn7000_mame` for any package not
  explicitly scoped to edit them; one workflow at a time per repo.
- `make all` + `compare_roms.py` at 100% byte-match after every disasm merge.
- technics-docs commits need a passing
  `JEKYLL_NO_BUNDLER_REQUIRE=true jekyll build -s … -d /tmp/kn-site`, must
  `git add` explicit paths only, and must leave the pre-existing uncommitted
  `flowcharts/` edits alone. Nothing is ever pushed.
- Anything that is not an honest dump stays `BAD_DUMP` / `NO_DUMP` in MAME.
- Grade every finding and never inflate. A SUPPORTED hypothesis is not a fact;
  an UNDECIDED one must read as open.

## Estimated remaining

11 hardware/external asks (3 of them free and blocking), 4 analysis packages in
Group A, 6 documentation packages in Group B, 7 MAME packages in Group C, 2 in
Group D. Group A + C1 + C2 is the smallest set that produces a testable result
(the install replay, C5), and it does not require the instrument.
