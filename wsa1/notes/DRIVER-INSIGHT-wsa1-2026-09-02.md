# Does the completed WSA1R disassembly answer the driver's own TODOs?

Lane `w12/drvwsa1`, 2026-09-02.  Written against the block comment of
`~/compartilhado/kn7000_mame/src/mame/matsushita/wsa1.cpp` (the overlay
development copy), which names three things as open.  **Nothing in the driver
was changed; this is an assessment.**

Reproduce every number quoted below:

```
python3 wsa1/notes/driver_insight/driver_insight_probes.py --selftest
    # 3 sections, 36 checks, 0 failures, 6 of them negative or positive controls
sh     wsa1/notes/driver_insight/render_service_manual_crops.sh /tmp/crops
    # re-renders the eight schematic crops this note reads by eye
python3 wsa1/notes/prom_a_census_round8.py --ata
    # the pre-existing 41-call ATA accessor census (not written by this lane)
```

Toolchain: nothing here decodes with `llvm-mc` or `unidasm`; the probe reads
`wsa1/original_ROMs/*` bytes directly, so no figure depends on the shared
toolchain build.  No `.s` file was touched, so no gate run was needed
(`git diff --name-only main` shows only `wsa1/notes/`).

---

## THE HEADLINE, AND IT IS AN UNCOMFORTABLE ONE

**Two of the three TODOs are settled — and the artefact that settles them was
already in this repository's sibling tree the whole time.**
`~/compartilhado/KN7000/service_manual/SX-WSA1R Service Manual.pdf` contains
complete P.C. diagrams for the MAIN (A), MAIN (B) and MAIN (C) boards.  The
driver header calls the scan "photocopy grade" and says several designators
"did not survive at all", which is true of the *parts list*; the **schematic
sheets on pages 19-23 are legible**, and they carry the chip-select decoders
with every output named.

The reason this was missed is worth recording: `pdftotext` returns **nothing**
for that file — it is image-only — so every text-based search over it has
returned a false negative, and the driver's provenance section was written as
if the book could not answer these questions.  It can.

Below, each target states what the **disassembly** establishes and what the
**schematic** establishes, separately, because they are different kinds of
claim and the driver's existing comments are careful about exactly that
distinction.

---

## TARGET 1a — `0x7E0008` on the first processor

### SETTLED. It is an ATA (IDE) hard disk.

**The driver's text is stale.**  It currently says

> STILL INERT, deliberately.  Knowing which block-device layer drives it is not
> knowing what the device IS: no part is named, no register in either bank has a
> meaning, and the accessor's index construction ... is all that says there are
> two banks of eight -- in the only traced caller (0xFE50A0) both indices are
> zero for all 256 iterations, so `0x7E0008` is the only address the code is
> known to reach.

Every clause of that after the first sentence has been overtaken by the
disassembly, in round 8 and round 10 of the prom_a waves (2026-08-25 /
2026-08-30).  `prom_a/wsa1_prom_a.s` already carries the finding at
`0xFE4C73` and in the FDC module header at `0xFE5000`:

* **The register file is an ATA task file.**  41 accessor calls have a literal
  bank and register (`notes/prom_a_census_round8.py --ata`).  Bank 0 =
  `0x7E0008..0x7E000F` is the command block (data, features/error, sector
  count, sector number, cylinder low, cylinder high, device/head,
  command/status); bank 1 register 6 = `0x7E0016` is device control, and it is
  written `0x0C` then `0x08` with nothing between them at `0xFE50E9` /
  `0xFE50F5` — SRST asserted and released.  Those are the *only* two bank-1
  writes in prom_a.
* **Seven ATA opcodes are issued**, each with the data phase its opcode
  demands: `0x20` READ SECTOR(S), `0x30` WRITE SECTOR(S), `0xEC` IDENTIFY
  DEVICE, `0x91` INITIALIZE DEVICE PARAMETERS, `0xEF` SET FEATURES, and
  `0x94`/`0x95` which move nothing.
* **The status bits are used for what ATA uses them for**: bit 7 polled until
  clear with a 500-tick timeout (BSY), bit 3 required before each 512-byte
  transfer (DRQ), bit 0 checked after one (ERR), bit 6 required after a
  command that moves no data (DRDY).

