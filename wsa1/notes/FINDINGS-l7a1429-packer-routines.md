# The routines that BUILD the L7A1429's register values, named

Wave 20, 2026-09-03, lane `w20/lsi-packers`. Wave 19 said **what** each of the
nineteen `0x00104000` registers is, **when** it is written, **what quantity** its
curve produces and **what the machine calls it**. This lane is the fifth
companion and answers the remaining question: **which routine computes it, and
what should that routine be called.**

Everything below is re-derived from `original_ROMs/wsa1_prom_c.ic28` by

```
python3 notes/w20_lsi_packer_checks.py            # 9 sections, printed
python3 notes/w20_lsi_packer_checks.py --selftest # FAILURES: 0
```

which reads bytes and never a `.s` file. The names themselves were applied by
`notes/w20_lsi_packer_names.py` from `notes/w20-lsi-packer-renames.map`, and
each named routine carries a `★ WAVE 20` block in `prom_c/field_accessors.s`
giving its arithmetic, its destination register and its grade.

---

## 0. The answer in one paragraph

**24 of the 57 `sub_XXXXXX` routines in `prom_c/field_accessors.s` are named; 33
are refused.** The 24 fall into four groups that together are the whole
host-side pipeline of the modelling LSI: four routines that **allocate a slot**
whose index becomes register `0x0000`'s high byte; four that **build staging
words** for named registers; eight that **set one part-level control each**, in
eight consecutive words of the part record; and five that **push a changed
control back out to a sounding voice**, plus three that bind and configure the
elements. The pipeline has a shape nobody had stated: `PART[+0x01] …
PART[+0x0F]`, on a stride of two, is **one part-level control per modelling
parameter**, and one routine — the RESO MODE dispatcher — clears precisely that
set.

⚠ Three corrections are owed to files this lane does not own. See §4.

---

## 1. THE PIPELINE

```
  tone-edit parameter        wave-select record       part record
    (arm 4, CPU 1)     -->      Q[+0x0D..+0x2A]  \
                                                  >-- sub-record P --> staging
  MIDI controller / part -->  PART[+0x01..+0x0F]  /   *(0x00E084)      struct
                                                                          |
                                              Dev104_WriteAllChanRegs <---+
```

`PART` is the 187-byte part record at `0x005D23 + 0xBB*part`; `P` the 42-byte
sub-record at `PART + 0x13 + 42*element`, reached through `*(0x00E084)`; `R` the
37-byte per-voice record at `0x00753E + 37*voice`, reached through `*(0x00E086)`;
`Q` the 43-byte wave-select record, reached through `P[+0x03]`. Those four
objects and their strides are wave 17's
(`FINDINGS-prom_c-dev104-register-map.md` §1 and the `Pack104_SetInputs_*`
headers); this lane adds only what runs over them.

### 1.1 The staging-word builders — 4 routines

| new name | fills staging word | register | the guide's expression |
|---|---|---|---|
| `Pack104_ComputeTuningWords_0040_0080` | its inputs `P[+0x0A]`/`P[+0x0C]` | `0x0040`, `0x0080` | §5 row 0x0040's first term |
| `Pack104_StageRegs_00C0_0100_0240` | `+0x06`, `+0x08`, `+0x12` (words 3, 4, 9) | `0x00C0`, `0x0100`, `0x0240` | §5 rows 0x00C0 / 0x0100 / 0x0240, verbatim |
| `Pack104_StageReg_0280` | `+0x14` (word 10) | `0x0280` | §5 row 0x0280, verbatim |
| `Pack104_StageReg_0000_ForVoice` | `+0x00` (word 0) | `0x0000` | §5 row 0x0000, the `R[+0x07] << 8` half |

★ The two `Stage*` names mirror their writers exactly —
`Dev104_SetChanRegs_00C0_0100_0240` and `Dev104_SetChanReg_0280`, already named
from their own `add rr,0x00C0` / `ld rr,(XBC+0x14)` operands — so a reader can
pair producer with consumer by name alone.

`Pack104_UnpackWaveSelRec_ToSubRecord` (was `sub_FC47EE`) sits upstream of all
four: it is the routine that turns `Q`'s modelling tail into `P`'s fields,
including the `i5 = clamp(p15, 44..96)` index whose two cached curve entries
become registers `0x0480` and `0x03C0` — the **third** MUTING section the
guide's §2.3 proves exists. `Pack104_LoadElementWaveSelRec` (was `sub_FC6803`,
40 call sites) is what binds a wave-select record to one element and calls it.

### 1.2 ★★ The eight part-level controls — a new structural result

