# Gap A, half-closed: 21 of the 22 0x0010C000 words have a LOCATED producer

> ★★ **THE COUNTS IN THIS FILE ARE UNDER-COUNTS -- CORRECTED 2026-08-25 (round 3).**  The
> scan behind section 2 cannot see three classes of write, and misses **17 sites**:
> absolute read-modify-write (`ordm16_24`, 3 sites), a based store after an interior label
> (7), and a store made through a struct POINTER handed to a callee (7).  The true figure is
> **87 write sites over the same 21 of 22 words** -- word 0 still has no producer.  Two
> consequences matter downstream:
>
> * **"Eleven of the 22 words have exactly two write sites" is now SIX** -- `0x0080`,
>   `0x00C0`, `0x0180`, `0x09C0`, `0x0A00`, `0x0A40`.  `0x0500`, `0x0900`, `0x0940`,
>   `0x0980` and `0x04C0` leave that list.  Section 4's shortest-path reasoning is scoped by
>   those counts.
> * **Register `0x0040 + chan` has a producer that is not in this file's table at all**:
>   `Word_AddTickLow3` (`0xFC369F`) adds `(tick & 7)` to staging word 1 through a pointer
>   `VoiceRegs_Stage_D` hands it (`lda XBC,0x00d75e / inc 2,XBC` at `0xFB2EED`), so the
>   register the played note selects is jittered in its low three bits on the D path only.
>
> Every figure re-derived, with the corrected table, by
> **`python3 notes/prom_c_staging_producer_audit.py --selftest`** (3 negative controls).
> ⚠ The scan's own docstring says "any write through a base this script cannot follow is
> COUNTED AND REPORTED, never dropped"; its `unfollowed` list is built and never appended
> to.  That sentence is the reason the gap went unnoticed and is asserted false by the
> audit's section 1.

> ★★ **SUPERSEDED IN PART, 2026-08-25 (round 3).**  Two more registers are named and a
> third has the sibling's name with a calibration behind it: the KN5000 sub-CPU stages **the
> same 22 registers in the same order**, and `0x0100`/`0x0140` are established here as a
> PAIR with a 7-bit field clamped to 36..120.  See
> **`notes/FINDINGS-prom_c-dev10c-sibling-register-map.md`** and
> `python3 notes/prom_c_reg0100_0140_checks.py --selftest`.

> ★★ **SUPERSEDED IN PART, 2026-08-25 (round 7).**  Section 0's first bullet — *"No register's
> meaning.  Not one."* — is **no longer true for four of them**, and section 4's next-pass list
> is done for two of its three items.  `0x0400 + chan` is the PITCH (1/256 semitone),
> `0x0080 + chan` is the OUTPUT LEVEL (log2, 256 counts per octave), `0x0040 + chan` is the word
> the played note selects out of a key-zone record, and `0x0800`/`0x0840 + chan` have their
> quiescent value.  See **`notes/FINDINGS-prom_c-dev10c-register-meanings.md`** and
> `python3 notes/prom_c_dev10c_meaning_checks.py`.  Everything else in this file stands: the
> producer index, the 70 write sites, and the other seventeen registers' meanings still being
> unknown.
>
> ⚠ Round 7 took a route this file did not rank: **not** the two-producer registers, but the MIDI
> CONTROLLER DISPATCHER, whose 26 arms carry the standard controller numbers and so give a name
> to the part-record fields that the register producers read.  Section 4's item 1 —
> `0x0180 + chan`, the register the firmware reads back — is **still open**.

⚠ **CORRECTED 2026-08-25 (wave-5 audit, finding 16).**  This file's title used to read
*"every 0x0010C000 register now has a named PRODUCER"*.  Two things were wrong with it and
both matter downstream:

* **located, not named.**  Every producer in the table below is a `sub_XXXXXX` label — an
  address.  None of them is named for what it computes.
