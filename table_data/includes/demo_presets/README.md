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
                        [5..255]=250 payload bytes
```

Cell bytes `[0..2]` are not used by the reader and their values vary -- byte 0 is
**not** a fixed marker.

Event stream: a byte with bit 7 set is a status byte; following bytes with bit 7
clear are its data.

| status | data | meaning |
|---|---|---|
| `0x81` | 0 | advance one beat |
| `0x83` | 0 | end of track |
| `0x82` | n | text / CUE data |
| `0x9n` | 5 (repeatable) | note: `pos, note, velocity, dur_ticks, dur_beats` |
| `0xBn` `0xCn` `0xDn` | 2-5 | not decoded |

Timing is **96 ticks per beat**: `pos` is the tick within the current beat and
`absolute tick = beat * 96 + pos`; `duration = dur_beats * 96 + dur_ticks`. Both
`pos` and `dur_ticks` are bounded by 95, which is why this is base-96 rather than a
16-bit little-endian value. Validated on the Feature Presentation: 3842 of 3843 note
events have a non-decreasing position within their beat, and the pitch-class
histogram is strongly tonal (C 38.6%, D 20.7%, G 14.9%, every chromatic note < 4%).

A single `0x9n` status can introduce several consecutive 5-byte note records.

## Build

`demo_preset_NN.bin` (decompressed) is the **source of truth**. The build
recompresses it and `.incbin`s the result into `table_data/kn5000_table_data.s`:

```
make rebuild-demo-presets    # regenerate demo_preset_NN_compressed.bin
make verify-demo-presets     # check each matches the factory stream byte-for-byte
make decompress-demo-presets # re-extract sources + references from the factory ROM
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
