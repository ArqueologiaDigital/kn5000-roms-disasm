# Probe: llvm-mc spelling for the unidasm form `lda r,r+r`

Example the search started from: `lda XBC,XBC+WA`, and the concrete site
v7 `0xEF3600` = `lda XDE,XDE+BC`, ROM bytes `f3 07 e8 e4 32`.

| script | question it answers | command |
|---|---|---|
| `verify_lda_regreg.py` | Which llvm-mc spelling encodes to the ROM bytes of *every* `lda r,r+r` site in the KN5000 / HD-AE5000 images? | `python3 tools/spelling-probes/verify_lda_regreg.py` |
| `verify_lda_regreg.py rom` | …for the 1918 real instances a linear decode finds | `… rom` |
| `verify_lda_regreg.py exhaustive` | …for all 16384 encodings of the shape, including the ones no ROM contains | `… exhaustive` |
| `verify_lda_regreg.py blobs` | Which sites still sit inside `.byte` blobs, and does the rule spell each one? | `… blobs` |
| `verify_lda_regreg.py real` | Do the `stb_dri` lines already in the byte-exact trees match the real ROM? | `… real` |
| `verify_lda_regreg.py neg` | Which plausible spellings assemble and produce the WRONG bytes? | `… neg` |

**Signal read:** the raw bytes of each instruction. The listing is not trusted —
`rom` re-reads every instance from the ROM **file** at `addr - base` and asserts
it equals what unidasm printed. PASS = `llvm-mc -triple=tlcs900 --show-encoding`
emits exactly those bytes. "Assembled without error" is NOT a pass; see the
negative controls.

## The spelling — a function of the RAW BYTES, never of the printed text

```
f3 <m> <base> <index> <sub>        m = 0x03 -> 8-bit  index register
                                   m = 0x07 -> 16-bit index register
sub = 0x30|r    ->    stb_dri GR8[r], m, base, index
GR8 = w a b c d e h l              r = sub & 7
```

The three addressing bytes pass through **verbatim** as plain immediates. The
register operand exists only to supply the low nibble `r`.

### The trap: the GR8 letter names neither printed register

```
printed destination   XWA XBC XDE XHL XIX XIY XIZ XSP
sub-opcode r            0   1   2   3   4   5   6   7
GR8[r] you must write   w   a   b   c   d   e   h   l
```

`lda XIY,XIY+A` (`f3 03 f4 e0 35`) is written `stb_dri e, 0x03, 0xf4, 0xe0`.
The `e` is an index into the GR8 allocation order, and has nothing to do with
`XIY` or with `A`. Writing the "obvious" letter silently changes the
destination register — see the negative controls.

### The mnemonic is misnamed

`ST_DRI3B` / `"stb_dri"` is documented in `TLCS900InstrInfo.td` (~line 4708) as
an 8-bit **store**, but sub-opcode `0x30` is really `lda XRR,mem`. Its `GR8`
operand is what makes all eight destinations reachable — including
`lda XSP,base+index` (`r = 7` → `l`), which a 32-bit-typed operand could not
reach because `GPR` and `GR16` handle SP inconsistently elsewhere. `0x37` does
not occur in any ROM here; the `exhaustive` pass proves it is spellable anyway.

The sibling `README-ld_regreg_store.md` already recorded that `stb_dri` really
means `lda`; this probe is the other half of that observation — it is the form
that *needs* the misnamed mnemonic.

## Dangerous candidates — these ASSEMBLE and are WRONG

