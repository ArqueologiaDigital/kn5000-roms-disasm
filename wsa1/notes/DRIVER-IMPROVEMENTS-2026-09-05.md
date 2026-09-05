# Driver improvements from the disassembly — KN5000 + SX-WSA1R, 2026-09-05

Lane `w29/driver-mining`. **READ-ONLY pass**: nothing in `~/compartilhado/kn7000_mame`
was edited (a build is in progress against the live symlinked source). This file is a
plan to apply after that build lands. It writes only itself.

Drivers read (current tip, verified line-by-line):
`~/compartilhado/kn7000_mame/src/mame/matsushita/{kn5000.cpp, wsa1.cpp,
acoustic_modeling.{h,cpp}, kn5000_cpanel.*, wsa1_cpanel.*}`.
Disassembly read: `~/compartilhado/kn5000-roms-disasm/{v10,v142,subcpu,table_data,wsa1}`
and the driver-facing notes there and in `kn7000_mame/notes/`.

---

## THE HEADLINE, AND IT IS UNCOMFORTABLE

**Both drivers have already absorbed almost the entire completed disassembly, including
BOTH of the examples the task brief cited as "already found this session".**

* WSA1R FDC crystal — `wsa1.cpp:3330` **already** reads `UPD765A(config, m_fdc,
  24'000'000, true, true); // IC8's X5`. The 8 MHz was the old value; the 24 MHz
  (IC8 D72070GF3BE, crystal X5, schematic sheet II-9/II-10) is in place.
* KN5000 FDC Terminal Count — `kn5000.cpp:1391-1394` **already** binds
  `porth_write()` bit 0 → `m_fdc->tc_w()`, and `:1244-1247` documents that the old
  `to0_callback()` wiring (an 8-bit *timer 0* match the firmware never starts) was the
  bug it replaced.

