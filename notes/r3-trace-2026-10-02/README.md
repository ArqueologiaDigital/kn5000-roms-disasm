# R3 refusals that control flow refutes (2026-10-02/03)

`trace_r3_sites.py` (usage in its docstring) traces control flow over one source file's
address range, entering only at addresses some `call`/`calr` of the tree targets, and lists the
"absurd block" (R3) refusals of symbolize_numeric_branches.py whose branch AND target are
reached as instruction starts.  `trusted_<file>_<tree>.json` are those lists, as applied with
`symbolize_numeric_branches.py --trust-traced` (every other rule still applies; `--verify`
re-mirrors the tree and compares the dump: PASS each time).

| tree | accompaniment_engine.s: R3 sites / traced / applied | other files, applied |
|---|---|---|
| v10 | 153 / 54 / 54 | 17 (audio_control_engine 3, flash_floppy_handlers 8, sound_editor_ui 3, note_voice_mapping 3) |
| v9 | 153 / 54 / 54 | 17 |
| v7 | 445 / 362 / 362 | 29 |

Every trace reported 0 conflicts.  The remaining refusals are in code no call reaches (jump
tables and indirect calls are not followed), or in data.

## Seeded blocks (2026-10-03)

`--seed ADDR[,ADDR...]` adds entry addresses for a block that no `call` reaches but that was read
by hand as code. The trace still has to reach each R3 site and its target from there, so a seed
vouches only for the block's first instruction.

| file | block | seed (v10 / v9 / v7) | R3 sites reached | applied |
|---|---|---|---|---|
| `trusted_seed_cmstep_debug_<tree>.json` | `CmStep_DebugShowHexBytes` (accompaniment_engine.s) | 0xF6304A / 0xF6304A / 0xF62C46 | 11 / 11 / 11 | 11 each, `--verify` PASS |
| `trusted_seed_acc_batch2_<tree>.json` | 18 blocks of accompaniment_engine.s (`seeds_acc_batch2_v10_v9.txt`) | 18 / 18 / 11 (`seeds_acc_batch2_v7.txt`) | 51 / 51 / 13 | 51 / 51 / 13, `--verify` PASS |

The seed was chosen because the block is coherent without the trace. All six `calr`s resolve to
one routine. That routine's two `calr`s resolve to a nibble splitter and a bare `ret`, and the
digit table "0123456789ABCDEF" follows.

### How the batch-2 seeds were chosen

`list_r3_clusters.py` prints each cluster of R3 refusals with the code around it and with line addresses.
Every cluster was read before seeding.  Seeded: blocks that are coherent code, i.e. a loop's branch lands on
its own head, all calls go to existing routines, and the flags a branch tests are set by the instruction
before it.  Not seeded:
- tables decoded as code: a run of `xx 56 f6 00` pointers (0xF65657), bit masks (0xF6A55D), and byte tables
  indexed by (0x34D6) (0xF65CAF);
- a garbage decode (`ld xsp,0xca041ef1`, 0xF5AACD);
- a loop that branches on flags no instruction set (`ld a,(xiy)` / `jr nz`, 0xF63813);
- a block whose entry is unclear (0xF65AF6).

v7's seeds are v10's mapped through the nearest label that both trees have, kept only when v7's instruction at
the mapped address has the same mnemonic.  Seven did not map, because v7 still holds those blocks as `.byte`.

## `--rich` beyond accompaniment_engine.s (2026-10-03)

`trusted_dsp_config_sysex_<tree>.json`: all 12 R3 sites of audio/dsp_config_sysex.s, in each tree, are in
UIStateEvt_ParamEdit_Data.  That is a handler reached only through widget_dispatch.s's `.long` table, so only
`--rich` enters it.  12 / 12 / 12 traced, 0 conflicts; 12 operands and 4 labels applied per tree, `--verify` PASS.

## `--rich` over the remaining files (2026-10-03): `rich-2026-10-03/`

`summary.txt` is the trace output for every file and tree that still had R3 refusals.  The `trusted_*.json`
files are the non-empty lists, as applied:

| tree | file: R3 sites / traced and applied |
|---|---|
| v10 | midi_dispatch_handlers 4/4, fdc_routines 1/1, audio_control_engine 10/9, accompseq_routines 2/0, system_handlers 2/0 |
| v9 | midi_dispatch_handlers 4/4, fdc_routines 1/1, audio_control_engine 16/9, accompseq_routines 2/0, system_handlers 2/0 |
| v7 | fdc_routines 2/2, audio_control_engine 7/7, sound_editor_ui 7/7, cpanel_routines 4/4, midi_serial_routines 4/4, smf_event_processor 2/2, system_handlers 2/0 |

