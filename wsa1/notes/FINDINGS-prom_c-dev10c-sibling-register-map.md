# Gap A: the KN5000 sub-CPU stages **the same 22 registers in the same order**, and names twenty of them — three of which this image now confirms on its own

Round 3, 2026-08-25, prom_c (IC28, CPU 2). Written against gap **A** of
`../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` — *"for at least one register block of
the device at CPU 2's 0x0010C000: what physical quantity does it carry?"*

Everything below is re-derived from `original_ROMs/wsa1_prom_c.ic28`, and from the KN5000
sub-CPU's own linked image, by

```
python3 notes/prom_c_reg0100_0140_checks.py --selftest   # 3 negative controls, FAILURES: 0
```

The conversion itself is certified by `python3 scripts/analysis/assert_byte_identical.py`.

---

## 0. What is **not** established

* **That register `0x0100 + chan` is a filter cutoff.** Nothing in prom_c or prom_d names
  it. What this image contains is a *pair* of registers, a *field split*, and the bounds
  *36* and *120* — all measured. "TVF cutoff" is the **sibling project's** word, adopted
  here as a labelled hypothesis with the calibration in §2, never as a decode.
* **That the two chips are the same silicon.** The KN5000's tone generator is IC303 behind
  a two-port window at `0x100000`/`0x100002`; this machine's is a 22-register-per-channel
  device at `0x0010C000`. What is measured is that **the register NUMBERING is the same**.
* **Byte identity.** The three counterpart routines are *not* byte-identical — 19/20,
  100/102 and 116/120 of the bytes they share differ (§3). Nothing here is a transplant.
* Anything about the twin device at `0x00104000`. Both devices have registers `0x0040`,
  `0x0080` and `0x0100`; this note is `0x0010C000` only, reached through the staging struct
  at RAM `0x00D75E`. This tree has already had to retract once over exactly that confusion.

---

## 1. The correspondence, machine-checked

`Dev10C_WriteAllChanRegs` (`0xFB713A`) moves 22 words from RAM `0x00D75E` into 22 registers
of one channel. The KN5000 sub-CPU's `ToneGen_WriteVoiceParams` moves 22 words from RAM
`0x0451CC` into 22 registers of one voice, and its disassembly writes the map out
(`../kn5000-roms-disasm/v142/subcpu/kn5000_subprogram_v142.s:6938-6959`).

