# Lane V10DAC, 2026-09-02: converting v10's data-as-code STRICT list to typed data

Lane V10DAC of the full-disassembly push (`notes/lanes/BRIEF-2026-09-01.md`). Target: the
7,128 B / 264 spans that `scripts/analysis/v10_data_as_code_census.py --report --strict`
identified as v10 (KN5000 maincpu) bytes disassembled into plausible-but-dead instruction
mnemonics (see `notes/v10-data-as-code/README.md` for the method and its calibration).

## Numbers

A fresh run of the census at the start of this session (the figure drifts hourly per its own
README) measured **266 spans, 7,183 B**. Of those:

* **120 spans, 3,390 B converted** to `.byte` data, each with a header citing the exact address
  range, byte count, the census's per/dist statistics, and the nearest named label — see
  `notes/v10-data-as-code/v10dac_conversion_manifest.json` for the full list.
* **146 spans, 3,793 B left unconverted** — 91 spans (2,536 B) because the automated locator could
  not find a provably unique source location for them (see "What resisted" below), and 55 spans
  (1,257 B, across 43 distinct labels/aliases) because the safety checks or a manual read of the
  actual disassembly found they are almost certainly REAL CODE that the census's reachability
  signal simply could not trace (see "False positives found and excluded" below). Both buckets are
  recorded with their reasons in the manifest's `excluded` list.

## Gate

```
$ make rebuilt_ROMs/kn5000_v10_program.llvm.rom
$ cmp original_ROMs/kn5000_v10_program.rom rebuilt_ROMs/kn5000_v10_program.llvm.rom
(no output -- byte-identical)
```

Toolchain: `LLVM: tlcs900_backend@63ff7d92fb5f (63ff7d92fb5f0289e8106c043f596167cac062dc)`.

A second, finer-grained check (independent of the whole-ROM `cmp`, and reproducible any time
without rebuilding) pins the byte-identity claim to exactly the 120 converted regions:

```
$ python3 scripts/analysis/verify_v10dac_conversions.py
120 converted-span headers found in the current tree
  120/120 match the original ROM bytes exactly, 3,390 B total
  manifest cross-check: 120 expected spans, 0 missing from the tree, 0 present but not in the manifest
ALL CONVERTED SPANS VERIFIED BYTE-IDENTICAL TO THE ORIGINAL ROM.
```

## Method

1. For every STRICT-flagged span `[a,b)`, pulled the exact list of (address, length, source
   mnemonic text) instructions covering it from the census's own cached instruction stream
   (`notes/v10-data-as-code/cache.pkl`, regenerated fresh this session) — this is literally the
   text the source file has at that address, not a re-decode.
2. Located the physical source line range by finding the ONE place in the entire 407,000-line
   `v10/maincpu/**/*.s` tree where that exact sequence of instruction texts occurs consecutively
   (numeric operands compared by VALUE so `0xfd05` and `64773` match) — first with a short window,
   then, for spans whose pattern repeats identically elsewhere (a real risk given these are
   short, templated garbage runs), by growing the match to include the REACHED code immediately
   preceding the span until the combined sequence is provably unique. A span is only accepted if
   this match is unique; ambiguous or unmatched spans are left alone (43 spans, 1,067 B — see
   below).
3. Replaced the exact matched lines with `.byte` directives reproducing the corresponding
   ORIGINAL ROM bytes (pulled directly from `original_ROMs/kn5000_v10_program.rom`, never from
   the mis-disassembled text), with a one-line comment citing the address range, byte count and
   the census's per/dist evidence.
