# The twelve WSA1R character generators, as contact sheets

One PNG per face, 16 cells per row, ink black, paper white, 1-pixel grey (160)
gutter between cells.  Each sheet is a **lossless, exact** rendering of its
table's bytes; `scripts/build/wsa1_fonts.py rewrite` regenerates the `.byte`
rows in `prom_b/wsa1_prom_b.s` from it, and `check` asserts they already agree.
Run `wsa1_fonts.py list` for the bases, pitches and cell counts, and
`notes/FINDINGS-fonts.md` for how each was established.

★ The counts are ARITHMETIC: the twelve tables abut with no padding, so
`next_base - base` divided by the pitch IS the cell count, and it comes out at
exactly 200 for all six Latin faces across five different pitches and exactly
120 for all three kana faces.  `wsa1_fonts.py` asserts every abutment before it
will export or verify anything.

What the sheets show at a glance, which the `.byte` rows did not:

* `Font_Svc21_16x24` -- a 16x24 Latin face whose code `0x5C` is **¥, not a
  backslash**.  That is JIS X 0201 Roman, and it is one more independent sign
  that this is a Japanese-market machine (`FINDINGS-fonts.md` reaches the same
  conclusion from the kana and kanji faces).
* `Font_Svc1A_16x16` -- "kanji, set A", 224 defined cells, and legible:
  状態 心配 故障 工場 出荷 構成 再生 最適 簡単 機器 演奏 音色 記憶 設定 選択
  自動 確認 ...  ⚠ Read off the rendering by eye, and worth following up: many
  ADJACENT cells form a compound word, which suggests the private encoding of
  `FINDINGS-fonts.md` section 5 numbers the kanji in the order the UI's own
  message text first needs them.  Not established here.
