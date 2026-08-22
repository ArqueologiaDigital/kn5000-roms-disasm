# Probe: llvm-mc spelling for the unidasm form `add r,r`

Companion to `README-ld_r_N.md`. One script, four passes:

| script | question it answers | command |
|---|---|---|
| `verify_add_r_r.py` | For each of the SIX encodings that unidasm prints as `add r,r`, is there an llvm-mc spelling whose `--show-encoding` bytes equal the real ROM bytes? | `python3 tools/spelling-probes/verify_add_r_r.py` |
| `verify_add_r_r.py exhaustive` | Same, synthetic sweep of all 6336 encodings of the form. | `... exhaustive` |
| `verify_add_r_r.py rom` | Which `add r,r` sites still sit inside `.byte` blobs in v7/v9/v10, and does the rule spell each one byte-exactly? | `... rom` |
| `verify_add_r_r.py real` | Do the already-converted `addb_erp`/`addw_erp` lines in the byte-exact v9 sources match the real ROM at their real addresses? | `... real` |
| `verify_add_r_r.py brute` | Can ANY of the 702 mnemonics the AsmParser knows emit the encodings the rule cannot spell? | `... brute` |
| `verify_add_r_r.py boundary` | Is the one unspellable site a real 3-byte instruction, or a linear-decode artefact? | `... boundary` |

Signal read: raw bytes of `original_ROMs/kn5000_v{7,9,10}_program.rom`, load base
`0xE00000`. PASS = llvm-mc encoding equals those bytes. "Assembled without error"
is NOT a pass.

## The rule — decided on the RAW BYTES, never on the printed text

`add DST,SRC` is one printed string and six encodings. `add A,C` is `cb 81`
**or** `c7 e4 81`; both print identically. Discriminate on byte 0 and length:

| byte 0 | len | size | dst | src | llvm-mc spelling |
|---|---|---|---|---|---|
| `C8..CF` | 2 | byte | `b[1]&7` | `b[0]&7` | `add <GR8[dst]>, <GR8[src]>` |
| `C7`     | 3 | byte | `b[2]&7` | `b[1]` (raw bank byte) | `addb_erp <GR8[dst]>, <b[1]>` |
| `D8..DF` | 2 | word | `b[1]&7` | `b[0]&7` | `add <GR16[dst]>, <GR16[src]>` |
| `D7`     | 3 | word | `b[2]&7` | `b[1]` (raw bank byte) | `addw_erp <GR16[dst]>, <b[1]>` |
| `E8..EF` | 2 | long | `b[1]&7` | `b[0]&7` | `add <GPR[dst]>, <GPR[src]>` |
| `E7`     | 3 | long | `b[2]&7` | `b[1]` (raw bank byte) | **none — see below** |

The last byte is always `0x80 | dst`. Register index order is
`GR8 = w a b c d e h l`, `GR16 = wa bc de hl ix iy iz sp`,
`GPR = xwa xbc xde xhl xix xiy xiz xsp`.

`add C,QIZH` is `c7 fb 83` → `addb_erp c, 0xfb`.

Aliases that emit the SAME bytes (safe, but pick one): for `D7` the spellings
`addw_erp r,bank`, `add_erpw_rr r,bank` and — only when the bank byte is one of
`E2 E6 EA EE F2 F6 FA FE` — `add r,q<xx>` are all identical encodings.

## Results, 2026-08-22, LLVM `tlcs900_backend@cb165c5cdc4b`

Pass 1 (synthetic, 6336 encodings, 0 unidasm form-mismatches):

| family | encodings | byte-exact | holes |
|---|---:|---:|---|
| short8  | 64 | 64 | — |
| short16 | 64 | 49 | 15, all involving `SP` (`GR16` excludes SP) |
| short32 | 64 | 64 | — |
| erp8    | 2048 | 2048 | — |
| erp16   | 2048 | 1792 | 256, all `dst = SP` |
| erp32   | 2048 | **0** | **no spelling exists at all** |

Pass 2 (`.byte` blobs of v7+v9+v10): 2054 candidate sites, 116 distinct
encodings, **115 byte-exact, 0 mismatches**, 1 unspellable. No SP-hole encoding
occurs in any blob, so the SP holes are theoretical for the converter.
The single unspellable site is v7 `0xf20158`: `e7 34 81` = `add XBC,XBC3`,
inside a blob in `v7/maincpu/ui/setwall_routines.s`.

