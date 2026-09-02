# lane LLVMENCAUDIT — the `Opcode < 0xF0` size-guard audit

**Verdict: the reported ST_RRW/ST_RRL collision is not real on the current
tree.** It was real once, and was fixed in
`llvm-project@1b9432474daa` ("[TLCS900] Fix two silently-wrong sub-opcodes in
the F3 memory forms", 2026-08-22 16:25:51 +0100) — eleven days before
`kn5000-roms-disasm/notes/DEBT-INVENTORY-2026-09-02.md` (item 6) described it
as an open, unresolved encoder bug. The debt-inventory entry is stale: it
documents the pre-fix shape of the source, not the tree it was committed
against. This lane could not correct that file directly (out of scope — main
checkouts of `kn5000-roms-disasm` are read-only for every lane), so this note
is the record; whoever owns `main` should retire/replace that entry.

## What was checked, and how

1. **`f0_guard_size_collision_audit.py`** — assembles `st_rrb`/`st_rrw`/
   `st_rrl` (the exact family named in the debt-inventory note) plus five
   sibling families that share the same shape (fixed prefix >= 0xF0, more
   than one `OpSize` variant): `ST_RR8*`, `ST_DD8*`, `ST_DRI3*`, `ST_DPI*`,
   `ST_DPD*`. Every one already carries a distinct trailing sub-opcode byte
   (`0x40`/`0x41`/`0x50`/`0x60` depending on register encoding) and none
   collides. `LD_RR*` is included as a negative control: its prefix is
   `0xC3` (< 0xF0), so the guard's `OpSize * 0x10` adjustment DOES apply and
   the size is carried in the prefix byte (`C3`/`D3`/`E3`) instead.
   `--selftest` re-injects a genuine collision (same instruction three times)
   to prove the "assert all distinct" check can actually go red, not just
   pass vacuously.

   ```
   python3 notes/llvmencaudit-audit/f0_guard_size_collision_audit.py
   python3 notes/llvmencaudit-audit/f0_guard_size_collision_audit.py --selftest
   ```

2. **`sri_rr_subopcode_rom_census.py`** — scans the KN5000 v10 program ROM
   and all four WSA1R PROM images for byte sequences shaped like
   `[F3, 0x07, base_addr, idx_addr, sub_opc]` (the SriRRReg encoding) and
   buckets by sub-opcode nibble. All four nibbles the fix relies on — LDA
   (0x30), STB (0x40), STW (0x50), STL (0x60) — occur, at frequencies that
   fall off monotonically (address computation commonest, 32-bit stores
   rarest), consistent with real code rather than noise. This corroborates
   the analogy the 2026-08-22 fix drew from the DRI3/DPI/DPD families; it is
   NOT independent proof that any single 0x50/0x60 hit really is
   `st_rrw`/`st_rrl`, because no SriRRReg decoder exists yet (nothing has
   round-tripped these bytes against semantically-labelled disassembly —
   see DEBT-INVENTORY item 5, which is the OTHER lane's territory, not
   this one's).

   ```
   python3 notes/llvmencaudit-audit/sri_rr_subopcode_rom_census.py
   ```

## Broader audit: every family the `Opcode < 0xF0` guard can affect

`TLCS900MCCodeEmitter.cpp` has 22 call sites of
`if (Opcode < 0xF0) Prefix += OpSize * 0x10;`, covering the formats
`ExtAddrModeSuffix`, `ExtAddrModeOpImm`, `ERPReg`, `ERPSmallImm`, `ERPUnary`,
`ERPImmAfter`, `PIReg`, `PIUnary`, `RIReg`, `SriD16Reg`, `SriRRReg`,
`SriRRImm`, `SriRRQReg`, `SriRR8Reg`, `SriRRUnary`, `RIUnary`, `RIImmAfter`,
`D8Reg`, `D8Unary`, `D8ImmAfter`, `ExtImmMod`, `RIImmMod`. Every `.td`
instantiation of these formats was enumerated (`grep` for each `*Inst<`
constructor plus every `let Opcode = 0xF... in { ... }` block) and grouped by
(format, literal Opcode). Findings:

* **`PIReg`/`PIUnary`** have ZERO instantiations anywhere in
  `TLCS900InstrInfo.td`. Dead formats — no encoder risk, nothing to fix.
* **Formats at a literal Opcode < 0xF0** (`ERPReg`/`ERPSmallImm`/`ERPUnary`/
  `ERPImmAfter` fixed at `0xC7`; `LD_RR*`/`LD_RR8*`/`LD_SRI*_D16` at `0xC3`;
  `PUSH_SD16*` at `0xC1`) get the `OpSize*0x10` prefix adjustment for free —
  not at risk by construction.
* **Every remaining family instantiated at a literal Opcode >= 0xF0 with
  more than one `OpSize` variant already spells its sub-opcode out per size**
  — `ST_RR*`/`LDA_RR` (F3, 0x30/0x40/0x50/0x60), `ST_RR8*` (F3, same),
  `ST_DD8*`/`LDA_DD8L` (F0, same), `ST_DRI3*`/`LDA_DRI3` (F3, same),
  `ST_DPI*`/`LDA_DPI`/`POPB_DPI`/`POPW_DPI` (F5), `ST_DPD*`/`LDA_DPD`/
  `POPB_DPD`/`POPW_DPD` (F4), `POPB_DD8`/`POPW_DD8` (F0),
  `STCFA_DD16`/`POPB_DD16`/`POPW_DD16` (F1), `LDMMB_DD24`/`LDMMW_DD24` (F2).
  Bit-test/branch families at >=0xF0 (`RES`/`SET`/`BIT`/`CHG`/`LDCF`/`TSET`/
  `STCF`/`JP`/`CALL` variants across `DD8`/`DD16`/`DRI`) have no OpSize
  variance to begin with (a bit test is not sized), so the guard is moot for
  them.
* No family was found still sharing a sub-opcode across two OpSize variants
  under a >=0xF0 prefix. **Nothing left to fix under this defect class.**

## Gate

Ran in this worktree (`~/compartilhado/disasm-lanes/llvmencaudit`,
`w3/llvmencaudit`) with no source changes to `llvm-project` (the bug this
lane was sent to find and fix was already fixed before this lane started):

```
make all        # 100.00% romset bytematch, all 9 KN5000 images
make gate       # PASS: assemble + byte-identical, 9/9 KN5000
make wsa1       # builds all 4 WSA1R images
make gate-wsa1  # PASS: byte-identical, 4/4 WSA1R
```

llvm-mc binary: `~/compartilhado/llvm-project/build/bin/llvm-mc`,
built 2026-09-02 01:03 (after tlcs900_backend HEAD `ad8129f59880`, committed
2026-09-02 00:56:01 +0100 — the binary reflects the checked-out source).
`cd ~/compartilhado/llvm-project/build && ninja llvm-mc` reported
`ninja: no work to do`, confirming the binary was already current.

LLVM: tlcs900_backend@ad8129f59880c0 (ad8129f59880c0fac8b20cc40f2e46aa950f4a1f)
