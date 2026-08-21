# Demo song presets (SLIDE4K)

The 19 demo/preset songs referenced by the pointer table at ROM `0x9C4000`.
Entries 0-17 sit at `0x9C4050`-`0x9F94CB`; entry 18 (the Feature Demo /
Feature Presentation) sits apart at `0x8E0000`.

## Block format

```
+0x00  8 bytes   "SLIDE4K\0" magic
+0x08  3 bytes   uncompressed size, 24-bit little-endian
+0x0B  ...       LZSS payload
```

LZSS is the classic Okumura variant: 4 KB ring buffer prefilled with zeros,
initial write position `0xFEE`, flag byte LSB-first (1 = literal, 0 = match),
match = 12-bit offset + 4-bit length nibble where the copy length is
`nibble + 2 + 1` (3..18 bytes).

The decoder stops as soon as the declared uncompressed size is reached; a few
real (non-`0xFF`) stream bytes can follow that point and are preserved verbatim.

⚠ **The `*_compressed.bin` files in this directory are the PAYLOAD ONLY.** The block format
above describes what sits in the ROM; the 8-byte magic and the 3-byte size are emitted by
`table_data/kn5000_table_data.s` (`.asciz "SLIDE4K"` + `.byte`), not stored in the file. An
implementer following this section alone will look for a magic that is not there. Noted
2026-08-21 after `tests/l5_reimplement_slide4k.py` did exactly that.

**The codec description itself is sufficient and verified**: that test implements SLIDE4K from
this section and nothing else, and decompresses all 19 songs byte-exactly.

## Decompressed song layout

```
+0x1E   u16       track-enable mask
+0x20   16 x u8   track type
+0xD0   16 x      { u8 flags (bit7 = present), u16 start cell }
+0x800  cells     cell c at +0x800 + (c-1)*256
                  cell: [0]=0x80 marker, [3..4]=u16 next cell (0xFFFF = end),
                        [5..255]=251 payload bytes
```

Cell bytes `[0..2]` are not used by the reader and their values vary -- byte 0 is
**not** a fixed marker (unlike the IC19 accompaniment cells, where it always is; see
`docs/accompaniment-style-format.md` -- the two containers are similar but NOT the same, and
they also differ in how a cell pointer is resolved).

⚠ THE PAYLOAD IS 251 BYTES, corrected 2026-08-21. `[5..255]` inclusive is 251, and this file
said 250 while `demo_preset_to_midi.py` used 250 -- so byte 255 of every cell was dropped and
any event straddling a cell boundary was truncated. Measured over the 19 songs: 588 note
events decode short at 250 and **none** at 251, and at 252 the next cell's byte 0 appears 1009
times, which pins the boundary from the other side. Found by
`tests/l5_reimplement_demo_format.py`, a reader written from this file alone.

Event stream: a byte with bit 7 set is a status byte; following bytes with bit 7
clear are its data.

| status | data | meaning |
|---|---|---|
| `0x81` | 0 | advance one beat |
| `0x82` | 0 | **end of track** (measured; see below) |
| `0x83` | -- | **does not occur** -- 0 times in all 19 songs |
| `0x9n` | 5 (repeatable) | note: `pos, note, velocity, dur_ticks, dur_beats` |
| `0xBn` `0xCn` `0xDn` | 2-5 | not decoded |

### Confirmed from the firmware

The note-event layout is not inferred -- it is read out of the firmware's own event
queue. `f56EED` parses an event into `0x342D..0x3432`, and `f57040` queues the
fields in order: status, note, velocity, duration-low, duration-high.

* `0x342F` is the **note**: `f57006` compares it against a note register (`(0x3558) & 0x7F`).
* `0x3431` is the **duration low byte**: `f5706F` applies an explicit "if zero then one".
* **96 ticks per beat** is the literal `0x60` in the timing routine `f570BB`.

`data[0]` is the tick within the current beat for *every* event family, not just
notes -- verified across all 19 songs: 10,330 of 10,330 non-note events have
`data[0] <= 95`, with zero exceptions.

### CORRECTED 2026-08-21: the terminator is 0x82, and only THREE statuses are undocumented

This file used to say `0x83` ends a track and `0x82` carries text/CUE data. **Measured across all
19 songs: `0x83` occurs ZERO times and every one of the 168 tracks contains `0x82`.** The firmware
agrees -- `SetWall_ParseStream_MainLoop` (`v10/maincpu/ui/setwall_routines.s:797`) jumps to its End
label on `0x82`.

