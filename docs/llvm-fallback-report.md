# LLVM TLCS-900 Backend: Instruction Fallback Report

**Date:** 2026-02-22
**ROM:** KN5000 v1.0 Program ROM (2MB, `kn5000_v10_program`)
**Converter:** `scripts/converters/asl_to_llvm.py` → `maincpu/llvm/kn5000_v10_program.s`
**Status:** 100% byte-identical ROM reconstruction via LLVM toolchain

## Executive Summary

The LLVM TLCS-900 backend currently handles **90,660 native instructions** (41.7% of all
code), while **126,730 instruction lines** (58.3%) remain as `.byte` fallback sequences.
49 unique TLCS-900 mnemonics appear in fallback; only 21 are natively supported.

**Four improvements would convert 63.8% of all code to native:**
1. Relative branch encoding (JR/JRL/CALR) — 36,432 lines
2. Load Effective Address (LDA) — 11,587 lines
3. Remaining LD addressing modes — 53,813 lines
4. Short-form immediate encodings — ~10,000 lines

---

## 1. Current Native vs Fallback Coverage

| Mnemonic | Native | Fallback | Total | % Native | Status |
|----------|-------:|----------:|------:|----------:|--------|
| LD       | 28,277 | 53,813   | 82,090 | 34.4% | Partial — many addressing modes missing |
| CALL     | 14,389 | 375      | 14,764 | 97.5% | Nearly complete |
| CP       |  8,669 | 8,194    | 16,863 | 51.4% | Partial |
| EXTZ     |  6,933 | 0        |  6,933 | 100%  | Complete |
| ADD      |  5,579 | 1,124    |  6,703 | 83.2% | Partial |
| PUSH     |  5,618 | 1,556    |  7,174 | 78.3% | Partial |
| RET      |  5,203 | 545      |  5,748 | 90.5% | Nearly complete |
| POP      |  3,589 | 1,014    |  4,603 | 78.0% | Partial |
| INC      |  3,553 | 1,066    |  4,619 | 76.9% | Partial |
| AND      |  2,083 | 1,322    |  3,405 | 61.2% | Partial |
| DEC      |  1,560 | 216      |  1,776 | 87.8% | Nearly complete |
| SUB      |  1,287 | 458      |  1,745 | 73.7% | Partial |
| EXTS     |  1,230 | 0        |  1,230 | 100%  | Complete |
| OR       |  1,028 | 1,039    |  2,067 | 49.7% | Partial |
| XOR      |    851 | 47       |    898 | 94.8% | Nearly complete |
| JP       |    595 | 284      |    879 | 67.7% | Partial |
| CPL      |     93 | 26       |    119 | 78.2% | Partial |
| NOP      |     78 | 0        |     78 | 100%  | Complete |
| NEG      |     23 | 0        |     23 | 100%  | Complete |
| RETI     |     20 | 0        |     20 | 100%  | Complete |
| HALT     |      2 | 0        |      2 | 100%  | Complete |
| JR       |      0 | 22,715   | 22,715 | 0%    | **No native support** |
| LDA      |      0 | 11,587   | 11,587 | 0%    | **No native support** |
| CALR     |      0 | 6,871    |  6,871 | 0%    | **No native support** |
| JRL      |      0 | 6,846    |  6,846 | 0%    | **No native support** |
| BIT      |      0 | 2,494    |  2,494 | 0%    | **No native support** |
| SLL      |      0 | 1,221    |  1,221 | 0%    | **No native support** |
| SLA      |      0 | 1,137    |  1,137 | 0%    | **No native support** |
| RES      |      0 | 647      |    647 | 0%    | **No native support** |
| SET      |      0 | 528      |    528 | 0%    | **No native support** |
| SRL      |      0 | 366      |    366 | 0%    | **No native support** |
| EI       |      0 | 301      |    301 | 0%    | **No native support** |
| SCC      |      0 | 218      |    218 | 0%    | **No native support** |
| DJNZ     |      0 | 129      |    129 | 0%    | **No native support** |
| LDIR     |      0 | 77       |     77 | 0%    | **No native support** |
| MUL      |      0 | 71       |     71 | 0%    | **No native support** |
| STCF     |      0 | 69       |     69 | 0%    | **No native support** |
| RETD     |      0 | 68       |     68 | 0%    | **No native support** |
| DIV      |      0 | 59       |     59 | 0%    | **No native support** |
| SCF      |      0 | 37       |     37 | 0%    | **No native support** |
| LDI      |      0 | 33       |     33 | 0%    | **No native support** |
| EX       |      0 | 29       |     29 | 0%    | **No native support** |
| MULS     |      0 | 24       |     24 | 0%    | **No native support** |
| UNLK     |      0 | 21       |     21 | 0%    | **No native support** |
| DIVS     |      0 | 17       |     17 | 0%    | **No native support** |
| RRC      |      0 | 15       |     15 | 0%    | **No native support** |
| RLC      |      0 | 14       |     14 | 0%    | **No native support** |
| TSET     |      0 | 11       |     11 | 0%    | **No native support** |
| RCF      |      0 | 10       |     10 | 0%    | **No native support** |
| ADC      |      0 | 6        |      6 | 0%    | **No native support** |
| CHG      |      0 | 2        |      2 | 0%    | **No native support** |
| LDDR     |      0 | 1        |      1 | 0%    | **No native support** |
| RL       |      0 | 1        |      1 | 0%    | **No native support** |
| RR       |      0 | 1        |      1 | 0%    | **No native support** |