Eight consecutive 16-bit words of the part record, on a stride of two, are one
control each, and each has exactly one setter in this file:

| word | setter (new name) | pushes into | LSI parameter | registers reached |
|---|---|---|---|---|
| `PART[+0x01]` | `PartRec_SetFittingOffset_0001` | `P[+0x16]`, `P[+0x18]` | `FITTING` main + sub | `0x0140`/`0x01C0`, `0x0180`/`0x0200` |
| `PART[+0x03]` | `PartRec_SetPositionOffset_0003` | `P[+0x20]`, `P[+0x22]` | `P0SITI0N` | `0x00C0`, `0x0240` |
| `PART[+0x05]` | `PartRec_SetPositionOffset_0005` | `P[+0x20]`, `P[+0x22]` | `P0SITI0N` (second source) | `0x00C0`, `0x0240` |
| `PART[+0x07]` | `PartRec_SetMovementDepth_0007` | `P[+0x28]` -> `R[+0x1D]` | `P0SITI0N M0VEMENT` depth | `0x00C0`, `0x0240` |
| `PART[+0x09]` | `PartRec_SetMovementRate_0009` | `P[+0x29]` -> `R[+0x1E]` | `P0SITI0N M0VEMENT` rate | `0x00C0`, `0x0240` |
| `PART[+0x0B]` | `PartRec_SetMutingOffset_000B` | `P[+0x1A]`, `P[+0x1C]` | `MUTING` main + sub | `0x0340`/`0x0400`, `0x0380`/`0x0440` |
| `PART[+0x0D]` | `PartRec_SetTuningOffset_000D` | `P[+0x0A]`, `P[+0x0C]` | `KEY SHIFT` + `TUNE` | `0x0040`, `0x0080` |
| `PART[+0x0F]` | `PartRec_SetSubGainOffset_000F` | `P[+0x1E]` -> `R[+0x23]` | `SUB GAIN` | `0x0280` |

**THE CONTROL.** These eight are not a list somebody assembled: they are exactly
the eight words `Pack104_DispatchByResoMode_ForPart` clears, one after another,
at `0xFC7527`, `0xFC7533`, `0xFC753F`, `0xFC754B`, `0xFC7557`, `0xFC7563`,
`0xFC756F`, `0xFC757B` — twelve bytes apart, `ld (XBC+off),0x0000` each. A
routine that resets *precisely that set and no other word of a 187-byte record*
is an independent statement that they are one group. Probe §7 asserts both the
eight setters and the eight clears.

★ And the assignment of parameter to word is not by position: each setter's own
arithmetic names it. `PartRec_SetMutingOffset_000B`, for instance, writes
`P[+0x1A] = (p22 & 0x7F) ± PART[+0x0B]` at `0xFC6483-0xFC64A2`, and `P[+0x1A]` is
read at `0xFC529F` as the additive term of the index `i3` that selects
`Curve_Muting_Cutoff_Q16_128` for register `0x0400`. `p22` is the tone editor's
MAIN `MUTING` value (`FINDINGS-l7a1429-parameter-names.md` §4). Three
independent things — the byte the editor writes, the curve the index selects and
the register the curve feeds — agree at every row of the table.

### 1.3 The refresh half — the callers pin the names

`Voice_ApplyParamChange_Dispatch`'s arms in `prom_c/midi/midi_controllers.s`
pair each setter with a per-voice refresher, and it is the **caller** that pins
each one:

| refresher (new name) | its caller then calls | so it prepares |
|---|---|---|
| `Pack104_RestageRegs_00C0_0100_0240_ForVoice` | `Dev104_SetChanRegs_00C0_0100_0240` (`0xFAEB56`, `0xFAEBC2`) | `0x00C0`, `0x0100`, `0x0240` |
| `Pack104_RestageReg_0280_ForVoice` | `Dev104_SetChanReg_0280` (`0xFAED24`) | `0x0280` |
| `Pack104_RefreshMovementDepth_ForVoice` | *nothing* | `R[+0x1D]`, picked up by the 40.69 Hz refresh |
| `Pack104_RefreshMovementRate_ForVoice` | *nothing* | `R[+0x1E]`, likewise |
| `Pack104_TickPositionMovement_ForVoice` | (calls the stager itself) | `R[+0x21]`, then all three |

★ **The prepare/write pairing is the strongest single argument in this pass.**
`sub_FAEAF9` calls `Pack104_RestageRegs_00C0_0100_0240_ForVoice` at `0xFAEB41`
and, on a non-zero return, `Dev104_SetChanRegs_00C0_0100_0240` at `0xFAEB56`
**with the same staging buffer `0x00D7A2`**. The writer's name comes from its
own `add rr,0x00C0` operands, so the preparer's name is not an inference about
what the value means — it is the register the very next call ships.