| spelling | emits | ROM has |
|---|---|---|
| `lda xwa, (xwa+bc)` | `f3 e1 A A 30` — the `(XWA+d16)` mode; `bc` becomes an undefined **symbol**. In an object file: `f3 e1 00 00 30` + `R_TLCS900_LO16 bc` | `f3 07 e0 e4 30` |
| `lda xbc, (xbc+wa)` | `f3 e5 A A 31` — same trap | `f3 07 e4 e0 31` |
| `lda xwa, (xwa+xbc)` | `f3 e1 A A 30` — same trap with 32-bit index names | `f3 07 e0 e4 30` |
| `stb_dri a, 0x07, 0xe0, 0xe4` | `f3 07 e0 e4 **31**` — destination XBC, not XWA | `f3 07 e0 e4 30` |
| `stl_dri xwa, 0x07, 0xe0, 0xe4` | `f3 07 e0 e4 **60**` — the 32-bit store | `f3 07 e0 e4 30` |
| `lda_dri xwa, 0x07, 0xe0, 0xe4` | `f3 07 e0 e4 **40**` — the 8-bit store, despite the name | `f3 07 e0 e4 30` |

⚠ The first row is **a rule the tree already documents as confirmed**:
`scripts/converters/convert_corroborated_blocks.py` lists
`lda XHL,XDE+XBC -> lda XHL,(XDE+XBC)` — "parenthesise reg+reg" — among its
confirmed translations. For the register-index form it is wrong. It is caught
today only because the byte-match gate sees `00 00` where the ROM has
`07 e4`, which is why all 323 of these sites are still `.byte`. Changing the
converter is out of scope for this probe (new files only), but the rule to use
is the `stb_dri` one above.

These do **not** parse at all, which is safe but worth recording so nobody
retries them: `lda XWA,XWA+BC` (unidasm's own text), `lda XBC,XBC+WA`,
`stb_dri xwa, 0x07, 0xe0, 0xe4` (the operand is `GR8`, not `GPR`).

## Numbers (2026-08-22, LLVM `tlcs900_backend@cb165c5cdc4b`)

Images scanned: `kn5000_v7_program.rom`, `kn5000_v9_program.rom`,
`kn5000_v10_program.rom`, `kn5000_table_data.rom`,
`kn5000_subprogram_v142.rom`, `kn5000_subcpu_boot.ic30`,
`hd-ae5000_v2_06i.ic4`.

* **rom** — 1918 printed instances (v7 566, v9 565, v10 565, subprogram v142
  215, subcpu boot 2, HD-AE5000 5, table_data 0). **Every** one is
  `f3 {03,07} base index 0x30|r`: 1915 with mode `0x07`, 3 with mode `0x03`.
  118 distinct byte strings; sub-opcodes `0x30`–`0x36` occur, `0x37` never.
  * TEST 1 assembled bytes == ROM bytes: **1918 / 1918**
  * TEST 2 assembled bytes re-disassemble to the identical text: **1918 / 1918**
* **exhaustive** — all `2 × 32 × 32 × 8 = 16384` encodings of the shape:
  **16384 / 16384** byte-exact. 9216 of them (`8 r × 24 base × 24 index ×
  2 modes`) re-print as `lda r,r+r`; the other 7168 have a base or index byte
  ≡ 3 (mod 4), which unidasm renders `rE3L`-style — those still assemble
  byte-exactly, they simply are not this printed form.
* **blobs** — 323 sites inside uniquely-located `.byte` runs: v7 248,
  subprogram v142 45, v10 20, v9 10. **323 / 323 spellable byte-exactly,
  0 unspellable.** Heaviest files: `midi_dispatch_handlers.s` 47,
  `note_voice_mapping.s` 46, `kn5000_subprogram_v142.s` 45,
  `single_load.s` 33, `scoop_display.s` 20.
* **real** — 96 `stb_dri` lines already in the byte-exact trees are uniquely
  locatable by content in their own ROM: **96 / 96** byte-exact, e.g. v7
  `0xF89451` `f3 07 e4 f8 31` ← `stb_dri A, 0x07, 0xe4, 0xf8`
  (`v7/maincpu/demo/file_demo_proc.s:4866`).
* **neg** — **6 / 6** dangerous candidates produced different bytes.

**No sites are data.** Every instance is spellable, so the "are the leftovers a
linear-decode artefact?" question does not arise for this form.

**What would falsify this:** any site where `llvm-mc` emits bytes other than the
ROM's. `rom`, `blobs` and `real` print and count every such mismatch; they
reported none.
