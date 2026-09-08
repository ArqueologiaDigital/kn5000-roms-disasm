# A documented NEC DSP as a Rosetta stone for the uPD6383GF

**Date 2026-09-09.** A different way in — not correlation, not hardware, but a *documented*
source. The uPD6383GF itself is undocumented (absent from every NEC databook, confirmed
again below). But NEC's **general-purpose DSP family — the µPD7720 / 77C25** — *is* fully
documented, in the 1989 "DSP and Speech Products Data Book" and the 1992 "NEC DSP and Speech
Processor Products" book (both held in `~/compartilhado/KN7000`), and it is even emulated in
MAME (`upd7725`). NEC reused its horizontal-microcode conventions across its DSP products, so
the documented 77C25 word is a house-style Rosetta stone for the 6383's field structure and —
more usefully — its **execution-order model**, several parts of which the 6383 disassembly had
only ever graded as *FORCED* (inferred, not measured). Evidence + reproduction recipe:
`dsp/analysis/data/nec-upd77c25-op-format-extract.txt`.

## First, the negative control

The 6383 is not in these books: `pdftotext | grep -i 638x` returns one incidental hit and
**zero** for `reverb`/`effect`, and no 36-bit instruction word is described. The databooks
document the µPD7720/77C25 (a **23-bit** word) and the 77220/77230 (float DSPs). So this is an
*analogy to a documented sibling family*, not a datasheet for the part — graded accordingly
below.

## The µPD77C25 OP word, and the 6383 word beside it

The 77C25 multifunction **OP instruction** is one 23-bit horizontal word whose fields are
(high→low): `opcode · P-Select · ALU · ASL · DPL · DPH-M · (RP)DCR · SRC · DST`. It performs,
in one word: a **data move** (SRC→DST), an **ALU op** (on a P-select operand, into ACCA/ACCB
chosen by ASL), a **pointer modification**, and optionally a **return**.

The 6383's 36-bit word decodes as `hi12 · class4 · addr8 · lo12`, with
`lo12 = SRC[10:6] · ptr-mode[5] · DST/ACT[4:0]` (`dsp_disasm.lo_src`/`lo_act`), `addr8` a
signed pointer post-increment, and `f31 = hi12[1:3]`. Field-for-field that is the **same shape
of instruction**: a SRC→DST data-move pair, a pointer field, and an ALU-op subfield, packed in
one horizontal word. The 6383 is a wider, later member of the same design school.

## What the documented convention CORROBORATES (previously FORCED/speculative)

The high-value payoff is the 77C25's stated **execution order**, because it independently
confirms 6383 decode decisions that had no measured basis:

| 77C25 documented rule | 6383 disasm decision it corroborates | was graded |
|---|---|---|
| "data moves … **before** other elements … the data move supersedes the ALU operation" | `plain store: mem[ptr] <- acc, taken **BEFORE** this word's ALU step` | **FORCED** → *now convention-corroborated* |
| "pointer modifications occur at the **end** of the instruction cycle after their values have been used" | the `cur+` pointer **post**-increment (used first, advanced after) | inferred → corroborated |
| "if a return is specified … it is executed **last**" | `END OF BLOCK … CALL/RETURN … and still performs the rest of the word` | FORCED → corroborated |
| SRC field / DST field data-move pair | `lo12 = SRC[10:6] · DST/ACT[4:0]` | the field split itself, corroborated |
| two accumulators **ACCA/ACCB**, selectable, usable as SRC/DST operands | `SRC 0x11 = ACCB (2nd accumulator)` (speculative) | SPECULATIVE → *plausibility raised* |
| ALU field = NOP/ADD/SUB/AND/OR/XOR/INC/DEC/CMP | `f31 = hi12[1:3]` read as an ALU-op select (LOAD/HOLD…) | speculative → *framed by a documented op-set* |

