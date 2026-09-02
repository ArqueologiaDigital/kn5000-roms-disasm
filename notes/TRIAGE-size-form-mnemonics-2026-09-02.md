# The size/form mnemonics: which are spellings, which are form selectors

**Lane `w16/conv-size`, 2026-09-02.** Executing the internal-convergence
decision in `notes/ASSESSMENT-syntax-convergence-2026-09-02.md` §8 for the
eleven mnemonics whose name may be selecting an *encoding* rather than a
*spelling* — the assessment's §1.2 class 2.

Everything below is produced by
`notes/syntax-convergence-probes/size_family_convert.py`; the triage table is
literally its `--triage` output, and each conversion was verified site by site
with `--family <name>` before a byte was written.

## The verdicts

Of **88,141 sites** in this lane, **6,526 (7.4%) are pure spellings and are
converted**; **3,251 need no conversion at all**; **78,364 are genuine form
selectors and are refused**, with three backend features named below that would
retire all of them.

| mnemonic | sites | files | native spelling tried | old bytes | new bytes | verdict |
|---|---:|---:|---|---|---|---|
| `incm`    |  1,535 | 120 | `incw 1, (xsp+4)`       | `9f 04 61` | `9f 04 61` | **(a) CONVERTED** |
| `ldda32`  |  4,991 | 104 | `ld xwa, (4160:16)`     | `e1 40 10 20` | `e1 40 10 20` | **(a) CONVERTED** |
| `cpw`     |  3,251 | 154 | `cp (xsp+6), 0`         | `9f 06 3f 00 00` | `8f 06 3f 00` | **already native — keep** |
| `cps`     | 19,261 | 247 | `cp a, 4`               | `c9 dc` | `c9 cf 04` | (b) refused — feature A |
| `lds`     | 18,564 | 222 | `ld hl, 0`              | `db a8` | `db 03 00 00` | (b) refused — feature A |
| `lds32`   | 14,239 | 180 | `ld xiz, 0`             | `ee a8` | `46 00 00 00 00` | (b) refused — feature A |
| `ldb`     | 16,138 | 212 | `ld d, 0x4`             | `24 04` | `cc 03 04` | (b) refused — feature B |
| `ldio`    |  2,354 | 104 | `ld (0x07:8), 0xFF`     | `08 07 ff` | `f0 07 00 ff` | (b) refused — feature B |
| `ldwio`   |  1,111 |  76 | `ldw (237:8), 0x8e00`   | `0a ed 00 8e` | `f0 ed 02 00 8e` | (b) refused — feature B |
| `stb_erp` |  4,471 | 126 | `ld (0xFB), a`          | `c7 fb 89` | `f2 fb 00 00 41` | (b) refused — feature C |
| `ldb_erp` |  2,226 | 121 | `ld a, (0xFB)`          | `c7 fb 99` | `c2 fb 00 00 21` | (b) refused — feature C |

Site and file counts are the assessment's census
(`out/mnemonic_census.csv`), i.e. the state *before* this lane ran; `incm` and
`ldda32` are now zero. Reproduce the byte columns with

    python3 notes/syntax-convergence-probes/size_family_convert.py --triage

and the transcript of the run these numbers come from, with its toolchain
commit and `llvm-mc` sha256, is `out/SIZE-FAMILY-RUN.log`.

### ⚠ Nothing here is a matter of taste

Every "refused" row above is a line that **assembles cleanly under the native
spelling and emits different bytes**. That is the silent-failure class §3 of the
assessment measured at 246,857 sites for unidasm's notation, reappearing inside
our own. A plain `sed s/cps/cp/` over 247 files would have produced 19,261 wrong
instructions and a red gate with no clue as to which of them was at fault.

## The two conversions, and why they are safe

