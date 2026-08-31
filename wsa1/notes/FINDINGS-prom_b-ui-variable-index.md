# The UI's RAM-variable index, and the tables it draws them through

**Tool:** `python3 notes/prom_b_var_screens.py` (`--census`, `--var`, `--tables`,
`--families`, `--table`, `--site`). Everything below is its output; nothing is
typed by hand.

## Why this index exists

Interpreter B of the display-list VM reads a **16-bit RAM address out of every
record it runs** — `IX=(XIY+2)` inside `DisplayListB_ExtractField` (`0xF31CC5`,
established in `FINDINGS-ui-display-list-interpreter-b.md`). So the 494
interpreter-B records *are* a reverse index from a RAM variable to the place on
screen where the firmware prints it, and, through the code address of the call
site, to the interpreter-A text the same routine draws around it.

That is the missing half of converting a module. A converted routine leaves you
holding `(0x0D4A)` and `(0x76AA)`; this says which screen shows them.

⚠ The link from a variable to a caption is **"the same routine draws both"** —
proximity in the code, within a window (default 0x200 bytes) around the
interpreter-B call site. The script prints the window and says so. It is
evidence for a name, not a proof of one.

## What the index contains

```
$ python3 notes/prom_b_var_screens.py --census
interpreter-B display-list records: 494 (494 carry a variable)
distinct RAM variables displayed: 92
```

The 92 fall into five neighbourhoods:

| range | n | the screen its captions name |
|---|--:|---|
| `0x12F6-0x1309` | 19 | `SEQUENCER PLAY` / `S0NG` / `CYCLE:` / `MEASURE = ` / `TIME SIG.= ` / `REC0RD` / `MASTER:` / `MIXER` |
| `0x216A` | 1 | — |
| `0x2640-0x2674` | 16 | `SOUND MODE`, parts 1-6, columns `OCT LVL PAN EFF1 EFF2 REV INT MIDI DRAWBAR` |
| `0x27A3-0x27B7` | 19 | the sound-edit parameter pages |
| `0x2808-0x280B` | 4 | the four resonator selectors — they index `DLTable_F03241`, the 64 resonator names already decoded in the .s |
| `0x76A5-0x789F` | 32 | `C0MBINATI0N M0DE` / `PAGE1/2`, parts 1-6, `OCT VOL PAN EFF1 EFF2 REV` |