★ **And the ROM says the word.**  `prom_a 0xFE69BF` is a complete FAT16 boot
sector for a **fixed disk**, followed by a matching master boot record.  The
probe decodes it out of the EPROM:

| BPB field | value |
|---|---|
| OEM name | `" EMID2.0"` |
| media descriptor | `0xF8` — fixed disk |
| BIOS drive number | `0x80` — first hard disk |
| sectors per track / heads | 60 / 15 |
| hidden + total sectors | 60 + 511,140 |
| filesystem type | `"FAT16   "` |
| boot code strings | `"Non-System disk or disk error"`, **`"This is Technics HDD."`** |

`(511140 + 60) / (60 * 15) = 568` cylinders **exactly, remainder 0**, i.e. a
261.7 MB drive — and the same geometry appears independently on the ATA path:
INITIALIZE DEVICE PARAMETERS is issued with sector count `0x3C` = 60 and
device/head `0x0E` = heads-1, and the request layer compares RAM cells against
`0x0239` cylinders, `0x000F` heads and `0x003C` sectors at `0xFE31AA` /
`0xFE31B3` / `0xFE31BC`.  Two structures written by different parts of the
firmware, agreeing on one drive.
(`--hdd`; the string is absent from prom_b and prom_c, which is the null.)

### And the schematic agrees, from the other end

`fig1_ic1_main.png`: IC1's port pins include **`HDINT`** and **`HDIORDY`**.
`fig4_cpu1_decoders.png`: IC18, a D74HC138GS with `A=A16 B=A17 C=A18`,
`G1=A19`, `/G2A=/G2B=CS0`, decodes

| output | address | net |
|---|---|---|
| Y0 | `0x780000` | *(no net name)* |
| Y1 | `0x790000` | **LCDCS** |
| Y2 | `0x7A0000` | **FDDAK** |
| Y3 | `0x7B0000` | **FDCS** |
| Y4 | `0x7C0000` | **MIF** |
| Y5 | `0x7D0000` | *(no net name)* |
| Y6 | **`0x7E0000`** | **HDCS** |
| Y7 | `0x7F0000` | *(no net name)* |

Five named outputs land on exactly the five addresses the disassembly derived
from the firmware alone, with the names the disassembly gave them
(SED1330, floppy DMA acknowledge, floppy controller, inter-processor
interface).  **`HDCS`** is the sixth.

### What to change in the driver

1. Replace the "STILL INERT ... no part is named" paragraph.  `0x7E0000`'s
   decode is `HDCS`; the register protocol is ATA; the ROM carries a FAT16
   boot sector for a 261.7 MB fixed disk and the string "This is Technics
   HDD.".
2. `map(0x7e0008, 0x7e0009).noprw()` is too narrow and states something now
   known to be false.  The reached window is `0x7E0008-0x7E000F` (command
   block, register = `addr & 7`) plus `0x7E0016` (device control).
3. If it is wired to a real device, `ata_interface`/`ide_controller` is the
   family, with **`cs0` on `0x7E0008-0x7E000F` and `cs1` on
   `0x7E0010-0x7E0017`, register select from `A0..A2`** — note that is A0-A2,
   not the A1-A3 spacing a PC-style hookup uses; the firmware forms
   `0x7E0000 + ((n & 7) | 0x08)` with `n` consecutive.  `HDINT` should drive
   an interrupt line (which one is not established here) and `HDIORDY` a wait.
4. `Fdc_Request`'s comment "unit 1 is the device at 0x7E0008, not a floppy"
   can say "an ATA hard disk".

⚠ **NOT established, and it matters for whether this is worth wiring.**
Nothing traced here shows a *user path* that sets the request block's unit
field to 1, and `notes/prom_a_xref.py` finds **no consumer at all** for the two
1024 bytes of boot-sector/MBR images — nothing in prom_a or prom_b copies them
anywhere.  So the firmware can drive an ATA disk and can describe one; whether
any menu reaches that code, and whether a drive was ever fitted, is open.  The
service manual's parts list and Felipe's machine are what would settle it.
⚠ The opcode and register NAMES are the ATA standard's; no ROM image spells
them, exactly as the floppy half of the same module declines to name its
uPD765 part.

---

## TARGET 1b — `0x7F0000` on the first processor

### NARROWED, hard: the strongest reading is that NO CHIP IS FITTED THERE.

