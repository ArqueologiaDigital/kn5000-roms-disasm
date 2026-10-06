# KN5000 routine names from callers, with evidence (2026-10-06)

**What question this answers.** Routines that were renamed from a generic label (`X_Helper7` is just "a piece of
X"): what is each name based on?

Read-only triage passes took the `_Helper` routines of v10 ranked by named callers
(`~/compartilhado/research-scratch`, `rank_helpers.py`). For each routine the pass read the callers and then the
body, and gave a name only when the two agreed. Every record in `proposals-*.json` has `old`, `new`, a `header`
(what it does, with its basis) and `evidence`: the `file:line` instructions, paths relative to `v10/maincpu`, with
at least one caller site. Refused records keep the reason and a mechanical description of the body.

**Apply** with `scripts/renaming/apply_kn5000_naming_proposals.py TAG proposals-*.json --apply`. It renames v10 only,
because an old generic label of v9 / v7 need not sit on the same code. Then `make all` and
`scripts/renaming/harmonize_version_labels.py --to v9 --apply` / `--to v7 --apply`: they carry the new names by address
correspondence with a byte proof. Then run `make gate-all` and `l2_symbol_reference.py --regen` / `--check`.

**Batches e-h** (`proposals-2026-10-06-helpers-{e,f,g,h}.json`): the next 120 `_Helper` routines with a named caller,
minus the ones refused before; nearly all have one named caller. 94 named, 26 refused. The harmonizer carried 93 to v9
and 50 to v7 (the rest sit where v7's code differs).

`probes/rhythm_probe.py` answers what byte +976 (0x3D0) of each rhythm header in the Rhythm Data ROM holds: the
time-signature index that `Rhythm_LoadCurrentTimeSig` copies to RAM 0x34F0. Run it from the repository root on a
built tree. On 2026-10-06 it printed 201 rhythms: 7 for 186 of them, 6 for 13, and 9 and 11 once each.

**Batches i-j** (`proposals-2026-10-06-helpers-{i,j}.json`): 53 named, 7 refused.

**Switch-case pilot** (`proposals-2026-10-06-cases-{c1,c2}.json`): 20 compiled `switch` statements whose owners
have real names. For each one the pass established first what the switched value is: an event code, an edit
parameter number, a design-box style, a caption code, CURRENT_MODE or a DSP effect number. Then it named the
`<Owner>_CaseN` labels of `scripts/tools/frame_switch_cases.py` after it. 224 cases named, 52 refused. The refused
ones are switches whose value is a raw byte offset into a record of unestablished meaning, or method codes the
firmware's own name table skips. Finding: for switches that serve several value ranges from one table,
`frame_switch_cases.py` set N to the table index plus only the last bias subtracted, so N is not the switch value
there (DrawDesignBox_Impl, DSPCfg_ApplyParamStructFull, GetClientBox2, DrawDesignBox_PartGroupStyle). The names now
in the source state the right values; the remaining `_CaseN` labels of such switches need re-checking.

**Batches k-l and case batches c3-c6** (`proposals-2026-10-06-helpers-{k,l}.json`, `-cases-{c3,c4,c5,c6}.json`):
44 helpers and 236 cases named. c5 is the sub-CPU payload (`--tree v142/subcpu`) and c6 is HD-AE5000
(`--tree hdae5000`); the applier takes that option for single-version images. Leads the passes reported for later:
- `ToneGen_ParamTable_0x216` is the WRITE SOUND title's 18-entry switch-handler table, `.incbin`'d, and its targets
  have no labels. `ToneGen_ParamTable_0x25E` (SeDigEff) looks the same. These are census detector gaps.
- Data spelled as instructions: `SeMenu_ShowConfirmDialog_Code` (the black-key offset table) and
  `RhythmVariation_InlineCode_Code` (32 bytes indexed by (0x379B) & 31).
- Wrong names: `SysEx_BytecodeDispatcher` (TT_SQSTEP panel-button action dispatcher), `Part_LoadAndApplyVoiceTable`
  (maps SEQ_ERROR_CODE to GLOBAL_ERROR_CODE), `DrawProgressRectH/V` (ArrowProc copies), `RegHamaTitle1/2_Entry`
  (format 2DD/2HD floppies), `Bitmap_DigitD` (holds "U"), `SqplyFunc_FormatIntro/Ending/FillIn` (the punch-in,
  punch-out and count-in fields), `NakaInst_OK` (holds "ON"), `ENCODER_STATE_BASE` (the panel LED row image).

**Batches m-n and case batches c7-c8** (`proposals-2026-10-06-helpers-{m,n}.json`, `-cases-{c7,c8}.json`):
52 helpers and 122 cases named. Leads reported for later:
- a stray `.byte 0xde` in `ui/ui_playback_modes.s` is half of `xorcf A, IZ`;
- `Audio_DispatchCommand_Case6` in v10/v9 has `ld xwa, 0x3d3420` spelled as `.asciz "@ 4="`;
- `NoteEventBuffer_CopyToSlot` copies flash to RAM, the other way round from its comments;
- `SeqState_Case0..4` are ordinary branch labels, not switch cases;
- TRACK ASSIGN values 12-16 are DRUMS / CHORD / APC / CONTROL / RHYTHM. This may reopen refusals that hinged on
  "track type 15/16".
