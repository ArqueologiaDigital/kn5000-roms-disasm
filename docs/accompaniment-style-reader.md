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

## Known defect (KN5000 Feature Demo)

With the demo running, `(0x32E5)=0x48` → `(0x3285)=0x1A` and section 7's lane pointers
are `0xE754…0xFD29`, but bank `0x1A`'s data ends at `0xE230`. The reader therefore
walks `0xFF`, the watchdog trips, and the shared transport stops — which also kills
the demo song player, since it gates on the same `bit 2,(0x0420)`.

Open question: whether the style→bank mapping is wrong, or the firmware should have
clamped the section request for a style that has no section 7.
Full investigation: `kn7000_mame/notes/HANDOFF-kn5000-demo-playback.md`.
