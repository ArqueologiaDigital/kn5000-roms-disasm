# Gap A, three registers NAMED: `0x0400` is the pitch, `0x0080` is the level, `0x0040` is the key-zone word

> ★★ **SUPERSEDED IN PART, 2026-08-25 (round 3).**  `0x0100` and `0x0140` are now
> established as a PAIR carrying a 7-bit field clamped to 36..120, and `0x0180`'s WRITE
> side is decoded; the KN5000 sub-CPU is shown to stage **the same 22 registers in the
> same order**, which puts a name on those three and a calibrated hypothesis on ten more.
> Section 0's "six registers now have no statement of any kind" is now **four**:
> `0x0440`, `0x0480`, `0x04C0`, `0x0500`.  See
> **`notes/FINDINGS-prom_c-dev10c-sibling-register-map.md`** and
> `python3 notes/prom_c_reg0100_0140_checks.py --selftest`.

Round 7, 2026-08-25, prom_c (IC28, CPU 2).  Written against gap **A** of
`../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md`, which says in as many words what the
previous round left open:

> *"Located, not named."*  Every producer in that index is a bare `sub_XXXXXX` label.
> **Not one register in this device is called pitch, level, wave address or anything else.**

Three of its twenty-two per-channel registers are now called something, one more has its
quiescent value pinned, and the two remaining questions gap A asks are answered in full for
question 1 and in part for questions 2 and 3.

Everything below is re-derived from `original_ROMs/wsa1_prom_c.ic28` by

```
python3 notes/prom_c_dev10c_meaning_checks.py        # 15 sections, FAILURES: 0
```

which reads **bytes**, never `prom_c/wsa1_prom_c.s` and never unidasm's text.  The conversion
itself is certified by `python3 scripts/analysis/assert_byte_identical.py`.

---

> ★★ **SUPERSEDED IN PART, 2026-08-25 (round 2).**  Section 0's first bullet is no longer
> true of seventeen registers: `0x0800 + chan` is now named **(envelope level << 8) |
> (envelope rate)**, the whole block group `0x20-0x29` is established as **byte pairs**, the
> READ at block `0x0000` index 0..3 is established as a **16-channel busy bitmap** and the
> READ at `0x0180 + chan` as a **falling magnitude with a retirement threshold**.  Six
> registers now have no statement of any kind: `0x0100`, `0x0140`, `0x0440`, `0x0480`,
> `0x04C0`, `0x0500`.  See **`notes/FINDINGS-prom_c-voice-readback.md`**,
> `python3 notes/prom_c_voice_sweep_checks.py`, `notes/prom_c_reg_bytepair_check.py` and
> `notes/prom_c_curve_table_census.py`.  Everything else in this file stands.

## 0. What is NOT established

* **Seventeen of the twenty-two per-channel registers still have no meaning.**  ⚠ SUPERSEDED
  — see the note at the head of this section; the figure is now six.  This note names
  three and gives a fourth and fifth their power-on value.  Nothing here says what blocks
  `0x00C0`, `0x0100`, `0x0140`, `0x0180`, `0x0440`-`0x0500`, `0x08C0`-`0x0A40` carry.
* **The 3-bit field in bits 14..12 of register `0x0080`** is measured (it tiles the register
  with the level and the gate, and its note-derived form is an eight-step staircase per
  octave) and is **not named**.
* **"Wave" is not asserted anywhere.**  Register `0x0040` carries the first word of a record
  the played note selects; that the record is a SAMPLE is an inference, flagged as one in §4.
* The MIDI *roles* of controllers 1, 2, 4, 10, 16-19, 64, 91, 93 and 94.  Their **numbers** are
  instructions; the roles are the MIDI specification's.  Only 7 (volume), 64 (the switch
  threshold) and 120 (all sound off) are corroborated inside this firmware.
* Why the key-follow reference pitch is note **66**.

---

## 1. The lever that opened it: a MIDI controller dispatcher with the standard numbers

`MidiCtrl_Dispatch` (was `sub_FAFDA5`, `0xFAFDA5`) takes an internal 4-byte message —
`[0]` status, `[1]` part index, `[2]` controller number, `[3]` value — and selects on byte `[2]`
through a chain of `cp BC,imm / jrl Z`.  Walking those bytes gives **twenty-six** arms
(`--` section 1 extracts all 26 with their `cp` sites and asserts the last one, controller
`0x9C -> 0xFB0003`).  Seventeen of the numbers are below `0x80`:

```
1  2  4  7  10  11  16  17  18  19  64  91  93  94  120  121  123
```

