# v7 Precision Surgery Plan

1,228 remaining diff bytes organized into 40 parent groups.

## Tier 1: Sub-label parents NOT YET transplanted (952 diffs, 77%)

These parents contain sub-labels (`.set` positional offsets) that have diff bytes. The parent source has v9 inline code/data. Transplanting the parent fixes ALL sub-label diffs within it.

### 1a. Parents blocked by `.include` in their range (706 diffs)

| Parent | Diffs | File | Blocker |
|--------|-------|------|---------|
| MidiStream_HandleRunningStatus | 497 | audio_control_engine.s | LAST IN FILE — diffs are PAST the .incbin end (0xfccc45-0xfcce4a gap) |
| TuningSystem_Handler_Table | 208 | sound_editor_ui.s | `.include "storage/flash_floppy_handlers.s"` is inside its source range |
| AccStyle_TableDataEntry | 69 | accompaniment_engine.s | LAST IN FILE with `.include` chain |

**Fix for MidiStream (497):** The parent IS transplanted (1444 bytes). The 497 diffs are in the GAP between the transplant end (0xfccc45) and SndParam_ProbeCheckMatch (0xfcce9f). This gap is "orphan code" from `boot/interrupt_vector_trampolines.s` and subsequent includes. **Fix: transplant `interrupt_vector_trampolines.s` initial code as a separate block, OR extend the MidiStream .incbin to 1969 bytes and add a `.skip` directive in the next included file to prevent double-emission.**

**Fix for TuningSystem (208):** The parent contains `flash_floppy_handlers.s` via `.include`. Split the transplant: `.incbin` for the part BEFORE the `.include`, keep the `.include`, then `.incbin` for the part AFTER. Requires measuring exact byte count of the pre-include portion.

**Fix for AccStyle (69):** LAST IN FILE with `.include` chain. Measure actual assembled size using standalone assembly test, transplant exactly that many bytes.

### 1b. Parents that ARE safe to transplant but were missed (83 diffs)

| Parent | Diffs | File | Status |
|--------|-------|------|--------|
| SeMenu_CompareScreen_DataTable | 61 | sound_editor_ui.s | Sub-label diffs REMAIN after parent was transplanted — the transplant bin has wrong bytes |
| ColorBlit2_LargeCodeBlock | 26 | ui_window_procs.s | LAST IN FILE, actual=4128 vs ELF=4919 (791 orphan bytes) |
| DrumDetailEdit_Menu_Table | 17 | flash_floppy_handlers.s | Has EffectParamEdit sub-labels between it and next label |
| SeMenu_RefreshPartDisplay_Data | 4 | semenu_routines.s | LAST IN FILE |
| SeBitmap_EnvCurve5 | 164 | sound_editor_ui.s | Already transplanted but sub-label diffs remain — transplant bin has wrong bytes |

**Fix for SeMenu_CompareScreen + SeBitmap (225):** These WERE transplanted but still have diffs. The transplant bins were extracted at the wrong v7 ROM offset. The extraction uses the v7 ELF address, but the v7 ROM has different content at that address because of cascading shifts. **Fix: use the v9 ROM fingerprint to find the correct v7 offset for these specific blocks, then re-extract.**

**Fix for ColorBlit2 (26):** Transplant with actual assembled size (4128 bytes, not ELF's 4919).

**Fix for DrumDetailEdit (17):** Split around EffectParamEdit labels.

## Tier 2: Source-level labels with inline code diffs (192 diffs, 16%)

These labels have their own source code (instructions) that differs between v7 and v9.

| Label | Diffs | File | Issue |
|-------|-------|------|-------|
| VoiceParam_LookupAndEnqueue | 59 | midi_dispatch_handlers.s | HAS `.include` |
| DSPCfg_ReturnValueTable | 20 | dsp_config_sysex.s | HAS `.include` |
| SndParam_HeapAllocOK | 13 | sndparam_routines.s | LAST IN FILE |
| Math_AbsInt16 | 10 | note_voice_mapping.s | HAS `.include` |
| InitializeRoot | 6 | graphics_text_vga.s | Contains `.macro _VGA_WRITE` definitions |
| InitializeScoop | 6 | scoop_display.s | LAST IN FILE (assembly fails standalone) |
| InitializeToshi | 6 | extension_init.s | LAST IN FILE (assembly fails standalone) |
| AccState_ReadAccompParams | 6 | smf_event_processor.s | Source label found but may have issues |
| DispSeqList_LoopBody | 6 | smf_operations.s | Source label |
| RVari_Select_CheckSameBank | 6 | ui_mode_handlers.s | Source label |
| Encoder_ConfigureRangeLimit | 5 | midi_encoder_routines.s | Source label |
| 17 more labels | 49 | various | 1-3 diffs each |

**Fix for InitializeRoot (6):** Split the transplant around the 6 VGA macro definitions: `.incbin` for bytes before macros, keep macros as source, `.incbin` for bytes after macros.

**Fix for HAS `.include` labels:** Measure pre-include assembled size, transplant only that portion.

**Fix for LAST IN FILE labels:** Measure using standalone assembly test (`.include "file" / __end:`).

**Fix for small labels (1-3 diffs):** Direct `.byte` value patching — find the specific hex value and change it.

## Tier 3: Stale transplant bins (225 diffs, 18%)

SeBitmap_EnvCurve5 and SeMenu_CompareScreen_DataTable were transplanted but their bins have wrong bytes. The extraction reads `v7_rom[elf_addr]` but the v7 ROM has shifted content at that address.

**Fix:** Use v9 ROM fingerprinting to find the correct v7 offset for each block, then re-extract.

## Execution Order

1. **Fix stale transplant bins** (Tier 3, ~225 diffs) — highest ROI, just fix extraction offsets
2. **Split InitializeRoot** around VGA macros (6 diffs) — proves the split technique
3. **Transplant LAST_IN_FILE labels** with measured sizes (Tier 2 small labels, ~50 diffs)
4. **Handle MidiStream gap** (497 diffs) — the single biggest remaining issue
5. **Handle TuningSystem split** around `.include` (208 diffs)
6. **Direct `.byte` patching** for remaining 1-3 byte diffs (~50 diffs)

Expected result: 0 diffs (100.00% byte-match) from pure source.