The error mattered. Walking with `0x83` as the terminator never stops, so the walk runs past the
end of the real stream into trailing bytes and reports them as events. That produced a list of
*eleven* "undocumented statuses" (0xFF, 0xF2, 0xF3, 0xE3, 0xE7, 0xE4, 0xE8, 0xF4 among them) which
were **not events at all** -- just data after the terminator, parsed by mistake.

With `0x82` as the terminator, the genuinely undocumented in-stream statuses are exactly three:

| status | count | args | firmware |
|---|---|---|---|
| `0x80` | 16 | 3 | explicit case in `SetWall_ParseStream_MainLoop`; **probably TEMPO, see below** |
| `0x85` | 10 | 1 | explicit case in the same parser |
| `0x86` | 10 | 1 | explicit case in the same parser |

Two independent routes agreeing exactly -- the data says these three are left over, and the
firmware has a case for each -- is why this list is trusted where the eleven were not. Their
MEANINGS are still not established and no names are proposed.

Reproduce: `tests/l5_reimplement_demo_format.py`, which reports 67,132 events and 36 malformed,
the 36 being these three statuses.

#### `0x80` is very likely the TEMPO event [INFERENCE]

This matters because the docstring of `demo_preset_to_midi.py` lists tempo as NOT DECODED and makes
the user pass `--bpm`. The structural evidence:

* **Exactly one per song, at the very start of one track** -- 16 events across 19 songs, and in 14
  of them it is event #0 or #1.
* **Always the same track per song generation**: track 7 in songs 00-11, track 4 in songs 12-18.
  A single track carrying a song-global setting is what a conductor track is.
* **Song 01 has a SECOND one, at event #157.** A song-global value that can change once partway
  through is a tempo change; very few other quantities behave that way.
* The three arguments are `[0, lo, hi]` with `hi` only ever 0 or 1, i.e. `pos=0` followed by a
  14-bit value `lo + 128*hi`. Across the 16 events that value spans **88..228**, which is a
  musically sane tempo range and not a plausible range for an index or a flag.

    song 00 -> 113   song 01 -> 195, then 120   song 04 -> 148   song 05 -> 131   song 06 -> 107
    song 08 -> 111   song 10 -> 88    song 11 -> 178   song 12 -> 160   song 13 -> 130
    song 14 -> 165   song 15 -> 120   song 16 -> 134   song 17 -> 228   song 18 -> 90

**NOT CONFIRMED**, and the confirmation is cheap: song 18 is the Feature Presentation, which plays
in the emulator, and its value is 90. Time a known number of beats against the wall clock and see
whether it comes out at 90 BPM. Until someone does that, no code should treat this as the tempo --
`--bpm` stays.

### Still inferred

* `0xCn` looks like a **program change**: `data[2]` is always 0 (one distinct value
  in 286 events) and `data[3]` spans 0-127 with 82 distinct values. Not emitted by
  default -- KN5000 tone numbers are not General MIDI, so emitting them would make
  playback sound confidently wrong. Use `--program-changes`.
* `0xBn` looks like a **parameter change**: `data[2]` has only 9 distinct values
  (max 10), so it is an internal parameter index, *not* a MIDI CC number. No
  mapping is invented.
* `0xDn` may be **pitch bend or a centred controller**: `data[1]` takes only 3
  values (`00`/`40`/`7F`) and `data[2]` clusters tightly around `0x40`.

Timing is **96 ticks per beat**: `pos` is the tick within the current beat and
`absolute tick = beat * 96 + pos`; `duration = dur_beats * 96 + dur_ticks`. Both
`pos` and `dur_ticks` are bounded by 95, which is why this is base-96 rather than a
16-bit little-endian value. Validated on the Feature Presentation: 3842 of 3843 note
events have a non-decreasing position within their beat, and the pitch-class
histogram is strongly tonal (C 38.6%, D 20.7%, G 14.9%, every chromatic note < 4%).

A single `0x9n` status can introduce several consecutive 5-byte note records.

## Build

The checked-in source is **`midi/demo_preset_NN.mid` + `sidecar/demo_preset_NN.yaml`**.
The decompressed `.bin` and its LZSS payload are both generated:

```
midi/*.mid + sidecar/*.json --> demo_preset_NN.bin --> demo_preset_NN_compressed.bin
                                                              |
                                                          .incbin --> ROM
```

`compress_lzss.py --strict` makes a mismatch against the factory stream a hard
build failure, so a bad edit cannot silently ship different music (verified: a
one-semitone change to a single note makes `make` exit non-zero and produce no ROM).

