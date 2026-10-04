# prom_a 0xFE0000-0xFE54B6: naming the disk / block-device COMMAND layer

**w30, 2026-09-05.** The module header at 0xFE0000 says in as many words that the
21,686-byte span was converted to assembly but "almost every label in it is
`sub_XXXXXX`, which is an ADDRESS, not a claim … The naming work is the next
round's, not this one's." This is that round's first instalment: **13 routines
named, the rest deliberately refused.**

Every number below is re-derived from `prom_a/wsa1_prom_a.s` by
`python3 notes/prom_a_disk_cmd_layer_checks.py --selftest` (8 checks + 1
control, all passing). Run it before quoting anything here. The rename map is
`notes/prom_a_disk_cmd_layer_rename.map`; both byte gates and the comment gate
are green (see the end).

## Why this subsystem

It is the layer directly ABOVE the already-named FDC driver (`Fdc_Request`,
0xFE66C7) and BELOW the UI — the disk stack the MAME driver needs names for. It
is the preferred kind of target (emulation-relevant, disk), it is the subsystem
four findings files already give evidence for
(`FINDINGS-prom_a-fdc.md` for the request-block layout and `Fdc_Request`;
`FINDINGS-prom_a-disk-format.md` §4/§6 for the operation census, the ready flag
and the result byte; `FINDINGS-prom_a-portb-and-blockdev-entry.md` §2 for the
18-slot public API; `FINDINGS-prom_a-ring-buffers.md` §6 for the extent), and it
is still overwhelmingly `sub_XXXXXX`: **280 of 293** module labels before this
pass. It is neither the UI screen-object vtable subsystem (w29) nor the
tone-editor families (w21/w23).

## The request-block layout this pass leans on

`Fdc_Request`'s own header documents the 16-byte block it consumes:
`+0 op(0..11) · +2 unit · +4 head · +6 track/media · +8 sector · +A count ·
+C long buffer`. Operation meanings come from the census in
`FINDINGS-prom_a-disk-format.md` §4: **0** reset+identify media, **3** READ
SECTORS, **4** WRITE SECTORS, **5** FORMAT, **10** test controller present,
**11** SENSE DRIVE STATUS. A routine that writes a constant to block offset +0
and then reaches `Fdc_Request` is therefore issuing a *named* operation — that is
the decisive, checkable evidence behind the four builder names.

## Named (13)

### The two command cores' entry seam (0xFE3000-0xFE30D7)

The module publishes both cores through a `jp`-slot table at 0xFE3000 (4-byte
stride). Each published slot jumps to a trampoline; two trampolines save the
caller's registers to a fixed scratch block, invoke the core, and restore them.
All of this is register save/restore around a `call`/`jp` to a named core — pure
mechanism, checkable line by line.

| new name | was | role |
|---|---|---|
| `Fdc_Request_SaveRegs` | sub_FE308D | save XIX/XIY/XBC/XDE/XHL to 0x605D84, call `Fdc_Request`, restore |
| `Fdc_Request_Thunk` | sub_FE3032 | push block ptr, call `Fdc_Request` (no reg save) |
| `Disk_CommandDispatch_SaveRegs` | sub_FE3042 | save regs to 0x605D70, call `Disk_CommandDispatch`, restore |
| `Disk_CommandDispatch_Thunk` | sub_FE3020 | push args, call `Disk_CommandDispatch` |
| `Fdc_Request_SaveRegs_Entry` | sub_FE3018 | published jp slot (T_Fdc_Request_SaveRegs_Entry, 17 sites) |
| `Fdc_Request_Thunk_Entry` | sub_FE3004 | published jp slot (T_Fdc_Request_Thunk_Entry, 0 callers) |
| `Disk_CommandDispatch_SaveRegs_Entry` | sub_FE3014 | published jp slot (T_Disk_CommandDispatch_SaveRegs_Entry, **23 sites**) |
| `Disk_CommandDispatch_Thunk_Entry` | sub_FE3000 | published jp slot |

### The second command core

`Disk_CommandDispatch` (**was sub_FE426E**) is the module's own command
dispatcher, distinct from `Fdc_Request`: it reads a command code from
`(XSP+0x04)` and routes it through a word-offset jump table (offsets at
0xFE6DFE, base 0xFE42B4) to ~19 handlers. It is the busiest published entry into
the module (T_Disk_CommandDispatch_SaveRegs_Entry, 23 call sites). ⚠ **The individual handlers are NOT named**
— see the refusal below.

### The FDC-request builders

| new name | was | operation | evidence | calr callers |
|---|---|---|---|---:|
| `Disk_ReadSectors` | sub_FE442E | 3 READ SECTORS | 0xFE4443 writes 0x0003 to block +0; 0xFE444A call `Fdc_Request` | 15 |
| `Disk_WriteSectors` | sub_FE4452 | 4 WRITE SECTORS | 0xFE4467 writes 0x0004; 0xFE446E call `Fdc_Request` | 9 |
| `Disk_RequestSenseDriveStatus` | sub_FE0755 | 11 SENSE DRIVE STATUS | 0xFE075B writes 0x000B; 0xFE077E via `Fdc_Request_SaveRegs` | 5 |
| `Disk_SetRequestGeometry` | sub_FE4399 | — (helper) | LBA→CHS: `div ..,(0x605D68)` at 0xFE43E6/F2, stores to block +6/+4/+8/+A/+C | 2 |

