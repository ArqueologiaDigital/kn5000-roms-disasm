# Lane `seqeng`, 2026-09-25 -- tools and how to re-run them

Lane `seqeng` owns the five sequencer sources (`sequencer_engine.s`,
`seq_event_playback.s`, `smf_event_processor.s`, `smf_tonegen_core.s`,
`smf_playback.s`) in `v10/`, `v9/` and `v7/` maincpu.

| script | question it answers | command |
|---|---|---|
| `scripts/analysis/seqeng_line_map.py` | which ROM address does line L of one of these files emit? (v10/v9/v7; proven-inert mirror build) | `python3 scripts/analysis/seqeng_line_map.py v9 sequencer/seq_event_playback.s --addr 0xF71A24` |
| `scripts/analysis/seqeng_misframe_zones.py` | where does the source's instruction framing disagree with MAME unidasm's (misframed multi-byte instructions)? | `python3 scripts/analysis/seqeng_misframe_zones.py v10 sequencer/sequencer_engine.s --unidasm <v10.unidasm>` |
| `scripts/converters/seqeng_reframe.py` | rewrite those zones on unidasm's framing, instruction by instruction, only where llvm-mc decodes the same bytes as ONE instruction, re-assembles them exactly, AND agrees with unidasm on the operation and registers; `.byte` + unidasm text otherwise | `python3 scripts/converters/seqeng_reframe.py v10 sequencer/sequencer_engine.s --auto --unidasm <v10.unidasm> [--apply]`; `--selftest` checks the agreement rule on synthetic pairs |
| `scripts/converters/seqeng_code_runs.py` | which census `embedded-in-code` data runs are really code, and what are their instructions? (fresh unidasm framing from the run's start, evidence per zone) | `python3 scripts/converters/seqeng_code_runs.py v7 sequencer/sequencer_engine.s --census X.json --unidasm <v7.unidasm> --xref v10 [--apply]` |
| `scripts/converters/seqeng_symbolize_imm.py` | which numeric ROM addresses in 32-bit loads / address arithmetic have a label at exactly that address? | `python3 scripts/converters/seqeng_symbolize_imm.py v7 [--apply]` |
| `scripts/converters/seqeng_retype.py` + `notes/seqeng-2026-09-25/retypes.py` | retype a data object spelled as code, from the dump, under an evidence header written in `retypes.py` (reader name + per-image address, stride, count) | `python3 scripts/converters/seqeng_retype.py v10 notes/seqeng-2026-09-25/retypes.py [--apply]` |
| `scripts/renaming/rename_seqeng_2026_09_25.sed` | the lane's label renames (FloppyIO_SwitchboardChannelPtrs -> ChannelRecord_PtrTable; call sites of VoiceChannel_ParamTable1_0x80 -> VoiceChannel_SetRecordField3) | `sed -i -f scripts/renaming/rename_seqeng_2026_09_25.sed <file>` |
| `scripts/analysis/seqeng_v7_call_targets.py` -> `v7-unlabelled-call-targets.txt` | what do the still-numeric v7 `call`s in these files call? (v7 target, the v7 label it falls inside + offset, and the v10 name of the matching call's target, by masked byte context) -- a worklist for the owners of the TARGET files | `python3 scripts/analysis/seqeng_v7_call_targets.py sequencer/sequencer_engine.s sequencer/seq_event_playback.s sequencer/smf_event_processor.s sequencer/smf_tonegen_core.s sequencer/smf_playback.s` |
| `scripts/tools/seqeng_annotate_swapped_dpi.py` | which `lda_dpi`/`stb_dpi` lines (backend mnemonics swapped) are in these files, and what does each really do? appends unidasm's decode of the line's own bytes | `python3 scripts/tools/seqeng_annotate_swapped_dpi.py v10 [--apply]` |
| `scripts/tools/seqeng_stale_v10_notes.py` | which of v7's `; v10 does not spell this byte either` notes are now false (v10 spells those bytes as instructions)? | `python3 scripts/tools/seqeng_stale_v10_notes.py [--apply]` |
| `scripts/analysis/seqeng_measure.py` | per-file census grades (CODE/KNOWN-A/KNOWN-B/UNKNOWN/FILLER/research) + data-as-code markers + numeric branches + v7 romslice bytes | `python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json && python3 scripts/analysis/seqeng_measure.py X.json` |

The unidasm listings are regenerable (not committed for v9/v7):

    ../tools/unidasm original_ROMs/kn5000_v9_program.rom -arch tlcs900 -basepc 0xE00000 > v9.unidasm
    ../tools/unidasm original_ROMs/kn5000_v7_program.rom -arch tlcs900 -basepc 0xE00000 > v7.unidasm

(`original_ROMs/kn5000_v10_program.rom.unidasm` is committed and identical to a
fresh run.)

## Guards in seqeng_reframe.py, and the case that forced each

* **zone ends on agreed boundaries** -- first byte and end must be unidasm
  instruction starts, and the unidasm walk must land exactly on the end.
* **misframe signature** -- the old text of the zone must contain a `.byte`
  fragment or an absurd mnemonic, else unidasm (not the source) may be the
  one out of sync.
* **shape guard** -- a zone holding a `.long`/`.short`/`.ascii` line or a
  `.byte` line of more than 4 values is refused: seen, v10
  `smf_event_processor.s` 0xF532A9, a two-entry pointer table followed by a
  `ret` that unidasm read straight through.
* **decode-absurdity guard** -- a zone whose unidasm framing reads as data
  (`db`, `(r+)`/`(-r)` stores, `call 0x00..`, halt/swi/...) is data typed as
  code, not a misframe: seen, `VoiceChannel_ParamTable1` (32-bit RAM pointers
  0xF496 + 26k).
* **referenced mid-instruction label** -- refused: seen, `SndParam_LookupChannelVoice`
  (0xF26E81) is a real entry, and unidasm had eaten its first byte as the
  operand of `ei` after three data bytes.
* **operation agreement** -- seen, `f5 e0 31`: unidasm `lda XBC,(XWA+)` (the C
  idiom `p = q++`), llvm-mc `stb_dpi a, 224`.  The LLVM backend has the
  mnemonics of F5-prefix opcodes 0x31 and 0x41 SWAPPED (`f5 e0 41` prints as
  `lda_dpi xbc, 224` but is `ld (XWA+),A`).  Those are written as `.byte`.

★ RESOLVED 2026-09-25 (TOOLCHAIN_VERSION UPDATE 17): the swapped `lda_dpi` /
`stb_dpi` mnemonics and the missing post-increment syntax are fixed in the
backend (llvm-project ac3f1ed19ab6); every annotated line is now spelled
`ld (xde+), a` / `lda xbc, (xwa+:1)` and the `(backend mnemonic is swapped)`
annotations are gone (scripts/converters/wave3a_respell.py autoinc).  The text
above is the record of what this lane found and did.
