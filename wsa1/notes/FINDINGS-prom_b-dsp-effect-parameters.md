# EffectNames entry *k* IS effect algorithm *k* — closed, with a partition control

*prom_b lane, wave 8, 2026-08-31. Byte gate passes.*

```
python3 notes/prom_b_effect_param_map.py            # all 56 effects and their parameters
python3 notes/prom_b_effect_param_map.py --raw      # the descriptors, undecoded
python3 notes/prom_b_effect_param_map.py --selftest # 20 checks, 3 of them controls
```

## 1. Two headers that each admitted they could not close

`EffectNames_F147AC` (128 x 16 ASCII, 56 real names and 72 `----------`
placeholders):

> ⚠ Unknown: that entry k is effect algorithm k. The block at
> 0xF0EA9F-0xF13D33 has three 128-entry tables indexed from (0x2796);
> **128 and 128 is a CORRESPONDENCE, not a decoded fact.**

`DataPtrTable_F12F24` (128 `.long`, 57 distinct):

> Unknown: what indexes it, and what the entries mean.

The second is the answer to the first.

## 1b. ★ PRIOR ART — half of this chain was already established, in round 4/5

Grepped before writing, per the lane rule. `notes/FINDINGS-prom_b-f0ea9f-module.md`
(§2.1 and §3, and `notes/gen_prom_b_f0ea9f_module.py`) already had:

* the indexer itself — *"`0xF10609 mul WA,(0x2796)` / `0xF1060F add
  XWA,0x00f12f24  ; &Table128[(0x2796)]` / `ld XWA,(XWA)` / `ld H,(XWA)`"* — and
  the classification that follows from it, **DEREF**: the entries are DATA
  pointers, so they must not seed the code walk. That rule is what stopped the
  4-byte descriptor records at `0xF124EC-0xF12EE4` being decoded as instructions,
  which an earlier round had done;
* that those records exist and where they live (`notes/prom_b_screen_arrays.py`
  censuses *"0xF124EC-0xF12F23 (the arrays the 0xF12F24 pointer table names)"*);
* `EffectNames_F147AC`'s 128 x 16 tiling and its 56/72 split
  (`notes/gen_prom_b_effect_tables.py`);
* `EffectParamNames_F15024`'s 17-byte row stride and its 113-row extent;
* and the refusal — *"128 names and 128 entries … is **not** proof that the index
  is the effect-algorithm number"*.

**What is new here is only the last step**, and it is the step that turns the
correspondence into a decode: that the two 56/72 partitions are the SAME
partition, that descriptor byte 0 is a row of `EffectParamNames`, and that the
0x78 bytes at `0xF14FAC` are the eight records that draw them. Everything the
argument stands on below the join was already in the tree.

## 2. The chain

**`DspEffect_LoadParamNames`, prom_b 0xF10FF1** — until this round `sub_F10FF1`:

```
	ld C,0x04
	mul BC,(0x2796)		; F10FFC   BC = 4 * (0x2796)
	ld XIX,XBC
	ld A,0x04
	mul WA,(0x2792)		; F11006   WA = 4 * (0x2792)
	...
	lda XWA,0xf12f24	; F11017   the pointer table
	add XWA,XIX		;          + 4 * (0x2796)
	ld XIY,(XWA)		; F1101E   DEREFERENCE -> this algorithm's descriptor
	add XIY,XBC		;          + 4 * (0x2792)
	ld E,(XIY)		; F11022
	ld (XBC+0x2640),E	; F1102A   store byte j at (0x2640 + j)
	...			;          eight times, source stepping by 4
	lda XBC,0xf15024	; F1103F   push EffectParamNames_F15024
	lda XWA,0xf14fac	; F11045   push the display list
	call 0xf42e04		; F1104B   run it
```

and the display list it runs, **0xF14FAC-0xF15023**, is `0x78` bytes — *exactly*
eight interpreter-B records of fifteen. Each one is

```
	.byte 0x02, 0x0F	; opcode 2, 15 bytes
	.short 0x2640+j		; +0x02 source variable
	.byte 0xFF		; +0x04 mask -- the whole byte
	.byte 0x00		; +0x05 shift
	.byte 0x20		; +0x06 swi 7 function = LCD_Svc_20_DrawText8x10
	.long 0x00F15024	; +0x07 table base = EffectParamNames_F15024
	.short 0x0011		; +0x0B entry width = 17
	.short <cursor>		; +0x0D