The driver models it as "the 4 x 32 register file its driver shape says it is,
without a part name".  The shape is right and is not in doubt.  What the
completed disassembly adds is **character**, and what the schematic adds is a
missing net.

**What the firmware does (all from `--dev7f`, byte-derived):**

* prom_a names `0x007F0000` in exactly **5** `ld <Xrr>,imm32` instructions and
  prom_b in **none**; prom_c names `0x00E00000` in exactly **3** and never
  names `0x007F0000` (the null runs both ways and both are clean).
* The device is **written and never read**, on either processor, in any path.
* The four 8-bit values per slot go to registers `(n<<5)|0x10 .. +7`; register
  `(n<<5)|0x1F` is set to 1 once.  Registers `0x00-0x0F` and `0x18-0x1E` of
  every slot are **never touched at all**.
* `sub_F831B3`, its only *directly called* writer (one site, `0xF825E1`, in the
  boot block), builds four words of `0x0005` on the stack and then hands
  `XSP+8`, `XSP+6`, `XSP+4`, `XSP+2` to the four slots — **overlapping reads
  that run past the pushed words into this routine's own return address.**  The
  source header already flags this and refuses to name it.  Code that feeds a
  device its caller's return address is not code anybody tested against a chip.
* `DSP_ChannelRegs_Init` (0xF85F0F) has **no caller at all** in prom_a or
  prom_b — no `call`, no `jp`, no `calr`.
* `T_DSP_WriteAllChannelRegs` (prom_b slot 0xF42DE4) has **zero** call sites;
  `T_DSP_ChannelRegs_Write8` (0xF42DE0) has **exactly one**, at `0xF8287B` in
  the boot block, and it hands the device eight bytes from `0x6007DB` — which
  is where the link module keeps its **error counters**.
* `sub_FA6068` and its byte-identical twin `sub_FA6112`, which call all four
  slot entries, have **no caller**.  The thirteen `calr Dev7F_WriteAllFourSlots
  / ret` stubs in the 0xFAD800 parameter module have **no reference between
  them** — total 0.
* ⚠ **Reachability is NOT fully negative and this note does not claim it is.**
  `Dev7F_WriteAllFourSlots` (0xFADF0D) has 16 `calr` sites, three of which
  (`0xFAE02E`, `0xFAE049`, `0xFAE2DE`) are not among those thirteen stubs, and
  the four slot thunks have three further call sites each in the 0xFAE800-
  0xFAED89 range.  Whether *those* are reached was not traced.

**On the other processor the same driver is equally quiescent.**
`DSP_ChannelRefresh_Loop` (prom_c 0xF98118) is CPU 2's highest-priority task and
reloads all four slots — but it blocks on `Kernel_SemaWait(3)` each pass, and
`prom_c/boot/boot_and_main.s` records that **nothing found ever signals
semaphore 3** (both `Kernel_SemaSignal` sites push 2).  Semaphore 3 starts at 1,
so on the evidence available that task runs **exactly one pass and then blocks
for ever**.  Its four buffers are also odd: channels 0 and 2 are both loaded
from RAM `0x6612`, channels 1 and 3 from `0x0100` and `0x0108`.

### The schematic's contribution, and it is the decisive one

* CPU 1: IC18 Y7 = `0x7F0000` — **no net name** (table above).
* CPU 2: `fig5_cpu2_decoder.png`, IC27 D74HC139GS, second half
  (`2E=SCS2`, `2DA=SA19`, `2DB=SA20`): `2Y1 = SFLSHCS` (0xE80000),
  `2Y2 = PROMDCS` (0xF00000), `2Y3 = PROMCCS` (0xF80000), and
  **`2Y0` = `0xE00000` — no net name.**

★ **The two addresses that the one shared 234-byte driver targets — one per
processor, on two different boards, through two different decoder chips — are
the only decoder outputs in this machine that the firmware writes and the
schematic does not name.**  Every other unnamed output (`0x780000`,
`0x7D0000`, CPU 1's `0xE80000`, CPU 2's CS1 sub-windows) sits at an address the
firmware never touches, which is the control that makes the convention
readable.  And the first half of that same IC27 — CPU 2's CS0 decoder — has
**all four outputs used and all four named** (`SMIF`, `WFICS`, `KSCS`,
`SGCS`), landing exactly on 0x100000 / 0x104000 / 0x108000 / 0x10C000.