* **21 of 22, not 22.**  Word 0 has no staging-word producer at all: block 0 is written
  with the literal `0x8100` inside the device writer itself.  `--verify` has always
  asserted the accurate form ("covers 21 of the 22 words"); only the prose overstated.

Wave 5, 2026-08-25.  Written against gap **A** of
`../kn7000_mame/notes/WSA1-EMULATION-DISASM-GAPS.md` — *"for at least one register block of
the device at CPU 2's 0x0010C000: what physical quantity does it carry?"*

**This note does not answer that question.**  What it does is remove the reason the
question could not be attacked.  The gap list says the register meanings stay unknown
"until one of [0xFA8347, 0xFA83CC, …] is converted, because the drivers only move words".
Those routines — and the other nineteen the same paragraph names — **are all converted
now**, and this pass turns that into a usable index:

```
python3 notes/prom_c_dev10c_field_sources.py            # per-register: who writes it
python3 notes/prom_c_dev10c_field_sources.py --verify   # assertions, exit != 0 on failure
python3 notes/prom_c_dev10c_field_sources.py --sites    # every write, with its address
python3 notes/prom_c_dev10c_field_sources.py --dev104   # the 0x00104000 packer's 19 writes
```


### Names the producer table below now has (wave 7, round 6 — 2026-08-30)

Twelve more of the `sub_XXXXXX` labels in section 2 are now named, for the register block
each one stages.  The mapping, so the table below stays followable:

| here | now |
|---|---|
| `sub_FA826C` | `Voice_StageRegs_0040_B` |
| `sub_FAA0BC` | `Voice_StageRegs_00C0_AB` |
| `sub_FAA1A5` | `Voice_StageRegs_00C0_CD` |
| `sub_FA9C60` | `Voice_StageRegs_0180_AB` |
| `sub_FAA4C3` | `Voice_StageRegs_0800_A` |
| `sub_FAACEE` | `Voice_StageRegs_0800_B_ModeLt3` |
| `sub_FAB0BD` | `Voice_StageRegs_0800_B_ModeGe3` |
| `sub_FAA96C` | `Voice_StageRegs_0800_CD` |
| `sub_FAA87E` | `Voice_StageRegs_0840_0880_AB` |
| `sub_FAAC00` | `Voice_StageRegs_0840_0880_CD` |
| `sub_FA842D` | `Voice_StageRegs_0900_0940_0980_AB` |
| `sub_FA93AF` | `Voice_StageRegs_09C0_0A00_0A40_AB` |
| `sub_FC4DBD` | `Dev104_PackStagingStruct` |
| `sub_FC4BB6` | `Pack104_SetInputs_PartRecord` |
| `sub_FC4C85` | `Pack104_SetInputs_SubRecordPair` |

⚠ **AND ONE CORRECTION TO §3.**  This file says `sub_FC4DBD` "writes **19 offsets** in
`0x00..0x24`".  Nineteen is the number of WRITE SITES; the distinct offsets are **16**, of
which 15 are even (whole words) and one (`+0x1D`) is a high-byte write.  Four of the
nineteen even fields — `+0x06`, `+0x08`, `+0x12` and `+0x16` — are not written by the
packer's own instructions at all.  Re-derived by
`python3 notes/prom_c_understanding_round6.py --packer`, which counts them with this
file's own scanner (`notes/prom_c_dev10c_field_sources.py --dev104`).

⚠ **AND ONE THING §3 DOES NOT SAY.**  `VoiceRegs_Stage_B` never calls the packer.
Stage_A, Stage_C and Stage_D do; Stage_B calls `Dev104_LoadStageBImage` (was `sub_FC571A`)
at `0xFB1F42`, which block-copies a fixed 19-word image from `0xFE1315` into the same
struct and patches five fields.  Same section, same check.

### Names the producer table below now has (round 7)

The `sub_XXXXXX` labels in section 2 are still the addresses this pass indexed; nine of them
have since been named in `prom_c/wsa1_prom_c.s`.  The mapping, so the table stays followable:

