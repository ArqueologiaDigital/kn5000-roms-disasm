# The port-P7 five-byte GROUP, and what lane w17/p7-dsp named

*Measured 2026-09-03 in `wsa1/prom_c/p7/`.  Regenerate every number; do not retype it:*

```
python3 notes/p7_group_template_probe.py --verify   # the group, the commands, the tables
python3 notes/p7_sub_classify.py                    # entry points vs continuations
make LLVM_MC=.../llvm-mc.snap gate-all              # 13/13 byte-identical, 8/8 assembling
python3 scripts/analysis/assert_comments_preserved.py --base main wsa1/prom_c/p7/*.s
```

---

## 0. What is NOT claimed

* **Which chip is on the other end of P7.** Unchanged from every earlier round. The port
  is an instruction operand; the destination is a number 0/1/2 that arrives in a data
  record. Three destinations and three uPD6383GF DSPs is consistent and is not proof.
* **What any value means in engineering units.** This pass decodes a *container* one
  level further down. No byte acquired a musical or physical meaning.
* **The second consumer.** Already found, by `notes/prom_c_fcd0f7_interpreter.py`. It is
  re-measured here only because §2 depends on it; the finding is that note's.

## 1. The new fact: the module has two ways to say the same thing

`P7Stream_Run` replays a canned stream from the pool. A family of small routines at
0xF9AEB6-0xF9B54A instead *computes* a value in floating point and sends it. **They emit
byte-for-byte the same five-byte groups.**

```
ADDRESS group, opcode-0 form   00 00  0x10+((A>>4)&0x0F)  (A<<4)&0xF0  00
ADDRESS group, opcode-1/5 form 08 01  (A>>4)&0x0F         ((A<<4)&0xF0)+8  0x21 / 0x25
VALUE   group                  0A  (v>>17)&0x7F  (v>>9)&0xFF  (v>>1)&0xFF  ((v<<7)&0x80)+K
```

Measured over the 2,633 groups in the pool's whole-group opcode-0/1/5 records:

| claim | measured | null | grade |
|---|---|---|---|
| every opcode-1 record is one `08 01` address group ending **0x21** | 99 / 99 | 0.39% per fixed byte | **PROVEN** |
| every opcode-5 record opens with an `08 01` group ending **0x25** | 81 / 81 | 0.39% | **PROVEN** |
| every opcode-0 value group's tail is **K = 0x15** | 963 / 963 | 0.78% per fixed 7-bit tail | **PROVEN** |
| every opcode-5 value group's tail is **K = 0x4C** | 1,036 / 1,036 | 0.78% | **PROVEN** |
| opcode-0 records never use the `08 01` form | 0 / 1,417 | — | **PROVEN** |
| opcode-1 and opcode-5 records all open `01 01 60` | 180 / 180 | — | **PROVEN** |

0x21, 0x25, 0x15 and 0x4C are *instruction immediates* at 0xF9B2E5, 0xF9B49F, 0xF9B156 and
0xF9B53A. The pool and the code were not compared through any intermediate model.

**Phase control.** Re-cutting the same payload bytes at every other head offset drops
"0x0A first" from 68.0% (opcode 0) and 92.7% (opcode 5) to **0.4%**. So the framing
carries information; it is not a pattern any cut would find.

**And that pins each global to an opcode** — the tail constant is the witness, because
each emitter reads exactly one base:

| global | is record byte | relocates | witness |
|---|---|---|---|
| 0x008614 | b0 | opcode 1 | its emitters push tail 0x21; 99/99 opcode-1 records end 0x21 |
| 0x008616 | b1 | opcode 0 | its emitters build the `00 00` form, which only opcode-0 records use; 310 of those 316 groups end 0x00 and 301 carry the `+0x10` the emitter adds |
| 0x008618 | b2 | opcode 5 | its emitter pushes 0x25; 81/81 opcode-5 records end 0x25 |
| 0x00861A | b4 | opcode 2 | enters a **value**, scaled by 256, not an address — 0xF9B4A5 |
| 0x00861C | b5 | — | the **destination**; 165 of its 170 occurrences are that argument |

which is the same b0/b1/b2/b4/b5 assignment `P7Stream_Run`'s header states for its *frame
slots*, reached from the other end. `P7Block_Run` copies the record into these globals with
the identical `6*index - 6` arithmetic (0xF9ADBA vs 0xF9A652). **STRONG.**

⚠ **K = 0x26 occurs in no canned stream.** The three emitters that use opcode 1's base
tail their value groups with 0x26, and the pool's opcode-1 records carry an *address* and
no value at all (0 of 99). The canned half supplies opcode 1's address and the computed
half its value. Stated because the wrong reading — "0x26 is a mis-decode" — has to be ruled
out, and it is: 0x26 is an immediate at 0xF9B36D, 0xF9B27A and 0xF9B434.

## 2. The command set is bigger than the code makes it look

A command is a byte sent with P5.3 low. **21 call sites; 14 carry a literal, and the
literals are only `0x01` (opens, 8 sites) and `0x03` (closes, 6).** The other seven are
`P7Stream_Run`'s opcode arms, which take the byte *from the stream* — so the pool decides.
Read out of the pool: **34 distinct command bytes**, including 0x02 (all 99 opcode-2
records), 0x0F (6 opcode-4 records) and a band filling 0x61..0x79 with no gap.

