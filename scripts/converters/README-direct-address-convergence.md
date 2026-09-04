# Direct-address syntax convergence — `convert_direct_address_family.py`

**The question it answers:** can the seventeen SYNTHETIC mnemonics of the
direct-address family — the ones that carry the address WIDTH and the operand
SIZE in the *name* — be respelled with the NATIVE mnemonic plus the width
annotation the assembler already supports, without changing one ROM byte?

    ldb_da  a, (0x120000)   ->   ld  a, (0x120000:24)
    stda16  61458, xwa      ->   ld  (61458:16), wa
    stdi16  4156, 0         ->   ldw (4156:16), 0
    cpdi16  10215, 48       ->   cpw (10215:16), 48
    bitda   6, (1278)       ->   bit 6, (1278:16)

This is section 8 of `notes/ASSESSMENT-syntax-convergence-2026-09-02.md`
(Option B), for the family that needs **no backend change at all**.

## The three scripts

| script | the question it answers |
|---|---|
| `convert_direct_address_family.py` | can this family be respelled with the native mnemonic plus a width annotation, site by site, without changing a byte? |
| `run_direct_address_convergence.sh` | **which native spelling does each synthetic name become** — the SPELL map — and does the tree still gate green one family at a time? |
| `verify_direct_address_convergence.py` | does the whole branch still encode identically under ONE named assembler, checked from git rather than from the converter? |

## The exact commands

    # dry run — reports, writes nothing
    python3 scripts/converters/convert_direct_address_family.py --all

    # one family, written
    python3 scripts/converters/convert_direct_address_family.py \
        --mnemonic stdi8 --apply

    # every family, each one gated and committed on its own
    scripts/converters/run_direct_address_convergence.sh /tmp/conv-out \
        stdi8 stda16 cpdi8 bitda ldw_da ldl_da stdi16 ldb_da stib_da \
        stw_da anddi8 stda32 stiw_da ordi8 cpdi16 stb_da ldda32

    # after the fact, with one pinned binary
    python3 scripts/converters/verify_direct_address_convergence.py \
        --base main --llvm-mc ~/compartilhado/toolchain-snapshot/llvm-mc.snap

    # and the byte gate itself
    make LLVM_MC=~/compartilhado/toolchain-snapshot/llvm-mc.snap gate gate-wsa1
    python3 scripts/analysis/assert_toolchain_is_a_prerequisite.py \
        --assembler ~/compartilhado/llvm-project/build/bin/llvm-mc --selftest

⚠ `make gate-all` bundles a third step, `assert_toolchain_is_a_prerequisite.py`,
whose assembler defaults to `ROOT.parent/llvm-project` — wrong when the tree is
a git worktree under `disasm-lanes/`. Run it separately with `--assembler`, as
above; it asserts a property of the Makefiles, not of any conversion.

⚠ Pin the assembler. The shared `llvm-project/build/bin/llvm-mc` was relinked
five times during this lane, always while `git log` said `7e541b8ddb07`, and
one of those links parsed `ld a, (0x120000:24)` while rejecting
`ldw (0xe0b4:16), 0`. A per-site check taken with one binary and a byte gate
taken with the next are two measurements, not one.


## The map — what each synthetic name becomes

The finding of this lane, in one table. `MAP` in
`convert_direct_address_family.py` is the machine-readable form and
`SPELL` in `run_direct_address_convergence.sh` the human one; both must agree
with this.