**`incm` → `incw`** (1,535 sites, 120 files). `incm` was never an instruction:
`TLCS900InstrInfo.td:5670` defines it as an `InstAlias` of `INC16m`, whose own
`AsmString` is `incw`. The two spellings are therefore the *same definition* and
cannot differ in bytes. `incw` is also in unidasm's vocabulary
(`dasm900.cpp` `s_mnemonic[]`), so this converges with the oracle as well as
internally.

⚠ The trap next door: `incm` → **`inc`** matches `INC8m` and emits `8f 04 61`
instead of `9f 04 61` — a one-nibble difference and an 8-bit read-modify-write
where the ROM does a 16-bit one. The size suffix on a memory operand is load
bearing, because a memory operand carries no size of its own.

**`ldda32 xwa, 4160` → `ld xwa, (4160:16)`** (4,991 sites, 104 files). This is
the UPDATE 7 address-width annotation doing exactly what it was built for: the
mnemonic's `d`+`a`+`32` was saying "direct address, 16-bit field, 32-bit
operand", and all three now live in the operand — the width in `:16`, the
operand size in the register `xwa`. All 4,991 operands are plain numeric
literals (no symbols), verified before the rewrite.

## ⚠ The conversions are half a fix: the PRINTER still emits the old names

    $ echo '0x9f,0x04,0x61'      | llvm-mc -triple=tlcs900 -disassemble
            incm    1, (xsp+4)
    $ echo '0xe1,0x40,0x10,0x20' | llvm-mc -triple=tlcs900 -disassemble
            ldda32  xwa, (4160)

The sources now say `incw` and `ld …, (…:16)`; the disassembler still says
`incm` and `ldda32`. Nothing is wrong today — the byte gate is a statement about
the assembler — but **any region disassembled from here on reintroduces the
spellings this lane just retired**, and the tree grows by disassembly.

Two small backend changes finish it, and neither can move a byte:

* `incm`: `INC16m`'s own `AsmString` is already `incw`; the `InstAlias` at
  `TLCS900InstrInfo.td:5670` is what gets *printed*. Giving that alias a zero
  emit priority keeps it parseable and stops it printing.
* `ldda32`: `LD32_da16` needs `AsmString` `ld` and the decoder needs to set
  `AddrBytes = 2` on the operand, so the printer emits the `:16` it already
  knows how to print (`ld xwa, (4160:16)` round-trips today when *written*).

## `cpw` needs nothing — the census misclassified it

`cpw` is flagged SYNTHETIC in `out/mnemonic_census.csv` only because unidasm has
no such name; unidasm prints plain `cp` for the word-sized memory compare, which
is one of the ambiguities the assessment lists in §3.1 (`mul BC,(XIZ+0x08)`,
"operand SIZE not printed"). But `cpw` is the `AsmString` of `CP16mi` itself,
not an alias, and the `w` suffix is Toshiba's own convention for word memory
operations — `incw`, `decw`, `ldw`, `slaw`, `cpiw` are all in unidasm's list.
**Here the tree's notation is the more precise of the two.** `cp (xsp+6), 0`
already means the 8-bit form and emits `8f 06 3f 00`.

★ The general point: *"unidasm does not have this name" is not the same as
"this name is synthetic".* The census answers the first question, which was the
right one for the unidasm question, and the wrong one for this lane.

## The three backend features that would retire the other 78,364 sites

### Feature A — an immediate **field width**, exactly parallel to `(addr:16)`

Covers `cps` + `lds` + `lds32` = **52,064 sites in up to 247 files.**

The short form puts the immediate in the **3-bit sub-opcode field**
(`prefix+r, 0xA8+imm` for LD, `prefix+r, 0xD8+imm` for CP); the long form uses a
trailing 8/16/32-bit immediate. That is a *field width*, the same kind of fact
`(0x2075:16)` already states for direct addresses, and it is not recoverable
from the value:

    cp a, 4:3     ->  c9 dc            (today: cps a, 4)
    cp a, 4:8     ->  c9 cf 04         (today: cp a, 4)
    ld hl, 0:3    ->  db a8            (today: lds hl, 0)
    ld hl, 0:16   ->  db 03 00 00      (today: ld hl, 0)
    ld xiz, 0:3   ->  ee a8            (today: lds32 xiz, 0)

