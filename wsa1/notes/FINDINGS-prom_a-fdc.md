# The device at 0x7B0004/0x7B0005 + 0x7A0000 is a uPD765-family FLOPPY DISK CONTROLLER

**Established 2026-08-25** while converting prom_a `0xFE54EC-0xFE594B`,
`0xFE5A41-0xFE6850` and the four jump tables at `0xFE6E3A-0xFE6E83` — 4,794
substantive bytes, the whole driver in one contiguous module.

This **closes emulation gap B** of
`kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md`, which asked: "What is on the
other side of that command/status pair? And what do the ten direction codes
`0x4D 0xC9 0xC5` (RAM → device) and `0xDD 0xD9 0xD1 0x4A 0x42 0xCC 0xC6`
(device → RAM) mean?"

They are **uPD765 command opcodes**, and the pair is the FDC's Main Status
Register and Data Register.

`notes/FINDINGS-dev7b-and-int5.md` said *"⚠ What the device IS has not been
established … **Do not name it.** In particular this note does not claim it is a
floppy controller"*. That sentence is now **withdrawn**, and that note has been
corrected in the same pass. It was the right call on the evidence it had: the
five accessors and the INT5 handler alone do not identify anything. The
identification comes from the 4,720 bytes underneath them, which were `.incbin`
when it was written.

Every number below is re-derived from the ROM by
**`python3 notes/prom_a_fdc_checks.py`** — 138 named checks, all passing. Run it
before quoting anything here.

---

## 1. The decisive evidence: a 32-value truth table

`Fdc_ClassifyCommandOpcode` (`0xFE5CE8`) is the driver's own opcode validator.
It masks the command byte with `0x1F` — so MT, MFM and SK are ignored, which is
how a uPD765 decodes — and then accepts

* `0x1D` and `0x19` by direct comparison,
* the run `0x02`–`0x0A` by a signed range test,
* and, for `0x0B`–`0x11`, whichever the 7-entry `Fdc_OpcodeValidityJumpTable`
  sends to `0xFE5D2A` (`ld L,0`) rather than `0xFE5D2D` (`ld L,1`): those are
  `0x0C`, `0x0D`, `0x0F` and `0x11`.

So the accepted set over the 32 values of the five-bit field is

```
{ 02 03 04 05 06 07 08 09 0A 0C 0D 0F 11 19 1D }          15 accepted
{ 00 01 0B 0E 10 12 13 14 15 16 17 18 1A 1B 1C 1E 1F }    17 rejected
```

and that is **exactly** the truth table of
`upd765_family_device::check_command()`
(`../mame/src/devices/machine/upd765.cpp:1433-1478`): every accepted value is a
uPD765 command and every rejected value is not.
`prom_a_fdc_checks.py` builds both sets — ours by simulating this routine from
constants read back out of the ROM, MAME's by parsing the `case` labels — and
fails unless all 32 values agree.

That is one coincidence to explain away. The rest are independent of it.

## 2. Corroboration, none of it assumed

| what the ROM does | where | why only an FDC does that |
|---|---|---|
| emits per opcode exactly that command's parameter count: 1 byte for `0x08`, 2 for `0x03`, 2 for `0x07`/`0x04`/`0x4A`, 2 for `0x0F`, 5 for `0x4D`, 8 for the read/write family | `Fdc_IssueCommand` `0xFE5C0A` | the uPD765 command lengths, all of them |
| takes the SPECIFY arm **before** building the drive byte | `0xFE5C6B` vs `0xFE5C73` | SPECIFY is the one uPD765 command with no HD/US byte |
| substitutes STP for DTL for opcodes `0xDD`, `0xD9`, `0xD1` | `0xFE5DFE` | those three are SCAN HIGH/LOW/EQUAL, the only commands whose ninth byte is STP |
| builds the drive byte as `(head & 1) << 2 \| (unit & 3)` | `0xFE5C81`-`0xFE5C95` | HDS, US1, US0 |
| builds SPECIFY as `(SRT<<4)\|HUT` then `(HLT<<1)\|ND` | `0xFE5D41` | the SPECIFY encoding |
| FORMAT TRACK's filler byte is `0xE5` | `0xFE639C` | the conventional format filler |
| reads the IC field as `ST0 & 0xC0`, then tests ST0 bits 3 and 4 and ST1 bits 0,1,2,4,5,7 | `Fdc_ClassifyResultStatus` `0xFE5B5E` | ST0_NR, ST0_EC and **all six defined ST1 bits and neither undefined one** (`upd765.h:82-95`) |
| decodes SENSE DRIVE STATUS's single result byte as ST3 bits 7, 5, 6 | `0xFE6668` | ST3_FT, ST3_RY, ST3_WP — and it raises the **same three error codes** the ST0/ST1 path raises for fault, not-ready and read-only |
| masks the status byte with `0x1F`, `0x90`, `0xE0`, `0xF0`, and clears bit 4 | throughout | unions of MSR_DB, MSR_CB, MSR_EXM, MSR_DIO, MSR_RQM (`upd765.h:76-80`) |
| programmes three complete geometries | `Fdc_SelectFormatParameters` `0xFE57FF` | see §4 |
| writes `0x08` to the data register straight after a controller reset, in a loop that ends when ST0's IC field reads `0x80` | `Fdc_ResetAndIdentifyMedia` `0xFE558B` | SENSE INTERRUPT STATUS, drained until "invalid command" — the standard post-reset drain |

