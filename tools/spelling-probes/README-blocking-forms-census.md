# Census: what still blocks the v7 `.byte` -> instruction converter, in BYTES

`scripts/converters/convert_reachable_ranges.py` decodes a reachable range and
re-spells every instruction with llvm-mc, requiring the re-assembled bytes to
equal the ROM bytes. One instruction it cannot spell TRUNCATES the range there.
The question this pair of scripts answers is **what is still blocking, and which
fix is worth the most bytes** — so the next work is aimed rather than guessed.

| script | question it answers | command |
|---|---|---|
| `scripts/analysis/v7_blocking_forms_census.py` | Which instruction forms block conversion, how many sites and RANGES each, how many BYTES each would release, and is each one really code? | `python3 scripts/analysis/v7_blocking_forms_census.py` |
| … `--limit 40 --no-oracle` | smoke test, ~15 s | `python3 scripts/analysis/v7_blocking_forms_census.py --limit 40 --no-oracle` |
| … `--set 'NAME=form1;form2'` | What does ONE spelling rule that covers several forms buy, cumulatively? Repeatable, applied in the order given. | see "the seven rules" below |
| … `--explain 'FORM'` | WHERE one form's marginal bytes come from: every range it first-blocks, the cut today and after, and the exact blocking bytes. Repeatable. | `python3 scripts/analysis/v7_blocking_forms_census.py --top 0 --no-oracle --explain 'ld (r+imm),r'` |
| … `--json out.json` | machine-readable census: every form, its blocked byte-sequences with counts, its v9 verdict | `python3 scripts/analysis/v7_blocking_forms_census.py --json /tmp/c.json` |
| `tools/spelling-probes/verify_top_blocking_spellings.py` | Do the proposed spellings reproduce the ROM bytes at **every** site of their form, in all four ROMs? | `python3 tools/spelling-probes/verify_top_blocking_spellings.py` |
| … `--negative` | Can that check fail? Runs the spelling each rule replaces. | `python3 tools/spelling-probes/verify_top_blocking_spellings.py --negative` |
| `tools/spelling-probes/try_spelling.py` | Spot check: does ONE candidate text assemble to exactly these ROM bytes? Every spelling quoted below was found this way. | `python3 tools/spelling-probes/try_spelling.py 833d60 "xor (xhl), 0x60" "xormi8 (xhl), 0x60"` |

Signal read: raw bytes of `original_ROMs/kn5000_{v7,v9,v10}_program.rom` at load
base 0xE00000 and `kn5000_table_data.rom` at 0x200000, versus
`llvm-mc -triple=tlcs900 --show-encoding`. PASS = identical bytes. "Assembled
without error" is NOT a pass.

## Why not `convert_reachable_ranges.py --forms`

That counter records at most **one form per RANGE** — the converter stops at the
first unspellable instruction, so a range that also holds four of another form
attributes nothing to it. It undercounts, and it counts instances rather than
bytes. The census decodes every range to its full extent, collects every
unspellable instruction, and then re-runs the converter's own byte accounting
once per candidate form.

The two agree where they should: the census reproduces the converter's headline
figure, **12,930 B in 155 ranges**, exactly.

## Units — state them or the numbers lie

* **RANGE** — one reachable call target and the run decoded from it. The unit
  the converter converts or skips.
* **SITE** — one decoded INSTRUCTION occurrence that cannot be spelled. One
  range holds many.
* **BYTE** — a ROM byte that would move from `.byte` to an instruction. The
  ranking key. `marginal B` = bytes gained if THAT ONE form became spellable and
  nothing else changed. Marginals do **not** add up across forms (a range
  blocked by F then G gives its bytes to whichever is fixed first), which is why
  the greedy cumulative table and `--set` exist.

## Result, 2026-08-22, repo `a33b512`, llvm tlcs900_backend@cb165c5cdc4b

