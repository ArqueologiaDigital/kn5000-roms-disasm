# v7 audio/sndparam_routines.s + midi/midi_serial_routines.s: the 0x41A drift removed (2026-10-03)

Wave-3b plan, lane A ("v7 drift consolidation"): the v7 labels of `audio/sndparam_routines.s` sat
0x41A bytes away from the code they name (66 of them as `.set Name, . + k` inside instructions), and
other files reached the real routines as `<drifted label> + k`.

**Question:** can this span carry v10's names at the addresses of v10's code, keep every instruction
the pre-port files had, and still build the v7 dump byte for byte?  **Yes:** `run.sh`.

| file | measure | before | after |
|---|---|---:|---:|
| audio/sndparam_routines.s | labels aligned / drift / v7-only / no match (`v7_label_drift.py`) | 0 / 69 / 225 / 33 | 191 / 0 / 42 / 82 |
| | `.set Name, . + k` aliases | 66 | 0 |
| | `.byte` rows | 66 | 8 |
| midi/midi_serial_routines.s | labels aligned / drift / v7-only / no match | 45 / 2 / 1 / 53 | 93 / 0 / 10 / 59 |
| | `.byte` rows | 8 | 7 |

How (`run.sh`, every step refuses or the build proves it):
1. `scripts/converters/port_v10_span_to_v7.py --span sndser` (new span: the two files are one stretch of
   v7 -- the sndparam tail IS the start of v10's serial code) ports every v10 line whose bytes recur in
   v7.  With `PORT_GAPFILL=1`, a gap (v7 bytes with no byte-identical v10 line) keeps the pre-port
   lines when they tile it exactly (42 of 43 gaps); pre-port labels there keep their names unless
   `v7_label_drift.py`'s test finds v10's bytes for that name elsewhere nearby (then they are renamed
   under the nearest new label, `INTTX0_HANDLER_Skip`).  With `PORT_REPOINT=1`, a pre-port label that
   other files reach only as `Name + k` is not kept.
2. `scripts/converters/repoint_v7_after_port.py` re-aims those references (35) at the label now at the
   address each one meant (its old address from the committed symbol file, plus k).
3. One reference had no label at its address, `SndParam_RegisterHandlers[4]` (v7 0xFCD5CA): labelled
   `SndParam_RegisterType4_Handler` (the table's own index; v10's table order differs).
4. The island at 0xFCCE4A (kn5000_v7_program.s) named its labels `SndParam_RW_*_v7` only because the
   drifted file held the plain names; renamed (scripts/renaming/rename_v7_rw_island_plain_names.sed).

Not done: `midi/midi_dispatch_handlers.s` still has 2 labels at -0x41A; the rest of lane A
(midipkt_routines.s <-> dsp_config_sysex.s, screen_group_dispatch.s, the `.set` aliases of
kn5000_v7_program.s) is untouched.  `scripts/converters/split_byte_runs_by_decode.py` (split a `.byte`
run at unidasm's boundaries so respell_raw_pseudos.py --bytes can respell it) was written for an earlier
attempt of this port and is not part of `run.sh`; the gap fill made it unnecessary here.

## The -0x41A drift left in v7 after this port (measured the same day)

`v7_label_drift.py` over every v7 file: 20 labels still sit 0x41A after v10's code of their name, all
in the 0xFD8000-0xFEFFFF stretch, and every one is referenced from code (so it marks a real entry
point that needs ITS v10 name), and most of the true addresses already carry another v7 name -- a
rename chain, not a move.  `refs` counts occurrences in v7 sources minus the definition.

```
audio/dsp_config_sysex.s SysEx_ValidateRolandHeader_Cmd33 0xfdaab2 -> 0xfda698 refs 3 there: ['SysEx_DispatchByChannel_49_Entry_Code_Skip2']
audio/dsp_config_sysex.s SysEx_ApplyVoiceParam_49 0xfdac20 -> 0xfda806 refs 48 there: ['SoundMode_ApplyVoiceParams_Helper']
audio/dsp_config_sysex.s BitMapOut_CopyRegion_Done 0xfdb24c -> 0xfdae32 refs 4 there: ['BitMapOut_RenderDisplay_Skip']
audio/note_voice_mapping.s UIParam_CallbackReturn 0xfe8887 -> 0xfe846d refs 6 there: ['UIParam_ScanAndCollect_Loop']
audio/note_voice_mapping.s VoiceSlot_CheckAndApply_Data 0xfe9f94 -> 0xfe9b7a refs 35 there: ['Chord_Tables']
audio/note_voice_mapping.s VoiceSlot_CheckAndApply_Data2 0xfea15f -> 0xfe9d45 refs 5 there: ['Chord_BitMask16']
audio/note_voice_mapping.s SndParam_ProcessEntry 0xfea4ca -> 0xfea0b0 refs 6 there: []
audio/note_voice_mapping.s MIDI_SendChannelPressure 0xfeb7b0 -> 0xfeb396 refs 4 there: ['SndPart_SetParam_Helper']
audio/note_voice_mapping.s SeqVoice_CheckAndRet_Data 0xfeb8a1 -> 0xfeb487 refs 18 there: ['SndPart_SetParam_Helper2']
audio/note_voice_mapping.s ReadNextRecord_Block 0xfedc26 -> 0xfed80c refs 7 there: ['FileIO_ReadNextRecord_Loop']
audio/note_voice_mapping.s ApplyProgramChangeAs_LoadReg2 0xfee429 -> 0xfee00f refs 3 there: ['SndParam_FetchOscTableEntry_Helper']
audio/note_voice_mapping.s SndParam_LookupOscEnvelope 0xfee53c -> 0xfee122 refs 8 there: ['MidiPgmChg_Mode0_SetupA_Code_Helper']
audio/note_voice_mapping.s TmFlash_Return_LoadReg 0xfef1cf -> 0xfeedb5 refs 7 there: ['TmFlash_Return_Prologue_Loop']
audio/note_voice_mapping.s SendPartDataBlock_Data3 0xfefc57 -> 0xfef83d refs 3 there: []
audio/note_voice_mapping.s SendPartDataBlock_Data5 0xfefd3f -> 0xfef925 refs 3 there: []
audio/note_voice_mapping.s SendPartDataBlock_InitVal4 0xfefd6e -> 0xfef954 refs 4 there: ['HdaeRom_DataHandler_Helper3']
midi/midi_dispatch_handlers.s VoiceData_ZeroFillInner 0xfd86ae -> 0xfd8294 refs 8 there: ['VoiceData_ZeroFillAll_Loop']
midi/midi_dispatch_handlers.s VoiceParam_MultiBlock_Epilogue_Data 0xfd98ce -> 0xfd94b4 refs 4 there: []
midi/midipkt_routines.s MidiPkt_ExtractAndPack 0xfd994d -> 0xfd9533 refs 3 there: []
midi/midipkt_routines.s MidiPkt_EnqueueControl_335C 0xfd9fd2 -> 0xfd9bb8 refs 5 there: ['SeqAlt_DescriptorBlock_Data_Helper']
```
Reproduce: the snippet that wrote this list is `drift41a.py` beside this README.

## Resolved 2026-10-06

`scripts/tools/fix_v7_displaced_names.py` moved every name of v7 0xFCC000-0xFF2000 to the v7 code v10
gives that name, using a measured v7 <-> v10 map (12-byte sequences unique in both ROMs, in runs of one
delta) instead of a per-name search.  The table above was the part of the drift that other files
referenced; the same band also held ~360 derived names built on the displaced ones
(`MidiPkt_ArpConfigChain_Data_Helper18_Helper`, `AudioDispatch_CheckStereoMode_Code_Skip26`, ...), which
took v10's names site by site.  `drift41a.py` above now prints nothing, and
`python3 scripts/tools/fix_v7_displaced_names.py --audit` reports 0 names in the band away from v10's
code of them.
