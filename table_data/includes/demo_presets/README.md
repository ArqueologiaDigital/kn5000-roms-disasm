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

Event stream: a byte with bit 7 set is a status byte; following bytes with bit 7
clear are its data. `0x81` = advance one beat, `0x83` = end of track,
`0x9n` + 5 data bytes = note event.

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

## Note on the previous extraction

These files were previously extracted with a 14-byte header assumption and a
match length of `nibble + 2`. Both were wrong: the header is 11 bytes (the
"3 metadata bytes" were the first flag byte and first two payload bytes), and
the copy length is one byte longer. The old output was short and corrupted
(entry 18: 32,910 bytes instead of 38,144). The current extraction is validated
against the firmware's own decompressor running in MAME - entry 18 matches the
emulator's output byte-for-byte, and all 19 now decode to exactly the size
declared in their own headers.
