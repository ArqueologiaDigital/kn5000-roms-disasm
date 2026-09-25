# Lane `scoop` — semantic push 2026-09-25

Files: `display/scoop_display.s`, `display/scoop_editor_data.s`,
`display/graphics_text_vga.s` in `v10/`, `v9/` and `v7/` maincpu.

## Tools (what question each answers, exact command)

| tool | question |
|---|---|
| `scripts/converters/scoop_reframe.py plan` | Following control flow with MAME `unidasm` from every trusted reference, which bytes of a span are code (and where does each instruction start) and which are data? |
| `scripts/converters/scoop_reframe.py islands` | Which source lines frame their bytes differently from that plan (the misframes / data-as-code / code-as-data islands)? Everything else is left exactly as written. |
| `scripts/converters/scoop_reframe.py apply` | Re-spell only those islands; is the linked image still byte-identical?  (Rolls every file back if not.) |
| `scripts/analysis/scoop_lane_measure.py` | Per-file census grades, research targets, data-as-code markers, numeric branch operands, romslice bytes. |

### How the plan decides code vs data (`plan`)

Entries, in order of trust:

1. every `call/jp/jr/jrl/calr/djnz` reference to a name in the span from
   another file, and every `.long`/`addr24` reference whose target decodes
   cleanly (a value table the source had decoded as code is refused: see the
   `SUSPECT ptr entry` lines of the run);
2. **A** internal branch references whose referring instruction is itself
   traced code (a branch written inside data-as-code is a phantom and does not
   count);
3. **B** targets of runs of ROM pointers found in unreached bytes, 32-bit
   values elsewhere in the ROM that point into the span (only when preceded by
   an `ld xRR,#32` opcode or inside a pointer run), and `ld xRR, NAME` loads
   whose register is then called (`call (xRR)`) or handed to
   `UIRender_TwoTableGeneral` as its callback;
4. **C** any line start in unreached bytes whose decode is clean and ANCHORED
   (branches/calls to a traced instruction or a known routine outside the span,
   or joins traced code after >= 3 instructions), no nop/ei/di/SFR-page operand;
5. **D** what the source already spells as code, if its decode is clean, >= 8
   bytes, >= 3 instructions, `ret`-terminated and free of odd instructions.

Refused everywhere: undecodable bytes, `halt/incf/decf/ldf/normal/max/min/swi`,
`jr cc,+0`, `jr f`, branches out of ROM or into the middle of a traced
instruction, text (printable with real letters — push/pop runs such as
`9:;<=>` are told apart), and 2+ consecutive ROM pointers.

Each instruction is framed by unidasm and spelled by the LLVM backend only if
it decodes the same bytes AND re-assembles to them; otherwise the tree's own
spelling for those exact bytes (or its SRI/DRI template, e.g. `cpib_sri`), else
`.byte` with unidasm's reading as a comment.

### v10 / v9 `display/scoop_display.s` (whole file 0xEF5B02-0xF03719)

    python3 scripts/converters/scoop_reframe.py plan --image v10 \
        --file v10/maincpu/display/scoop_display.s --lo 0xEF5B02 --hi 0xF03719 \
        --exclude 0xEFE989 --entry 0xEFB0D3 --entry 0xEFF326 --entry 0xEFF077 \
        --entry 0xF0029C --entry 0xF000BB --out PLAN.json
    python3 scripts/converters/scoop_reframe.py islands --image v10 --plan PLAN.json --out ISL.json
    python3 scripts/converters/scoop_reframe.py apply --image v10 --spec ISL.json
    python3 scripts/converters/symbolize_numeric_branches.py --image v10 \
        --only display/scoop_display.s --apply --verify