Every trace reported 0 conflicts, and every apply passed `--verify`.

## Data decoded as code: `reframe-specs/` (2026-10-03)

Some R3 clusters are not missed code but data that an early pass decoded as instructions. Seeds cannot
fix those, so each is re-spelled with `scripts/converters/scoop_reframe.py apply --spec <file>`. That
command proves byte identity and rolls back on any difference.

| spec (v10 / v9) | span | what it was | post-edit |
|---|---|---|---|
| `cmpncp_itemhandlers_<tree>.json` | 0xF6541A-0xF6577B, accompaniment_engine.s | `CmpNcp_ItemHandlerTable` (7 `.long`), `CmpNcp_ItemA/B_HandlerIndex` (`.short`), `CmpNcp_ProgramGroupBase` (12 bytes) and the five handlers they reach, plus ten title-hook fragments spelled `.byte 0xc1, ... / push xiz` | `cmpncp_postedit.py <tree>`: title RAM operands by name (`PREVIOUS_TITLE` ...), the obsolete misframing note removed |

How the span was laid out:

    python3 scripts/converters/scoop_reframe.py plan --image v10 \
        --file v10/maincpu/sequencer/accompaniment_engine.s --lo 0xF6541A --hi 0xF6577B \
        --entry 0xF65516 ... --entry 0xF65771 --exclude 0xF656EB --out <plan.json>

The 17 `--entry` values were 0xF65516-0xF6551F (one-`ret` stubs and `and (0xe3e2),0xfe; ret`),
0xF656E1, 0xF656E8, 0xF65716, 0xF65717, 0xF65718, 0xF6571F and 0xF65771. 0xF656EB, which the planner's
phase D picked, is excluded because it lies inside the `cp` at 0xF656E8. No `.long` in any image points
at the stubs or wrappers. They have the shapes the dispatch tables of this module call, and unidasm
decodes them cleanly. The specs set `keep_original_code`, so an instruction line that already spelled
its bytes keeps its text, with its RAM names and its choice among aliases: 266 of the 289 lines in each
tree. Labels renamed by `scripts/renaming/rename_cmpncp_item_tables.sed` first.

v7 held the same code as the romslice `includes/romslices/v7_transplant_DrumVoice_Handler7.bin`
(0xF650AC-0xF654EE, v10 address - 0x404). It is ported from v10 and the bin is removed:

    python3 scripts/lanes/sys/port_islands.py --src v10 --dst v7 \
        --file sequencer/accompaniment_engine.s --line 24399 --apply
    python3 notes/r3-trace-2026-10-02/reframe-specs/cmpncp_v7_postport.py

The port covers 1054 of the 1090 bytes in 357 lines, with 53 labels, and is identical after round 0.
The post-port step names the two tables the port left as `.byte` / numbers (`CmpNcp_ProgramGroupBase`,
`CmpNcp_ItemHandlerTable`). It also restates the carried `[v10]` comments with v7's RAM addresses:
(0x390B) / (0x390C) for v10's (0x39A7) / (0x39A8), and (0xE31C) / (0xE31E) for (0xE3E2) / (0xE3E4).
Eight `calr`s of the block stay numeric in v7. Their targets lie past the island, in v7 source that is
itself misframed (`.byte 0xc8, 0x04` for `push w` ...). In v10, five of them are numeric too: unnamed
routines after a `ret`, one of them (0xF65CF1) not even a line start.

### `cmpncp_itemsteps_<tree>.json`: the step routines the item handlers call (2026-10-03)

Two spans of v10/v9 accompaniment_engine.s: 0xF659D1-0xF65B24 and 0xF65B3C-0xF65D64. The first span
starts after `TimeSig_DisplayStrings`, whose 20 ten-byte records end at 0xF659D1. The planner's auto
entry 0xF659A9 falls inside them and was not used. The tables `TimeSig_StepUpTable15` /
`StepDownTable15` in between were typed already. Results:

