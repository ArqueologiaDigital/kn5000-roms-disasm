# Addendum to `README-lsw-drawbar-records.md`: tag `0x71` is a PER-PANEL-MEMORY bit

Written minutes after the main note, because a commit landing in parallel
(`f35f452`, `analysis/disk-format-probes/lsw_region_to_block_map.py`) answered the last
item on that note's "what would settle it" list. Kept as a separate file only because
this pass was told to create files and never to edit one; **read it as the closing
paragraph of `README-lsw-drawbar-records.md`, not as a separate finding.**

## What changed

The main note reported, as the strongest thing it could prove about tag `0x71`:

> The third grid arm does `bit 1,(0x1ED400 + index*0x3C0 + 0x38C) / jr Z` and picks between
> `0xE8013E` `" ON  "` and `0xE80144` `" OFF "`. … the byte it reads is tag `0x71` payload+0
> inside a **960-byte-strided array at `0x1ED400`**, not the live panel.

and listed as the third thing that would settle it:

> Identify the `0x1ED400` array (960-byte stride) and its element count.

`f35f452` identifies it, from a completely different route — the `.LSW` format-2 importer, which
reads 0x300 bytes per slot from file offset 0x0680 into `0x1ED400 + 960*j`, bracketed by the
factory-test entry points `PrePmLoad` / `PostPmLoad`:

    0x1ED400 + 960*j   is PANEL MEMORY slot j.  80 slots: (0x200000 - 0x1ED400) / 960 == 80 exactly.

The two derivations meet on the arithmetic, and it is checkable in one line:

    block 0 of the panel TLV spans 0xF9A0..0xFD60      -> 0xFD60 - 0xF9A0 = 0x3C0 = 960
    tag 0x71's payload sits at 0xFD2C                  -> 0xFD2C - 0xF9A0 = 0x38C

So the grid arm's `0x1ED400 + index*0x3C0 + 0x38C` is not "a field in some array". It is
**tag `0x71` payload+0 of panel memory slot `index`**, and a panel-memory slot is exactly TLV
block 0.

## What that upgrades

| claim | before | now |
|---|---|---|
| the three `PmemOutLGridCheck` arms set / clear / display bit 1 | [CODE] | unchanged |
| the byte they address is tag `0x71` payload+0 | [CODE], of an unidentified array | [CODE], **of panel memory slot `index`** |
| the grid is a panel-memory grid | [NAME] only (`AcPmemOutLGridBox`) | [CODE] — the address arithmetic says so |
| what the bit *is* | not determined | **a per-panel-memory ON/OFF flag**, one per slot, drawn as ` ON  ` / ` OFF ` |

Combined with the main note's last proven site — `bit 1,(0xFD2C)` in
`BitMapOut_Snapshot_PostProcess` (v9 `0x00FB4631`), which gates `BitMapOut_DispatchIOChanges`, which
re-posts payload `+14`/`+15`/`+17` of parts `0x00`/`0x01`/`0x02` = RIGHT 1 / RIGHT 2 / LEFT — the
mechanism is complete end to end:

* the bit is stored **per panel memory**, in that slot's copy of tag `0x71`;
* the user toggles it on a panel-memory grid, where it reads ` ON  ` / ` OFF `;
* when a panel memory is recalled into the live panel, the live copy at `0xFD2C` is what
  `BitMapOut_Snapshot_PostProcess` tests, and bit 1 decides whether RIGHT 1 / RIGHT 2 / LEFT's
  stored `+14`/`+15`/`+17` are re-emitted.

## What is STILL not determined — say it plainly

* **The name the instrument gives the toggle.** ` ON  ` / ` OFF ` is the cell's text, not a label.
  The KN7000's equivalent widget, whose labels are plain ASCII, is the cheap way to get it; a
  KN5000 in front of you is the certain way.
* **Bit 0** of the schema's `mask 0x03`. No instruction in v7, v9 or v10 reads or writes it, and no
  parameter id names it. The census in `lsw_drawbar_records.py` D9c is what says so, and it is the
  same census that finds all five sites for bit 1 — so it is not a search that cannot see.
* **Payload bytes `+1` and beyond.** The KN5000 record is 2 bytes; the descriptor list at
  `0xED8DFE` declares four; the disk files carry four. Nothing reads `+1..+3` in any dumped image.

## Independent agreement worth recording

`f35f452` locates the ROM's factory-default panel image at `0xEDB3DC` (header
`5A 5A 00 00 48 4B …`, `"HK"` at +4). `lsw_drawbar_records.py` D7 found the same image from the
other end — by walking a TLV stream against the schema — and lands on `0xEDB3FC`, which is
`0xEDB3DC + 0x20`, the byte after that 32-byte header. Two searches with nothing in common
agreeing on one address.

Reproduce everything above with:

```
python3 analysis/disk-format-probes/lsw_drawbar_records.py --lsw-dir /tmp/disk
python3 analysis/disk-format-probes/lsw_region_to_block_map.py
```
