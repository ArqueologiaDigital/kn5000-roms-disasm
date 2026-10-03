# What prom_b has to say to `src/mame/matsushita/wsa1.cpp`

*prom_b lane, wave 8, 2026-08-31. Nothing in the MAME tree was edited.*
*Everything below is re-derivable from this repository; the command is given
with each item.*

The driver is on branch `technics-wsa1`, worktree `~/compartilhado/mame-pr-wsa1`.
Items are ordered by what they would change.

---

## 1. ★ CPU 1's CS1 static RAM is mapped too small — the firmware uses 0x7FC2

**The driver has**

```cpp
    map(0x000080, 0x0051ff).ram();
```

with the honest note that the boot clear loop (`0xF8278A`, `0x1460` longwords) is
*"a lower bound, not the size"*. It is, and prom_b exceeds it.

The converted 80.2 % of prom_b (`python3 scripts/analysis/source_coverage.py`)
contains **74 absolute memory accesses to 10 distinct addresses above `0x0051FF`**,
none of them a branch target or an immediate — they are byte reads, bit tests and
read-modify-writes:

| address | refs | an example site |
|---|---:|---|
| `0x7634` | 2 | `0xF10178  xor (0x7634),0x01` |
| `0x7922` | 4 | `0xF696FC  ld W,(0x7922)` |
| `0x7EE2` | 8 | `0xF3885F  ld C,(0x7ee2)` |
| `0x7EE3` | 5 | `0xF38866  ld (XIZ+0xfe),(0x7ee3)` |
| `0x7F05` | 7 | `0xF38872  ld E,(0x7f05)` |
| `0x7F32` | 8 | `0xF445A6  bit 2,(0x7f32)` |
| `0x7F34` | 2 | `0xF00320  bit 2,(0x7f34)` |
| `0x7F4D` | 31 | `0xF443BD  bit 2,(0x7f4d)` |
| `0x7FC0` | 3 | `0xF3890B  ld H,(0x7fc0)` |
| `0x7FC2` | 4 | `0xF6658B  and (0x7fc2),0xfe` |

A read-modify-write is the strongest shape available here: `and (0x7fc2),0xfe`
at `0xF6658B` and `or (0x7fc2),0x01` at `0xF66592` are the two arms of one
`if`, so the firmware both reads and writes that byte and expects the write to
stick.

⚠ These are not device registers. CPU 1's TMP95C061 internal I/O area is
`0x000000-0x00007F` only, and the device supplies its own `internal_mem()`.

prom_a agrees independently, goes higher, and has already named the chip. Its
power-down routine check-sums two 512-byte blocks and stores the results, and
the header on it says:

> `0x007620 for 512 bytes -> checksum word at 0x007FD2`
> `0x617800 for 512 bytes -> checksum word at 0x007FD4`
> The first is **CS1 static RAM**, the second is work DRAM …

So prom_a's own transcription already places CS1 static RAM at `0x007620` and
writes checksum words at `0x007FD2` and `0x007FD4` — 8,658 bytes above the top
of what the driver maps. That is a settings-retention area, which is exactly the
kind of thing that must be mapped for a boot to get past it.

★ **SUPERSEDED AS THE BOUND, and by a better measurement.** Lane N1 ran the same
question over BOTH CPU-1 images (`notes/cs1_sram_extent.py`, committed
`f7d78f6`) and gets **227 distinct addresses, 827 references, highest
`0x7FD7`** — with **9** of the 10 above also touched by prom_a. So prom_a
carries the great majority of the evidence and reaches 21 bytes higher than
prom_b does. The table above is the prom_b half, kept because it is what this
lane measured and because a read-modify-write is a sharper shape than a
reference count; **quote N1's number, not this one, when changing the driver.**

**Suggested change:** widen the CS1 map to at least `0x007FFF`. 32 KiB is the
obvious chip and `0x7FD4`/`0x7FC2` sitting 44 and 62 bytes below its top is the
usual top-of-RAM layout. State it as a lower bound, as the driver already does.

