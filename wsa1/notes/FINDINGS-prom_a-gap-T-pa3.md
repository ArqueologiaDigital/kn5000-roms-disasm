# Emulation gap T: what the firmware DOES with CPU 1's PA bit 3

Wave 6 round 2, 2026-08-25. **This note exists because the previous one was
wrong**, and wrong in the direction that costs the emulation lane the most time:
`notes/FINDINGS-prom_a-disk-format.md` §4 shipped *"nothing in this firmware ever
changes it … gap T is now a hardware question, not a disassembly one."* It is not
a hardware question. The firmware drives the pin on every block-device
operation. §4 now carries the retraction; this note carries the answer.

Every number below is re-derived from the ROM images and from the gate-verified
source by `python3 notes/prom_a_pa3_census.py` — **19 checks, 0 failures**. The
byte gate (`python3 scripts/analysis/assert_byte_identical.py`) proves the source
rebuilds these exact ROMs and is blind to every sentence here.

---

## 1. The whole port, at the granularity the claim is made at

`0x1E` is PA (`include/tmp95c061_sfr.inc`; MAME `tmp95c061.cpp:128` maps it,
`:1363` names it). The census scans **every byte offset of prom_a and prom_b**
for the two-byte prefix `<g> 1E` with g in {0xC0, 0xD0, 0xE0, 0xF0} — the four
TLCS-900 memory-operand groups in 8-bit-absolute addressing mode; 0xF0 is the
group that writes. 101 byte hits; filtered against the converted source's own
instruction boundaries, **six are instructions and four of those are writes**:

| addr | instruction | which bit | what follows |
|---|---|---|---|
| 0xFE18EF | `res 3,(0x1E)` | 3 | `calr Delay_150Ticks` — **307 ms** |
| 0xFE18F7 | `set 3,(0x1E)` | 3 | nothing; returns |
| 0xFE660D | `ld (0x1E),A` after `and A,0xF7` | 3 | `Fdc_DelayTicks(5)` — **10 ms** |
| 0xFE6631 | `ld (0x1E),A` after `or A,0x08` | 3 | `ret` |

★ **Bit 3 is the only bit of PA this firmware ever changes after RESET.** Two of
those four instructions are new: 0xFE18EF and 0xFE18F7 are in the block-device
layer at 0xFE0000-0xFE54B5, one level above the FDC module, and they were missed
because the earlier scan looked for `f0 1e 41` only.

⚠ **What is still not excluded**, and no static scan can exclude it: a write to
PA through a register pointer. What IS excluded is a write through a 16- or
24-bit spelling of `0x00001E` — `python3 notes/prom_a_addr_census.py 0x00001E`
runs all twelve direct spellings and every additional hit is either 0/64 on the
convergence test or lands inside emitted font `.byte` data (0xF205FB and
0xF20667 in prom_b are the two that look believable and are both inside emitted
font bitmaps — prom_b source lines 21906 and 21909, whose `.byte` rows cover
0xF205F0-0xF2060F and 0xF20650-0xF2066F).

## 2. The two directions are not symmetric, and that fixes the polarity

```
Disk_PortA3_ClearAndSettle   (0xFE18E9)      Disk_PortA3_Release  (0xFE18F7)
    Delay_Ticks(5)     ~10 ms                     set 3,(PA)
    res 3,(PA)                                    if (0x2076) != 0x0D:
    Delay_150Ticks    ~307 ms                         (0x2244) := 0xFF
    ret                                           ret
```

and the FDC module's own dead API has the same asymmetry:

```
Fdc_Op6_PortA3_Off  (0xFE65EF)                Fdc_Op7_PortA3_On  (0xFE661F)
    ld A,(PA) / and A,0xF7 / ld (PA),A            ld A,(PA) / or A,0x08 / ld (PA),A
    Fdc_DelayTicks(0x0A)  = 5 ticks ~10 ms        ret
    ret
```

