# What the completed KN5000 disassembly says that the MAME drivers do not model

Lane `w12/drvkn5000`, 2026-09-02.  Sources read: `v10/maincpu`, `v9/maincpu`,
`v7/maincpu`, `v142/subcpu`, `subcpu/boot`.  Drivers read **read-only**:
`~/compartilhado/kn7000_mame/src/mame/matsushita/kn5000.cpp`, `kn7000.cpp`,
`kn7000_cpanel.{h,cpp}`, `kn_cpanel.{h,cpp}`, and
`~/compartilhado/mame/src/devices/bus/technics/kn5000/hdae5000.cpp`.
No driver was modified.

Reproducibility: every count below comes from one of two committed scripts,
each carrying a header that states the question it answers and the exact
command:

* `scripts/analysis/io_address_census.py`  — commit `0bacfc73`
* `scripts/analysis/flash_command_census.py` — commit `3d270feb`

Toolchain at the time of measurement (nothing here depends on the decoder, but
the tree does): `tlcs900_backend @ 6f456a19f05b`.

---

## Part 1 — the five stale driver comments, verified one at a time

Four of the five hold up.  **One is backwards**, and the correction it proposes
would put a retracted theory back into the driver.

### A. `kn7000.cpp:1491-93` — "Only CPL is filled in" + "HLE device still to be written"

**Both halves REFUTED.**  What the code does now:

* `kn7000_cpanel.cpp` declares **22** `PORT_START("CP…")` blocks covering all
  three physical panel boards — CPL segs 0,1,2,3,4,6,7; CPC segs 5,8,9,10,11;
  CPR segs 0..9 (`kn7000_cpanel.cpp:53-242`).  Not "only CPL".
* The HLE device exists and is instantiated: `KN7000_CPANEL(config, m_cpanel)`
  at `kn7000.cpp:2061`, with the ATN line, the RX push and the analog ports
  bound at `:2062-2069`.  The frame parse, LED decode and button/analog scan
  live in `kn7000_cpanel_device` / `kn_cpanel_base_device`.

The one true residue is **CPSD**: no `CPSD_*` ioport exists, and the SD
front-panel board's buttons are not scanned.

**Corrected wording** for `:1490-93`:

> The button names below are transcribed from the CPL schematic; the exact
> SW-row within each SEG column should be double-checked against the print.
> CPL, CPC and CPR are populated (see `kn7000_cpanel_device::device_input_ports`);
> the SD front-panel board (CPSD) is not yet scanned.

Comment-only.  Nothing to verify beyond re-reading the two files.

### B. `:739 / :1404 / :1487 / :2035` "MIDI port 2" vs `:763` "CPSD link" — **REFUTED, and backwards**

The review has this the wrong way round.  The four "MIDI port 2" comments are
**current**; the `:763` block header is the stale one.

What the code does:

* `enum { SIO_PANEL = 0, SIO_MIDI1 = 1, SIO_MIDI2 = 2, SIO_SD = 2 };` (`:747`)
  — `SIO_SD` is an alias left over from the retracted theory.
* Channel 2 is wired to a **real MIDI port pair**: `m_midi_uart[1]` →
  `mdout2` / `mdin2` (`:2040-2058`, ch2 arm at `:2054`).
* `cpsd_queue()`, the CPSD-on-ch2 delivery path, is marked
  `[[maybe_unused]]` (`:1431`) and its declaration says so out loud:
  `// (unused since the ch2=MIDI-2 finding; kept for a future SD transport)` (`:775`).
* The SD card is reached **not** over ch2 but over a byte **mailbox at
  0x9805000C** with an ICR group-0x1C ack (`:1079-1081` dispatch,
  `cpsd_mbx_write` at `:1339`), clocking MAME's `SPI_SDCARD` bit by bit.

The provenance is in the notes, not just the code.  `notes/sd-card-emulation-plan.md`
line 285 is headed *"ch2 was MIDI-2 all along; the REAL gate is a MILK property"*
and line 286 reads *"**ch2 is the MIDI-2 UART, not CPSD**"*, adversarially
confirmed 2026-07-10; line 339 repeats *"ch2 is MIDI-2, leave it plain."*
`notes/panel-serial-protocol.md:20` lists the channel bases as
panel 0x34000800 / MIDI-1 0x34000810 / **MIDI-2 0x34000820**.

The `:763` block is visibly a half-finished edit: line 764 begins
*"The SD card is reached over SIO ch2. Delivery model (RE 2026-07-08): the"* and
stops mid-sentence, and line 765 starts a new sentence over the top of it.