Note that this also retires `lds8`/`lds`/`lds32` as three names for one
operation: the operand size is already carried by the register class, exactly as
`cps` already carries all three sizes under one name. (Today `lds xiz, 0` is
rejected outright — `invalid operand for instruction` — so the three names are
not interchangeable and no source-only merge is available.)

**Where it goes:** `AsmParser/TLCS900AsmParser.cpp:468` already parses `:8`/
`:16`/`:24` after an expression, but only inside `(...)` in
`parseMemoryOperand`, storing it in `MemOp::AddrBytes`. Feature A is the same
lexing at the immediate-operand site, a `k_Immediate` width field, and
`isImm3Field`-style predicates so the matcher can choose.

⚠ **The default must stay the long form, and this is measured, not assumed.**
The tree contains **2,658 `cp Xrr, n` sites and 53 `ld Xrr, n` sites whose
immediate is 0–7 and which nevertheless use the long encoding** (e.g.
`v10/maincpu/file_io/single_load.s:361` `cp xwa, 5` = 6 bytes). An assembler
rule of "pick the short form when the immediate fits" would silently rewrite
every one of them.

### Feature B — a way to name the **alternative shorter encoding**

Covers `ldb` + `ldio` + `ldwio` = **19,603 sites in up to 212 files.**

These three cannot use feature A, because both of their encodings carry an
immediate of the *same* width; they differ in the shape of the opcode:

| today | bytes | native spelling | bytes |
|---|---|---|---|
| `ldb d, 4` | `24 04` — one-byte opcode `0x20+r`, imm8 | `ld d, 4` | `cc 03 04` — prefix `C8+r`, sub-op `0x03`, imm8 |
| `ldio 0x07, 0xFF` | `08 07 ff` — dedicated `LD (n),n` opcode | `ld (0x07:8), 0xFF` | `f0 07 00 ff` |
| `ldwio 237, 0x8e00` | `0a ed 00 8e` | `ldw (237:8), 0x8e00` | `f0 ed 02 00 8e` |

Proposal: a suffix on the immediate that names the *encoding*, not a width —
`ld d, 4:s`, `ld (0x07:8), 0xFF:s`, `ldw (237:8), 0x8e00:s`. Each of the six
families in this lane has **exactly two** legal encodings, so "the other one" is
unambiguous today; the same `:s` would then also cover feature A's three and the
parser change would be one piece of work for **71,667 sites**.

⚠ **Do not define `:s` as "the shortest".** That is a derived property: the day a
third encoding is added, every existing `:s` silently means something else.
Define it as an explicit per-instruction alternative recorded in the `.td`, so
adding an encoding is a compile-time decision rather than a silent one.

### Feature C — a `PrevGR8` register class for the C7-prefix byte forms

Covers `stb_erp` + `ldb_erp` = **6,697 sites in up to 126 files.**

`stb_erp a, 0xFB` = `c7 fb 89` is `ld <byte register 0xFB>, a`, where `0xFB` is
a Toshiba *register code byte*, not an address — the `.td` comment at
`TLCS900InstrInfo.td:5320` reads it as `QIZH`. The operand is currently an
`i32imm` raw byte, which is why no rename reaches it: there is no register to
name. `PrevGR16` (QWA–QSP) already exists at
`TLCS900RegisterInfo.td:129` for the D7-prefix word forms; the 8-bit
counterpart was never defined.

**Scope, measured:** `stb_erp` uses **42** distinct bank codes and `ldb_erp`
**45**, concentrated in `0xE0–0xFF` (`0xFB` alone is 2,717 of the 6,697 sites)
with a tail at `0x3c`/`0x60`. So the class needed is bounded and small, and the
conversion afterwards is a code→name table, not a guess. Until then this is
assessment §1.2 class 3 and Option C applies: leave it alone.