(`0x0000` is the 92nd; it appears in 21 records whose `+2` field is zero.
1 + 19 + 1 + 16 + 19 + 4 + 32 = 92, and the six row counts are the script's,
not the reader's addition.)

## An array of records, found by arithmetic

```
$ python3 notes/prom_b_var_screens.py --families
  stride 0x40  x8   0x76A5 0x76E5 0x7725 0x7765 0x77A5 0x77E5 0x7825 0x7865
  stride 0x40  x8   0x76AA 0x76EA 0x772A 0x776A 0x77AA 0x77EA 0x782A 0x786A
  stride 0x40  x8   0x76AF 0x76EF 0x772F 0x776F 0x77AF 0x77EF 0x782F 0x786F
  stride 0x40  x8   0x76DF 0x771F 0x775F 0x779F 0x77DF 0x781F 0x785F 0x789F
```

Four fields, each appearing eight times at a spacing of `0x40`, is **an array of
eight 0x40-byte records** covering `0x0076A0-0x00789F`. The fields:

| field | drawn as | evidence |
|---|---|---|
| `+0x05` | a decimal number, mask `0x7F` (0-127) | opcode 09 record, no table |
| `+0x0A` | through the 3-byte table at `0xF28522`, whose first entries are `L64 L63 L62 …` — a **pan** scale | opcode 07 record |
| `+0x0F` | a single bit, mask `0x20` shift 5 | opcode 03 record |
| `+0x3F` | through the 3-byte table at `0xF297A0` (`R1- R2- …`) | opcode 07 record |

and the captions the same routine draws are `C0MBINATI0N M0DE`, `PAGE1/2`,
`1`-`6`, `OCT`, `VOL`, `PAN`, `EFF1`, `EFF2`, `REV`.

⚠ Two honest limits. (a) The record BASE is `0x76A0` only if the record starts a
multiple of `0x40` below `0x76A5`; the four residues are consistent with that and
with any other constant offset. (b) The array is **eight** records because eight
is how many the display lists draw; the screen labels six parts. Nothing here
measures the array.

⚠ The `--families` output also prints stride-1, -2 and -4 rows inside
`0x12F6-0x1305` and `0x27A6-0x27B7`. Those ranges are *contiguous*, so a run at
every small stride is arithmetic, not structure. The script prints that warning
itself.

## The 55 tables

```
$ python3 notes/prom_b_var_screens.py --tables
interpreter-B tables: 55 distinct (pointer, entry width) pairs
```

42 are in prom_b ROM, 13 in RAM.  Those 13 rows are only **10 distinct RAM
addresses** -- three of them appear at more than one entry width:

```
0x0012F6 w6   0x0012F7 w6   0x0012F8 w6   0x0012FE w6
0x0022F0 w2   0x0022F0 w13  0x0022F0 w16
0x002300 w13  0x002310 w13  0x002320 w13
0x00264C w6   0x002661 w2   0x002661 w3
```

(Evidence: the `RAM` rows of `python3 notes/prom_b_var_screens.py --tables`;
`--selftest` asserts this list.  An earlier revision of this line said "live
text buffers around 0x22F0, 0x2640, 0x2661", which omitted the whole 0x12Fx
cluster and misnamed 0x264C as 0x2640 -- 0x2640 is a *variable* in the `vars`
column, not one of the 13 table pointers.) ⚠ The "bound" the script prints is `(mask >> shift) + 1` — an upper
bound on the INDEX, not a measurement of the array, which is the same caveat
`FINDINGS-ui-display-list-interpreter-b.md` records for the operand gaps.

Where the extent can actually be MEASURED — the table ends exactly where the next
object begins — the count is stated below as measured; otherwise only the text is:

| table | width | entries | measured how | contents |
|---|--:|--:|---|---|
| `0xF33022` | 13 | **64** | `+64*13 = 0xF33362`, where a well-formed interpreter-A record (`op 1B len 0A`) starts | the controller-destination list: `PITCH BEND`, `SUSTAIN LEVEL`, `FILTER CUTOFF`, `PTCH/AMP/FLTR LFO1-4 DEP`, the same 12 `… SPD`, `FITTING`, `POSITION`, `POS.DEPTH`, `POS.COLOR`, `POS.MOV.WIDTH`, `POS.MOV.SPEED`, `INTERACTION`, `MUTING`, `RESO.KEYSHIFT`, `SUB GAIN`, `DELAY`, `PANNING`, `EFF1 SEND`, `REV SEND`, `LEVEL`, `ATTACK TIME`, `DECAY TIME`, `RELEASE TIME`, `FILTER RESO.`, `EFF1/EFF2/REV DYNAMIC` — and then entries 50-63 are the right-aligned decimals `50`..`63`, which is why the table is 64 long and not 50 |
| `0xF05286` | 8 | **15** | `+15*8 = 0xF052FE`, the first byte of the next table | the temperaments: `OFF RANDOM PIANO ORCHESTR PHYTHAGO WERCKMEI KIRNBERG ARABIC1..5 SLENDRO PELOG USER` |
| `0xF052FE` | 4 | 8 (mask) | — | `NORM 1/2 1/4 1/8 1/16 1/32 1/64 FIX` |
| `0xF05182` | 8 | **3** | `+3*8 = 0xF0519A`, where a run of 32-bit ROM pointers starts | `ATTACK)  DECAY)  RELEASE)` |
| `0xF06598` | 4 | **5** | `+5*4 = 0xF065AC`, where a run of 32-bit ROM pointers starts | `OFF MAIN SUB1 SUB2 SUB3` |
| `0xF3AA3F` | 7 | **3** | `+3*7 = 0xF3AA54`, where an interpreter-A `op 1C len 15` record whose text is `VEL0CITY…` starts | `ALL NOTE CONTROL` |
| `0xF05469` | 3 | 4 (mask) | — | `SIN TRI SQR SAW` |
| `0xF32A5A` | 7 | ≥5 | — ⚠ the mask allows 4 but the fifth 7-byte entry is `CHORD  `, so 4 is the index bound and NOT the extent | `KEY ON  KEY OFF  LEGATO  NON LEG  CHORD` |
| `0xF05B60` | 3 | 128 (mask) | — | note names, `C-2 C#2 D-2 …` |
| `0xF05CF8` | 5 | 128 (mask) | — | the matching frequencies, `65.4  69.3  73.4 …` |
| `0xF28522` | 3 | 128 (mask) | — | pan positions, `L64 L63 L62 …` |
| `0xF34E88`, `0xF395A2` | 3 | 256 (mask) | — | `P 1`..`P32`, then `CYCLE`, `PLAY` |
| `0xF39602`, `0xF3B7E8` | 7 | 256 (mask) | — | `PART 1`..`PART 8` |
| `0xF03241` | 8 | 64 | already decoded in the .s | the 64 resonator names |

⚠ Only the six marked **measured** have an established entry count. The rest are
`.incbin` in the gaps between the display lists and stay that way until
`notes/prom_b_dl_operand_tables.py` can tile their gap exactly; that is the same
standard the 13 already-decoded gaps had to meet.

## The one thing this index could NOT answer

None of the block-store module's variables — `(0x0D4A)`, `(0x0C8A)`, `(0x345C)`,
`(0x2880)` — is displayed by any interpreter-B record. The index is a map of what
the UI *prints*, and firmware state that is only *acted on* is invisible to it.
That is worth knowing before reaching for it again.
