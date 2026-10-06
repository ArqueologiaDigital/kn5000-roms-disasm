# Port B is not a second motor line, and where the disk stack is entered from

Wave 6 round 3, 2026-08-25. Two things the emulation lane asked for, both
re-derived by `python3 notes/prom_a_portb_and_blockdev_census.py` — **15 checks,
0 failures**, `--selftest` fires 3 negative controls. The byte gate
(`python3 scripts/analysis/assert_byte_identical.py`) proves the source these
numbers are filtered against rebuilds the exact ROMs and is blind to every
sentence here.

---

## 1. Gap T / gap U: the complete Port B writer census, and a correction

`notes/FINDINGS-prom_a-gap-T-pa3.md` §5 records PB bit 2 as *"a 307 ms HIGH
pulse issued once, immediately after the PA bit 3 assert"*. **It is issued at two
sites, and the two pulses are not the same shape.** Every Port B access that is
an instruction of the converted prom_a source — 9 of 104 byte-pattern hits:

| addr | instruction | bit | what follows |
|---|---|---|---|
| 0xF82884 | `bit 0,(PB)` | 0 | the model strap; **a read**, already documented |
| 0xFE08C8 | `set 2,(PB)` | 2 | `Delay_150Ticks` — **307 ms** |
| 0xFE08CE | `res 2,(PB)` | 2 | **nothing** — `res 6,(0x21E7)` next, no delay |
| 0xFE2F3A | `set 2,(PB)` | 2 | `Delay_Ticks(2)` — **4 ms** |
| 0xFE2F43 | `res 2,(PB)` | 2 | `Delay_Ticks(5)` — 10 ms settle |
| 0xFE594C-0xFE5960 | `PortB3_Pulse` | 3 | five NOPs; the TC inference (gap U) |

★ **Only bits 0, 2 and 3 of Port B are ever touched**, bit 0 only read. That is
the whole port, and it is the thing gap U's argument needed in order to be
checkable.

★ **PB bit 2 is not a motor and not a level.** A motor line is a LEVEL held
across an operation — which is exactly what PA bit 3 is (cleared at the head of
a block-device operation, set again on every exit path). PB bit 2 is a PULSE,
and the same bit is pulsed **307 ms** at one site and **4 ms** at the other, a
factor of 75. Nothing is driven for 4 ms to spin a disk up. A set/wait/clear
pulse of two very different widths, each at the head of a routine, is the shape
of a **reset or a strobe**.

⚠ **What it is wired to is still not established**, and this note does not
claim it. What it removes is a candidate: after this, **PA bit 3 is the only
LEVEL output the disk stack drives**, so if the emulated drive is to become
ready, PA bit 3 is the only firmware-side line that can do it. That is the
answer to "find what actually gates drive-ready" that the ROM can give:
*nothing else in the firmware is a candidate*.

**Where the second site is.** `Disk_InitDriveAndNameEntry` — pulse PB2 for 4 ms, wait 10 ms,
call 0xFE2EF2, then fill eleven bytes at RAM 0x21C8 with 0x5F and call 0xFE1774.
It is in the 0xFE2F00 neighbourhood of the disk-request module, not in the
0xFE08BD block-device head. So the two sites are in different layers, which is
another reason to read the bit as a reset the two layers share rather than as
one operation's line.

---

## 2. Gap V: the block-device layer is entered from prom_b through 18 slots

Gap V asks *"how does a user reach `Fdc_Request` at all?"* and points at "the
0xFE3000 module's entry directory". **That is the wrong door**, and this is the
measurement that says so.

**64 slots** of prom_b's 0xF4xxxx thunk directory target prom_a's block-device
half (0xFE0000-0xFE7FFF). The two that name the 0xFE3000 disk module are
`T_Disk_CommandDispatch_SaveRegs_Entry` -> 0xFE3014 (23 call sites) and `T_Fdc_Request_SaveRegs_Entry` -> 0xFE3018 (17). **Every
one of those 40 call sites is inside 0xFE0000-0xFE7FFF itself** — the disk module
has no caller outside prom_a's own block-device half at all.

The door is one level up. **18 of the 64 slots have a prom_b caller**, and those
are the UI's way in:

| slot | prom_a target | prom_b call sites |
|---|---|---|
| `T_BStore_Workspace_StoreParamImage` | 0xFE1BCE | 6: 0xF44098, 0xF44A33, 0xF4525E, 0xF6AA32, 0xF73B20, 0xF7C5F6 |
| `T_F42578` | 0xFE1BDE | 7: 0xF44882, 0xF44934, 0xF45132, 0xF56534, 0xF6AEE0, 0xF6F521, 0xF6F83D |
| `T_Medley_NormFileCommand` | 0xFE152E | 5: 0xF44A92, 0xF44AD3, 0xF661DF, 0xF66241, 0xF6649D |
| `T_F42580` | 0xFE1C16 | 2: 0xF662EA, 0xF662F2 |
| `T_DiskApi_ReadFileToWindow_Entry` | 0xFE1C3A | 8 |
| `T_DiskApi_WriteFileFromWindow_Entry` | 0xFE1C4D | 9 |
| `T_DiskApi_DeleteFile_Call` | 0xFE1C55 | 10 |
| `T_DiskLoadFile_Execute` | 0xFE1C79 | 2 |
| `T_DiskSaveFile_Execute_Entry` | 0xFE1C80 | 1 |
| `T_DiskApi_CloseFile_Call` | 0xFE1CAF | 4 |
| `T_DiskSave_CheckFreeSpace` | 0xFE1CB3 | 3 |
| `T_Disk_PortA3_Release_Entry` | 0xFE1CC4 | 1: 0xF66159 |
| `T_Var2216_SetW145C_Call` | 0xFE1CD4 | 2 |
| `T_DiskProgress_PrintDotForSmf` | 0xFE1CD8 | 8 |
| `T_Medley_AdvanceInternalSong` | 0xFE7927 | 1: 0xF44AA3 |
| `T_Medley_Start` | 0xFE7800 | 1: 0xF661BF |
| `T_Medley_Stop` | 0xFE782C | 1: 0xF6622A |
| `T_Medley_Next` | 0xFE7848 | 1: 0xF66480 |

The script prints every site; the table above abbreviates the long rows.

**What this is worth to the emulation lane.** Gap V's practical form is "put a
breakpoint somewhere that a user action reaches". These 74 prom_b addresses are
that somewhere: they are the only places in the UI image that call into the
block-device layer, and they cluster in four prom_b neighbourhoods —
0xF440xx-0xF452xx, 0xF56xxx-0xF66xxx, 0xF6Axxx-0xF6Fxxx and 0xF73xxx-0xF77xxx.
A trace that never reaches one of them never gets near the drive.

⚠ **What is NOT established.** Which menu each of those 74 sites belongs to. All
74 are `sub_XXXXXX` in prom_b's source, and naming them is prom_b's lane, not
this one. And the call-site scan is opcode-anchored, so it is an **upper bound**:
an 0x1B/0x1D byte inside data can fake a site. The 40 sites of the two 0xFE3000
slots were cross-checked against the converted prom_a source; the prom_b sites
were not.

---

## 3. What this pass did not do

* It did not identify what PB bit 2 resets. The two callers, `Disk_MountFloppyWithRetry` and
  `Disk_InitDriveAndNameEntry`, are both still `sub_`.
* It did not name any of the 74 prom_b entry sites.
* It did not touch gap A or gap O.
