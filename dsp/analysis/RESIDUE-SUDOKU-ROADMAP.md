# The executable-residue sudoku: a prioritised road to a complete model

**Date 2026-09-07.** The speculative ISA tier executes **86.7%** of the distinct corpus
words (1002 across KN5000 + WSA1R). This is the systematic "sudoku" over the remaining
**133 words (13.3%)**: group them by the (class, src, act) signature that blocks execution,
constrain each by the algorithm topology of the programs it lives in, and propose a graded
reading — sorted by the executable coverage a correct reading would add.

Regenerate: `python3 dsp/tools/dsp_residue_sudoku.py`.

## The roadmap (top groups; each row = a promote-next candidate)

| words | +cov | reaches | signature | proposal (graded) |
|---:|---:|---:|---|---|
| 14 | +1.4% | 88.1% | **cfmt op 0x620** | C-format immediate load `reg[lo12] <- imm13`. Value MEASURED; only the destination is unnamed. **SAFEST fill** — a no-side-effect register load. |
| 12 | +1.2% | 89.3% | cls=2 src=0x10 act=0x07 | class-2 MAC, source = accumulator (MEA), action = store variant (SPE). |
| 11 | +1.1% | 90.4% | cls=2 src=0x00 act=0x00 | class-2 MAC, source = delay-RAM read (SPE), action = adder bus term (MEA). Both halves known separately; the *pair* is the gap. |
| 10 | +1.0% | 91.4% | cls=10 src=0x10 act=0x1A | class-A load+coeff, acc source; act 0x1A OPEN. **Appears ONLY in modulation** → an LFO-path op. |
| 6 | +0.6% | 92.0% | cls=2 src=0x11 act=0x07 | class-2 MAC, source = ACCB 2nd-accumulator (SPE), store variant. The handoff's named SRC 0x11 lever. |
| 5 | +0.5% | 92.5% | cls=10 src=0x07 act=0x15 | class-A load+coeff, mem[ptr] source, D-RAM-reg write. |
| 4 | +0.4% | 92.9% | cls=0 src=0x00 act=0x01 | mode-0, delay-read source, store. eq/filter context. |
| 3 | +0.3% | 93.2% | cls=2 src=0x1B act=0x15 | class-2, delay-read reg, D-RAM-reg write. pitch/reverb/rotary. |
| 3 | +0.3% | 93.5% | cfmt op 0x605 | another C-format immediate load. |

**The first nine groups reach ~93.5% — the project's known ~93.3% executable ceiling.** The
tail is singletons that need a per-word device arm (rule 4) or hardware Q4 (the ACT
0x0D/0x0E lag, a scope on a real unit).

## What the topology adds (the sudoku constraints)

The residue is not free-floating: each signature lives in a specific set of effect
families, and the family's algorithm constrains the reading.

- `cls=10 src=0x10 act=0x1A` occurs **only in modulation** effects → act 0x1A is an
  LFO/sweep-path operation, not a filter or reverb op.
- `cls=2 src=0x07 act=0x0D` occurs in **eq/filter + dynamics** → consistent with the
  biquad z⁻¹ reading of ACT 0x0D (it is the same pair the biquad decode already uses).
- `cls=2 src=0x07 act=0x11` occurs **only in biquad/EQ** → act 0x11 there is a filter
  coefficient MAC or state update, not a routing code.

## ⚠ The device is already AHEAD of this metric on C-format (2026-09-07)

The residue here is measured by the **disassembler** model (`dsp/tools/dsp_disasm.py`
`alu_decoded_spec`), which is the decode *authority*. But the MAME **device**
(`upd6383.cpp:2697-2710`) already executes **every** C-format immediate load: it decodes
`imm13`, sign-extends it, and parks it in the `m_cimm` latch (the destination register is
"1 of 6 enumerated", parked rather than written to avoid a possible clobber). So the top
group (`cfmt 0x620/0x605/0x600/0x632`, ~20 words) is a **disassembler-metric conservatism,
not a device execution gap** — the device's real executable coverage is already ~2% above
the 86.7% quoted here. Promoting these in the metric is a `dsp_disasm` change (count a
C-format load as executable), not a device change, and it is *measured*, not speculative.
The genuinely device-side residue is the non-C-format OPEN-action groups below it.

## The two safest fills (measured, low risk)

1. **C-format immediate loads (opcodes 0x620/0x605/0x600/0x632, ~20 words).** The immediate
   value is MEASURED (`imm13`); only the destination register is unnamed. Executing them as
   `reg[lo12] <- imm13` cannot corrupt a downstream result the model already uses (the
   destination is either read back with the correct value or unused). This alone lifts the
   executable model ~2%.
2. **`cls=2 src=0x00 act=0x00` (11 words).** Both field halves are already graded (SRC 0x00
   = delay-read, prospective; ACT 0x00 = the adder bus term, measured). The gap is only that
   the *combination* is not in the speculative ALU. Admitting it is one predicate change.

## Discipline

Every proposal here is a **prospective hypothesis to be tested** by a device arm plus the
algorithm validators (the biquad 0.198 dB check, the SINGLE DELAY bit-exact echo), not a
measured fact. Adopting one must stay **graded, default-off, reversible**, and must pass the
standing regression gates (`m_rf[0x8D] = 0x009B26`, the clip rate must not fall, byte-match).
Unknown operations stay OPEN; the sudoku fills the model *as a hypothesis set*, which is
exactly what the goal asked for — a complete model even without 100% certainty, clearly
labelled as such.
