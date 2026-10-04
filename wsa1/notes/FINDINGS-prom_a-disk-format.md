# prom_a 0xFE69BF-0xFE7FB1: the disk FORMAT module, four filesystem templates,
# and a hard disk nobody has mentioned before

Wave 6, 2026-08-25. 5,340 substantive bytes converted; the byte gate passes.

Two emulation gaps sent this pass here and both move:

* **Gap T** ("what does CPU 1's PA bit 3 drive?") gets a **prior question answered
  NO**: no code path in either image ever asks for the FDC operation that touches
  PA bit 3. §4. ⚠ The CONCLUSION §4 drew from that — "nothing in this firmware
  ever changes it", "gap T is a hardware question" — is **RETRACTED**; §4 now
  carries the retraction and `notes/FINDINGS-prom_a-gap-T-pa3.md` the answer.
* **Gap V** ("how does a user reach `Fdc_Request` at all?") gets **most of its
  answer**: through the disk FORMAT function, which is here, in full. §3.

And one gap gets an unexpected present: **gap J** ("what is the device at
0x7E0008?") now has a candidate with a name on it — §2.

Reproducibility: `python3 notes/prom_a_disk_format_checks.py` (46 checks, all
from the ROM image rather than the source text) and
`python3 notes/prom_a_fdc_operation_census.py` (**9** checks — one more than the
8 this line used to claim, added by the §4 retraction). Both exit non-zero on
failure and both are in this repository. The gap-T material has moved to
`notes/FINDINGS-prom_a-gap-T-pa3.md` / `notes/prom_a_pa3_census.py`.

---

## 1. How the target was picked, and why it was the right one

`notes/prom_a_xref.py 0xF42D38` — the prom_b directory slot that publishes the
FDC request veneer `0xFE3018` — returns 17 call sites, and **16 of them fall
inside 0xFE725B-0xFE75BC**, a stretch that was still `.incbin`. That is the
densest concentration of disk traffic anywhere in either image, and
`notes/FINDINGS-prom_a-fdc.md` had already established what the callee does.
So the callee was understood and its busiest caller was not.

The unconverted stretch turned out to run further back than the call sites: from
`FP_UnsignedDiv`'s last `ret` at 0xFE69BE to the module pad at 0xFE7733, broken
only by the four FDC jump tables at 0xFE6E3A-0xFE6E84 that a previous wave had
already converted. The whole of it is now assembly.

## 2. 0xFE69BF-0xFE6DBF is an x86 boot sector and an x86 master boot record

This is the surprise of the pass, and it is not a resemblance argument — it is
arithmetic that closes.

**`DiskImage_HardDisk_BootSector` (0xFE69BF, 512 bytes)** is a DOS **FAT16** boot
sector. Every BIOS Parameter Block field is in its standard place, `EB 3C 90` at
the front and `55 AA` at +0x1FE, filesystem type `"FAT16   "`, OEM name
`" EMID2.0"`, and:

| field | value | field | value |
|---|---|---|---|
| bytes/sector | 512 | media descriptor | **0xF8 — FIXED DISK** |
| sectors/cluster | 8 | sectors/FAT | 250 |
| reserved sectors | 1 | sectors/track | 60 |
| FATs | 2 | heads | 15 |
| root entries | 512 | hidden sectors | 60 |
| total sectors (16) | 0 | total sectors (32) | 511140 |
| BIOS drive number | **0x80 — first hard disk** | ext boot signature | 0x29 |

★ **The check that makes it a decode:** 511140 + 60 hidden = **511200 = 568 × 15
× 60 exactly** — a whole number of cylinders on the geometry the same sector
states. Capacity 511200 × 512 = **261,734,400 bytes, ~250 MiB**.

Its boot code carries three strings, and one of them is not generic:

```
Non-System disk or disk error
This is Technics HDD.
```

**`DiskImage_HardDisk_MBR` (0xFE6BBF, 512 bytes)** is the matching master boot
record — the textbook `CLI / XOR AX,AX / MOV SS,AX / MOV SP,0x7C00` preamble, the
0000:0600 relocation, the strings *"Invalid partition table"*, *"Error loading
operating system"*, *"Missing operating system"*, and ONE partition entry:

* type **0x06** (FAT16 over 32 MB), not bootable;
* LBA start **60** — the boot sector's hidden-sector count;
* length **511140** — the boot sector's total-sectors-32;
* end CHS **head 14, sector 60, cylinder 567** — the last sector of a 568×15×60
  disk, reached through a completely different encoding (the two high cylinder
  bits ride in the sector byte).

Three independent statements of one geometry, in two sectors written years apart
from each other by whatever tool built them. Nothing here is inferred.

### ★ What this says about emulation gap J, and what it does not

Gap J asks what the second storage unit at `0x7E0008` IS — `Fdc_Request` is a
**two-unit** block-device layer, every operation branches on `(0x605A32) == 1`,
and the unit-1 arms all reach that port. This ROM turns out to contain a boot
sector for a **fixed disk** and an MBR for the same disk, and a string that says
*"This is Technics HDD."* That is the first thing in either image to name a hard
disk at all.

⚠ **It is evidence, not proof, and the missing link is named:** **no consumer is
located.** Two searches were run and both came back empty —
`notes/prom_a_xref.py` on 0xFE69BF, 0xFE6BBF and 0xFE6DBF, and a raw scan of
prom_a *and* prom_b for those three little-endian address bytes. Nothing in
either image copies these 1024 bytes anywhere. So the ROM carries hard-disk boot
images; whether this firmware can format a hard disk is **not** established
here, and a wave that finds the consumer (or proves there is none) settles it.

**0xFE6DBF-0xFE6E3A** is 123 further bytes, emitted as `.byte`. 123 is odd, so
the block is not a whole number of 16-bit words on any alignment, and no reader
is located. Recorded as an observation only: read as words from the *second*
byte the first six are 0, 94, 188, 282, 376, 469 — differences 94, 94, 94, 94,
93, the shape of a cumulative offset table, which is also the shape of the four
FDC jump tables that start 74 bytes later. No base, so no claim.

## 3. 0xFE6E84-0xFE7732 is the FORMAT function — gap V, most of the way

```
Disk_FormatSelectedMedia   0xFE7200   ld C,(0x21E7) / and C,0x40
    bit set   -> DiskImage_Build1440K -> Disk_Format1440K
    bit clear -> DiskImage_Build720K  -> Disk_Format720K
    both      -> (0x2243) := the error code
```

One RAM bit picks the density and everything downstream of it.

**`DiskImage_Build720K` (0xFE75CA)** and **`DiskImage_Build1440K` (0xFE763E)**
assemble the filesystem in RAM at 0x60A080: copy a 32-byte ROM template, zero-fill
to 512 (the boot sector), then copy a second 32-byte template and zero-fill to
0x800 / 0xC00 (the FAT area). The two routines differ in exactly three
immediates — the two template addresses and the second fill count — and in
nothing else.

**`Disk_Format720K` (0xFE7222)** and **`Disk_Format1440K` (0xFE7401)** then issue
seven and nine requests through the veneer, abandoning the sequence on the first
non-zero error:

| # | op | trk/media | sec | cnt | buffer | what |
|---|---|---|---|---|---|---|
| 1 | 0 | 0xE0 / 0xC3 | 1 | 1 | — | reset + identify media |
| 2 | 5 | 0 | 1 | 1 | — | **FORMAT DISK** |
| 3 | 4 | 0 | 1 | 1 | 0x60A080 | write boot sector |
| 4… | 4 | 0 | 2… | 3 / 5+4 | 0x60A280… | write FAT 1 |
| …  | 4 | 0 | 5 / 11… | 3 / 5+4 | 0x60A280… | write FAT 2 |
| n-1 | 3 | 0x4F | 9 / 18 | 1 | 0x60A080 | verify read, last track |
| n | 3 | 0 | 9 | 1 | 0x60A080 | verify read, track 0 |

★ **Why the density labels are decodes.** For each routine three independent
statements agree, and they come from three different places in the ROM:

1. the **media descriptor** — 0xE0 & 0x0F = 0 and 0xC3 & 0x0F = 3, and
   `Fdc_MediaTypeJumpTable` maps those to geometry 0 (512 B × 9) and geometry 3
   (512 B × 18) (`FINDINGS-prom_a-fdc.md` §4);
2. the **verify read** asks for sector 9 on the 720 KB path and sector 18 on the
   1.44 MB path, both on track 0x4F = 79, the last of 80;
3. the **boot sector it writes** states 1440 total sectors / 9 per track / media
   0xF9 / 3 sectors per FAT, and 2880 / 18 / 0xF0 / 9 — and the FAT writes total
   2×3 and 2×9 sectors, i.e. exactly two FATs of the stated size.

`notes/prom_a_disk_format_checks.py` §4 recomputes the whole request table out
of the instruction stream and compares it with the tables above.

**The four templates.** ⚠ They are not four of a kind, and an earlier summary
of this section said "four floppy BPB templates, OEM `Technics`", which sends a
reader looking for four OEM strings that do not exist. **Two** of the four are
32-byte BOOT SECTOR heads carrying `EB 1C 90`, the OEM name `"Technics"`, a full
BIOS Parameter Block and an `EB FE` (x86 `JMP $`) stub where boot code would go
— so a Technics-formatted floppy is a valid DOS disk that is deliberately
**not** bootable. The other **two** are FAT ID stubs: three media bytes and 29
zeros, no OEM field and no BPB. `Technics` occurs **3×** in prom_a (0xFE6B86,
inside *"This is Technics HDD."*, and 0xFE76B5 and 0xFE76F5) and **0×** in
prom_b:

| at | what | media | total sectors | sec/track | root entries | sec/FAT |
|---|---|---|---|---|---|---|
| 0xFE76B2 | `BootSector_Floppy720K` | 0xF9 | 1440 = 80×2×9 | 9 | 112 | 3 |
| 0xFE76D2 | `FatId_Floppy720K` | `F9 FF FF` + 29 zeros | | | | |
| 0xFE76F2 | `BootSector_Floppy1440K` | 0xF0 | 2880 = 80×2×18 | 18 | 224 | 9 |
| 0xFE7712 | `FatId_Floppy1440K` | `F0 FF FF` + 29 zeros | | | | |

**What gap V still wants:** which UI control sets bit 6 of `(0x21E7)`, and who
calls `Disk_FormatSelectedMedia` — it has no absolute reference, so its caller is
a `calr` from code that is still `.incbin`, or from the module at 0xFE7800 that
this pass also converted but did not name.

## 4. ⚠ RETRACTED, and inverted: Gap T is NOT a hardware question

★ **This section shipped a false conclusion on 2026-08-25 and it is aimed
straight at the emulation lane, so the retraction comes before anything else.**

**What it said:** *"`Fdc_Op6_PortA3_Off` (0xFE65EF) and `Fdc_Op7_PortA3_On`
(0xFE661F) are the only writers of PA bit 3 … nothing in this firmware ever
changes it — through format, through identify-media, through every sector read
and write … a driver that gates drive READY on it will never see a ready drive
… Gap T is now a hardware question, not a disassembly one."*

**What is true:** the firmware changes PA bit 3 constantly, from a layer this
section never looked at. `python3 notes/prom_a_pa3_census.py` re-derives the
whole port from the images (19 checks, 0 failures) and the answer to gap T is
now in `notes/FINDINGS-prom_a-gap-T-pa3.md`.

**Where the error came from, because it is a general trap.** The census scanned
for one encoding, `f0 1e 41` = `ld (PA),A`, and its own justifying sentence was
the false step: *"The scan is opcode-anchored at every byte offset, so it can
over-report and cannot under-report, which is what a 'these two and no others'
claim needs."* The scan cannot miss an `ld (PA),A`. The claim being made was
about **writers of PA bit 3**, which is a strictly larger set: a bit write is
`f0 1e b3` (`res 3,(0x1E)`) or `f0 1e bb` (`set 3,(0x1E)`), and both occur, at
0xFE18EF and 0xFE18F7, reached by 15 `calr` sites.
★ **A completeness claim must be scanned for at the granularity it is made.**
`notes/prom_a_fdc_operation_census.py` now asserts the *presence* of those two
extra writers, so the old claim cannot come back silently.

**What SURVIVES from this section, unchanged and re-run:** the operation census
itself. 23 located call sites carry an operation word, every one an immediate;
the operations requested are exactly `{0, 3, 4, 5, 10, 11}`; operations 6 and 7
are requested by nothing; veneer 0xFE3004 / thunk `T_Fdc_Request_Thunk_Entry` has no caller in
either image; 8 absolute `call`/`jp` to 0xFE66C7, of which 2 are the veneers
0xFE3032 and 0xFE308D themselves; veneer 0xFE3018 (thunk `T_Fdc_Request_SaveRegs_Entry`) has 17 call
sites. All of that is still `python3 notes/prom_a_fdc_operation_census.py`,
9 checks, 0 failures.

| op | meaning | sites |
|---|---|---|
| 0 | reset + identify media | 5 |
| 3 | READ SECTORS | 5 |
| 4 | WRITE SECTORS | 9 |
| 5 | FORMAT DISK | 2 |
| 10 | test controller present | 1 |
| 11 | sense drive status | 1 |
| **6** | **clear PA bit 3** | **0** |
| **7** | **set PA bit 3** | **0** |

So operations 6 and 7 really are dead API. What was wrong was the leap from
"this API is dead" to "the pin is never driven": the pin is driven by the layer
ABOVE this module, which does not go through `Fdc_Request` to do it.

### The trap this census walked into first, recorded because it is general

The first version read the operation word as "the nearest preceding
`m_ld_mi16 MDI+rN, 0, imm`" and reported operation **0xFFFF** at 0xFE3868. It is
wrong: that instruction writes offset 0 *of whatever the register holds*, and at
0xFE3861 the register has already had `add XWA,0x0000000A` applied — so it is the
SECTOR COUNT, not the operation. The script now walks the window forward with a
per-register clean/dirty flag and only a freshly-loaded register's offset-0 store
counts. **An offset in a mnemonic is an offset from a pointer, not from a
structure.**

## 5. Also converted, and deliberately NOT named

**0xFE7800-0xFE7FB1** (1,969 bytes) is a separate module, published through
directory slots `T_F43020`-`T_F43034`. It walks 0x0C00-byte records at RAM
0x610100 looking for a byte with bit 7 set, and its three entry points each
branch on `(0x220B)` being 0 or 1 with a second test on `(0x0E35)`. Every routine
in it is `sub_XXXXXX`. It is converted because it is contiguous with the format
module and completes the span to the next `.incbin` boundary; nothing here
establishes what it is for, and the tree's rule is that an address label plus a
stated gap beats a plausible name.

## 6. Where the next wave should go from here

1. **Find the consumer of the hard-disk boot images** (§2), or prove there is
   none. It decides gap J.
2. **Find who calls `Disk_FormatSelectedMedia`** and what sets bit 6 of
   `(0x21E7)`. It finishes gap V and gives the emulator a reachable disk path.
   ⚠ Half of this is now answered: `Disk_MountFloppyWithRetry` **clears** bit 6 of `(0x21E7)`
   at 0xFE08D1 and **sets** it again at 0xFE08F3 when the disk-command result
   byte `(0x1735)` — the byte `Disk_MountFloppy` and its siblings store at 0xFE1957 —
   comes back as **0x0B**. And `sub_FE09BE` writes the same bit through a
   POINTER — 0xFE09C0 `lda XIX,0x21E7`, then 0xFE0A0E `and (XIX),0xBF` and
   0xFE0A1B `or (XIX),0x40` — which **copies bit 3 of `(0x21E8)` into bit 6 of
   `(0x21E7)`**. So bit 6 is a state flag the block-device layer raises itself,
   not only something a UI control sets, and a search for "the UI control that
   sets it" is looking for the wrong kind of writer.
   ⚠ Because of that pointer path, *"the only writers of bit 6 are the `res`/`set`
   at 0xFE08D1 and 0xFE08F3"* would be FALSE — the same shape of error as §4's.
   Asserted, pointer path included, by `python3 notes/prom_a_pa3_census.py`.
3. ~~Gap T is now a **hardware** question, not a disassembly one.~~
   **WRONG — see the retraction in §4.** The next step is
   `notes/FINDINGS-prom_a-gap-T-pa3.md` and the 0xFE0000 module, not a
   schematic. A schematic would still settle what the pin is WIRED to, which is
   the one part the ROM cannot say.