4. **Before accepting any span, ran three independent falsification checks** beyond the census's
   own reachability signal, because manual spot-checking during this pass found the STRICT rule's
   calibrated 0.3–2.3% false-positive rate does not fully protect against a human hand-writing a
   real, short, repetitive utility routine (exactly the `DataBuf_CopyBulkBitfields_Large/_Stub`
   trap the census's own README already documents) or a routine reached only through mechanisms
   invisible to a static, name-based scan:
   - **Indirect dispatch**: excluded any span whose enclosing label is loaded into an index
     register (`lda_24 xix, (LABEL)` etc.) with a `jp_ind` or register-indirect `call (xreg)`
     within 40 source lines of the label's own definition — TLCS900 `jp_ind`/`call (reg)` targets
     are invisible to the census's name-based reachability walk by construction, so a span in this
     shape is far more likely to be a real computed-jump-table entry point than dead data.
   - **Named branch target**: excluded any span whose EXACT label (including its `_0xNN` offset
     alias, not just the base routine name) is itself the target of a `call`/`calr`/`jp`/`jr`/`jrl`
     instruction anywhere else in the tree — the census deliberately never seeds from branch
     operands (to defeat the HDAE5000_RECORD_TABLE self-reference trick), which means a routine
     that IS genuinely called by name from elsewhere, but whose OWN caller chain the static scan
     can't independently prove reached, still shows up as "unreached". A real cross-file call by
     name is strong evidence of live code.
   - **First-instruction-is-a-real-branch**: excluded any span whose very first byte is itself a
     clean `jp`/`jr`/`jrl`/`call`/`calr` to a name that resolves to a real symbol elsewhere in the
     tree — this caught two real jump-trampoline tables (`AccStyle_JumpTable2`, `AccWrap_JumpTable`,
     both literally sequences of `jp NAMED_HANDLER`) and one orphaned-but-real code stub
     (`Audio_NullRet1_Data`, whose first instruction is `jp NullRet2_Block`) that the STRICT byte
     statistics rule could not distinguish from genuine data.
5. On top of the three automated checks, **manually read the actual disassembly context of every
   surviving candidate label** (not just the flagged bytes — the routine around them) before
   accepting it. This caught five further false positives the automated checks missed entirely:
   `RingBuf_CopyPtr_Sub1` and `LcdOff_Done` (clean, previously human-commented one-liner utility
   routines), `SetWall_InitCallSequences` and `SeqStep_FileSectorDone` (coherent multi-instruction
   real code), and `SLSrcBankList_FuncBody` and `DSPCfg_VoiceSlotB_ExtractData` (real prologue/
   bit-manipulation code, more likely a misframed island than data-as-code) and
   `ExtData_VoiceParam_DispatchBytecode` (a coherent `cp c,N / ret z` switch ladder). All are
   recorded in the manifest with the specific evidence that disqualified them.

## What converted, and why it's believed genuine

Every accepted span passed ALL of: unreached by the census's BFS, STRICT byte-stats
(≤15 distinct bytes, ≥60% periodicity), not indirectly dispatched, not named-branch-targeted
elsewhere, and a clean manual read finding either (a) a repeating template with a fixed,
meaningless tail (`push 1/reti/halt/nop/nop/swi 7` after every `VoiceParamEx_Entry_NNN`,
`MidiChParam_Entry_NNN`), (b) branches/calls to raw NUMERIC addresses or address ZERO rather than
names (`calr 72`, `jp 0`, `call 0x5a00f1`) — TLCS900 code in this tree essentially never does
this for real control flow, (c) a real routine ending in `ret`/`halt` immediately followed by
garbage with no fallthrough path in, referenced only as a loaded VALUE from elsewhere (the
`PanelEvt_Handler_4_DualValueCheck_0x77` flagship case: a 90+-repetition 4-byte-periodic
`[payload][halt][swi 5][nop]` record chain, verified directly against the raw ROM bytes), or
(d) sitting immediately adjacent to already-`.incbin`/`.ascii`/`.zero`-typed data with the same
periodic byte character (e.g. `NakaInst_MainVariSet`'s tail, an unlabelled 900+ B gap right after
a compiled-C-struct `.incbin` ends, matching the same `push xix/nop/jr f,1/push_f/nop/swi7/swi7`
template repeated elsewhere in the same file).

Largest contributions: `PanelEvt_Handler_4_DualValueCheck_0x77` (673 B, the census's flagship
example), `Voice_NoteChannelTable1_0x2`/`Voice_NoteChannelTable2_0x2` (502 B combined),
`Protocol_values_for_LED_rows_0x56` (224 B), `NakaInst_MainVariSet` (163 B),
`AccVoice_IndexedTableLookup_BaseOffsets_0x2` (102 B), the `TuningSystem_Handler_Table_*` family
(297 B across 7 aliases), `SeBitmap_EnvCurve5_*` family (243 B across 10 aliases). Full
per-span breakdown: `notes/v10-data-as-code/v10dac_conversion_manifest.json`.

## What resisted (left ambiguous, NOT claimed as converted)

* **91 spans, 2,536 B**: the automated unique-match locator could not find a provably unique
  source location (0, or more than one, matches for the instruction-text sequence, even after
  growing the match window with preceding reached context). Rather than guess which of several
  textually-identical occurrences was meant, these were left untouched. Reason strings of the
  form `"N matches (no unique context)"` in the manifest's `excluded` list.
* **55 spans, 1,257 B across 43 distinct labels/aliases**: real code the census's static
  reachability signal could not prove reached, per the safety checks in step 4/5 above —
  `DispTimeSet_EventDispatch`, `TchSensGrid_EventDispatch`, `GetDiskFreeSpace_JumpTable`,
  `NOTE_EVENT_DISPATCH_1`, `DemoDesc_DispatchTable`, `SndParam_TypeDispatch_Entry1`,
  `NoteEditSy_Dispatch85`, `ButtonState_DispatchDSP_InlineData`, `SeqAccomp_Dispatch`,
  `ObjectEnum_Init`, `EventDispatch_Select`, `ScoopDisp_DispatchTable_Extended`,
  `ScoopDisp_HandlerData2`, `SeqByteBlock_ChannelContainer`, `SeqByteBlock_StyleBitmapRef`,
  `FileIO_BytecodeData`, `Data_UnknownBlock`, `AccPatch_VoiceAssignDataBlock`,
  `StringData_APCModeNames`, `SeMenu_ApplyPartEdit_Data2`, `SeMenu_WaveformSelect_Data`,
  `VoiceState_DataBlock2` (all excluded for an indirect-dispatch or named-branch-target signal),
  plus `DisplayMode_Handler_3`/`_0x399` (register-indirect `call (xhl)` from a real `.long` jump
  table), `Part_ApplyVoiceTableB`, `SeMenu_CopyWriteUpdate_Data`, `VoiceSlot_StatusRet`,
  `VoiceSlot_TableSetup`, `VoiceSlot_FinalRetZ`, `SetWall_MiscDataAndCode`, `MemConfig_Handler_1`
  (aliases whose EXACT name is itself a real branch target elsewhere), `AccStyle_JumpTable2`/
  `AccWrap_JumpTable` (real jump-trampoline tables), `Audio_NullRet1_Data` (an orphaned-but-real
  `jp` stub), `RingBuf_CopyPtr_Sub1`, `LcdOff_Done`, `SetWall_InitCallSequences`,
  `SeqStep_FileSectorDone`, `SLSrcBankList_FuncBody`, `SeqChan_TraverseAndProcess`,
  `Sprintf_InsertCarry_Propagate`, `DSPCfg_VoiceSlotB_ExtractData`,
  `ExtData_VoiceParam_DispatchBytecode` (manual-read false positives). **This 1,257 B is evidence
  the STRICT rule's calibrated false-positive rate understates the real risk for hand-picked
  spans**, not just a random sample — a future pass measuring the census's calibration against
  DELIBERATELY-chosen short utility routines (rather than random windows of long reached runs)
  would likely find a higher rate than the 0.3–2.3% quoted in `notes/v10-data-as-code/README.md`.
* One additional span (`note_voice_mapping.s`, a stray `.ascii` fragment inside otherwise clean
  code) had no parseable report-row evidence and was excluded for lack of corroboration rather
  than a specific finding either way.

## Reproducibility

* `notes/v10-data-as-code/v10dac_conversion_manifest.json` — the full converted/excluded list
  with addresses, sizes, evidence and (for excluded spans) the specific reason.
* `scripts/analysis/verify_v10dac_conversions.py` — re-verifies every converted span's current
  source against the original ROM bytes, independent of a full rebuild; command and expected
  output above.
* The interactive per-span locator/exclusion scripts used to build the manifest were throwaway
  (written to `/tmp`, not committed) — they are fully superseded by the manifest they produced
  plus the verifier above, which is the artefact that actually needs to survive: it re-checks the
  claim from first principles (the real ROM bytes) rather than re-running a bespoke locator.
