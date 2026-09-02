# prom_a bitmaps as PNG

Every file here is a **lossless, exact** rendering of a range of
`original_ROMs/wsa1_prom_a.ic12`, and the assembly's `.byte` rows for that range
are regenerated from it by `scripts/build/wsa1_bitmaps.py rewrite`.  The
dimensions are the firmware's, not a guess -- run `wsa1_bitmaps.py list` for each
file's evidence.  Ink is black.

* `SplashImage_*.png` -- the three 320x240 power-on screens.  `DitherA` and
  `DitherB` are disjoint half-tones of ONE picture (bitwise AND = 0, equal
  popcounts 3983/3983) composited by the SED1330's layer OR; opened together
  they read **`WSA`** in a brush script.  ★ That closes the "what the artwork
  says is NOT established" line in `notes/FINDINGS-prom_a-splash-bitmaps.md`.
  `Wordmark` reads `Technics`.
* `Bitmap_FF17E2.png` .. `Bitmap_FF20F4.png` -- ten 16x129 strips.  Opened, they
  are a **vertical piano-keyboard ruler labelled C-2, C-1, C0 ... C8**, the same
  keyboard at ten scroll positions -- a key-range / split-point display.
* `Widget_FC48D7.png` .. -- eight 48x15 pictograms (a flat bar, a cylinder,
  tapered wedges, a parallelogram, a spool, an arrow, a bolt).
* `Bitmap_F82BB0.png`, `Bitmap_F82C00.png` -- two op-03 targets inside prom_a.
