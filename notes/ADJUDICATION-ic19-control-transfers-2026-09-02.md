# The 13 control transfers into IC19's window: **all 13 are misframes**

Lane `drvpromd`, 2026-09-02. Script:
`scripts/analysis/ic19_control_transfer_adjudication.py` (6 sections, 0
failures). No source or driver file was modified.

## The question

`kn5000.cpp:631` maps IC19 as `map(0x300000, 0x3fffff).rom().region("custom_data", 0)`
— it is **CPU-fetchable**, so "IC19 is a pure data ROM" is a real claim and not
a tautology. A previous lane established that verdict (all 206 references load
its address; `llvm-mc` emits 0 instruction statements from `custom_data/`'s
source against 36,391 for HD-AE5000; injected real code scores far above
anything actually there). **But 13 control transfers targeting `0x300000-0x3FFFFF`
exist in the maincpu sources, all inside `.byte`-adjacent regions, and nobody
had adjudicated them.**

## Verdict: **REFUTED as an entry path — every one of the 13 is a phantom.**
## The pure-data verdict for IC19 is STRENGTHENED, not corrected.

## The 13 sites, and what they collapse to

All 13 are `jp`, all 13 are in one file (`sequencer/accompaniment_engine.s`),
and they name only **four distinct targets**:

| target | v10 sites | v9 sites |
|---|---:|---:|
| `0x3540F1` | 1 | 1 |
| `0x379BF1` | 1 | 1 |
| `0x37C9F1` | 4 | 4 |
| `0x3B1D1C` | 0 | 1 |
| **total** | **6** | **7** |

`jp imm24` is `1B <lo> <mid> <hi>`. Searching **both program ROMs** for those
four encodings finds **12 ROM addresses**, and the v9 and v10 images are
**byte-identical in the 0x40-byte neighbourhood of every one** — so one
adjudication covers both trees, and the 13 source sites are all drawn from this
set of 12.

    0xEEC9C8  0xF608BC  0xF61FBF  0xF65219  0xF660FD  0xF6612F
    0xF675AA  0xF675CB  0xF675EC  0xF6760D  0xF67CF8  0xF6B1FD

## Evidence 1 — the targets are data, and one is erased flash

| target | IC19 file offset | what is there |
|---|---|---|
| `0x3540F1` | `0x0540F1` | structured record data, 0xFF ratio 0.12 |
| `0x379BF1` | `0x079BF1` | style record — the ASCII name `"CaribbeanRockN  "` starts 16 bytes later |
| `0x37C9F1` | `0x07C9F1` | structured record data, 0xFF ratio 0.06 |
| `0x3B1D1C` | `0x0B1D1C` | **`0xFF` erased flash, ratio 1.00** — cannot be an entry point under any reading |

## Evidence 2 — an independent decoder begins no instruction at any of the 12

MAME's `unidasm` is a decoder wholly independent of this tree's `llvm-mc`
backend, and its listing is committed beside the ROM
(`original_ROMs/kn5000_v10_program.rom.unidasm`). **At all 12 sites it does not
start an instruction at all** — the `0x1B` is mid-instruction. Examples:

    f675a9: 66 1b                 jr Z,0xf675c6          <- the 0x1B is a DISPLACEMENT
    f675ab: f1 c9 37 00 08        ld (0x37c9),0x08

    f65218: 66 1b                 jr Z,0xf65235
    f6521a: f1 40 35 00 01        ld (0x3540),0x01

    f608bb: 66 1b                 jr Z,0xf608d8
    f608bd: f1 9b 37 cb           bit 3,(0x379b)

    f660fc: 6e 1b                 jr NZ,0xf66119
    f660fe: f1 9b 37 00 04        ld (0x379b),0x04

## Evidence 3 — the mechanism, which explains every digit of every target

The `0x1B` the tree reads as a `jp` opcode is the **displacement byte of a
preceding `jr cc,d8`** (`0x66` = `jr Z`, `0x6E` = `jr NZ`). The three bytes the
phantom then swallows are `F1 <lo> <hi>` — the TLCS-900 `(nnnn)` direct-memory
prefix followed by a **16-bit RAM variable address**.

That is why **every phantom target ends in `0xF1`** and why its top byte is
`0x3n`: the variables are `0x3540`, `0x379B`, `0x37C8` and `0x37C9`, which the
same routines address explicitly a few instructions away (`ld (0x3540),0x01`,
`bit 3,(0x379b)`, `ld (0x37c9),0x08`). The `0x3` is the high byte of a low-RAM
address, not the high byte of an IC19 address. **The coincidence is arithmetic,
not semantic.**

