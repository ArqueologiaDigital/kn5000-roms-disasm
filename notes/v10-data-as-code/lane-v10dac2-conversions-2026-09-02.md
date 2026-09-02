# Lane V10DAC2, 2026-09-02: resolving the 91 "no unique context" data-as-code spans

Follow-on to lane V10DAC (`notes/v10-data-as-code/lane-v10dac-conversions-2026-09-02.md`), which
converted 120 of the STRICT census's 264 spans and left two buckets untouched: 55 spans (1,257 B)
corroborated as real code, and **91 spans (2,536 B)** where its text-based locator found either
zero or more than one occurrence of the flagged instruction-text sequence in the 407,000-line
source tree and correctly refused to guess.

This lane's job (per the parent task's brief, "the previous lane's uniqueness requirement is what
kept it honest... resolve ambiguity with *more* evidence, never a looser test") was to break that
ambiguity with address ground truth instead of text matching.

## Method: an address-anchored assembler probe (brief's suggestion 2, "the assembler knows")

`scripts/analysis/v10dac2_line_probe.py`, adapted from `hdae5000/tools/get_lprobe_addrs.py`
(single-file per-line labelling + rebuild + read addresses off the ELF) generalised to the whole
156-file, `.include`-based v10/maincpu tree:

1. Copy the already-built `v10/maincpu` tree (with `includes/generated/*.bin` and the indexed
   images already in place) to a scratch directory.
