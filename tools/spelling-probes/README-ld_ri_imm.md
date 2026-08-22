# Probe: llvm-mc spelling for the unidasm form `ld (r+imm),imm`

Companion to `README-ld_direct_imm.md` (`ld (imm),imm`, eight encodings) and
`README-add_r_r.md`. One script, five passes:

| script | question it answers | command |
|---|---|---|
| `verify_ld_ri_imm.py rom` | Which `ld (r+imm),imm` sites still sit inside `.byte` blobs in all eight trees, and does the rule spell each one byte-exactly? | `python3 tools/spelling-probes/verify_ld_ri_imm.py rom` |
| `... sweep` | Synthetic sweep of the whole encoding space — does the rule hold away from the sites that happen to occur? | `... sweep` |
| `... real` | The instruction is already native in 1418 source lines; are those byte-exact? | `... real` |
| `... dangerous` | Which natural-looking spellings ASSEMBLE but emit the wrong bytes? | `... dangerous` |
| `... data` | Which of the remaining sites are data, not code? | `... data` |

Signal read: raw bytes of the eight original binaries in `original_ROMs/` at
their real ORIGIN. PASS = the llvm-mc `--show-encoding` bytes equal the bytes in
the binary at that address. "Assembled without error" is NOT a pass.

## The rule — decided on the RAW BYTES, never on the printed text

`ld (XIZ+0x00),0x90`, `ld (XBC+0xfe),0x1234` and `ld (XSP+0x00ac),0x00` are the
same printed shape and **four different encodings**. The printed text drops
everything that distinguishes them: the sub-opcode byte (byte vs word store),
the sign of the displacement, and whether the displacement is 8- or 16-bit.

| bytes | len | store | spelling |
|---|---|---|---|
| `B8+r, d8, 00, ii` | 4 | byte | `ld (<XRR[r]><disp>), ii` |
| `B8+r, d8, 02, lo, hi` | 5 | word | `ldw (<XRR[r]><disp>), lo\|hi<<8` |
| `F3, R\|01, lo, hi, 00, ii` | 6 | byte | `stib_ind R\|01, lo, hi, ii` |
| `F3, R\|01, lo, hi, 02, il, ih` | 7 | word | `stiw_ind R\|01, lo, hi, il, ih` |

`XRR = xwa xbc xde xhl xix xiy xiz xsp`, `r = b[0] & 7`.

`disp` is the **signed** value of `d8` (`0xf6` → `-10`), with one exception:

> **`d8 == 0` must be written `+256`.** The backend uses 256 as a force-d8
> sentinel (`TLCS900MCCodeEmitter.cpp:242`). A plain `+0` — or no displacement
> at all — collapses to the 1-byte `B0+r` prefix and the instruction comes out
> one byte short. 49 of the sites in the ROM have `d8 == 0`, including the
> canonical example v7 `0xefb8e2` `be 00 00 90`.

For the `F3` family the raw-byte form `stib_ind` / `stiw_ind` is always correct.
`ld (<XRR>+d16), imm` is an **alias** that is only right when the register byte
is one of `E1 E5 E9 ED F1 F5 F9 FD` (a current-bank `XRR`) *and* the signed d16
is outside `-128..127`; otherwise llvm-mc compacts it to the shorter prefix.
Two real sites (`table_data` `0x85fc3f`, `0x8617a9`, register byte `0x1d`) have
no register name at all, so only the raw form reaches them.

## Results, 2026-08-22, LLVM `tlcs900_backend@cb165c5cdc4b`

Pass 1 — `.byte` blobs of all eight trees:

| tree | sites |
|---|---:|
| v7/maincpu | 1316 |
| v9/maincpu | 85 |
| v10/maincpu | 85 |
| table_data | 215 |
| v142/subcpu | 41 |
| subcpu, custom_data, hdae5000 | 0 |
| **total** | **1742** |

663 distinct encodings, **1742/1742 byte-exact, 0 mismatched, 0 unspellable.**
Families: `B8/ld` 1145, `B8/ldw` 476, `F3/ld` 115, `F3/ldw` 6.
38 further decodes were discarded as blob-end artefacts: unidasm zero-pads past
the end of the run it is given, so it invents an instruction there — the bytes
it prints are not the bytes in the file, which is exactly why every site is
re-read from the binary before it is counted.

Pass 2 — synthetic: 8 registers × all 256 `d8` × 10 immediates, plus 8
registers × 11 `d16` values × 10 immediates = **21360 encodings, 21360
byte-exact**. 221/221 sampled cases were fed back through unidasm to confirm
they really do print as this form.

Pass 3 — 1418 lines of this instruction are already native in the sources (v7
147, v9 616, v10 616, v142 39), and all eight trees currently rebuild
**md5-identical** to their original binaries, so those lines are byte-exact by
construction rather than by search.

Pass 4 — the dangerous ones. All six assemble cleanly and all six are wrong:

| spelling | ROM bytes | what llvm-mc emits | why |
|---|---|---|---|
| `ld (xiz+0), 0x90` | `be 00 00 90` | `b6 00 90` | `d8==0` collapses to the `B0+r` prefix |
| `ld (xiz), 0x90` | `be 00 00 90` | `b6 00 90` | same trap, no displacement written |
| `ldw (xiz+0), 0x1234` | `be 00 02 34 12` | `b6 02 34 12` | the word form of the same trap |
| `ld (xsp+4), 0x00ff` | `bf 04 02 ff 00` | `bf 04 00 ff` | a word store written `ld` becomes a BYTE store |
| `ld (xix+246), 0` | `bc f6 00 00` | `f3 f1 f6 00 00 00` | unidasm's raw `d8` read as unsigned inflates to d16 |
| `ld (xbc+44), 0` | `f3 e5 2c 00 00 00` | `b9 2c 00 00` | a d16 site whose value fits in d8 is compacted |

Pass 5 — 227 of the 1742 sites are **data**, not code: 215 in `table_data`
(a data ROM — 91 of them inside the `0x830000-0x87FFFF` tone database that
`SubCPU_Send_Payload` bulk-copies to Sub-CPU RAM, and in
`panel_memory_presets.s` 79 of the 80 sites sit on a fixed **674-byte record
stride**) plus 12 in `v142/subcpu/subcpu_data_tables.s`. The rule spells them
byte-exactly all the same, but a converter should leave them as `.byte`.

## Verdict

No backend work is needed. Every encoding of this form already has a byte-exact
spelling; what was missing was the rule, and in particular the `+256` sentinel,
which no source line in any tree had yet used for the immediate-store form.
