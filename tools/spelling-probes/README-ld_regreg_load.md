# Probe: llvm-mc spelling for the unidasm form `ld r,(r32+r)`

Example the search started from: `ld W,(XIY+A)` at v7 `0xF54C3A`,
ROM bytes `c3 03 f4 e0 20`. In context it is an ordinary table lookup:

```
f54c32: 3d              push XIY
f54c33: c9 88           ld W,A
f54c35: 45 42 61 e4 00  ld XIY,0x00e46142
f54c3a: c3 03 f4 e0 20  ld W,(XIY+A)      <-- the form
f54c3f: c8 a1           sub A,W
f54c41: 5d              pop XIY
```

| script | question it answers | command |
|---|---|---|
| `verify_ld_regreg_load.py` | Which llvm-mc spelling encodes to the ROM bytes of *every* `ld <reg>,(<r32>+<reg>)` site in the KN5000 / HD-AE5000 images? | `python3 tools/spelling-probes/verify_ld_regreg_load.py` |
| `blocked_ld_regreg_load.py` | Which sites of that form still block the converter, and why exactly? | `python3 tools/spelling-probes/blocked_ld_regreg_load.py --ranges` |

**Signal read:** the five raw bytes of each instruction, re-read from the ROM
image at the harvested address (not merely copied out of the listing text).
PASS = `llvm-mc -triple=tlcs900 --show-encoding` emits exactly those bytes.
"Assembled without error" is NOT a pass — see the danger list below.

## The spelling (a function of the raw bytes, not of the printed text)

```
<P> <m> <base> <index> <sub>        always five bytes

P   = 0xC3 -> ldb_dri     destination is an  8-bit register
      0xD3 -> ldw_dri     destination is a  16-bit register
      0xE3 -> ldl_dri     destination is a  32-bit register
m   = 0x03 -> the index byte names an  8-bit register   ->  prints `(XIY+A)`
      0x07 -> the index byte names a  16-bit register   ->  prints `(XIX+HL)`
sub = 0x20|r ,  r = sub & 7  -> which register is loaded

spelling  =  "<mnemonic> <REG[r]>, 0x<m>, 0x<base>, 0x<index>"

R8  = w  a  b  c  d  e  h  l
R16 = wa bc de hl ix iy iz (sp)
R32 = xwa xbc xde xhl xix xiy xiz xsp
```

`base` and `index` **pass through verbatim as immediates** and are never
decoded, which is what makes odd index bytes spellable at all: v7 `0xFF1BCB`
holds `c3 07 e0 fa 21`, printed `ld A,(XWA+QIZ)` — a previous-bank register
that no name table in this tree carries.

Only the DESTINATION needs a table, and its width comes from the **prefix**.

## ⚠ The mode byte is not always 0x07

477 of the 7,164 instances use mode `0x03`. The printed text cannot be used to
recover it with a single table: `(XHL+A)` is mode `0x03` index `0xE0` and
`(XHL+WA)` is mode `0x07` index `0xE0` — same index byte, different mode.
`scripts/converters/convert_corroborated_blocks.py::translate()` hardcodes
`0x07` and looks the base/index up by printed NAME, so every mode-`0x03` site
fails today. Taking `m`, `base` and `index` straight from the bytes removes the
table and the failure together.

## Dangerous candidates — these ASSEMBLE and are WRONG

ROM reference: `c3 03 ec e0 21` = `ld A,(XHL+A)` at v7 `0xEFC898`.