**Clearing is followed by a wait; setting never is.** Waiting is what asserting
needs and releasing does not, in both layers independently. And RESET agrees:
0xF826D6 `ldio PA,0xF9` with `PAFC = 0x00`, `PACR = 0x0E` leaves PA1-PA3 driven
and **bit 3 HIGH** (PACR is the output enable — MAME masks the driven value with
it at `tmp95c061.cpp:107`). A machine at rest sits in the SET state.

★ So **PA bit 3 is an ACTIVE-LOW output**, released at reset. That single
sentence is what the earlier note's "an active-high motor enable would be
asserted from power-on, which is not how a floppy drive is driven" was groping
for, and it dissolves the objection: the assertion is LOW.

**The unit of the wait.** `Delay_Ticks` (0xFE1421) spins until the free-running
counter at `(0x0080)` has advanced by its stack argument. `(0x0080)` is what
`INTT1_Tick` increments (0xF82D11 `add (0x80),XHL` with XHL = 1) and that timer
runs at **488.28 Hz** (`notes/FINDINGS-system-clock.md`), so one unit is 2.048
ms: 5 → 10.2 ms, 150 → **307 ms**, 500 → 1.02 s. The FDC module's
`Fdc_DelayTicks` counts the same tick through its own copy `(0x605A00)`, which
the same interrupt increments, and halves its argument.
⚠ `Delay_Ticks` has NO timeout, unlike `Fdc_DelayTicks`, which caps its spin at
0xFFFF iterations.

## 3. Where the 15 call sites are, and what they bracket

| routine | direction | sites |
|---|---|---|
| `Disk_PortA3_ClearAndSettle` (0xFE18E9) | clear = **assert** | 3: 0xFE08C5, 0xFE09F1, 0xFE199D |
| `Disk_PortA3_Release` (0xFE18F7) | set = **release** | 12: 0xFE0552, 0xFE0589, 0xFE095F, 0xFE09EE, 0xFE0A90, 0xFE11F1, 0xFE14C3, 0xFE15D5, 0xFE15E0, 0xFE15E5, 0xFE168B, 0xFE1CC4 |

All 15 are `calr`, all 15 are inside 0xFE0000-0xFE54B5, and the shape is the one
a per-operation line has:

* **the asserts are at the head of a routine.** 0xFE08C5 is 4 instructions into
  `Disk_MountFloppyWithRetry`, 0xFE199D is 2 into the routine at 0xFE1997.
* **eleven of the twelve releases are on an exit path** — the linear stream from
  the call reaches a `ret` within 12 instructions and issues no disk request on
  the way. 0xFE1CC4 is a bare `calr Disk_PortA3_Release / ret` veneer.
* ⚠ **the twelfth release is not an exit, and the first draft of the census
  asserted it was and failed.** 0xFE09EE is immediately followed by 0xFE09F1,
  which asserts: `sub_FE09BE` **cycles** the line, release then assert, 20
  instructions into its own body. That is exactly what a driver does to a motor
  it is not sure of the state of.

**And the asserting side really is disk traffic.** A breadth-first search over
`calr`/`call`/`jp`, dereferencing prom_b's routine directory, gets from
`Disk_MountFloppyWithRetry` to `Fdc_Request` (0xFE66C7):

```
Disk_MountFloppyWithRetry -> Disk_MountFloppy -> T_Disk_CommandDispatch_SaveRegs_Entry -> 0xFE3042 (Disk_CommandDispatch_SaveRegs) -> Disk_CommandDispatch (sub_FE426E) -> DiskCmd_MountDrive -> Fdc_Request
```

`Disk_MountFloppy` is one of **23** call sites of directory slot `T_Disk_CommandDispatch_SaveRegs_Entry`, all in
this module; the slot's target 0xFE3042 marshals five long registers into
0x605D70-0x605D80 and tail-jumps into the request layer. So the module that
drives PA bit 3 is the module that issues disk requests, and it drives the pin
around them.

## 4. What this leaves for the emulator, stated as an instruction

* **PA bit 3 is asserted LOW around a block-device operation and released HIGH
  otherwise, and RESET releases it.** That is established.