So "the device has a resident command set {0x01, 0x02, 0x03}" is **the record layer's
vocabulary, not the device's**, and the honest statement is 2 literals in code against 34
bytes in the data. **PROVEN** (exhaustive enumeration, not a sample).

⚠ Six of the eight opens are closed in the same routine. **Two are not**: 0xF9FA3A in
`sub_F9F9FA` and 0xF9FBE9 in `sub_F9FBA9`. Both are called only from `sub_FA237C`, so the
close is the caller's or there is none. **UNIDENTIFIED**; it is one reason those two keep
their addresses.

## 3. The value tables measure themselves

`P7Unit_SendValueTable` (0xF9F765) reads one of three tables installed by
`P7Unit_SelectStreamsForRecord`, four 24-bit big-endian values at a time, and takes the
length from `(0x00F365/67/69)`. If that word is the payload length, each table must be
exactly `1 + length` bytes. **All seven are — 7 of 7.** The four that take 99 are 100-byte
objects ending on the next pool object; the three that take 0x6C are 109 bytes each and
*tile* one 327-byte object exactly. Nothing forces a data object in a 65,972-byte pool to
any particular size. **STRONG.**

## 4. What was named, and what was refused

**14 labels renamed** (code only; see §5). `P7Block_Run`, `P7Block_Seek`,
`P7Block_ReportStatus`, `P7Unit_SendValueTable`, and the seven-strong `P7Group_Send*`
family with three continuations.

**Six named in the header but NOT renamed**, because a citation lives in a file this lane
may not write and a rename must update every reference tree-wide:

| label | proposed | blocked by |
|---|---|---|
| `sub_F9E0B7` | `P7Block_FindByTag` | `prom_c/data_tables/touch_eq_mixer.s` |
| `sub_F9B54B` | `P7Block_EmitItems` | its continuations, cited in `prom_c/mathlib/mathlib.s` |
| `sub_F9A86B` | `P7Stream_Run__F9A86B` | `notes/sound/dsp_protocol_cross_product.py` |
| `sub_F9AB2A` `sub_F9ACCE` `sub_F9AD65` | `P7Stream_Run__XXXXXX` | held with `sub_F9A86B` for family consistency |

A lane with write access to those three files can finish it with the map in §5 plus
`P7Stream_Run__` for the four continuations.

**Nineteen refused**, with what each would take, in section I of `p7_module.s`'s added
banner. Two shapes dominate: the four big floating-point kernels (2,676-9,073 bytes) that
compute the values, which need the values' engineering meaning; and `sub_FA362C` /
`sub_FA3717`, a fully readable pair of twins separated only by which literal stream each
picks — where the only available names would be positional, which is the wrong kind.

## 5. The rename map

```
0xF9ADB5  sub_F9ADB5 -> P7Block_Run                        0xF9B32C  -> P7Group_SendOp1AddrValue__F9B32C
0xF9AEB6  sub_F9AEB6 -> P7Group_SendOp0AddrValueScaled     0xF9B37E  -> P7Group_SendValueScaled
0xF9AFDC  sub_F9AFDC -> P7Group_SendOp0AddrValue           0xF9B445  -> P7Group_SendOp5AddrValue
0xF9B0D1  sub_F9B0D1 -> P7Group_SendValue                  0xF9E140  -> P7Block_Seek
0xF9B167  sub_F9B167 -> P7Group_SendOp1AddrValueScaled     0xF9E1AC  -> P7Block_ReportStatus
0xF9B28B  sub_F9B28B -> P7Group_SendOp1AddrValue           0xF9F765  -> P7Unit_SendValueTable
0xF9B2EE  -> P7Group_SendOp1AddrValue__F9B2EE
0xF9B305  -> P7Group_SendOp1AddrValue__F9B305
```

⚠ **Only CODE was rewritten.** Every existing comment is byte-identical to `main`, which
`scripts/analysis/assert_comments_preserved.py` requires, so the banner line over a renamed
routine still spells its old `sub_XXXXXX` and each header carries a `★ RENAMED` block
saying so. That is the same discipline the extraction header already applies to its own
stale line.

## 6. A comment this pass believes is WRONG, and did not edit

`prom_c/p7/p7_stream_pool.s`, in the banner's `⚠ WHAT IS NOT ESTABLISHED`:

> "130 of the 297 streams contain at least one record whose payload is NOT a whole number
> of the interpreter's groups. Those streams cannot be what `P7Stream_Run` runs, so a
> SECOND consumer exists **that this pass has not found**."

The second consumer **has** been found since — `notes/prom_c_fcd0f7_interpreter.py`, which
names 0xF9ADB5 (now `P7Block_Run`) and its framer 0xF9E140 (now `P7Block_Seek`), and shows
the 130 sorting perfectly by which directory field a stream sits in. The paragraph is left
exactly as written and annotated in place; correcting it belongs to whoever adjudicates.

## 7. What would settle the next thing

* **The 0x61..0x79 command band.** 25 consecutive values, only in opcode-0 records, and
  nothing in this module correlates with them. They need the device side, not more of this
  ROM — the KN5000's DSP microprogram corpus is the one place a comparison is possible.
* **`sub_FA362C` / `sub_FA3717`.** Six literal streams, three per routine, at adjacent
  addresses. Whichever of those six turns out to be identifiable in the KN5000 corpus names
  both routines at once.
* **The two unclosed 0x01 records** in `sub_F9F9FA` and `sub_F9FBA9`: reading
  `sub_FA237C`'s 766 bytes settles whether it closes them.
