# prom_b bitmaps as PNG

Every file here is a **lossless, exact** rendering of a range of
`original_ROMs/wsa1_prom_b.ic13`, and the assembly's `.byte` rows for that range
are regenerated from it by `scripts/build/wsa1_bitmaps.py rewrite`.  The
dimensions are the firmware's -- run `wsa1_bitmaps.py list` for each file's
evidence.  Ink is black.

* `DLGlyph_000_*.png` .. `DLGlyph_118_*.png` -- **the WSA1's UI icon sheet**,
  119 cells of 24x24 at `0xF78028 + index*72`, the grid `DLHandler_Glyph24x24`
  (`0xF31ACE`, display-list opcode `0x23`) computes.  Opened as a sheet they are
  unmistakable: MIDI plugs, `EDIT`, `ROM/ORIG`, the `GENERAL MIDI` logo, a
  `PRESET` grid, a keyboard, a tuning fork, a metronome, a clock, disks,
  `SONGS`, `NOM/EXP`, waveforms, envelope curves, a grand piano, a mixer.
* `ValueGlyph_00_*.png` .. `ValueGlyph_28_*.png` -- the 29-step **rotary knob**
  `DrawValueGlyph_24x24` draws; consecutive files rotate the pointer.
* `Curve_F019C2.png` .. -- six 40x40 **response-curve** thumbnails (concave
  through convex), the six targets of the selector table at `0xF5BEFB`.
* `Bitmap_F019AA.png`, `Bitmap_F01992.png`, `Bitmap_F13D00.png` .. -- 16x12
  circle icons; `Bitmap_F0191A.png` .. -- 24x10 cells.
* `Bitmap_F283A7.png`, `Bitmap_F2CAC3.png` -- 40x30 rounded UI frames.
* `Bitmap_F54718.png`, `Bitmap_F54790.png` (48x20), `Bitmap_F54D7E.png` (304x6),
  `Bitmap_F17C59.png` (24x17), `Bitmap_F05CE0.png` (16x12).
