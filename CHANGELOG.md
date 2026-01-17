# Changelog - Claude Code Session

## Summary

This changelog documents the code changes made by Claude Code to improve the byte-matching accuracy of the Technics KN5000 ROM disassembly project.

**Starting point:** maincpu: 99.94% (1310 incorrect bytes)
**Ending point:** maincpu: 99.95% (1007 incorrect bytes)
**Improvement:** 303 bytes fixed

---

## Commits

### f0f0623 - Add CLAUDE.md with project guidance for Claude Code

Created `CLAUDE.md` containing:
- Build commands (`make all`, `make clean`)
- Project architecture overview
- Memory map documentation
- Technical constraints about ASL assembler limitations
- Guidelines for working with the codebase

### 43e909c - Add .gitignore for build artifacts

Created `.gitignore` to exclude:
- `rebuilt_ROMs/` directory (build output)
- `part_a.rom` and `part_b.rom` (intermediate files)

### 0aca1cb - maincpu: 99.95% (1109 bad bytes) - fix shift instruction encodings

**Problem:** ASL Macro Assembler 1.42 Beta encodes shift instructions differently than the TMP94C241F CPU expects. When writing `SRL 8, XWA`, ASL generates the shift amount as 8 in the instruction encoding, but the original ROM uses shift amount 0.

**Solution:** Added new macros to `tmp94c241.inc` that emit the correct raw bytes:

```asm
SRL_0_XBC MACRO
    db 0e9h, 0efh, 000h    ; SRL 0, XBC
    ENDM

SLL_0_XWA MACRO
    db 0e8h, 0eeh, 000h    ; SLL 0, XWA
    ENDM

SLL_0_XBC MACRO
    db 0e9h, 0eeh, 000h    ; SLL 0, XBC
    ENDM

SLL_0_XDE MACRO
    db 0eah, 0eeh, 000h    ; SLL 0, XDE
    ENDM

SLL_0_XHL MACRO
    db 0ebh, 0eeh, 000h    ; SLL 0, XHL
    ENDM

SLL_8_XIX MACRO
    db 0ech, 0eeh, 008h    ; SLL 8, XIX
    ENDM

SLA_0_XWA MACRO
    db 0e8h, 0ech, 000h    ; SLA 0, XWA
    ENDM

SRA_0_XBC MACRO
    db 0e9h, 0edh, 000h    ; SRA 0, XBC
    ENDM

SRA_0_XDE MACRO
    db 0eah, 0edh, 000h    ; SRA 0, XDE
    ENDM
```

**Bug fix:** Corrected `SLA_8_XWA` macro which had `000h` instead of `008h` for the shift amount byte.

**Files modified:**
- `tmp94c241.inc` - Added 9 new macros, fixed 1 existing macro
- `maincpu/kn5000_v10_program.asm` - Replaced ~405 shift instructions with appropriate macros

### baa7e24 through 77b0e91 - Iterative shift amount corrections

Multiple commits to refine which specific shift instructions needed the 0-shift vs 8-shift encoding:

| Commit | Bad bytes | Description |
|--------|-----------|-------------|
| baa7e24 | 1083 | Partial corrections |
| 1ef8040 | 1066 | Reverted incorrect changes |
| 557ab05 | 1016 | More corrections |
| 77b0e91 | 1007 | Complete shift corrections |

**Methodology:**
1. Compare rebuilt ROM with original byte-by-byte
2. Identify specific addresses with mismatches
3. Map addresses to source code lines using nearby labels
4. Determine correct encoding by examining original ROM bytes
5. Apply targeted replacements

---

## Technical Details

### Shift Instruction Encoding

The TLCS900 shift instructions have the format:
```
[register byte] [opcode byte] [shift amount byte]
```

| Instruction | Register byte | Opcode byte | Notes |
|-------------|---------------|-------------|-------|
| SRL XWA | E8h | EFh | Shift right logical |
| SRL XBC | E9h | EFh | |
| SLL XWA | E8h | EEh | Shift left logical |
| SLL XBC | E9h | EEh | |
| SLL XDE | EAh | EEh | |
| SLL XHL | EBh | EEh | |
| SLL XIX | ECh | EEh | |
| SLA XWA | E8h | ECh | Shift left arithmetic |
| SLA XDE | EAh | ECh | |
| SRA XWA | E8h | EDh | Shift right arithmetic |
| SRA XBC | E9h | EDh | |
| SRA XDE | EAh | EDh | |

The third byte specifies the shift amount (00h = shift by 0, 08h = shift by 8).

### ASL Assembler Limitation

ASL 1.42 Beta only supports TMP96C141, not the TMP94C241F used in the KN5000. This causes encoding differences for certain instructions. The workaround is to define macros that emit raw bytes for the correct encoding.

---

## Remaining Work

**1007 bytes** still differ from the original ROM due to:

1. **FA→E6 register encoding** (~61 cases)
   - `CP QIZ, 0` instruction encoded differently
   - Pattern: `D7 FA D8` (original) vs `D7 E6 D8` (ASL)

2. **Memory-to-memory load encoding** (~185 cases)
   - Pattern: `C1` (original) vs `F1` (ASL)

3. **CB→D9 register encoding** (~8 cases)
   - Different register encoding for certain instructions

---

## Files Changed

| File | Changes |
|------|---------|
| `CLAUDE.md` | Created - Project documentation |
| `.gitignore` | Created - Build artifact exclusions |
| `tmp94c241.inc` | Added 9 macros, fixed 1 bug |
| `maincpu/kn5000_v10_program.asm` | ~405 line changes for shift encodings |