★ **And it explains an asymmetry.** The two movement refreshers have no
`Dev104_` call after their loop, and they do not need one: registers `0x00C0`,
`0x0100` and `0x0240` are rewritten for every sounding voice at the measured
40.69 Hz (`FINDINGS-l7a1429-write-sequencing.md`), so a new depth or rate is
picked up on the next tick. The two that *do* ship are exactly the two whose
registers are **not** periodic.

⚠ One unexplained detail: `Pack104_RestageReg_0280_ForVoice` ORs `7` into the low
three bits of the staged word at `0xFC67EF`, which `Dev104_PackStagingStruct`
does not do on the note path. Register `0x0280` therefore has a low-3-bit field
this refresh sets and the packer leaves clear. Recorded, not explained.

### 1.4 ★ The `P0SITI0N M0VEMENT` modulator, in full

`Pack104_TickPositionMovement_ForVoice` (was `sub_FC7C0D`) is the guide's
`R[+0x21] = p17 · sine / 50` implemented:

```
   R[+0x1C]  run state    1 run · 4 start (state<-1, phase<-0) · 3 stop
   R[+0x1F] += R[+0x1E]                          0xFC7C5D-0xFC7C6D
   R[+0x1F] &= 0x01FF                            0xFC7C7A   a 512-step phase
   w = (s8) *(0x00FE02C9 + R[+0x1F])             0xFC7C91
   R[+0x21] = w * R[+0x1D] / 50                  0xFC7CAA-0xFC7CB4
   -> Pack104_StageRegs_00C0_0100_0240           0xFC7CE9
```

Two tables fall out, both in files this lane does not own and therefore **not
renamed**:

* **`0x00FE0296`** — the table `PartRec_SetMovementRate_0009` reads with a 0..50
  index (`0xFC626E`) to produce the **phase increment** `R[+0x1E]`. 51 entries.
  It is `Curve_FE0296`, still an address label in
  `prom_c/data_tables/tail_data_zone.s`. **Proposed name:
  `Curve_Movement_PhaseStep_51`.**
* **`0x00FE02C9`** — a 512-entry signed **movement waveform**, indexed by the
  9-bit phase. `0xFE0296 + 51 = 0xFE02C9` exactly, so the two are adjacent and
  the 51-entry extent is bounded from both sides. **Proposed name:
  `Table_Movement_Waveform_512`.**

⚠ **A vocabulary divergence, stated rather than smoothed away.**
`FINDINGS-l7a1429-parameter-names.md` §5e calls `p18` the movement **form**. Its
low seven bits become a per-tick phase increment, which is a **rate**; bit 7,
which that note reads as a form flag, is masked off at `0xFC6211` and is a
separate field. This lane's names say RATE and this paragraph is the index
between the two words.

### 1.5 ★★ Register `0x0000`'s high byte is an ALLOCATED SLOT

`HLE-GUIDE-l7a1429.md` §8.5 lists `0xFC4D27` and `0xFC7DE9` as the undecoded
writers of register `0x0000`. Both store the return value of one routine, and
that routine is a **64-entry allocator**:

* the pool is at `0x005B63`, **64 entries of 7 bytes**
  (`{next, prev, list id, own index, use count}`), built by
  `Slot64Pool_InitAllFree`; `0x005B63 + 7·64 = 0x005D23`, **the part-record
  base**, so the extent is bounded on both sides;
* two list heads at `0x00E00E` and `0x00E010`; `Slot64Pool_MoveToList` splices a
  node between them;
* `Slot64Pool_AcquireOrAddRef(0xFF)` takes the head and returns its index 0..63;
  `Slot64Pool_Release` returns it when the last user drops it;
* the index goes to `R[+0x07]`, and `Dev104_PackStagingStruct` builds staging
  word 0 as `(R[+0x07] << 8) | P[+0x07]` at `0xFC4DE3-0xFC4DF1`.

The guide reads bits 13:8 of that register as "the CHANNEL on the power-on
path". A **64**-entry allocator writing a **0..63** index into exactly those bits
on the **note** path is the same field, allocated. Grade **STRONG** for "these
are the device's 64 channels" (the channel count is PROVEN from the device's own
loops); **PROVEN** for "a 0..63 index out of a 64-entry pool".

★ It also explains `Pack104_SetInputs_PartRecord`'s four `0xFF` stores to
`0x00E08F`..`0x00E092` (`0xFC4BCE`-`0xFC4BE0`): that is a four-slot cache of
"which pool entry this part's element already holds", and `0xFF` means none.