## 3. So the ten "direction codes" are command opcodes

`Dev7A_StartDma` (`0xFE596A`) picks the micro-DMA direction from a flat compare
chain on `(0x605A18)` — which this pass shows is the **command byte**. Reading
the ten literals as uPD765 opcodes:

```
RAM -> device   0x4D  FORMAT TRACK          (0x0D | MFM)
                0xC9  WRITE DELETED DATA    (0x09 | MT | MFM)
                0xC5  WRITE DATA            (0x05 | MT | MFM)
device -> RAM   0xDD  SCAN HIGH OR EQUAL    0xD9  SCAN LOW OR EQUAL
                0xD1  SCAN EQUAL            0x4A  READ ID
                0x42  READ TRACK            0xCC  READ DELETED DATA
                0xC6  READ DATA
```

Ten codes, ten commands, and the split is exactly the direction each command
moves data. `prom_a_fdc_checks.py` asserts that every one of the ten is in the
accepted set and that the two groups decode to those opcodes.

## 4. Three disk geometries, read off 30 immediates

| index (low nibble of the media byte) | N | EOT | GPL | GPL format | cylinders | sectors/track | capacity |
|---|---|---|---|---|---|---|---|
| 0, 4, 5 | 2 (512 B) | 9 | 0x1B | 0x54 | 0x50 = 80 | 9 | 2 × 80 × 9 × 512 = **720 KB** |
| 2 | 3 (1024 B) | 8 | 0x53 | 0x74 | 0x4D = 77 | 8 | 2 × 77 × 8 × 1024 = **1.2 MB** |
| 3 | 2 (512 B) | 0x12 | 0x1B | 0x6C | 0x50 = 80 | 0x12 = 18 | 2 × 80 × 18 × 512 = **1.44 MB** |

Those are the three standard uPD765 parameter sets, GPL values included, and
the driver also derives `(0x605AF7) = sectors/track + 1` and
`(0x605AF1) = last cylinder + 1` from them — both re-checked.

Sector size is taken from the geometry index a second time in the transfer
loops: `0x400` when the index is 2 and `0x200` otherwise (`0xFE6089`), which is
consistent with N above.

## 5. The register map, as the driver uses it

| address | direction | what |
|---|---|---|
| `0x7B0004` | read | **Main Status Register**: bit 7 RQM, bit 6 DIO, bit 5 EXM, bit 4 CB, bits 3-0 drive busy |
| `0x7B0004` | write | a **control register**. Written with `0x80`, `0x02` and `0x00`; it does not read back, which is why `Dev7B_WriteControl_Shadowed` keeps a copy at `(0x605B09)`. ⚠ **Which bit does what is NOT established.** What is established is that the `0x80` write is followed by the standard post-reset sequence |
| `0x7B0005` | read/write | **Data Register** — command, parameter and result bytes |
| `0x7A0000` | read/write | the **same data register on the DMA-acknowledged decode**. Two paths reach it and both move one byte per INT7: micro-DMA channel 0 (`Dev7A_Dma_DeviceToRam` / `_RamToDevice`) and the programmed-I/O handler `Fdc_ServiceDataByte` (`0xFE67F9`), which ends its transfer with the same `PortB3_Pulse` + `uDMA0_ArmOnINT7` pair `INTTC0_uDMA0Done` uses |
| PA bit 3 (SFR `0x1E`) | write | set by operation 7, cleared by operation 6. ⚠ **not established** — the obvious reading is drive motor or drive select, and it is not claimed |

Interrupts: **INT5** is the result-phase interrupt, **INTTC0** is micro-DMA
channel 0's end-of-count, and `Fdc_EnableInterrupts` (`0xFE5C03`) arms exactly
those two and nothing else (`INTE45 = 0x40`, `INTETC01 = 0x05`).