2. Insert a uniquely-numbered `LPROBE_<idx>:` label before every source line of every `.s` file,
   **except** inside a `.macro`/`.endm` body (a label there would redefine the same global symbol
   at every macro-expansion call site and break the build; only 3 of 156 files define any macro,
   and none of the 91 target spans' labels live in those files).
3. Reassemble/relink the exact same `kn5000_v10_program.llvm.o` -> `.elf` -> `.rom` pipeline the
   Makefile uses, and require the result be **byte-identical** to `original_ROMs/` before trusting
   anything (it is — confirmed on every run).
4. Read every probe's real linked address back out of the ELF with `llvm-nm`, giving an
   address -> (file, line) map with zero text comparison anywhere.
5. 17 of 156 `.s` files are never reached by any `.include` from `kn5000_v10_program.s` (dead
   sources — `audio/sound_data_*.s` x15, `includes/gui_display_struct_data.s`,
   `ui_widgets/block_007.s`); their probes never produce a symbol, which is expected and reported,
   not an error.

For each of the 91 target spans (address range known exactly from the manifest, since the census
itself works in ROM addresses, not text), a single cache lookup returns the exact physical
file + line range that produced those bytes — no ambiguity possible, because two different
physical locations cannot share one linked address in a single flat ROM image.

**All 91 of 91 resolved to exactly one file, addr_lo-anchored, single-line-boundary-clean range.**
Worked example: `CtrlAssignStr_Off+18` (0xED11EE-0xED1226, 56 B) resolves to
`extensions/extension_data.s:873-914` — the `CtrlAssignStr_Off:` label itself lives at line 872
(`aligned_string "      OFF       "`), confirming the 18-byte offset lands exactly where the
string's `aligned_string` macro (`.asciz` + `.p2align 1,0xff`) ends.

## Resolving location is not the same as proving it's data

Address resolution answered "where," not "is this really data." Every one of the 91 still needed
the same falsification reading lane V10DAC applied to its own candidates — named-call and
named-branch checks plus a manual read of the surrounding disassembly — because the STRICT rule's
byte statistics alone cannot distinguish a real, short, repetitive routine from genuine filler (the
`DataBuf_CopyBulkBitfields_Large/_Stub` trap documented in `notes/v10-data-as-code/README.md`).

Running a `call`/`calr`/`jp`/`jr`/`jrl` scan over the resolved content (excluding condition-code
tokens like `jrl ge, 250`, which are not branch targets) found **9 of the 91** ending in a call to
a real, named routine elsewhere in the tree — the single strongest "this is real code" signal used
throughout this whole push:

* `DisplayMode_Handler_3_0x612+16` / `_0x65A+15` — `call VoiceSlot_ReadCurrentParams` /
  `call VoiceSlot_FlagCheck`. Consistent with the sibling `DisplayMode_Handler_3_0x399` lane V10DAC
  already excluded as real code (register-indirect dispatch target) — same handler, same verdict.
* `SubCPU_ToneParamRet_0x9D1+57` — `call OscScope_RenderBlock_0x3F` then `_0x50`, bookended by
  `ret`/`ret`.
* `Scoop_SoundEditorData_0xEB+1539/+1699/+1859/+2042/+2225` (all 5 offsets of this base label in
  the target list) — every one calls `SeMenu_LoadPartParam` then
  `SeMenu_SetupPartDisplay_End_0x219`, byte-identical template repeated at five different offsets
  in the editor's menu-dispatch table. Five real calls, not five coincidental fake ones.
* `SndParam_BatchUpdate_Data+189` — `call SndParam_ComputeVoiceIndex`.
* the one `loc=None` span (0xFDBCC1, no named anchor at all) — `call CtrlPanel_SetIndicatorLED` in
  a coherent reset-bit/load/call/set-bit/`ret` sequence.

A manual read of the remaining candidates' surrounding source (not just the flagged bytes, per
lane V10DAC's own step 5) found **5 more** that are real code or a misframed island rather than
data, despite passing the byte-stats and named-branch-target checks:

* `KeyScaleNoteStr_G_0x18+37` and `Flash_InitBytecodeBlock+141` — both sit inside stretches of
  source riddled with stray `.byte` escapes interleaved with otherwise-valid instructions (one of
  them a real `call AccPatch_InitFromSlotIndex`), the exact "misframed islands" signature already
  named in `DEBT-INVENTORY-2026-09-02.md` for `VGA_CRTCTiming_ByteData`. Not data-as-code; left for
  whichever lane owns that separate category.
* `FDemoText_ByteData_LayoutEngine+754` — same misframed-island signature (stray escapes at 0xf3,
  0xda, 0x52, 0xf3/`reti`, 0x8e, 0x37, 0xf2, 0xe6 throughout the surrounding ~300 lines), despite
  the prior pass's own "ByteData" name suggesting it had already been recognised as data.
* `FDC_CMD_EXEC+141` and `+448` — a coherent, meaningful 8-instruction
  decrement-one-counter/increment-another idiom over two real fixed addresses (0x8a4a/0x8a48),
  repeated **verbatim** at both offsets. No named call, but an identical, meaningful, multi-operand
  sequence repeated twice outweighs the byte statistics; a genuine data table would not reproduce
  the exact same "real logic" pattern twice with no varying field.

**14 spans, 293 B excluded** on this evidence (the 9 named-call spans plus these 5), all recorded
in the manifest's `excluded` list with the specific evidence, using `loc=None` for the 15th
(counted once above under the named-call group).

## Converted: 76 of 91 spans, 2,243 B

The remaining 76 spans all passed: STRICT byte-stats, no named call/branch target inside the span,
and a manual read finding either a repeating filler template (`nop`/`swi 7`/`halt` chains, `push
xbc` repeats, `di` repeats) or numeric-only branch targets (`jrl ge, 250`, `jr nz, 0`, `calr
1645/1724` — TLCS900 code in this tree essentially never branches to a raw number for real control
flow, per lane V10DAC's own established criterion). Most of them are literally **more repeats of
already-converted arrays**: 12 of the 21 base labels in this list already had 1-16 sibling offsets
converted by lane V10DAC (`NakaInst_MainVariSet` +9 siblings, `SeBitmap_EnvCurve5` +16,
`PanelEvt_Handler_4_DualValueCheck` +3, `Protocol_values_for_LED_rows` +15, `Voice_NoteChannelTable2`
+11, `TuningSystem_Handler_Table` +8, `FlashWrite_BlockRef_Type6` +4, `AccVoice_IndexedTableLookup_
BaseOffsets` +2, `AccScreen_DataBlock` +1, `Demo_StyleRhythmData` +1, `KeyScaleNoteStr_G` +1 (a
*different* offset of this base was converted; the +37 offset above was excluded) — the previous
lane's own text search had already proven these arrays are data, just not at these specific
repeated offsets.

Largest contribution: the `PanelEvt_Handler_4_DualValueCheck_0x*` family, 44 spans / 1,411 B, all
in `midi_dispatch_handlers.s` — more entries of the exact flagship 4-byte-periodic record array
lane V10DAC already converted 630 B of.

Per-file breakdown:

| file | spans | 
|---|---:|
| `midi/midi_dispatch_handlers.s` | 44 |
| `audio/sound_editor_ui.s` | 9 |
| `extensions/extension_data.s` | 12 |
| `sequencer/accompaniment_engine.s` | 5 |
| `storage/flash_floppy_handlers.s` | 3 |
| `audio/audio_control_engine.s` | 2 |
| `sequencer/seq_event_playback.s` | 1 |

Each converted span carries the same header format as lane V10DAC's, so
`scripts/analysis/verify_v10dac_conversions.py` (unmodified — it already scans the whole
`v10/maincpu` tree and cross-checks the shared manifest) verifies both lanes' work together:

```
$ python3 scripts/analysis/verify_v10dac_conversions.py
196 converted-span headers found in the current tree
  196/196 match the original ROM bytes exactly, 5,633 B total
  manifest cross-check: 196 expected spans, 0 missing from the tree, 0 present but not in the manifest
ALL CONVERTED SPANS VERIFIED BYTE-IDENTICAL TO THE ORIGINAL ROM.
```

## Gate

Narrow gate only, per the brief (`make gate-all` explicitly NOT run by this lane):

```
$ make rebuilt_ROMs/kn5000_v10_program.llvm.rom
$ cmp original_ROMs/kn5000_v10_program.rom rebuilt_ROMs/kn5000_v10_program.llvm.rom
(no output -- byte-identical)
```

Toolchain: `LLVM: tlcs900_backend@63ff7d92fb5f (63ff7d92fb5f0289e8106c043f596167cac062dc)`.

## What's left ambiguous

Nothing from the original 91 remains ambiguous — all 91 were located exactly by address; 76
converted, 15 excluded with specific evidence (9 real calls, 5 misframed-island/coherent-real-code
manual reads, all named above). The 15 exclusions are recorded in
`v10dac_conversion_manifest.json`'s `excluded` list with a `reason` string prefixed
`"lane V10DAC2 address-probe locate succeeded... but excluded on further evidence:"` so a future
pass can see the locate step worked and re-examine only the judgment call, not redo the address
resolution.

A fresh STRICT census run after this pass reports **67 remaining spans, 1,469 B** (down from 144
spans / 3,738 B before this lane) — dominated by the already-known 55-span real-code family (their
addresses drift slightly run-to-run as neighbouring conversions change span boundaries; this is
the documented behaviour in `notes/v10-data-as-code/README.md`, not new debt).

## Reproducibility

* `scripts/analysis/v10dac2_line_probe.py` — the committed, reusable address-probe tool. Rerun with
  `--build` (~10-15s) to regenerate `notes/v10-data-as-code/line_probe_cache.json` (gitignored,
  16 MB+); `--lookup ADDR_LO ADDR_HI` or `--lookup-file` to query it.
* `notes/v10-data-as-code/v10dac_conversion_manifest.json` — updated in place: 76 entries moved
  from `excluded` to `converted`, 15 rewritten with their specific exclusion evidence, the
  remaining 55 real-code exclusions from lane V10DAC untouched.
* The interactive resolve/review/convert scripts that drove this specific pass were written to
  `/tmp` (session scratch) and are not committed, matching lane V10DAC's own precedent — they are
  fully superseded by the manifest they produced plus `v10dac2_line_probe.py`, which is the
  reusable artefact: rerunning `--build` plus a manifest diff re-derives the same evidence from
  first principles (the real ROM/ELF), not from a bespoke one-off locator.
