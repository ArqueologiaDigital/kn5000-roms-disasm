
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
on exactly the regions it was built to investigate.