* **What it is wired to is still not established.** But a *drive select* line
  would not need a 307 ms settle, and a *drive power* line would not be
  released on every exit path. A 300-ish ms wait after asserting, on a machine
  with a 3.5-inch floppy, is a **motor spin-up** wait; that is the reading, and
  it is a reading, not a decode. What would settle it is the FDD connector
  sheet — pin 16 on a Shugart/PC 34-way interface is `/MOTOR ON`, active low,
  which is the same polarity this pin has.
* **IF it is the motor line, the polarity maps to MAME with no inversion.**
  `floppy_image_device::mon_w` takes 0 = motor on
  (`mame/src/devices/imagedev/floppy.cpp:822-842`), and PA bit 3 asserts at 0,
  so the line would be `m_floppy->mon_w(BIT(data, 3))` and not its complement.
  ⚠ **That "if" is load-bearing and is not discharged here.** Round-2 audit F5
  caught a lane report quoting the `mon_w` line as a decode — "gap T now has an
  answer, not a hardware referral". It does not: what is decoded is *bit 3 is
  driven low around every block-device operation, with a 307 ms settle, and
  high otherwise*. Wiring a motor to it is still an inference, and the driver
  lane should treat it as one until the FDD connector sheet or a scope says
  otherwise.
* ⚠ **One measurement to make before believing the first disk read.** MAME sets
  `m_ready_counter = 2` on motor-on, i.e. READY after two index pulses ≈ 400 ms
  at 300 rpm, and this firmware waits **307 ms** before it goes on. If the
  first request after the assert comes back "not ready", that difference is the
  first thing to check — and it is a MAME-side timing question, not a firmware
  bug.

## 5. What this pass did NOT do

* It did not name `Disk_MountFloppyWithRetry`, `sub_FE09BE` or the routine at 0xFE1997. They
  are the three sequences that own the line; what each one is FOR is unknown,
  and the module they live in is still the one whose banner says "converted but
  NOT NAMED".
* It did not establish what `(0x2244) := 0xFF` means, or what `(0x2076) = 0x0D`
  selects, both in `Disk_PortA3_Release`.

## 6. Round-3 amendment: the routine was renamed

`Disk_PortA3_AssertAndSettle` is now **`Disk_PortA3_ClearAndSettle`** (round-2
audit F5). "Assert" put the active-low reading into a permanent label, where a
reader meets it with no warning attached; the new name states only what the
instruction does. Everything about the polarity in §2 stands — it is a reading,
and it is argued, and it lives in prose where it can be contradicted.
* It did not touch PB bit 3 (**gap U**). ★ But it found a neighbour worth
  recording: `Disk_MountFloppyWithRetry` also drives **PB bit 2** — 0xFE08C8 `set 2,(0x1F)`,
  then `Delay_150Ticks`, then 0xFE08CE `res 2,(0x1F)` — a 307 ms HIGH pulse
  immediately after the PA bit 3 assert. Gap U's argument that "the floppy
  module is PB's only writer" needs to survive that.

  ⚠ **CORRECTED in round 3, 2026-08-25.** This paragraph said the pulse was
  "issued once". It is issued at **two** sites, and the widths differ by a
  factor of 75: 0xFE08C8 holds it HIGH for **307 ms** and then clears it with no
  settle at all, while `Disk_InitDriveAndNameEntry` at 0xFE2F3A holds it HIGH for **4 ms**
  (`Delay_Ticks(2)`) and waits 10 ms after clearing. Two widths out of one bit
  is a reset or a strobe, not a level, so PB bit 2 is **not** a second motor
  candidate — which leaves PA bit 3 as the only LEVEL output the disk stack
  drives. The full Port B census (only bits 0, 2 and 3 are ever touched, bit 0
  only read) is in `notes/FINDINGS-prom_a-portb-and-blockdev-entry.md`,
  re-derived by `python3 notes/prom_a_portb_and_blockdev_census.py` — which
  also supersedes the suggestion to run `prom_a_addr_census.py 0x00001F`: that
  census reports 104 byte-pattern hits, and only 9 of them are instructions.