⚠ **INT7 has no vector.** `Fdc_ServiceDataByte` is published as slot 3 of the
module's entry directory at `0xFE3000` (through prom_b thunk `0xF42D2C`), but
`notes/vector_map.py` puts vector slot `0x38` at `0xF82D09`, the deliberate
hang. So on this firmware the byte path is micro-DMA only. Stated as measured;
no claim about intent.

## 6. The API: a TWO-UNIT block-device layer, which also closes gap J

`Fdc_Request` (`0xFE66C7`) is the module's only public entry — eight call sites,
all in already-converted prom_a code, all exact (`notes/prom_a_fdc_callgraph.py`
reads them out of the source's own byte comments; `notes/prom_a_xref.py`
independently finds the same eight). It takes a 16-byte request block:

```
+0x00 word  operation 0..11        +0x02 word  UNIT, 0 or 1
+0x04 word  head                   +0x06 word  track, or the media descriptor
                                               byte for operation 0
+0x08 word  first sector           +0x0A word  sector count
+0x0C long  buffer address
```

copies it to `(0x605A30)` **and** `(0x605A40)`, guards re-entry with `0xA5` at
`(0x605A09)` under `ei 6` / `ei 0` (a second entry returns error `0xFB`),
validates it through a 12-entry table, and executes it through another:

| op | routine | what |
|---|---|---|
| 0 | `Fdc_Op0_ResetAndIdentifyMedia` | reset, drain, SPECIFY, choose geometry |
| 1 | `Fdc_Op1_Recalibrate` | seek to 5, then RECALIBRATE |
| 2 | `Fdc_Op2_SeekToCylinder` | SEEK, skipped when `(0x605AEE)` already matches |
| 3 | `Fdc_Op3_ReadSectors` | CHS loop, opcode `0xC6` |
| 4 | `Fdc_Op4_WriteSectors` | CHS loop, opcode `0xC5` |
| 5 | `Fdc_Op5_FormatDisk` | every track, opcode `0x4D` |
| 6 | `Fdc_Op6_PortA3_Off` | clear PA bit 3, wait 5 ticks |
| 7 | `Fdc_Op7_PortA3_On` | set PA bit 3 |
| 8 | `Fdc_Op8_GetSavedError` | republish the previous request's error |
| 9 | `Fdc_Op9_SetFlag605A59` | set/clear a flag nothing reads |
| 10 | `Fdc_Op10_TestControllerPresent` | MSR reads `0xFF` ⇒ error `0xFC` |
| 11 | `Fdc_Op11_SenseDriveStatus` | opcode `0x04`, decode ST3 |

★ **The unit field selects the BACK END.** Every operation begins
`cp (0x605A32),1`, and the unit-1 arm calls one of seven routines in
`0xFE4CE0-0xFE544D`. `python3 notes/prom_a_unit1_backend_check.py` shows that
**all seven** reach the four accessors of the **16-bit port at
`0x7E0008`/`0x7E0010`** — `0xFE4C73` write byte, `0xFE4C99` write word,
`0xFE4CBF` read byte, `0xFE4CE0` read word — and that those four are the only
`add Xrr,0x007E0000` instructions in the **converted text** of prom_a and prom_b
(4 in prom_a, 0 in prom_b). Beyond the converted text the evidence is a BYTE-WINDOW
SCAN of both images, which is what makes the image-wide form of this sentence
weaker than the converted-text one: the scan finds exactly one further hit on the
immediate, prom_a `0xF96DA9`, and it is inside a table of 32-bit values stepping
by `0x20`, not an instruction; the script reports it and does not count it.
⚠ CORRECTED 2026-08-25 (audit F13): this paragraph said "the only … in prom_a or
prom_b" without saying which of the two searches carried the claim.