| synthetic | native spelling | address width | data size | sites |
|---|---|---:|---|---:|
| `stdi8`   | `ld (addr:16), imm8`   | 16 | 8  | 10,895 |
| `stda16`  | `ld (addr:16), r16`    | 16 | 16 |  7,764 |
| `cpdi8`   | `cp (addr:16), imm8`   | 16 | 8  |  5,191 |
| `ldda32`  | `ld r32, (addr:16)`    | 16 | 32 |  4,991 |
| `bitda`   | `bit n, (addr:16)`     | 16 | –  |  3,669 |
| `ldw_da`  | `ld r16, (addr:24)`    | 24 | 16 |  3,335 |
| `ldl_da`  | `ld r32, (addr:24)`    | 24 | 32 |  2,924 |
| `stdi16`  | `ldw (addr:16), imm16` | 16 | 16 |  2,652 |
| `ldb_da`  | `ld r8, (addr:24)`     | 24 | 8  |  2,425 |
| `stib_da` | `ld (addr:24), imm8`   | 24 | 8  |  1,967 |
| `stw_da`  | `ld (addr:24), r16`    | 24 | 16 |  1,829 |
| `anddi8`  | `and (addr:16), imm8`  | 16 | 8  |  1,791 |
| `stda32`  | `ld (addr:16), r32`    | 16 | 32 |  1,780 |
| `stiw_da` | `ldw (addr:24), imm16` | 24 | 16 |  1,300 |
| `ordi8`   | `or (addr:16), imm8`   | 16 | 8  |  1,279 |
| `cpdi16`  | `cpw (addr:16), imm16` | 16 | 16 |  1,119 |
| `stb_da`  | `ld (addr:24), r8`     | 24 | 8  |  1,116 |

⚠ The DATA size column is why `ld` alone is not always enough. Where the size
is 16 and the other operand is an immediate there is no register to carry it,
so the size stays in the mnemonic as `ldw` / `cpw` — this tree's existing
spelling, 22,574 and 3,251 sites before this lane. Where the other operand is
a register, the register name carries it, which is the rename described below.

## ⚠ The width is read off the MNEMONIC, never off the address

`TOOLCHAIN_VERSION` UPDATE 7: the address width is *requested* in the source
and is not derivable from the value. This firmware writes `set 7,(0x00008a)`
as `F2 8A 00 00 BF` — a 24-bit field for an address that fits in eight bits.
So the `width` column of `MAP` in the script is the width the mnemonic is
*defined* to emit in `TLCS900InstrInfo.td` (C0/D0/E0/F0 = 8, C1/D1/E1/F1 = 16,
C2/D2/E2/F2 = 24), not an inference from any number in the source.

## ⚠ Verification is PER SITE, not per family

Both spellings of every single line are assembled in isolation by `llvm-mc`
and their `-show-encoding` output — the encoding bytes **and** every relocation
fixup — must be identical before the line is written. A family-level byte gate
can be green while one site changed and another compensated. `make gate-all` is
still run after every family; it is the certification, this is the guard.

## The controls, without which the counts are worthless

A verifier that cannot go red has certified nothing.

    python3 scripts/converters/convert_direct_address_family.py --all --foil width

states the **other** address width (16<->24) at every site. Expected, and
measured on 2026-09-02 at `llvm-mc` sha256 `d338b73ef5232fc9`
(tlcs900_backend@6f456a19f05b):

    convert 0 / 56,027 · refuse 56,027
      BYTES-DIFFER 43,784 · new-does-not-assemble 12,237 · old-does-not-assemble 6

`--foil reg` leaves a 32-bit register name on a 16-bit form. It is the sharper
control because it must refuse *only* the sites that actually name a 32-bit
register, and pass the ones this tree already writes with a 16-bit name:

    --mnemonic stda16 --mnemonic stw_da --mnemonic ldw_da --foil reg
    convert 6,670 · refuse 6,258  (BYTES-DIFFER 6,252 + the 6 macro bodies)

and 6,252 is exactly the x-named site count from the operand census
(stda16 3,780 + ldw_da 1,520 + stw_da 952); the six `ldw_da` macro bodies are
the remainder, and they are x-named too but refused earlier for another reason.

## What the register rename is, and why it is not cosmetic