So the two seeds are DONE. They are recorded here only to stop a future pass
re-proposing them. See the "ALREADY DONE — do not re-propose" ledger at the end for the
full list I verified closed (gap T drive motor, gap G P9-ready, gap U FDTC pin, panel
legends, prom_d base 0xF00000, CS1 RAM 0x7FFF, PEDALS port, PE.0 extension-present,
PE.2/PE.5 comments, acoustic_modeling.h's 0x104000→IC3 promotion, and more).

**What remains is genuine residue, and it is short.** The KN5000 driver carries two
findings that materially affect emulation; the WSA1R driver carries almost none that are
not blocked on undumped mask ROMs or on Felipe's hardware. That is the honest result of
a mature codebase, and it is stated first so the list below is read as a small, sharp
set rather than a long one.

Grades: **PROVEN** (firmware/schematic settles it *and* it changes what the emulator
does) / **STRONG** (well-evidenced, lower or latent impact) / **WEAK** (certain but
nothing breaks today — cosmetic or documentation) / **NEEDS-HARDWARE**. Sorted strongest
first within each machine. Every row states the firmware evidence (routine + address),
what the driver does today (file:line, current tip), what to change, and what breaks if
it is not changed.

---

# KN5000 (`kn5000.cpp`)

## K1 — PROVEN — `custom_data`, `table_data` and `program` are AMD-command-set FLASH, mapped `.rom()`

* **Firmware.** `Flash_InitAllBanks` (`v10 boot/system_handlers.s:6466`) is called
  unconditionally at boot (`kn5000_v10_program.s:571`). It runs a JEDEC autoselect on
  two banks and stores the device IDs at DRAM `0x0205E0` / `0x0205E2`. The IDs are
  load-bearing: `:6380` (`cpw_da (0x205e0),0x2258`) and `:6411` (`cpw_da (0x205e2),
  0x22AB`) **choose the erase sector layout**. Accepted IDs
  `0x2223 / 0x22AB / 0x22D6 / 0x2258` (Am29F400/800 T/B), manufacturer AMD(1) or
  Fujitsu(4). Census: `scripts/analysis/flash_command_census.py` (commit `3d270feb`),
  identical in v10/v9/v7. The 32-bit array's identify compares the ID **duplicated per
  lane** (`0x22D622D6`), which proves two x16 parts in parallel on `table_data`.
* **Driver today.** `kn5000.cpp:631` `custom_data` `.rom()`, `:634` `table_data`
  `.rom()` (2 parts, `.mirror(0x200000)`), `:635` `program` `.rom()`. The driver's own
  `:1719` says `// FIXME: These are actually stored in a couple flash rom chips IC6
  (even) and IC4 (odd)`. The subcpu payload lives compressed in the IC19 flash at
  `0x3E0000` (`:633`).
* **What breaks.** Every boot drops the autoselect writes, reads ROM back, fails the
  compares and stores `0xFFFF`. The **firmware-update path cannot work** — the floppy
  updater (`kn5000_v10_program.s:7900-7913`) burns "Technics KN5000 Program/Table DATA
  FILE" images, which is how a real unit goes v7→v10; and the HD-AE5000's IC4 is
  field-programmable (that is why `hdae5000.cpp` carries four `ROM_SYSTEM_BIOS` update
  outputs MAME cannot reproduce). Normal play is unaffected — nothing on the play path
  reads `0x0205E0/0x0205E2` — so this is scoped to firmware-update, which is a
  first-class use case for a preservation project.
* **Change.** Replace the three `.rom()` entries with real flash (`intelfsh.h`:
  `AMD_29F800T`/`_29F800B` class, **two in parallel** for `table_data`, one for
  `custom_data`, and the card's IC4), backed by a persistent image — exactly the pattern
  `kn7000.cpp:1692-1730` already uses for its IC21 (`fujitsu_29lv160b_device` +
  `customflash_r/w`). If done, main P7.5's `set_constant(0x20)` (`:1252`, the flash
  RY/~BY line polled in four unbounded spins) should follow the flash device's ready
  state instead of staying constant.
* **Verify.** Tap `0x0205E0`/`0x0205E2` after boot: pre-change must be `0xFFFF`;
  post-change must hold an accepted ID. Then run an update floppy and confirm region
  contents change. (Source: `notes/DRIVER-INSIGHT-kn5000-2026-09-02.md` §Part-2.3.)

## K2 — PROVEN — a real device at `0x150000` is written every boot and mapped nowhere

* **Firmware.** `AudioMix_Init` (`v10 boot/system_handlers.s:1827-1876`), reached
  unconditionally via `kn5000_v10_program.s:582 → Seq_FullInit → :1800`, writes a
  register-address latch at **`0x150000`** and data at **`0x150002`**: 4 channels × 8
  registers plus four 32-bit combined writes, **~68 stores per boot** (denominator: one
  cold boot of v10; identical in v9 `:1712` and v7 `:1728`). The shape is the exact twin
  of the `0x130000`/`0x130002` block the driver already models on the sub bus, and
  `table_data/boot_cpserial_states.s:931-955` records the same 259-byte library appearing
  three times (table-data bootloader + maincpu at `0x150000`, sub-CPU boot at
  `0x130000`), byte-identical apart from the base immediate.
* **Driver today.** `0x150000` appears **nowhere** in `kn5000.cpp` (grep: 0 hits). It is
  the hole in an otherwise regular IC11 74VHC138 A16-A18 decode the driver already fills
  (`0x110000` FDC, `0x120000` DMA-ack, `0x130000`, `0x140000` latch, `0x160000` PPI,
  `0x170000` VGA).
* **What breaks.** ~68 unmapped-write log lines every boot, and a real
  audio/mixer-adjacent register block whose effect the emulator never applies.
* **Change.** Identify the chip on service-manual p.32 at the IC11 decode, then map it.
  ⚠ Do **not** map it to a `.nopw()` fake — the census note (`kn7000_mame/notes/
  kn5000-port-census-2026-09-03.md` item 2, which calls this "the strongest candidate for
  the next pass") argues that would hide a real gap behind a fake device; the
  unmapped-write log is the honest signal until the part is named. So the actionable step
  is **schematic identification first, then a real handler** — the firmware side is
  settled, the chip identity is not.

## K3 — WEAK — sub-CPU `0x100004` is unmapped; the TG liveness probe passes by accident

* **Firmware.** `AUDIO_HW_WRITE_READ` (`subcpu/boot/kn5000_subcpu_boot.s:2269-2272`)
  writes the register address to `0x100000` and reads status back from **`0x100004`**;
  `HARDWARE_CALIBRATION_SEQUENCE` (`:2286`) succeeds when `0x100004` reads **0**, retries
  1000×, returns `0xFFFF` on failure.
* **Driver today.** `subcpu_mem` maps only `0x100000-0x100003` (`:641-642`); `0x100004`
  is unmapped, so MAME's default 0 read *accidentally* satisfies the probe.
* **What breaks.** Nothing today — but "right answer for the wrong reason": it flips the
  day anyone sets an unmap value or widens a handler there.
* **Change.** Map `0x100004-0x100005` to a `kn5000_tonegen_device` status read returning
  0 when idle, commented as this probe. Verify: forcing it non-zero must make the routine
  return `0xFFFF`.

## K4 — WEAK — sub-CPU `0x1e0000 .noprw()` stub has no firmware basis

* **Firmware.** Neither sub-CPU image accesses `0x1E0000` **on the sub bus**. Its three
  occurrences in `v142/subcpu/kn5000_subprogram_v142.s` (`:41815/:41991/:42158`) are the
  **destination in the MAIN CPU's address space** (the IC21 battery SRAM at `maincpu_mem`
  `0x1e0000`) passed to `InterCPU_E1_DMA_Transfer`; the tree says so at `:30263/:41811`.
  ⚠ Found only via the census `--bases` mode: a plain `grep` and the direct-addressing
  census both returned zero (the literal is `0x1E0000`, wrong case for the pattern) — a
  zero from one instrument is not a fact.
* **Driver today.** `kn5000.cpp:653` `map(0x1e0000,0x1effff).noprw(); // Waveform/sample
  RAM (stub)`.
* **What breaks.** Nothing (`noprw()` only suppresses logging). Value is removing a false
  claim a future sample-path modeller would inherit. Delete the line or re-comment it as
  "no firmware basis".

## K5 — WEAK — DSP1 `0x130000` latch drops the high byte of a 32-bit store

* **Firmware.** `DSP_Init_Channels` writes the 32-bit value `0x0101001F` to `0x130000`
  as **one store** (driver's own comment cites subcpu `0x01FC95`; note `finding 10` cites
  `v142 :396-427`), i.e. address `0x1F + ch*0x20`, data `0x0101`. `DSP_Write_Channel`
  writes 8 consecutive registers per channel (`channel*32 + 0x10`).
* **Driver today.** `dsp_reg_data_w` (`:717`) does `m_dsp_regs[m_dsp_reg_addr] = data &
  0xff`, silently dropping the `0x01` high byte of `0x0101`. The whole DSP1 core is a
  disabled draft (`KN5000_ENABLE_DSP1=0`).
* **What breaks.** Nothing today — no consumer. Worth widening the shadow to 16 bits
  before anyone models IC311. ⚠ Register-indirect access; invisible to an operand census
  (use `io_address_census.py --bases`).

## K6 — WEAK — sub-CPU `0x110002` is mapped read-only but the boot writes it once

* **Firmware.** `INIT_MEMORY_TEST__no_error` (boot ROM) does `stiw_da (0x110002),
  0x0003`.
* **Driver today.** `:644` maps `0x110002-0x110003` `.r(...)` only (kbd status).
* **What breaks.** The one boot write is dropped/logged. Cosmetic. Add a write side or a
  comment.

## K7 — WEAK (comment / type-6) — main P8.6 `~WAIT` comment describes a bit nothing reads

* **Firmware.** Census (`kn5000-port-census-2026-09-03.md` §8): no firmware in v10/v9/v7
  samples P8.6.
* **Driver today.** `:1256` `// bit 6 (~WAIT pin) (input): Something involving VGA.RDY,
  FDC.DMAACK`. The comment asserts a read that does not happen.
* **Change.** Note that no firmware samples it. Comment-only.

---

# SX-WSA1R (`wsa1.cpp`)

The WSA1R driver is the more complete of the two. Its own `TODO` block (`wsa1.cpp:269-297`)
is an accurate statement of what is left, and every item there is either blocked on
undumped mask ROMs or is a deliberate refusal. The findings below are what a fresh pass
adds or sharpens.

## W1 — STRONG (low urgency; already in the driver's TODO) — the three µPD6383GF DSPs have no device, and their upload goes nowhere

* **Firmware.** CPU 2 uploads a fully-specified byte stream to three DSP destinations
  over P7 (data) + P5/P2/PB (strobes), polling P9.3 for READY at 18 sites
  (`prom_c 0xF9A19F…0xF9A600`). The host-side protocol is completely decoded — command
  set `{0x01 set-write-pointer, 0x02 24-bit-coefficient, 0x03 end}`, 5-byte instruction
  words to a 384-word I-RAM, +1 auto-increment, a 7-bit destination tag — see
  `notes/DRIVER-INSIGHT-dsp-2026-09-02.md` §9 ("what a device could honestly be written
  for today").
* **Driver today.** No device; `wsa1.cpp:269-297` TODO already records "the three
  D6383GF-3BA DSPs (IC5, IC6, IC30) have no MAME device… their host bus is fully mapped…
  so the byte stream CPU 2 uploads to them is visible and goes nowhere."
* **What breaks.** Little, now. The 70-second boot stall that used to motivate this is
  **already gone** — `cpu2_p9_r()` (`:1049`) returns `0x09` (bit 3 DSPRDY set), so READY
  is answered. A `upd6383gf_device` would only make the traffic *inspectable* and give
  the instruction-set work a live target; it **would produce no audio** (instruction set
  13.4% decoded, control registers unmapped, wave mask ROMs undumped) and its header
  should say so. So this is a future/optional device, not a fidelity fix.
* ⚠ Do NOT fold in IC310 (the KN5000's second DSP, an MN19413): different chip, transport,
  word widths.

## W2 — WEAK / needs re-measurement — the link "receiver-busy" keybed→tonegen path (old gap C)

* **Status.** `WSA1-EMULATION-DISASM-GAPS.md` gap C reported (PRIORITY 1) that CPU 1
  stops releasing the link's receiver-busy line after CPU 2's first packet, dropping the
  keybed's note-on triples. **But that measurement was taken with the 16×-slow prescaler
  that has since been fixed** (appendix item 2), and the note flags in bold that "nothing
  here should be quoted until the script is re-run." The 500/2500-tick deadlines it raced
  are now 1.02 s / 5.12 s, a 16× change that can turn a timeout race either way.
* **Driver today.** The receiver-busy lines are modelled (`wsa1.cpp:906` SSTAT1 = CPU 2's
  busy, `:939` MSTAT1 = CPU 1's busy), and the driver keeps a one-byte INT0 latch model.
* **What to do.** Re-run `notes/wsa1-probes/wsa1_link_handshake.lua` against the current
  timer model **before** proposing any change. This is on the list so it is not forgotten,
  not because a defect is confirmed — it may already be resolved by the timer fix. Grade
  WEAK precisely because the only measurement on file is now invalid.

## W3 — NEEDS-HARDWARE — the L7A1429 (IC3) register meanings

* IC3 = L7A1429 is now schematic-settled (IC27 `1Y1 = WFICS` → IC3 `NSGCE`; the driver's
  `acoustic_modeling.h` already cites it and feeds IC4). The 64-channel × 19-block
  register file is fully mapped and the driver holds it (`acoustic_modeling.cpp`), but
  **no register meaning is derivable**: 2,642 writes / **0 reads** in 45 s (denominator:
  a full bus trace, `tools/rigs/wsa1_dev104_bus_trace.lua`), no readback to calibrate
  against, no KN5000 sibling to borrow from, and the wave DRAMs/mask ROMs are undumped.
  Settling it needs a per-block sweep on Felipe's hardware with a fixed note/tone. **Do
  not model around this** — WSA1R audio is blocked at the undumped mask ROMs regardless.

---

# NEEDS-HARDWARE (both machines) — legitimate outcomes, not failures

These need the instrument, not more disassembly. The KN5000 ones already sit in the
parked queue (`kn7000_mame/notes/kn5000-port-census-2026-09-03.md` "Questions for Felipe"
and `HARDWARE-QUESTIONS-PENDING-FELIPE.md`); listed here only so this plan is complete —
**do not duplicate them into the parked queue.**

* **KN5000 PD.6 polarity** — read as the floppy disk-change line (`fdc_routines.s:2405/
  2478`) *and* into the pedal parameter block (`audio_control_engine.s:1869`). The driver
  inverts `dskchg_r()` (`kn5000.cpp:1286`); under a "/DSKCHG" reading the inversion is
  wrong, under any other reading of net FD.I/O it may be right by accident. Flipping it
  changes a boot path, so it must not be resolved on a routine name. Needs the FDD
  connector sheet or Felipe.
* **KN5000 PE.4 (MICSNS)** — `CommPort_StatusCheckAndSend` sends an 8-byte packet on a
  change of PE.4; the driver returns 0 so it never fires. Needs a modelled mic / Felipe's
  answer on the front-jack behaviour.
* **KN5000 sub-CPU SC1** — a complete UART driver pointed at nothing (likely the CN12
  check terminal); needs both the `tmp94c241` 8-bit-UART core feature and an endpoint.
* **WSA1R P9.3 READY timing** — the driver returns a constant ready; whether the real
  line falls, and for how long, is unmeasured (logic-probe capture).
* **WSA1R panel SC1 command semantics (gap P), keybed status value 2 (gap I), P8 bit 2
  transport switch (gap K), DATA-dial 0xD7 encoding (gap Q)** — all modelled with
  documented inferences; settling any needs the panel MCU dump, the FDD/panel connector
  sheets, or Felipe.

---

# ALREADY DONE — verified closed against the current tip, do NOT re-propose

Checked against `kn5000.cpp` / `wsa1.cpp` at this session's tip:

**Both seeds from the brief:** WSA1R FDC crystal 24 MHz (`wsa1.cpp:3330`); KN5000 FDC TC
= Port H bit 0, not the never-started timer 0 (`kn5000.cpp:1391-1394`, history at
`:1244-1247`).

**WSA1R:** gap T PA-bit-3 drive motor active-low, schematic-settled (`cpu1_pa_w`
`:1519-1521`); gap U PB-bit-3 = net FDTC / IC1 pin 39 confirmed (`:1475` + comment); gap G
P9.3 DSP-ready answered (`cpu2_p9_r` `:1049` returns 0x09); gap W `0x7B0004` write = DSR /
data-rate select (`fdc_ctrl_w`, comment `:2711`); gap E control panel HLE'd; gap F
`tg_status_r` modelled (`:2127`, not a stub); gap O panel button **legends** attached (89
`PORT_NAME` "rack: …" entries in `wsa1_cpanel.cpp`); gap J `0x7E0008` identified as the
ATA hard disk and comment rewritten (`:280`, `:2771-2784`) — kept `.noprw()` on the data
register **deliberately**, leaving the rest of the task file unmapped so it logs (so a
"widen the map" proposal is contrary to the driver's stated design); prom_d base corrected
to `0xF00000` on CPU 2 (`:2801/:2958/:2976`); CS1 static RAM widened to `0x007FFF`
(`:2627`); `acoustic_modeling.h` promotes `0x104000`→IC3 from "firmware cannot show" to
schematic-cited; IC1=MAIN/IC2=SUB from the schematic; IC4 tone-generator 33.869 MHz /
44.1 kHz recorded; interrupt map (INT0/INT5/INT6/INT7/INTTC0/…) wired; tmp95c061 overlay
fixes (INTNEST 0x3C, timer prescaler taps, INT6/INT7 lines, SC1 serial).

**KN5000:** Port G pedals wired with released-state `0xFC` (`PEDALS` port, `portg_read`
`:1355`); PE.0 extension-present now `get_card_device() ? 0x00 : 0x01` (`porte_read`
`:1325-1326`); PE.2 HDDRDY comment corrected to "output, firmware never reads it"
(`:1292`); PE.5 INTA direction settled from `PECR=0x46` (`:1303`); INT9 extension IRQ
noted dead; µITRON kernel identified; ERROR-08 shown to be a catch-all default (relevant
to the KN7000 investigation, not this driver).

---

## Summary counts

| machine | PROVEN | STRONG | WEAK | NEEDS-HARDWARE |
|---|---:|---:|---:|---:|
| KN5000 | 2 (K1, K2) | 0 | 5 (K3-K7) | 3 (PD.6, MICSNS, sub-SC1) |
| SX-WSA1R | 0 | 1 (W1) | 1 (W2) | ~5 (W3 + panel SC1 / keybed-status-2 / P8.2 / 0xD7 / P9.3-timing) |

Only two proposals materially change what the emulator does today, both KN5000: **K1**
(flash) and **K2** (`0x150000`). The next-strongest is **W1** (a WSA1R DSP transport
device), which is well-evidenced but low-urgency because the boot stall it once fixed is
already gone. No WSA1R read handler returns an undocumented divergent constant — the
three return-constant sites (`wsa1.cpp:1049`, `:2215`, `:2290`) are all deliberate and
documented.

## Reproducibility / provenance

No number here was newly measured; each is cited to a committed disassembly script or note:
`scripts/analysis/flash_command_census.py` (`3d270feb`), `io_address_census.py`
(`0bacfc73`), `port_read_census.py` (`0543c32c`) in the KN5000 tree; `notes/vector_map.py`,
`tools/rigs/wsa1_dev104_bus_trace.lua`, `notes/wsa1-probes/wsa1_sch_cpu_ports.sh` and
`tools/kn5000-io-census/` for the WSA1R/schematic figures. Driver line numbers are the
current tip and will drift once the in-progress build's edits land — re-anchor by symbol
(handler name) before applying, per the "a pin column is an ordered join" lesson in
`DRIVER-INSIGHT-wsa1-2026-09-02.md`.

LLVM: tlcs900_backend@86332721969d (86332721969de2d2b4c2ac16bc217b5cdee5cca5)