⚠ The sources spell these operands inconsistently — `0xFB`, `0xfb` and `251`
all appear for the same register, as do `A` and `a` for the register. Whoever
implements feature C gets the normalisation for free by naming the register.

## The same problem one level down: the `(Xrr+256)` sentinel

Met while foil-testing this lane's rewrites, and worth recording because it is
**the identical design question already answered a different way, today, by
another lane** — and the two answers should not stay different.

`(xix)` is `94 60`, two bytes. `(xix+0x00)` is `9c 60`… no: it is `9c 00 60`,
three bytes, with the displacement field present and zero. Two encodings, and
before 2026-09-02 they printed the same text, so a disassembled 3-byte form
re-assembled as the 2-byte one. `TLCS900MCCodeEmitter.cpp:283` and
`TLCS900Disassembler.cpp:747` fix that (llvm-project `63ff7d92fb5f`) with a
**sentinel**:

    // Sentinel: displacement of 256 means "force d8 form with displacement 0".

It works, the round trip is injective again, and
`scripts/analysis/census_rid8_zero_disp.py` is the lane converting the old
forced `*_rid8` mnemonics onto it. **1,132 sites in this tree already carry the
sentinel** — measured by
`size_family_convert.py --sentinel`, which matches on the *value*, because the
tree spells it `256` (931), `0x0100` (200) and `0x100` (1) and a text match
undercounts by 201.

The observation this lane adds is only this: a form selector is being spelled as
a **magic number** in the operand where every other form selector in this
backend is spelled as a `:width` annotation on the operand, and the source text
now says a displacement of 256 where the hardware does 0 — the independent
oracle reads the same bytes the other way:

    $ printf '\x9c\x00\x60' | unidasm - -arch tlcs900
    0: 9c 00 60  incw 0,(XIX+0x00)

Feature A's parser change would cover this case for free: `(xix+0:8)` says
"displacement field present, width 8, value 0" in the same idiom as
`(0x2075:16)`, after which the sentinel can be deleted and `+256` made an error.
Worth raising with the lane that owns the sentinel **before** its 1,132 sites
grow further, because unwinding a magic number costs more than not introducing
one.

## What was NOT done, and why

* No backend change. This lane edited sources only; every feature above is
  described for the backend lane to implement and encoding-test.
* No conversion whose bytes moved. Two families converted, nine refused, and
  the refusals are the more useful half of the output.

## Gate

`make gate-all` in this lane's worktree, after each family separately:

| after | KN5000 byte-identical | WSA1R byte-identical | assembling |
|---|---|---|---|
| baseline (`a6507fdd`, nothing changed) | 9/9 | 4/4 | 8/8 |
| `incm` → `incw` | 9/9 | 4/4 | 8/8 |
| `ldda32` → `ld …, (…:16)` | 9/9 | 4/4 | 8/8 |

**And the gate was shown able to fail on these lines, twice**, because a green
gate that was never made red certifies nothing:

* one converted `incw 1, (xde - 2)` in `v10/maincpu/boot/system_handlers.s`
  changed back to `inc` → `kn5000_v10_program  1 BYTES DIFFER`, `FAIL: 1
  target(s) differ`;
* one converted `ld xwa, (1498:16)` in the same file changed to `:24` → the
  extra byte desynchronises the image and `v10/maincpu/storage/fdc_routines.s`
  fails outright with `invalid .org offset '1670541' (at offset '1670543')`.

Both were restored and the gate re-run green before committing.

⚠ **The shared `llvm-mc` was re-linked at least four times during this lane**
(sha256 `d338b73ef5232fc9` → `4356ff9f56a1ee37` → `40e0268cfa11f05c` →
`52563be155f9bfaf`), all at llvm-project commit `7e541b8ddb07`. Every number
here was re-derived at the last of those; the per-site verification of each
family was run with the same binary that then built its gate. Other lanes'
in-flight measurements from earlier tonight may not have been.
