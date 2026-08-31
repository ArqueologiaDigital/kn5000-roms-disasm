# What prom_a establishes that `src/mame/matsushita/wsa1.cpp` does not yet say

**Compiled 2026-08-31**, by reading the driver on branch `technics-wsa1`
(worktree `~/compartilhado/mame-pr-wsa1`) against this tree. **Nothing here
edits the driver** — that is another lane's file. Every row cites the prom_a
address that establishes it, so each can be checked without this note.

The driver is careful and its memory map is already derived from these images.
What follows is what has landed in the disassembly *since*, plus facts that were
in the tree but never crossed over.

---

## 1. ★★ The two "unidentified" CS0 devices are ONE FLOPPY DISK CONTROLLER

The driver maps

```
map(0x7a0000, 0x7a0001).noprw();   // "A byte port, ring buffered in both directions"
map(0x7b0004, 0x7b0005).noprw();   // "an unidentified byte-wide device"
```

and its own TODO already lists, from the parts list, *"the uPD72070 floppy disk
controller"* among the parts with no MAME implementation. The firmware and the
parts list now agree, and MAME's `upd765` family covers it.

`notes/FINDINGS-prom_a-fdc.md` (established 2026-08-25, driver text predates it):

* **0x7B0004** — Main Status Register on read, control on write. Bit 7 = RQM,
  bit 6 = DIO, bit 5 = EXM, bit 4 = CB, bits 3-0 = per-drive busy. The five
  accessors are prom_a `0xFE54B6-0xFE54EB` and nothing else reaches the port.
* **0x7B0005** — the Data Register.
* **0x7A0000** — *the same controller's data register on the DMA-acknowledged
  decode*, not a separate device. Two paths reach it: programmed I/O through
  the pointer at `(0x605A3E)` (`0xFE680F ld C,(0x7A0000)`,
  `0xFE682B ld (0x7A0000),C`) and **micro-DMA channel 0** through
  `(0x605A3C)`. `Dev7A_Dma_DeviceToRam` (`0xFE59BB`) sets DMAS0 = 0x7A0000
  fixed / DMAD0 = RAM walking / DMAM0 = 0x00; `Dev7A_Dma_RamToDevice`
  (`0xFE59DA`) is the mirror with DMAM0 = 0x08.
* The driver is at `0xFE54EC-0xFE6850`, with four jump tables at
  `0xFE6E3A-0xFE6E83`, and the disk-format module at `0xFE69BF-0xFE7732`
  carries four filesystem templates — including the ASCII `"FAT16"` at
  `0xFE69EA` and the volume labels `"WSA SOUND RAM S0"` (`0xFE7026`),
  `"KN3000 SOUND RAM"` (`0xFE7038`) and `"WSA1"` (`0xFE7049`).

**Also unmapped and real:** `0x7E0008-0x7E0017`, which the driver maps one word
of, is *the second storage unit of the same block-device layer*: all seven
unit-1 arms of `Fdc_Request` reach its four accessors
(`notes/prom_a_unit1_backend_check.py`).

## 2. ★ The interrupt map is complete, and the driver models none of it

`notes/FINDINGS-interrupt-vectors.md` resolves **all 33 slots** of CPU 1's
vector table at `0xFFFF00` (`python3 notes/vector_map.py`). The ones a driver
needs first:

| slot | source | handler | what it is |
|---|---|---|---|
| 0x20 | NMI | `NMI_PowerFail_SaveAndHalt` 0xF8306E | power fail |
| 0x24 | INTWD | `INTWD_Reboot` 0xF82CFF | watchdog |
| 0x28 | INT0 | `INT0_LinkByte` 0xF8E47F | inter-processor link, byte in |
| 0x30 | INT5 | `INT5_Dev7B_Receive` 0xFE6866 | **the FDC's interrupt** |
| 0x34 | INT6 | `INT6_SC1_PeerRequest` prom_b 0xF5AC0A | **control-panel link request** |
| 0x38 | INT7 | (the hang trap) | **but it is what triggers micro-DMA ch 0** for the FDC data port: `INTTC0_uDMA0Done` writes `DMA0V = 0x0E`, and `0x0E << 2 = 0x38` |
| 0x44 | INTT1 | `INTT1_Tick` | the system tick |
| 0x48 | INTT2 | prom_b 0xF57D45, a bare `reti` | paces micro-DMA channel 2 |
| 0x4C | INTT3 | `INTT3_KernelTick` | the multitasking kernel's tick |
| 0x50 | INTTR4 | `INTTR4_SequencerTick` 0xF82EA2 | the sequencer clock |
| 0x60/0x64 | INTRX0/INTTX0 | `MIDI_RX_Byte` / `MIDI_TX_Ready` | **serial 0 = the MIDI port** |
| 0x68/0x6C | INTRX1/INTTX1 | prom_b `INTRX1_SC1_Dispatch` / `INTTX1_SC1_Dispatch` | **serial 1 = the control-panel link** |
| 0x74 | INTTC0 | `INTTC0_uDMA0Done` 0xFE6851 | FDC DMA done, re-arms DMA0V |
| 0x7C/0x80 | INTTC2/INTTC3 | 0xF8E52D / 0xF8E54F | link DMA done |

