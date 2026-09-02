
## `llvm_roundtrip_probe.py`

**Question:** can the assembler re-encode what its own disassembler emits? Takes
real ROM bytes, disassembles, feeds that exact text back to `llvm-mc`, compares
BYTES against the original.

    python3 notes/llvm_roundtrip_probe.py       # LLVM_MC= and ROM= override

Three outcomes, deliberately distinguished: round-trips / REJECTED (cannot parse
its own output) / ⚠ ENCODES DIFFERENTLY — accepted and wrong, which produces no
diagnostic and is why this compares bytes rather than exit status.

⚠ It also reports **VACUOUS** when zero instructions decode. Without that guard
it printed "roundtrip: OK" for an empty comparison — 0 bytes against 0 bytes —
on exactly the regions it was built to investigate: it was seeking a ROM
*address* straight into the *file* with no base subtracted, so every
DSP_Bytecode_Op0N region (all above 0x30000) read past EOF and decoded 0
instructions, which the vacuous-pass bug then misreported as clean. Fixed:
`kn5000_subprogram_v142.rom` addresses start at 0x0EF00, not 0 (confirmed
against `kn5000_subprogram_v142.rom.unidasm`'s first/last line addresses,
which span exactly the 196,608-byte file size from that base) — `ROM_BASE`
env var overrides it for another image. `--diagnose` adds a per-instruction
breakdown (original bytes vs re-encoded bytes) for whichever blocks don't
round-trip clean, using the disassembler's own reported encoding per
instruction as the position anchor rather than an inferred length, so one
bad instruction can't desync every mismatch reported after it. The same
invocation also walks the still-`.byte` TaskSched/TaskEvent/FIFO runs in
`v142/subcpu/kn5000_subprogram_v142.s` directly from source.
