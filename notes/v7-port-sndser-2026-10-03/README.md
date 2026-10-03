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