`Disk_SetRequestGeometry` is the shared setup that `Disk_ReadSectors` and
`Disk_WriteSectors` both call (its only two callers) to convert a logical sector
number to the block's head/track/sector fields using the drive geometry at
0x605D54/0x605D68/0x605D6A/0x605D98.

## Refused (280), and the measured reason

The other 280 labels in 0xFE0000-0xFE54B6 stay `sub_XXXXXX`. They fall into two
groups, and neither can be named honestly yet:

1. **Handlers of `Disk_CommandDispatch`.** Reached only through its word-offset
   jump table; each manipulates the 0x605Axx disk state and eventually reaches
   `Fdc_Request`, but nothing here ties a command index to a user-visible
   operation. Naming the dispatcher does not name what it dispatches.
   **Superseded 2026-10-04.** The command codes ARE the tie. Decoded from the word-offset
   table at 0xFE6DFC (base 0xFE42B4), the handled codes are 0x0F-0x13, 0x16, 0x1A, 0x1B and
   0x80-0x85, and 0x14/0x15/0x17-0x19 fall to the default case. Those are MS-DOS INT 21h's FCB
   function numbers. The anchor is 0x1A: its handler only stores the transfer-buffer pointer
   (0x605D2C), which is DOS "Set Disk Transfer Address". Each name was then checked against
   its body, and the evidence per routine is in `notes/prom_ab_read_names_2026_10_04.py`:
   `DiskCmd_OpenFile` (0x0F), `_CloseFile` (0x10), `_FindFirst` / `_FindNext` (0x11/0x12),
   `_DeleteFile` (0x13, repeats while the name has a wildcard), `_CreateFile` (0x16),
   `_SetTransferAddress` (0x1A), `_CheckMediaId` (0x1B), and the extensions `_CountFreeSpace`
   (0x80), `_ReadSectors` / `_WriteSectors` (0x81/0x82), `_ReadFileBlock` / `_WriteFileBlock`
   (0x83/0x84). Under them is the FAT layer: `Fat_GetEntry` / `_SetEntry` (FAT12 and FAT16),
   `Fat_Load` / `_Store`, `Fat_ClusterToSector`, `Fat_FindFreeClusterFrom` / `_After`,
   `Fat_DeleteFileAndFreeChain`, and the cluster and root-directory sector readers and writers.
   Still `sub_`: 0x85 (0xFE423E) and the code-0 case (0xFE370A).
2. **File-system workers.** Compound routines (e.g. `sub_FE08BD` pulses Port B
   bit 2, clears/sets the ready flag `(0x21E7).6` from the result byte
   `(0x1735)`; `sub_FE1962` invokes dispatcher command 0 with a fixed argument)
   whose *purpose* the source does not state. `FINDINGS-prom_a-portb-and-blockdev-entry.md`
   §1 explicitly declines to say what the Port B bit-2 pulse even does — so a
   name like "reset" would be a guess, not a reading.
   [Named 2026-10-03: `(0x21E7)` is `Disk_Flags` in `wsa1/include/wsa1_ram.inc` -- only its
   bit 6, the ready flag, is established; 91 operands.]

### The control that makes the refusal a measurement, not a mood

`prom_a_disk_cmd_layer_checks.py --selftest` asserts that the routine physically
adjacent to `Disk_ReadSectors` — `Disk_SetRequestGeometry` — writes **no**
operation field. An "name a routine from its neighbour" rule would therefore have
called a geometry-setup routine "read". The check fails (exit 1) if that ever
stops being true, so the discipline is pinned, not merely asserted.

## An existing name I did NOT change but flag

`Disk_FormatSelectedMedia_Veneer` (0xFE0039) is correctly named. No wrong
existing name was found in the module.

## Cross-file blast radius handled

The rename of `sub_FE426E` reached two notes that referenced it by its old
address: `notes/FINDINGS-prom_a-gap-T-pa3.md` line 113 and
`notes/prom_a_pa3_census.py` line 338 — both updated to `Disk_CommandDispatch`.

## Gates

* **BYTE:** `make -C wsa1 all LLVM_MC=…/llvm-mc.snap` + `cd wsa1 &&
  python3 scripts/analysis/assert_byte_identical.py` → **PASS**, all four WSA1R
  ROMs byte-identical.
* **COMMENT:** `python3 scripts/analysis/assert_comments_preserved.py --base main
  --rename-map notes/prom_a_disk_cmd_layer_rename.map wsa1/prom_a/wsa1_prom_a.s`
  → **PASS**, +142 comments, none altered.
