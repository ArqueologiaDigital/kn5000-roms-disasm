# Syntax convergence: retiring synthetic mnemonics for native LLVM ones

These scripts execute **Option B** of
`notes/ASSESSMENT-syntax-convergence-2026-09-02.md`: retire the synthetic
mnemonics that carry an operand *form* in their name, in favour of the native
LLVM mnemonic with the form carried in the **operand**.

    ldb_d8  a, (0x2877)   ->   ld  a, (0x2877:16)

Nothing here is a textual find-and-replace. Every rewrite is proved
instruction-by-instruction by assembling the old and the new spelling and
requiring the same encoding — bytes *and* fixups — before a byte is written.
The ROM byte gate (`make gate-all`) is the certification; the per-site check
exists so a family-level pass cannot hide a compensating pair of errors.

## `converge_direct_addr.py`

**Question it answers:** which sites of the direct-address and
register-plus-displacement families can be spelled with the native mnemonic
without changing one ROM byte, and exactly which cannot and why?

Families it knows (`--family <name>`, or `all`):

| synthetic | native target | what the instruction is |
|---|---|---|
| `ldb_d8`  | `ld  r8,  (addr:16)`  | 8-bit load, 16-bit direct address |
| `ldw_d16` | `ld  r16, (addr:16)`  | 16-bit load, 16-bit direct address |
| `stb_d8`  | `ld  (addr:16), r8`   | 8-bit store, 16-bit direct address |
| `lda_d16` | `lda r32, (addr:16)`  | LDA of a 16-bit direct address |
| `lda_24`  | `lda r32, (addr:24)`  | LDA of a 24-bit direct address |
| `ld_sril` | `ld  r32, (Xrr+d16)`  | 32-bit load, base register + d16 |

⚠ The **register spelling changes too**, and that is why the rewrite may not
be inferred from the suffix. `ldw_d16 xwa, (0x28af)` is a *16-bit* operation
written with a 32-bit register name; the native form is `ld wa, (0x28af:16)`.
Spelled `ld xwa, (0x28af:16)` it assembles to `e1 …` — a 32-bit load, the
wrong instruction and the wrong bytes. The script generates the sub-register
candidate *and* the original spelling and lets the assembler pick.

Exact commands, from the tree root:

    # census + per-site verification, writes nothing:
    python3 scripts/convergence/converge_direct_addr.py --family lda_24 \
        --refusals out/refusals.csv

    # the same, then rewrite only the verified sites:
    python3 scripts/convergence/converge_direct_addr.py --family lda_24 --apply

    make gate-all      # 13/13 byte-identical is the certification

⚠ **Pin the assembler, and pin the SAME one for both steps.** The shared
`llvm-mc` is rebuilt in place by backend lanes — it was re-linked at least five
times on 2026-09-02 while `git log` in `llvm-project` never moved off
`7e541b8ddb07`, because the changes were uncommitted. A per-site comparison
taken with one binary and a gate taken with another certify nothing together.
Use the coordinator's snapshot for both:

    SNAP=~/compartilhado/toolchain-snapshot/llvm-mc.snap
    python3 scripts/convergence/converge_direct_addr.py --family lda_24 --mc $SNAP
    make LLVM_MC=$SNAP gate-all

This is not a theoretical hazard here: a full gate on the finished `ld_sril`
conversion failed with `invalid .org offset` in `fdc_routines.s` under the
shared binary and passed 13/13 on the same sources under a pinned one.

## What it refuses, and why the refusal is right

* **`ld_sril` with displacement `0x0100`** — 189 sites, and the only refusal
  left. The value 256 is a **sentinel** in
  `TLCS900MCCodeEmitter.cpp:287`: on the native `ld`'s memory operand it
  means *"emit the 2-byte (Xrr+d8) form with a displacement of zero"*, not
  *"displace by 256"*. `ld_sril`'s own encoder has no such sentinel, so the
  identical operand text denotes two different encodings under the two
  mnemonics — `e3 e5 00 01 23` versus `a9 00 23`. Until the native operand
  syntax gains a way to request the long form, these sites must keep their
  synthetic mnemonic. (65536 is a second sentinel, same shape, unused here.)
* **`.macro` bodies** are never touched — a different lane owns those, and a
  macro parameter cannot be assembled in isolation to prove anything.