Reproduce:

```
python3 notes/prom_b_ram_and_device_census.py --lowram
```

## 2. ★ prom_b identifies NONE of the six unnamed CS0 devices — because it names no device at all

The driver has six `noprw()` entries on CPU 1 with no part identified:
`0x790000`, `0x7A0000`, `0x7B0004`, `0x7C0000`, `0x7E0008`, `0x7F0000`.

⚠ **Two of those six are no longer unidentified, and the answer came from
prom_a, not here.** Lane N1's `notes/FINDINGS-prom_a-for-the-mame-driver.md`
establishes `0x7A0000` and `0x7B0004`/`0x7B0005` as **one uPD765-family floppy
controller** — `0x7A0000` its data register on the micro-DMA-0 path,
`0x7B0004`/`5` its status and result path, `INT5` (`INT5_Dev7B_Receive`,
`0xFE6866`) its interrupt. Nothing in prom_b contradicts that, and nothing in
prom_b could confirm it either, for the reason below. The remaining four are
`0x790000` (the SED1330, already identified in the driver's own TODO),
`0x7C0000`, `0x7E0008` and `0x7F0000`.

**Not one of them appears anywhere in prom_b**, and neither does any other
address in `0x700000-0x7FFFFF`. Over the converted 80.2 % of the image every one
of the 130 distinct addresses at or above `0x600000` that prom_b names — 1,194
references — lies in `0x600000-0x617800`, which is work DRAM:

```
$ python3 notes/prom_b_ram_and_device_census.py --devices
addresses >= 0x600000 named by converted prom_b: 130 distinct, 1194 references
  0x600000xx  130 distinct, 0x600000-0x617800
  the driver's six unidentified CPU-1 devices named here: 0 []
  any address at all in 0x700000-0x7FFFFF: 0

$ grep -c '0x790000\|0x7a0000\|0x7c0000\|0x7e0000\|0x7f0000' prom_a/wsa1_prom_a.s
61
```

This is a **negative result and it is useful**: prom_b is the UI, text and
table half of CPU 1's image and it drives no hardware. Every device on CPU 1 is
reached through prom_a, so the TODO list's "identify the devices on both
processors' CS0 areas" has nothing to gain from this image and the effort
belongs in prom_a and prom_c — which is where lane N1 found the floppy
controller.

⚠ **And the converse caution, from N1: prom_b does not own all the UI text.**
prom_a carries substantial text of its own — the SYSTEM menus at
`0xFA1F00-0xFA4E58`, DSP EFFECT / SOUND EDIT at `0xFC40F4`, SEQUENCER at
`0xFF0E26`, disk volume labels at `0xFE7026`. So "prom_b holds most of the UI
text" is a rough division of labour and not a rule: a string found in prom_b may
have a twin in prom_a, and a text-drawing routine in prom_b may be drawing a
table that lives there. Every literal the `MsgLine_*` round named was checked to
be in `0xF00000-0xF7FFFF` — the addresses are in each header — but the next lane
should not assume it.

## 3. The LCD text layer, with pixel coordinates

Derived in `notes/FINDINGS-prom_b-message-line.md`
(`python3 notes/prom_b_msgline.py`, `--selftest` 45 checks):

* CPU 1 keeps **four 30-character text lines in low RAM** at `0x000FE4`,
  `0x001012`, `0x001030`, `0x00104E`.
* Each is drawn by one interpreter-B display-list record (`0xF3D38A`,
  `0xF3D3AD`, `0xF3D3CB`, `0xF3D3E9`) that carries the buffer address, the
  count 30, `swi 7` function 6 and an LCD cursor.
* `AP = 40` bytes per display line (`0xF8E850` APL = 0x28, `0xF8E85B` APH = 0),
  so the four cursors put them at **x = 8, y = 52 / 97 / 142 / 180**, in the
  8-pixel-wide, 14-row font at prom_b `0xF1B400`. ⚠ Those are rows within
  whichever of the three OR-composited layers is selected — the service adds
  `(0x2555)` to the record's cursor first — and which layer was not traced.
* Nothing draws them unless the **screen id byte `(0x207C)` is `0x0E`**.

Useful the moment `0x790000` is wired to a `sed1330_device`: those four lines
are the first legible thing that should appear, and their content is composed
by the 38 `MsgLine_*` routines named this round.

Related RAM the driver may want in a comment:

| RAM | what it is |
|---|---|
| `0x0EF5` | which sub-screen of screen `0x0E` is showing |
| `0x207C` | the screen id; indexes a 256-entry table at prom_b `0xF2D000` |
| `0x2661-0x2663` | three ASCII digits, output of prom_a's `Value_ToAsciiDigits3` |
| `0x2555` | the LCD layer base that `swi 7` adds to a record's cursor |

**Named in the source (2026-10-03).** These, with the screen-request pair and the status byte that
FINDINGS-prom_b-song-store.md and FINDINGS-prom_a-panel-control-map.md establish, are symbols in
`wsa1/include/wsa1_ram.inc`: `UI_Screen0E_SubScreen` (0x0EF5), `UI_Request` / `UI_Request_Hi`
(0x2070 / 0x2071), `UI_RequestBits` (0x2075), `UI_ScreenId` (0x207C), `Value_AsciiDigits`
(0x2661, `+1`, `+2`), `UI_StatusCode` (0x2880; 0x2555 was already `LCD_CurrentLayerBase`) --
1,684 operands in prom_a and prom_b (`python3 scripts/tools/name_wsa1_ram_count.py`).
`(0x207E)` stays a number: what it means is recorded as not established.

## 4. `swi 7` function 6: what `HL` is — an answer to a stated Unknown

prom_a's `LCD_Svc_06_DrawText8x14` header says

> `Unknown: what HL is a stride THROUGH; it is multiplied by BC once, before the loop, and never used again.`

It is the **entry index of a string table**. The service computes
`IZ = HL * BC` and then reads glyph bytes from `XIY + IZ`; the only caller that
sets those three registers is `DLB_Handler_StringTable` (prom_b `0xF31B21`),
which loads `XIY` = the table base from record `+7`, `BC` = the entry WIDTH from
record `+0x0B`, and `HL` = the bit-field it just extracted. So the product is
`base + index * width`, the address of entry `HL` of a table of `BC`-wide
entries — which is exactly what the record at `0xF3D38A` does with `BC = 30` and
`HL = 0`.

⚠ prom_a is another lane's file and was not edited.

## 5. The machine reads and writes Standard MIDI Files, and this is their shape

`notes/prom_b_smf_reader.py` (40 checks) and this round's
`notes/prom_b_apply_smf_names.py`:

* `Smf_ReadFile` (prom_b `0xF6F530-0xF6F8A4`) and `Smf_WriteFile`
  (`0xF7385F-0xF74809`). Both are bracketed by bit 7 of `(0x21E8)`, which is
  set on entry and cleared before the `ret`, and prom_b touches that bit at
  exactly those four addresses.
* The **output template** is at `0xF7493F` and again at `0xF760BF`:

```
  4D 54 68 64  "MThd"   00 00 00 06  len 6
  00 00        format 0
  00 01        one track
  00 60        division = 96 ticks per quarter note
  4D 54 72 6B  "MTrk"   00 00 00 00  track length, patched at write time
  00 FF 03 0F  delta 0, meta FF 03 (track name), length 15
  57 53 41 20 20 20 20   "WSA    "
```

  so a song saved by this machine is **SMF format 0, one track, 96 PPQN**, with
  a track-name meta event `WSA    ` + 8 characters.
* Those 8 characters come from **RAM `0x21C8`**, and the reader writes `M` `I`
  `D` to `0x21D0-0x21D2`, so `0x21C8-0x21D2` is an **8.3 filename** field. The
  default extension is `MID`.
* Input arrives through a **1,024-byte sliding window at `0x60A700-0x60AAFF`**
  in work DRAM, cursor `(0x1088)`, refilled by `InputStream_Refill`
  (`0xF765D4`) which leaves prom_b through slot `T_F425A8` to prom_a
  `0xFE1C3A`. The floppy is the obvious source and is **not** asserted here.

For the driver this makes the `uPD72070` TODO concrete: a floppy image for this
machine should contain ordinary `.MID` files, so an implemented FDC is testable
against a file anyone can make.

## 6. Three file signatures the firmware checks

Same buffer, `0x60A700`, so all three are disk content:

| signature | where checked | note |
|---|---|---|
| `MThd` / `MTrk` | `0xF6F59B`, `0xF6F658` | Standard MIDI File; retries once at `+0x80`, then error `0x31` in `(0x2880)` |
| `WSA SOUND RAM S0` | `0xF48C1A` onward, 16 bytes at `+0` | only when the screen id `(0x207C)` is `0x54` |
| `WSA1` | the same routine, 4 bytes at `+6` | `0xFF` is accepted as a wildcard; mismatch returns error `0x2B` |

## 7. The 0x617800 record array — size confirmed, count still open

The driver deliberately leaves this unmapped because *"nothing in the reached
code fixes how many records there are"*. That is still true, and prom_b does fix
the **record size and the numbering**: `0xF61D94` and `0xF61F24` both do
`sub <reg>,0x00617800 / sra 0x08,<reg> / inc 1,<reg>`, and `0xF61F5B` is the
inverse (`sla 0x08 / add 0x00617800`). So records are **256 bytes** and the
number the UI carries is **1-based**. No bound was found; leaving it unmapped
remains right.

## 8. DSP effects — 128 slots, 56 used

Not new here, but worth carrying into the driver's documentation when the DSP is
modelled: prom_b `0xF147AC` holds **128 sixteen-character effect names**, of
which 56 are real (`CHORUS`, `GATED REVERB`, `PLATE REVERB 1`,
`PEQ+COMPR+DIST`, …) and 72 are the placeholder `----------`; the parameter
labels follow at `0xF15024`. Lane A4 joined that table to prom_c's
`PoolDir_RecordForUnitProgram` (`0xFDC551`) and showed the 56 named programs map
to 56 distinct pool records, a bijection
(`notes/FINDINGS-prom_c-p7-is-dsp-effects.md`).

⚠ **A correction to the brief that sent this lane here:** it says the 128 names
at `0xF147AC` are "the strongest naming evidence available anywhere in this
project" and that "whatever in prom_b indexes or renders that name table can be
named with confidence". It cannot. **Nothing in prom_a or prom_b spells
`0x00F147AC` in a decodable operand** — the header on `EffectNames_F147AC` has
said so since it was converted, and this round re-checked it. The three
128-entry tables in the `0xF0EA9F` block are indexed from `(0x2796)` and their
correspondence with the name table is a correspondence, not a decode. The
neighbouring `EffectParamNames_F15024` **is** named by an operand
(`sub_F10FF1`), and that is a different table.

## 9. A standing check that came out of this round

Two routines in prom_b had **no label at all** because the object before them
was data and the emitter never opened a new one: the SMF reader at `0xF6F530`
(881 bytes, under `Data_F6F528`) and the accompaniment-volume line at
`0xF6E4F2` (80 bytes, under a 64-byte `.ascii`). Both are labelled now, and

```
$ python3 notes/prom_b_ram_and_device_census.py --orphans
code rows following a data row under a data-kind label: 49
  of those, named by a decoded transfer or a thunk slot (= a LOST ROUTINE ENTRY): 0
```

says there is no third: the remaining 49 cases are tables embedded mid-routine
that the code jumps over, and must **not** be given labels.