**Corrected wording** — retitle the `:763-775` block, do not touch `:739`,
`:1404`, `:1487` or `:2035`:

> `// --- CPSD (SD sub-CPU MN102H60): NOT on a SIO channel ---------------------`
> The SD path is the byte mailbox at 0x9805000C with the group-0x1C ack (see
> `cpsd_mbx_write`), not SIO ch2 — the 2026-07-08 "CPSD on ch2" reading was
> retracted on 2026-07-10 (`notes/sd-card-emulation-plan.md` §"ch2 was MIDI-2
> all along").  `cpsd_queue()` is the dead remnant of that theory.

If anything here is a code change rather than a comment change, it is deleting
`SIO_SD` and `cpsd_queue()`; that is a judgement call for whoever owns the
driver, not this lane.

### C. `:1508-09` — "volume sliders NOT yet wired" — **CONFIRMED stale, for two of the four**

* `VOL_MAIN` **is** wired: `kn7000.cpp:1450`, `volume_scan()` reads it and calls
  `m_dspbridge->set_master_gain(v * v)`.
* `VOL_APCSEQ` **is** wired: bound at `:371`, handed to the panel device at
  `:2068` / `:2163` (`set_volapcseq_port`), and the base class turns its changes
  into CP-protocol analog frames on wire ADDR 0xD2 — `kn_cpanel.cpp:182-194`.
* `VOL_MIC` and `VOL_LINEIN` have **no reader anywhere**: the only matches in
  the whole `matsushita/` directory are their own `PORT_START` lines.

**Corrected wording** for `:1507-09`:

> Front-panel volume sliders.  MAIN drives the DSP-bridge master gain
> (`volume_scan`); APC/SEQ is sent to the firmware as a CP analog frame on wire
> 0xD2 by the panel device.  MIC and LINE-IN are still placeholders with no
> reader — their control targets are TBD.

Comment-only.

### D. `:1865-66 / :2086 / :2087` — "FDC INTRQ/DRQ not wired / logging stubs" — **CONFIRMED stale**

The handlers are not stubs:

```
void kn7000_state::fdc_irq_w(int state) { if (state) intc_assert(0x18); }
void kn7000_state::fdc_drq_w(int state) { if (state) intc_assert(0x18); }
```

Both raise INTC group 0x18, and the member declarations at `:425-426` already
say so.  The three comments that call them "logging stub" / "not yet wired to
the MN10300" contradict the code beside them.

What is still true is the *second* clause of `:1866`: there is no data-phase
DMA — DRQ raises an interrupt and the transfer, if any, is left to the ISR.

**Corrected wording**:

* `:1865-66` → "The FDC INTRQ and DRQ both raise INTC group 0x18 (`fdc_irq_w`
  / `fdc_drq_w`); the firmware additionally polls MSR for the command and
  result phases.  There is no data-phase DMA engine — DRQ only interrupts."
* `:2086` → `// FDC INTRQ -> INTC group 0x18`
* `:2087` → `// FDC DRQ  -> INTC group 0x18 (no DMA engine; per-byte software transfer)`

Comment-only.

### E. `kn7000_cpanel.h:12` — "40 normalized segments, 230 descriptor button-bits" — **CONFIRMED wrong, and both numbers are unsourced**

* `num_segs()` returns `0x21` = **33** (`kn7000_cpanel.h:51`).
* Of those 33, `seg_wire_addr()` gives a real wire path to **27**: normSeg
  0x00-0x0B → ADDR 0xC0-0xCB, 0x0C-0x15 → 0x00-0x09, 0x16-0x19 → 0xD0-0xD3
  (the analog pots), 0x20 → 0x17 (the tempo encoder).  0x1A is the DATA dial on
  its own path and 0x1B-0x1F are `0xff` = no wire.
* `num_scan_ports()` returns **22** — the button scan columns — declaring
  22 × 8 = **176** `PORT_BIT`s, of which **152** are named and 24 are
  `IPT_UNUSED`.

So neither "40" nor "230" corresponds to anything in the device.  For the
record, `notes/panel-descriptor-map.md:9` — the firmware-side extraction — says
**199** descriptor button-bits over normSeg 0x00-0x23, which matches neither
number either, and implies the device's `num_segs()` of 0x21 stops three
segments short of the firmware's range.  That last point is a real open
question, not a comment fix, and is listed in Part 2 §6.

**Corrected wording**:

> Only the KN7000-SPECIFIC half lives here: the button scan matrix (33
> normalized segments, 22 of them button scan columns carrying 176 declared
> bits) and the three-board LED register decode.

Comment-only.

---

## Part 2 — what the disassembly says that the drivers do not model

Ranked by how much emulation fidelity is at stake.  Findings 1-3 change what the
emulated machine does; 4-6 are latent (they matter once 1-3 are addressed);
7-10 are corrections to the record.

Counts come from `scripts/analysis/port_read_census.py` (commit `0543c32c`),
`io_address_census.py` (`0bacfc73`) and `flash_command_census.py` (`3d270feb`).

---

### 1. ★★★ Main CPU **Port G is never wired**, so the emulated KN5000 has both foot switches and all four foot controllers permanently pressed

`kn5000.cpp:1291-1298` carries a Port G comment block —

```
	// MAINCPU PORT G:
	//   bit 2 (input) = FS1  (Foot Switches and Foot Controler ?)
	//   bit 3 (input) = FS2
	//   bit 4 (input) = FC1 … bit 7 (input) = FC4
```

— and **no `portg_read()` binding whatsoever** (`grep -ac portg kn5000.cpp` = 0).
MAME's core does map the register: `tmp94c241.cpp:908`
`map(0x000040, 0x000040).r(FUNC(tmp94c241_device::port_r<PORT_G>))`, and
`port_r` returns `(m_port_latch[P] & dir) | (external & ~dir)` with
`m_port_read(*this, 0)` — an unbound callback returning **0**.  Port G has no
control register on this part (the SFR table jumps `PG 0x40` → `PH 0x44`), so
`dir` is 0 and the firmware reads **0x00, always**.

The firmware reads it three times per periodic tick.
`v10/maincpu/audio/audio_control_engine.s:1848-1871`, reached from
`Audio_PeriodicUpdate` via `calr MIDI_ProcessVoiceAssignment` (`:1796`):

```
MIDI_ProcessVoiceAssignment:
	ld_sd8b A, 0x40      ; A = (PG)
	and a, 0xc           ; bits 3:2 = FS1/FS2
	srl a, 2
	ld c, a
	ld xwa, 0x8eb6
	calr MIDI_WriteParamByte
	ld_sd8b A, 0x40      ; A = (PG)
	and a, 0xf0          ; bits 7:4 = FC1..FC4
	srl a, 4
	cp a, 0xf            ; ALL FOUR HIGH -> nothing engaged
	jr nz, MIDI_ValidateParam
	stdi16 (0x8ec8), 500 ; ...so arm a 500-count debounce and skip the write
	jr MIDI_WriteSecondByte
MIDI_ValidateParam:
	cpdi16 0x8ec8, 0
	jr nz, MIDI_WriteSecondByte
	lda_d16 xwa, (0x8eba)
	ld_sd8b C, 0x40      ; A = (PG)
	and c, 0xf0
	srl c, 4
	calr MIDI_WriteParamByte
```

The firmware's **own idle test is `upper nibble == 0xF`**, which is what makes
the polarity a fact rather than an inference: these pins are **active LOW**, and
0x00 is the all-four-engaged encoding.  In MAME `a` is 0, the `cp a, 0xf` branch
is never taken, the debounce at `0x8EC8` is never armed, and the firmware writes
the fully-engaged pedal values into its parameter block on every tick.

Note the label `MIDI_ProcessVoiceAssignment` is auto-generated and misleading;
judge the block by the instructions, which are a foot-switch / foot-controller
scan.

**Proposed change**: add an ioport for the pedals and
`m_maincpu->portg_read().set_ioport("PEDALS")`, with the released state = bits
2..7 SET (byte `0xFC`).  If nobody wants the ioport yet, `set_constant(0xFC)` is
strictly better than the present silence.
**Verification**: memory-tap DRAM `0x8EB6` (FS byte), `0x8EBA` (FC byte) and
`0x8EC8` (the debounce counter) over a few seconds of idle running.  Today
`0x8EC8` must stay 0 and `0x8EBA` must be written every tick; after the change,
with no pedal pressed, `0x8EC8` must be armed to 500 and `0x8EBA` must stop
being rewritten.  That before/after pair is the null this claim needs — without
it, "the pedals are wrong" is only a reading of the code.

⚠ Not yet checked: whether anything downstream of `0x8EB6`/`0x8EBA` audibly
changes the sound today.  The defect is certain; its audibility is not, and I
have not run the emulator.

### 2. ★★ The extension slot can hold an HD-AE5000, but Port E bit 0 is hard-coded to "absent"

