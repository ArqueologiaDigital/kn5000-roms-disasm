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
findings that materially affect emulation; the WSA1R driver carries one firmware-answerable
item with a behavioural stake (W1, the voice-pool busy bit) and otherwise little that is
not blocked on undumped mask ROMs or on Felipe's hardware. That is the honest result of a
mature codebase, and it is stated first so the list below is read as a small, sharp set
rather than a long one.

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

## W1 — STRONG — decode `0xFA62DA` and `0xFA643F` so the tone-generator busy bit can fall (voice-pool exhaustion risk)

> **✅ RESOLVED 2026-09-05 (steal-vs-refuse): the allocator STEALS; the fake is
> benign for polyphony.** The two "undecoded" routines are decoded (wave 17):
> `0xFA62DA` = `ChanRec_RelinkToPoolQueue`, `0xFA643F` = `ChanRec_RelinkToPartQueue`
> — the doubly-linked-queue relink helpers, not the allocator. The allocator is
> `ChanAlloc_ForNoteRequest` → `ChanAlloc_FindVictim` (`0xFA69FD`), which walks
> the per-part priority list at `0xFE1220` (records point at
> `Voice_Search_Order_List_1..3`, e.g. `86 85 06 05 84 83 82 04 03 02 81 80 01 00 FF`
> — bit 7 = shared-pool queue, low 3 bits = queue number: **release/idle queues
> first, the part's SOUNDING queue 0 last**) and takes the first non-empty queue.
> It returns `0xFF` (silent) only if *every* queue including sounding is empty.
> So the pool never replenishing does NOT refuse note-ons — it steals a sounding
> voice. `tg_status_r`'s `0x1000` fake is benign for allocation; a faithful
> retire and a true magnitude still need synthesis (gap A, blocked on the
> undumped mask ROMs). Landed in `kn7000_mame` `4633537` (driver comment). The
> separate, still-open item is premature retirement if the device busy bitmap
> ever reads 0 — see `note_engine.s` §RETIRE; the driver keeps `m_tg_busy` set
> to avoid it.


* **Firmware / driver.** `tg_status_r()` (`wsa1.cpp:2199`) answers the per-channel
  magnitude query with a hard-coded `0x1000` and self-labels it (`:2175`) "THE ONE FAKE
  IN THIS HANDLER". The deeper problem is stated at `:2202-2213`: **the tone-generator
  busy bit never falls by itself.** It clears only when the firmware writes `0x7E00`
  (via `Dev10C_ChanReset`), and that is called ONLY from the retire path, which is itself
  driven by the bit falling — a loop real hardware breaks because the chip decides when a
  voice ends. `ChanRec_Release` has two call sites (`0xFA6892` all-64-at-boot, `0xFA6989`
  the poll), so **between one `VoiceSubsystem_Init` and the next, no channel record
  returns to the pool.**
* **The disassembly gap.** Whether the allocator then STEALS a voice or REFUSES is **NOT
  established** — the driver comment names `0xFA62DA` and `0xFA643F` as **undecoded**, and
  "both are exactly the routines that could re-link a record". These are firmware
  addresses in prom_c; decoding them is a firmware-only job (no hardware needed).
* **What breaks / what to settle.** If the allocator REFUSES when the pool is empty, the
  emulated WSA1R would stop sounding new notes after 64 note-ons until the next re-init —
  a real, observable polyphony bug hiding behind the fake. If it STEALS, the current model
  is benign. **Decode the two routines to find out which**; that decides whether
  `tg_status_r` needs a real retire model or the fake is harmless. This is the strongest
  WSA1R item because it is firmware-answerable and has a concrete behavioural stake — full
  closure (a true magnitude) still needs synthesis (gap A, blocked on the undumped mask
  ROMs), but the steal-vs-refuse question does not.
* Source: `wsa1.cpp:2170-2213` (the driver's own reading); `notes/FINDINGS-prom_c-voice-
  readback.md`, `FINDINGS-prom_c-dev10c-producers.md`.

## W2 — STRONG (low urgency; already in the driver's TODO) — the three µPD6383GF DSPs have no device, and their upload goes nowhere

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

## W3 — WEAK / needs re-measurement — the link "receiver-busy" keybed→tonegen path (old gap C)

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

## W4 — WEAK — keybed status word value 2 is never produced, and its meaning is undecoded

* **Firmware.** `KeyScan_ReadEvent` compares the keybed status word against **2** at
  `prom_c 0xF9979A` and treats it like a touch byte of `0xFF` (note-on dropped,
  `(0x008517) |= 3`; note-off velocity forced to 0). `0x008517` has exactly one literal
  reference in the image (the `or` that sets it), so its reader is through a pointer.
* **Driver today.** `keybed_status_r()` returns only 0/1 (`wsa1.cpp:2276`); the comment
  `:2235` states "what value 2 MEANS is NOT ESTABLISHED, so this model never produces it".
* **What breaks.** Nothing today — but if 2 is "queue overflow"/"scan error", a real
  machine reaches a path the emulator never can. Disassembly-answerable (find the reader of
  `0x008517`); listed WEAK because the current model is safe. See
  `notes/FINDINGS-prom_c-keyboard-and-touch.md` §3.

## W5 — NEEDS-HARDWARE — the L7A1429 (IC3) register meanings

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
| SX-WSA1R | 0 | 2 (W1, W2) | 2 (W3, W4) | ~4 (W5 + panel SC1 / P8.2 / 0xD7 / P9.3-timing) |

The proposals that could most change what the emulator does today: **K1** (KN5000 flash,
firmware-update path), **K2** (KN5000 `0x150000`, a real device mapped nowhere), and
**W1** (WSA1R — decode two named routines to learn whether the voice pool exhausts,
because the tone-generator busy bit never falls in the model). **W1 is the one WSA1R item
that is both firmware-answerable and carries a behavioural stake**; the DSP transport
device (W2) is well-evidenced but low-urgency because the boot stall it once fixed is
already gone. No WSA1R read handler returns an *undocumented* divergent constant — the
three return-constant sites (`wsa1.cpp:1049`, `:2199`, `:2215`) are each labelled and
justified in the code (the `0x1000` at `:2199` is W1's "one fake").

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


## ADJUDICATED 2026-09-05 — the prom_d `0xE80000` "drift" is a FALSE ALARM

The out-of-scope drift note (prom_d's linker "still carries 0xE80000" vs the driver's
0xF00000) does not hold. Verified: prom_d's linker uses **ORIGIN 0 by deliberate decision**
(its own header: "ORIGIN STAYS 0, AND THAT IS NOW A DECISION RATHER THAN AN ADMISSION"), and
only *mentions* 0xE80000 to explain it is a **different, smaller flash on CS2**, not prom_d's
base. The driver's `PROMDCS = 0xF00000` (wsa1.cpp) and the linker's ORIGIN 0 describe different
things -- a chip-select address vs a position-independent data image -- and agree with
FINDINGS-memory-map.md F4. ⚠ Do NOT relink prom_d at 0xF00000: it would relabel ~32,000 source
lines for zero gain and put the byte gate at risk. No action.


## APPLIED 2026-09-05 — what actually landed, and two refinements the firmware forced

Committed to the overlay (`kn7000_mame` main) and published; all three machines validate and
boot byte-identically to the pre-change baseline (only the flash ID differs, as intended).

* **K2, K4, K7 — landed** in `5376e62`. K2: `0x150000/0x150002` mapped as a labelled logging
  register file (68 writes/boot captured, no effect synthesised; chip ID still needs manual
  p.32). K4/K7: the two contradicted comments corrected.
* **K1 — landed in `0d02d16`, but custom_data ONLY**, not all three ROMs the plan named.
  Verified behavioural win: KN5000 flash autoselect now returns `0x0205E0 = 2258`
  (`AMD_29F800B_16BIT`) where it read `0xFFFF` before. Re-derivable:
  `tools/rigs/kn5000_flash_id_tap.lua`.

⚠ TWO PLACES THIS PLAN WAS WRONG, corrected in the code and here:
  1. **K1's scope was overstated.** Only **custom_data (bank 1, 0x300000)** has a
     boot-consumed JEDEC ID. `program (0xE00000)` is never put in command mode by resident
     firmware (0 command hits in v10; the updater at 0xEF3740 uses only 0x280000/0x300000/
     0x380000), and `table_data (0x800000)`'s autoselect result is READ AND DISCARDED by
     `Flash_InitAllBanks`. Converting either adds regression risk for zero boot-consumed
     benefit, so they were deliberately left as `.rom()`. Do NOT 'finish' K1 on them.
  2. **K7's citation was wrong** — it pointed at census '§8', which is Sub-CPU P6.7, not the
     main P8.6. The claim holds; the code comment now cites `rom_bitop_census.py --all-bits P8`.

## ✅ PLACEHOLDER SINE shipped 2026-09-05 (gap A stand-in, like the KN5000)

While the six wave mask ROMs stay undumped, the WSA1R tone generator (IC4) now
has a placeholder sine backend, the same stand-in the KN5000 uses
(kn5000_tonegen.cpp RENDER_SINE): `kn7000_mame` `685c64a`, new
`wsa1_tonegen_device` (a real MAME sound device on a stereo speaker). It renders
one sine per gated voice, driven ONLY by the real 0x0010C000 writes the driver
already decodes -- PITCH `chan+0x0400` (1/256 semitone) and the block-0 gate
latch (0x8100/0x7E00) -- with a fixed per-voice level (0x0080's pin sense is not
established) and click-free gate ramps. A `:TGSINE` toggle (default on) mutes it.

Verified with `tools/rigs/wsa1_tg_sine_test.lua` + `-wavwrite`: gating an
A-major triad through the port renders exactly 440/554/659 Hz and nothing else,
and the no-gate null is silent from 2.0 s. It is drop-in replaceable by a real
IC4 model behind the same two hooks once the ROMs are dumped.

⚠ It is silent in normal use for a reason OUTSIDE this backend: no musical note
reaches the TG yet (the CPU2->CPU1 link wedges; a brief boot-init transient
aside, the firmware gates no musical voice on its own). Making a note reach the
TG -- the link, or a MIDI-in path into prom_c's ring -- is the next step toward
hearing it play without an injected gate.

## ✅ ENVELOPE + LINK + MIDI-IN, 2026-09-06

Following the placeholder sine, three more landed in `kn7000_mame`:

* **Amplitude envelope.** The sine is no longer fixed-level. Each voice's
  amplitude follows the OUTPUT LEVEL register (`chan+0x0080`, base-2 log, 256
  counts/octave, `0x0FF4`=unity, larger=louder) and a channel in its idle marker
  (`chan+0x0800`==0xFF80 && `chan+0x0840`==0xFF00) is silent. Verified: a unity
  A4, an idle-marked C#5 (silent), and a −2-octave E5 rendered at 2949 / 2.5 / 740
  (idle 0.0008×, −2oct 0.2507× ≈ 0.25). The boot-init transient is now silent.
* **Link wedge — confirmed already fixed** (OVERLAY FIX 6 in tmp95c061 +
  `perfect_quantum`, 2026-08-27). Verified end to end below.
* **MIDI IN wired.** tmp95c061 gained an SC0 receive engine (`sc0_rxd` →
  `INTRX0`); `wsa1_midi_uart` bridges MAME's bit-serial `midiin` to CPU 1's SC0
  (rear MIDI1 jack). **End-to-end verified**: a `.mid` file fed to `-midiin`
  (MAME's midiin is a MIDI-in *image* device — plays a file, no host port
  needed) is silent through boot and sounds from ~t=25 s. So the whole chain
  works: MIDI → SC0 → link → CPU 2 note engine → tone generator → placeholder
  sine. Machine flag is now `MACHINE_IMPERFECT_SOUND`.

✅ **Note-off / retirement — CLOSED (2026-09-06).** A released voice now
retires through the firmware's own path. The mechanism (RE'd this session):
there is **no note-off gate bit**; on note-off the retire walk
(`MidiNote_Dispatch` velocity-0 arm → `VoiceList_RetireByMode` →
`Voice_Retire_Mode20` 0xFB3D26) re-stages the amplitude envelope with a RELEASE
profile via `Dev10C_WriteSixChanRegs_FromD78A` (0xFB7345), writing
`chan+{0x0800,0x0840,0x0900,0x0940,0x09C0,0x0A00}` but **not** `chan+0x0A40` —
whose only writer is the note-on burst `Dev10C_WriteAllChanRegs` (its last
register; order `...0x0A00` then `0x0A40` measured at 0xFB7278/0xFB728B). The
driver keys on that single asymmetry: `0x0A40` ends a note-on burst, so a later
`0x0A00` write on a still-gated channel is the release. The placeholder voice
decays (fixed placeholder ramp; the real segment rate/level is still not
established), and when it reaches silence the driver drops the busy bit in
`tg_status_r` QUERY 1 — so the firmware's own poll writes `0x7E00` (FREE) via
`Dev10C_ChanReset`, exactly as the chip's decaying busy bit makes it on
hardware. No `0x7E00` is fabricated. **Verified** with
`kn7000_mame/tools/rigs/wsa1_wav_rms.py` on `note_long.mid`: before, a monotonic
drone to full-scale clipping (32767); after, voices retire (peak 1949, the
passage ends in silence).

`MidiNote_OffTail` (0xFB374A) is a byte-for-byte re-stage of the note-on writes
and is inert on a genuine note-off — the release is the retire walk, which runs
*before* it in the dispatch arm. Full trace in the session's note-off RE.

✅ **MIDI OUT — wired (2026-09-06).** `tmp95c061` gained an SC0 transmit
callback (`sc0_txd`, called from `sc0buf_w`, which previously only faked
send-complete); the `wsa1_midi_uart` now shifts those bytes out (byte→bits,
31250 baud) to a `midiout` port. The machine transmits what the firmware sends
(bulk/group SysEx dumps, GM). This is also the carrier for a live parameter
mirror (see the sysex-messages live-sync analysis on the docs site).

**Related, same session — WSA1R DSP ISA cross-validation.** The WSA1R's three
uPD6383GF DSPs run the *same* ISA as KN5000 IC311; running the KN5000 model over
the WSA1R microcode confirms the ISA and populates the KN5000's undecidable
hapaxes. See `FINDINGS-dsp-isa-crossval.md` and
`dsp/analysis/wsa1_dsp_isa_crossval.py`.