| here | now |
|---|---|
| `sub_FA7467` | `KeyZone_Stage_Reg0040_Stride8` |
| `sub_FA74AB` | `KeyZone_Stage_Reg0040_Stride6A` |
| `sub_FA74ED` | `KeyZone_Stage_Reg0040_Stride6B` |
| `sub_FA752F` | `KeyZone_Stage_Reg0040_Stride4` |
| `sub_FA819A__FA8231` | inside `Voice_SelectKeyZone_Reg0040` |
| `sub_FA7D6A__FA7E1A` | inside `Voice_StageLevel_Reg0080` |
| `sub_FA8347__FA8398` | inside `Voice_StagePitch_Reg0400_AB` |
| `sub_FA83CC__FA841D` | inside `Voice_StagePitch_Reg0400_CD` |
| `sub_FC4D85` | unchanged — still an address |

---

## 0. ⚠ What is still NOT established

* **No register's meaning.**  Not one.  No register is called pitch, level or wave here or
  in the source.
* A routine that writes a staging word is not necessarily the routine that DECIDES it; the
  value may arrive as an argument.  `--sites` prints the value operand so that is visible.
* The naming discipline is unchanged: `Dev10C_` states an address, not a role.

---

## 1. The correction that made this possible

`prom_c/wsa1_prom_c.s` claimed, in `VoiceRegs_Stage_A`'s header and in the
`VoiceRegs_Stage_*` block comment, that *"every helper … is still `.incbin`, so which
staged word is which parameter is not established."*  **All twenty-one are converted.**
Twelve other headers in the same file carried the same kind of stale `still .incbin`
sentence about addresses that are now assembly; all thirteen are corrected in the source,
each marked `⚠ CORRECTED 2026-08-25` with what it used to say.

---

## 2. The 0x0010C000 side: 22 registers, 70 producer sites

`Dev10C_WriteAllChanRegs` (0xFB713A) moves 22 words from the staging struct at RAM
`0x00D75E` into 22 registers of one channel.  The word → register-block map is
`notes/prom_c_tg_chanmap.py`'s, not retyped: blocks 1, 3-6, 16-20 and 32-41 for words
1, 3-6, 7-11 and 12-21, plus word 2 → block 2 (the bit-15 gate it pulses 1-then-0) and
block 0 written with the literal `0x8100` and no struct field.