`v10/maincpu/kn5000_v10_program.s:571-578`, on the **normal boot path**
(`Boot_FlashAndExtensions`):

```
	call Flash_InitAllBanks
	bit_dd8 0, 0x38	;  Is the optional HD-AE5000 board present?
	jr nz, BootInit_SeqAndPanel
	calr Get_Region_Code
	cps l, 4
	call_24 nz, HDAE5000_Parport_Setup
```

SFR `0x38` is **Port E** (`v142/subcpu/shared/sfr_tmp94c241.s:51`).  So
**PE.0 = 1 → skip the board; PE.0 = 0 → the board is fitted**, and the init
additionally requires the region code not to be 4.

The boot programs `PECR = 0x20` (`v10/maincpu/shared/boot_hw_init.s:59`,
`ldio 0x3a, 0x20`), i.e. only PE.5 is an output — **PE.0 is an input**, so
MAME's `port_r` does pass the driver's callback value through for this bit.
`kn5000.cpp:1268-1274` returns `0x01 | (m_cpanel_inta ? 0x20 : 0x00)`; bit 0 is
always 1.

So although the driver instantiates a real extension connector
(`KN5000_EXTENSION(config, m_extension, kn5000_extension_intf, nullptr)`,
`:1527`) and `hdae5000` is a selectable card that installs an ATA interface, a
uPD71055 PPI and 1 MB of SRAM+ROM, **the firmware is told the slot is empty**.
`HDAE5000_Parport_Setup` never runs, the PPI is never programmed, the hard disk
is never probed.  Everything the card provides is mapped and unreachable.

**Proposed change**: give the slot a card-present query (either a
`bool card_present()` on `device_kn5000_extension_interface`, or just test the
connector's card pointer) and make `porte_read` return bit 0 = 0 when a card is
fitted.
**Verification**: run with `-extension hdae5000` and break on the write of
`0x82` to `0x160006` (the PPI mode word, the first thing
`HDAE5000_Parport_Setup` does).  It must be reached with the card and NOT
reached in a no-card control run.  The `AREA` ioport must not select region 4.

### 3. ★★ Three regions the driver maps `.rom()` are really AMD-command-set FLASH, and the identify runs on every boot

`Flash_InitAllBanks` (`v10/maincpu/boot/system_handlers.s:6466`) is called
unconditionally at boot from `kn5000_v10_program.s:571`.  It runs a JEDEC
autoselect on two banks, stores the device IDs at DRAM `0x0205E0` / `0x0205E2`,
and for non-region-4 units also calls `TableDataROM_IdentifyChip`.

`flash_command_census.py`, run over v10, v9 and v7 (identical picture in all
three), finds exactly two families:

| family | base(s) | unlock offsets | command word | array |
|---|---|---|---|---|
| 16-bit | `0x300000` custom_data IC19; `0x280000` HD-AE5000 IC4 | `+0xAAAA` / `+0x5554` = word 0x5555/0x2AAA × **2** | `0x00AA`,`0x0055`,`0x0090`,`0x00A0`,`0x0080`+`0x0030`,`0x0080`+`0x0010`,`0x00F0` | ONE x16 device |
| 32-bit | `0x800000` table_data IC1/IC3 | `+0x15554` / `+0xAAA8` = word 0x5555/0x2AAA × **4** | `0xAA00AA`,`0x550055`,`0x900090`,`0xA000A0`,`0x800080`+`0x300030`,`0x100010` | TWO x16 devices in parallel |

The 32-bit family's identify (`:6698-6716`) compares the manufacturer long
against `0x00010001` / `0x00040004` and the device long at `+4` against
`0x22D622D6` / `0x22582258` — **the same 16-bit ID duplicated per lane**, which
is what proves the array is two x16 parts on a 32-bit bus rather than one wide
part.  Its label in the tree is `HDAE5000_Detect`, which is a **mislabel**: the
routine identifies the table-data array at `0x800000`.

Device IDs accepted (`Flash_IdentifyAndValidateChip:6186-6193`):
`0x2223` Am29F400BT, `0x22AB` Am29F400BB, `0x22D6` Am29F800BT, `0x2258`
Am29F800BB; manufacturer 1 (AMD) or 4 (Fujitsu).

The stored IDs are load-bearing: `:6380` (`cpw_da (0x205e0), 8792` = 0x2258) and
`:6411` (`cpw_da (0x205e2), 8875` = 0x22AB) use them to **choose the boot-block
sector layout for erase**.  A wrong ID erases the wrong sectors.

`kn5000.cpp:631` and `:634` map `custom_data` and `table_data` `.rom()`;
`hdae5000.cpp:card_map` maps `0x280000-0x2fffff` `.rom()`.  So every emulated
boot drops the autoselect writes, reads back ROM contents, fails the compares
and stores `0xFFFF`.  Consequences, increasing in severity:

* The KN5000's **firmware-update path cannot work**.  The floppy updater
  (`:7900-7913`) calls `Flash_BurnWithProgress` on file types the tree names
  *"Technics KN5000 Program DATA FILE"* / *"Technics KN5000 Table DATA FILE"* —
  the mechanism by which a real unit goes from v7 to v10.
* The **HD-AE5000's IC4 is field-programmable** (base `0x280000` is one of the
  two identify banks; `HDAE5000_FlashWrite_BankLoop:8055` and `Flash_ProgramWord`
  target it).  That is why `hdae5000.cpp` carries four `ROM_SYSTEM_BIOS` entries
  v1.10i…v2.06i: those are update outputs MAME cannot reproduce.