which is the standard MIDI controller allocation — modulation, breath, foot, **channel volume**,
pan, **expression**, general purpose 1-4, sustain, effect depths 1/3/4, and the three
channel-mode messages — **with no number in the list that is not in that allocation**.
Independently, `MidiMsg_SendBootSequence` hands this same routine the literals `B0 00 07 00` and
`B0 00 78 7F` (`FINDINGS-prom_c-voice-module.md` §2), i.e. controller 7 = volume and
controller 120 = all sound off spelled out in ROM.  The nine numbers `>= 0x80` cannot be MIDI
controllers at all; they are the firmware's own extensions and are named `MidiCtrl_IntXX`.

**That is what makes the rest possible**: a controller number is a name the MIDI standard
already gives, and following one to the register it ends up in names the register.

### The part record's controller-written fields

RAM `0x001523`, stride `0x012C` = 300 bytes, index `0..0x20`.  Every row is a
`mul BC,0x012C / add BC,<offset> / <store>` inside the named handler:

| ctrl | handler | field | width | stored |
|---|---|---|---|---|
| 7 | `MidiCtrl_CC07` | `+0x0B` | word | `Voice_CC_VolumeCurve[v]` |
| 10 | `MidiCtrl_CC10` | `+0x0D` | byte | `v` raw |
| 11 | `MidiCtrl_CC11` | `+0x0E` | word | `Voice_CC_VolumeCurve[v]` |
| 64 | `MidiCtrl_CC64` | `+0x09` | word | bit 0 set iff `v >= 0x40` |
| 91 | `MidiCtrl_CC91` | `+0x10` | byte | `v` raw |
| 93 | `MidiCtrl_CC93` | `+0x11` | byte | `v` raw |
| 0x80 | `MidiCtrl_Int80` | `+0x12` | byte | `v` raw |
| 0x81 | `MidiCtrl_Int81_FineTune` | `+0x13` | word | `(v - 0x80) * 2` |
| 0x82 | `MidiCtrl_Int82_Transpose` | `+0x15` | byte | `v - 0x40`, signed |
| 0x97 / 0x99 / 0x9A / 0x9B / 0x9C | `MidiCtrl_Int97…Int9C` | `+0x16…+0x1A` | byte | `v` raw |

★ **Six of those handlers are the same thirty bytes and differ in EXACTLY ONE**: the immediate
that names the offset (`0x0D`, `0x10`, `0x11`, `0x16`, `0x19`, `0x1A`).  Stated because this
tree's rule is to diff the bytes before calling two routines twins.

★ **Controller 64's threshold is 64.**  `cp (XIZ+0x0A),0x40` at `0xFAD81E`, `set 0,WA` above it
and `res 0,BC` below — the MIDI specification's own on/off point for a switch controller,
present as an immediate.

---

## 2. ★★ Register `chan + 0x0400` is the PITCH, in units of 1/256 semitone

The chain, all of it converted assembly:

```
MidiNote_Dispatch             note byte -> voice_record[+0x05]   (RAM 0x003BCF + 0x44*voice)
Voice_ComputePitch  0xFA7F28  -> voice[+0x06]  and voice[+0x08]
Voice_PitchAddZoneOffset_AB   -> voice[+0x0A] = Sat16(voice[+0x06] + (0x005A4F))
   (0xFA8323, and _CD 0xFA83A8 for the C/D staging routines)
Voice_StagePitch_Reg0400_AB   -> staging word 7 at RAM 0x00D76C
   (0xFA8347, and _CD 0xFA83CC)   = Sat16(voice[+0x0A] + (0x001503) [+/- part[+0x1D]])
Dev10C_WriteAllChanRegs       -> register chan + 0x0400          (0xFB71D4 / 0xFB71DD)
Dev10C_SetChanReg_0400        -> the same field, on its own, from the two controller-driven
                                 refresh loops at 0xFADD1A and 0xFADDB8
```

**The unit is fixed three times over, and two of the three are independent of each other:**

1. the accumulator is seeded `ld A,(XIX+0x05) / sll 0x08,WA / and WA,0x7F00 / add HL,0x0080`
   (`0xFA7F3A`-`0xFA7F4B`) — the note number times 256, centred half a step up;
2. `part[+0x15]`, which **`MidiCtrl_Int82_Transpose` writes as a signed SEMITONE count**
   (`v - 0x40`), is added **shifted left eight** (`0xFA7F5A`);
3. `part[+0x13]`, which **`MidiCtrl_Int81_FineTune` writes as `(v - 0x80) * 2`**, is added
   **unshifted** (`0xFA7F68`) — so that control's full swing, `+/-0x100`, is exactly one
   semitone.