The reading that fits everything: **`dsp/dsp_channel_regs.s` is shared source
inherited from the KN5000 sub-CPU, where the device at `0x00130000` is real,
and the SX-WSA1R fits no chip on either of the two windows it was recompiled
for.**  That is exactly what write-only traffic, an uncalled initialiser, a
writer that reads its own return address, and a refresh task nothing ever
wakes look like.

⚠ **What would refute it, and why this is NARROWED rather than SETTLED.**  An
unlabelled stub on a 1995 photocopy is an *absence*, and this note is reading
one.  Three things would settle it, in increasing order of trouble: the
service manual's **parts list** for the MAIN (A) and MAIN (B) boards (does any
unaccounted-for IC remain?); the **foil-side board pages** 25-28, which show
whether a trace leaves IC18 pin 7 at all; and Felipe's actual machine.  It is
also possible the **SX-WSA1 keyboard** version populates it — this manual
covers only the rack.

### What to change in the driver

Nothing yet — the current model (store the writes so the debugger can see
them, log an unexpected read) is exactly right for a window whose device is in
doubt, and it should stay.  What should change is the **comment**: the block
comment above `cpu1_chanreg_addr_w` can say that the decoder output for this
window carries no net name on the schematic, that the device is written and
never read on either processor, and that the driver is shared source with the
KN5000 sub-CPU where the twin at 0x130000 *is* fitted.  The `LOG_CHANREG`
description ("the 4 x 32 channel register files") should lose the word
"channel", which imports a role from the KN5000.

---

## TARGET 2 — which processor is IC1 "MAIN" and which is IC2 "SUB"

### The disassembly: NOT ANSWERED. The schematic: SETTLED.

**No ROM image can answer this.**  A designator is a fact about a drawing.  The
levers the question suggests were all checked and all fail:

* **A self-identifying byte over the link?**  No.  The header byte is
  `(channel << 5) | (len - 1)` and the command set `0xE1..0xE7` is the same on
  both sides; `prom_c/link/link_service.s` shows CPU 2 answering an `0xE2`
  remote-read with an `0xE1` write using the identical field layout CPU 1 uses.
  The protocol is symmetric.
* **A master/slave asymmetry in remote memory access?**  No.  CPU 1 has
  `Remote_E80000_Read32Blocks`; CPU 2's link service answers `0xE2` and also
  issues its own.  Both sides read each other's memory.
* **A boot-order asymmetry?**  Not one that names an IC.
* **A part-numbered device only one of them talks to?**  Neither image names a
  single part number anywhere — that is a standing result of this tree
  (`FINDINGS-sound-subsystem-boundary.md` §5).

What the disassembly *does* give is a functional split, which supports the
conventional reading without proving the designators: CPU 1 owns the panel
link, the SED1330, the floppy, the disk stack, the song store and the UI; CPU 2
owns the keybed, the tone generator, the voice engine and MIDI port 2, and
forwards keyboard events to CPU 1 as MIDI note-ons on link channel 5 and raw
MIDI-in bytes on channel 6 — channels that are receive-side no-ops on CPU 2,
"which is what a one-way assignment looks like".

**The schematic settles it outright** (`fig1_ic1_main.png`, `fig2_ic12_ic13.png`,
`fig3_ic2_sub.png`):

* Sheet II-7/II-8, "MAIN (A)/MB2 P.C. Diagram": **IC1 TMP95C061AF
  MICROCOMPUTER (MAIN)**, on the unprefixed `A0..A20 / D0..D15` bus, with
  **IC12 QSIGCWSA1AX** (`/CE = PROMACS`) and **IC13 QSIGCWSA1BX**
  (`/CE = PROMBCS`), both "4M BIT PROGRAMMED EP ROM", `A1..A18`, `D0..D15`.
* Sheet II-9/II-10: **IC2 TMP95C061AF MICROCOMPUTER (SUB)**, on the
  S-prefixed bus (`SA0..SA21`, `SD0..SD15`, `SCS0/1/2`, `SRD/SWR/SHWR`).
* Sheet II-11/II-12: **IC28 QSIGCWSA1CX** (`PROMCCS`) and **IC21
  QSIGCWSA1DX** (`PROMDCS`) are on the S bus.