(same with `v9` — the v9 plan is instruction-for-instruction identical to v10's).

Manual overrides and why:

* `--exclude 0xEFE989` — `OscScope_FinalizeRender` is cited by `.long` from
  `ui/drawbar_panel_ui.s` and `ui/ui_mode_handlers.s`, but 0xEFE989 is two bytes
  into `ld xix, 0x0e59` (0xEFE987, reached by fall-through from `ld xiy, 0x0e55`
  at 0xEFE982).  The name is kept as `.set OscScope_FinalizeRender, . + 2`.
  Same for `OscScope_DrawWaveform` (0xEFE808 = 3 bytes into `ld (0x0ec2), wa`),
  cited only by a `.long` inside misframed code in `sequencer/smf_event_processor.s`.
* `--entry 0xEFB0D3` — `MemConfig_Handler_3` (in `MemoryConfig_Handler_Table`):
  five `call`s to traced routines then `cp (0x0d6a),0 / jrl z,+0 / ld w,0 / ret`;
  the `jrl z,+0` is what the absurd-marker rule refuses, the rest is plainly code.
* `--entry 0xEFF326` — `ld xiy, <"OFF">` falling into the tail at 0xEFF32B
  that the `ld xiy, <" ON"> / jp 0xEFF32B` path also uses; no reference to
  0xEFF326 was found (byte scan for its 24-bit address: none), so it is kept as
  (unreached) code rather than re-typed.
* `--entry 0xEFF077`, `0xF000BB`, `0xF0029C` — lone `ret` bytes between routines;
  0xF00299/A/B, three identical `ret`s next to 0xF0029C, are each `call`ed from
  0xEFCC4F/0xEFCE9F/0xEFCEA7, so these are kept as empty routines, as the
  source already had them.

Idempotence check: re-running `plan` on the re-framed file gives the SAME
instruction set (16,189 instructions) and `islands` then reports **0 islands**.

### v10 / v9 `display/graphics_text_vga.s` and `display/scoop_editor_data.s`

`graphics_text_vga.s` has two spans of its own (it `.include`s
`ui/bitmap_out_routines.s` and `ui/ui_mode_handlers.s` in the middle):

    plan --image v10 --file v10/maincpu/display/graphics_text_vga.s --lo 0xFB13B0 --hi 0xFB3F8C
    plan --image v10 --file v10/maincpu/display/graphics_text_vga.s --lo 0xFC1A22 --hi 0xFC2F93
    plan --image v10 --file v10/maincpu/display/scoop_editor_data.s --lo 0xF03D80 --hi 0xF0616F

(then `islands`, `apply`, symboliser; the same for v9, whose plans are
instruction-for-instruction identical to v10's).  No manual overrides.

`islands` only re-types code as data on POSITIVE evidence (text, ROM pointers,
an absurd or undecodable decode, a branch out of ROM, or a decode that runs past
the segment).  Unreached code without such evidence is left as the source had
it and printed as `KEPT AS CODE`: here `BitMapOut` (0xFB3F67, the routine that
runs on into `ui/bitmap_out_routines.s`), the `VGA_Stub_1..3` `ret`s,
`WallSureShowHideFunc`, `MainSysCtrl_Entry8`, `AcTranspose_ParamData`
(`ld xhl, 0x01020004 / ret`), two `jr t,+0` join bytes and three short tails in
`scoop_editor_data.s`.  (The same rule applied retroactively to the
`scoop_display.s` plan flags only two segments, both data by their reader: a
4-byte slice of the `.long` table at 0xEFB2B3-0xEFB307 and the display list
`Scoop_DisplayData_ButtonLayout` handed to `UIRender_TwoTableGeneral` in xiy.)

### v7 (all three files; every romslice retired)

    plan --image v7 --file v7/maincpu/display/scoop_display.s --lo 0xEF5AD8 --hi 0xF036EF \
         --exclude 0xEFE95F --entry 0xEFB0A9 --entry 0xEFF2FC --entry 0xEFF04D \
         --entry 0xF00272 --entry 0xF00091
    islands --image v7 --plan PLAN.json --force-data 0xF00A79
    plan --image v7 --file v7/maincpu/display/scoop_editor_data.s --lo 0xF03D56 --hi 0xF06146 \
         --entry 0xF05132 --entry 0xF051C2
    plan --image v7 --file v7/maincpu/display/graphics_text_vga.s --lo 0xFB0FA3 --hi 0xFB3B7F
    plan --image v7 --file v7/maincpu/display/graphics_text_vga.s --lo 0xFC1257 --hi 0xFC27C8

The v7 overrides are the v10 ones at their v7 addresses (located by byte
context: v10 0xEFE989/0xEFB0D3/0xEFF326/0xEFF077/0xF0029C/0xF000BB =
v7 0xEFE95F/0xEFB0A9/0xEFF2FC/0xEFF04D/0xF00272/0xF00091), plus the two
`extz wa / ld bc,3 / ldw de,48 / jr <join>` alternate entries of the sound
editor that v10 holds as code at 0xF0515C/0xF051EC (v7 0xF05132/0xF051C2), and
`--force-data 0xF00A79`: the 8-byte display list v10 calls
`Scoop_DisplayData_ButtonLayout`, which its reader loads into xiy for
`UIRender_TwoTableGeneral` (byte-level evidence alone cannot see a reader).
`islands` always re-types a `.incbin` in the span.

Corroboration (scripts/analysis/scoop_v7_v10_correspondence.py, unidasm
mnemonic streams of the two images aligned with difflib):

| v7 span | v10 span | matching instructions |
|---|---|---|
| 0xF03D56-0xF06146 (scoop_editor_data) | 0xF03D80-0xF0616F | 3,421 / 3,422 (ratio 1.000) |
| 0xFB0FA3-0xFB3B7F (graphics_text_vga) | 0xFB13B0-0xFB3F8C | 3,986 / 3,986 (1.000) |
| 0xFC1257-0xFC27C8 (graphics_text_vga) | 0xFC1A22-0xFC2F93 | 1,689 / 1,689 (1.000) |
| 0xEF5AD8-0xF036EF (scoop_display, data included) | 0xEF5B02-0xF03719 | 18,113 / 19,240 (0.942) |

The retired `.bin` romslices under `v7/maincpu/includes/romslices/` are no
longer referenced by these files; they are owned by lane `sys` and were left
in place.

Correction to 02d072ed: v7 scoop_editor_data.s held 9 romslices, not 11
(the 7,434 B figure was right).


## Semantic pass (after the re-frame)

| step | tool | what it does |
|---|---|---|
| pop-up family | `scripts/converters/scoop_popup_names.py` | the hand-written record: 27 routines (ParamPopup_*, Disp_ShowNoteNameAndVelocity, Disp_ShowNoteValueFields) and 41 text tables, each header naming the instructions it rests on; v9 same addresses, v7 located by byte context with its moved RAM block learned by aligning unidasm streams |
| drafts | `scripts/analysis/scoop_data_readers.py`, `scripts/analysis/scoop_data_headers.py` | every data object, split at every address something loads, with its readers and their index arithmetic |
| headers | `scripts/converters/scoop_auto_headers.py` + `scoop_annotate.py` | reader-cited header (and a label when missing) for every object not already KNOWN-A; dispatch/pointer tables re-spelled one `.long <label>` per entry, unlabelled handler targets get `<Table>_Target<k>` |
| numbers | `scripts/converters/scoop_symbolize_imm.py`, `scoop_label_numeric_targets.py` | ROM addresses written as numbers in instruction operands made symbolic (label added first where the target is in these files) |
| corrections | `scripts/converters/scoop_refresh_headers.py`, `scoop_rename_unref.py` | re-derive generated headers after readers became visible; rename `Unref_*` placeholders that turned out to be read |
| 2-line rule | `scripts/converters/scoop_header_second_line.py` | the census credits only >= 2-line headers: adds the reader's instruction line under one-liners |
| spellings | `scripts/converters/scoop_respell_byte_insns.py` | `.byte`-written instructions the backend can spell after all (`srla e`, `popw (0x0d5c:16)`, `xorcf a, (m:16)`, `add xhl, (0x2a:8)`, `rrc_i_8 a, 3`) |
| branches | `scripts/converters/scoop_symbolize_rel.py` | numeric relative branches the shared symboliser refused (R3/R5), re-checked site by site against unidasm |
| labels | `scripts/renaming/scoop_reparent_structural.py` (+ committed `rename_scoop_reparent_*.sed`) | structural labels on code whose parent was a DATA label, re-parented onto the enclosing routine |

## Measured before / after (all three versions, the three files summed)

    python3 scripts/analysis/data_range_census.py --images v10,v9,v7 --json X.json
    python3 scripts/analysis/scoop_lane_measure.py --census X.json [--base BEFORE.json]

Before = branch base 3958235e; after = this branch's head.  Toolchain
tlcs900_backend@4d7fa4f6b37c for every figure.

| | before | after |
|---|---:|---:|
| CODE | 200,392 | 229,279 |
| KNOWN-A | 747 | 16,871 |
| KNOWN-B | 45,644 | 231 |
| UNKNOWN (honest admissions) | 0 | 402 |
| research targets | 31,574 | 624 |
| data-as-code markers (lane_worklists.py ABS rule) | 1,701 | 0 |
| numeric branch operands | 2,154 | 39 (v7 only, targets in other lanes' files) |
| v7 romslice bytes | 23,038 | 0 |

The per-file table is `measure_final.txt` next to this file.

The 46 retired romslice files are listed in `retired_romslices.txt`; none
is referenced by any v7 source any more (checked with a byte-safe search),
and they belong to lane `sys` to delete.

## What remains (and why)

* v7: 16 `calr` to 0xFAFAC0 and 23 absolute `call`/`jp` (0xFDD89E x5,
  0xFE2F1D x2, 0xFE2CBC x6, ...) point into OTHER lanes' files at addresses
  where no label stands -- in each case inside a data line there, so the
  owners' files are misframed or mis-typed at those addresses.
* backend has no spelling for `cp BC/IY,(XIX+IZ)` (d3 07 f0 f8 f1/f5) and
  `ldcf/stcf A,RH3` (c7 3d 2b/2c): still `.byte` with unidasm's reading.
* honest unknowns: the 64-byte second part-name scheme after Str_TuningEq,
  Str_ExtTabEffectEnDis, Unref_EF6BD3_Tbl / Unref_EFA7C5_Tbl (v10/v9),
  ClockConfig_Select_Table (no reader by name or 32-bit value), and the role of
  the 0x09 bytes in Tbl_AccompPartNames.
* `.long OscScope_DrawWaveform` (sequencer/smf_event_processor.s) and
  `.long OscScope_FinalizeRender` (ui/drawbar_panel_ui.s, ui/ui_mode_handlers.s)
  point into the middle of instructions (now `.set NAME, . + k` here): the
  referring lines are probably misframed code in those files.
* ui/drawbar_panel_ui.s loads StringData_APCModeNames_0x160..0x163
  (0xF00001-0xF00004) and hands them to SendEvent: most likely numeric event
  arguments that a positional-label pass symbolised by accident.
* naming: handler routines reached through the dispatch tables carry
  `<Table>_Target<k>` names; the sound-editor code (all of
  scoop_editor_data.s, 3,4xx instructions) has only structural labels.