`Sat16_0_to_7FFF` (was `sub_FA7570`) then clamps to `[0x0000, 0x7FFF]`, and
`0x7FFF / 256 = 127.996`: **the register's range is exactly the 128 notes.**

### What else goes into it

In order: `note*256 + 0x80`; the global word at RAM `0x001505`; `part[+0x15] << 8`;
`part[+0x13]`; the return of `0xFA72E9(voice[+0x04], (voice[+0x13])[+0x55])`; then **one** of
four key-dependent corrections selected by the byte at `0x00150A` (or by
`(voice[+0x13])[+0x13]` on the other arm):

| selector | correction |
|---|---|
| `0x40` | a pseudo-random detune, `(0xFA7F04() * 13) >> 7` |
| `0x41` | `Voice_KeyBend_Curve_0[pitch >> 8]` (`0xFDD3AB`, signed bytes) |
| `0x42` | `Voice_KeyBend_Curve_1[pitch >> 8]` (`0xFDD3AB + 0x80`) |
| else | a table at `0xFDF2C3` indexed by `12*H + note/12`, doubled |

and finally a **key-follow** stage with `H = (voice[+0x17])[+0x06] & 7`:

```
H == 7  ->  pitch = 0x4280                              (fixed pitch, no key tracking)
H != 7  ->  pitch = 0x4280 + ((pitch - 0x4280) >> H)    (the interval scaled by 2^-H)
```

`0x4280 = 0x4200 + 0x80` is this routine's own encoding of **note 66**, so 66 is the reference
the key-follow scaling pivots on.  ⚠ *Why* 66 is not established.

> The two bend curves were already proven to be bend curves twice — by this image's own reader
> (`index = pitch accumulator >> 8`, signed byte, added into the accumulator, `0xFA8016`) and by
> byte identity with the KN5000 sub-CPU's two s16 bend tables.  See
> `Voice_KeyBend_Curve_0`'s header in the source.

---

## 3. ★★ Register `chan + 0x0080` is the OUTPUT LEVEL, and its sixteen bits tile exactly

`Voice_StageLevel_Reg0080` (was `sub_FA7D6A`, `0xFA7D6A`) writes staging word 2 (RAM
`0x00D762`), which `Dev10C_WriteAllChanRegs` sends to register `chan + 0x0080` **twice**: once
with bit 15 SET (`0xFB717E`) before the other twenty registers and once with bit 15 CLEAR
(`0xFB7304`) after them — the 1-then-0 gate pulse §5 of the tone-generator note describes.

```
idx    = Clamp_0_to_00FF( part[+0x0B] + arg1 + part[+0x0E] + voice[+0x2F] [+/- part[+0x2B]] )
value  = ( 2 * Voice_OutputLevel_Table[idx] )                       bits 11..0
       | ( the 3-bit field )                            << 12       bits 14..12
                                                                    bit 15 = the gate
```

* `part[+0x0B]` is **MIDI controller 7, channel volume**; `part[+0x0E]` is **controller 11,
  expression**; both arrive through `Voice_CC_VolumeCurve`.
* the 3-bit field is `(voice[+0x0F])[+0x02] & 0x70` shifted left 8 when bit 7 of that byte is
  set, else `Voice_Reg080_NoteField_Table[voice[+0x06] >> 8]`.
* **the three fields tile the sixteen bits with no overlap**: `2*T[255] = 0x0FF4 < 0x1000`, and
  every entry of the note-field table is a multiple of `0x1000` below `0x8000`.  A wrong field
  split does not do that.

### The two curves, both with a closed form checked entry by entry

**`Voice_CC_VolumeCurve` (`0xFDF3F1`, 128 u16)** runs `0xFF01` (= −255) at value 0 to `0x0000`
at values 126 and 127, monotone throughout, and **falls exactly 32 counts per halving of the
controller value on every power of two**:

```
T[1] = -224   T[2] = -192   T[4] = -160   T[8] = -128
T[16] = -96   T[32] = -64   T[64] = -32   T[127] = 0
```

Off the powers of two it matches `round(32*log2(k/127))` for 113 of the 127 non-zero entries and
sits exactly **one count lower** on the other 14 (indices 3, 5, 9, 10, 13, 18, 20, 27, 40, 54,
59, 87, 99, 108).  So: a **logarithmic attenuation, 32 counts per 6.02 dB**, i.e. 0.188 dB per
count and a 48 dB span — with the exact table, not the formula, being what the machine uses.

