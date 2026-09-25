# Lane `seui` (2026-09-25 semantic push) -- sound-editor UI files

Owned files (v10, v9 and v7 copies): `audio/sound_editor_ui.s`,
`sound_editor_routines.s`, `sound_editor_screens/*`, `semenu_routines.s`,
`sndparam_routines.s`, `sndparam_records/*`.

| script | question it answers | command |
|---|---|---|
| `se_gfx_wrappers_probe.py` | Are the 17 `SeGfx_*` wrappers (ex `SeMenu_NameEditor_*`) what their names say? Reads both ScreenData handler tables out of each ROM and checks every wrapper's single `call` (decoded by MAME unidasm) against the table entry its name claims, and its use of the RAM record buffer 0x6CA. | `python3 scripts/lanes/seui/se_gfx_wrappers_probe.py` (needs the three `.llvm.elf`) |
| `seui_census_summary.py` | How much of this lane's files is CODE / KNOWN-A / KNOWN-B / UNKNOWN / research target, plus data-as-code markers and v7 romslice bytes? | `python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json && python3 scripts/lanes/seui/seui_census_summary.py X.json` |
| `seui_amap.py` | Which source line emits which address, for v10, v9 AND v7 (reuses the census's proven-inert mirror)? | `python3 scripts/lanes/seui/seui_amap.py --image v7 --out amap.json` |

The rename itself is `scripts/renaming/rename_seui_gfx_wrappers.sed` (applied to
the three `sound_editor_ui.s`).  `scripts/renaming/rename_maincpu_seq_init_labels.py`
still holds the old `SeMenu_NameEditor_*` names: it is the historical record of
an earlier pass and is deliberately left as it was.

## The screen-data block (`SeScreenData` .. `SeScreenData_End`)

| script | question it answers | command |
|---|---|---|
| `se_screendata_model.py` | What is every byte of the 19,617-byte block v10/v9 0xF10C06-0xF158A7 (v7 -0x2A), and which code or pointer field pins it? Seeds on every `ld xiy/xix/xiz, imm32` into the block, walks the code symbolically to the `SeGfx_*` call, parses each list exactly as the interpreter does, follows every pointer field the handlers dereference. | `python3 scripts/lanes/seui/se_screendata_model.py --image v10 [--json out.json]` |
| `se_screendata_render.py` | Re-spell the block as typed data (one macro line per record, `.long` tables, `.ascii` cells, `.short` boxes, one `.byte 0b........` per bitmap byte) keeping the C-descriptor `.incbin`s, comments, `.set`s and referenced labels. `--apply` writes; `make gate` certifies. | `python3 scripts/lanes/seui/seui_amap.py --image v10 --out A.json --files audio/sound_editor_ui.s && python3 scripts/lanes/seui/se_screendata_render.py --image v10 --amap A.json --apply` |
| `se_screendata_symbolize_refs.py` | Rewrite the code's operands into the block (numeric `0x00f1xxxx`, and positional aliases of the old wrong base names such as `SeBitmap_EnvCurve5_0x46B`) to the label the block now defines at that address; a list END that is no object's start becomes `<nearest label> + N`. Only this lane's files, only operands. | `python3 scripts/lanes/seui/se_screendata_symbolize_refs.py --image v10 [--apply]` (needs the linked ELF) |
| `gate_perturbed_2026-09-25.log` | Does the byte gate SEE the rendered data? One number changed in one record (`sd_quad 0x09, 5, 30, 43, 47` -> `48`): `make gate` went red, `kn5000_v10_program 1 BYTES DIFFER` (at 0xF1144A). Restored before commit. | (a log, not a script) |

What the model established (v10; v9 and v7 have identical structure):

* **248 record lists, every one parsing EXACTLY to the end its code states** --
  0 over/under-runs, from 143 code sites; 1,382 records (1,188 static, 194
  bound), 13,709 B.  A misread length anywhere in a list would miss its end;
  that is the falsifiable test of the framing.
* 128 single records, 13 list-boundary tables (entry i..i+1 = list i), 17
  record-pointer tables (read by the helper at v10 0xF10BE7, `xiy=table[wa]`),
  8 list-start tables, 1 (start,end) pair table, 1 record-group table
  (`ptr + 10*value`), 24 string tables, 12 box tables, 4 u16 coordinate
  tables, 13 bitmaps.
* Record layouts are the handlers' reads, each disassembled from the ROM with
  MAME unidasm: see the macro header at `SeScreenData` in
  `audio/sound_editor_ui.s`.
* Bitmaps are stored COLUMN BY COLUMN: the blitter reached from static op 03
  (v10 0xFAFB48) loops y inside each 8-pixel column (`incw 1,(xsp+8)`,
  `add (xsp+0x18),1`) and only then steps x by 8 (`incw 0,(xsp+6)`).  Read that
  way the 13 bitmaps are coherent pictures (six 40x40 envelope curves, four
  24x10 patterns, a filled and an empty 16x12 circle, one unreferenced 40x40
  picture); a row-major reading is noise.
* 314 B have no reader (listed with their admission in the source): a 40x40
  picture, a duplicate of a referenced string table, two identical 30-byte
  record groups and a 20-byte one inside C blocks, and `"+-"`.
* Hand refinements after the render (so a re-render will not reproduce them
  byte-for-byte in the text): the 40x40 picture is `SeBitmap_Picture40x40`
  with a note that its address occurs only as a list END, and the 14 dead
  `.set TuningSys_Param_02..13/_NamesAndCoords/_ModeSelect` aliases are gone.
* ⚠ Correction to `sound_editor_screens/*.c`: `SD_LABELED_REF_TYPE.addr`
  (op 06) is not an address -- the op-06 handler divides it by 40; it is the
  y*40 + x/8 cell position.  The "op 0x02 subtype" there is the ordinary length
  byte.  The C files still compile byte-exact and are left as they are.

## Mis-framed code (`se_reframe_code.py`)

| mode | question it answers | command |
|---|---|---|
| auto (v10/v9) | Where does this lane's code spell a real instruction as a lone `.byte` prefix plus "instructions" made of its operand bytes (e.g. `.byte 0x8f` / `push xsp` / `nop` for `cp (xsp+2), 0`), and what is the right instruction? Seeds on `.byte` and data-as-code-marker lines; replaces only the mis-framed middle of a window where the tree's backend (llvm-objdump) and MAME unidasm agree on every instruction boundary and meet the old framing again; the window must be flanked by real instructions on both sides (a `.byte` row of a data table never is), and the SeScreenData block is excluded. Lines whose framing the decode confirms are kept verbatim. | `python3 scripts/lanes/seui/seui_amap.py --image v10 --out A.json --files audio/semenu_routines.s,audio/sndparam_routines.s,audio/sound_editor_ui.s,audio/sound_editor_routines.s` then `python3 scripts/lanes/seui/se_reframe_code.py --image v10 --file audio/semenu_routines.s --amap A.json [--show] [--apply]` |
| --runs (v7) | Can a v7 `.byte` / romslice run in code be spelled as instructions? Lock-step decode following unidasm's framing, each instruction spelled by the backend at the same address and length (else kept as `.byte`), ending where the old framing resumes; a THIRD witness is required: at least 90% of the instructions whose bytes are equal in the witness image (offset chosen from same-named labels) must start a source line there. | `... --image v7 --file F --amap A7.json --runs --witness v10 A10.json [--apply]` |

Result of the auto mode on 2026-09-25 (then `symbolize_numeric_branches.py
--only <the four files> --apply --verify`):

| image | windows re-framed (semenu / sound_editor_ui / sndparam) | branch operands symbolised | labels added |
|---|---|---:|---:|
| v10 | 269 / 363 / 20 | 620 | 380 |
| v9 | 269 / 363 / 22 | 622 | 381 |

Refused (left as they were): backend cannot decode 13/37/29, not flanked by
code 21/48/25, a label that would fall inside a new instruction 1
(`SeMenu_CompareAndApply_Data6`).