Scanning prom_c for every byte or word written into `0x00D75E..0x00D789`, in both the
absolute (`ld (0x00d766),BC`) and based (`lda XIX,0x00d75e` … `ld (XIX+0x0e),BC`) forms,
gives **70 write sites over 21 of the 22 words**:

     word  struct    register   writers
       0   +0x00      --          0 site(s): (none located)
       1   +0x02    0x0040+ch    9 site(s): sub_FA7467, sub_FA74AB, sub_FA74ED, sub_FA752F, sub_FA819A__FA8231, sub_FA826C__FA82D8
       2   +0x04    0x0080+ch    2 site(s): sub_FA7D6A__FA7E1A, sub_FAC2AE   [the bit-15 gate, pulsed 1-then-0]
       3   +0x06    0x00C0+ch    2 site(s): sub_FAA0BC__FAA196, sub_FAA1A5__FAA2A6
       4   +0x08    0x0100+ch    5 site(s): VoiceParam_DispatchOn_17_11__FA904A, sub_FA919B__FA9260, sub_FA919B__FA928D, sub_FA92A5__FA936A, sub_FA92A5__FA9397
       5   +0x0A    0x0140+ch    5 site(s): VoiceParam_DispatchOn_17_11__FA904A, sub_FA919B__FA9260, sub_FA919B__FA928D, sub_FA92A5__FA936A, sub_FA92A5__FA9397
       6   +0x0C    0x0180+ch    2 site(s): sub_FA96F7__FA9801, sub_FA9C60__FA9F06   [the block read back at 0xFA69B1]
       7   +0x0E    0x0400+ch    3 site(s): sub_FA8347__FA8398, sub_FA83CC__FA841D, sub_FAC2AE
       8   +0x10    0x0440+ch    4 site(s): sub_FA96F7__FA9773, sub_FA9915, sub_FA9915__FA99C7, sub_FA9915__FA9ACB
       9   +0x12    0x0480+ch    3 site(s): sub_FA96F7__FA9773, sub_FA9915, sub_FA9915__FA9B74
      10   +0x14    0x04C0+ch    2 site(s): sub_FA96F7__FA9801, sub_FA9F19
      11   +0x16    0x0500+ch    2 site(s): sub_FA95D4__FA9676, sub_FA96F7
      12   +0x18    0x0800+ch    4 site(s): sub_FAA4C3__FAA624, sub_FAA96C__FAAA26, sub_FAACEE__FAAE63, sub_FAB0BD__FAB20E
      13   +0x1A    0x0840+ch    5 site(s): sub_FAA87E__FAA93A, sub_FAA87E__FAA954, sub_FAAC00__FAACBC, sub_FAAC00__FAACD6, sub_FAC2AE
      14   +0x1C    0x0880+ch    7 site(s): sub_FAA87E__FAA8F5, sub_FAA87E__FAA921, sub_FAA87E__FAA954, sub_FAAC00__FAAC77, sub_FAAC00__FAACA3, sub_FAAC00__FAACD6, sub_FAC2AE
      15   +0x1E    0x08C0+ch    3 site(s): sub_FA95D4__FA9676, sub_FA95D4__FA96CE, sub_FA96F7
      16   +0x20    0x0900+ch    2 site(s): sub_FA842D__FA859D, sub_FA96F7
      17   +0x22    0x0940+ch    2 site(s): sub_FA842D__FA8623, sub_FA96F7
      18   +0x24    0x0980+ch    2 site(s): sub_FA842D__FA8623, sub_FA96F7
      19   +0x26    0x09C0+ch    2 site(s): sub_FA93AF__FA94B3, sub_FA96F7
      20   +0x28    0x0A00+ch    2 site(s): sub_FA93AF__FA9556, sub_FA96F7
      21   +0x2A    0x0A40+ch    2 site(s): sub_FA93AF__FA9556, sub_FA96F7
    
    70 write sites over 21 of the 22 words.

**Word 0 has no writer, and `Dev10C_WriteAllChanRegs` reads no word 0 either.**  Two
independent readings agreeing is the check that the scan is not missing a whole class of
write.

### What is immediately usable

* **Eleven of the 22 words have exactly two write sites** — words 2, 3, 6, 10, 11 and
  16-21.  A register with two producers is one routine-read away from a meaning.
* **Word 6 → register `0x0180 + channel` is the one the emulator most needs**: it is the
  block `0xFA69B1` READS BACK and keeps as `(value & 0x3FFF) >> 5` (gap F).  Its only two
  producers are `sub_FA96F7__FA9801` and `sub_FA9C60__FA9F06`.  That is the shortest path
  in this table from "the driver answers 0" to "the driver answers something true".
* Word 1 → register `0x0040 + channel` has the most: **nine write sites from six
  routines**.  Four of them — `sub_FA7467`, `sub_FA74AB`, `sub_FA74ED`, `sub_FA752F`, of
  68, 66, 66 and 65 bytes — are the same SHAPE and are the only callers of `sub_FC4D85`:

  ```
      XIX = arg(+0x0A) + STRIDE * arg(+0x0E)      ; index a record array
      (state+0x0F) = XIX                          ; save the cursor
      (state+0x01) |= MASK                        ; set a flag pair
      (0x00D760)   = word at (XIX+0)              ; <- staging word 1
      sub_FC4D85( (XIX+4), (XIX+5), (XIX+6) )
  ```

  and **the four STRIDES are different: 8, 6, 6 and 4**, with MASK `0x6000`, `0x6000`,
  `0x4000` and none.  ⚠ They are NOT byte twins — pairwise, 18 to 38 of 66 bytes differ
  (`cmp` over `0xFA7467`, `0xFA74AB`, `0xFA74ED`, `0xFA752F`), so nothing here is
  transplanted from one to another.
  [INFERENCE, stated as such] four routines stepping four differently-sized record arrays
  and each writing the record's first word into the SAME per-channel register is the shape
  of several parameter sources multiplexed onto one register.  Nothing here decides what
  the records are.  What is measured is the four strides, the `+0` word, the cursor and
  the shared callee.