Pass 3 (real v9 ROM addresses): 12 located, **12/12 byte-exact** — e.g. v9
`0xf0b826` `c7 fb 83` ← `addb_erp C, 0xfb`, v9 `0xff1664` `d7 fa 80` ←
`addw_erp WA, 0xfa`. Five more source lines exist but their neighbourhoods are
not literal-only, so the window search cannot pin them uniquely; that is a limit
of the locator, not a failure of the spelling.

Pass 5 (instruction-boundary proof): see below.

Pass 4 (falsification): 702 mnemonics × 41 operand shapes = 28782 lines
(llvm-mc **crashes** on some mnemonic/operand pairs, so the runner bisects around
crashes — a plain batch silently loses every later line). 967 assembled.
`e7 34 81`, `d8 87`, `df 80`, `d7 00 87` → **0 spellings**. The four control
encodings in the same sweep were all found, so the sweep can detect a hit.

## What the missing 32-bit ERP def needs

The `E7` gap is not cosmetic: v9/v10 already contain the instruction and the
converter could not write it, so it emitted an orphan prefix byte instead —
`v9/maincpu/ui/setwall_routines.s:2050` is `.byte 0xe7` followed by a bogus
`ldw ix, 0xda81` / `ld w, 0` re-sync, covering ROM `0xf20182..0xf20188`.

Pass 5 settles which framing is right without trusting any disassembler. In v7
the same routine is a 16-iteration loop:

```
f20140: e9 d1              xor XBC,XBC
f20142: da d2              xor DE,DE
f20144: c3 07 f0 e8 21     ld A,(XIX+DE)     <- loop head, target of the jr C below
f20149: c9 33 07           bit 0x07,A
f2014c: 66 0d              jr Z,0xf2015b     <- lands EXACTLY after the E7 instruction
f2014e..f20157             push/call/pop
f20158: e7 34 81           add XBC,XBC3
f2015b: da c8 03 00        add DE,0x0003
f2015f: da cf 30 00        cp DE,0x0030
f20163: 67 df              jr C,0xf20144
```

A branch target is an instruction boundary, and `0xf2014c` targets `0xf2015b`,
so `f20158..f2015a` is exactly one instruction. Under the v9 framing
(`.byte 0xe7`, then `34 81 da`, then `c8 03 00`) that branch would land in the
middle of `ldw ix, 0xda81`. The v9 framing is therefore wrong, and
`e7 34 81 = add XBC,XBC3` is right — it is the loop's accumulator step. Bank-3
registers are used as scratch all over this file (`ldfr_lerp XIZ, 0x38`,
`ldto_lerp XIZ, 0x38`), so `XBC3` is in character.

Sibling defs are `ADD_BERP`/`ADD_WERP` in `TLCS900InstrInfo.td` (~line 3640/3668).
The missing one belongs in the existing `// 32-bit ERP operations with register
operand` block next to `LDTO_LERP`/`LDFR_LERP` (~line 3689):

```tablegen
let OpSize = OpSize32.Value in {
def ADD_LERP : ERPRegInst<0x80, (outs), (ins GPR:$rs, i32imm:$bank),
    "addl_erp", "$rs, $bank", []>, Sched<[WriteSTW]>;
}
```

Derivation from the real bytes: `ERPRegInst` emits `[prefix, bank, SubOpcode+reg]`
with `prefix = Opcode(0xC7) + OpSize*0x10` (`TLCS900MCCodeEmitter.cpp`,
`case TLCS900II::ERPReg`), so `OpSize32 = 2` gives `0xE7`; `SubOpcode = 0x80`
gives the trailing `0x80|dst`; `GPR` (`HWEncoding` `XWA`=0 … `XSP`=7) gives the
`dst` field. `e7 34 81` would then be written `addl_erp xbc, 0x34`.

Not added here: this task was allowed to create new files only.

## Known holes that are NOT in any blob

`GR16` deliberately excludes `SP`, so the 16-bit `add` with SP as source or
destination (`d8..df` with `b[0]&7 == 7` or `b[1]&7 == 7`, and `d7 <bank> 87`)
cannot be written either. Linear decodes of the four ROMs show 22 such byte
sequences, but none of them is inside a located `.byte` blob, i.e. none is a
converter candidate — they are unaligned decodes of data. Fixing them would need
a `GR16SP`-typed 16-bit add, which is a separate question from this one.
