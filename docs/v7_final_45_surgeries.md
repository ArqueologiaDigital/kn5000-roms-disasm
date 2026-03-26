# v7 Final 45 Bytes — Surgery Notes

## Pattern Analysis

The 45 diff bytes cluster into 4 patterns:

### Pattern A: 3× pointer pairs with diff=(-13,-4) — 18 bytes

InitializeScoop (6 bytes) and InitializeRoot (6 bytes) have **identical** diff patterns:
```
+13: -13, +14: -4
+53: -13, +54: -4
+93: -13, +94: -4
```
These are 3 pointer low-bytes that shifted by a constant. The -13/-4 pattern suggests a 24-bit address where byte 0 shifted by -13 and byte 1 shifted by -4 (total address shift ≈ -1037).

**Fix:** These labels contain `RegObjTable` / `RegObjTabl` macro calls with hardcoded NAKA widget addresses. The macros emit 24-bit addresses where bytes 0-1 are the shifted part. Change the hex operands in the macro calls.

InitializeRoot also has `.macro _VGA_WRITE` definitions inside — requires **split around macros**: .incbin for bytes 0-to-macro, keep macros as source, .incbin for post-macros bytes.

### Pattern B: 2-byte pointer with diff=(-156) — 10 bytes

5 labels each have a 2-byte 16-bit value difference of exactly -156:
- Boot_ReadFDCStatus (+1,+2)
- AccState_ReadAccompParams (+39,+40)
- Voice_InitBankTables_SlotLoop (+15,+16)
- NumToAscii_OnesDigitAndFinish (+5,+6)

These are `.short` or `.byte` pairs encoding 16-bit pointers to functions that shifted by -156 bytes between v7 and v9.

**Fix:** Find the `.byte` or `.short` line at the specific offset and change the 2 hex values.

### Pattern C: 2-byte pointer with diff=(-1050) — 6 bytes

3 labels with 16-bit value diff of exactly -1050:
- free_X (+2,+3)
- VoiceUI_MiscHandler (+72,+73)
- AcTranspose_FormatLabel (+22,+23)

Same fix as Pattern B.

### Pattern D: Individual bytes — 11 bytes

| Label | Diff | Likely cause |
|-------|------|-------------|
| NakaInst_MainVariSet | +42 | SeqChannels shift |
| TuningSys_Param_01_0x25E | -42 | SeqChannels shift |
| ChanDisp_NoteOnZeroReturn | +230 | Genuinely different opcode |
| BitMask_Ctrl40_ConfigExit | +19 | Different data value |
| PreTmLoad | -14 | Pointer shift |
| MSP_FACTORY_DEFAULTS | +1995 | Large pointer shift |
| MSP_FactoryPresetData_Continued | +1995 | Same |
| SC0TxEnable_Return | +1387 | Different data |
| Rhythm_TailPadding | -1028 | Pointer shift |
| ColorBlit2_LargeCodeBlock_0xBD9 | various | Sub-label in transplanted parent |

## Execution Plan

### Surgery 1: InitializeRoot macro split (6 bytes)
Split .incbin around the 6 VGA macro definitions at lines 1943-2009.
Pre-macro .incbin + macros as source + post-macro .incbin.

### Surgery 2: InitializeScoop pre-include (6 bytes)
The standalone assembly FAILED earlier. Need to debug why and fix.

### Surgery 3: ColorBlit2 sub-label (6 bytes)
ColorBlit2_LargeCodeBlock was transplanted (4128 bytes) but its sub-label _0xBD9 still has diffs. The transplant bin may need re-extraction at the correct offset.

### Surgery 4: Pattern B pointer pairs (10 bytes, 5 labels)
Find the exact `.byte` lines at known offsets and change the 2 values each.

### Surgery 5: Pattern C pointer pairs (6 bytes, 3 labels)
Same as Surgery 4.

### Surgery 6: Individual single-byte fixes (11 bytes, 8 labels)
Direct `.byte` value changes for each known diff.

## Total: 45 bytes in 6 surgery types
