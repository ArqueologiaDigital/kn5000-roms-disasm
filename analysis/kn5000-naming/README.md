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

**Batches o-p and case batches c9-c10** (`proposals-2026-10-06-helpers-{o,p}.json`, `-cases-{c9,c10}.json`):
52 helpers (every one with a named caller left after the earlier refusals) and 161 cases named, with 14 switch
owners renamed in the same records (the case framer had used the nearest label above the dispatch, often a
leftover such as `SendEpilogue_Data` -> `SndParam_ApplySystemParam`). Applied to v10, then:
- `rename_orphan_locals.py --tree v10` (202 + 6) and the new `--misplaced` mode (1,460 locals whose prefix routine
  still lives elsewhere but which sit inside, and are branched to only from, another named routine);
- `name_se_screen_records.py` (16; `sdb_*` record macros no longer count as readers);
- `harmonize_version_labels.py` to v9 / v7 until it settled. Its new `rename-by-proposal` rule renames a target
  label that is not generic when a proposal here replaced exactly that old name with exactly this one (v9 11,
  v7 9: the owner renames).
Leads reported for later:
- `SoundCtrl_SendCommand` opens an interrupting screen (0xEE message box, 0xA5 sequencer mixer, 0xD6
  Entertainer); it sends nothing to the sound hardware.
- `HdaeRom_DataHandler` / `HdaeRom_AltHandler` convert sound-RAM images of older models (KN2000, MKA, MKB,
  KN3000, KN1500) to the KN5000 layout; nothing to do with the HD-AE5000.
- `MspMenuTtl_Case2` and `SndArg_GridBnk_Case3` are duplicate labels at a function entry; MainCmpSet, VocalistP1OK,
  SqAftSet, SndArg_GridBnk own no switch. The `TmFlash_*` cases' owners at 0xFF07C7 / 0xFF0870 have no label.
- event 0x1E80010 (MT_GetParaSize) has no EVT_ constant; `MSP_Default_VarSize` / `MSP_Default_GroupOffsetB` are
  NoteEventBuffer case tables.
- panel record 0x92 is the scale-tune record (type, key/on-off, 12 user offsets).

**Single-image batches s1-s3** (`proposals-2026-10-06-{v142-s1s3,hdae5000-s2,tabledata-s2,subboot-s2}.json`): the
generic or positional names the semantic score still counted in the sub-CPU payload (91 of 115 named), HD-AE5000
(11 of 11), table data (1 of 3) and the sub-CPU boot ROM (1 of 1), applied with `--tree`. Highlights: the
`DSP_Set_*` setters are the global effect switches (DIGITAL REVERB / ACOUSTIC ILLUSION / mic reverb / EQUALIZER
on-off, rotary speed, fade level, mic level, MICSNS); the 2^21 / 2^22 / 2^23 FP constants are Q-format ones;
`VoiceCC_DataTable_028F75` is `TVF_Refresh_Sounding_Voices`; `StyleRec_PtrTable_C2C5` (C2/C5 were the UI states
that select it) holds the styles in category order. `Detect_Region_Code` / `Get_Region_Code` keep their names
(the region code is the real thing, and the main-CPU trees share the routine). The website pages and the
living scripts that quoted the old names were updated; dated notes keep them.

**Generic-label batches g1-g6** (`proposals-2026-10-07-generic-g{1..6}.json`): every v10 `_Data` / `_Code` /
`_Entry` / `_Part` / `_Sub` / `_Block` / `_Wrapper` / `_Stub` / `_Tail` / `_Thunk` label that has a named
referrer and is not internal flow (477 labels referenced only within 400 lines of their own file were left
out), 543 in all. 384 renamed. The batches were stopped early at the owner's request, and each agent wrote out what
it had finished: 100 records are "not reviewed (stopped early)", mostly g5 (79) and g3 (17). The 26
`PartName6_PartN` / `PartName4_PartN` proposals were not applied: those names already say what they are and
match the `_Part` suffix rule only by accident. g6's evidence has 14 line citations off by one or two lines
(its own final check; the quoted instructions are right). Leads, not acted on:
- alias merges: seven `SndParam_*_Data` labels sit on the address of a semantic label (`SndParam_Registry`,
  `SndParam_ReadHandlers`, ...; g6 `merge_into`), as do `AcChordBoxProc_Entry` and `DirmdEmulator_Entry`;
- wrong names: `SndParam_ClampReverbTime` / `ClampDelayTime` clamp the tempo to 40..300;
  `DkMdlyPly_SendAudioCmd` returns the index of the lowest set bit; `MidiStream_DispatchLoop_Data`'s buffer is
  the PanelEvent_Post queue; `MainSysControl`'s siblings follow the INITIAL SETTING list (Entry4 = PANEL MEMORY);
- spelling: `.byte 0xdc,0x38,0xff,0x07` = `minc1_16 ix, 0x7ff`; `Sprintf` loads 10 and 8 as `(P2CR:8)` /
  `(P2:8)`; `MidiStream_InitFromLookup_Data`'s 16 pointers are `.byte`; `AccPatch_SeqDispatch_Entry` holds 12
  bytes of 0x90 fill as six `adc wa,(xwa)`; misframed code near `Param_SignExtendReturn_Code3` (0xFEEE47);
  `AccFill_AdvanceAndCheck_Code` is a bar-length table; HD-AE5000 veneers still use 0x280008 / 0x280010;
- reopen: c9's `SendEpilogue_Data_Case5` (parameter 0x4005 is the fade level) and c4's GS chorus cases 1-7;
- 0xFFFEED-0xFFFEEF are configuration bytes (payload transfer on, try the 0x3E0000 update image first,
  main-loop hooks off), identical in v7 / v9 / v10.
