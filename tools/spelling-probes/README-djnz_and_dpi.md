# `djnz r,imm` and `ld (r+),r` — spelling rules, with the bytes

Two forms from `convert_reachable_ranges.py --forms` (3 blocking sites each, out
of 88 blocking instances at the 2026-08-23 fixpoint).  Both are spellable today.
Neither is a missing backend instruction.

## Scripts

| script | question it answers | run |
|---|---|---|
| `verify_djnz_and_dpi.py` | Does the proposed spelling assemble to **exactly** the ROM bytes at every site of the two forms — 7 `djnz`, 16 `ld (r+),r`? | `python3 tools/spelling-probes/verify_djnz_and_dpi.py` |
| `measure_djnz_dpi_gain.py` | What do the two rules unblock, in ranges and bytes, measured with the converter's own accept loop? | `python3 tools/spelling-probes/measure_djnz_dpi_gain.py` |

Signal read: `original_ROMs/kn5000_v7_program.rom` at `addr - 0xE00000`, 3 bytes
per site.  PASS = llvm-mc's bytes are identical to the ROM's.  Both scripts exit
non-zero if any site has no byte-exact spelling or a negative control matches.

Measured 2026-08-23 (llvm-mc from `~/compartilhado/llvm-project/build`):
**23/23 sites byte-exact, 21/21 negative controls correctly fail.**
Baseline replay reproduces the committed converter exactly (77 ranges / 5,880 B
/ 799 B truncation / 610 skipped); with the two rules, **82 ranges / 6,336 B**,
i.e. **+5 ranges, +456 bytes**, and 5 fewer ranges lost to
`truncation would orphan a branch label`.

## Rule 1 — `djnz` is a BRANCH and `resolve_branches` does not know it

`BRANCH_RE` in `convert_reachable_ranges.py` matches only `jr|jrl|calr`, so a
`djnz` falls through to the per-instruction candidate loop, which offers the
NUMERIC target.  llvm-mc then takes the **low byte of the address** as the
displacement — the identical silent-wrong behaviour the module docstring already
records for `jr nz, 0xef1371`:

```
djnz16 bc, 0xef8480   ->  d9 1c 80      ROM at 0xEF8484 holds d9 1c f9
```

So the fix belongs in `resolve_branches`, not in `translate()`; cause **(d), an
existing rule too narrow**.  Two traps in extending it:

* the second capture group of `BRANCH_RE` is a **condition code** for jr/jrl/calr
  but a **register** for djnz;
* the mnemonic carries the **operand width**.  Plain `djnz` takes a 32-bit GPR
  (it still emits the D8 16-bit prefix), so `djnz bc, L` is rejected with
  *invalid operand for instruction*.  A printed 16-bit name needs `djnz16`, an
  8-bit name `djnz8`.

Register codes in the backend match the hardware r-field digit for digit
(W/A/B/C/D/E/H/L = 0..7, WA/BC/DE/HL/IX/IY/IZ/SP = 0..7), so the printed name is
written as-is once the mnemonic is right.

## Rule 2 — `ld (r+),r` is destination post-increment (F5), and has no rule at all

`[F5, base_reg_byte, SubOpc + reg_code]`.  The base byte is the 32-bit
register's byte plus the increment size minus one — `XWA=0xE0 XBC=0xE4 XDE=0xE8
XHL=0xEC XIX=0xF0 XIY=0xF4 XIZ=0xF8 XSP=0xFC`, `+0` byte / `+1` word / `+3` long
— and the sub-opcode is `0x40` (byte) / `0x50` (word) / `0x60` (long) plus the
register code.  `translate()` has no rule for this shape at all: cause **(a), a
spelling not tried**.

The 16-bit and 32-bit stores have correctly-named defs (`stw_dpi`, `stl_dpi`).

⚠ **The 8-bit store does not.**  The F5 block of `TLCS900InstrInfo.td` still
carries the LDA/byte-store swap that was fixed for the F3 (DRI) block in
`tlcs900_backend 1b9432474daa`: `stb_dpi` sits on SubOpc `0x30`, which the
hardware uses for `lda`, and `lda_dpi` sits on `0x40`, the byte store.  unidasm
settles it — `f5 ec 30` is `lda XWA,XHL+`, `f5 ec 41` is `ld (XHL+),A`.  So the
spelling that emits the right bytes **today** is

```
lda_dpi <GPR whose code equals the 8-bit register's code>, <base byte>
```

e.g. `ld (XHL+),A` = `f5 ec 41` = `lda_dpi xbc, 0xec` (A's code is 1, and XBC is
the GPR with code 1).  `dpi_spellings()` emits both that and the semantically
correct `stb_dpi a, 0xec`, so the byte comparison picks — and the rule keeps
working unchanged once the backend is fixed.

The same swap is present in the F4 (pre-decrement) block: `f4 ec 30` is
`lda XWA,-XHL` while the backend names `st_dpdb` there, and `f4 ec 40` is
`ld (-XHL),W` while the backend names `lda_dpd`.
