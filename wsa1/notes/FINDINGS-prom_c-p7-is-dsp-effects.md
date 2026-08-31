# The P7 "units" are DSP EFFECT SLOTS, and a "PROGRAM" is an EFFECT NUMBER

*Measured 2026-08-30 by lane A4, during the prom_c per-subject split.*
*Regenerate every number below -- do not retype it:*

```
python3 notes/prom_c_p7_program_is_effect.py            # the measurement
python3 notes/prom_c_p7_program_is_effect.py --selftest # invariants + NEGATIVE controls
```

⚠ **NO LABEL HAS BEEN RENAMED.** 572 `P7*` labels is a bulk rename, and a bulk
rename belongs in its own pass with its own byte gate, not bolted onto a
127,730-line source reorganisation where nobody could review either half. The
recommended mapping is at the bottom of this note; the argument for it is above.

---

## 1. The two open questions this closes

Two tables in two different EPROMs each carried an admission of ignorance, and
each was the other's answer.

**prom_c** `PoolDir_RecordForUnitProgram` -- 0xFDC551, 128 bytes
(`prom_c/p7/p7_stream_pool.s`). A P7 unit block's byte +0 is a number 0..127
that this table turns into a `PoolDir_Records` index. `prom_c/p7/p7_module.s`
calls it a PROGRAM and says:

> `⚠ WHAT IS NOT ESTABLISHED ... what a PROGRAM 0..127 sounds like. The word
> means the selector at block +0 and nothing more`

**prom_b** `EffectNames_F147AC` -- 0xF147AC, 128 x 16 ASCII effect names
(`prom_b/wsa1_prom_b.s:29401`). Its own header says:

> `Read by: NOTHING in prom_a or prom_b spells 0x00F147AC in a decodable operand`
> `⚠ Unknown: that entry k is effect algorithm k.  ... 128 and 128 is a
>  CORRESPONDENCE, not a decoded fact.`

The index prom_b could not find is in prom_c. The meaning prom_c could not find
is in prom_b.

## 2. The join, and why it is a measurement and not a resemblance

Slot *k* of the NAME table carries a real name (rather than the `----------`
placeholder) **if and only if** slot *k* of the prom_c table resolves to a
record other than the catch-all:

```
  slots where 'has a real name' == 'maps to a record != 53':  127 of 128
    exception  slot   0  name '  NO OPERATION  '  record 53
  distinct records the 56 named programs map to: 56   (BIJECTION)
  records the 72 placeholder programs map to:   [53]
```

The single exception is the one that has to be there: `NO OPERATION` is a real
name for a program with nothing to load, so it correctly shares the catch-all.

And the 56 named programs take **56 distinct records** -- a bijection, not two
counts that happen to agree.

★ **The negative control is what makes this evidence.** "Two tables agree" only
counts if disagreement was possible. All 127 non-zero rotations of the name
table against the program table disagree on **at least 13** slots, against 1 for
the true alignment. The join can fail; it does not.

## 3. The chain closes end to end, and the EFFECT NUMBER appears twice

Four `P7Stream` objects in prom_c are byte-identical runs of **named** objects in
the KN5000 sub-CPU ROM, and the KN5000's own label carries the effect number:

```
  program   5 PHASER             record   9 field + 4 -> 0xFD7764 (164 B)  BYTE-IDENTICAL to DSP_Eff05_Coef_Bytecode
  program  65 S.DELAY+S.DELAY    record  39 field + 8 -> 0xFD0C4B ( 95 B)  BYTE-IDENTICAL to DSP_Eff65_Param_Values
  program  64 S.DELAY+CHORUS     record  38 field + 8 -> 0xFD08CD ( 49 B)  BYTE-IDENTICAL to DSP_Eff64_Param_Values
  program  68 S.DELAY+PHASER     record  42 field + 8 -> 0xFD1399 ( 49 B)  BYTE-IDENTICAL to DSP_Eff68_Param_Values
```

Read the first row from both ends. **WSA1:** program 5 -> prom_b name `PHASER`
-> `PoolDir_Records[9]` field +4 -> the stream at 0xFD7764. **KN5000:** the same
164 bytes are `DSP_Eff05_Coef_Bytecode`, under a header that reads
`----- effect 5: PHASER -----`
(`../kn5000-roms-disasm/v142/subcpu/subcpu_data_tables.s:5244`). Two machines,
two firmwares, the same number, the same name, the same bytes.

⚠ The KN5000 offsets in `notes/FINDINGS-kn5000-transplant-offset.md`'s table do
NOT locate these runs in `kn5000_subprogram_v142.rom` -- that column is in some
other coordinate. The offsets in the probe were re-found by searching the KN5000
image for the WSA1 bytes, and the probe carries a negative control: the same
lengths taken one byte earlier do not match, so this is not a run of padding.

## 4. What this establishes

* The P7 unit block's byte +0 is a **DSP effect number**, on the **same
  numbering the KN5000 uses**.
* A "unit" is therefore an **effect slot**; the WSA1 has three, the KN5000 five.
* A `P7Stream` is **DSP effect data** -- coefficient bytecode in pool fields
  +0/+4, parameter-value records in +8/+12, matching the KN5000's
  `*_Coef_Bytecode` / `*_Param_Values` split.
* prom_b's effect-name table is **indexed from prom_c**, which is why no operand
  in prom_a or prom_b spells its address.
* The WSA1's 56 real names against the KN5000's larger set is itself a fact
  worth keeping: this machine's effect catalogue is a **subset** of the family's.

## 5. What this does NOT establish

* **The part number.** Nothing in any WSA1 ROM names the chip on the other end
  of port P7. "Three destinations and three uPD6383GF DSPs in the machine is
  consistent and is NOT proof" (`prom_c/p7/p7_module.s`). A `Upd6383_` prefix
  would still be an import from a parts list.
* **What any individual stream byte means.** This joins a NUMBER to a NAME. It
  decodes no payload, and the 297 streams keep their addresses for names.
* **That the WSA1 and KN5000 DSPs are the same silicon.** Identical data does
  not identify a part -- it identifies a shared *format*, which is what is
  claimed here and nothing more.

## 6. The recommended rename -- NOT APPLIED, and the reasons

| now | proposed | what supports it |
|---|---|---|
| `P7Byte_*` | **keep** | the transport really is a P7/P5/P2/PB/P9 handshake and the port number is an instruction operand. `P7` is the honest name for the wire. |
| `P7Unit_*` | `EffSlot_*` | §4: a unit is an effect slot; `P7Unit_` = per-slot accessor (arg1 = slot) |
| `P7Units_*` | `EffSlots_*` | `P7Units_` = broadcast / module lifecycle across all three |
| `P7Stream_*` | `DspEff_*` | §3, byte identity with the KN5000's `DSP_Eff*` objects |
| `PoolDir_RecordForUnitProgram` | `EffectNumberToRecord` | §2 |

Two reasons it was not done in the same pass:

1. **Rule: never rename in bulk.** 572 labels touched by a script, inside a
   commit that already moves 125,264 lines, produces a diff nobody can review --
   and this tree has already had to retract one bulk prefix (`TG_` -> `Dev10C_`,
   `notes/FINDINGS-prom_c-tone-generator.md`).
2. **The byte gate cannot see a wrong rename.** Labels assemble to addresses; a
   rename that is *semantically* wrong still rebuilds. The only check is the
   argument, and an argument is easier to review on its own.

★ If the rename is done, do it as one commit whose message enumerates the five
rows above, and run the byte gate. `notes/prom_c_split.py --verify` is pinned to
the pre-split commit and will report the rename as a change, which is correct --
retire it at that point.