---

## 2. Improvement Areas (Ordered by Impact)

### 2.1. Relative Branch Encoding — 36,432 lines (28.8% of fallback)

**Problem:** The LLVM backend does not support the short relative branch/call
instructions JR, JRL, and CALR. These are the most space-efficient control flow
instructions on TLCS-900, but the backend always emits absolute JP/CALL instead.

The converter cannot use native LLVM `jr`/`jrl`/`calr` because LLVM pads them with
NOPs to reach 4 bytes (the absolute instruction size), producing wrong byte sequences.

| Instruction | Encoding | ROM Size | LLVM Emits | Fallback Count |
|-------------|----------|----------|------------|---------------:|
| JR cc, d8   | `6C+cc d8` | 2 bytes | 4-byte JP (padded) | 22,715 |
| JRL cc, d16 | `6C+cc d16_lo d16_hi` | 3 bytes | 4-byte JP (padded) | 6,846 |
| CALR d16    | `1E d16_lo d16_hi` | 3 bytes | 4-byte CALL (padded) | 6,871 |

**What needs to change in LLVM:**
- **MCCodeEmitter:** Emit correct 2-byte (JR) or 3-byte (JRL/CALR) encodings
  without NOP padding. The backend currently pads all branch instructions to a
  uniform 4-byte size.
- **Relaxation support:** Implement `MCFixup` relaxation so the assembler can
  choose between JR (±128), JRL (±32K), and JP (absolute) based on actual
  branch distance. This is the standard LLVM pattern for variable-length branches.
- **MCFixupKind:** Define fixup kinds for 8-bit relative (JR) and 16-bit relative
  (JRL/CALR) displacements.

**Impact:** Converting these alone would move native coverage from 41.7% to **58.5%**.

---

### 2.2. Load Effective Address (LDA) — 11,587 lines (9.1% of fallback)

**Problem:** The LDA instruction (load effective address into register) has zero
native support. LDA is the TLCS-900 equivalent of x86's LEA — it computes an
address and stores it in a register without dereferencing memory.