`stda16 (X), xwa` names a **32-bit** register for a **16-bit** store. The
sub-opcode is `0x50 + index`, so the operand is really WA. Encoding all eight
names in both spellings shows the mapping is index-preserving —
`xwa->wa xbc->bc xde->de xhl->hl xix->ix xiy->iy xiz->iz xsp->sp` — and this
tree already writes the 16-bit name at about half of those sites. On the 8-bit
forms a 32-bit name denotes the pair's **low byte** (`xwa->a`, corroborated by
the source's own comment at `hdae5000/hdae5000_hd_driver.s:403`); the four
pairs with no 8-bit half are refused rather than guessed. This is the same
class of defect as `TOOLCHAIN_VERSION` UPDATE 5's `stb_dri`: bytes right, name
wrong.

## What it refuses, and why

Six `ldw_da xwa, (\ParamC)` sites inside `.macro` bodies (v7/v9/v10
`display/scoop_display.s` and `factory_test/test_init.s`). A macro parameter
cannot be assembled in isolation, so the per-site guard cannot certify them and
they are left alone — which is also what this lane's brief requires.

---

# UPDATE 2026-09-04 (lane `w26/conv-alu`): the ALU-direct remainder

The same question, asked of the ninety-four synthetic direct-address mnemonics
the 2026-09-03 lane left behind — the ALU forms, the bit forms, inc/dec, and
`stl_da` / `cpib_da` / `cpw_da` / `jp_24` / `call_24` / `pushdi_24`.

**11,840 of 11,875 sites in 220 files converted; 35 refused.** Both byte gates
green after each of the ten families. Driver:
`scripts/converters/run_alu_direct_convergence.sh`.

## How the set was chosen — not by the name's shape

Every mnemonic in `TLCS900InstrInfo.td` whose `(ins ...)` list contains
`directaddr`, intersected with what the tree actually writes: **95 names,
11,881 sites** (`ldw_da`'s 6 macro bodies are one of them and were already
refused by the earlier lane). That is larger than the "9,748 sites over 66
names" the 2026-09-03 note predicted, which was read off the census by name
shape. Reading the OPERAND LIST rather than the name is what found the extra
29 — `jp_24`, `call_24`, `lda_24`, `pushdi_24`, `chgda_24` and the `_24`
siblings do not look like the others but take the same operand.

## The map — the finding

The address WIDTH is `AddrWidth` in the `.td` (0 => a 16-bit field, 1 => a
24-bit one), never an inference from the address value. The `w` suffix appears
only where there is no register operand to carry the 16-bit data size, exactly
as `ldw`/`cpw` above.

| shape | synthetic names | native spelling |
|---|---|---|
| ALU reg,(addr) | `addda8/16/32`, `subda8/16/32`, `sub32_24`, `andda*`, `orda*`, `xorda*`, `cpda8/16/32` (+ `_24`) | `add`/`sub`/`and`/`or`/`xor`/`cp` `r, (addr:16\|24)` |
| ALU (addr),reg | `adddm*`, `addl_da`, `subdm*`, `anddm*`, `orddm*`/`ordm*_24`, `xordm*`, `cpdm*` | same op, `(addr:16\|24), r` |
| ALU (addr),imm | `adddi8/16`, `subdi8/16`, `anddi8_24`/`anddi16`, `ordi8_24`/`ordi16`, `xordi8`, `cpib_da`, `cpw_da` (+ `_24`) | `add`/`addw`/… `(addr:16\|24), imm` |
| INC/DEC n,(addr) | `incdi8/16`, `decdi8/16` (+ `_24`) | `inc`/`incw`/`dec`/`decw` `n, (addr:16\|24)` |
| bit n,(addr) | `resda`, `setda`, `bitda_24` (+ `_24`) | `res`/`set`/`bit` `n, (addr:16\|24)` |
| store 32 | `stl_da` | `ld (addr:24), r32` |
| flow | `jp_24`, `call_24`, `pushdi_24` | `jp cc, (addr:24)`, `call cc, (addr:24)`, `pushw (addr:24)` |