**`Voice_OutputLevel_Table` (`0xFDDE2B`, 256 u16)** has an EXACT closed form, **all 256 entries,
zero exceptions**:

```
T[16*e + m] = 128*e + round(128 * log2(1 + m/16))
            = round(128 * log2( (16 + m) * 2^e )) - 512
```

— the base-2 logarithm, 128 counts per octave, of the amplitude whose 4-bit exponent and 4-bit
mantissa are packed in the index.  Doubled by the caller that is **256 counts per octave of the
register field, ~0.0235 dB per count**.  `T[255] = 0x07FA`, so the field spans `0x0000..0x0FF4`.

**Larger value = louder.**  Controller value 127 contributes 0 attenuation and lands at the top
of the table; value 0 contributes −255 and drives the index to the clamp floor.

> The same 512 bytes are byte-identical to the KN5000 sub-CPU's `Voice_OutputLevel_Table`
> (`v142/subcpu/subcpu_data_tables.s:1317`), which is a second project having named the same
> bytes the same thing — but the argument above does not rest on that.

---

## 4. Register `chan + 0x0040` carries the word the played note selects

`Voice_SelectKeyZone_Reg0040` (was `sub_FA819A`, `0xFA819A`):

```
zone = KeyMap_LookupByPitch( table, voice[+0x06] )      ; table[(pitch & 0x7F00) >> 8], 128 bytes
one of four walkers, chosen by bits 0x40 / 0x80 of (voice[+0x1F])[0]:
      XIX = array + STRIDE * zone         STRIDE = 8, 6, 6 or 4
      voice[+0x0F] = XIX                  (the cursor)
      voice[+0x01] |= 0x6000 / 0x6000 / 0x4000 / --
      staging word 1 (0x00D760) = word at (XIX+0)       -> register chan + 0x0040
      (0x005A4F)                = the record's tuning word, or 0
      sub_FC4D85( (XIX+4), (XIX+5), (XIX+6) )           -> the 0x00104000 packer's inputs
then, if (0x0014FF) & 4 and (word & 0xF000) < 0x6000:
      word = (word & 0x0FFF) | ((word & 0xF000) * 2)
```

So the firmware itself reads this register as **a 4-bit top field plus a 12-bit payload**, and a
global configuration bit **doubles the top field** while the payload passes through unchanged.
The identical fix-up appears a second time, in `sub_FA826C` at `0xFA82F0`-`0xFA8318`.

⚠ **[INFERENCE, stated as such]** a small top field that a configuration bit doubles, sitting
over a 12-bit index, is the shape of a **memory-bank selector over a wave number** — and the
machine has four flash "SOUND RAM" banks and six undumped mask ROMs.  Nothing here decides it.
What is measured is the key map, the four record strides, the field split and the doubling.

⚠ **The four walkers are NOT copies of one another** — pairwise, 18 to 38 of the bytes they
share differ (section 11 prints all six counts).  They are four record formats, distinguished
by which optional fields exist:

| walker | stride | flag OR'd into `voice[+0x01]` | fields handed on |
|---|---:|---|---|
| `KeyZone_Stage_Reg0040_Stride8` | 8 | `0x6000` | `(+4)`, `(+5)`, `(+6)` |
| `KeyZone_Stage_Reg0040_Stride6A` | 6 | `0x6000` | `(+4)`, `(+5)`, 0 |
| `KeyZone_Stage_Reg0040_Stride6B` | 6 | `0x4000` | 0, 0, `(+4)` |
| `KeyZone_Stage_Reg0040_Stride4` | 4 | — | 0, 0, 0 |

★ And the zone record's tuning word is what closes the pitch chain's third stage: it is latched
into `0x005A4F` here and added to the pitch by `Voice_PitchAddZoneOffset_*` (§2).

---

## 4b. ★★ And those records are read out of the image at `0x00F00000` — i.e. prom_d's format

`ExtBoard_ProbeAndInstallBases` (`0xFB0504`) installs eight 32-bit base pointers at boot.  Two
of them matter here:

```
(0x00D7ED) = (0x00D7F1) = 0x00F00000        always            (0xFB051E / 0xFB0523)
(0x00D80D)              = 0x00C00000        iff the expansion board answers "WSA1 EXTBD",
                          0                 otherwise         (0xFB0594 / 0xFB05B2)
```

and `Voice_SelectKeyZone_Reg0040` **relocates every pointer it follows against one of them**:

```
XWA = voice[+0x1F]                       ; the voice's tone-object pointer, absolute
XIX = (XWA > (0x00D7ED)) ? (0x00D7ED)    ; the internal image
                         : (0x00D80D)    ; the expansion board
key_map_hdr = (XWA+0x01) + XIX           ; a 0-BASED OFFSET plus the base
zone_array  = (XWA+0x05) + XIX           ; a second one
key_map     = *(key_map_hdr) + XIX       ; a third, nested
zone        = key_map[ note ]            ; KeyMap_LookupByPitch, 128 bytes
sub_index   = key_map_hdr[ 4 + zone ]    ; a byte array right behind the pointer
record      = zone_array + STRIDE * sub_index
```

★ **This is the byte-level tie to prom_d's INTERNAL structures that
`FINDINGS-memory-map.md` §5 says is still missing.**  That section established prom_d's base as
`0x00F00000` from CPU 1's remote read of the build tag at `0x00F7FFF0`, and then said:

> *"nothing indexes prom_d's 44-entry offset header or its 274-entry pointer directory, so the
> tie is to the image, not to its internal structures."*

Now something does.  prom_d's own description (`prom_d/prom_d.ld`, `FINDINGS-prom-d-tone-database.md`
§1) is *"every value is a 0-based file offset — prom_d contains no absolute pointers at all"*, and
the code above is exactly a consumer of 0-based offsets against the base `0x00F00000` that the
same firmware installs.  Two independent descriptions of the same addressing scheme meeting at the
same base address.

⚠ **What is still NOT proven**: that a *specific* prom_d structure is the key-zone array.  The
offsets are held in RAM objects whose own provenance (a tone load from flash, from prom_d, or from
the expansion board) is not traced here.  What is proven is the SCHEME — base plus 0-based offset,
the base being `0x00F00000` — and that the expansion board at `0x00C00000` is an alternative
source for the same kind of object, which is what an add-on sample board would be.

★ And it explains `Voice_SelectKeyZone_Reg0040`'s top-nibble doubling (§4): the field it doubles
sits above a 12-bit payload in the one register that carries the zone record's word 0, and the
machine has two possible sources for that record.

---

## 5. Registers `chan + 0x0800` and `chan + 0x0840`: the quiescent pair

`Dev10C_QuiesceListedChans_0800_0840` (was `sub_FB0200`, `0xFB0200`) walks a one-byte-per-voice list
until the first entry `>= 0x40` and, per channel, writes

```
register chan + 0x0840 = 0xFF00
register chan + 0x0800 = 0xFF80
```

which are **exactly** the two values `Dev10C_ResetAllChannels` writes to the same two blocks for
all 64 channels at power-on (`0xFB811E` and `0xFB8132`).  So `0xFF80`/`0xFF00` in blocks `0x20`
and `0x21` is this device's per-channel quiescent state, reached both from reset and from a
voice-list clear.

⚠ **"Silence" fits both uses and is not asserted here**: nothing in this image reads either
register back, and nothing ties either to an audible effect.

---

## 6. What this changes for the emulator

`wsa1.cpp`'s `tg_data_w()` stores 4096 words and synthesises nothing.  It can now, for each of
the 64 channels:

* take `reg[0x0400 + ch]` as a pitch, `note = value / 256.0`, saturated at 0 and 127.996;
* take `reg[0x0080 + ch] & 0x0FFF` as a logarithmic gain with 256 counts per octave — i.e.
  `amplitude = 2 ** ((value - 0x0FF4) / 256.0)` for a unity top — with bits 14..12 held aside as
  an unknown 3-bit field and bit 15 as a strobe that the CPU pulses 1-then-0 around every full
  parameter update;
* treat `reg[0x0800 + ch] == 0xFF80 && reg[0x0840 + ch] == 0xFF00` as the channel's idle state;
* and log `reg[0x0040 + ch]` split as `(value >> 12, value & 0x0FFF)`, which is how the firmware
  itself manipulates it.

⚠ Do **not** import any of this into the twin device at `0x00104000`.  Both devices have blocks
`0x0040` and `0x0080`, and this tree has already had to retract once over exactly that
confusion.  Everything above is `0x0010C000`.

---

## 7. Where the names went

In `prom_c/wsa1_prom_c.s`, 40 labels lost their address-only names.  Two new block comments
carry the tables: **"THE PART RECORD, AND THE CONTROLLERS THAT WRITE IT"** in front of
`MidiCtrl_Dispatch`, and **"0x0010C000: THE REGISTERS THAT NOW HAVE A MEANING"** in front of
`Dev10C_WriteAllChanRegs`.  Every renamed routine's header carries an `Evidence:` paragraph
citing the instruction addresses, and each of those addresses is asserted by
`notes/prom_c_dev10c_meaning_checks.py`.
