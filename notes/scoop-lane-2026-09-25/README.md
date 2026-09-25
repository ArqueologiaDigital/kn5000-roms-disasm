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