* IC19 is **two** devices for region 4: `Flash_ProgramWord:6218-6231` adds
  `0x80000` to the command base when `Get_Region_Code` returns 4 **and** the
  target is `>= 0x380000` — and the sub-CPU payload at `0x3E0000` is in that
  second device.

**Proposed change**: replace the three `.rom()` entries with real flash devices
(`AMD_29F800T`/`AMD_29F800B` class from `machine/intelfsh.h`; two in parallel for
`table_data`, one for `custom_data`, one on the card), backed by a persistent
image — exactly the pattern `kn7000.cpp` already uses for its IC21
(`fujitsu_29lv160b_device` + `customflash_r/w`, `kn7000.cpp:1692-1730`).
**Verification**: memory-tap `0x0205E0`/`0x0205E2` after boot.  A pre-change
control run must show `0xFFFF`; after the change they must hold an accepted
device ID.  Then run an update floppy through `FLASH_MEM_UPDATE` and check the
region contents change.

Honest scoping: nothing on the normal play path reads those two words, so this
does not affect playing the instrument.  It is what stands between the emulator
and running a firmware update, which for this project is a first-class use case.

### 4. ★ The HD-AE5000 PPI has an unbound port B that the firmware spin-waits on

`HDAE5000_Parport_Setup` (`v10/maincpu/boot/system_handlers.s:8345-8361`):

```
	stib_da (0x160006), 0x82   ; PPI control word
	stib_da (0x160000), 0x00   ; PA = 0
	stib_da (0x160004), 0x00   ; PC = 0
	stib_da (0x160004), 0x0f   ; PC = 0x0F
	ld xwa, 0xdbba0 ; calr BusyWait_XWA_Cycles
	stib_da (0x160004), 0x00   ; PC = 0
Parport_WaitDataReady:
	ldb_da a, (0x160002)       ; read PB
	extz wa ; bit 0, wa
	jr nz, Parport_WaitDataReady   ; spin while PB.0 == 1
```

`0x82` decodes as an 8255 mode-set word: mode 0 both groups, **PA output, PB
input, PC output** — precisely how the firmware uses the four registers, and an
independent confirmation that `0x160000-0x160007` is the uPD71055 the card
device already instantiates.  (`io_address_census.py` counts **30** static sites on `0x160000-0x160006` in
  v10, 30 in v9 and 21 in v7 — all of them in `boot/system_handlers.s`.  Command:
  `python3 scripts/analysis/io_address_census.py v10/maincpu --map main | awk '/^0x16000/{gsub(/[RWM]=/,"");s+=$2+$3+$4} END{print s}'`.)

`hdae5000.cpp:device_add_mconfig` leaves every PPI callback commented out.
MAME's `i8255` defaults an unbound input to **0** (`i8255.cpp:223-225`,
`m_in_pb_cb(*this, 0)`), so the loop exits on its first read and the firmware
walks into `Parport_ReadNextByte` — a **PC-to-keyboard file transfer over the
board's DB15 parallel port**, complete with an on-screen progress rectangle
(`VRAM_FillRect` at `:8380`) — reading a phantom stream.  Unreachable today
because of finding 2; fixing finding 2 alone turns a silent absence into a
wrong-data path.