```

The eight bytes the routine writes are the eight the records read, and 17 is the
row stride `EffectParamNames_F15024`'s own header already states. The eight
cursors are 640 apart — 16 display lines of AP = 40 bytes — so the rows are at
**x = 72, y = 74, 90, 106, 122, 138, 154, 170, 186**.

So: **descriptor byte `4*j` is the row of `EffectParamNames` that names the
effect's j-th parameter**, and the table at `0xF12F24` is indexed by the effect
algorithm number in `(0x2796)`.

## 3. ★ The control is an identity of PARTITIONS, not a pair of equal counts

The old header was right to refuse "128 and 128". This is a different shape of
evidence.

```
pointer table 0xF12F24 : 128 entries, 57 distinct
                         56 pointers used once, ONE (0xF124EC) used 72 times
EffectNames_F147AC     : 56 real names, 72 `----------` placeholders

the 72 slots that SHARE the pointer  ==  the 72 slots that carry the placeholder
symmetric difference: EMPTY
```

Two 56/72 partitions of `0..127`, derived from a pointer table and from a string
table that share no bytes, and they are the *same partition*. There are
C(128,72) ≈ 10³⁷ ways for that to have failed.

**A second, independent control:** all 8 × 57 = **456** decoded descriptor bytes
land in rows **0-99** of `EffectParamNames`, and rows 0-99 are exactly its
PARAMETER-LABEL rows — 99 of those 100 end in `:`, row 0 being the blank, while
rows 100-112 do not. A random byte is < 100 with probability 0.39, so 456 of 456
is 0.39⁴⁵⁶, and not one lands in the 13 rows that are not labels.

⚠ **CORRECTED the same day.** This paragraph first said *"`EffectParamNames` has
exactly 100 rows"*. It does not: `FINDINGS-prom_b-f0ea9f-module.md` §4b already
states its tiling as **113 rows of 17** covering 1,921 of 1,924 bytes, with *"99
of the first 100 rows end in `:`"*. The control is sharper stated correctly, but
the wrong number was quoted first and is recorded rather than quietly replaced.

**And a semantic one**, which is not a proof but is what a reader will check
first — the parameter lists read correctly for the effect they belong to:

| effect | parameters |
|---|---|
| `DISTORTION` | WET, DRIVE, ADJUST, VOLUME |
| `CHORUS` | WET, DEPTH, LFO SPEED, LFO WAVEFORM, VOLUME |
| `FLANGER` | WET, DEPTH, LFO SPEED, RESONANCE, MANUAL, PHASE, LFO WAVEFORM, VOLUME |
| `GATED REVERB` | WET, GATE TIME, HIGH DAMP GAIN, THRESHOLD, MASK TIME, VOLUME |
| `ROOM REVERB 1` | REVERB TIME, PRE DELAY, HIGH DAMP GAIN, EARLY REFL LEVEL, VOLUME |
| `COMPRESSOR` | WET, THRESHOLD, RATIO, ATTACK SENS., RELEASE SENS., VOLUME |
| `S.DELAY+CHORUS` | DELAY WET, DELAY L, DELAY R, FEEDBACK L, FEEDBACK R, CHORUS DRY/WET, DEPTH, LFO SPEED |

`NO OPERATION` (program 0) and all 72 placeholders share the catch-all
descriptor, whose eight indices are all 0 — row 0 of `EffectParamNames` is
blank. The one effect with a real name that has no parameters is the one that
should have none.

## 4. What this joins to

Lane A4's `FINDINGS-prom_c-p7-is-dsp-effects.md` showed that prom_c's
`PoolDir_RecordForUnitProgram` (0xFDC551) maps a P7 "program" 0..127 to a pool
record, that the 56 programs with a real name in prom_b take **56 distinct**
records, and that the 72 placeholders all take the catch-all. That is the *same
56/72 partition again*, now found for the third time in a third table, in the
other processor's EPROM.

So a P7 unit block's byte +0 is the effect algorithm number, its name is
`EffectNames_F147AC[k]`, and its parameter list is
`EffectParamDescriptors_F12F24[k]`.

## 5. ⚠ What is NOT claimed

* Bytes 1 and 3 are decoded in section 6 below; **byte 2 is not**. `--raw`
  prints the descriptors whole.
* **The number of parameters per effect** is bounded here by the next
  descriptor's address, not by a terminator this note trusts. The gaps between
  the 57 descriptors are 40 bytes in 38 cases and up to 84, so descriptors run
  to about ten and at most twenty-one groups; the routine only ever loads eight.
* **`(0x2792)` is not identified.** It offsets the eight-byte window into a
  descriptor longer than eight, so "scroll position" is the obvious reading and
  is not asserted.
* **`EffectNames_F147AC` still has no reader.** Its header's
  `Read by: NOTHING in prom_a or prom_b spells 0x00F147AC in a decodable
  operand` is unchanged and was re-checked. The join above runs entirely through
  `0xF12F24`; whatever draws the effect's *name* is still unfound.

⚠ **A correction to the brief that sent this lane here.** It said the 128 names
at `0xF147AC` are "the strongest naming evidence available anywhere in this
project" and that "whatever in prom_b indexes or renders that name table can be
named with confidence". Nothing indexes that table in any decodable operand, so
nothing could be named from it directly. What could be named — and was — is the
routine that indexes the table *next to* it.

## 6. The descriptor's other bytes, and the value lists — added the same day

`DspEffect_PaintParamEditor` (prom_b 0xF11057, until this round `sub_F11057`)
paints the page `DspEffect_LoadParamNames` labelled. It makes the *same*
descriptor fetch — `lda XIX,0x2796` (0xF1107A), `ld A,(XIX)` (0xF11096),
`mul A,4`, `add XWA,0x00f12f24`, `ld XWA,(XWA)` — and then, per screen line,
with `C = (0x2792) + E` the parameter index and `XBC = 4*C` the group:

| byte | what the code does with it |
|---|---|
| `+0` | the parameter NAME row — read by `DspEffect_LoadParamNames`, drawn by `DL_EffectParamPage` |
| `+1` | written to `(0x2640)` (0xF110AC); `4 * byte1` indexes the 32-entry arrays at `0xF13264` (0xF110EA, jumped to at 0xF110F8) and `0xF132E4` (0xF110FA), and **that** entry `+ 15*line` is the interpreter-B record that draws the VALUE |
| `+2` | pushed at 0xF110DF for the handler jumped to above. **Not decoded.** |
| `+3` | compared at 0xF1112B against the byte `IndexedTable_GetByte` returns for `0x61 + (0x2797)`; equal writes 1 to `(0x2640)`, `0xFF` writes 0, otherwise 2, and a record from the SECOND group of `DLB_Records_F157A8` (0xF15820) draws that — the cursor marker |

The line loop is `add H,0x0F` / `inc 1,E` / `cp H,0x69` / `jrl ULE`
(0xF1115F-0xF11168), so `H` runs 0, 15, 30 … 105: **eight lines**, the same
eight `DL_EffectParamPage` names.

### 6.1 This half-answers a stated Unknown in the value-list block

`notes/gen_prom_b_dsp_value_lists.py` emits, on each of the 18 record arrays at
`0xF157A8`:

> Unknown: which effect parameter occupies which line, and — where there is more
> than one group — what selects between them. The caller adds a byte offset, so
> `15 * (8*group + line)` reaches any of them, but **nothing converted here
> computes that offset**.

It is computed, in `DspEffect_PaintParamEditor`, and the answer is that *the
effect chooses*: descriptor byte `4*p+1` picks the array through `0xF132E4`, and
the line is the parameter's position on the page.

⚠ **Still open:** what selects a record GROUP above 0. This loop never exceeds
offset 105, so it only ever reaches group 0 of a 16- or 32-record array. Group 1
of `DLB_Records_F157A8` is separately reached, at `0xF15820`, and it is the
cursor marker.

The generator's text and the 18 copies of it in `prom_b/wsa1_prom_b.s` were
corrected **together**, in the same commit, so that regenerating reproduces what
is in the source; `python3 notes/gen_prom_b_dsp_value_lists.py --selftest` still
passes 105 checks and the byte gate still passes.
