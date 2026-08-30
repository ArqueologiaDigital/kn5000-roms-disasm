# Four misframes corrected. The v10 work list fell from 13 runs to 3.

**Date:** 2026-08-30
**Follows:** `FINDINGS-reachability-strong-ev-refusals-2026-08-30.md`, which
refused all 13 STRONG-with-evidence runs and showed that **every one of them was
named by an instruction this tree had framed over data**. This lane corrected
the misframes.

**Gates, both green:**

```
python3 scripts/analysis/assert_byte_identical.py           # all six ROMs IDENTICAL
python3 scripts/analysis/misframe_reframe_evidence.py       # per-site structure + falsification
python3 scripts/analysis/misframe_reframe_evidence.py --selftest
python3 scripts/analysis/reachability_refusal_evidence.py   # updated: 3 surviving runs
python3 scripts/analysis/address_line_map.py 0xED1BAA       # which line owns an address
python3 scripts/analysis/emit_rom_data_lines.py --selftest  # the .s text generator
python3 scripts/analysis/code_vs_data_delta.py 8b3d510 HEAD # the 1,753-byte figure
```

## The numbers

| `notes/reachability_kn5000.py --targets` | before | after |
|---|---|---|
| **STRONG seeds AND start evidence** | **176 B, 13 runs** | **37 B, 3 runs** |
| STRONG seeds, evidence ignored | 4,275 B | 4,136 B |
| any seed | 128,097 B | 128,072 B |
| `.incbin` spans containing reachable bytes | 1,567 | 1,564 |

The three survivors are B2's runs 5, 6 and 7, all in
`ui_widgets/control_menu_screens.s`. Their namers are in a file this lane did
not touch; they remain correctly REFUSED.

Bytes moved from CODE territory to DATA: **1,753 net** — 1,767 out, and 14 back
the other way (see the correction at site 2). Measured, not counted by hand:

```
python3 scripts/analysis/code_vs_data_delta.py 8b3d510 HEAD
  8b3d510  code 1,003,078  data 1,019,364  pad 74,710
  HEAD     code 1,001,325  data 1,021,116  pad 74,711
```

code + data + pad closes on 2,097,152 at both revisions. **Not one ROM byte
changed** — `assert_byte_identical.py` is green throughout.

## Site 1 -- `0xED1BA6..0xED1BEC`, `extensions/extension_data.s`

An 11-entry LE32 pointer table read **one byte late**, from 0xED1BAB, so every
pointer became a `jp` whose high byte was the *low* byte of the next entry --
phantom entry points marching down in steps of exactly 0x020000.

* the last entry, `0x00ED1BD6`, is exactly the first byte past the table's own
  end (`0xED1BAA + 11*4`);
* every entry lands on a 2-byte NUL-terminated ASCII digit, and the eleven
  cells fill 0xED1BD6..0xED1BEB with no gap;
* **`display/graphics_text_vga.s` indexes the table start**: `divs hl, 0xc` /
  `sla hl, 2` / `lda_24 xbc, (SplitNoteStr_C_0x4)` at 0xFC2DE2 and 0xFC2E67.
  Note number / 12, scaled by 4 = the pointer width.

*Inbound-reference check:* only 0xED1BA6 (the `"C "` string) and 0xED1BAA (the
table) are referenced from outside; nothing lands strictly inside.

*Names:* the five phantom `jp` operands (`NakaData_PartConfig`,
`Bitmap_SplitPoint_Gb_0x2B`, `Bitmap_Dredt0d_0xA8D`, `SepaOut_FormatData_Tail`,
`FILETYPE_SIG_TABLE_2_0x15`) were **references** to labels defined elsewhere,
not definitions here, so nothing lost a name. Three digit cells that had been
swallowed by phantom instructions gained one: `OctaveDigitStr_7`, `_3`, and
`_0C`. `_0C` sits between `_0A` (0xED1BE6) and `_0B` (0xED1BEA) in address
order because those two names predate the cell becoming visible and
`positional_labels.s` aliases `_0B`.

## Site 2 -- `0xF6A9D7..0xF6B206`, `sequencer/accompaniment_engine.s`

`AccScreen_UIDataBlock`. **The tree's own header already said it was data** --
`Total: 2096 bytes (698 + 15 + 120 + 15 + 6 + 287 + 955)`, `compiled from C
source` -- yet only the three `.incbin` parts (317 B) were data and 1,779 bytes
were framed as instructions, including the six 20-byte cells
`"CONTROL PITCH BEND ="` .. `"CONTROL AFTER TOUCH="` framed as
`ld xhl,0x52544e4f` (= the ASCII `"ONTR"`).

Descriptors verified in place (`02 0f`, five bytes, LE32 pointer at +7, LE16
cell width at +11): 0xF6AC91 -> 0x00F6ACA0 w20; 0xF6AD18 -> 0x00F6AD27 w3;
0xF6AD37 -> 0x00F6AD9E w2; 0xF6AD46 -> 0x00F6ADB6 w2; 0xF6AD8F -> 0x00F6AE4C w4.

⚠ **0xF6AD37 and 0xF6AD46 needed no work**: they, and the note-name and octave
cells they point at, are already inside `.incbin accomp_display_full.bin`. Same
for 0xF12B86 in `sound_editor_ui.s`. Only the *namers* were misframed.

### ★ The falsification test FIRED here, and it changed the answer

Of the 23 positional labels pointing into the block, **two are reached by
`call`, not `ld`** -- offsets 0x804 and 0x829. Both are **real 7-byte
subroutines** inside what the header called 955 bytes of "part names and
ordering":