**Eight slots are a deliberate trap** — `IRQ_UnusedVector_Hang` is `jr T,self`
and never executes `reti`, so an unexpected interrupt *stops the machine*.
Anyone debugging a hang in this driver will want that on the record.

## 3. Serial channel 1 is the control panel, and channel 0 is MIDI

The driver instantiates no serial. The boot block programs both
(`0xF8294B` onward): `SC0CR=0x00, SC0MOD=0x29` (8-bit UART, baud from TREG),
`BR0CR=0x0C` at boot and `0x0E` at MIDI init (`0xFA58F8`, = 31250 baud at
fc = 28 MHz, which is the driver's own clock derivation); `SC1CR=0x00,
SC1MOD=0x01, BR1CR=0x36`.

SC1 carries the CP1 panel MCU's packets — `[0xC0|segment][bitmask]` — decoded by
prom_b `SC1_RxOp0_ThreeByte` (`0xF5B0D5`) into the queue at RAM `0x2B40`, which
prom_a `PanelWireQueue_DrainToGroupQueue` (`0xF8A088`) drains.

## 4. ★★ PORT B bit 0 is the model strap, and on the SX-WSA1R it reads LOW

`Variant_SetFromPB0` (prom_a `0xF82882`): `A = 1`; `bit 0,(PB)`; on the
not-taken arm `A = 2`; `(0x00C4) = A`. So `(0xC4)` is **1 when PB0 is HIGH and
2 when it is LOW**, and 111 sites branch on it.

Which value is the rack was open until 2026-08-31 and is now settled — see
`notes/FINDINGS-prom_a-panel-control-map.md`: the panel event lists the strap
selects agree with the service manual's switch matrix on all twelve wire
segments for **variant 2**, and contradict it on six for variant 1. **A driver
that leaves PB0 pulled high boots this ROM set as the other model.**

## 5. Other port and peripheral programming the driver could assert

All from the reset block, `0xF826AF-0xF82779` (converted, with comments):

| register | value | note |
|---|---|---|
| P6 / P6FC | 0x1B / 0x1F | five alternate functions; CS3 pin = LCAS ⇒ CS3 is the DRAM area |
| P2 / P2FC | 0xFF / 0xFF | port 2 entirely A16-A23 |
| P5 / P5FC / P5CR | 0xFF / 0x24 / 0x2C | |
| P7 / P7FC / P7CR | 0xFF / 0x00 / 0x33 | **bit 0 = link strobe out, bit 3 = link busy in** |
| P8 / P8FC / P8CR | 0xFF / 0x29 / 0x09 | shared with TXD0/TXD1/RXD0/RXD1 |
| PA / PACR | 0xF9 / 0x0E | |
| PB / PBCR | 0xF3 / 0x0C | **bit 0 = the model strap** |
| ODE | 0x03 | open-drain on two outputs; which is not established |
| **ADMOD** | **0x3F** | the A/D converter is PROGRAMMED at boot. ⚠ the field layout is not established here; what is established is that the A/D is *used* — see below |
| IIMC | 0x05 | |
| DMA0V..DMA3V | 0x00 | none armed at reset; DMA2V = 0x12 later (0xF8E166) ⇒ vector 0x48 = INTT2, the link push engine; DMA3V = 0x0A (0xF8E4CA) ⇒ INT0 |

**The A/D matters**: prom_a `0xF8DC00-0xF8DDE5` is the ANALOGUE CONTROL SCAN —
**four A/D channels plus two software ones**, with a deadband filter
(`notes/FINDINGS-prom_a-control-normaliser.md`). So this machine has four
analogue panel controls the driver has nowhere to put yet.

**Power-down is modelled in firmware and needs a machine control to exercise**:
`0xF830AC ldio DMEMCR,0x2D` (DRAM self-refresh), then `0xF830B0 set 5,(P6)`,
then `0xF830B3 halt`. **P6 bit 5 is a power-control output.**

## 6. Timers: the constants, and a test for the prescaler question

The driver's header already argues that MAME's `tmp95c061` prescaler
(`phi-T1 = fc/128`) is probably wrong for this part and that the firmware picks
`fc/8`. The boot block's own numbers, which a wired-up timer must reproduce:

```
T01MOD = 0x0D   TREG0 = 0x0F   TREG1 = 0x1C      -> INTT1, 488.28 Hz at 28 MHz
T4MOD  = 0x05   (bits[1:0]=01 -> phiT1 = fc/8)
TREG4  = 0x0001 TREG5 = 0x3D09 = 15625           -> INTTR4, 140.0 BPM
T5MOD  = 0x02   TREG6 = TREG7 = 0x3A98 = 15000
TRUN   = 0xB7   (bit 7 = prescaler run)
```

`TREG1 = 0x1C` is a second, independent handle on the prescaler question the
driver raises: 28 MHz / 2048 (phiT256, from `T01MOD = 0x0D`) / 28 = 488.28 Hz,
a plausible system tick. ⚠ This pass did **not** work out what the same
constant gives under MAME's `tmp95c061` tap, so it is offered as a second
constant to check the answer against, not as a second proof.

## 7. The panel matrix now has legends — for `wsa1_cpanel.cpp`

`kn7000_mame`'s panel device declares its matrix positionally ("Panel SEG3
SW5"). Round 9 supplied `(segment, bit) -> SW -> legend`; 2026-08-31 closes the
layer above it, the 5-bit event code the firmware's per-screen tables are
indexed by:

```
0x00-0x07 SOFT KEY columns 1..8 (lower/upper share a code)
0x08-0x0C the five LCD-row buttons (left/right column share a code)
0x0D      -1 / +1        0x0F EXIT       0x10 PAGE v / PAGE ^
0x1B      number pad (whole field)       0x1E COMPARE
0x20      PLAY/EDIT MODE x2 and MENU PART/SYSTEM/MIDI/DISK
```

plus, outside class 0xA9, the four BANK buttons (`A8/07`, bits 4-6 as one
three-way field and RE-MAP on bit 7), REALTIME CREATOR (`A8/05`) and RESET
(`B8/00`). Derivation and 19 corroborations:
`notes/FINDINGS-prom_a-panel-control-map.md`.

## 8. The display controller, beyond "it is an SED1330"

The driver's TODO already identifies the part. What prom_a adds for whoever
wires it: the entry thunks and power-on setup are `0xF8E800-0xF8E9A4`, and the
whole graphics API is **SWI7, a 64-slot service gateway** at `0xF8E9A5` —
service 0x00 draw a line, 0x0B set a pixel, 0x03/0x04 layer select, 0x05 fill a
rectangle, 0x0E-0x15 the box/line services, 0x0C/0x0D **which of the three
layers are visible**, and ten fonts with three glyph blitters at
`0xF8F039-0xF8F3A3`. Three 320x240 bitmaps live at `0xFF8000-0xFFF080`.

## 9. Two smaller ones

* **0x7F0000's slot encoding is `(n << 5) | 0x10`**, eight writes per slot
  (`0xF8319A`), and prom_a `0xF85F59-0xF85FF8` treats the port as a **register
  file refreshed by a kernel task** (`0xF85E8A`, the task entry-point records).
  The driver notes the write shape but not that a periodic task drives it.
* **The multitasking kernel at `0xF85606-0xF85E89` is SHARED with CPU 2** and
  assembles byte-identically into prom_a and prom_c from one source
  (`kernel/kernel.s`). Anyone reading either program will meet it twice.

---

### Not a request

This is a list, not a patch. `notes/FINDINGS-*.md` and the listings carry the
detail; the driver's own rule — map only what the firmware establishes, and say
which address establishes it — is the right one and every row above is written
to fit it.