So the 6383's execution-order model — store-before-ALU, post-increment-at-end, return-last —
is not a guess forced by the corpus; it is **exactly the order NEC documents for its DSPs**.
That moves three FORCED readings onto a documented footing without any hardware.

## The register-operand encoding matches the convention — including adjacent pairs

The 77C25 provides its ALU/data-move operands as a small register vocabulary — RAM, the two
accumulators A/B, a temp register (TR), a ROM/data pointer, status/serial — with A and B as
*adjacent* codes in the SRC/DST tables. The 6383's already-decoded SRC codes (`dsp_disasm`)
line up with that vocabulary, and reproduce the *adjacent-pair* encoding:

| 6383 SRC | dsp_disasm role | NEC operand role | grade |
|---|---|---|---|
| `0x07` | `mem[ptr]` | **RAM** | MEASURED |
| **`0x10` / `0x11`** | ACCA / ACCB | **the two accumulators A/B** (adjacent codes) | 0x10 proven by the solved PEQ; 0x11 spec |
| **`0x19` / `0x1A`** | temp TA / TB | **temp register(s)** (adjacent codes) | anchored |
| `0x13` | coef/wave table | **ROM / coefficient-pointer read** | inferred |

That the accumulators sit at `0x10/0x11` and the temps at `0x19/0x1A` — each an adjacent
pair — is the NEC convention showing through: the register file is encoded the way NEC encodes
its DSP operands, which independently validates the 6383 register decode (and the Rosetta
approach itself: the convention *predicts* the encoding, it does not merely post-hoc fit it).

**A new graded reading for an OPEN code falls out.** SRC `0x01` (72 uses) never feeds a
multiply (0 % in MAC words); it appears only inside a fixed `C-format → [SRC 0x01 load] →
external-DRAM` template (preceded by a C-format immediate 64/72, followed by a DRAM access
70/72). That is not an ALU input — it is an **address / data-pointer setup**, matching NEC's
**DP (data-pointer)** operand role: load an immediate, stage it through SRC 0x01, use it to
address delay-DRAM. Graded — a documented-role hypothesis to confirm by a device arm — but it
retires "SRC 0x01 dark" with a specific, testable role drawn from the documented vocabulary
rather than invented.

## What it does NOT prove (honest limits)

- **Not ISA identity.** The word widths differ (23 vs 36 bit), the product lines differ
  (general math DSP vs audio-effects ASSP), and the *numeric* field codes do **not** transfer
  — a 6383 SRC of `0x11` is not the 77C25's ACCB code; only the *presence and role* of an
  ACCB-as-operand convention transfers.
- So every row above is graded **"corroborated by documented NEC DSP convention (µPD77C25)"** —
  stronger than the corpus-only correlation grade, weaker than a bit-level datasheet match.
  It raises confidence and retires the bare "FORCED" label; it does not close a Q4.

## Why this is a new "other way", and what it unlocks next

Correlation (`DECODE-by-correlation`, §1–§16) mined the corpus against itself; this mines a
*documented relative* instead. Two further moves it opens, both hardware-free:

1. **MAME's `upd7725` core** implements the 77C25 ALU/flag/pointer semantics already. Reading
   it is a second, executable expression of the same conventions to check the 6383 model
   against (e.g. the dual-accumulator flag behaviour, the "data-move supersedes ALU" NOP case).
2. The 77C25 P-select/SRC/DST **register tables** name the standard NEC DSP operands (RAM, IDB,
   M/N multiplier ports, TR, DP, RP, DR, SR, serial). The 6383's still-OPEN SRC/ACT codes can
   now be read *as a search for these known register roles* (a multiplier input port, a status
   register, a serial I/O latch) rather than from scratch — a documented hypothesis set to test
   by context (`dsp_context_analysis`) instead of inventing meanings.

Instruments: the databook extract (`data/nec-upd77c25-op-format-extract.txt`) with its
`pdftotext` recipe; the corroborated 6383 annotations are in the committed `dsp/disasm/*.dsm`.
