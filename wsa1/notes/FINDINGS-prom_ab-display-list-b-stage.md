# prom_a + prom_b: the display-list-B staging block 0x12F6-0x1310 (2026-10-03)

An interpreter-B display-list record draws a RAM variable, named by its `+0x02 source variable`
word (FINDINGS-ui-display-list-interpreter-b.md). The bytes from 0x12F6 to 0x1310 form one block
used only that way:

- every one of its 27 bytes is the source variable of at least one record;
- the code writes these bytes and almost never reads them.

A screen's `*_StageValues` routine, e.g. `CyclePlayScreen_StageValues`, copies the values it is
about to show into the block. Then `DisplayListB_Run` draws them through the records. Which value a
byte holds therefore depends on the screen being drawn. On the song screens (0x12F6) is the song
number, `BStore_CurrentBank` + 1 (FINDINGS-prom_b-song-store.md). On the cycle-play screens it is
(0x3627). One record maps it through a table to "P 1".."P32".

    python3 wsa1/notes/prom_ab_dl_stage_census.py

| | count |
|---|---|
| bytes in the block (0x12F6-0x1310), each read by at least one DL record | 27 |
| DL records reading 0x12F6 / 0x12F7 / 0x12F9 / 0x12FB / 0x12FC (the busiest) | 25 / 14 / 12 / 11 / 12 |
| code stores `ld (0x12F6+n),...` | 363 |
| pointer loads `ld XIX,0x12F6+n` (stores then go through XIX) | 17 |
| code reads | 1: `sub A,(0x12F6)` in `Str_SongNameBlank`, which opens with six `pop XSP`; whether that entry is real was not checked |

The 25 for 0x12F6 counts `.short` source words in the transcriptions.
`notes/prom_b_var_screens.py --var 0x12F6` (wsa1/) decodes the records from the ROM bytes and
reports 23. The two counts were not reconciled here.

Below and above the block the pattern stops. 0x12C0-0x12ED and 0x1336-0x133F are read and written
by code, and no DL record names them.

The block is named as one array, `DisplayListB_Stage`, and the code spells element n as
`DisplayListB_Stage+n`. A per-byte name would claim one meaning per byte, and the bytes have one
meaning per screen.