So: **prom_a + prom_b are IC12 + IC13 on IC1, the MAIN processor; prom_c and
prom_d are IC28 and IC21 on IC2, the SUB processor.**  The tree's existing
naming — `wsa1_prom_a.ic12`, "CPU 1, MICROCOMPUTER (MAIN), IC1/IC12" in
`kernel/kernel.s` — is correct, and can now cite a sheet instead of asserting.

### Four more things that fall out of the same two sheets

1. **The x16 inference the driver flags as "inferred, not proven" is proven.**
   IC12 and IC13 are drawn with `A1..A18` on the EPROM's `A0..A17` and
   `D0..D15` — the CPU's `A0` is not connected, which is exactly what a x16
   device on a byte-addressed bus looks like.
2. **prom_a's and prom_b's bases are confirmed.**  IC17 (D74HC139GS), second
   half, `2E=CS2`, `2DA=A19`, `2DB=A20`: `2Y0 = EXTCS` (0xE00000, the
   expansion board), `2Y2 = PROMBCS` (0xF00000), `2Y3 = PROMACS` (0xF80000).
   The driver's `map(0xf00000,0xf7ffff)` = IC13 and `map(0xf80000,0xffffff)` =
   IC12 are right.
3. ★ **The fourth EPROM's base is settled, and the driver's TODO has it
   backwards.**  The TODO says prom_d is "strongly supported as the content of
   the 512 KiB flash at 0xE80000 ... but not proven".  IC27's second half
   gives `2Y1 = SFLSHCS` at `0xE80000` (that is IC22, the AM29F400T) and
   `2Y2 = PROMDCS` at **`0xF00000`** — a *separate* select for a *separate*
   4M-bit EPROM, IC21.  prom_d is at `0xF00000-0xF7FFFF` on CPU 2, which is
   what the disassembly already concluded from CPU 1's remote read of the build
   tag at `0x00F7FFF0`.  The flash and the fourth EPROM are different chips.
   ★ Lane `drvpromd` reached `0xF00000` **independently and first**, from the
   firmware alone, and its `notes/DRIVER-INSIGHT-promd-base-2026-09-02.md` is
   the fuller argument; this sheet is a second, physical witness to the same
   number, and the two agree.  Note also that IC17's `2Y0 = EXTCS` puts CPU 1's
   expansion-board window at `0xE00000-0xE7FFFF`, which is a *different* window
   from the `0x00C00000` base prom_c installs for the board on CPU 2's bus, and
   prom_a never names `0x00E00000` in an immediate at all — so what CPU 1 does
   with `EXTCS`, if anything, is open and is not claimed here.
4. **Port pin names for IC1, free of charge** (`fig1_ic1_main.png`):
   `P65=MSTAT0`, `P70=MSTAT1`, `P71=SSTAT0`, `P72=SSTAT1`, `P73=LCDOFF`,
   `P74=MUTE`; `TXD0/RXD0 = MIDI1OUT/MIDI1IN`, `P82 = MIDI1SNS`;
   `TXD1/RXD1/SCLK1` = the control-panel link; and the interrupt-side names
   `FS1 FS2 FDMON HDINT FDINT FDRST FDTC FDDRQ HDIORDY SIFINT`.
   ⚠ **This contradicts the disassembly on one point and the conflict must be
   resolved before anything is changed.**  `FINDINGS-interprocessor-link.md`
   reads P7 bit 3 as the link's busy input and records that
   `NMI_PowerFail_SaveAndHalt` sets P7 bits 4 and 5 first thing.  Under the
   schematic P73 is `LCDOFF` and P74 is `MUTE` — and "on power fail, mute the
   audio and blank the LCD" is a far better explanation of that NMI than
   anything the link reading offers.  The four handshake pins the driver says
   are "derived from the firmware and not from a schematic" are
   `MSTAT0/MSTAT1/SSTAT0/SSTAT1`; mapping them onto the firmware's bit tests is
   the obvious next pass and is **not done here**.

   ★★ **CORRECTED 2026-09-03 — THE PIN TABLE ABOVE IS OFF BY ONE ROW, AND THE
   CONTRADICTION IT FLAGS DOES NOT EXIST.** The sheet reads
   `P70=MSTAT0, P71=MSTAT1, P72=SSTAT0, P73=SSTAT1, P74=LCDOFF, P75=MUTE`.
   Pin 1 is `P65`, whose line runs to IC39 and carries **no label**, so the
   first *label* in the column belongs to pin 2 — reading the labels against
   the pins one row high is what produced the table above.

   The firmware settles it three ways, none of them needing the schematic:

   * `ldio P7CR,0x33` (prom_a 0xF8...:4854) makes P7 bits **0, 1, 4 and 5**
     outputs. Under the corrected reading those are exactly
     `MSTAT0, MSTAT1, LCDOFF, MUTE` — the two status lines this CPU asserts
     plus the two control lines. Under the table above they would be
     `MSTAT1, SSTAT0, MUTE`, which makes **SSTAT0 an output** — but `SSTAT0` is
     the SUB CPU's status and must be an input here. The old reading is not
     merely unsupported, it is incoherent.
   * `NMI_PowerFail_SaveAndHalt` sets bits 4 and 5 = `LCDOFF` + `MUTE`, which is
     "on power fail, blank the LCD and mute the audio" under the corrected
     reading too — the good explanation survives the correction.
   * The link's busy test is on bit 3 = `SSTAT1`, an input, exactly as
     `FINDINGS-interprocessor-link.md` reads it.

   ⚠ So the "conflict that must be resolved before anything is changed" was an
   artefact of the misread column, and the disassembly was right all along. The
   crops and the pin/net table are regenerated by
   `kn7000_mame/notes/wsa1-probes/wsa1_sch_cpu_ports.sh`.

   ★ The lesson is the reusable part: **a pin column is an ordered join between
   two lists, and an unlabelled pin silently shifts one of them.** Anchor such a
   table to something independent — here, a control register whose bits say
   which pins are outputs — before quoting it.