```
0xF6B1DB  push xhl / ldb_d8 a,(0x353e) / pop xhl / ret     (= _0x804)
0xF6B200  push xhl / ldb_d8 a,(0x353c) / pop xhl / ret     (= _0x829)
```

They match their callers exactly (`xor xwa,xwa` / `call` / `ld l,a` /
`ldb a,96` / `mul8rr a,l`). The second had **lost its entry point** inside a
phantom `jp 0x3b1d1c` at 0xF6B1FD. Both are framed as code again and named
`AccScreen_GetByte_0x353E` / `_0x353C`. So the tree's "955 bytes" comment is an
over-claim: 941 data + 14 code, and the comment now says so.

The data around them is self-consistent: 30 seven-byte section-name cells at
0xF6B109 (`0xF6B109 + 30*7 = 0xF6B1DB`, the first routine) named by the stride-7
descriptor at 0xF6ABBE, and a 30-entry ordering table between the two routines
that is exactly a permutation of 0..29.

## Site 3 -- `0xEED628..0xEED657`, `ui_widgets/widget_dispatch.s`

A 48-byte code island between a `.byte` run and a `.zero 232`, in a zone that is
otherwise `.byte`/`.zero`/`.fill`/`.ascii`. The record the tree framed as two
`calr 7680` repeats, byte for byte, a shape the tree **already spells as data**
0x36 bytes earlier at 0xEED60C: `1e 00 1e 00 1e 00 1e 00 00 00 42 00 00 00`.
Both phantom `calr` targeted the same address, 0xEEF445 -- run 8's STRONG
`branch` seed, manufactured out of a repeated 16-bit constant.

*Inbound-reference check:* zero 24- or 32-bit references land inside the island.

## Site 4 -- `0xF12AD0..0xF12B86`, `audio/sound_editor_ui.s`

A record chain whose every boundary is confirmed **twice** -- once by a length
field or a fixed cell grid, once by a pointer from outside the span:

```
0xF12AD0 +4  (the previous record's LE32 pointer field) = 0xF12AD4
0xF12AD4 +41 (25x1 + 2x4 + 2x4 ASCII cells)             = 0xF12AFD   <- 5 refs
0xF12AFD +76 (19 LE32 pointers)                          = 0xF12B49  <- 2 refs
0xF12B49 +10 (record, its own length byte 0x0a)          = 0xF12B53  <- 1 ref
0xF12B53 +40 (five 8-byte cells)                         = 0xF12B7B  <- 2 refs
0xF12B7B +11 (record, its own length byte 0x0b)          = 0xF12B86  <- the .incbin
```

The last record's trailing LE32 is `0x00F12D0B`; the tree framed its `0x00` high
byte at 0xF12B85 as the `nop` that gave run 9 its fall-through seed.

*Inbound-reference check:* no 32-bit pointer from outside lands anywhere but a
structure start.

## ★ The descriptor shape is a ROM-WIDE construct, not six coincidences

Shape: a 15-byte record beginning `02 0f` (the second byte is the record
length), five payload bytes, an **LE32 pointer at +7**, an **LE16 cell width at
+11**.

Scanned over the whole 2 MiB (`misframe_reframe_evidence.py --survey`):

* 261 windows begin `02 0f`;
* **208 of them** carry a pointer that lands on two full cells of display text
  of exactly the declared width;
* the **null** -- the same test applied at 200,000 random offsets -- is
  **0.024%**. So 79.7% vs 0.024%, a factor of ~3,300.

All six descriptors named in B2's note are in the sieve. The tables they name
are unmistakable UI option labels: `LPF+EQ/HPF+EQ/LPF24`, `KEY ON/KEY OFF/
LEGATO`, `CELESTE 1/CELESTE 2/CHORUS 1`, `NORM/1/2/1/4`, `SIN/TRI/SQR`,
`TENU/NORM/STAC`, `A-vari1/2/3`, `ACCOMP 1/2/3`, `MONO/STEREO`, `OFF/ON`.

**They were not converted.** They are spread over `sound_editor_ui.s`,
`extension_data.s` and others, in data zones thousands of lines long that are
still framed as code, and re-framing them needs the same per-site bracketing
this lane did four times. The survey is the work list for whoever takes that on.

## What this lane did NOT do, and why

* **The 43 `\.byte 0xNN / ldb w,0 / swi 7` triples in `extension_data.s`** are
  `aligned_string "X "` note-name strings misframed the same way -- the sibling
  `SplitNoteStr_F: aligned_string "F "` spells the identical four bytes
  correctly. **All 43 were left alone** -- they seed nothing, so they cost the
  reachability metric nothing, and the diff is 120 lines of churn in a file
  another lane may be reading. They are recorded here as the next cheap win:
  each triple `.byte 0xNN / ldb w,0 / swi 7` is exactly `aligned_string "X "`,
  four bytes `NN 20 00 ff`, under labels already named `NoteStr0_C`,
  `TransposeNoteStr_B`, `SplitNoteStr_G`, `KeyScaleNoteStr_F` and friends.
* **`NoteNameStr_Table_0` at 0xED02A0 is one entry late.** The table has 16
  entries starting at **0xED029C** (16 strings at 0xED02DC..0xED0325, one per
  entry; the tree frames entry 0 as `ldb b,3 / .byte 0xed / nop`). Nothing
  references the label, so moving it is safe -- but moving a semantic name is
  exactly the change that needs saying out loud first, so it is recorded here
  rather than done quietly.
* **The three surviving runs** in `control_menu_screens.s` stay refused; their
  namers are naka widget records whose grammar that file documents, and
  re-framing them is a separate bracketing job.