1,118 reachable call targets. 635 pass the converter's pre-spelling gates; 195
of those hold at least one unspellable instruction.

    164 ranges  decoded fewer than 3 instructions
    163 ranges  no `ret`, and does not end at a code boundary
    156 ranges  a branch target cannot be named

    31,342 B pass the SPELLING stage · 57,699 B if every form below were
    spellable · 26,357 B on the table for spelling work

### ★ The single biggest blocker is NOT a spelling — it is a broken gate

After spelling, the converter re-assembles the kept prefix as ONE block and
requires the bytes back. Replaying that gate:

    53 ranges    4,460 B  pass
   140 ranges    8,470 B  skipped (range has intra-range .Lc_ labels; gate not run)
   361 ranges   18,412 B  FIXUP  <-- cannot ever pass
    22 ranges        0 B  genuine byte mismatch
    59 ranges        0 B  n/a (range yields nothing anyway)
   ------------------------------
                12,930 B  actually reaches the source tree today

**18,412 B — seven times the whole top-five spelling list — sit behind a check
that cannot succeed.** A branch to an external symbol assembles to
`; encoding: [0x6e,A]`: the displacement is a placeholder the LINKER fills in.
`cc.encode_block` parses that `A` as 0x0A, so the byte comparison fails for any
block containing such a branch. The converter already knows this —
`resolve_branches` deliberately checks only the LENGTH of a symbolic branch, and
its docstring says the bytes "cannot be byte-matched here" — and then compares
the bytes anyway in the last gate. Reproduce with:

    printf 'ld a, 0x01\njr nz, SomeExternalSymbol\nret\n' | \
      llvm-mc --triple=tlcs900 --show-encoding

Fixing this is a converter change (exclude symbolic-branch bytes from that
comparison, as the per-instruction path already does), not a backend change, and
it is worth more than every spelling rule below combined.

### Ranked forms — marginal BYTES if that one form became spellable

`sites` = unspellable instruction occurrences · `1st` = ranges where it is the
first blocker · `ret/code` = how the containing ranges end.

| form | sites | 1st | marginal B | ret/code | is it CODE? |
|---|---:|---:|---:|---|---|
| `xor (r),imm` | 6 | 1 | 1,884 | 6/0 | YES 2/6 sites |
| `ld (r+r),r` | 38 | 11 | 946 | 13/25 | YES 37/38 |
| `lda r,r+r` | 22 | 8 | 878 | 12/10 | YES 22/22 |
| `ld (r+imm),r` | 16 | 3 | 799 | 16/0 | YES 16/16 |
| `cp (imm),r` | 18 | 10 | 732 | 10/8 | YES 11/18 |
| `cp r,(r+r)` | 3 | 1 | 664 | 3/0 | YES 3/3 |
| `bit 5,(r+r)` | 2 | 2 | 655 | 2/0 | YES 2/2 |
| `ld (r+imm),imm` | 20 | 8 | 543 | 16/4 | YES 19/20 |
| `pushw (r+imm)` | 13 | 5 | 487 | 3/10 | YES 13/13 |
| `or (r+imm),imm` | 3 | 3 | 481 | 2/1 | YES 2/3 |
| `dec 1,(imm)` | 8 | 5 | 428 | 5/3 | YES 2/8 |
| `incw 1,(r+imm)` | 3 | 2 | 371 | 2/1 | YES 3/3 |
| `ldw (imm),(imm)` | 8 | 5 | 289 | 2/6 | YES 7/8 |
| `cp (r+r),imm` | 3 | 2 | 269 | 3/0 | **no v9 hit** (0 of 2 byte-seqs) |
| `cp r,(imm)` | 31 | 16 | 258 | 5/26 | YES 3/31 |
| `ld r,(r+r)` | 9 | 7 | 253 | 4/5 | YES 7/9 |
| `cp (r+r),r` | 1 | 1 | 238 | 1/0 | YES 1/1 |
| `cp (imm),imm` | 3 | 3 | 192 | 0/3 | YES 3/3 |
| `push r` | 7 | 5 | 180 | 5/2 | YES 7/7 |
| `lda r,r+imm` | 2 | 1 | 166 | 0/2 | YES 2/2 |
| `ld (r+imm),(imm)` | 3 | 2 | 158 | 2/1 | **no v9 hit** (0 of 3) |
| `pushw (r)` | 5 | 2 | 154 | 3/2 | YES 5/5 |
| `add (imm),r` | 3 | 1 | 154 | 2/1 | YES 2/3 |
| `ld (r+),r` | 12 | 4 | 139 | 10/2 | YES 12/12 |
| `sla r,r` | 6 | 3 | 137 | 1/5 | YES 6/6 |

