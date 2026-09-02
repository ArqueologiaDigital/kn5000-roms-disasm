# `driver_insight/` — the artefacts behind `notes/DRIVER-INSIGHT-wsa1-2026-09-02.md`

Two files, one question each.

## `driver_insight_probes.py`

*What question does it answer?*  Three, one per section, all from the raw
EPROM images in `wsa1/original_ROMs/` — never from the `.s` listings, so a
mistake in the disassembly cannot make one of these numbers agree with it.

| flag | question |
|---|---|
| `--hdd` | Does the ROM itself say what the unit-1 block-device back end at `0x7E0008` is?  Decodes the FAT16 BPB at prom_a `0xFE69BF`, checks its geometry against the ATA INITIALIZE DEVICE PARAMETERS operands and the `0xFE31xx` compares, and locates the boot-code strings. |
| `--dev7f` | How much of the traffic to the 4x32 register files at `0x7F0000` (CPU 1) and `0x00E00000` (CPU 2) is reachable?  Counts `ld <Xrr>,imm32` sites naming each base, then `call`/`jp` (abs24) and `calr` (disp16) references to every entry point that drives them. |
| `--dev104` | What constants does the firmware put into the `0x00104000` register file, and does the unrolled writer really span 19 blocks?  Re-derives the block ladder of `Dev104_WriteAllChanRegs` from the bytes and dumps the three ROM images the reset and Stage_B paths hand out. |

Exact command, from the repository root:

    python3 wsa1/notes/driver_insight/driver_insight_probes.py --selftest

36 checks, 0 failures.  Six of them are controls and they matter:

* the "This is Technics HDD." string must be **absent** from prom_b and prom_c;
* prom_a must **never** name `0x00E00000` and prom_c must **never** name
  `0x007F0000` — the two nulls that make the 5-site / 3-site counts meaningful;
* `Fdc_Request` must score **8** callers, or the xref scanner's zeros prove
  nothing;
* `Dev10C_WriteGlobalRegs` must form **no** register number by adding, or the
  block-ladder recovery would find ladders everywhere.

## `render_service_manual_crops.sh`

*What question does it answer?*  Which chip and which address the SX-WSA1R
schematic puts on each chip-select — and whether that agrees with the addresses
the disassembly derived from the firmware alone.  The findings note reads eight
crops **by eye**; this is the recipe that puts the same pixels in front of the
next reader, so the reading can be checked rather than trusted.

    sh wsa1/notes/driver_insight/render_service_manual_crops.sh /tmp/crops

⚠ Its input is **not in this repository**: `SX-WSA1R Service Manual.pdf`,
ORDER NO. EMiD951604, in `~/compartilhado/KN7000/service_manual/`.  It is
image-only — `pdftotext` returns nothing — which is why every text search over
it had reported it as having nothing to say.  Needs poppler's `pdftoppm` and
python3-pil.  The script's comments record what each crop shows.