---

## TARGET 3 — the `0x104000` register file

### The PART is SETTLED. The REGISTER MEANINGS are NOT, and cannot be from the ROM.

The question was: "can you now specify the register file well enough to write a
real device?"  The honest answer is **no — but for a reason that is worth
having, and the identification underneath it just got much stronger.**

### What is now SETTLED

**`0x104000` is IC3 L7A1429 MODELING LSI.**  `acoustic_modeling.h` currently
carries this as "the project owner's call" over a "ranked inference", and says
in as many words that "*that `0x00104000` DECODES TO IC3 is what the firmware
cannot show*".  The schematic shows it (`fig5_cpu2_decoder.png`,
`fig6/fig7_ic3_l7a1429_*.png`):

* IC27 D74HC139GS, first half: `1E = SCS0`, `1DA = SA14`, `1DB = SA15` →
  `1Y0 = SMIF` (0x100000, the link), `1Y1 = WFICS` (**0x104000**),
  `1Y2 = KSCS` (0x108000, keybed), `1Y3 = SGCS` (0x10C000, tone generator).
  All four of CPU 2's CS0 devices, in the order the disassembly derived them.
* IC3's host port: **`NSGCE ← WFICS`**, **`NAD ← SA1`**, `NWR ← SWR`,
  `NRST ← +5MI`, `MD0..MD15 ↔ SD0..SD15`.
  `NAD ← SA1` *is* the driver's `+0 = address latch, +2 = data`: one address
  line picks address-vs-data.  The interface the disassembly read off the
  instruction stream is the pin.

★ **And the "alternative that fits every number" in `acoustic_modeling.h` is
the right one.**  That file offers two readings — "the PCM part and the
modelling part" versus "the DRIVER and the RESONATOR halves of one engine" —
and says nothing measured separates them.  The schematic does: IC3's
**`RQWFI` and `IOWFI(0..12)`** outputs are the nets **`RQWFI`, `DWFI0..DWFI12`**
that arrive on **IC4's pins 25-40**.  The modelling LSI feeds the tone
generator over a 13-bit bus with a request line.  They are two stages of one
signal path, not two independent voices.