| Operand Pattern | Count | % | Encoding |
|-----------------|------:|----:|----------|
| reg, (reg+d16) — register+displacement | ~5,224 | 45.1% | Prefix + opcode + d16 |
| reg, abs24 — absolute address | 3,142 | 27.1% | Prefix + opcode + abs24 |
| reg, (XSP+d16) — stack-relative | ~2,666 | 23.0% | Prefix + opcode + d16 |
| reg, (reg) — register indirect | 314 | 2.7% | Prefix + opcode |
| reg, symbol — symbolic address | 241 | 2.1% | Same as abs24 |

**What needs to change in LLVM:**
- **InstrInfo:** Define `LDA` instruction with all addressing modes (register+disp,
  absolute, stack-relative, register indirect).
- **MCCodeEmitter:** Encode the prefix byte (register specifier) + LDA opcode +
  address operand.
- **InstrFormats:** LDA uses the same prefix-based encoding as LD but with a
  different sub-opcode.

---

### 2.3. Remaining LD Addressing Modes — 53,813 lines (42.5% of fallback)

**Problem:** LD is already partially supported (28,277 native), but the majority of
LD instructions still fall back because many addressing modes are missing from the
LLVM backend.

| Addressing Mode | Fallback Count | % of LD Fallback | Description |
|-----------------|---------------:|---:|-------------|
| reg, (reg+d) | 18,807 | 34.9% | Load from register+displacement |
| reg, #imm | 10,548 | 19.6% | Load immediate (various sizes) |
| reg, (abs) | 7,086 | 13.2% | Load from absolute memory |
| (reg+d), reg | 5,717 | 10.6% | Store to register+displacement |
| (abs), reg | 4,125 | 7.7% | Store to absolute memory |
| reg, reg | 2,337 | 4.3% | Register-to-register |
| (abs), #imm | 1,962 | 3.6% | Store immediate to memory |
| (reg+d), #imm | 1,185 | 2.2% | Store immediate to displacement |
| (reg), #imm | 632 | 1.2% | Store immediate to indirect |
| Other (76 patterns) | 1,414 | 2.6% | Auto-inc, 3-reg, etc. |

**Specific encoding issues:**

**A. 16-bit register immediate loads (5,675 lines):**
ROM uses a 3-byte encoding (`LD rr, #imm16` = prefix + imm16_lo + imm16_hi),
but LLVM emits a 4-byte encoding. The backend selects the wrong encoding table
for 16-bit register operands.

**B. Short-form immediate values 0–7 (4,055 lines across LD/CP/ADD/AND/OR/etc.):**
TLCS-900 has 2-byte short-form encodings for immediate values 0–7 using a
3-bit field embedded in the opcode. The LLVM backend always uses the full
immediate encoding (3+ bytes). This affects LD, CP, ADD, AND, OR, SUB, XOR.

**What needs to change in LLVM:**

- **Displacement addressing:** Add `(reg+d8)` and `(reg+d16)` addressing modes
  to LD instruction definitions. This requires:
  - New `MachineOperand` types for register+displacement
  - MCCodeEmitter support for prefix byte (source/dest register) + displacement
  - Both load and store directions

- **Absolute memory addressing:** Add `(abs24)` addressing modes (many already
  exist for CP/AND but not all LD variants).

- **16-bit immediate encoding fix:** The MCCodeEmitter must select the correct
  3-byte encoding for `LD rr, #imm16` instead of the 4-byte form.

- **Short-form immediate optimization:** Add patterns that recognize immediates
  0–7 and emit the 2-byte short-form encoding. This is a peephole-level
  optimization in the MCCodeEmitter or instruction selection.

---

### 2.4. ALU Instructions with Missing Modes — 12,960 lines (10.2% of fallback)

Several ALU instructions are partially supported but missing addressing modes:

