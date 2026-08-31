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
are `< 100`, and `EffectParamNames` has exactly 100 rows. A random byte is < 100
with probability 0.39.

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

* **Only byte 0 of each four-byte descriptor group is decoded**, because it is
  the only one `0xF10FF1` reads. `--raw` prints the rest. `CHORUS`'s descriptor
  is `01 01 01 00 | 19 01 02 01 | 1A 06 03 02 | 1B 07 04 FF | 04 01 05 04`, and
  the guess that byte 1 selects one of the 18 value-name lists at `0xF157A8`
  (`LFO WAVEFORM` has byte 1 = 7, `WET` has 1) is a **guess** and is written
  down as one.
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