---

## 3. The 0x00104000 side: ONE packer, and its input block

The twin device's staging struct at `0x00D7A2` is not filled that way at all.  **One
routine fills it**: `sub_FC4DBD` (0xFC4DBD, 2,311 bytes), whose only argument is the
struct POINTER and which writes **19 offsets in `0x00..0x24`** through it — exactly the
span `Dev104_WriteAllChanRegs` reads (`register (chan + k*0x40) = struct word 2k`,
k = 0..0x12).  `VoiceRegs_Stage_A` calls it with `0x00D7A2` and then hands the same
pointer to the device writer, two instructions later.

That asymmetry — many small writers on one device, one packer on the other — is itself a
finding, and it makes `sub_FC4DBD` the single highest-value routine body left in this
subsystem.

### Its inputs are a "current object" pointer block at RAM 0x00E082-0x00E08D

`sub_FC4DBD` reads no argument except the struct pointer.  Everything else comes from
seven globals, set by four small routines that this pass read:

| global | set by | value |
|---|---|---|
| `0x00E082` | `sub_FC4BB6` | `0x005D23 + 0xBB * arg` — an array at RAM `0x005D23`, stride **187** |
| `0x00E084` | `sub_FC4C85` | `(0x00E082) + 0x2A * arg + 0x13` — a sub-array at `+0x13` inside that record, stride **42**.  187 − 19 = 168 = **4 × 42** |
| `0x00E086` | `sub_FC4C85` | `0x00753E + 0x25 * arg` — an array at RAM `0x00753E`, stride **37** |
| `0x00E088` | `sub_FC4D63` | `voice_record[+0x0C]` with **bit 7 cleared** |
| `0x00E089` | `sub_FC4D63` | the first byte of the object the 32-bit pointer at `voice_record[+0x1F]` points to |
| `0x00E08A` | `sub_FC4D63` | `voice_record[+0x08]` (word) |
| `0x00E08D` | `sub_FC4DA1` | `voice_record[+0x0A]` (word) |
| `(0x00E086)[+0x0E]` | `sub_FC4DA1` | `voice_record[+0x06]` (word) |

`voice_record` is the 68-byte record at `0x003BCF + 0x44 * voice` — the same array the
tone-generator note already documents, re-derived here from
`ld C,0x44 / mul BC,(XIZ+0x08) / ld WA,0x3bcf / add DE,BC` at the top of every
`VoiceRegs_Stage_*`.

`sub_FC4BB6` is called from the arms of `MidiNote_OnByPartMode`, so `0x00E082` is
"the record of the part this note-on belongs to", 187 bytes, containing four 42-byte
sub-records at `+0x13`.

### And this is what one register's value actually is

The first two of the nineteen writes are the same idiom:

```
  struct word 1  (register 0x0040 + chan) = SAT( P[+0x0A] + P[+0x12]  ±  delta )
  struct word 2  (register 0x0080 + chan) = SAT( P[+0x0C] + P[+0x14]  ±  delta )
```