| Mnemonic | Fallback | Native | Missing Modes |
|----------|--------:|-------:|---------------|
| CP       | 8,194  | 8,669  | (abs),#imm; (reg+d),#imm; reg,(reg+d); (reg),#imm |
| ADD      | 1,124  | 5,579  | (abs),#imm; reg,(reg+d); (reg+d),#imm |
| AND      | 1,322  | 2,083  | (abs),#imm; (reg),#imm; reg,(abs); (reg+d),#imm |
| OR       | 1,039  | 1,028  | Similar to AND |
| SUB      | 458    | 1,287  | Similar to ADD |
| INC      | 1,066  | 3,553  | (abs); (reg+d); (reg) |
| DEC      | 216    | 1,560  | (abs); (reg+d) |
| XOR      | 47     | 851    | Mostly covered |

**What needs to change in LLVM:**
- Extend existing ALU instruction definitions with displacement and absolute
  memory addressing modes (same patterns as LD above).
- The encoding follows the same prefix-based scheme — once displacement
  addressing is implemented for LD, ALU instructions can reuse the same
  infrastructure.

---

### 2.5. Bit Manipulation — 3,669 lines (2.9% of fallback)

| Mnemonic | Count | Description |
|----------|------:|-------------|
| BIT      | 2,494 | Test bit |
| RES      | 647   | Reset (clear) bit |
| SET      | 528   | Set bit |

**Operand patterns (BIT):**
- `BIT n, (abs)` — 54.6% (1,361 lines)
- `BIT n, reg` — 31.7% (791 lines)
- `BIT n, (reg)` — 6.7% (167 lines)
- `BIT n, (reg+d)` — 4.8% (120 lines)

**What needs to change in LLVM:**
- Define BIT/RES/SET/CHG/TSET instructions
- These use a bit-number immediate (0–7) encoded in the opcode
- Support register, absolute, indirect, and displacement addressing modes

---

### 2.6. Shift/Rotate — 3,967 lines (3.1% of fallback)

| Mnemonic | Count | Description |
|----------|------:|-------------|
| SLL      | 1,221 | Shift Left Logical |
| SLA      | 1,137 | Shift Left Arithmetic |
| SRL      | 366   | Shift Right Logical |
| SRA      | 25    | Shift Right Arithmetic |
| RLC      | 14    | Rotate Left through Carry |
| RRC      | 15    | Rotate Right through Carry |
| RL       | 1     | Rotate Left |
| RR       | 1     | Rotate Right |

Shift/rotate by immediate count (97.5%) and by register (2.5%).

**What needs to change in LLVM:**
- Define all 8 shift/rotate instructions
- Support both immediate shift count and register shift count operands
- These use the same prefix-based encoding scheme

---

### 2.7. Miscellaneous Instructions — 1,158 lines (0.9% of fallback)

| Mnemonic | Count | Description |
|----------|------:|-------------|
| RET cc   | 545   | Conditional return (RET already native, but conditional forms missing) |
| PUSH r   | 1,556 | Some register sizes missing |
| POP r    | 1,014 | Some register sizes missing |
| EI n     | 301   | Enable interrupts (interrupt level) |
| SCC cc,r | 218   | Set register on condition |
| DJNZ     | 129   | Decrement and Jump if Not Zero |
| LDIR     | 77    | Block transfer (repeat) |
| MUL      | 71    | Unsigned multiply |
| STCF     | 69    | Store carry flag to bit |
| RETD     | 68    | Return and deallocate stack |
| DIV      | 59    | Unsigned divide |
| SCF      | 37    | Set carry flag |
| LDI      | 33    | Block transfer (single) |
| EX       | 29    | Exchange registers |
| MULS     | 24    | Signed multiply |
| UNLK     | 21    | Unlink frame pointer |
| DIVS     | 17    | Signed divide |
| TSET     | 11    | Test and set bit |
| RCF      | 10    | Reset carry flag |
| ADC      | 6     | Add with carry |
| CALL cc  | 375   | Conditional call (absolute CALL native, conditional missing) |
| JP cc    | 284   | Conditional JP to memory/register operands |
| LDDR     | 1     | Block transfer (repeat, decrement) |

**What needs to change in LLVM:**
- **Conditional RET/CALL/JP:** Add condition code operand to existing instruction
  definitions. The encoding adds a condition nibble to the opcode.
