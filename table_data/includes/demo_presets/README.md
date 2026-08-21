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
| `0x83` | 0 | end of track |
| `0x82` | n | text / CUE data |
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

### The status vocabulary is INCOMPLETE -- eleven more exist

The table above does not cover everything the 19 songs actually use. Reading them with only the
documented statuses leaves 255 events unparsed, and they are NOT trailing filler: every one occurs
MID-STREAM, before the track's 0x83, and each status has a CONSISTENT argument count, which is what
a real event type looks like and what random bytes do not.

| status | count | args | notes |
|---|---|---|---|
| `0xFF` | 76 | 0 | 69 of 76 take no arguments |
| `0xF2` | 46 | 2 | |
| `0xF3` | 29 | 2 | |
| `0xE3` | 22 | 3 | |
| `0xE7` | 20 | 3 | |
| `0x80` | 16 | 3 | note this is the same byte the IC19 container uses as a cell marker |
| `0x86` | 15 | 1 | |
| `0xE4` | 10 | 3 | |
| `0x85` | 10 | 1 | |
| `0xE8` | 5 | 3 | appears in runs, e.g. `e8 1a 40 3d  e8 1c 00 3f  e8 1c 40 3e` |
| `0xF4` | 2 | -- | |

**None of these has an established meaning**, and no name is proposed. They are listed so that a
reader knows the vocabulary here is partial: an encoder built from this document would be unable to
round-trip a real song, and a decoder should reject rather than guess on them.

Reproduce with `tests/l5_reimplement_demo_format.py`, which reports them as malformed by design.

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