## ★ THE BACKEND HAS TWO RULES FOR A 32-BIT NAME IN A NARROWER SLOT

The 2026-09-03 lane established that `ldb_da xwa` means **A**, the pair's LOW
BYTE, and mapped `xwa->a xbc->c xde->e xhl->l` accordingly. That is right —
**for the LD-direct class only.** Measured here, on the same assembler:

    ldb_da xbc, (0x120000)   ->  ...,0x23   LD base 0x20 + 3  =  C   low byte
    cpda8  xbc, (0x1000)     ->  ...,0xf1   CP base 0xf0 + 1  =  A   same index

The ALU-direct class encodes the x-name INDEX-PRESERVINGLY
(`xwa->w xbc->a xde->b xhl->c xix->d xiy->e xiz->h xsp->l`). Applying the
LD rule to the ALU forms produced 161 `BYTES-DIFFER` refusals and 17
`x-name-with-no-8bit-half`, and applying it *silently* would have been a wrong
register name at 2,379 sites.

**So the converter no longer asserts a rule.** `reg_candidates()` returns every
name of the right class — the rule-based guesses first, then the rest — and the
per-site check keeps the one whose encoding equals the line being replaced.
Each 8-bit name has a distinct sub-opcode, so at most one candidate can match:
a match is a MEASUREMENT of what the ROM byte says, not a guess. Which rule won
is counted and printed:

    no-register       5520      (the other operand is an immediate or a cc)
    as-written        3941      (already the right class)
    index-preserving  2379      (an x-name, resolved by the ALU rule)
    low-byte             0
    byte-search          0

★ **Byte-identity is per instruction CLASS, not per register file.** Two
conventions live in one backend. Measure the class you are converting; a rule
carried over from a neighbouring family is a guess wearing evidence's clothes.

## The controls

`--foil op` is new and is the sharp one for this lane: it substitutes a sibling
operation of the SAME encoding class (add<->sub, and<->or, cp->and, res<->set,
inc<->dec, jp<->call, bit->res), so the foil spelling always parses and must be
rejected on BYTES, not on a syntax error.

    --foil op      convert 0 / 11,875   BYTES-DIFFER 11,848 + 27 macro bodies
    --foil width   convert 0 / 11,875   BYTES-DIFFER 8,344, new-won't-assemble 3,504
    --foil reg     convert 9,461        BYTES-DIFFER 2,379

`--foil reg` is the one that must reject *some* and accept the rest: 2,379 is
exactly the number of sites the real run resolved by renaming a register, and
every one of the 9,461 that never needed a rename still passes.

## Refused: 35 sites, and why

* **27 × `lda_24 xwa, (\ParamB|\ParamD)`** — inside `.macro` bodies in v7/v9/v10
  `display/scoop_display.s` and `factory_test/test_init.s`. A macro parameter
  cannot be assembled in isolation, so the per-site guard cannot certify it.
  Same class as the six `ldw_da` bodies the earlier lane refused, in the same
  two files.
* **8 × `chgda_24 n, (0x160004)`** — `chg` has no memory-operand form in the
  backend at all: `chg 2, (0x160004)` is *invalid operand*, and
  `chg 2, (0x160004:24)` does not even parse. Only the synthetic `chgm`
  accepts it, and respelling one synthetic name as another is not convergence.
  ⚠ This wants a one-line `chg` -> `chgm` alias in `TLCS900InstrInfo.td`,
  which is a BACKEND change and out of this lane's scope.

## What did NOT reach a native name

861 of the 11,840 land on a size-suffixed name that unidasm's table does not
contain, so the census still calls them SYNTHETIC: `cpw` 442, `orw` 279,
`andw` 67, `addw` 55, `subw` 18. The address width did leave the mnemonic —
that is the conversion — but the DATA size cannot, because those forms have an
immediate on the other side and no register to carry it. This is the tree's
established `ldw`/`cpw` convention, not a new one.