---

## 2. WHAT WAS REFUSED, AND WHY

33 of the 57 keep `sub_XXXXXX`. A wrong name is worse than no name, so the
reason each still stands is recorded here rather than left to be re-derived.

### 2.1 Established as NOT on the `0x00104000` path

| routine | what it really belongs to |
|---|---|
| `sub_FC39FA`, `sub_FC3B24` | the SOUND-RAM / flash path: both call `SoundRam_ClearFourBanks`, `Flash_ReprogramSector` and `Flash_ReadSectorToBuffer`, and neither touches `0x00E082`/`0x00E084`/`0x00E086`. |
| `sub_FC3407`, `sub_FC3480`, `sub_FC355B` | called only from `Voice_StageRegs_0040_B`; no contact with the packer's input globals. |
| `sub_FC35DB`, `sub_FC36BE`, `sub_FC382A`, `sub_FC4B2E` | voice-parameter helpers under `VoiceParams_Compute_*`; no contact with the globals. |
| `sub_FC7E10`, `sub_FC7E79`, `sub_FC7F03`, `sub_FC7F7A`, `sub_FC7FCA`, `sub_FC810C`, `sub_FC8129`, `sub_FC81B8`, `sub_FC81F8` | the `0x0010C000` voice-register and part-record side; `sub_FC7E79` calls `Dev10C_ReadChanReg_0100`, and the `Voice_StageRegs_*` / `Dev10C_Stage*` callers name the other device. |
| `sub_FC7CF9` | reached from `ExtBoard_ProbeAndInstallBases`; its only tie here is that it initialises the slot pool. |
| `sub_FC3CB8` | one byte, a bare `ret`. |
| `sub_FC4140`, `sub_FC4269` | arithmetic: `Divide32_Signed` and a 1,087-byte routine over `Math_Sin_Q11` / `Math_Cos_Q11` / `Math_Atan_Q11` / `Math_Exp2_Q11`. `sub_FC4269` *is* reached from the RESO MODE arms, but naming it needs §2.2's answer. |

### 2.2 On the path, but the purpose is not established

* **`sub_FC6CA8`, `sub_FC6CEA`, `sub_FC6D2C`, `sub_FC6D6E`, `sub_FC6FFD`,
  `sub_FC723F`** — the six arms `Pack104_DispatchByResoMode_ForPart` selects on
  the four elements' `RESO MODE` code. What *selects* them is PROVEN; what they
  *compute* is not. Three are 66-byte near-twins (the block header's own
  duplicate census records `0xFC6CA8`/`0xFC6CEA` differing in one byte); the
  other three are 578-655 bytes and all three call `sub_FC4269`'s trigonometry
  and write `0x00E093`/`0x00E095`, two globals nothing in this pass located.
  **Tried:** the MODELING top screen's `CONNEC`+`TION` caption makes a
  connection-topology reading attractive, and that is exactly why it was
  refused — a plausible caption is not a decode. **What would settle it:** the
  producers and consumers of `0x00E093`/`0x00E095`.
* **`sub_FC578C`** — reads `PART[+0x01]`, `PART[+0x03]`, `R[+0x21]` and
  `Q[+0x14]` and returns
  `Q[+0x14] - 100 + clamp(±(2·PART[+0x03] + R[+0x21]) >> 4, -8..8)
  + clamp(±PART[+0x01] >> 1, -16..16)`. Every input is a `P0SITI0N`-chain term,
  but its two callers (`0xFAB6BF`, `0xFAB789`) are outside this file and what
  they do with the result was not established, so the routine is not named.
  See §4.2 — it is where `p20` is read.
* **`sub_FC56C4`** — takes `0x00E086` by address and is called from the five
  `MidiNote_*` sites, so it is on the note path; not decoded this pass.
* **`sub_FC7A1F`, `sub_FC7AB4`, `sub_FC7B64`** — `sub_FC7AB4` and `sub_FC7B64`
  write `0x00E084` directly, from `sub_FBDCD3` / `sub_FBF280`; `sub_FC7A1F`
  re-enters two of the RESO MODE arms. All three are one hop from a named
  routine and none is decoded.

---

## 3. GRADES, IN ONE PLACE