The four `0x37C9F1` sites at `0xF675AA/CB/EC/0D` sit at an exact **stride of
33 bytes** and are four iterations of one bit-test chain:

    bit 3,(0x37c8) / jr Z,+27 / ld (0x37c9),0x08
    bit 4,(0x37c8) / jr Z,+27 / ld (0x37c9),0x10
    bit 5,(0x37c8) / jr Z,+27 / ld (0x37c9),0x20
    bit 6,(0x37c8) / jr Z,+27 / ld (0x37c9),0x40

The bit number and the mask march in lockstep (`1<<3 … 1<<6`). Perfectly
coherent real code with no jump to IC19 anywhere in it.

## Evidence 4 — one of the 13 is already a PROVEN misframe, in this tree

`jp 0x3b1d1c` at `0xF6B1FD` survives **only in v9**. v10's byte-gated source
already frames those exact bytes correctly, and carries the note saying so:

> `0xF6B200 = AccScreen_UIDataBlock_0x829` … The tree **had lost its entry
> point inside a phantom `jp 0x3b1d1c` at 0xF6B1FD**.

v10's framing: the `0x1B`/`0x1C` are entries `0x1B`/`0x1C` of a 30-entry display
ordering permutation table (`0x00..0x1D`), and the `0x3B` is `push xhl`, the
first instruction of `AccScreen_GetByte_0x353C`. **The byte gate certifies that
framing.** This is why v9 has 7 sites and v10 has 6 — same bytes, one tree
corrected. It is a worked precedent for the other 12.

⚠ At this one site `unidasm` is *also* misframed (it linearly decodes the data
table and produces its own phantom `jp 0x1c1b`), so evidence 2 settles nothing
there on its own. What settles it is v10's byte-gated source.

## The nulls

Two were computed, and they say different things. Both are reported.

**Null A — `jp`-shaped BYTES per 1 MiB window of the maincpu space. FLAT.**
Every `1B <3 bytes>` in the 2 MiB v10 image, bucketed by target window:

    IC19 window (0x3xxxxx) ....... 74
    NO-DEVICE windows (0x2,C,D) .. [106, 61, 65]   mean 77.3
    IC19 / null mean ............. 0.96x

IC19's window is **not enriched at all** in `jp`-shaped bytes relative to
address space that holds no device.

**Null B — `jp`/`call`/`jr` STATEMENTS this tree actually emits. DOES NOT WASH OUT.**

    window 0x2xxxxx    0     -- NO DEVICE --
    window 0x3xxxxx   13     IC19
    window 0xCxxxxx    0     -- NO DEVICE --
    window 0xDxxxxx    8     -- NO DEVICE --

13 against a no-device mean of 2.7 is **4.8x**, and IC19 leads the table. So
this null does not by itself acquit IC19, and it should not be quoted as if it
did. What it *does* establish is that phantom transfers into address space
holding no device are a **real and common artefact of this tree's framing** —
eight aim at `0xDxxxxx`, where nothing can be entered. The verdict therefore
does not rest on either null; it rests on the twelve individual reframes in
evidence 2-4.

## Consequences

* **The driver needs no change.** `kn5000.cpp:631` maps IC19 `.rom()`, which is
  faithful to the hardware (it is on CS5 and is fetchable); nothing in the
  firmware ever fetches from it. There is no missing entry path and no missing
  device behaviour.
* **The pure-data verdict for IC19 is strengthened.** The only 13 pieces of
  contrary evidence in the whole tree are accounted for, individually, from ROM
  bytes.
* **Follow-up available, not done here (byte-neutral):** the 12 sites are real
  reframing debt of the "data disassembled as plausible instructions" kind that
  `notes/DEBT-INVENTORY-2026-09-02.md` tracks. `unidasm` supplies the correct
  framing for 11 of them directly and v10's own source supplies the 12th. A
  conversion lane can apply it; the byte gate will certify it, and the count of
  transfers into IC19 should fall to 0 in both trees.
  ⚠ `accompaniment_engine.s` is **latin-1** — patch it with an explicit
  latin-1 read/write, never with the Edit tool (lane brief addendum).

## Run it

    python3 scripts/analysis/ic19_control_transfer_adjudication.py            # all six sections
    python3 scripts/analysis/ic19_control_transfer_adjudication.py --null     # just the two nulls

Sections read ROM bytes and one committed text listing only; none invokes
`llvm-mc`, so none is exposed to the shared-toolchain drift the lane brief
warns about. The four `jp imm24` encodings were taken from
`llvm-mc -triple=tlcs900 -show-encoding` at `tlcs900_backend@6f456a19f05b` and
are asserted against the ROM inside the script, so a later decoder change
cannot move them silently.