⚠ **THESE ARE `0x00104000` REGISTERS, NOT `0x0010C000` ONES.**  Stated here because the
wave-5 round report quoted this formula under the heading "EMULATION GAP A", and gap A is
specifically about `0x0010C000`.  **Both devices have a register `0x0040 + chan`**; the two
are told apart only by the peripheral base, which is the same defect this tree has already
had to retract once ("a routine 80/81 identical to the sibling where the one difference was
the PERIPHERAL BASE").  The section heading above — *"The 0x00104000 side"* — is the
authority; the `0x0010C000` register `0x0040 + chan` has its own, different producer list,
nine sites from six routines, in section 2.

where `P` is the 42-byte sub-record `(0x00E084)`, the two summands are exactly 8 bytes
apart, and

```
  delta = + ( voice_record[+0x08] - voice_record[+0x0A] )   if bit 7 of Q[+0x16]
        = -   (0x00E086)[+0x0C]                             otherwise
  Q     = the 32-bit pointer at P[+0x03]
```

`SAT` is a **signed 16-bit add with an asymmetric clamp**, and the asymmetry is worth
copying exactly into any re-implementation: on POSITIVE overflow the result becomes
`0x7FFF`; on NEGATIVE overflow it becomes **`0x0000`, not `0x8000`**.  A result that is
merely negative, without overflow, passes through unchanged.

So a `0x00104000` register carries a 16-bit quantity built as *base + trim*, where the
base is a pair of per-part values eight bytes apart and the trim is a difference of two
per-voice words.  That is what the hardware is fed.  **What it is a quantity OF is still
open** — but it is now open at the level of "read one 2,311-byte routine", not "convert a
module".

---

## 3b. ★ ROUND 3: two of `sub_FC4DBD`'s nineteen registers now have their TABLES

`sub_FC49AD` — a helper `sub_FC4DBD` calls at `0xFC56AA` — reads two parallel 251-entry tables
with one index, clamped to `0..250` by its own code (`cp HL,0x00FA` at `0xFC49CC`, `cp HL,0` at
`0xFC49D7`), and stores both results through the struct pointer:

| table | contents | struct | register |
|---|---|---|---|
| `Curve_Log2_251` (`0xFDFAE0`) | `round(27543 − 3072·log₂k)`, `T[0] = 0x6C00` | `+0x06` | `0x00C0 + chan` |
| `Const_0100_251` (`0xFDFCD6`) | `0x0100` in **all 251 entries** | `+0x08` | `0x0100 + chan` |

So register `0x0100 + chan` is fed a **constant** on this firmware, and `0x00C0 + chan` a
**logarithmic** quantity — 3072 counts per halving — plus two per-part offsets, clamped to
`0x0000` or `0x7F00` at `0xFC4A2B`. The same `>> 5` Q5 idiom that reads the four `LinCoef`
tables (`0xFE0096`, `0xFE0116`, `0xFE0196`, `0xFE0216`) supplies four more of the nineteen.
Full account and the closed forms: `notes/FINDINGS-prom_c-tail-data-zone.md` §4 and §5.
⚠ Still `0x00104000`, not `0x0010C000`.

---

## 4. What the next pass should do

> ⚠ **Item 3 is DONE (round 3, in part) and the counts this section reasons from are the
> under-counts corrected at the head of this file.**  The four `KeyZone_Stage_Reg0040_*`
> walkers were named in round 7; round 3 adds the fifth producer of that register,
> `Word_AddTickLow3`.  Item 1 -- the two producers of `0x0180` -- is still open on the READ
> side; its WRITE side is decoded in
> `notes/FINDINGS-prom_c-dev10c-sibling-register-map.md` §4.

1. Read `sub_FA96F7__FA9801` and `sub_FA9C60__FA9F06` — the only two producers of the one
   register the firmware READS BACK (`0x0180 + channel`, gap F).  Two routines, one
   register, and the emulator has a stub waiting for the answer.
2. Read `sub_FC4DBD` end to end.  Nineteen registers of the twin device come out of it and
   its inputs are already enumerated above.
3. Read one of `sub_FA7467` / `sub_FA74AB` / `sub_FA74ED` / `sub_FA752F` and identify the
   record arrays they walk (strides 8, 6, 6, 4).  Four same-shaped routines feeding one
   register is the strongest structural signal in the whole subsystem, and the shared
   callee `sub_FC4D85` — 28 bytes — is the cheapest place to start.
