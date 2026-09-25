# Lane uimisc -- data-object specs and how they were derived (2026-09-25)

Each `mk_spec_*.py` here prints the JSON spec that
`scripts/converters/retype_data_objects.py` applies: for every object its
address range, label, header (reader routine by name AND v10 address, element
width, stride, how the entry count was pinned) and render type.  The tool
renders the bytes from the ROM, keeps every label other files use (as `.set`
aliases where the object got a better name), rebuilds the image and refuses the
edit unless the ROM is byte-identical.

| file | question it answers | command |
|---|---|---|
| `mk_spec_ee0142.py` | what are the 12 objects in 0xEE0142-0xEE1574 (the tree's `Naka_SubDispatch_A/B_Table`, `Naka_MainDispatch_Table`)? the 972-entry SndParam registry, five per-type handler tables, the 256-entry block RAM pointer table | same command with this spec |
| `mk_spec_eeae44.py` | what are the 38 objects in 0xEEAE44-0xEEC288 (the tree's `SoundEffect_Dispatch_Table` tail + 36 positional names)? chord-recognition table, semitone tables, SMF chunk ids, "COM-ESEQ", switch tables | same command with this spec |
| `mk_spec_ee8c7e.py` | what are the 42 objects in 0xEE8C7E-0xEEAE44 (the tree's `SystemConfig_PointerTable`, `AudioInit_VoiceDispatch_Table`, `CharMap_ValueData_A/B`, 4 B of `SoundEffect_Dispatch_Table`)? | `python3 notes/uimisc-specs/mk_spec_ee8c7e.py > s.json; python3 scripts/converters/retype_data_objects.py --image v10 --file ui_widgets/widget_dispatch.s --spec s.json --nearest --apply` (v9/v7: add `--v10-names`) |

How the readers were found (repeat for any range):

    make rebuilt_ROMs/kn5000_v10_program.llvm.elf
    python3 scripts/analysis/data_readers_profile.py --image v10 0xEE8C7E 0xEEAE08 --next 7
    python3 scripts/analysis/data_pointer_scan.py   --image v10 0xEE8C7E 0xEEAE08

`data_readers_profile.py` lists every instruction operand that names an
address in the range, with the following instructions (element width from
`ld_rrb`/`ld_rrw`/`ld_rrl`/`ldb_sri`, strides from `muls`/`sla`, use from
`call (xhl)` / `jp_rr` switches).  `data_pointer_scan.py` lists 32-bit words
anywhere in the ROM that point into the range.  Both have blind spots (a base
passed in a register from afar, `TABLE - 4*k` constants, misframed code); a
header that says "no reader" names the two scans it ran.

Measured facts the headers rely on (v10 ROM, re-derivable with the commands
above):

* the seven chord-row tables 0xEE8FCE-0xEEADFE: six of them are exactly
  28 x 12 x k bytes up to the next referenced object (k = 1,2,4,1,3,3 from each
  reader's `muls wa,12k`), the seventh (0xEEA8BE) likewise 28 x 48; the 1680
  bytes 0xEEA22E-0xEEA8BE have no reader in either scan;
* `Harmony_HandlerTable` entries 1-13 are exactly SoundFX_Handler_0..12, the
  routines that read the chord-row tables.