```
make rebuild-demo-presets    # .mid + sidecar -> .bin -> compressed payload
make verify-demo-presets     # check each matches the factory stream byte-for-byte
```

Bootstrap targets, only needed if the extraction itself changes (they re-derive the
checked-in source from the factory ROM):

```
make decompress-demo-presets # factory ROM -> .bin + compression references
make demo-midi               # -> midi/*.mid
make demo-sidecars           # -> sidecar/*.json
```

`compress_lzss.py --reference` replays the original stream's compression
decisions, so the rebuilt ROM stays byte-identical to the factory ROM.
The references live in `original_ROMs/demo_preset_NN_compressed.original.bin`.

## Listening to them

```
make demo-midi               # writes midi/demo_preset_NN.mid
```

Standard MIDI File format 1, 96 ticks per quarter note, one MIDI track per part.
Caveats, so nothing here is mistaken for decoded fact:

* **Tempo is not decoded.** The files render at a nominal 120 BPM (`--bpm`).
* **The part -> instrument mapping is not decoded.** No program change is emitted;
  each part's type byte is carried through in the MIDI track name instead.
* **Percussion is a guess.** `make demo-midi` passes `--drum-type 0x0C`, because
  type `0x0C` parts have a median note range of 82 semitones (vs 39-57 for other
  types) and the highest note counts. That is suggestive, not confirmed. Use
  `--drum-track N` to override per part index.

## Lossless round-trip

Every non-note event is also written verbatim into a **sequencer-specific meta
event** (`FF 7F <len> <status> <data...>`) at its correct tick, so nothing is
discarded just because it is not understood yet. Measured over all 19 songs,
reading the `.mid` files back recovers:

| | recovered |
|---|---|
| note events | 32,548 / 32,548 (100%) |
| other events | 10,800 / 10,800 (100%) |

So the **event stream** is fully recoverable from the MIDI. What is still *not* in
the `.mid`, and would be needed before MIDI could become the build source:

* the song header `+0x00..+0x800` (track types, present flags, the `+0x30..+0xD0`
  region) -- not musical data; needs a sidecar or deterministic regeneration
* the cell allocation and link topology
* trailing beat markers after the final event of a track

## MIDI -> preset (the reverse stage)

This now exists and passes for all 19 songs:

```
make rebuild-demo-presets    # .mid + sidecar -> .bin -> compressed payload
make verify-demo-presets     # check each payload against the factory stream
```

The sidecars are commented YAML -- each structure carries a short note saying what
it is and why MIDI cannot hold it.

`midi_to_preset.py` takes note values (pitch, velocity, in-beat position, duration)
from the **MIDI**, so DAW edits are honoured. The sidecar supplies everything a MIDI
file cannot represent:

* the song header `+0x00..+0x800`, cell allocation and link topology, cell prefix
  bytes, unreached cells and padding (51-91% of each `.bin` comes from the MIDI;
  the rest is sidecar residue)
* the exact stream order -- the factory streams are **not** strictly time-sorted
  (~200 of 43,348 events, e.g. two notes at position `0x5F` then `0x5E` in one beat)
* which status bytes were explicit vs **running status** (`81 22 4C 6C 0C 00` is a
  beat marker followed by a note reusing the previous `0x9n`)
* 320 of 32,575 note durations (0.98%) that MIDI cannot round-trip: same-pitch
  overlaps on one channel (note-off pairing is FIFO, so crossing durations come
  back swapped), and a few records whose duration low byte exceeds 95, which the
  base-96 split cannot regenerate

The `.bin` files are no longer checked in -- keeping both would have stored the same
songs twice. `original_ROMs/demo_preset_NN_compressed.original.bin` remains the
byte-exact ground truth from the factory ROM, and `--strict` gates every build
against it.

## An easter egg

Part 14 of the Feature Presentation carries a developer memo in a `0x82` event:

```
Memo
These area meansCUE data
0xbf00-,0x6e00- also,AcoustIlusndata near 0x9b91 adjusted by
Harry Nak./EMID '97.07/07
```

It is also a useful correctness check: a broken decompressor does not produce
clean English.

## Note on the previous extraction

These files were previously extracted with a 14-byte header assumption and a
match length of `nibble + 2`. Both were wrong: the header is 11 bytes (the
"3 metadata bytes" were the first flag byte and first two payload bytes), and
the copy length is one byte longer. The old output was short and corrupted
(entry 18: 32,910 bytes instead of 38,144). The current extraction is validated
against the firmware's own decompressor running in MAME - entry 18 matches the
emulator's output byte-for-byte, and all 19 now decode to exactly the size
declared in their own headers.