| claim | grade |
|---|---|
| which staging word each named routine writes, and hence which register | **PROVEN** — displacement operands, cross-checked against `Dev104_SetChanReg*`'s own reads |
| the arithmetic quoted in every `★ WAVE 20` header | **PROVEN** — probe §§1-9 |
| the eight part-record words are one group | **PROVEN** — one setter each, and one routine clearing exactly that set |
| the parameter NAMES (`FITTING`, `MUTING`, `P0SITI0N`, `SUB GAIN`, `KEY SHIFT`, `TUNE`, `RESO MODE`) | **STRONG**, inherited whole from `FINDINGS-l7a1429-parameter-names.md`, including its two points of failure (guide §3.3): the MAIN/SUB direction rests on `SUB GAIN`, and the FITTING/MUTING split on one drawn caption |
| `p18`'s low 7 bits are a movement RATE | **PROVEN** — it is a phase increment into a 512-step accumulator |
| `0x00FE0296` is 51 entries and `0x00FE02C9` is the 512-entry waveform | **PROVEN** — adjacency plus the 0..50 clamp and the `& 0x01FF` |
| register `0x0000` bits 15:8 are an allocated 0..63 slot | **PROVEN** for the allocator; **STRONG** for "slot = the device's channel" |
| `0x0240`'s parameter name | still **WEAK** — this lane found its producer, not its meaning |

---

## 4. ⚠ THREE CORRECTIONS OWED TO FILES THIS LANE DOES NOT OWN

Reported, not edited.

### 4.1 `0xFC4D27` and `0xFC7DE9` write `R[+0x07]`, not `P[+0x07]`

`FINDINGS-l7a1429-parameter-names.md` §6 and `HLE-GUIDE-l7a1429.md` §8.5 both say
those two sites are the writers of `P[+0x07]`'s bits 6:4. They are not: each
takes its base from `lda XIX,0x00e086` (`0xFC4C8C`, `0xFC7DB6`) — the **37-byte
record** — and the packer shifts that byte into bits **15:8**, not 6:4
(`0xFC4DE3-0xFC4DF1`). The `& 0x0070` at `0xFC4865` *preserves* `P[+0x07]`'s bits
6:4; it does not write them. **So the producer of the bits that gate register
`0x0300` is still unlocated**, and the two sites named as its writers are the
channel-slot allocator instead. Probe §2 asserts both bases.

### 4.2 `p20` is read

`FINDINGS-l7a1429-parameter-names.md` §5e says `p12` and `p20` "are read by
nothing in the image". Wave-select byte `+0x14` — `p20` — is read at `0xFC588B`
in `sub_FC578C`, through `P[+0x03]`, and **100 is subtracted from it** at
`0xFC5890`. That is why its factory value is the constant 100: it is a
zero-offset base. The claim about `p12` is untouched. Probe §9.

### 4.3 The `Calls:` / `Called from:` comments in five other files are now stale

This lane owns `prom_c/field_accessors.s` only, so the generated cross-reference
comments elsewhere still spell the old `sub_XXXXXX` names. The exact list is in
the header of `notes/w20-lsi-packer-renames.map`; the sweep is

```
python3 scripts/converters/sync_comments_to_renamed_labels.py \
    --base main --apply --write-map /tmp/w20.map \
    wsa1/prom_c/wsa1_prom_c.s wsa1/prom_c/midi/midi_controllers.s \
    wsa1/prom_c/voice/note_engine.s wsa1/prom_c/tone_db/tone_db_module.s \
    wsa1/prom_c/devices/dev10c_dev104_drivers.s
```

⚠ The last of those is another lane's file and must wait for that lane.

---

## 5. WHAT THE NEXT PASS SHOULD DO

1. **`0x00E093` and `0x00E095`.** They are the only outputs of the three large
   RESO MODE arms, and finding their consumers names six routines and probably
   the `CONNECTION` menu with them. This is the cheapest remaining item in this
   file.
2. **Rename `Curve_FE0296` and label `0x00FE02C9`** in
   `prom_c/data_tables/tail_data_zone.s` — §1.4 gives both the extents and the
   proposed names, and neither table is currently labelled for what it does.
3. **`sub_FC578C`'s two callers**, `0xFAB6BF` and `0xFAB789`. The routine
   combines `p20`, two part-level position words and the live movement term into
   one small signed number; what consumes it is one hop away.
4. **`PART[+0x05]`.** `PartRec_SetPositionOffset_0005` stores into it but
   re-derives the elements from `PART[+0x03]` (`0xFC5C4D`, `0xFC5C7C`,
   `0xFC5CA2`, `0xFC5CB9`). Either something else folds `+0x05` into `+0x03`, or
   the second control reaches the device by a route this pass did not find.
   ⚠ Recorded as an open asymmetry; it is not called a bug.
5. **Nothing here proposes measuring the instrument.** It is in storage abroad.
