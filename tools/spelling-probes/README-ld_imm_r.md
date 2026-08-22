# Probe: llvm-mc spelling for the unidasm form `ld (imm),r`

Example listing line: `ef8d85: f1 0e 11 63    ld (0x110e),XHL`

| script | question it answers | command |
|---|---|---|
| `verify_ld_dir_store.py` | Does the proposed spelling rule assemble byte-exactly at **every** `ld (imm),r` site in v7, v9, v10 and table_data? | `python3 verify_ld_dir_store.py` |

Signal read: the raw ROM bytes at each address (`original_ROMs/kn5000_v{7,9,10}_program.rom`
at load base 0xE00000, `original_ROMs/kn5000_table_data.rom` at 0x800000).
PASS = `llvm-mc -triple=tlcs900 --show-encoding` output equals those bytes.
"Assembled without error" is NOT a pass. Exit code 0 = every site byte-exact.

## The rule

One printed form, **nine encodings**: three address widths x three operand sizes.
The *prefix byte* picks the address width; the *sub-opcode nibble* picks the operand size.

| bytes | size | mnemonics (byte / word / long) | operand order |
|---|---|---|---|
| `f0 <a8> <sub>` | 3 | `st_dd8b` / `st_dd8w` / `st_dd8l` | **reg first, bare address** |
| `f1 <a16 LE> <sub>` | 4 | `stb_d8` / `stda16` / `stda32` | address first, parenthesised |
| `f2 <a24 LE> <sub>` | 5 | `stb_da` / `stw_da` / `stl_da` | address first, parenthesised |

`sub = 0x40|r` byte, `0x50|r` word, `0x60|r` long, with
`r` indexing `W A B C D E H L` / `WA BC DE HL IX IY IZ SP` / `XWA XBC XDE XHL XIX XIY XIZ XSP`.

```
st_dd8b a, 0x3e            -> f0 3e 41
stda32 (0x110e), xhl       -> f1 0e 11 63
stl_da (0x027416), xiz     -> f2 16 74 02 66
```

**SP (`sub = 0x57`) needs the 32-bit name**, because the backend's `GR16` class excludes SP
(`TLCS900RegisterInfo.td:95`). `getRegEncoding()` reduces the operand modulo the instruction's
operand size, so `xsp` reaches index 7 under a word mnemonic:

```
stda16 (0x1800), xsp       -> f1 00 18 57      ( `sp` is rejected outright )
stw_da (0xf1453b), xsp     -> f2 3b 45 f1 57
```

## Result 2026-08-22

**18407 / 18416 sites byte-exact**; round-trip through unidasm reproduces the original
printed text for all 71 distinct (prefix, sub-opcode) forms present.

The 9 failures are all one form, `f0 .. 57` (`ld (0xNN),SP`), which has **no spelling**:
`ST_DD8W` is declared `GR16`-only with no `GPR` overload, so both `st_dd8w sp,N` and
`st_dd8w xsp,N` are rejected. **It costs nothing here** -- all 9 sites are linear-sweep
artifacts inside 32-bit pointer tables, e.g. v9 `0xE0DBFC` is the third byte of the record
`f0 00 57 3b` in a run of `...3a`/`...3b` pointers. There are zero real-code instances.
If it is ever wanted, the fix mirrors `LD16m_da16` / `LD16m_da16_r16` (two defs, one mnemonic):

```tablegen
def ST_DD8W_L : D8RegInst<0xF0, 0x50, (outs), (ins GPR:$rs, i32imm:$addr),
    "st_dd8w", "$rs, $addr", []>;
```

(`D8RegInst` defaults to `OpSize32`, under which `getRegEncoding(XSP)` is already 7.)

## The text is a sufficient discriminator too -- checked, not assumed

Unlike `ld (0xADDR),0xIMM`, this form is *not* ambiguous in its printed text. MAME zero-pads
the address to the width of the encoding, so the hex-digit count alone identifies the prefix:
**2 digits -> f0 (411 sites), 4 -> f1 (16267), 6 -> f2 (1738), 0 exceptions.** The script
asserts this and aborts if a single site ever violates it. A converter may drive off the text;
the bytes remain the authority and are what is graded.

## Near-misses that assemble but are wrong

| spelling | assembles to | wanted | what it really is |
|---|---|---|---|
| `stda16 (0x110e), xhl` | `f1 0e 11 53` | `f1 0e 11 63` | word store of **HL** |
| `stb_d8 (0x110e), xhl` | `f1 0e 11 47` | `f1 0e 11 63` | byte store of **L** -- the 32-bit name silently means index 3 |
| `stw_da (0x110e), xhl` | `f2 0e 11 00 53` | `f1 0e 11 63` | 24-bit-address form, 5 bytes |
| `stb_d8 (0x3e), a` | `f1 3e 00 41` | `f0 3e 41` | 16-bit-address form, 4 bytes |
| `stda32 (0x3e), xhl` | `f1 3e 00 63` | `f0 3e 63` | 16-bit-address form, 4 bytes |

Corroboration that the `f0` family is real code and not only a sweep artifact: v9's
`maincpu/ui/cpanel_routines.s` carries exactly 18 `st_dd8b A, 0x3e` lines, and the v9 ROM
carries exactly 18 occurrences of `f0 3e 41` -- writes to the TMP94C241 internal I/O
register at 0x3E.
