# Accompaniment / style pattern reader (main CPU)

Reverse-engineered by tracing the running firmware in MAME while the Feature Demo
plays. Every address below was confirmed at runtime unless marked *inferred*.
This subsystem had no semantic labels before; the names are now in
`symbols/maincpu_symbols_reference.txt`.

## Where the pattern data actually lives

The reader does **not** read the composer pool in DRAM. `AccompStyle_ResolveReadBase`
(`F58FF9`) picks between two resolvers:

| condition | resolver | source |
|---|---|---|
| `(0x32E5) < 0x80` | `F59035` → `AccompStyle_RhythmROMBase` (`F590A9`) | **rhythm ROM IC14** |
| otherwise | `F59059` / `F59069` | banked DRAM / IC19 user patterns |

Preset styles take the first path. The effective address is

```
read = 0x400000 + (0x3285) * 0x10000 + ptr + 6
```

`(0x3285)` is the 64 KB bank (table at `F590D1` = `0x400000, 0x410000, …`, 0x40 entries),
`+6` skips the cell header `80 FF FF FF FF 87`, and the `+0x8000` that `F590A9` adds is
cancelled by the `-0x8000` in `AccompStyle_LaneBaseFromRecord`. Note `(XHL+IY)` indexes
with a **signed** 16-bit offset.

## Finding the style record

`AccompStyle_LookupRecord` (`F53D9A`) turns a (group, style) pair into the address of
a style record in the rhythm ROM:

```
F53D77   H &= 7 ; H <<= 1 ; W = 0 ; WA <<= 2 ; L = 0 ; HL = H*256 + A*4
         XIY = 0xE45142                  ; style directory, 4 bytes per entry
         WA  = (XIY+HL)                  ; word 0: low byte = 64 KB bank
         IY  = (XIY+HL+2)                ; word 1: offset within that bank
F53D9A   calr F53D77 ; call F590B4 ; extz XIY ; add XHL,XIY ; ld XIY,XHL
```

so

```
record = 0x400000 + (0x3277) + bank * 0x10000 + offset      ; index (H&7)*512 + style*4
```

The directory is **8 groups x 128 styles**; 202 distinct records. The caller is
`F55F9E` with `A = (0x32E5)` (style) and `H = (0x32E6)` (group). `(0x32E6)` is bounded
to 0..6 by the seven compare sites `F54692..F54AF4`.

Both inputs, and the section request, come from control-panel mirror bytes sampled by
one routine:

```
F53367   A = (0xFC5A)              -> (0x32F5)   pending style
F5336F   A = (0xFC5B) & 0x7F & 7   -> (0x32F7)   pending group
F533FF   A = (0xFC61) & 0x30 >> 4  -> (0x3305)   section request
F55EA4   (0x32E6) = (0x32F7) ; (0x32E5) = (0x32F5)      ; commit
```

## Selecting a section

```
F55F87   A = (0x3305) & 3            ; 2-bit section request
         (0x3338) = A ; (0x333A) = A
F56373   AccompStyle_SelectSection
           -> F563A2 -> F56402: idx = f56413[req]      ; table 00 03 04 07
                        F563E1/…  A   = f5646e[idx]    ; table 00 05 0A 0F 14 19 1E 23
           -> writes that byte to (0x32A3..0x32A8), one per lane
```

So there are **8 sections at stride 5**, and the 2-bit request selects section
0, 3, 4 or 7. Measured: the home screen idles on request 0 → section 0; the Feature
Demo sets request 3 → section 7.

## Per-lane pointers

`AccompStyle_InitLaneBases` (`F55FDE`) takes the style byte from `(XIY+0x3D1)` into
`(0x3285)`, then for each lane calls `AccompStyle_VariationOffset` (`F5657E`) and
`AccompStyle_LaneBaseFromRecord` (`F56CD0`):

```
ptr    = u16 at (XIY + HL + 0x118 + 0x26*lane)
base   = ptr - 0x8000 + 6                     ; stored at 0x3287/89/8B/8D/8F/91
```

`XIY = (0x32CE)` is the style record, which lives **in the rhythm ROM** (e.g. `0x402800`).
Its bank byte array starts at `+0x3D1`; `0x3D` there is a "no data" sentinel (banks
0x38-0x3F are entirely `0xFF`).

⚠ `F5657E` shifts `W` twice — `F5659B` shifts once and overwrites `W` with a byte read
from the record, then `F56592` shifts again — so the index into `F5669A`/`F566AA` comes
from the record, not from the incoming `A`.

## Event stream

`AccompStyle_ReaderDispatch` (`F567CD`) accepts `0x81` (advance one beat), `0x83`
(end of track), `0x87` (cell link) and `0x90/0x91/0xD1..0xD5` (events). Anything else
falls to `AccompStyle_BadOpcodeWatchdog` (`F568A8`), which skips one byte and bumps
`(0x32ED)`. At 32 it calls `AccompStyle_StopTransport` (`F59AB9`) and
`AccompStyle_ResetToEmptySong` (`F5E931` → `Composer_InitEmptySong` `F5CE20`), which
memsets the composer pool from the ROM templates at `F5D340`/`F5D440`/`F5D540`.

`AccompStyle_DecodeEvent` (`F56E71`) parses an event into `0x342D..0x3432`:
status, in-beat position, note, velocity, duration-low, duration-high. `F57006`
compares `0x342F` against a note register and `F5706F` forces a zero duration to one,
which is what identifies those two fields. The beat is **96 ticks** — the literal
`0x60` in the timing routine `F570BB`.

## Where the pattern data really is — and a defect in the ROM DUMP

Every track begins with the six-byte cell header `80 FF FF FF FF 87`, and the reader
starts exactly 6 bytes past it. That makes lane pointers self-checking: a correct one
must land 6 bytes after that pattern. Over all 202 records x 48 lane reads:

| rhythm ROM image | correctly framed | landing on 0xFF |
|---|---|---|
| `kn5000_rhythm_data_rom.ic14` as dumped | 3439 / 9696 (35.5%) | 409 |
| same image with bank bits 3 and 5 swapped | **9696 / 9696 (100%)** | **0** |

The declared-bank -> actual-bank relation is a clean deterministic bit swap —
`0x08-0x0F <-> 0x20-0x27`, `0x18-0x1F <-> 0x30-0x37`, everything else identity — i.e.
ROM address lines **A19 and A21 are transposed** in the dump we hold. The bank table at
`F590D1` is strictly linear (all 64 entries `0x400000 + i*0x10000`), so the firmware does
no scrambling of its own; and the record area (banks 0x00-0x07) has both bits clear, so
records, style names and the directory all read correctly. Only the pattern data is
displaced, which is why this hid for so long.

132 of the 202 records sit in banks where bit 3 != bit 5, so about two thirds of the
factory rhythms read the wrong 64 KB bank. With the KN5000 Feature Demo (group 4,
style 0x48, section 7) the reader walks `0xFF`, the bad-opcode watchdog trips, and the
shared transport stops — which also kills the demo song player, since it gates on the
same `bit 2,(0x0420)`.

It is **not yet settled** whether the dump is wrong or the board routes CPU A19/A21 to
different IC14 pins; the fix belongs in the ROM in the first case and in the emulator's
memory map in the second. Full investigation:
`kn7000_mame/notes/HANDOFF-kn5000-demo-playback.md`.
