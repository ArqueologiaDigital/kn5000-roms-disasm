# Changelog - Claude Code Session

## Summary

This changelog documents the code changes made by Claude Code to improve the byte-matching accuracy of the Technics KN5000 ROM disassembly project.

**Starting point:** maincpu: 99.94% (1310 incorrect bytes)
**Current status:** maincpu: 99.99% (227 incorrect bytes)
**Total improvement:** 1083 bytes fixed (83% reduction in errors)

---

## Commits (Chronological)

### f0f0623 - Add CLAUDE.md with project guidance

Created project documentation file with build commands, architecture overview, and technical constraints.

### 43e909c - Add .gitignore for build artifacts

Excluded `rebuilt_ROMs/`, `part_a.rom`, `part_b.rom` from version control.

### 0aca1cb through 77b0e91 - Fix shift instruction encodings (1310→1007 bytes)

Fixed ASL assembler encoding issues with shift instructions (SRL/SLL/SLA/SRA).
Added 9 new macros for 0-shift variants and fixed `SLA_8_XWA` bug.

### cd07409 - Fix CP QBC/QIZ register encoding (1007→951 bytes)

Changed 61 instances of `CP QBC, 0` to `CP QIZ, 0` where the original ROM uses the QIZ register encoding.

### 3d501bb - Fix remaining CP QBC/QIZ cases (951→947 bytes)

Fixed `CP QBC, 7` → `CP QIZ, 7` (1 instance) and `CP QBC, 3` → `CP QIZ, 3` (3 instances).

### 8291b7d - Fix memory-to-memory LD encoding (947→417 bytes)

Added `LD_8_8` macro using C1 encoding (`C1 src 19 dst`) instead of ASL's F1 encoding.
Replaced 106 byte memory-to-memory load instructions.

### a3b950b - Fix LDW memory-to-memory encoding (417→257 bytes)

Converted 27 `LDW (mem), (mem)` instructions to use `LDW_16_16` macro with D1 encoding.

### ed2dd6a - Fix MUL_C macro encoding (257→240 bytes)

Fixed `MUL_C` macro to use `CB` prefix (for C register) instead of incorrect `D9` prefix.

### 2e3845f - Fix LDA E0 encoding variants (240→227 bytes)

Added E0 variant macros for LDA instructions and changed 13 instructions to use correct encoding.

---

## Technical Details

### Issue Categories Fixed

| Issue | Pattern | Count | Solution |
|-------|---------|-------|----------|
| Shift amount encoding | 00↔08 in shift instructions | ~303 | Created 0-shift macros |
| CP register encoding | FA↔E6 (QIZ vs QBC) | 65 | Changed QBC to QIZ |
| Memory-to-memory LD | C1↔F1 (different encodings) | 106 | Created LD_8_8 macro |
| Memory-to-memory LDW | D1↔F1 (use macro) | 27 | Used LDW_16_16 macro |
| MUL_C macro bug | CB↔D9 (wrong prefix) | 17 | Fixed macro prefix |
| LDA addressing mode | E0↔E2 (different modes) | 13 | Created E0 variant macros |

### New Macros Added to tmp94c241.inc

**Shift instruction macros (0-shift variants):**
- `SRL_0_XBC`, `SRL_0_XWA` (already existed)
- `SLL_0_XWA`, `SLL_0_XBC`, `SLL_0_XDE`, `SLL_0_XHL`
- `SLL_8_XIX`
- `SLA_0_XWA`
- `SRA_0_XBC`, `SRA_0_XDE`

**Memory-to-memory load macro:**
- `LD_8_8` - Byte memory-to-memory load with C1 encoding

**LDA E0 variant macros:**
- `LDA_XBC_XWA_plus__e0__`
- `LDA_XDE_XWA_plus__e0__`
- `LDA_XHL_XWA_plus__e0__`
- `LDA_XIX_XWA_plus__e0__`
- `LDA_XWA_XWA_plus__e0__`

### Bug Fixes in tmp94c241.inc

1. `SLA_8_XWA`: Changed shift amount from `000h` to `008h`
2. `MUL_C`: Changed prefix from `D9h` to `CBh`

---

## Remaining Work

**227 bytes** still differ from the original ROM, scattered across 28 small groups.
These appear to be various individual encoding differences that would require detailed investigation:

- Operand byte ordering differences
- Other addressing mode variants
- Individual instruction encoding quirks

---

## Files Changed Summary

| File | Total Changes |
|------|---------------|
| `CLAUDE.md` | Created |
| `.gitignore` | Created |
| `tmp94c241.inc` | +17 new macros, 2 bug fixes |
| `maincpu/kn5000_v10_program.asm` | ~650+ line changes |

---

## Methodology

1. **Identify patterns:** Compare rebuilt ROM with original byte-by-byte to find mismatch patterns
2. **Analyze encoding:** Determine what instruction each byte pattern represents
3. **Test with ASL:** Verify ASL's encoding vs original ROM encoding
4. **Create macros:** For unsupported encodings, create macros that emit raw bytes
5. **Apply fixes:** Replace instructions in source with correct macros
6. **Iterate:** Rebuild, compare, refine until pattern is fixed
7. **Commit:** Save progress after each improvement