A big marginal from few sites is not a bug: one blocker early in a long range
holds the whole range. `xor (r),imm`'s 1,884 B is a single 707-instruction
range at 0xFAFB4D that ends in `ret`; blocked at instruction 134 it yields
**nothing** today, because truncating there also orphans a `.Lc_` branch label.
`--explain 'xor (r),imm'` prints exactly that, and `--explain 'ld (r+imm),r'`
prints the three ranges behind its 799 B (43 + 592 + 164).

Two entries elsewhere in the census carry a NEGATIVE marginal (`srl r,r` -90,
`bit 3,(r+r)` -20). That is real, not a rounding artefact: extending a range
past its current cut brings in branches whose `.Lc_` targets lie beyond the new
cut, and the converter refuses such a truncation outright.

### Is it code? — how the two checks work

* **v9-CODE.** The v9 sources rebuild byte-identical to the original ROM. Built
  with `llvm-mc -g`, the DWARF line table carries one row per emitting source
  STATEMENT — and `.byte` directives emit NO row. Verified directly:

      printf '\t.text\n\tnop\n\tnop\n\t.byte 0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88\n\t.byte 0x99,0xaa,0xbb,0xcc\n\tnop\n\tret\n' > /tmp/t.s
      llvm-mc -triple=tlcs900 -filetype=obj -g /tmp/t.s -o /tmp/t.o
      llvm-dwarfdump --debug-line /tmp/t.o     # rows at 0x0,0x1,0xe,0xf only

  So a row address is an instruction boundary in real, human-checked source.
  A blocked site is corroborated when its exact bytes occur in the v9 ROM at
  such an address **and no row falls strictly inside them** (so v9 does not
  express those bytes as two shorter instructions). 358,975 rows exist, and the
  check comes out positive 200+ times, so it can say yes.
  ⚠ Direction: a hit PROVES code. A miss proves nothing on its own — v9 is a
  different revision and is itself only ~48% expressed as instructions.
* **FRAMING.** `ret` = the decode ran from a proven call target to a return.
  `code` = it landed exactly on the first byte of territory the sources already
  express as instructions. Either means the whole decode is correctly framed.

## The seven rules worth writing next, and the evidence

`verify_top_blocking_spellings.py` runs each over every site of its form in v7,
v9, v10 and the table-data ROM: **35,252 byte-exact, 0 wrong**. The
`--negative` run of the spellings they replace is wrong **2,123 times in v7
alone**, so the check can fail.

Cumulative value at the spelling stage, from `v7_blocking_forms_census.py --set`
(the forms each rule covers are listed here; run them in this order):

    A <op>mi8          +2,471 B   xor (r),imm ; or (r),imm ; or (r+imm),imm ; add (r+imm),imm
    B st_rrb/stw_dri     +946 B   ld (r+r),r
    C lda_rr             +878 B   lda r,r+r
    D cpdm*              +732 B   cp (imm),r
    E pushm              +673 B   pushw (r+imm) ; pushw (r)
    F d8 = 0 sentinel    +799 B   ld (r+imm),r
    G incdi/decdi        +785 B   dec 1,(imm) ; inc 1,(imm) ; incw 1,(imm)
    --------------------------
    +7,284 B, taking the spelling stage from 31,342 B to 38,626 B of 57,699 B

