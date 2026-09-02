# Does the completed disassembly give new insight for improving the drivers?

**Yes — and the single most valuable finding was not in the disassembly at all.**

Four lanes cross-checked the now-complete disassembly (all 13 gated images at
zero verbatim debt) against the MAME drivers in `~/compartilhado/kn7000_mame`.
Per-lane detail: `DRIVER-INSIGHT-wsa1-2026-09-02.md`,
`DRIVER-INSIGHT-kn5000-2026-09-02.md`, `DRIVER-INSIGHT-dsp-2026-09-02.md`,
`DRIVER-INSIGHT-promd-base-2026-09-02.md`.

## What "full disassembly" actually bought

Not new behaviour — the firmware always did what it does. What changed is that
**negative results became sound.** Every question of the form "does the firmware
ever touch X?" used to carry an implicit *"…except in the bytes we haven't
decoded."* That caveat is gone, so exhaustive claims are now possible, and three
of the findings below are exhaustive claims.

⚠ It bought less than it sounds like, in one specific way: zero **verbatim** debt
is not full understanding. Code-as-`.byte` and data-as-code remain, semantic
labelling was deferred throughout, and a register the firmware writes is still
not a register whose meaning we know.

## ★★★ The fidelity bug: every pedal reads as pressed

The KN5000 main CPU's **Port G has a comment block and no `portg_read()`
binding**, so it returns `0x00` forever. The firmware scans it three times per
periodic tick and its own idle test is **`upper nibble == 0xF`** — the pins are
active-low, and `0x00` is the *all-engaged* encoding.

So the emulated instrument has both foot switches and all four foot controllers
**permanently pressed**. Fix: `set_ioport("PEDALS")`, released = `0xFC`.

This is the shape of finding the exercise was for: not a discovery about the
hardware, but a **behavioural divergence nobody could see** until the firmware's
own idle test was legible.

Two more of the same shape:

* **PE.0 is hard-coded to "no extension"**, so a fitted HD-AE5000 is invisible to
  the firmware and the ATA/PPI/ROM it maps are unreachable.
* **`custom_data`, `table_data` and the card's IC4 are AMD-command-set flash**,
  identified on every boot by `Flash_InitAllBanks` with accepted IDs
  (0x2223/0x22AB/0x22D6/0x2258) that also select the erase sector map. All three
  are `.rom()`, so the firmware-update path cannot work.

## ★★ The methodological finding, which has now cost us twice

**The service manuals are image-only PDFs.** `pdftotext` returns nothing;
`grep` returns nothing; **neither is evidence of absence.** Rendered, the WSA1R
manual's pages 19–23 are legible P.C. diagrams naming every chip-select decoder
output.

The KN5000 work already lost nine rounds to this exact trap, hunting the ROM for
a map printed on page 32 of its own manual.

Rendering it settled, in one lane, what months of firmware analysis had not:

| question | answer |
|---|---|
| `0x7E0008` | an **ATA (IDE) task file** — IC18 Y6 = `HDCS`, IC1 has `HDINT`/`HDIORDY`; `prom_a` holds a FAT16 boot sector for a fixed disk, 568 cylinders, reading **"This is Technics HDD."** ⚠ decode is **A0–A2**, not PC-style A1–A3 |
| `0x104000` | **IC3 L7A1429**, via IC27 `1Y1 = WFICS` — promoting `acoustic_modeling.h`'s ranked inference to established, and deciding the alternative it left open: IC3 feeds IC4, so they are two halves of one path |
| IC1 / IC2 | **IC1 = MAIN, IC2 = SUB.** No ROM can name a designator; only the document could |
| `0x7F0000` | probably **no chip fitted** — and the evidence is an *absence*: it and `0xE00000` are the only decoder outputs the firmware writes that the schematic leaves unnamed |

## What the disassembly could NOT do, stated plainly

* **A real `0x104000` device.** 2,642 writes, **0 reads**, no sibling to borrow
  meanings from, wave DRAMs unmodelled. Settling it needs a per-block sweep on
  real hardware with a fixed note.
* **A real µPD6383GF device.** The *bus* is now specifiable — enough for a device
  that latches traffic, answers the handshake and lets both machines boot — but
  it would make **no sound**: the instruction set is 13.4% decoded and the chip's
  control registers are unmapped.
* **The KN7000 floppy defect.** It is an MN10300 problem and *that* disassembly
  is at **3.64%**. The completed images are the KN5000's and cannot adjudicate it.

## ⚠ Four things we believed that are wrong

1. **ERROR 08 names no decision point.** It is `FmmFormatFunc`'s *default*
   message number — any result absent from the table at `0x00EA067C` yields it,
   and the format worker's own `-6` maps to 8 too. It means "the format returned
   failure" and nothing more. Several KN7000 notes reason as if 8 named a branch.
2. **SIO channel 2 really is MIDI.** A documentation review called four such
   comments stale; it had them **inverted** — the `:763` "CPSD link" header is the
   stale half. The SD card goes through the `0x9805000C` mailbox.
3. **The "231 of 234 identical bytes" is not a DSP driver.** It drives a
   board-level 4-channel × 32-register file, on **two** processors, not four.
4. **`wsa1.cpp` carries three stale comments about prom_d's base**, including one
   40 lines above the `map()` that contradicts it. The base is **`0x00F00000`**,
   established twice over from the readers; `0xE80000` is the separate, undumped
   AM29F400T flash.

## The pattern worth keeping

Every one of the four lanes found the driver and the disassembly **drifting past
each other** — each carrying corrections the other had not absorbed, in both
directions. The disassembly reaching completion is what made the comparison
worth doing; it is not what produced most of the answers.