| spelling | emits | why it is wrong |
|---|---|---|
| `ld A,(XHL+A)` (unidasm's own text) | `c3 ed A A 21` | the `(XHL+d16)` mode, `A` parsed as an undefined **symbol** with a 2-byte relocation. Five bytes, right length, no diagnostic |
| `ld W,(XIY+A)` | `c3 f5 A A 20` | same trap |
| `ldb_dri a, 0x07, 0xec, 0xe0` | `c3 07 ec e0 21` | **the one that matters** — mode hardcoded to `0x07` gives `ld A,(XHL+WA)`, a different index register, same length |
| `lda_dri xbc, 0x03, 0xec, 0xe0` | `f3 03 ec e0 41` | the STORE direction |
| `ldb_dri a, 0x03, 0xe0, 0xec` | `c3 03 e0 ec 21` | base and index swapped: `ld A,(XWA+L)`, a different address |
| `ldw_dri bc, 0x03, 0xec, 0xe0` | `d3 03 ec e0 21` | wrong width mnemonic |
| `ldb_dri a, 0x00, 0xec, 0xe0` | `c3 00 21` | a bad mode byte silently changes the **LENGTH** to three bytes — in a converted block that shifts everything after it |
| `ldb_dri a, 0x103, 0xec, 0xe0` | `c3 03 ec e0 21` | assembles to the *right* bytes for the wrong reason: the 9-bit value is truncated to 8 with no diagnostic, exactly like `lds32 xhl, 8` wrapping imm3 to 0 |

## The same encoding has a second set of mnemonics

`ldb_sri` / `ldw_sri` / `ld_sril3` (`TLCS900InstrInfo.td` "Consolidated SRI LD
defs") emit byte-identical output to `ldb_dri` / `ldw_dri` / `ldl_dri`.
Either set is correct. Two footnotes:

* `CLAUDE.md` documents this family as `ld_srib3` / `ld_sril3`. **`ld_srib3`
  does not exist** in the current backend — it is an `unrecognized instruction
  mnemonic` error. The 8-bit name is `ldb_sri` (or `ldb_dri`).
* `CLAUDE.md`'s example `ld_sril3 xbc, 0xe5, 0x0a, 0x0e` -> `e3 e5 0a 0e 21` is
  a **different addressing mode** (`(XBC+d16)`) wearing the same mnemonic. The
  mnemonic does not identify the addressing mode; the mode byte does.

## Sub-opcode neighbours, checked by hand

* `c3 07 f0 ec 28` and `c3 07 f0 ec 2f` are **not instructions** — unidasm
  prints `db`. That is why the rule tests `sub & 0xF8 == 0x20`, not just the
  high nibble.
* `d3 07 f0 ec 27` **is** one (`ld SP,(XIX+HL)`) and is the one gap: the
  backend's `GR16` class has no `SP`. It occurs **zero** times across all seven
  images (the widest `0xD3` sub-opcode seen is `0x26`), so nothing needs it.
* `e3 03 fc e0 27` (`ld XSP,(XSP+A)`) spells fine as
  `ldl_dri xsp, 0x03, 0xfc, 0xe0`. No image here uses base `0xFC`, and it would
  still be spellable if one did, because the base byte is raw.

## Numbers (2026-08-22, LLVM `tlcs900_backend@cb165c5cdc4b`)

```
verify_ld_regreg_load.py
  7164 instances: v7 2166 · v9 2167 · v10 2167 · table_data 20 ·
                  subprogram v142 562 · subcpu boot 4 · HD-AE5000 78
  prefixes c3:3437 d3:1500 e3:2227      modes 0x07:6687 0x03:477
  22 distinct (prefix,sub) pairs, 343 distinct five-byte strings
  TEST 0 listing bytes == image bytes            7164/7164
  TEST 1 assembled bytes == image bytes          7164/7164
  TEST 2 round-trip text identical               7164/7164
  TEST 3 negative controls differ                   7/7

blocked_ld_regreg_load.py --ranges
  A. 1138 sites still inside `.byte` blobs (v7 1100, v9 38)
     modes 0x07:1030  0x03:108
     located in the ROM image                    1138/1138
     converter translate()/canonical() matches   1029/1138
     raw-byte rule matches                       1138/1138
  B. reachable call-target ranges: 210 sites, 9 unspellable, all mode 0x03:
       0xefc898 c3 03 ec e0 21  ld A,(XHL+A)
       0xf54c3a c3 03 f4 e0 20  ld W,(XIY+A)
       0xf55fc4 d3 03 ec e0 23  ld HL,(XHL+A)
       0xf5619f d3 03 ec e1 23  ld HL,(XHL+W)
       0xf5edce d3 03 f4 e4 23  ld HL,(XIY+C)
       0xf670e8 c3 03 e0 ec 20  ld W,(XWA+L)
       0xf6e2c5 c3 03 f0 ed 27  ld L,(XIX+H)
       0xf6e2cc c3 03 f0 ed 26  ld H,(XIX+H)
       0xfcac9c e3 03 f0 e0 24  ld XIX,(XIX+A)
     raw-byte rule matches                            9/9
  C. replaying the converter's gates: 7 counted + 2 never reached = 9
```

## Why the converter's census says 7 and section B says 9

`python3 scripts/converters/convert_reachable_ranges.py --forms` prints

```
      7  ld r,(r+r)                 e.g. ld W,(XIY+A)
```

(2026-08-22 run: 257 unspellable instances in total, ~2 minutes). It TRUNCATES
a range at the first instruction it cannot spell, so anything of this form
further along is never counted. Section C replays those gates and reproduces
the 7 exactly, plus the two sites it never reaches:

| never counted | why |
|---|---|
| `0xefc898` `c3 03 ec e0 21` `ld A,(XHL+A)` | its range (entry `0xefc788`) stops 111 bytes earlier at `0xefc829` `cp (XIX+IZ),0x0c` — a **different** unspellable form |
| `0xf6e2cc` `c3 03 f0 ed 26` `ld H,(XIX+H)` | its range (entry `0xf6e24d`) stops at `0xf6e2c5`, the previous site of **this** form, 7 bytes earlier |

7 + 2 = 9, which is section B's total. Both numbers are correct about what they
measure; only section B's is about the form.

## What the converter needs

In `convert_corroborated_blocks.py::translate()`, the `_RIDX` branch should
offer the mode-`0x03` candidates as well as the mode-`0x07` ones, and should
map the 8-bit index names it currently lacks (`W`=0xE1, `B`=0xE5, `D`=0xE9,
`H`=0xED, and the Q set). Offering both modes is safe under this tree's rule
that selection is by BYTE MATCH, never by "it assembled" — a wrong candidate
simply fails to reproduce the bytes. Better still, when the raw bytes are in
hand, skip the names: `m`, `base` and `index` are bytes 1, 2 and 3.
