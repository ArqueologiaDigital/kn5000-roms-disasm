# Where the C `field_` debt is (2026-10-03)

**Question:** the NAKA class system names every field of a class record (`propname`,
`scripts/analysis/nakarest_objtab_map.py`).  Can the ~18,000 `field_` / `pad_` occurrences per
maincpu tree (the dashboard's `field` column) take those firmware names?

**Answer: mostly not.**  `probe_records.py` walks each `naka_*.c` blob for class records and counts
the struct's top-level `field_XXXX` members inside them.  v10 (`v10.txt`): of 792,654 blob bytes,
125,820 are class records, and of 6,296 `field_` declarations only **239** fall inside a record.
The big files are other data: `naka_sequencer_channels.c` is the work-RAM image that
`Boot_InitWorkRAM` copies to RAM 0x3D524 / 0xE35E (its fields are RAM variables' initial values;
naming them needs the KN5000 RAM variables named first), and `naka_disk_warning.c`,
`naka_extension_device.c`, `naka_style_bitmaps.c`, `naka_technichord_strings.c` hold constant
pools and tables whose layouts come from their readers.

Also found: the work-RAM image's member boundaries were cut by byte pattern, not by the real
layout -- the dial callback table at RAM 0x3EF50 (`../technics-docs/data-wheel-investigation.md`)
has its 32-bit callbacks split into two `uint16_t` NONE halves.  Typing a region means re-typing
the members, not renaming them.

    python3 notes/naka-fields-2026-10-03/probe_records.py v10 > notes/naka-fields-2026-10-03/v10.txt
