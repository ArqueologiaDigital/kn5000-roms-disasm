# What llvm-mc still cannot spell, and what it can now

`wsa1/include/tlcs900_mem_ops.inc` exists only to work around the assembler:
122 macros, 12,539 call sites, every one of them emitting raw `.byte` because
llvm-mc had no mnemonic for the instruction.  These two tools measure how much
of that is still necessary.  Both read the REAL call sites in this tree, so
their numbers are about this firmware, not about a synthetic test case.

| script | question it answers | run it |
|---|---|---|
| `llvm_encoding_gaps.py` | which forms are fixed, which are still rejected, and which are ACCEPTED AND WRONG | `python3 wsa1/notes/llvm/llvm_encoding_gaps.py` |
| `llvm_native_equivalence.py` | for every macro call site in the tree, does the native spelling emit the SAME BYTES? | `python3 wsa1/notes/llvm/llvm_native_equivalence.py` |

Both take `--selftest` (exit non-zero on failure); the equivalence tool also
takes `-v` to print the first few mismatches per macro.

## The rule these tools exist to enforce

**"llvm-mc accepted it" is not evidence that a macro can be retired.**  Until
2026-09-01 `push (0x1234)` assembled, without any diagnostic, to `09 34` -- the
address truncated to eight bits, because `push` had no memory form and the
parenthesised address was read as an immediate.  `mul WA,(0x1234)` was the same
defect wearing an "already native" label.  So the only acceptable proof that a
call site can become a real mnemonic is that both spellings emit the same
bytes, which is what `llvm_native_equivalence.py` checks and what the project
byte gate (`make gate-all`) then confirms end to end.

The macro's bytes are the specification: they were derived from ROMs that
rebuild byte-identically.  If a native encoding disagrees with the macro, the
encoding is wrong, not the macro.

## The address width is a spelling choice, not an optimisation

A direct memory operand encodes its address width in the prefix, and the width
is **not** a function of the address value -- this firmware really does write
`set 7,(0x00008a)` as `F2 8A 00 00 BF`, the 24-bit form, for an address that
fits in eight bits.  So llvm-mc must never pick a width by looking at the
number.  Since tlcs900_backend@e7a43c67fdca the source says which it wants:

    bit 1,(0x2075:16)     ->  f1 75 20 c9      the ROM's encoding
    bit 1,(0x2075)        ->  f2 75 20 00 c9   no suffix = the 24-bit default

## Reading the equivalence table

`sites` is every call of that macro in the tree; `tried` is how many had a
native spelling rendered for their addressing class; `same`/`diff` are the byte
comparison.  A macro is only `RETIREABLE` when `diff` is 0 **and** `tried`
equals `sites` -- a macro with `tried` below `sites` has call sites in an
addressing class for which this tool claims nothing.

The tool renders both sides itself, and two of its own details are easy to get
wrong and were: the `MBD/MWD/MLD/MDD` displacement is an **unsigned byte** in
the macro (`0xfe` means -2), and a displacement of **zero** still emits the
two-byte d8 prefix, which the backend spells with its `+256` sentinel.  Getting
either wrong produces mismatches that look like backend bugs and are not.