**Proposed change**: bind `in_pb_callback` explicitly to hold PB.0 = 1 ("no data
ready") until a parallel-port peer exists, and record in the device that PB.0 is
the data-ready poll.
**Verification**: with the card fitted and finding 2 applied, the boot must sit
in `Parport_WaitDataReady` and only leave it when PB.0 is driven low.

### 5. ★ PPI port A is a bank register for the card's 0x200000 / 0x280000 windows

Three routines write a block index to PPI **port A** and then walk a 512 KB
window:

* `HDAE5000_ROM_Transfer` (`:8023-8046`) — the tree's comment: *"Transfers data
  in blocks via HDAE5000 PPI at 0x160000 / Block index written to PORT_A for
  each 256KB block"*; the loop is `stb_da (0x160000), w` then `0x3FFFF` word
  iterations.
* `HDAE5000_FlashWrite_BankLoop` (`:8055-8078`) — banks 0..1, `0x40000`
  `Flash_ProgramWord` calls each, source `0x300000`, window `0x200000`.
* `HDAE5000_TableData_BankLoop` (`:8104-8135`) — banks 4..7, `0x20000`
  `Flash_ProgramByte` calls each, source `0x800000`, window `0x280000`.

`hdae5000.cpp` maps `0x200000-0x27ffff` flat `.ram()` and `0x280000-0x2fffff`
flat `.rom()`, with **no banking**, so a two-bank write through one 512 KB
window overwrites itself.

⚠ **Deliberately not proposing a wiring.**  The two loops use different strides
(`0x80000` bytes per bank for the SRAM path, `0x20000` for the table-data path)
and I have not reconciled them; the page granularity should be settled against
the schematic first.  Recorded here as a known gap, not a fix.

### 6. ★ The sub-CPU tone generator has a third port at 0x100004 that is not mapped

`subcpu/boot/kn5000_subcpu_boot.s:2269-2272`:

```
AUDIO_HW_WRITE_READ:
	stw_da (0x100000), xwa   ; latch the register address
	ldw_da xhl, (0x100004)   ; read status/result
	ret
```

and the tree's own note at `:500-507`: the power-on TG liveness probe
(`HARDWARE_CALIBRATION_SEQUENCE`, `:2286`) writes a 34-word voice-parameter
record and then **succeeds when `0x100004` reads back 0**, retrying up to 1000
times and returning `0xFFFF` on failure.

`kn5000.cpp:subcpu_mem` maps `0x100000-0x100003` only, so `0x100004` is
unmapped.  MAME's default unmapped read value is 0, so the probe *accidentally*
passes — the right answer for the wrong reason, which will change the day
anyone sets an unmap value or widens a handler there.

**Proposed change**: map `0x100004-0x100005` to a `kn5000_tonegen_device` status
read returning 0 when idle, with a comment naming this probe.
**Verification**: break at `HARDWARE_CALIBRATION_SEQUENCE__success` — it must be
reached on the first pass, and forcing the new handler to return non-zero must
make the routine return `0xFFFF`.  That forced-failure run is the null this
needs: as things stand an unmapped read and a correct handler are
indistinguishable.

### 7. ★ The sub-CPU's `0x1e0000` "Waveform/sample RAM" map entry has no basis in the firmware

`kn5000.cpp:653`: `map(0x1e0000, 0x1effff).noprw(); // Waveform/sample RAM (stub)`.

Neither sub-CPU image touches `0x1E0000` **on the sub-CPU bus**.  It appears
three times in `v142/subcpu/kn5000_subprogram_v142.s` (`:41815`, `:41991`,
`:42158`), always as

```
	lda_24 xwa, 0x007800
	ldw bc, 0x72AA
	ld xde, 0x1E0000
	call InterCPU_E1_DMA_Transfer
```

— i.e. `0x1E0000` is the **destination in the MAIN CPU's address space**, the
battery-backed IC21 SRAM that `maincpu_mem` maps at exactly `0x1e0000`, handed
as a parameter to the sub→main push over the `0x120000` latch protocol.  The
tree says so itself at `:30263` and `:41811` (*"the main CPU's window"*).

A **precise negative**: the map entry describes a device the firmware gives no
evidence for.  Deleting it changes no behaviour (`noprw()` only suppresses
logging); the value is removing a claim that would otherwise be inherited by
whoever models the sample path.

⚠ Method note, because this nearly went the other way: the direct-addressing
census reported zero **and** a plain `grep -a` for `0x1e0000` in
`v142/subcpu/*.s` also returned nothing (the literal is spelled `0x1E0000`).
Only the census's `--bases` mode found the three sites.  A zero from either
instrument alone would have been wrong.

### 8. Port bits the driver models as constants, where the disassembly changes the story

* **main PE.5 (INTA) — the driver's model can never be read.**  The boot
  programs `PECR = 0x20` (`boot_hw_init.s:59`) and `PE latch = 0x00` (`:57`),
  and MAME's `port_r` is `(latch & CR) | (external & ~CR)` — so bit 5 comes from
  the **latch**, and the `m_cpanel_inta` term in `porte_read` (`kn5000.cpp:1272`)
  is discarded.  The firmware's gate is
  `bit_dd8 5, 0x38 ; jr nz, <timeout>` (`v10/maincpu/ui/cpanel_routines.s:607`
  and `:1118`) — it requires PE.5 **low** to proceed, and the latch gives it that,
  so nothing hangs.  But there is a real contradiction on the record: the driver
  comments PE.5 as an INPUT (INTA) while the firmware programs it as an OUTPUT.
  One of the two is wrong.  **This needs the service-manual schematic or Felipe,
  not more disassembly**, and until it is settled the `m_cpanel_inta` term should
  be commented as presently inert rather than as the panel's interrupt line.
* **main PE.4 (MICSNS) — polled every main loop, driver returns 0 forever.**
  `v10/maincpu/audio/note_voice_mapping.s:26079-26090`
  (`CommPort_StatusCheckAndSend`, called from the main loop at
  `system_handlers.s:1231`) latches PE.4 into a shadow at DRAM `0xE35C` and, on
  a change, sends an 8-byte packet through `SendCOMM_VariableLengthPacket`.
  `porte_read` returns `0x01`, so bit 4 is 0 forever, the compare always matches
  and **that packet is never sent**.  Whether it should be is unknown — MICSNS is
  presumably a microphone-jack sense switch — but the code path is currently
  unreachable by construction.
* **main P7.5 — the constant is correct and load-bearing.**  `set_constant(0x20)`
  (`:1226`).  The disassembly shows this is the **flash ready/busy line, polled
  before every flash command**: `bit_dd8 5, 0x1c` opens `Flash_IdentifyChip`
  (`:6125`), `Flash_ProgramWord` (`:6218`), `Flash_ProgramByte` (`:6742`),
  `TableDataROM_IdentifyChip` (`:6671`), and is the entire body of
  `Flash_CheckReady` (`:6443`).  Four of the six sites are **unbounded spin
  loops** — the only unbounded port poll in the image — so the constant is what
  keeps the machine from wedging at boot and must stay.  If finding 3 is
  implemented, this bit should follow the flash device's ready state instead.
  (Corollary: the label `HDAE5000_Status_Check` at `:6927` is a misnomer — its
  body is the same three instructions as `Flash_CheckReady`.)
* **main PD.6 is consumed by two unrelated subsystems.**  The driver feeds it
  from the floppy's `dskchg_r` (`:1256-1263`), which is corroborated by
  `Check_for_Floppy_Disk_Change` (`fdc_routines.s:2569`) gating `FLASH_MEM_UPDATE`
  at `kn5000_v10_program.s:591`.  But `audio_control_engine.s:1874` reads the
  **same bit** into the pedal parameter block three instructions after the two
  Port G reads of finding 1.  Either PD.6 is genuinely dual-purpose or one of the
  two readings is wrong; as wired today MAME feeds floppy disk-change state into
  a pedal record.  Another one for the schematic.
* **sub-CPU PG.0 is a chip-select strap, not wired.**  `subcpu/boot/
  kn5000_subcpu_boot.s:627` and `:670`: `bit_dd8 0, 0x40` chooses between
  `MAMR3 = 0x1F` / `B3CSH = 0x8A` and an alternative.  334 = 0x14E = MAMR3 and
  333 = 0x14D = B3CSH per the SFR table, so this is a memory-size / board-revision
  strap for chip-select block 3, **not** the "clock configuration" the tree's
  comment claims.  Unwired → 0 → the 0x1F/0x8A path.  Harmless in MAME because
  the address map is fixed by the driver; recorded as a hardware fact.
* **sub-CPU P6.7 (SFR 0x18) is the tone generator's bus qualifier.**  The idiom
  repeats throughout `v142`:

  ```
  	res_dd8 7, 0x18            ; P6.7 = 0 for the ADDRESS cycle
  	stw_da 0x100000, xwa
  	nop
  	set_dd8 7, 0x18            ; P6.7 = 1 for the DATA cycle
  	stiw_da 0x100002, 0xa200
  ```

  (`v142/subcpu/kn5000_subprogram_v142.s:4567-4574`, and 20+ further pairs);
  `ToneGen_Read_Register` (`:2983-2987`) clears it for both the latch and the
  read-back.  The driver decodes TG-vs-keybed purely by address and does not wire
  sub-CPU P6.  Behaviourally equivalent **as long as** the firmware always pairs
  the right P6.7 with the right address — which in these two images it does — so
  this is a documentation gain, not a bug.  It becomes a bug the moment anything
  reads `0x100000` with P6.7 set.

Ports **never read** by either firmware: main P0-P6, P8, PA, PB; sub P0-P8, PA,
PB, PE, PF, PZ.  In particular the driver's comments for **main P8.6 (~WAIT)**
and **main PE.2 (HDDRDY)** describe bits that no firmware in these trees samples.

### 9. `FDC_Send_Command` — the KN5000 firmware never writes 0x110008

`kn5000.cpp:626` maps `0x110008` write to `upd72067_device::auxcmd_w`.  The only
routine that writes there is `FDC_Send_Command`
(`v10/maincpu/storage/fdc_routines.s:33`), and it has **no call site anywhere in
the image**: the callers in the tree are `FDC_Read_Status` (`0x110008` read =
MSR), `FDC_Write_Data` and `FDC_Read_Data` (both `0x11000A` = the FIFO), at
`fdc_routines.s:674, 713, 2426-2464`.  The `auxcmd_w` binding is unexercised.

Stated honestly: "no direct call site" is not "unreachable" — an indirect call
through a table would not show in a label search, and the bytes right after
`FDC_Send_Command`'s `ret` are misdecoded (`.byte 0xc1` then junk), so that
region's framing is not trustworthy.  Treat as "probably dead, worth a comment,
not worth deleting".

### 10. The DSP1 (IC311) register file has a shape the driver's latch does not record

`kn5000.cpp` models `0x130000` / `0x130002` as a 256-entry byte latch with no
behaviour.  The sub-CPU's driver gives the register file a structure:

* `DSP_Write_Channel` (`v142/subcpu/kn5000_subprogram_v142.s:445-459`) computes
  the register number as `channel * 32 + 0x10` and writes **8 consecutive
  registers** per channel, address to `(xhl)` and data to `(xhl + 2)`.
* `DSP_WriteChannelRegs_Inner` (`:487…`) does the same with a different source
  shuffle.
* `DSP_Init_Channels` (`:396-427`) writes the 32-bit value `0x0101001F` to
  `0x130000` **as one store**, incrementing the low byte by `0x20` four times —
  i.e. address `0x1F + channel*0x20`, data `0x0101`, for channels 0..3.

So: **4 channels × 32 registers, config block at `+0x10..0x17`, a per-channel
word at `+0x1F`**, and a 32-bit store writes address and data in one bus cycle.
The driver masks both to 8 bits (`data & 0xff`), silently dropping the high byte
of that `0x0101`.  No audible consequence today because nothing consumes the
latch; worth fixing before anyone models IC311.

⚠ These three routines are invisible to the direct-addressing census: they load
`0x130000` into a register and use register-indirect stores.  That is the blind
spot documented in `io_address_census.py`'s header, and the reason the `--bases`
mode exists.

---

## What I could NOT settle

**The KN7000 floppy `FORMAT` / class-5 disk-task defect.**  The brief asks
whether the now-complete disassembly can say what class-5 dispatch requires.
It cannot, and the reason is a false premise worth stating plainly:

* The class-5 failure is a **KN7000** defect.  Every address in
  `kn7000_mame/notes/fdc-architecture.md` addenda 12-15 is an MN10300 address
  (`0x484ADxxx`, `0x484A1766`, `0x4C03C5AF`).
* The images that reached zero verbatim debt are the **KN5000** ones —
  TLCS-900 main CPU (v10/v9/v7), the v1.42 sub-CPU payload and its update image,
  the sub-CPU boot ROM, table data, custom data, HD-AE5000.
* The KN7000's own firmware disassembly is a different repository
  (`~/compartilhado/kn7000_disassembly`) and its own tooling puts coverage at
  **3.64%** (commit `080d1d7`, *"tools: measure KN7000 source coverage honestly
  (3.64%, not 18.03%)"*).  The class-5 dispatcher is not inside that 3.64%.

The one route that could have worked — the two firmwares descending from a
shared Technics RTOS, so that the KN5000's complete source documents the same
kernel — was put to a dedicated search of the KN5000 tree; its verdict is in the
next section.

