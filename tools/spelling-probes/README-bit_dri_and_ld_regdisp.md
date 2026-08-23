# Probe: three blocking forms — `bit 7,(r+r)`, `ld (r+imm),r`, `ld (r+imm),imm`

All three are spellable today. None is a backend gap.

| script | question it answers | command |
|---|---|---|
| `blocking_bit_dri_and_ld_regdisp.py` | Which ROM addresses does a blocking form occur at, and what are the exact bytes there? | `python3 tools/spelling-probes/blocking_bit_dri_and_ld_regdisp.py 'bit 7,(r+r)' 'ld (r+imm),r' 'ld (r+imm),imm'` |
| `verify_bit_dri_and_ld_regdisp.py` | Does the proposed spelling reproduce the ROM bytes at every site, and do the negative controls fail? | `python3 tools/spelling-probes/verify_bit_dri_and_ld_regdisp.py [--all]` |

Signal read: the raw bytes of `original_ROMs/kn5000_v7_program.rom` at each site
(load base `0xE00000`). PASS = the llvm-mc `--show-encoding` bytes equal those
ROM bytes. "Assembled without error" is NOT a pass — every negative control
below assembles cleanly.

Both scripts import `scripts/converters/convert_reachable_ranges.py`, so they
decode with the converter's own `decode_range()` and judge "already spellable"
with the converter's own `translate()`/`canonical()`.

## Result, v7 reachable decode, 2026-08-23

807 decoded sites carry one of the three printed forms. 803 are real; 4 are
phantoms (see below).

| outcome | sites |
|---|---|
| rule A `bit_dri` | 2 |
| rule B `ld (<XRR><signed disp>), <reg>` | 561 |
| rule C `ld/ldw (<XRR><signed disp>), <imm>` | 235 |
| already spelled by the existing `translate()` rules | 5 |
| **still unspellable** | **0** |
| phantom decodes (not instructions) | 4 |

Of those, 29 were BLOCKING before this probe (2 + 15 + 12).

## Rule A — `bit N,(<base>+<index>)` is `bit_dri`

`BIT_DRI` already exists (`TLCS900InstrInfo.td:4195`, base `0xF3`, sub-opcode
`0xC8`, 5 bytes) next to `res_dri`/`set_dri`/`ldcf_dri`/`xorcf_dri`. It was
never offered: `translate()` handles `bit N,(0xABS)` only. The three addressing
bytes pass through as plain immediates, exactly as `ldb_dri` and `stib_ind` take
them; the register-byte table is the `_RIDX` map already in `translate()`.

    0xEFA650  f3 07 e8 f8 cf   bit 7,(XDE+IZ)   ->  bit_dri 7, 0x07, 0xe8, 0xf8
    0xEFD2E9  f3 07 e8 ec cf   bit 7,(XDE+HL)   ->  bit_dri 7, 0x07, 0xe8, 0xec

Offer mode `0x07` (16-bit index) **and** `0x03` (8-bit index) and let the byte
comparison choose — the same trap `ldb_dri` hit.

## Rules B and C — the displacement is SIGNED, and zero needs the sentinel

`(XRR+d8)` destinations are `0xB8+r`. unidasm prints `d8` as a RAW BYTE, so
`0xfc` means **-4**. Writing the printed value gets a different, longer
instruction that assembles without complaint.

    ld (xhl+0xfc), 0x0000   ->  f3 ed fc 00 00 00      (6 B, 16-bit disp form)
    ldw (xhl - 0x04), 0x0000 -> bb fc 02 00 00         (5 B, what the ROM holds)

And `d8 == 0` must be written `+0x100` — the backend's force-d8 sentinel —
because a literal `+0x00` collapses to the 2-byte `0xB0+r` form:

    ld (xix+0x00), wa   ->  b4 50        (2 B)
    ld (xix+0x100), wa  ->  bc 00 50     (3 B, what the ROM holds)

unidasm distinguishes the two: it prints `(XIX)` for `b4 50` and `(XIX+0x00)`
for `bc 00 50`, so the printed text is not ambiguous here.

**The printed digit count carries the displacement width** and must be used
instead of guessing from the byte value: `ld (XIZ+0x00d8),XWA` is `f3 f9 d8 00
60`, a *positive* 16-bit `+216`, while `ld (XBC+0xff),A` is `b9 ff 41`, an
8-bit `-1`. 71 sites use the 16-bit form.

### Negative controls (all assemble; all emit the wrong bytes)

| control | sites | result |
|---|---|---|
| unsigned 8-bit displacement, e.g. `ld (xbc+0xff), a` | 13 | 5–6 byte `f3`-prefixed form instead of 3–5 |
| literal `+0x00` instead of the `+0x100` sentinel | 14 | 2-byte `0xB0+r` form |

## Known latent trap: a genuine displacement of +256

`ld (xbc + 0x0100), a` emits `b9 00 41` — the sentinel wins — and no mnemonic
reaches `f3 e5 00 01 41`. `stib_ind`/`stiw_ind` cover the immediate direction
(`stib_ind 0xe5, 0x00, 0x01, 0x12` = `f3 e5 00 01 00 12`), but there is no
`st{b,w,l}_ind` for the register direction. **Zero sites in v7's reachable
decode use `+0x0100`**, so this costs nothing today; it is a real (though
currently free) backend gap.

## Phantom decodes — a fifth cause the census cannot distinguish

`decode_range()` hands unidasm only the bytes of the undisassembled run, and
unidasm reads past the end of that buffer as ZEROES. The last decoded
instruction can therefore be assembled from bytes that are not in the ROM:

| address | printed | run ends at | ROM really holds |
|---|---|---|---|
| `0xFCD010` | `ld (XSP+0x00),0x00` | `0xFCD011` | `bf 0a 60` = `ld (XSP+0x0a),XWA` |
| `0xFE5E1D` | `ld (XDE+0x00),0x00` | `0xFE5E1E` | `ba 03 46` = `ld (XDE+0x03),H` |
| `0xFE6807` | `ld (XSP+0x02),0x00` | `0xFE6809` | `bf 02 30` = `lda XWA,XSP+0x02` |
| `0xFE7375` | `ld (XSP+0x02),0x00` | `0xFE7377` | `bf 02 30` = `lda XWA,XSP+0x02` |

These four are harmless — `main()` refuses those ranges earlier, with
"no `ret`, and does not end at a code boundary", because the overshoot makes
`sum(len) != run length`. But they DO enter the `--forms` census as blocking
forms, so a form's instance count can be inflated by decodes that are not
instructions at all. `verify_bit_dri_and_ld_regdisp.py` labels them PHANTOM.