So the device at `0x7E0008-0x7E0017` — **emulation gap J**, previously "two
bytes of the driver's map are inert" — is the machine's **second storage unit**,
driven through the same request block and the same twelve operations as the
floppy. The four accessors' index construction, `0x7E0000 + ((n & 7) | 0x08)` or
`| 0x10`, is two banks of eight 16-bit registers, and the reachability closure
is an upper bound (see the script's own caveat), so the claim made here is that
unit 1 *is* this device, not that any particular register is touched by any
particular operation.

[Named in the source 2026-10-03 (`wsa1/include/wsa1_ram.inc`, `scripts/tools/name_wsa1_ram.py`): the
request copy at `0x605A30` as `Fdc_ReqOp` / `Fdc_ReqUnit` / `Fdc_ReqHead` / `Fdc_ReqTrack` / `Fdc_ReqSector`
/ `Fdc_ReqCount` / `Fdc_ReqBuffer` (the `0x605A3E` slot the PIO path walks is `Fdc_ReqBuffer+2`),
`Fdc_ReqCopy` (`0x605A40`), `Fdc_TickCount`, `Fdc_ReentryGuard`, `Fdc_DmaCount`, `Fdc_ErrorCode`,
`Fdc_CommandByte`, `Fdc_ResultBuf`, `Fdc_CurrentCylinder`, `Fdc_LastCylinderPlus1`,
`Fdc_SectorsPerTrackPlus1` -- 178 operands in prom_a.  `(0x605A59)` and `(0x605AEC)`, written and never
read, stay numbers.]

## 7. Errors

`Fdc_SetError` (`0xFE5E84`) keeps the **first** code; every operation clears
`(0x605A15)` before starting. Codes raised anywhere in the module:

```
0x01 idle / parameter-phase wait timed out     0x02 RQM wait timed out
0x03 command-byte wait timed out               0x08 unclassifiable status
0x09 no INT5 result in 500 ticks               0x10 read retries exhausted
0x20 write retries exhausted                   0x2F write protected
0x31 drive not ready                           0x32 equipment check / fault
0x33 no data          0x34 overrun             0x35 missing address mark
0x36 data error       0x37 end of cylinder
0xFB re-entered       0xFC no controller       0xFE bad request field
0xFF unknown operation code
```

The 500-tick timeouts run on `(0x605A00)`, the INTT1 counter with exactly one
writer (`notes/FINDINGS-dev7b-and-int5.md`); at the 488.28 Hz of
`notes/FINDINGS-system-clock.md` that is 1.024 s.

## 8. Two things the emulator must know before it models this

1. **`Fdc_WaitReadyForCommandByte` (`0xFE5A8F`) contains an unbounded drain.**
   When it sees `MSR & ~CB == 0xC0` it reads the data register, stores the byte
   at `0x605A50+i`, reads MSR, **discards that MSR** and loops, with no exit
   test. An emulated MSR that ever presents RQM|DIO with EXM and CB clear at a
   command-phase boundary wedges CPU 1 there. Reported as read; not diagnosed.
   (This is a *second* unbounded poll in this subsystem — `INT5_Dev7B_Receive`
   already had one, which is why the driver maps both windows inert today.)
2. **The controller is never CONFIGUREd.** `Fdc_IssueCommand` has an arm that
   sends `0x00, 0x0C, 0xFF` after opcode `0x13` — a well-formed uPD765-family
   CONFIGURE payload — but the routine classifies the opcode first and returns
   at once when the answer is "invalid", and `0x13` is one of the 17 rejected
   values (§1). So the arm is unreachable, `Fdc_ResetAndIdentifyMedia`'s
   `push 0x13` does nothing, and the part runs in its power-on mode. Recorded as
   read; no claim that this is a defect.

## 9. What is NOT established

* **The part.** The register-level protocol is uPD765-family; nothing in the ROM
  names a chip. `kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` records that
  the SX-WSA1R has a **uPD72070**, which is consistent — but note the driver's
  validator implements the **base** uPD765 opcode map, not the enhanced one.
* **Which bit of the control register at `0x7B0004` does what.**
* **What PA bit 3 drives.**
* **`(0x605A59)` and `(0x605AEC)`** — both written and never read anywhere in
  prom_a or prom_b (`notes/prom_a_addr_census.py 0x605A59` → 3 writes, 0 reads;
  `0x605AEC` → 2 writes, 0 reads).
* **Why the request block is copied twice**, to `0x605A30` and `0x605A40`.
* **`Fdc_WriteControlRegister_IfNoError` (`0xFE5B25`),
  `Fdc_WriteControlRegister_AndReadResult` (`0xFE5B3C`) and
  `Fdc_Delay20Ticks` (`0xFE5F14`) have no caller** in the module or in any
  converted prom_a code, and `notes/prom_a_xref.py` finds no absolute reference
  either. That is a searched negative with both searches named — not "unused".

## 10. Tools this pass added

| script | question it answers |
|---|---|
| `notes/prom_a_fdc_checks.py` | do the module's 138 quantified claims still hold against the ROM? |
| `notes/prom_a_fdc_callgraph.py` | inside `0xFE54B6-0xFE68F2`, which routine calls which — and which converted code outside calls in? |
| `notes/prom_a_unit1_backend_check.py` | does every unit-1 arm reach the `0x7E0000` accessors? |
| `notes/gen_prom_a_fdc_module.py` | regenerates the annotated assembly, with every "Called from:" line computed rather than typed |