- **EI/SCF/RCF/CCF:** Simple single-byte or two-byte instructions — easy to add.
- **PUSH/POP:** Add missing register size variants.
- **MUL/MULS/DIV/DIVS:** Arithmetic instructions with specific register constraints.
- **LDIR/LDI/LDDR:** Block transfer instructions — fixed encoding, no operands.
- **DJNZ:** Decrement-and-branch — similar to JR but with a register operand.
- **RETD/UNLK/EX:** Stack manipulation — straightforward encodings.

---

## 3. Recommended Implementation Order

Based on impact (lines converted) and implementation complexity:

| Priority | Improvement | Lines Converted | Cumulative Coverage |
|:--------:|-------------|----------------:|--------------------:|
| **P1** | Relative branches (JR/JRL/CALR) | 36,432 | 58.5% |
| **P2** | LD displacement addressing (reg+d) | 24,524 | 69.8% |
| **P3** | LDA instruction | 11,587 | 75.1% |
| **P4** | LD/ALU absolute memory modes | 14,821 | 81.9% |
| **P5** | Short-form immediates (0–7) | ~4,055 | 83.8% |
| **P6** | 16-bit register immediate fix | 5,675 | 86.4% |
| **P7** | Bit manipulation (BIT/RES/SET) | 3,669 | 88.1% |
| **P8** | Shift/rotate instructions | 3,967 | 89.9% |
| **P9** | Conditional RET/CALL/JP | 1,204 | 90.5% |
| **P10** | Remaining misc instructions | 1,158 | 91.0% |
| **P11** | LD immediate stores to memory | 3,779 | 92.7% |
| **P12** | Remaining LD patterns | 3,875 | 94.5% |
| **P13** | Remaining ALU fallback | ~5,984 | ~97.3% |

**Note:** The remaining ~3% consists of rare addressing modes, register size
variants, and edge cases scattered across many instructions.

---

## 4. Architectural Notes for Implementation

### Prefix-Based Encoding
TLCS-900 uses a prefix byte system for register operands. The prefix selects:
- Source/destination register bank (XWA, XBC, XDE, XHL, XIX, XIY, XIZ, XSP)
- Operand size (byte, word, long)
- Addressing mode (direct, indirect, displacement, auto-increment)

The LLVM backend already handles some prefix combinations. Extending to displacement
and absolute modes requires:
1. New `MCOperandInfo` entries for displacement operands
2. Prefix byte computation in MCCodeEmitter for the new addressing modes
3. Instruction format classes in TableGen for the new operand combinations

### Relaxation Framework
For relative branches, implement `MCFixup` relaxation:
- `JR` (8-bit displacement, 2 bytes) → `JRL` (16-bit, 3 bytes) → `JP` (absolute, 4 bytes)
- `CALR` (16-bit displacement, 3 bytes) → `CALL` (absolute, 4 bytes)

This is the standard LLVM pattern used by x86, ARM, RISC-V, etc.

### Short-Form Immediate Optimization
Values 0–7 can use a compact 2-byte encoding where the 3-bit value is embedded
in the opcode byte itself. This should be implemented as either:
- An MCCodeEmitter optimization (check immediate value at encoding time)
- Separate TableGen instruction definitions with `ImmRange<0,7>` constraints

---

## 5. Impact Summary

| Scenario | Native Lines | % of Code |
|----------|------------:|----------:|
| Current state | 90,660 | 41.7% |
| After P1 (relative branches) | 127,092 | 58.5% |
| After P1–P3 (+ displacement + LDA) | 163,203 | 75.1% |
| After P1–P6 (+ abs + imm fixes) | 187,758 | 86.4% |
| After P1–P10 (all major groups) | 196,598 | 90.5% |
| Theoretical maximum | ~217,390 | ~100% |

The first three priorities alone (relative branches, displacement addressing, LDA)
would nearly double native instruction coverage from 41.7% to 75.1%.