**IC4 is `TC183C230002` "TONE GENELATOR LSI"** (the sheet's own spelling), and
it takes **two** chip selects: `NSGCE ← SGCS` (0x10C000) and
`NKSCE ← KSCS` (0x108000).  So the keybed port the driver models separately is
inside the tone generator LSI, and `KS0..KS3 / KF0..KF3 / KB0..KB4 / LEL / LER`
on its left edge are the key-scan matrix and touch-sense lines.

★ **A hard number for a future sound device:** IC4's crystal `X4` is
**33.869 MHz** (33.8688 = 768 x 44100), so the tone generator's sample rate is
44.1 kHz.  IC4 also carries `LRCK`, `BCK` and `SDO0..SDO7` — **eight** serial
audio output lanes — and two independent 21-bit wave address buses with four
chip selects each (`XA0..XA20`/`XCS0..XCS3`, `YA0..YA20`/`YCS0..YCS3`) reaching
the six 16-Mbit mask ROMs on the MAIN (C)/HP sheet, alongside three
**uPD6383GF-3BA** DSPs — three, which is exactly the number of destinations the
disassembly found for the P7 effect-microcode transport.

IC3's own memory is four 16-bit DRAM ports, `M1`, `M2`, `S1`, `S2`
(`A0..A9`, `NRAS/NCAS/NWE`, `D0..D15`, nets `WM1*/WM2*/WS1*/WS2*`) — the
"SOUND RAM" the strings `"=WSA SOUND RAM S0"` and `"KN3000 SOUND RAM"` in
prom_a refer to.

### The register file, as completely as the firmware states it

From `--dev104`, re-derived from prom_c bytes rather than from the listing:

* **64 channels** (`ldb d,0x40`, prom_c 0xFB8116), register number =
  `block * 0x40 + channel`.
* **19 blocks**, `0x0000` and `0x0040 .. 0x0480` in steps of `0x40` —
  the probe recovers the eighteen `add <rr>,imm16` block offsets from
  `Dev104_WriteAllChanRegs` and they are exactly `0x40..0x480`; block 0 is
  written **last**, from the same struct.
* **staging word for block `k*0x40` is byte offset `2*k`** of a 38-byte struct,
  for all nineteen.
* **19 x 64 + 1 = 1217** distinct registers, which is precisely the count a bus
  trace of the real emulated machine measured
  (`kn7000_mame/tools/rigs/wsa1_dev104_bus_trace.lua`: 2,642 writes, **zero**
  reads, 1,217 distinct registers over `0x0000..0x0800`).  The `+1` is the
  single register `0x0800` written at power-on.
* **Modulated after note-on: blocks 0 and 3..10** (the nine that the seven
  small accessors reach).  **Set only as part of a whole-channel load: blocks
  1, 2 and 11..18.**  On a tone generator that is the boundary between
  per-note-modulated and set-at-note-on parameters.
* **Nothing is per-sample.**  There is no interrupt-rate or DMA writer: the
  only writers are the unrolled whole-channel load (9 call sites) and the seven
  small accessors, all driven from note-on staging and controller refresh.
* **Note-off**: no write to this device is a note-off.  The gate lives on the
  *tone generator*: `reg[0x0080 + ch]` bit 15 is pulsed 1-then-0 around a full
  parameter update, and `0x0800 + ch = 0xFF80` / `0x0840 + ch = 0xFF00` is the
  quiescent pair — all `0x10C000`, and `FINDINGS-prom_c-dev10c-register-
  meanings.md` §6 warns explicitly against importing any of it here.

**Three constant images the ROM holds, printed by `--dev104` and, as far as
this lane can tell, never written down before:**

| what | ROM | contents |
|---|---|---|
| `0x104000` register `0x0800` at power-on | `0xFE1313` | `0x1100` |
| the 19-word image `VoiceRegs_Stage_B` loads into the staging struct — part mode `0x40` runs the modelling LSI **from a constant** | `0xFE1315` | `0004` then 12 x `0000`, then `E150 E150 E150`, then `D71B D71B D71B` |
| `0x10C000`'s 13 global registers at reset | `0xFE12B5` | `006F 0993 0001 0004 0004 0001 0000 0000 0000 0000 0030 0001 0000` |

★ The Stage_B image's shape is itself informative: blocks `0x0340/0x0380/0x03C0`
share one value and `0x0400/0x0440/0x0480` share another.  Two groups of three
identical parameters is the same "three parallel slots" structure the tone
generator's own driver has (`FINDINGS-prom_c-tone-generator.md` §4), so the
modelling LSI's blocks 13-18 are very likely **three resonator sections x two
parameters**.  ⚠ That is a reading of a pattern, not a measurement.

### Why this is still NOT enough to write a real device — and it is not the disassembly's fault

1. **Nothing reads the device.**  2,642 writes, zero reads, in 45 emulated
   seconds.  There is no readback to calibrate a model against, so the firmware
   can tell you *what value* goes to block `k` and *when*, and nothing at all
   about what block `k` **does**.
2. **There is no sibling to borrow from.**  The whole reason `0x104000` was
   identified as the modelling section is that the KN5000 sub-CPU — the
   control group whose tone generator gave `0x10C000` twenty-two of its
   register meanings — has no counterpart device.  The lever that named
   `0x0400` as pitch and `0x0080` as level does not exist here.
3. **Its own memory is undumped and unmodelled.**  IC3 addresses four DRAM
   banks (`WM1/WM2/WS1/WS2`) that the firmware loads; IC4 reads six undumped
   mask ROMs.  A register map without the waveform memory would synthesise
   nothing anyway.
4. **The output does not go to a DAC.**  IC3's product leaves on
   `RQWFI/IOWFI(0..12)` into IC4, so a faithful `l7a1429_device` is not a sound
   device at all — it is a block that feeds the tone generator.  Modelling it
   before IC4 is modelled would be modelling the wrong end.

### What WOULD settle it

* **An L7A1429 or TC183C230002 datasheet.**  Both are Matsushita/Toshiba
  custom parts and neither is likely to exist publicly.
* **Failing that, measurement on Felipe's hardware:** hold one block's value
  and sweep it while capturing the audio, one block at a time.  Nineteen
  blocks x 64 channels is a small enough space that a sweep with a fixed note
  and a fixed tone would name several of them in an afternoon.  ★ This is the
  one place in the whole assessment where the answer is not in any document and
  only the instrument can give it.
* **The `SX-WSA1 TECHNICAL GUIDE`** in `~/compartilhado/KN7000/WSA1R_files/`
  is a user-facing document about the synthesis architecture (driver /
  resonator / etc.).  It will not give register numbers, but it will give the
  *parameter vocabulary*, and 19 blocks is a short enough list that matching a
  named parameter set against it is worth one pass.  Not attempted here.

### What to change in the driver now

* `acoustic_modeling.h` can promote **"0x104000 decodes to IC3"** from
  "what the firmware cannot show" to **established by the schematic**, citing
  IC27 `1Y1 = WFICS` → IC3 `NSGCE`, and can promote the DRIVER/RESONATOR
  reading over the PCM/modelling one, citing `IOWFI(0..12)/RQWFI` → IC4.
  The ranked-inference paragraphs should be kept as the record of how the
  identification was reached without the book.
* `wsa1.cpp`'s TODO list should stop calling the keybed at `0x108000` a
  separate device: `NKSCE ← KSCS` is a second chip select on IC4.
* The tone generator's clock is available: **33.869 MHz**, 44.1 kHz sample
  rate, eight `SDO` lanes.

---

## Summary

| target | verdict from the DISASSEMBLY | verdict overall |
|---|---|---|
| `0x7E0008` | **SETTLED** — ATA task file, seven opcodes, four status bits, plus a FAT16 boot sector for a 261.7 MB fixed disk and the string "This is Technics HDD." | SETTLED; the schematic's `HDCS` and IC1's `HDINT`/`HDIORDY` agree |
| `0x7F0000` | **NARROWED** — write-only on both processors, initialiser uncalled, boot writer feeds it its own return address, refresh task never woken | **NARROWED further**: the decoder output carries no net name, on both processors, for both windows of the one shared driver. Reading: no chip fitted. Settle with the parts list, the foil-side pages, or the machine |
| IC1 MAIN / IC2 SUB | **NOT ANSWERED** — the link protocol is symmetric, no image names a part, a designator is not a ROM fact | **SETTLED by the schematic**: IC1 = MAIN with IC12/IC13; IC2 = SUB with IC28/IC21 |
| `0x104000` | **NARROWED** — 64 channels x 19 blocks fully mapped, note-on/modulated/static split known, constants extracted; **no register meaning is derivable**, because nothing reads it and there is no sibling | part **SETTLED** (IC3 L7A1429, and it feeds IC4); meanings need a sweep on real hardware |

★ And the lesson this lane would put in front of the next one: **the question
"does the disassembly answer this?" was the wrong question for two of the
three.**  Both were answered by a document already sitting in
`~/compartilhado/KN7000/service_manual/`, which every text search had reported
as empty because it has no text layer.  Before the next "what artefact would
settle this", render the pages.