- `CmpNcp_ItemStep0`..`3` are labelled (the `calr` targets of `CmpNcp_ItemHandler0..3`).
- `TimeSig_StepDownTable26` / `TimeSig_StepUpTable26` (33 bytes each) were `calr 7710` / `max` /
  `ld (P2:8), 8` and are now typed. `scripts/renaming/rename_timesig_step_tables26.sed`, all three
  trees.
- `cp (0x34ed:16), 128` was `.byte 0xc1, 0xed / ldw ix, 0x803f`.
- `CmpNcp_ItemStep3` (0xF65CF1) is decoded from its first byte, with its three local labels.

`keep_original_code` no longer keeps a numeric relative branch, so the render can name its target.
`cmpncp_steps_postedit.py <tree>` labels `CmpNcp_ItemStep4` (0xF65D64, the span's end) and heads the five
routines.

v7: `port_islands.py --src v10 --dst v7 --file sequencer/accompaniment_engine.s --whole 24908-25250
--delta 0x404 --apply` ported all 915 B (v7 0xF655CD-0xF65960, 274 lines, 10 labels); identical after
round 0. `cmpncp_steps_v7_postport.py` restates the carried comments for v7's RAM:
v10 0x342D/0x342E/0x342F/0x34CD/0x34D6/0x34EF = v7 0x3391/0x3392/0x3393/0x3431/0x343A/0x3453.
The v7 comment on the 15-tables had quoted v10's (0x342D) since 257bd204; it now says (0x3391).
With the targets labelled, `symbolize_numeric_branches.py --image v7 --only sequencer/accompaniment_engine.s
--apply --verify` rewrote 26 operands (PASS), the island's eight `calr`s among them.

`call VoiceParam_ClampAndValidate_Tramp` at `DrumVoice_Handler7_Data_Code_Helper`: v10/v9 had it as
`call 16069349`, refused as an R2 fragment because it follows the TimeSig table, and the v7 port copied
the number. It is named in all three trees.


### `timesig_slots_<tree>.json` (2026-10-03)

v10/v9 0xF6604E-0xF66093 (R3 cluster at 0xF6605E):

- `TimeSig_SlotBitMask` (renamed from `TimeSig_DisplayStrings_Code4` by
  `scripts/renaming/rename_timesig_slot_bitmask.sed`, all three trees) holds `01 02 04 08 08 08 08 08`,
  the masks `TimeSig_DisplayStrings_Code_Helper3` ORs into (0x390D).
- `TimeSig_RunSlots0to4` was `.byte 0xc1 / ldw (57:8), 0xc104 / pushw 1081`. No absolute pointer in the
  ROM, no number in the source and no branch reaches it.

v7 (0xF65C4A, lines 25573-25598): `port_islands.py ... --whole 25573-25598 --delta 0x404 --apply`
ported 69 B in 23 lines, identical after round 0. Its comments were then restated by hand with v7's RAM
addresses (0x386E/0x386F/0x3871) and v7's helper names (`DrumVoice_NotifyEE_Helper5/7/10`).

### `accdraw_secondary_<tree>.json` (2026-10-03)

v10/v9 0xF6A489-0xF6A6D9 (R3 clusters at 0xF6A55D and 0xF6A67E):

- `AccDraw_SecondarySub_Handlers` (was `AccScreen_DataBlock_Data`) is 20 `.long`.
- `AccDraw_IndexBitMask` (was `AccScreen_DataBlock_Code3`) is 33 words: 0, then 1 << (n-1).
- `scripts/renaming/rename_accdraw_secondary_tables.sed` did the renames, in all three trees.
- `AccDraw_SecondarySub_Handler00`..`19` were laid out with the twenty pointers as `--entry`. Seven of
  the handlers had started with `.byte 0xc1, 0xe2, 0xe3 / push xiz`.

`accdraw_postedit.py <tree>` drops the carried notes that described the old misframing. Then
`symbolize_numeric_branches.py --image <tree> --only sequencer/accompaniment_engine.s --apply --verify`
rewrote 20 operands with 8 new labels in each of v10 and v9 (PASS).

v7 (0xF6A085, lines 32993-33271): `port_islands.py ... --whole 32993-33271 --delta 0x404 --apply` ported
536 of 592 B, identical after round 0. The pointer table came out half `.byte`, because the handler labels
did not exist in v7 yet, so `accdraw_v7_postport.py` writes it as 20 `.long`. The symbolizer then rewrote 2
more v7 operands (PASS).

### `accautoplay_modeavail_<tree>.json` (2026-10-03)

v10/v9 0xF5AACB-0xF5AAFB (R3 cluster at 0xF5AACB):

- `AccAutoPlay_ModeAvail_Values` (renamed from `AccAutoPlay_ModeAvail_Extended_Code` by
  `scripts/renaming/rename_accautoplay_modeavail_values.sed`, all three trees) is 5 bytes:
  `AccAutoPlay_ModeAvail_Process` reads [(0xFD02) & 3], and the fifth byte pads to an even address.
- The two bytes before it are padding, and their unreferenced label `AccAutoPlay_ModeAvail_Extended`
  is removed.
- `AccAutoPlay_ConfigureIfPending` (0xF5AAD2) is dead code with five branches, now decoded and named.

`accautoplay_postedit.py <tree>` handles the padding label and the stale note. v7 (0xF5A6C7, a `.byte`
run) was written by hand from its bytes, with v7's RAM addresses (0x33D2/0x33FC/0x33FD), and checked by
the byte gate.

### By hand, all three trees (2026-10-03)

- `AccPatch_DefaultSlotData` (v10/v9 0xF5EFA7, v7 0xF5EBA3; R3 cluster at 0xF5EFA8) is the 84-byte default
  record `AccPatch_CopyDefaultsForInit` copies with `ldir`. It was `reti / normal / ld w, 128 / ... /
  jrl ov, 20480`, and is now `.byte` / `.zero` / `.asciz "    clear       "`. The record is identical in
  the three images. The typed text was checked against the v10 bytes before writing, and the gate
  checked all three trees.
- `RhythmVoice_SpaceFill` (v10/v9 0xF63815, v7 0xF63411; R3 cluster at 0xF63813) was already framed
  right. Its three branches were numeric because nothing references the block. It now has labels, and
  the unreferenced positional label `RhythmVoice_WriteBuf_Clamp_Code` on the two padding bytes before it
  is gone.

### `cmpsetttl_cases_<tree>.json` (2026-10-03)

Six R5/R6/mid-line refusals at v10/v9 0xF67F9D-0xF67FE5. `CmpSetTtl_Dispatch2` is the base of
`jp t, (xix+de)` over `CmpSetTtl_DynamicLookup_CaseTable`, whose 12 offsets reach six 16-byte case bodies.
A lane had typed them as text: `":;<> "` is `push xde / push xhl / push xix / push xiz / ld w, ...`.

- Their targets are labelled: `CmpSetTtl_Dispatch2_Helper2` (0xF6616F) and `CmpSetTtl_Dispatch2_Helper3`
  (0xF661AD, mid-line in `ldw de, 15930` before).
- `TimeSig_SlotEntryByte2Offsets` (renamed from `TimeSig_DisplayStrings_Code5` by
  `scripts/renaming/rename_timesig_slot_entry_byte2.sed`) is `34, 42, 50, 58`: byte +2 of the slot
  record's four 8-byte entries, alongside `TimeSig_SlotFieldOffsets` (byte +5).
- The calls the render left numeric (labels defined in another span of the same spec) were named by hand.

`scoop_reframe.py keep_original_code` now also re-renders a `call` / `jp` whose target is a bare number.

v7: `port_islands.py --line 25637` (the `.byte` island at 0xF65CD2: 352 of 360 B, 17 labels) and
`--whole 29307-29368 --delta 0x404` (the case bodies, 94 B). `cmpsetttl_v7_postport.py` then:

- labels the two offset tables;
- names `ld xix, 0xf65da5` / `0xf65de3` and `call 16145895` (`S2cTtl_InitOnTitleChange`);
- restates the carried comments with v7's RAM: v10 0x39AA = v7 0x390E, and v10 0x3989/0x398A..0x3995 =
  v7 0x38ED/0x38EE..0x38F9;
- drops the unreferenced mid-body label `CmpSetTtl_Dispatch2_Code`.

### Two code tables after `ToneGen_Stereo_Return` (2026-10-03, by hand, all three trees)

v10/v9 0xF6288E-0xF62986, v7 0xF6248A, identical bytes. These held three refusals in v10: R6 at 0xF6290A
and two "external" targets, `jp 0x1e1d1c` and `jp 0x09121d`. The bytes are two runs of 120 distinct codes
in 0x01..0x7F, each after `0e 00 00`. No reader was found. No label is referenced, and the only ROM hits
for addresses in the span are three `1e 29 f6` byte runs inside `calr` instructions
(BmDrEdit_DelayAction_SetupAndWalk+11, Part_CheckAndReallocVoices_Join+2, AccPatch_ChIdx1_Bank1+51). The
region is now `.byte` with a comment, and the unreferenced positional label `ToneGen_Stereo_WriteParam_Code`
is removed.

### `accvoice_setupslots_<tree>.json` (2026-10-03)

Four v10 refusals: R5 at 0xF674FD, and `calr 828` / `calr 124` / `calr 92`, whose targets were mid-line.
The fixes, renamed by `scripts/renaming/rename_accvoice_setupslots_data.sed` in all three trees:

- 0xF674FC: `bit 2, (0x041e:16)`, was `.byte 0xf1 / calr 51716`.
- `Rhythm_EndPattern` (0xF67983, was `AccVoice_SetupSlots_DataBlock_Code2`): the one-byte pattern stream
  0x83. The code after it is now `AccVoice_SetupSlots_Apply` (0xF67984).
- `ldir85` (was `.byte 0x85 / scf`). `AccVoice_SlotName_Easy` (was `AccVoice_SetupSlots_DataBlock_Data`)
  is 16 characters; the old `aligned_string "Easy            #"` took the next instruction's `23 00`.
  `AccVoice_SetupSlots_ForEachSlot` starts at 0xF67A12.
- `AccPatch_IndexBitMask8` (0xF67BC9, was `AccVoice_SetupSlots_DataBlock_Code3`) is `01 02 04 08 10 20 40 40`.
  `AccVoice_SetupSlots_CheckStream` starts at 0xF67BD1.

`symbolize_numeric_branches.py --apply --verify` then named the three `calr`s (PASS).

v7: four `port_islands.py --whole ... --delta 0x404` runs (11, 21, 20 and 4 B), then
`accvoice_v7_postport.py`. It restates the comments with v7's names and RAM (0x372D/0x37FC/0x3835/0x343B)
and drops the 17 old "v10 does not spell this byte either" notes of the name and its two following bytes.

### `accompseq_step_<tree>.json` (2026-10-03)

accompseq_routines.s, v10/v9 0xF6EBC0-0xF6EC7A. These held three refusals in v10: R5 at 0xF6EC01 and R3 at
0xF6EC21/0xF6EC27.

- `AccompSeq_MidiFilterCodeBlock` is `or (0xe3e2), 8 / ret`, followed by a second, unreached `ret`.
- Two routines that step (0xFD12) follow: `AccompSeq_MidiFilterCodeBlock_Step` and `_Step2`. The second
  was `.byte 0xc1 / jrl 16254 / nop`, which is `cp (0x7e78:16), 0`. No reference reaches either: the ROM
  hits for 0xF6EC00 straddle two adjacent `.long`s.
- `AccompSeq_LowestBitIndex` (renamed from `AccompSeq_MidiFilterCodeBlock_Code` by
  `scripts/renaming/rename_accompseq_lowest_bit_index.sed`, all three trees) is a 64-byte
  count-trailing-zeros table, checked against the ROM for every a.

v7 held the block as the romslice `v7_transplant_AccompSeq_MidiFilterCodeBlock.bin` (0xF6E7BC). It is ported
(`port_islands.py --whole 1621-1622 --delta 0x404`, 186 B), its comments are restated for v7 (0x7E6F), and
the bin is removed.

## v7 sites named from their v10 counterparts (2026-10-03)

After v10 and v9 reached zero numeric branches, v7 still had 46 refused sites, 37 of them R3 in
accompaniment_engine.s. `scripts/tools/v7_branches_from_v10.py` handles a site only when all of these hold:

- the nearest label above the v7 site also exists in v10;
- v10 has a source line at that label plus the same offset, with the same mnemonic, condition and byte
  length, and it names its target;
- v7 defines that name at exactly the v7 target.

    python3 scripts/converters/symbolize_numeric_branches.py --image v7 --report R.json
    python3 scripts/tools/v7_branches_from_v10.py --report R.json --apply

Run on `v7_report_2026-10-03.json`, the report as it stood: 35 of 46 named, gate PASS. Each of the other
11 has its reason in the tool's output. 0xFDD7C0 has no v7 label where v10 has
`AudioMode_SetStereoFlags`, two v10 counterparts are not line starts, and so on. Before this run,
`symbolize_numeric_branches.py --image v7 --apply --verify` converted 3 sites that its own rules accept.
