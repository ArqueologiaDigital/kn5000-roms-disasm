# prom_a + prom_b: the 32-byte draw scratch at 0x2640-0x265F (2026-10-03)

A second block of RAM that display lists draw from, beside `DisplayListB_Stage`
(FINDINGS-prom_ab-display-list-b-stage.md). Unlike that block, the code also reads this one.
It is a scratch area that each screen fills with whatever it is about to show.

    python3 wsa1/notes/prom_ab_dl_stage_census.py 0x2640 UI_DrawScratch 0x2600 0x2680

| | count |
|---|---|
| contiguous bytes from 0x2640 that are display-list source variables | 32 (0x2640-0x265F; 0x2660 is not) |
| display-list records reading them | 188 |
| code stores `ld (0x2640+n),...` | 137 |
| other code uses: loads, `lda XIX/XBC,(0x2640)` pointers, `ldw BC,0x2640 / add BC,WA` | 83 |

What is staged there, by owner:

- **Version screen.** prom_a's boot and version screen copies two 11-byte build tags from the
  remote side into 0x2640 and 0x264C and draws them
  (FINDINGS-prom_a-boot-and-version-screen.md, FINDINGS-memory-map.md).
- **Name copiers.** `SoundName_CopyToBuffer`, `CombiName_CopyToBuffer`,
  `SoundGroupName_CopyToBuffer` and `CombiGroupName_CopyToBuffer` copy a name into it before the
  screen draws.
- **DSP effect editor.** prom_b stores parameter byte j at (0x2640 + j), and its records read
  `.short 0x2640+j` (FINDINGS-prom_b-dsp-effect-parameters.md).

So the bytes have no fixed meaning. The block is named as one array, `UI_DrawScratch`, and the code
spells element n as `UI_DrawScratch+n`. The neighbours are named or left alone separately:

- 0x2661-0x2663 is `Value_AsciiDigits`;
- 0x2666 / 0x266A are the two 32-bit enable masks of `PanelButton_CallTableEntry`;
- 0x2671 and 0x2674 are display-list sources, but outside the run.