**A — `<op> (mem),imm8` → `<op>mi8 <mem>, <imm>`** (add adc sub sbc and or xor).
`xor (XHL),0x60` = `83 3d 60` = `xormi8 (xhl), 0x60`. The spelling is not new:
the v9 sources already contain `xormi8 (xiz), 0x60` and `ormi8 (xwa + 2), 0xfe`.
Gate on the PREFIX byte 0x80..0x8F: `xor (XWA),0x43` is printed by both
`80 3d 43` and the extended form `c3 e0 3d 43`, and the probe caught exactly one
such site in `kn5000_table_data.rom` before the guard existed.

**B — `ld (r32+r16),src`** → `st_rrb src, base, idx` for a byte source;
`stw_dri`/`stl_dri src, 0x07, <base_byte>, <idx_byte>` for word and long.
`ld (XHL+IY),A` = `f3 07 ec f4 41` = `st_rrb a, xhl, iy`. The converter's
current candidate `stb_dri a, 0x07, 0xec, 0xf4` emits `…31`, a different
instruction (`lda XBC,XHL+IY`) — **`stb_dri` and `lda_dri` are swapped in
`TLCS900InstrInfo.td`**: SubOpc 0x30 is LDA and 0x40 is the byte store. ⚠ And
`st_rrw`/`st_rrl` LOOK right and are not: all three `st_rr*` defs carry SubOpc
0x40 and the 0xF3 prefix skips the OpSize adjustment, so they silently emit the
BYTE sub-opcode. Rule B's negative control is wrong at **every one** of v7's
454 sites.

**C — `lda r32,r32+r16` → `lda_rr rd, base, idx`.** `lda XHL,XDE+BC` =
`f3 07 e8 e4 33` = `lda_rr xhl, xde, bc`. 563 sites in v7, all byte-exact. The
converter today offers the parenthesised `lda xhl, (xde+bc)`, which assembles to
a 5-byte `f3 e9 0a 0a 32` — right length, wrong instruction.

**D — `cp (abs),reg`**, keyed on the PREFIX byte, which carries both widths:
`c1 -> cpdm8 <a16>, <r8>` · `c2 -> cpdm8_24` · `d1 -> cpdm16 <a16>, <XR>` ·
`d2 -> cpdm16_24` · `e1 -> cpdm32` · `e2 -> cpdm32_24`. ⚠ Note the 32-bit NAME
for a 16-bit register: the backend types that operand `GPR` and the
register-number field is identical, so `cp (0xf1ea),WA` = `d1 ea f1 f8` is
written `cpdm16 0xf1ea, xwa`. Writing `wa` is REJECTED (60 such sites in v7's
negative run). The 8-bit-address prefixes c0/d0/e0 have no mnemonic; the rule
declines them (278 sites in v7) and they stay `.byte`.

**E — `pushw (mem)` → `pushm <mem>`.** `pushw (XSP+0x28)` = `9f 28 04` =
`pushm (xsp + 0x28)`; `pushw (XIY)` = `95 04` = `pushm (xiy)`. The converter's
`pushw (xiy)` is rejected outright by llvm-mc.

**F — `ld (r32+d8),src` → `ld (<base> <signed d8>), <src>`.** 8,236 sites in v7,
all byte-exact. Its blocked sites are dominated by an explicit `d8 = 0x00`, and
those need the SENTINEL described below.

**G — `inc|dec n,(abs)` → `incdi8`/`decdi8` (prefix c1/c2) or
`incdi16`/`decdi16` (prefix d1/d2), `_24` for a 24-bit address.**
`dec 1,(0x0de7)` = `c1 e7 0d 69` = `decdi8 1, 0x0de7`. ⚠ `decdd8 1, 0x0de7`
looks like the same thing and emits `f1 e7 0d 69`, which unidasm reads back as
`db` — an INVALID encoding, not a synonym. Getting the width wrong is the
negative control: 391 wrong in v7.