**The two lists of register numbers are identical, in the same order**, asserted by
section 5b of the checker (which parses the sibling's own comment block and compares it with
`notes/prom_c_dev10c_field_sources.py`'s `WORD2BLOCK`, so neither side is retyped):

```
0x000 0x040 0x080 0x0C0 0x100 0x140 0x180 0x400 0x440 0x480 0x4C0 0x500
0x800 0x840 0x880 0x8C0 0x900 0x940 0x980 0x9C0 0xA00 0xA40
```

That is a sparse set of 22 values out of 64 possible blocks, in one order, in two firmwares
for two different instruments. The sibling's map is itself well-provenanced: its header says
it was *"assembled from this file's own scattered annotations … plus a capture of every write
the chip receives over 1705 note-ons of the built-in demo, which agrees register by
register."*

| register | the sibling's name for it | this image, independently |
|---|---|---|
| `0x000` | control / gate | written with the literal `0x8100` on update, `0x7E00` on stop |
| `0x040` | recording selector, `(class << 12) \| entry` | key-zone record word 0; **bits 15..12 a field, 11..0 a payload** |
| `0x080` | output level + the 3-bit descriptor field | **OUTPUT LEVEL** bits 11..0 log2, **bits 14..12 a 3-bit field**, bit 15 the gate |
| `0x0C0` | coarse level + expression | — (only its stopped value, `0x0000`) |
| `0x100` | **TVF cutoff** | **a pair with `0x140`; bits 6..0 clamped to 36..120** (§3) |
| `0x140` | **TVF depth / bias** | the other half of that pair |
| `0x180` | **pan, `0x0040` = centre** | write side: a 0..0x7F value, `0x80` selects a random one (§4) |
| `0x400` | absolute log pitch | **PITCH**, 1/256 semitone, saturated to notes 0..127.996 |
| `0x440` | *(unnamed there too)* | — |
| `0x480` | *(unnamed there too)* | — |
| `0x4C0` | oscillator config + slot | — |
| `0x500` | detune / bend pair | **byte pair; high byte through `DetuneCurve_LookupSigned`** (§4b) |
| `0x800` | amplitude envelope segment 0 | **(envelope level << 8) \| envelope rate** |
| `0x840` | amplitude envelope segment 1 | byte pair; quiescent `0xFF00` |
| `0x880` | amplitude envelope segment 2 | byte pair |
| `0x8C0` | amplitude envelope segment 3 | byte pair |
| `0x900` `0x940` `0x980` | second envelope, segments 0-2 | **byte pairs, all three from one routine** (`sub_FA842D`) |
| `0x9C0` `0xA00` `0xA40` | third envelope, segments 0-2 | **byte pairs, all three from one routine** (`sub_FA93AF`) |

---

## 2. ★ The calibration: five independent checks, five agreements, zero contradictions

The right question about a borrowed map is not "is it plausible" but "where this image has
its own answer, does the sibling agree?" It has five such answers, all from earlier rounds
and all derived without reference to the KN5000:

| # | this image's own finding | the sibling's name | verdict |
|---|---|---|---|
| 1 | `0x040` splits **4 bits over 12** (`Voice_SelectKeyZone_Reg0040`'s own `(word & 0xF000) < 0x6000` fix-up) | `(class << 12) \| entry` | **same split** |
| 2 | `0x080` = log2 level in bits 11..0 **plus a 3-bit field in 14..12** plus a bit-15 gate | "output level + **the 3-bit** descriptor field" | **same, including the odd 3-bit field** |
| 3 | `0x400` = pitch, 1/256 semitone | "absolute log pitch" | same |
| 4 | `0x800` = `(level << 8) \| rate` (from the four readers of `Voice_LevelPair_AttackCurve`) | "amplitude envelope segment 0" | same |
| 5 | the six curve-reading producers group **three and three**: `sub_FA842D` writes `0x900/0x940/0x980`, `sub_FA93AF` writes `0x9C0/0xA00/0xA40` | "second envelope, segments 0-2" / "third envelope, segments 0-2" | **same grouping** |

⚠ Row 5's grouping is about the two routines that read `Voice_EnvelopeLevel_Curve`. A
third writer, `sub_FC7FCA`, also fills `0x900/0x940/0x980` — all three with the *same*
value — and the shipped census cannot see it (§6). That does not disturb the 3-and-3
split; if anything "one routine sets all three segments of the second envelope at once"
is what the sibling's name predicts.

Check 2 is the load-bearing one: a 3-bit field wedged between a 12-bit level and a gate bit
is not a thing two projects guess the same way.

**So the sibling's map has a measured hit rate of 5/5 on this device** (6/6 once §4b is counted) and is adopted below
as a ranked hypothesis for the thirteen registers this image cannot yet answer for itself —
each with the test that would settle it.

---

## 3. ★★ What this round establishes on its own: `0x0100` and `0x0140` are a PAIR with a 7-bit field clamped to 36..120

Four routines stage these two words and **nothing else**, and every one of them writes
*both*:

| routine (was) | writes | how |
|---|---|---|
| `Voice_StagePair_Reg0100_0140_AB` (`sub_FA919B`) | words 4, 5 | six arms on `(voice[+0x17])[+0x36] & 7` |
| `Voice_StagePair_Reg0100_0140_CD` (`sub_FA92A5`) | words 4, 5 | the byte twin, on tone field **`+0x11`** |
| `Voice_StagePair_Reg0100_0140_First` (`sub_FA9081`) | words 4, 5 | offsets word 4 only |
| `Voice_StagePair_Reg0100_0140_Both` (`sub_FA9105`) | words 4, 5 | the same offset into both |

with `VoiceParam_DispatchOn_17_11`'s arm 0 as a fifth, verbatim, writer.

**The field split**, from the instructions — `and BC,0xFF80` appears seven times inside the
four stagers and nowhere else between `0xFA9081` and `0xFA93AE`: `0xFA90E3`, `0xFA9168`,
`0xFA917A`, `0xFA926B`, `0xFA927F`, `0xFA9375`, `0xFA9389`:

```
  register = (voice_word & 0xFF80) | Clamp_36_to_120( (voice_word & 0x7F) -/+ M )
  M        = (voice[+0x23])[+0x21]            a per-part byte
  sign     = SUBTRACT if bit 7 of (voice[+0x25])[+0x18], else ADD
  enable   = bit 6 of the same word; clear -> the voice word is copied verbatim
```

`Clamp_36_to_120` (was `sub_FA76B2`) is 36 bytes with exactly two comparisons, `cp HL,0x0078`
and `cp HL,0x0024`, both immediates. **All eight of its callers are on this path** — the four
stagers plus the two routines that build `voice[+0x3F]` / `voice[+0x41]`.

### The twins, diffed

`_AB` and `_CD` are 266 bytes each and **23 bytes differ**. Twenty-two of the 23 are
relocation: twelve are the six `u32` computed-goto entries, two are the table's own base
inside `add XWA,0x00fa91c6`, and eight are the displacement bytes of four `calr`/`jrl`. **The
one semantic difference is the tone-record field**: `ld A,(XBC+0x36)` at `0xFA91AA` against
`ld A,(XBC+0x11)` at `0xFA92B4`. The checker prints all 23 positions.

### And the sibling has the same three routines, not the same bytes

| this image | KN5000 sub-CPU | shared bytes | differing |
|---|---|---|---|
| `Clamp_36_to_120` `0xFA76B2` | `TVF_Clamp_Cutoff` `0x022BF2`, clamp `[0,120]` | 20 | **19** |
| `..._First` `0xFA9081` | `TVF_Emit_Offset_Reg100` `0x024366` | 102 | **100** |
| `..._Both` `0xFA9105` | `TVF_Emit_Offset_Both` `0x0243CC` | 120 | **116** |
| `..._AB` `0xFA919B` | `TVF_Emit_Registers` `0x024444` | — | different length |

Same algorithm, different code: this image passes arguments in a `link XIZ` frame and the
sibling in registers, and the two record layouts differ (`voice+66/+68/+35/+39` there,
`voice[+0x3F]/[+0x41]/[+0x23]/[+0x25]` here). What matches is structural and exact:

* the same two flag bits, 6 (enable) and 7 (sign), of the same field of the same record;
* the same `0x7F` extract, the same `0xFF80` merge, the same clamp with the same **upper**
  immediate `0x78` (the floor differs: 36 here, 0 there);
* the same three variants — verbatim / offset the first / offset both — reached from a
  six-case dispatcher on the tone record's `&7` field, with the same case roles;
* the same pair of destination registers, `0x100` and `0x140`.

**Therefore**: the sibling's `0x100` = *TVF cutoff*, `0x140` = *TVF depth / bias* is a
hypothesis with a 5/5 calibration behind it and a routine-for-routine match in front of it.
It is written into the source as the sibling's word, with this caveat, and the routine names
in `prom_c/wsa1_prom_c.s` state the **register numbers**, not the quantity.

---

## 4. `0x0180`: the sibling says PAN, and it explains an idiom this tree had already measured

The write side of `0x0180 + chan` is `voice[+0x27]`, staged by `sub_FA96F7` on the C/D path
(`0xFA9809`) and by `sub_FA9C60` on the A/B path (`0xFA9F0E`). **Both test the same tone-record
byte against the same sentinel, and both answer `0x80` with a random 0..0x7F**:

```
  sub_FA96F7, 0xFA9781-0xFA97FE:
      p = (voice[+0x17])[+0x01]
      if p == 0x80:                                   voice[+0x27] = Rand & 0x7F
      elif (voice[+0x25])[+0x1A] & 0x40:              voice[+0x27] =
              Clamp_ToRange_LowByte( p -/+ (voice[+0x23])[+0x25], hi = 0x7F, lo = 0 )
              with SUBTRACT chosen by (voice[+0x25])[+0x1C] & 0x40
      else:                                           voice[+0x27] = p

  sub_FA9C60, 0xFA9ECC-0xFA9F03:
      p = (voice[+0x17])[+0x01]
      if p == 0x80:  voice[+0x27] = (Rand & 0x7F)          | high-byte flags
      else:          voice[+0x27] = (voice[+0x25])[+0x27]  | high-byte flags
```

where `Rand` is `Rand_FromTickSquared` with bit 7 cleared (`res 7,A` at `0xFA978F` and
`0xFA9EDF`), and the "high-byte flags" are the word `sub_FA9C60` accumulates in `(XIZ+0xfa)`.

A parameter whose range is **0..0x7F** (the `hi = 0x7F, lo = 0` pair pushed at `0xFA97BD`
/`0xFA97C0`), whose **`0x80` encoding means "choose one at random"**, and which is offset
either way about its middle by a per-part byte, is what a pan control is — and the sibling states `0x0040 = centre`, the middle of 0..0x7F. `Rand_FromTickSquared`
(was `sub_FA7F04`) is `((tick × tick) >> 2) & 0xFF` over the free-running INTT1 counter at
`0x00F2F3`.

⚠ **The READ at block `0x0180` is a different quantity from the write** — this tree measured
that before it had a name for either: the read is masked `& 0x3FFF`, shifted right 5 and
truncated, i.e. **bits 12..5**, and the firmware retires nothing on it but hands the record to
`sub_FA65BD` when it falls below `0x80` (`notes/FINDINGS-prom_c-voice-readback.md` §3). A
7-bit pan write and a 14-bit falling read do not line up, and this note does **not** reconcile
them. Gap F's stub should keep answering the read side on its own terms.

---

## 4b. ★ `0x0500 + chan` — the test in §5 was run, and it agrees

The sibling calls `0x500` the *detune / bend pair*. In this image the only producer that
**computes** the register rather than clearing it is `Voice_StageRegs_0500_08C0_AB` (was
`sub_FA95D4`), and it assembles it as a byte pair:

```
  hi = Clamp_ToRange_Word( sub_FA75BA(tone[+0x12], voice[+0x0C], 6)
                           + DetuneCurve_LookupSigned(...), 0, 0x7F )
  lo = Clamp_ToRange_Word( sub_FA75BA(tone[+0x48], voice[+0x0C], 6) + 0x7F, 0, 0x7F ) & 0xFF
  word 11 = (hi << 8) | lo                 `sll 0x08,WA / or WA,BC`, 0xFA96AB-0xFA96B0
```

It is one of only four routines in the image that call `DetuneCurve_LookupSigned` (here at
`0xFA961F` and `0xFA9676`), and **the low byte is cached per voice**: `0xFA960D` hands it to
`sub_FC810C`, which stores it at RAM `0x00E1DD + voice[+0x00]`; `sub_FA96F7` clears that slot
on the C/D path and `sub_FC7FCA` reads it back and ORs it into the same register field
(`0xFC80D6`). So: **a byte pair, high byte through the detune curve** — which is what "detune
pair" predicts. "Bend" is not asserted. Checker section 6.

That makes the calibration **six of six**.

## 5. The twelve still open, ranked by what would settle them

| register | the sibling says | the test this image can run |
|---|---|---|
| `0x4C0` | oscillator config + slot | `sub_FA9F19` writes it with the literal `0x4400` and then ORs bits in (`0xFA9F20`, `0xFA9FEE`) — a config word's shape |
| `0x0C0` | coarse level + expression | two producers, `sub_FAA0BC` / `sub_FAA1A5`; expression is MIDI CC 11, whose part field `+0x0E` is already named |
| `0x440` `0x480` | *unnamed in both* | four and three producers; nobody has a name for these |
| `0x840` `0x880` `0x8C0` | amplitude envelope segments 1-3 | already known to be byte pairs; check the low byte against `Voice_EnvelopeRate_Table` as segment 0's was |
| `0x900`…`0xA40` | second / third envelope | already known to be two groups of three byte pairs from one routine each |
| `0x000` | control / gate | write-only here; `0x8100` and `0x7E00` are its only two values |

---

## 6. What the emulator can do with this

`wsa1.cpp`'s `tg_data_w()` can now label 7 of the 22 per-channel registers rather than 4:

* `reg[0x0100 + ch] & 0x007F` and `reg[0x0140 + ch] & 0x007F` are a **paired 7-bit control in
  the range 36..120**, bits 15..7 being a separate field the firmware never modulates. Log
  them as a pair; the sibling calls them filter cutoff and its depth/bias.
* `reg[0x0180 + ch] & 0x007F` is a **7-bit position with 0x40 as its centre** — pan, on the
  sibling's word — and `0x80` in the tone record randomises it per note, so two identical
  note-ons will differ in this register alone.
* `reg[0x0500 + ch]` is **two independent bytes**, the high one detune-curve derived.
* The four already named (`0x0040`, `0x0080`, `0x0400`, `0x0800`) are unchanged.

⚠ And the **producer index those decodes are navigated by is incomplete**: see
`notes/prom_c_staging_producer_audit.py`, which finds 17 write sites the shipped census
cannot see — including one, `Word_AddTickLow3`, that adds `tick & 7` to register `0x0040`'s
word on the D staging path only.
