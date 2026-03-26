# v7 Final 471 Diffs — Execution Plan

## Corrected Breakdown

| # | Parent Label | Diffs | Blocker | Strategy |
|---|-------------|-------|---------|----------|
| 1 | TuningSystem_Handler_Table | 208 | `.include` at +1651 lines | **Split transplant** |
| 2 | AccStyle_TableDataEntry | 69 | `.include` in accompaniment_engine.s | **Split transplant** |
| 3 | VoiceParam_LookupAndEnqueue | 59 | `.include` in midi_dispatch_handlers.s | **Split transplant** |
| 4 | ColorBlit2_LargeCodeBlock | 26 | LAST IN FILE (orphan code) | **Measured-size transplant** |
| 5 | DrumDetailEdit_Menu_Table | 21 | Has EffectParam_Edit_Table inside | **Split at sub-label** |
| 6 | DSPCfg_ReturnValueTable | 20 | `.include` in dsp_config_sysex.s | **Split transplant** |
| 7 | Math_AbsInt16 | 10 | `.include` in note_voice_mapping.s | **Measured-size transplant** |
| 8 | InitializeRoot | 6 | `.macro _VGA_WRITE` inside | **Split around macros** |
| 9 | InitializeScoop | 6 | `.include` in scoop_display.s | **Measured-size transplant** |
| 10 | AccState_ReadAccompParams | 6 | LAST IN FILE (11 lines) | **Measured-size transplant** |
| 11 | RVari_Select_CheckSameBank | 6 | `.include` in ui_mode_handlers.s | **Measured-size transplant** |
| 12 | 5 more small labels | 34 | Various | **Individual fixes** |

## Strategies

### A. Split Transplant (357 diffs — items 1,2,3,6)

For labels where `.include` is the blocker:
1. Measure the byte count from the label to the `.include` line using standalone assembly
2. Transplant ONLY the pre-include portion with that exact byte count
3. The `.include` and everything after it stays as source

**Example for TuningSystem (208 diffs):**
```
TuningSystem_Handler_Table:
    .incbin "includes/generated/v7_block_tuningsystem_pre_include.bin"  ; N bytes
    .include "storage/flash_floppy_handlers.s"
```
Where N = measured byte count from standalone assembly of sound_editor_ui.s.

**How to measure:** Assemble the file standalone with a marker BEFORE the `.include`:
```
.text
.include "shared/macros.s"
; ... (copy all content from TuningSystem_Handler_Table to the .include line)
__pre_include_end:
```
Then: N = address of `__pre_include_end` - address of `TuningSystem_Handler_Table`

### B. Measured-Size Transplant (54 diffs — items 4,7,9,10,11)

For LAST IN FILE labels:
1. Assemble the file standalone with an `__end:` marker
2. Size = `__end` - label address
3. Transplant with that exact size

For labels before `.include` where the include content doesn't overlap:
1. Same measurement approach

### C. Split at Sub-Label (21 diffs — item 5)

For DrumDetailEdit_Menu_Table:
1. Transplant DrumDetailEdit_Menu_Table to EffectParam_Edit_Table (150 lines, ~876 bytes)
2. Then transplant EffectParam_Edit_Table separately (if it has diffs)

### D. Split Around Macros (6 diffs — item 8)

For InitializeRoot (has `.macro _VGA_WRITE` at line ~1943):
1. Transplant bytes from InitializeRoot to the `.macro` definition
2. Keep all `.macro` definitions as source
3. Transplant bytes after the last `.endm` to VGA_Initialize

### E. Individual Fixes (34 diffs — remaining small labels)

For labels with 1-3 diffs:
- Direct `.byte` value changes where identifiable
- Small `.incbin` blocks where safe

## Execution Order

1. **DrumDetailEdit_Menu_Table** (21 diffs) — simplest, sub-label split only
2. **AccState_ReadAccompParams** (6 diffs) — LAST IN FILE, 11 lines, measurable
3. **ColorBlit2_LargeCodeBlock** (26 diffs) — LAST IN FILE, measure with standalone assembly
4. **TuningSystem split** (208 diffs) — biggest win, measure pre-include size
5. **VoiceParam split** (59 diffs) — same technique as TuningSystem
6. **AccStyle split** (69 diffs) — same technique
7. **DSPCfg split** (20 diffs) — same technique
8. **InitializeRoot macro split** (6 diffs)
9. **Remaining small labels** (56 diffs)

## Key Insight

The "standalone assembly measurement" technique is the breakthrough that unlocks ALL remaining diffs. By assembling each file independently with markers, we get EXACT byte counts that account for instruction encoding sizes — no manual byte counting needed.