## ⚠ RETRACTED in this same commit: "the zero-displacement hole"

An earlier draft of this file claimed that `d8 = 0x00` could not be spelled at
all — that `ld (xiy + 0), a` assembles to the shorter `b5 41` where the ROM has
`bd 00 41`, so `ld (r+imm),r` needed a backend change or the raw-byte escape
`extpfxN`. **That is wrong.** The backend already has a sentinel, put there for
exactly this purpose, in `TLCS900MCCodeEmitter.cpp`:

    // Sentinel: displacement of 256 means "force d8 form with displacement 0".
    // Used by the assembly converter to reproduce exact ROM encoding where
    // the original firmware used the 2-byte (Xrr+d8) prefix with d8=0x00
    // instead of the shorter 1-byte (Xrr) prefix.

So `ld (xiy + 256), a` = `bd 00 41`, `pushm (xsp + 256)` = `9f 00 04`,
`addmi8 (xde + 256), 0xd7` = `8a 00 38 d7`, `ld c, (xsp + 256)` = `8f 00 23`,
`ld (xsp + 256), 0x04` = `bf 00 00 04` — all verified. Writing `+ 0x00` instead
is the trap, and it is now rule F's negative control: 152 wrong in v7.

The lesson is the one this tree keeps re-learning: **grep the backend, then
assemble, before saying a form has no spelling.** Four such claims had already
been made and refuted here; this was the fifth.

The same sentinel unblocks the other `(r32+d8)` forms in the ranked table once
their own operand rules are written — `ld (r+imm),imm` (543 B, e.g.
`ld (xiz + 256), 0x90`) and `ld r,(r+imm)` (125 B, e.g. `ld c, (xsp + 256)`)
both assemble byte-exactly. Those two are not swept by the probe yet, so treat
them as spot-checked rather than verified — reproduce with

    python3 tools/spelling-probes/try_spelling.py be000090 "ld (xiz + 256), 0x90"
    python3 tools/spelling-probes/try_spelling.py 8f0023   "ld c, (xsp + 256)"

Likewise `cp (XBC+IZ),0x00` = `c3 07 e4 f8 3f 00` = `cpib_sri 0x07, 0xe4, 0xf8,
0x00`, quoted below as spellable, is a spot check of the same kind.

## What is genuinely NOT worth a spelling rule

* `cp (r+r),imm` (269 B) and `ld (r+imm),(imm)` (158 B) get **no v9
  corroboration at all** — 0 of 2 and 0 of 3 distinct byte-sequences occur at a
  v9 instruction boundary. `cp (r+r),imm` does have a spelling
  (`cpib_sri 0x07, 0xe4, 0xf8, 0x00`, verified), so the reason to skip it is the
  evidence, not the toolchain.
* `inc 1,(imm)` (129 B) is spellable via rule G but likewise gets 0 of 6, and
  every one of its ranges ends at a `code` boundary rather than a `ret`. Rule G
  is still worth writing for `dec 1,(imm)` (428 B) and `incw 1,(imm)`; just do
  not treat the `inc` half as proven.
* The backend's `GR16` class **excludes SP**, exactly as
  `README-inc_reg.md` records for `inc n, sp`. A 16-bit SP source has no
  register name to write, so rules B and F decline it. That costs **0 sites** in
  v7, v9 and v10 and 18 in the table-data ROM, all linear-scan noise.
* `extpfxN 0x.., 0x.., ..` assembles any literal byte string and would therefore
  "unlock" everything. It is `.byte` wearing a mnemonic, and using it as a
  general fallback would be the readability regression that got
  `convert_roundtrip_blocks.py` marked unsafe. Not recommended.
